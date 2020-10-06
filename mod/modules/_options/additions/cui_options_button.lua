-- ===========================================================================
-- cui_options_button.lua
-- ===========================================================================

include("cui_utils")
include("cui_settings")
include("cui_update")

-- CUI -----------------------------------------------------------------------
local isAttached = false

-- CUI -----------------------------------------------------------------------
function OpenOptionMenu()
    LuaEvents.CuiToggleOptions()
end

-- CUI -----------------------------------------------------------------------
function SetupUI()
    Controls.Version:SetText(CuiVersion)
    Controls.Version:SetToolTipString(VersionDetail)
    CuiRegCallback(Controls.CuiOptionButton, OpenOptionMenu, OpenOptionMenu)
end

-- CUI -----------------------------------------------------------------------
function OnMinimapResize()
    if isAttached then
        local minimap = ContextPtr:LookUpControl("/InGame/MinimapPanel/MiniMap/MinimapContainer")
        Controls.CuiOptionContainer:SetOffsetX(minimap:GetSizeX() + 10)
    end
end

-- CUI -----------------------------------------------------------------------
function AttachToMinimap()
    if not isAttached then
        local minimap = ContextPtr:LookUpControl("/InGame/MinimapPanel/MiniMap/MinimapContainer")
        Controls.CuiOptionContainer:ChangeParent(minimap)
        Controls.CuiOptionContainer:SetOffsetX(minimap:GetSizeX() + 10)
        SetupUI()
        isAttached = true
    end
end

-- CUI -----------------------------------------------------------------------
function Initialize()
    ContextPtr:SetHide(true)
    SetupUI()
    Events.LoadGameViewStateDone.Add(AttachToMinimap)
    LuaEvents.CuiOnMinimapResize.Add(OnMinimapResize)
end
Initialize()
