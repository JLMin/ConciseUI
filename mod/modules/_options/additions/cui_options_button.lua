-- ===========================================================================
-- Concise UI
-- cui_options_button.lua
-- ===========================================================================

include("cui_helper")
include("cui_settings")
include("cui_update")

-- Concise UI ----------------------------------------------------------------
local isAttached = false

-- Concise UI ----------------------------------------------------------------
function OpenOptionMenu()
    LuaEvents.CuiToggleOptions()
end

-- Concise UI ----------------------------------------------------------------
function SetupUI()
    Controls.Version:SetText(CuiVersion)
    Controls.Version:SetToolTipString(VersionDetail)
    CuiRegCallback(Controls.CuiOptionButton, OpenOptionMenu, OpenOptionMenu)
end

-- Concise UI ----------------------------------------------------------------
function OnMinimapResize()
    if isAttached then
        local minimap = ContextPtr:LookUpControl("/InGame/MinimapPanel/MiniMap/MinimapContainer")
        Controls.CuiOptionContainer:SetOffsetX(minimap:GetSizeX() + 10)
    end
end

-- Concise UI ----------------------------------------------------------------
function AttachToMinimap()
    if not isAttached then
        local minimap = ContextPtr:LookUpControl("/InGame/MinimapPanel/MiniMap/MinimapContainer")
        Controls.CuiOptionContainer:ChangeParent(minimap)
        Controls.CuiOptionContainer:SetOffsetX(minimap:GetSizeX() + 10)
        SetupUI()
        isAttached = true
    end
end

-- Concise UI ----------------------------------------------------------------
function Initialize()
    ContextPtr:SetHide(true)
    SetupUI()
    Events.LoadGameViewStateDone.Add(AttachToMinimap)
    LuaEvents.CuiOnMinimapResize.Add(OnMinimapResize)
end
Initialize()
