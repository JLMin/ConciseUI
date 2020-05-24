-- ===========================================================================
-- Cui Victory Tracking
-- eudaimonia, 11/10/2019
-- ===========================================================================
include("InstanceManager")
include("PlayerSupport")
include("cui_helper")
include("cui_settings")
include("cui_victory_support")

-- ---------------------------------------------------------------------------
local isAttached = false

local CuiVictoryTT = {}
TTManager:GetTypeControlTable("CuiVictoryTT", CuiVictoryTT)

local victoryIconInstance = InstanceManager:new("VictoryIconInstance", "Top", Controls.VictoryIconInstanceContainer)
local victoryLeaderInstance =
    InstanceManager:new("VictoryLeaderInstance", "Top", Controls.VictoryLeaderInstanceContainer)

local ranks = {}
local scienceData = {}
local cultureData = {}
local dominationData = {}
local religionData = {}
local diplomaticData = {}

-- ---------------------------------------------------------------------------
function GetData()
    local victoryTypes = GetVictoryTypes()
    for _, vType in ipairs(victoryTypes) do
        if vType == "SCIENCE" then
            scienceData, ranks["SCIENCE"] = GetScienceData()
        elseif vType == "CULTURE" then
            cultureData, ranks["CULTURE"] = GetCultureData()
        elseif vType == "DOMINATION" then
            dominationData, ranks["DOMINATION"] = GetDominationData()
        elseif vType == "RELIGION" then
            religionData, ranks["RELIGION"] = GetReligionData()
        elseif vType == "DIPLOMATIC" then
            diplomaticData, ranks["DIPLOMATIC"] = GetDiplomaticData()
        end
    end
end

-- ---------------------------------------------------------------------------
function PopulateVictoryIcons()
    victoryIconInstance:ResetInstances()
    local victoryTypes = GetVictoryTypes()
    for _, vType in ipairs(victoryTypes) do
        if CuiSettings:GetBoolean(CuiSettings[vType]) then
            local instance = victoryIconInstance:GetInstance(Controls.VictoryButtonStack)
            local icon = "ICON_VICTORY_" .. vType
            if icon ~= nil then
                local textureOffsetX, textureOffsetY, textureSheet = IconManager:FindIconAtlas(icon, 64)
                if (textureSheet == nil or textureSheet == "") then
                    UI.DataError('Could not find icon in PopulateVictoryButton: icon="' .. icon .. '", iconSize=64')
                else
                    -- set icon
                    instance.VictoryIcon:SetTexture(textureOffsetX, textureOffsetY, textureSheet)
                    -- set tooltip
                    instance.VictoryIcon:ClearToolTipCallback()
                    instance.VictoryIcon:SetToolTipType("CuiVictoryTT")
                    instance.VictoryIcon:SetToolTipCallback(
                        function()
                            UpdateVictoryToolTip(vType)
                        end
                    )
                    -- set rank
                    local rankText = ranks[vType]
                    if rankText == 1 then
                        rankText = "[COLOR_GREEN]" .. rankText .. "[ENDCOLOR]"
                    end
                    instance.Text:SetText("#" .. rankText)
                end
            end
        end
    end
end

-- ---------------------------------------------------------------------------
function UpdateVictoryToolTip(vType)
    local localPlayerID = Game.GetLocalPlayer()
    if localPlayerID == -1 then
        return
    end

    local leaders
    if vType == "SCIENCE" then
        leaders = scienceData
    elseif vType == "CULTURE" then
        leaders = cultureData
    elseif vType == "DOMINATION" then
        leaders = dominationData
    elseif vType == "RELIGION" then
        leaders = religionData
    elseif vType == "DIPLOMATIC" then
        leaders = diplomaticData
    end

    victoryLeaderInstance:ResetInstances()

    for i, leader in ipairs(leaders) do
        local leaderInstance = victoryLeaderInstance:GetInstance(CuiVictoryTT.VictoryLeaderStack)
        SetVictoryLeaderInstance(vType, leader, leaderInstance)
    end

    local title = ""
    if vType == "RELIGION" then
        title = "LOC_VICTORY_RELIGIOUS_NAME"
    else
        title = "LOC_VICTORY_" .. vType .. "_NAME"
    end

    CuiVictoryTT.Title:SetText(Locale.Lookup(title))
    CuiVictoryTT.Divider:SetSizeX(CuiVictoryTT.Title:GetSizeX() + 60)
    CuiVictoryTT.BG:DoAutoSize()
