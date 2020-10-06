-- ===========================================================================
-- Concise UI
-- cui_remind_panel.lua
-- ===========================================================================

include("InstanceManager")
include("cui_helper")
include("cui_settings")
include("cui_tech_civic_support")

-- Concise UI ----------------------------------------------------------------
local isAttached = false
local isAnyRemind = false
local testMode = false

-- Concise UI ----------------------------------------------------------------
function RefreshTech(localPlayer, eTech)
    if CuiSettings:GetBoolean(CuiSettings.REMIND_TECH) then
        local isReady = CuiIsTechReady(localPlayer)
        Controls.TechReady:SetHide(not isReady)
        if isReady then
            isAnyRemind = true
        end
    end
end

-- Concise UI ----------------------------------------------------------------
function RefreshCivic(localPlayer, eCivic)
    if CuiSettings:GetBoolean(CuiSettings.REMIND_CIVIC) then
        local isReady = CuiIsCivicReady(localPlayer)
        Controls.CivicReady:SetHide(not isReady)
        if isReady then
            isAnyRemind = true
        end
    end
end

-- Concise UI ----------------------------------------------------------------
function RefreshGovernment(localPlayer)
    if CuiSettings:GetBoolean(CuiSettings.REMIND_GOVERNMENT) then
        local isReady = CuiIsGovernmentReady(localPlayer)
        Controls.GovernmentReady:SetHide(not isReady)
        if isReady then
            isAnyRemind = true
        end
    end
end

-- Concise UI ----------------------------------------------------------------
function RefreshGovernor(localPlayer)
    if not isExpansion1 or not isExpansion2 then
        return
    end

    if CuiSettings:GetBoolean(CuiSettings.REMIND_GOVERNOR) then
        local isReady = CuiIsGovernorReady(localPlayer)
        Controls.GovernorReady:SetHide(not isReady)
        if isReady then
            isAnyRemind = true
        end
    end
end

-- Concise UI ----------------------------------------------------------------
function RefreshAll()
    if testMode then
        ReminderTest()
        return
    end

    local localPlayer = Game.GetLocalPlayer()
    if localPlayer ~= -1 then
        isAnyRemind = false
        RefreshTech(localPlayer)
        RefreshCivic(localPlayer)
        RefreshGovernment(localPlayer)
        RefreshGovernor(localPlayer)
    end

    ResizeBubble()
end

-- Concise UI ----------------------------------------------------------------
function ResizeBubble()
    Controls.RemindStack:CalculateSize()
    Controls.Bubble:SetHide(not isAnyRemind)
    if isAnyRemind then
        local stackX = Controls.RemindStack:GetSizeX()
        local stackY = Controls.RemindStack:GetSizeY()
        Controls.Bubble:SetSizeX(stackX + 34)
        Controls.Bubble:SetSizeY(stackY + 50)
    end
end

-- Concise UI ----------------------------------------------------------------
function ReminderTest()
    isAnyRemind = true
    Controls.TechReady:SetHide(false)
    Controls.CivicReady:SetHide(false)
    Controls.GovernmentReady:SetHide(false)
    Controls.GovernorReady:SetHide(false)

    ResizeBubble()
end

-- Concise UI ----------------------------------------------------------------
function OnMinimapResize()
    if isAttached then
        local minimap = ContextPtr:LookUpControl("/InGame/MinimapPanel/MiniMap/MinimapContainer")
        Controls.RemindContainer:SetOffsetX(minimap:GetSizeX() + 30)
    end
end

-- Concise UI ----------------------------------------------------------------
function AttachToMinimap()
    if not isAttached then
        local minimap = ContextPtr:LookUpControl("/InGame/MinimapPanel/MiniMap/MinimapContainer")
        Controls.RemindContainer:ChangeParent(minimap)
        Controls.RemindContainer:SetOffsetX(minimap:GetSizeX() + 30)
        isAttached = true
    end

    RefreshAll()
end

-- Concise UI ----------------------------------------------------------------
function Initialize()
    ContextPtr:SetHide(true)
    --
    Events.LoadGameViewStateDone.Add(AttachToMinimap)
    --
    Events.ResearchChanged.Add(RefreshAll)
    Events.ResearchCompleted.Add(RefreshAll)
    --
    Events.CivicChanged.Add(RefreshAll)
    Events.CivicCompleted.Add(RefreshAll)
    --
    Events.GovernmentChanged.Add(RefreshAll)
    Events.GovernmentPolicyChanged.Add(RefreshAll)
    Events.GovernmentPolicyObsoleted.Add(RefreshAll)
    --
    Events.GovernorAppointed.Add(RefreshAll)
    Events.GovernorAssigned.Add(RefreshAll)
    Events.GovernorPromoted.Add(RefreshAll)
    --
    Events.LocalPlayerTurnBegin.Add(RefreshAll)
    --
    LuaEvents.CuiRemindSettingChange.Add(RefreshAll)
    --
    LuaEvents.CuiOnMinimapResize.Add(OnMinimapResize)
end
Initialize()
