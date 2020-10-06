-- ===========================================================================
-- Concise UI
-- cui_note_button.lua
-- ===========================================================================

local isAttached = false
local notesButtonInstance = {}
local pipInstance = {}

-- Concise UI ----------------------------------------------------------------
function OnToggleNoteScreen()
    LuaEvents.Cui_ToggleNoteScreen()
end

-- Concise UI ----------------------------------------------------------------
function AttachToTopPanel()
    if not isAttached then
        local buttonStack = ContextPtr:LookUpControl("/InGame/LaunchBar/ButtonStack")
        ContextPtr:BuildInstanceForControl("CuiNotes", notesButtonInstance, buttonStack)
        ContextPtr:BuildInstanceForControl("Pip", pipInstance, buttonStack)

        notesButtonInstance.NotesButton:RegisterCallback(Mouse.eLClick, OnToggleNoteScreen)
        notesButtonInstance.NotesButton:SetToolTipString(Locale.Lookup("LOC_CUI_NOTES"))

        local x, y, sheet = IconManager:FindIconAtlas("ICON_CIVIC_DIPLOMATIC_SERVICE", 42)
        notesButtonInstance.NotesIcon:SetTexture(x, y, sheet)
        notesButtonInstance.NotesIcon:SetColorByName("White")

        buttonStack:CalculateSize()

        local backing = ContextPtr:LookUpControl("/InGame/LaunchBar/LaunchBacking")
        backing:SetSizeX(buttonStack:GetSizeX() + 116)

        local backingTile = ContextPtr:LookUpControl("/InGame/LaunchBar/LaunchBackingTile")
        backingTile:SetSizeX(buttonStack:GetSizeX() - 20)

        LuaEvents.LaunchBar_Resize(buttonStack:GetSizeX())
        isAttached = true
    end
end

-- Concise UI ----------------------------------------------------------------
function CuiOnIngameAction(actionId)
    if Game.GetLocalPlayer() == -1 then
        return
    end

    if actionId == Input.GetActionId("CuiActionToggleNotes") then
        OnToggleNoteScreen()
    end
end

-- Concise UI ----------------------------------------------------------------
function Initialize()
    ContextPtr:SetHide(true)

    Events.LoadGameViewStateDone.Add(AttachToTopPanel)
    Events.InputActionTriggered.Add(CuiOnIngameAction)
end
Initialize()
