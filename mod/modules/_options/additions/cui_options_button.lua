-- ===========================================================================
-- Cui Options Button
-- eudaimonia, 11/10/2019
-- ===========================================================================
include("cui_helper")
include("cui_settings")
include("cui_update")

-- ---------------------------------------------------------------------------
local isAttached = false

-- ---------------------------------------------------------------------------
function OpenOptionMenu()
  LuaEvents.CuiToggleOptions()
end

-- ---------------------------------------------------------------------------
function SetupUI()
  Controls.Version:SetText(CuiVersion)
  Controls.Version:SetToolTipString(VersionDetail)
  CuiRegCallback(Controls.CuiOptionButton, OpenOptionMenu, OpenOptionMenu)
end

-- ---------------------------------------------------------------------------
function OnMinimapResize()
  if isAttached then
    local minimap = ContextPtr:LookUpControl("/InGame/MinimapPanel/MiniMap/MinimapContainer")
    Controls.CuiOptionContainer:SetOffsetX(minimap:GetSizeX() + 10)
  end
end

-- ---------------------------------------------------------------------------
function AttachToMinimap()
  if not isAttached then
    local minimap = ContextPtr:LookUpControl("/InGame/MinimapPanel/MiniMap/MinimapContainer")
    Controls.CuiOptionContainer:ChangeParent(minimap)
    Controls.CuiOptionContainer:SetOffsetX(minimap:GetSizeX() + 10)
    SetupUI()
    isAttached = true
  end
end

-- ---------------------------------------------------------------------------
function Initialize()
  ContextPtr:SetHide(true)
  SetupUI()
  Events.LoadGameViewStateDone.Add(AttachToMinimap)
  LuaEvents.CuiOnMinimapResize.Add(OnMinimapResize)
end
Initialize()
