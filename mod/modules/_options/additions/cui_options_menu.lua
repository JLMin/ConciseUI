-- ===========================================================================
-- Cui Options Menu
-- eudaimonia, 11/10/2019
-- ===========================================================================
include("InstanceManager")
include("cui_helper")
include("cui_settings")

-- ---------------------------------------------------------------------------
local boolean_text = {"LOC_OPTIONS_ENABLED", "LOC_OPTIONS_DISABLED"}

-- ---------------------------------------------------------------------------
-- ---------------------------------------------------------------------------
-- UI Functions
-- ---------------------------------------------------------------------------
function PopulateCheckBox(control, k, enabled)
    key = CuiSettings[k]
    value = CuiSettings:GetBoolean(key)

    control:SetSelected(value)
    control:SetDisabled(not enabled)

    control:RegisterCallback(Mouse.eLClick, function()
        local selected = not control:IsSelected()
        control:SetSelected(selected)
        CuiSettings:SetBoolean(key, selected)
    end)
    control:RegisterCallback(Mouse.eMouseEnter, function()
        UI.PlaySound("Main_Menu_Mouse_Over")
    end)
end

-- ---------------------------------------------------------------------------
-- Victory Tab
-- ---------------------------------------------------------------------------
function LoadVictorySettings()
    PopulateCheckBox(Controls.CBScience, "SCIENCE",
                     Game.IsVictoryEnabled("VICTORY_TECHNOLOGY"))

    PopulateCheckBox(Controls.CBCulture, "CULTURE",
                     Game.IsVictoryEnabled("VICTORY_CULTURE"))

    PopulateCheckBox(Controls.CBDomination, "DOMINATION",
                     Game.IsVictoryEnabled("VICTORY_CONQUEST"))

    PopulateCheckBox(Controls.CBReligious, "RELIGION",
                     Game.IsVictoryEnabled("VICTORY_RELIGIOUS"))

    PopulateCheckBox(Controls.CBDiplomatic, "DIPLOMATIC",
                     Game.IsVictoryEnabled("VICTORY_DIPLOMATIC"))
end

-- ---------------------------------------------------------------------------
-- ---------------------------------------------------------------------------
-- ---------------------------------------------------------------------------
-- ---------------------------------------------------------------------------
-- ---------------------------------------------------------------------------
-- ---------------------------------------------------------------------------
-- ---------------------------------------------------------------------------
-- ---------------------------------------------------------------------------
-- ---------------------------------------------------------------------------
-- ---------------------------------------------------------------------------
-- ---------------------------------------------------------------------------
-- ---------------------------------------------------------------------------
-- ---------------------------------------------------------------------------
-- ---------------------------------------------------------------------------
-- ---------------------------------------------------------------------------
-- ---------------------------------------------------------------------------
-- ---------------------------------------------------------------------------
function LoadSettings() LoadVictorySettings() end

-- ---------------------------------------------------------------------------
function SaveSettings() end

-- ---------------------------------------------------------------------------
function Open()
    if ContextPtr:IsHidden() then UI.PlaySound("UI_Screen_Open") end
    UIManager:QueuePopup(ContextPtr, PopupPriority.Current)
end

-- ---------------------------------------------------------------------------
function Close()
    if not ContextPtr:IsHidden() then UI.PlaySound("UI_Screen_Close") end
    UIManager:DequeuePopup(ContextPtr)
end

-- ---------------------------------------------------------------------------
function OnShow()
    LoadSettings()
    Open()
end

-- ---------------------------------------------------------------------------
function OnConfirm()
    SaveSettings()
    Close()
end

-- ---------------------------------------------------------------------------
function OnInit(isReload)
    if isReload then if not ContextPtr:IsHidden() then Open() end end
end

-- ---------------------------------------------------------------------------
function OnInputHandler(pInputStruct)
    local uiMsg = pInputStruct:GetMessageType()
    if uiMsg == KeyEvents.KeyUp then
        local uiKey = pInputStruct:GetKey()
        if uiKey == Keys.VK_ESCAPE then
            if not ContextPtr:IsHidden() then
                Close()
                return true
            end
        end
    end
    return false
end

-- ---------------------------------------------------------------------------
function Initialize()
    ContextPtr:SetHide(true)
    ContextPtr:SetInitHandler(OnInit)
    ContextPtr:SetInputHandler(OnInputHandler, true)

    Controls.ConfirmButton:RegisterCallback(Mouse.eLClick, OnConfirm)
    Controls.ConfirmButton:RegisterCallback(Mouse.eMouseEnter, function()
        UI.PlaySound("Main_Menu_Mouse_Over")
    end)

    Controls.WindowTitle:SetText("Concise UI Options")
    Controls.TabStack:CalculateSize()

    LuaEvents.CuiToggleOptions.Add(OnShow)
end
Initialize()
