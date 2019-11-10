-- ===========================================================================
-- Cui Options Button
-- eudaimonia, 11/10/2019
-- ===========================================================================
include("cui_helper")
include("cui_settings")

-- ---------------------------------------------------------------------------
local isAttached = false

-- ---------------------------------------------------------------------------
function OpenOptionMenu() LuaEvents.CuiToggleOptions() end

-- ---------------------------------------------------------------------------
function SetupUI() end

-- ---------------------------------------------------------------------------
function OnMinimapResize()
    if isAttached then
        local minimap = ContextPtr:LookUpControl(
                            "/InGame/MinimapPanel/MiniMap/MinimapContainer")
        Controls.CuiOptionContainer:SetOffsetX(minimap:GetSizeX() + 10)
    end
end

-- ---------------------------------------------------------------------------
function AttachToMinimap()
    if not isAttached then
        local minimap = ContextPtr:LookUpControl(
                            "/InGame/MinimapPanel/MiniMap/MinimapContainer")
        Controls.CuiOptionContainer:ChangeParent(minimap)
        Controls.CuiOptionContainer:SetOffsetX(minimap:GetSizeX() + 10)
        SetupUI()
        isAttached = true
    end
end

-- ---------------------------------------------------------------------------
function Initialize()
    ContextPtr:SetHide(true)
    CuiRegCallback(Controls.CuiOptionButton, OpenOptionMenu, OpenOptionMenu)
    Events.LoadGameViewStateDone.Add(AttachToMinimap)
    LuaEvents.CuiOnMinimapResize.Add(OnMinimapResize)
end
Initialize()
