-- ===========================================================================
-- cui_spy_info.lua
-- ===========================================================================

include("EspionageSupport")

-- CUI -----------------------------------------------------------------------
local isAttached = false

-- CUI -----------------------------------------------------------------------
function RefreshSpyInfo()
    local localPlayer = Players[Game.GetLocalPlayer()]
    if localPlayer == nil then
        return
    end

    local numberOfSpies = 0

    -- normal spies
    local localPlayerUnits = localPlayer:GetUnits()
    for i, unit in localPlayerUnits:Members() do
        local unitInfo = GameInfo.Units[unit:GetUnitType()]
        if unitInfo.Spy then
            numberOfSpies = numberOfSpies + 1
        end
    end

    -- captured spies
    for i, player in ipairs(Game.GetPlayers()) do
        local playerDiplomacy = player:GetDiplomacy()
        local numCapturedSpies = playerDiplomacy:GetNumSpiesCaptured()
        for i = 0, numCapturedSpies - 1, 1 do
            local spyInfo = playerDiplomacy:GetNthCapturedSpy(player:GetID(), i)
            if spyInfo and spyInfo.OwningPlayer == Game.GetLocalPlayer() then
                numberOfSpies = numberOfSpies + 1
            end
        end
    end

    -- travelling spies
    local localPlayerDiplomacy = Players[Game.GetLocalPlayer()]:GetDiplomacy()
    if localPlayerDiplomacy then
        local numSpiesOffMap = localPlayerDiplomacy:GetNumSpiesOffMap()
        for i = 0, numSpiesOffMap - 1, 1 do
            local spyOffMapInfo = localPlayerDiplomacy:GetNthOffMapSpy(Game.GetLocalPlayer(), i)
            if spyOffMapInfo and spyOffMapInfo.ReturnTurn ~= -1 then
                numberOfSpies = numberOfSpies + 1
            end
        end
    end

    local spyCapacity = localPlayerDiplomacy:GetSpyCapacity()
    if spyCapacity > 0 then
        local coloredAvailable = numberOfSpies
        if numberOfSpies > spyCapacity then
            coloredAvailable = "[COLOR_RED]" .. numberOfSpies .. "[ENDCOLOR]"
        elseif numberOfSpies < spyCapacity then
            coloredAvailable = "[COLOR_GREEN]" .. numberOfSpies .. "[ENDCOLOR]"
        end
        Controls.SpyAvailable:SetText(coloredAvailable)
        Controls.SpyCapacity:SetText(spyCapacity)

        local tooltip = ""
        tooltip = tooltip .. Locale.Lookup("LOC_CUI_SI_SPY_AVAILABLE", numberOfSpies) .. "[NEWLINE]"
        tooltip = tooltip .. Locale.Lookup("LOC_CUI_SI_SPY_CAPACITY", spyCapacity)
        Controls.CuiSpyInfo:SetToolTipString(tooltip)

        Controls.CuiSpyInfo:SetHide(false)
    else
        Controls.CuiSpyInfo:SetHide(true)
    end

    Controls.SpyStack:CalculateSize()
    Controls.SpyStack:ReprocessAnchoring()
end

-- CUI -----------------------------------------------------------------------
function AttachToTopPanel()
    if not isAttached then
        local infoStack = ContextPtr:LookUpControl("/InGame/TopPanel/InfoStack/StaticInfoStack")
        Controls.CuiSpyInfo:ChangeParent(infoStack)
        infoStack:AddChildAtIndex(Controls.CuiSpyInfo, 1)
        infoStack:CalculateSize()
        infoStack:ReprocessAnchoring()
        isAttached = true
    end
    RefreshSpyInfo()
end

-- CUI -----------------------------------------------------------------------
function Initialize()
    ContextPtr:SetHide(true)
    Events.LoadGameViewStateDone.Add(AttachToTopPanel)
    Events.LocalPlayerTurnBegin.Add(RefreshSpyInfo)
    Events.LocalPlayerChanged.Add(RefreshSpyInfo)
end
Initialize()
