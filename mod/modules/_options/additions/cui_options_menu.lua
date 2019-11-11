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
function PopulateCheckBox(control, k, handler, enabled)
    local key = CuiSettings[k]
    local value = CuiSettings:GetBoolean(key)

    control:SetSelected(value)
    control:SetDisabled(not enabled)

    control:RegisterCallback(Mouse.eLClick, function()
        local selected = not control:IsSelected()
        control:SetSelected(selected)
        CuiSettings:SetBoolean(key, selected)
        handler()
    end)
    control:RegisterCallback(Mouse.eMouseEnter, function()
        UI.PlaySound("Main_Menu_Mouse_Over")
    end)
end

-- ---------------------------------------------------------------------------
function PopulatePullDown(control, options, selected_value, handler, enabled)
    control:ClearEntries()
    local button = control:GetButton()

    for i, option in ipairs(options) do
        local instance = {}
        control:BuildEntry("InstanceOne", instance)
        instance.Button:LocalizeAndSetText(option[1])
        instance.Button:SetVoid1(i)

        if option[2] == selected_value then
            button:LocalizeAndSetText(option[1])
        end
    end

    control:SetDisabled(not enabled)
    if enabled then
        button:RegisterCallback(Mouse.eMouseEnter, function()
            UI.PlaySound("Main_Menu_Mouse_Over")
        end)
        control:RegisterSelectionCallback(
			function(voidValue1, voidValue2, control)
				local params = options[voidValue1];
                local text = params[1]
                local buttonValue = params[2]
                button:LocalizeAndSetText(text);
				handler(buttonValue);
			end
        )
    end

    control:CalculateInternals();
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
    local options = {
		{"LOC_OPTIONS_ENABLED",  true},
		{"LOC_OPTIONS_DISABLED", false},
    }

    -- Science
    local ScienceHandler = function(v)
        CuiSettings:SetBoolean(CuiSettings.SCIENCE, v)
        UpdateVictory()
    end
    PopulatePullDown(Controls.SetScience,
                     options,
                     CuiSettings:GetBoolean(CuiSettings.SCIENCE),
                     ScienceHandler,
                     Game.IsVictoryEnabled("VICTORY_TECHNOLOGY")
                    )

    -- Culture
    local CultureHandler = function(v)
        CuiSettings:SetBoolean(CuiSettings.CULTURE, v)
        UpdateVictory()
    end
    PopulatePullDown(Controls.SetCulture,
                     options,
                     CuiSettings:GetBoolean(CuiSettings.CULTURE),
                     CultureHandler,
                     Game.IsVictoryEnabled("VICTORY_CULTURE")
                    )

    -- Domination
    local DominationHandler = function(v)
        CuiSettings:SetBoolean(CuiSettings.DOMINATION, v)
        UpdateVictory()
    end
    PopulatePullDown(Controls.SetDomination,
                     options,
                     CuiSettings:GetBoolean(CuiSettings.DOMINATION),
                     DominationHandler,
                     Game.IsVictoryEnabled("VICTORY_CONQUEST")
                    )

    -- Religious
    local ReligiousHandler = function(v)
        CuiSettings:SetBoolean(CuiSettings.RELIGION, v)
        UpdateVictory()
    end
    PopulatePullDown(Controls.SetReligious,
                     options,
                     CuiSettings:GetBoolean(CuiSettings.RELIGION),
                     ReligiousHandler,
                     Game.IsVictoryEnabled("VICTORY_RELIGIOUS")
                    )

    -- Diplomatic
    local DiplomaticHandler = function(v)
        CuiSettings:SetBoolean(CuiSettings.DIPLOMATIC, v)
        UpdateVictory()
    end
    PopulatePullDown(Controls.SetDiplomatic,
                     options,
                     CuiSettings:GetBoolean(CuiSettings.DIPLOMATIC),
                     DiplomaticHandler,
                     Game.IsVictoryEnabled("VICTORY_DIPLOMATIC")
                    )
end

-- ---------------------------------------------------------------------------
function UpdateVictory() LuaEvents.CuiVictorySettingChange() end

-- ---------------------------------------------------------------------------
function LoadLogSettings()
    local options = {
		{"LOC_CUI_OPTIONS_LOG_SHOW_NONE",  0},
		{"LOC_CUI_OPTIONS_LOG_DEFAULT", 1},
		{"LOC_CUI_OPTIONS_LOG_WORLDTRACKER", 2},
		{"LOC_CUI_OPTIONS_LOG_BOTH", 3},
    }
    
    -- Gossip
    local gossip_value = 0
    if CuiSettings:GetBoolean(CuiSettings.DF_GOSSIP_LOG) then
        gossip_value = gossip_value + 1
    end
    local GossipHandler = function(v)
        CuiSettings:SetBoolean(CuiSettings.DF_GOSSIP_LOG, (v == 1 or v == 3))
        CuiSettings:SetBoolean(CuiSettings.WT_GOSSIP_LOG, (v == 2 or v == 3))
        UpdateLog()
    end
    if CuiSettings:GetBoolean(CuiSettings.WT_GOSSIP_LOG) then
        gossip_value = gossip_value + 2
    end
    PopulatePullDown(Controls.SetGossip,
                     options,
                     gossip_value,
                     GossipHandler,
                     true
                    )
                    
    -- Combat
    local combat_value = 0
    if CuiSettings:GetBoolean(CuiSettings.DF_COMBAT_LOG) then
        combat_value = combat_value + 1
    end
    local CombatHandler = function(v)
        CuiSettings:SetBoolean(CuiSettings.DF_COMBAT_LOG, (v == 1 or v == 3))
        CuiSettings:SetBoolean(CuiSettings.WT_COMBAT_LOG, (v == 2 or v == 3))
        UpdateLog()
    end
    if CuiSettings:GetBoolean(CuiSettings.WT_COMBAT_LOG) then
        combat_value = combat_value + 2
    end
    PopulatePullDown(Controls.SetCombat,
                     options,
                     combat_value,
                     CombatHandler,
                     true
                    )
