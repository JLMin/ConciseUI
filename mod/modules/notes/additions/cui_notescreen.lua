-- ===========================================================================
-- Cui In Game Note Screen
-- eudaimonia, 11/05/2019
-- ===========================================================================
include("InstanceManager")
include("cui_helper")
include("cui_settings")

-- ===========================================================================
local cui_NoteEnter =
    InstanceManager:new("NoteEnter", "Top", Controls.NoteStack)
local EMPTY_NOTE = Locale.Lookup("LOC_CUI_NOTE_EMPTY")
local windowHeight = 0
local TOP_PANEL_OFFSET = 29

local NOTE = {
    NOTE0 = {field = "Note0", default = EMPTY_NOTE},
    NOTE1 = {field = "Note1", default = EMPTY_NOTE},
    NOTE2 = {field = "Note2", default = EMPTY_NOTE},
    NOTE3 = {field = "Note3", default = EMPTY_NOTE},
    NOTE4 = {field = "Note4", default = EMPTY_NOTE},
    NOTE5 = {field = "Note5", default = EMPTY_NOTE},
    NOTE6 = {field = "Note6", default = EMPTY_NOTE},
    NOTE7 = {field = "Note7", default = EMPTY_NOTE},
    NOTE8 = {field = "Note8", default = EMPTY_NOTE},
    NOTE9 = {field = "Note9", default = EMPTY_NOTE}
}

local NOTE_TURN = {
    NOTE0 = {field = "NoteTurn0", default = 0},
    NOTE1 = {field = "NoteTurn1", default = 0},
    NOTE2 = {field = "NoteTurn2", default = 0},
    NOTE3 = {field = "NoteTurn3", default = 0},
    NOTE4 = {field = "NoteTurn4", default = 0},
    NOTE5 = {field = "NoteTurn5", default = 0},
    NOTE6 = {field = "NoteTurn6", default = 0},
    NOTE7 = {field = "NoteTurn7", default = 0},
    NOTE8 = {field = "NoteTurn8", default = 0},
    NOTE9 = {field = "NoteTurn9", default = 0}
}

-- ===========================================================================
function PopulateNoteList()
    cui_NoteEnter:ResetInstances()
    for i = 1, 10, 1 do
        local note = cui_NoteEnter:GetInstance()
        local index = "NOTE" .. (i - 1)
        local textSaved = CuiSettings:GetString(NOTE[index])
        local turnSaved = CuiSettings:GetNumber(NOTE_TURN[index])
        SetNote(note, textSaved, turnSaved)

        -- left click call back
        note.EditButton:RegisterCallback(Mouse.eLClick, function()
            note.Overview:SetHide(true)
            local sText = note.Overview:GetText()
            if IsEmpty(sText) then
                note.EditNote:SetText("")
            else
                note.EditNote:SetText(note.Overview:GetText())
            end
            note.EditNote:SetHide(false)
            note.EditNote:TakeFocus()
        end)

        -- right click call back
        note.EditButton:RegisterCallback(Mouse.eRClick, function()
            SetNote(note, nil, 0)
            SaveNote(index, nil, 0)
        end)

        -- commit call back
        note.EditNote:RegisterCommitCallback(
            function(editBox)
                local userInput = note.EditNote:GetText()
                local currentTurn = Game.GetCurrentGameTurn()
                SetNote(note, userInput, currentTurn)
                SaveNote(index, userInput, currentTurn)
            end)
    end

    Controls.NoteStack:CalculateSize()
    Controls.NoteStack:ReprocessAnchoring()
end

-- ===========================================================================
function SaveNote(index, text, turn)
    if IsEmpty(text) then
        CuiSettings:SetString(NOTE[index], EMPTY_NOTE)
        CuiSettings:SetNumber(NOTE_TURN[index], 0)
    else
        CuiSettings:SetString(NOTE[index], text)
        CuiSettings:SetNumber(NOTE_TURN[index], turn)
    end
end

-- ===========================================================================
function IsEmpty(text)
    if text == nil then return true end
    if text == EMPTY_NOTE then return true end
    if string.gsub(text, "^%s*(.-)%s*$", "%1") == nil then return true end
    return false
end

-- ===========================================================================
function SetNote(note, text, turn)
    note.EditNote:SetHide(true)
    if IsEmpty(text) then
        note.Overview:SetText(EMPTY_NOTE)
        note.Overview:SetColorByName("Gray")
        turn = 0
    else
        note.Overview:SetText(text)
        note.Overview:SetColorByName("White")
    end
    note.Overview:SetHide(false)

    if turn == 0 then
        note.LastEdit:SetText("")
    else
        note.LastEdit:SetText(Locale.Lookup("LOC_CUI_NOTE_LAST_EDIT", turn))
    end
end

-- ===========================================================================
function CloseOtherPanel()
    LuaEvents.LaunchBar_CloseTechTree()
    LuaEvents.LaunchBar_CloseCivicsTree()
    LuaEvents.LaunchBar_CloseGovernmentPanel()
    LuaEvents.LaunchBar_CloseReligionPanel()
    LuaEvents.LaunchBar_CloseGreatPeoplePopup()
    LuaEvents.LaunchBar_CloseGreatWorksOverview()

    if isExpansion1 then
        LuaEvents.GovernorPanel_Close()
        LuaEvents.HistoricMoments_Close()
    end

    if isExpansion2 then LuaEvents.Launchbar_Expansion2_ClimateScreen_Close() end
end

-- ===========================================================================
function Open()
    if (Game.GetLocalPlayer() == -1) then return end
    CloseOtherPanel()

    if not UIManager:IsInPopupQueue(ContextPtr) then
        local kParameters = {}
        kParameters.RenderAtCurrentParent = true
        kParameters.InputAtCurrentParent = true
        kParameters.AlwaysVisibleInQueue = true
        UIManager:QueuePopup(ContextPtr, PopupPriority.Low, kParameters)
        UI.PlaySound("UI_Screen_Open")
    end

    PopulateNoteList()

    Controls.Vignette:SetSizeY(windowHeight)
    -- FullScreenVignetteConsumer
    Controls.ScreenAnimIn:SetToBeginning()
    Controls.ScreenAnimIn:Play()
end

-- ===========================================================================
function Close()
    if not ContextPtr:IsHidden() then UI.PlaySound("UI_Screen_Close") end

    UIManager:DequeuePopup(ContextPtr)
end

-- ===========================================================================
function ToggleNoteScreen()
    if ContextPtr:IsHidden() then
        Open()
    else
        Close()
    end
end

-- ===========================================================================
function OnInit(isReload)
    if isReload then if not ContextPtr:IsHidden() then Open() end end
end

-- ===========================================================================
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

-- ===========================================================================
function Initialize()
    ContextPtr:SetHide(true)
    ContextPtr:SetInitHandler(OnInit)
    ContextPtr:SetInputHandler(OnInputHandler, true)
    Controls.CloseButton:RegisterCallback(Mouse.eLClick, Close)
    Controls.CloseButton:RegisterCallback(Mouse.eMouseEnter, function()
        UI.PlaySound("Main_Menu_Mouse_Over")
    end)
    LuaEvents.Cui_ToggleNoteScreen.Add(ToggleNoteScreen)

    windowHeight = Controls.Vignette:GetSizeY() - TOP_PANEL_OFFSET
end
Initialize()
