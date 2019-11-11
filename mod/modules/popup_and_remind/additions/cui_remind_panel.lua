-- ===========================================================================
-- Cui Remind Panel
-- eudaimonia, 11/11/2019
-- ===========================================================================
include("InstanceManager")
include("cui_settings")
include("cui_tech_civic_support")

-- ---------------------------------------------------------------------------

local isAttached = false

-- ---------------------------------------------------------------------------
function RefreshTech(localPlayer, eTech)
    if not CuiSettings:GetBoolean(CuiSettings.REMIND_TECH) then
        Controls.TechReady:SetHide(true)
        return
    end

    local isReady = CuiIsTechReady(localPlayer)
    Controls.TechReady:SetHide(not isReady)
end

-- ---------------------------------------------------------------------------
function RefreshCivic(localPlayer, eCivic)
    if not CuiSettings:GetBoolean(CuiSettings.REMIND_CIVIC) then
        Controls.CivicReady:SetHide(true)
        return
    end

    local isReady = CuiIsCivicReady(localPlayer)
    Controls.CivicReady:SetHide(not isReady)
end

-- ---------------------------------------------------------------------------
function RefreshGovernment(localPlayer)
    if not CuiSettings:GetBoolean(CuiSettings.REMIND_GOVERNMENT) then
        Controls.GovernmentReady:SetHide(true)
        return
    end

    local isReady = CuiIsGovernmentReady(localPlayer)
    Controls.GovernmentReady:SetHide(not isReady)
end

-- ---------------------------------------------------------------------------
function RefreshGovernor(localPlayer)
    if not CuiSettings:GetBoolean(CuiSettings.REMIND_GOVERNOR) then
        Controls.GovernorReady:SetHide(true)
        return
    end

    local isReady = CuiIsGovernorReady(localPlayer)
    Controls.GovernorReady:SetHide(not isReady)
end

-- ---------------------------------------------------------------------------
function RefreshAll()
    local localPlayer = Game.GetLocalPlayer()
    if localPlayer ~= -1 then
        RefreshTech(localPlayer)
        RefreshCivic(localPlayer)
        RefreshGovernment(localPlayer)
        RefreshGovernor(localPlayer)
    end
end

-- ---------------------------------------------------------------------------
function AttachToActionPanel()
    if not isAttached then
        local actionPanel = ContextPtr:LookUpControl(
                                "/InGame/ActionPanel/EndTurnButtonLabel")
        Controls.RemindContainer:ChangeParent(actionPanel)
        isAttached = true
    end

    Controls.TechReady:SetHide(true)
    Controls.CivicReady:SetHide(true)
    Controls.GovernmentReady:SetHide(true)
    Controls.GovernorReady:SetHide(true)

    RefreshAll()
end

-- ---------------------------------------------------------------------------
function Initialize()
    ContextPtr:SetHide(true)
    --
    Events.LoadGameViewStateDone.Add(AttachToActionPanel)
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
end
Initialize()