end

-- ---------------------------------------------------------------------------
function UpdateLog() LuaEvents.CuiLogSettingChange() end

-- ---------------------------------------------------------------------------
function LoadPopupSettings()
    local options = {
		{"LOC_OPTIONS_ENABLED",  true},
		{"LOC_OPTIONS_DISABLED", false},
    }

    -- Research
    local ResearchHandler = function(v)
        CuiSettings:SetBoolean(CuiSettings.POPUP_RESEARCH, v)
    end
    PopulatePullDown(Controls.SetResearch,
                     options,
                     CuiSettings:GetBoolean(CuiSettings.POPUP_RESEARCH),
                     ResearchHandler,
                     true
                    )

    -- PlayAudio
    local AudioHandler = function(v)
        CuiSettings:SetBoolean(CuiSettings.AUDIO_RESEARCH, v)
    end
    PopulatePullDown(Controls.SetPlayAudio,
                     options,
                     CuiSettings:GetBoolean(CuiSettings.AUDIO_RESEARCH),
                     AudioHandler,
                     true
                    )

    -- EraScore
    local EraScoreHandler = function(v)
        CuiSettings:SetBoolean(CuiSettings.POPUP_HISTORIC, v)
    end
    PopulatePullDown(Controls.SetEraScore,
                     options,
                     CuiSettings:GetBoolean(CuiSettings.POPUP_HISTORIC),
                     EraScoreHandler,
                     true
                    )

    -- GreatWork
    local GreatWorkHandler = function(v)
        CuiSettings:SetBoolean(CuiSettings.POPUP_CREATWORK, v)
    end
    PopulatePullDown(Controls.SetGreatWork,
                     options,
                     CuiSettings:GetBoolean(CuiSettings.POPUP_CREATWORK),
                     GreatWorkHandler,
                     true
                    )

    -- Relic
    local RelicHandler = function(v)
        CuiSettings:SetBoolean(CuiSettings.POPUP_RELIC, v)
    end
    PopulatePullDown(Controls.SetRelic,
                     options,
                     CuiSettings:GetBoolean(CuiSettings.POPUP_RELIC),
                     RelicHandler,
                     true
                    )
end

-- ---------------------------------------------------------------------------
function UpdatePopup()
    -- LuaEvents.CuiPopupSettingChange()
end

-- ---------------------------------------------------------------------------
function LoadRemindSettings()
    local options = {
		{"LOC_OPTIONS_ENABLED",  true},
		{"LOC_OPTIONS_DISABLED", false},
    }

    -- TechRemind
    local TechRemindHandler = function(v)
        CuiSettings:SetBoolean(CuiSettings.REMIND_TECH, v)
        UpdateRemind()
    end
    PopulatePullDown(Controls.SetTechRemind,
                     options,
                     CuiSettings:GetBoolean(CuiSettings.REMIND_TECH),
                     TechRemindHandler,
                     true
                    )

    -- CivicRemind
    local CivicRemindHandler = function(v)
        CuiSettings:SetBoolean(CuiSettings.REMIND_CIVIC, v)
        UpdateRemind()
    end
    PopulatePullDown(Controls.SetCivicRemind,
                     options,
                     CuiSettings:GetBoolean(CuiSettings.REMIND_CIVIC),
                     CivicRemindHandler,
                     true
                    )

    -- GovernmentRemind
    local GovernmentRemindHandler = function(v)
        CuiSettings:SetBoolean(CuiSettings.REMIND_GOVERNMENT, v)
        UpdateRemind()
    end
    PopulatePullDown(Controls.SetGovernmentRemind,
                     options,
                     CuiSettings:GetBoolean(CuiSettings.REMIND_GOVERNMENT),
                     GovernmentRemindHandler,
                     true
                    )

    -- GovernorRemind
    local GovernorRemindHandler = function(v)
        CuiSettings:SetBoolean(CuiSettings.REMIND_GOVERNOR, v)
        UpdateRemind()
    end
    PopulatePullDown(Controls.SetGovernorRemind,
                     options,
                     CuiSettings:GetBoolean(CuiSettings.REMIND_GOVERNOR),
                     GovernorRemindHandler,
                     true
                    )
end

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
