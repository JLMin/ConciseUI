-- ===========================================================================
-- Concise UI
-- cui_unitlist_button.lua
-- ===========================================================================

local isAttached = false
local unitListButtonInstance = {}
local pipInstance = {}

-- Concise UI ----------------------------------------------------------------
function OnToggleUnitList()
    LuaEvents.CuiToggleUnitList()
end

-- Concise UI ----------------------------------------------------------------
function AttachToTopPanel()
    if not isAttached then
        local buttonStack = ContextPtr:LookUpControl("/InGame/LaunchBar/ButtonStack")
        ContextPtr:BuildInstanceForControl("CuiUnitList", unitListButtonInstance, buttonStack)
        ContextPtr:BuildInstanceForControl("Pip", pipInstance, buttonStack)

        unitListButtonInstance.UnitListButton:RegisterCallback(Mouse.eLClick, OnToggleUnitList)
        unitListButtonInstance.UnitListButton:SetToolTipString(Locale.Lookup("LOC_PEDIA_UNITS_TITLE"))

        local x, y, sheet = IconManager:FindIconAtlas("ICON_CIVIC_NATIONALISM", 42)
        unitListButtonInstance.UnitListIcon:SetTexture(x, y, sheet)
        unitListButtonInstance.UnitListIcon:SetColorByName("White")

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

    if actionId == Input.GetActionId("CuiActionToggleUnitList") then
        OnToggleUnitList()
    end
end

-- Concise UI ----------------------------------------------------------------
function Initialize()
    ContextPtr:SetHide(true)

    Events.LoadGameViewStateDone.Add(AttachToTopPanel)
    Events.InputActionTriggered.Add(CuiOnIngameAction)
end
Initialize()