end

-- ---------------------------------------------------------------------------
function SetVictoryLeaderInstance(vType, leader, instance)
    local shouldShowIcon = leader.isLocalPlayer or leader.isMet

    local text1 = ""
    local text2 = ""
    if shouldShowIcon then
        if vType == "SCIENCE" then
            text1 = "[ICON_SCIENCE]" .. leader.scienceY .. " (" .. leader.techs .. ")"
            local progressText = ""
            local progress = leader.progresses
            if isExpansion2 then
                text2 =
                    Locale.Lookup(
                    "LOC_CUI_DB_EXOPLANET_EXPEDITION",
                    progress[1],
                    progress[2],
                    progress[3],
                    progress[4],
                    progress[5]
                )
            else
                text2 = Locale.Lookup("LOC_CUI_DB_MARS_PROJECT", progress[1], progress[2], progress[3])
            end
        elseif vType == "CULTURE" then
            text1 = "[ICON_CULTURE]" .. leader.cultureY .. " ([ICON_TOURISM]" .. leader.tourism .. ")"
            text2 = Locale.Lookup("LOC_CUI_DB_VISITING_TOURISTS", leader.visiter, leader.tourists)
        elseif vType == "DOMINATION" then
            text1 = "[ICON_STRENGTH]" .. leader.strength
            text2 = Locale.Lookup("LOC_CUI_DB_CAPITALS_CAPTURED", leader.capture)
        elseif vType == "RELIGION" then
            text1 = "[ICON_FAITH]" .. leader.faithY
            text2 = Locale.Lookup("LOC_CUI_DB_CIVS_CONVERTED", leader.convert, leader.totalCiv)
        elseif vType == "DIPLOMATIC" then
            text1 = "[ICON_FAVOR] " .. leader.favor .. " (+" .. leader.favorPT .. ")"
            text2 = Locale.Lookup("LOC_CUI_DB_DIPLOMATIC_POINT", leader.current, leader.total)
        end
    end

    instance.Icon:SetTexture(CuiLeaderTexture(leader.leaderIcon, 45, shouldShowIcon))
    instance.UnMet:SetHide(shouldShowIcon)
    instance.State1:SetHide(not shouldShowIcon)
    instance.State1:SetText(text1)
    instance.State2:SetHide(not shouldShowIcon)
    instance.State2:SetText(text2 .. "  ")

    if leader.isLocalPlayer then
        instance.LeaderIcon:SetOffsetX(-2)
        instance.YouIndicator:SetHide(false)
    else
        instance.LeaderIcon:SetOffsetX(0)
        instance.YouIndicator:SetHide(true)
    end
end

-- ---------------------------------------------------------------------------
function RefreshAll()
    GetData()
    PopulateVictoryIcons()
end

-- ---------------------------------------------------------------------------
function OnMinimapResize()
    if isAttached then
        local minimap = ContextPtr:LookUpControl("/InGame/MinimapPanel/MiniMap/MinimapContainer")
        Controls.CuiVictoryTracking:SetOffsetX(minimap:GetSizeX() + 10)
    end
end

-- ---------------------------------------------------------------------------
function AttachToMinimap()
    if not isAttached then
        local minimap = ContextPtr:LookUpControl("/InGame/MinimapPanel/MiniMap/MinimapContainer")
        Controls.CuiVictoryTracking:ChangeParent(minimap)
        Controls.CuiVictoryTracking:SetOffsetX(minimap:GetSizeX() + 10)
        RefreshAll()
        isAttached = true
    end
end

-- ---------------------------------------------------------------------------
function Initialize()
    ContextPtr:SetHide(true)
    Events.LoadGameViewStateDone.Add(AttachToMinimap)
    LuaEvents.CuiOnMinimapResize.Add(OnMinimapResize)
    LuaEvents.DiplomacyActionView_ShowIngameUI.Add(RefreshAll)
    Events.TurnBegin.Add(RefreshAll)
    LuaEvents.CuiVictorySettingChange.Add(RefreshAll)
end
Initialize()
