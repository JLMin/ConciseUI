-- ===========================================================================
-- Cui Options Menu
-- eudaimonia, 11/10/2019
-- ===========================================================================
include("InstanceManager")
include("cui_helper")
include("cui_settings")

-- ---------------------------------------------------------------------------

local boolean_text = {"LOC_OPTIONS_ENABLED", "LOC_OPTIONS_DISABLED"}

local tabs = {
    {Controls.VictoryTab, Controls.VictoryOptions, 0},
    {Controls.LogTab, Controls.LogOptions, 0},
    {Controls.PopupTab, Controls.PopupOptions, 0},
    {Controls.RemindTab, Controls.RemindOptions, 0}
}

-- ---------------------------------------------------------------------------
-- UI Functions
-- ---------------------------------------------------------------------------
function PopulateCheckBox(control, k, check_handler, enabled)
    local key = CuiSettings[k]
    local value = CuiSettings:GetBoolean(key)

    control:SetSelected(value)
    control:SetDisabled(not enabled)

    control:RegisterCallback(Mouse.eLClick, function()
        local selected = not control:IsSelected()
        control:SetSelected(selected)
        CuiSettings:SetBoolean(key, selected)
        check_handler()
    end)
    control:RegisterCallback(Mouse.eMouseEnter, function()
        UI.PlaySound("Main_Menu_Mouse_Over")
    end)
end

-- ---------------------------------------------------------------------------
function SelectTab(tab)
    local button = tab[1]
    local panel = tab[2]

    for _, tab in ipairs(tabs) do
        tab[1]:SetSelected(false)
        tab[2]:SetHide(true)
    end

    button:SetSelected(true)
    panel:SetHide(false)
end

-- ---------------------------------------------------------------------------
function RegisterClickFunctions()
    -- tabs
    for _, tab in ipairs(tabs) do
        local button = tab[1]
        button:RegisterCallback(Mouse.eLClick, function() SelectTab(tab) end)
    end

    -- comfirm button
    Controls.ConfirmButton:RegisterCallback(Mouse.eLClick, OnConfirm)
    Controls.ConfirmButton:RegisterCallback(Mouse.eMouseEnter, function()
        UI.PlaySound("Main_Menu_Mouse_Over")
    end)
end

-- ---------------------------------------------------------------------------
-- Tab Functions
-- ---------------------------------------------------------------------------
function LoadVictorySettings()
--[[
    PopulateCheckBox(Controls.SetScience, "SCIENCE", UpdateVictory,
                     Game.IsVictoryEnabled("VICTORY_TECHNOLOGY"))

    PopulateCheckBox(Controls.SetCulture, "CULTURE", UpdateVictory,
                     Game.IsVictoryEnabled("VICTORY_CULTURE"))

    PopulateCheckBox(Controls.SetDomination, "DOMINATION", UpdateVictory,
                     Game.IsVictoryEnabled("VICTORY_CONQUEST"))

    PopulateCheckBox(Controls.SetReligious, "RELIGION", UpdateVictory,
                     Game.IsVictoryEnabled("VICTORY_RELIGIOUS"))

    PopulateCheckBox(Controls.SetDiplomatic, "DIPLOMATIC", UpdateVictory,
                     Game.IsVictoryEnabled("VICTORY_DIPLOMATIC"))
]]
end

-- ---------------------------------------------------------------------------
function UpdateVictory() LuaEvents.CuiVictorySettingChange() end

-- ---------------------------------------------------------------------------
function LoadLogSettings()
--[[
    PopulateCheckBox(Controls.SetGossipWT, "WT_GOSSIP_LOG", UpdateLog, true)
    PopulateCheckBox(Controls.SetCombatWT, "WT_COMBAT_LOG", UpdateLog, true)
    PopulateCheckBox(Controls.SetGossipDF, "DF_GOSSIP_LOG", UpdateLog, true)
    PopulateCheckBox(Controls.SetCombatDF, "DF_COMBAT_LOG", UpdateLog, true)
]]
end

-- ---------------------------------------------------------------------------
function UpdateLog() LuaEvents.CuiLogSettingChange() end

-- ---------------------------------------------------------------------------
function LoadPopupSettings()
--[[
    PopulateCheckBox(Controls.SetResearch, "POPUP_RESEARCH", UpdatePopup, true)
    PopulateCheckBox(Controls.SetPlayAudio, "AUDIO_RESEARCH", UpdatePopup, true)
    PopulateCheckBox(Controls.SetEraScore, "POPUP_HISTORIC", UpdatePopup, true)
    PopulateCheckBox(Controls.SetGreatWork, "POPUP_CREATWORK", UpdatePopup, true)
    PopulateCheckBox(Controls.SetRelic, "POPUP_RELIC", UpdatePopup, true)
]]
end

-- ---------------------------------------------------------------------------
function UpdatePopup()
    -- LuaEvents.CuiPopupSettingChange()
end

-- ---------------------------------------------------------------------------
function LoadRemindSettings() end

-- ---------------------------------------------------------------------------
function UpdateRemind() LuaEvents.CuiRemindSettingChange() end

-- ---------------------------------------------------------------------------
-- Data Functions
-- ---------------------------------------------------------------------------
function LoadSettings()
    LoadVictorySettings()
    LoadLogSettings()
    LoadPopupSettings()
    LoadRemindSettings()
end

-- ---------------------------------------------------------------------------
function SaveSettings() end

-- ---------------------------------------------------------------------------
-- Screen Functions
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
    Controls.ScreenAnimIn:SetToBeginning()
    Controls.ScreenAnimIn:Play()
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

    RegisterClickFunctions()

    local title = "Concise UI - " .. Locale.Lookup("LOC_MAIN_MENU_OPTIONS")
    Controls.WindowTitle:SetText(title)
    Controls.TabStack:CalculateSize()

    LuaEvents.CuiToggleOptions.Add(OnShow)

    SelectTab(tabs[1])
end
Initialize()
