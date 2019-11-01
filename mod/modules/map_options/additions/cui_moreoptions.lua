-- ===========================================================================
-- Cui More Map Options
-- eudaimonia, 3/6/2019
-- ===========================================================================
include("cui_settings") -- CUI

local isAttached = false

-- ===========================================================================
function AttachToTopOptionStack()
    if not isAttached then
        local optionPanel = ContextPtr:LookUpControl(
                                "/InGame/MinimapPanel/MapOptionsPanel")
        local optionStack = ContextPtr:LookUpControl(
                                "/InGame/MinimapPanel/MapOptionsPanel/MapOptionsStack")
        --
        Controls.ToggleImproved:ChangeParent(optionStack)
        Controls.ToggleCityBanners:ChangeParent(optionStack)
        Controls.ToggleTraderIcons:ChangeParent(optionStack)
        Controls.ToggleReligionIcons:ChangeParent(optionStack)
        Controls.ToggleUnitFlags:ChangeParent(optionStack)
        --
        optionStack:AddChildAtIndex(Controls.ToggleImproved,      2)
        optionStack:AddChildAtIndex(Controls.ToggleCityBanners,   4)
        optionStack:AddChildAtIndex(Controls.ToggleTraderIcons,   4)
        optionStack:AddChildAtIndex(Controls.ToggleReligionIcons, 4)
        optionStack:AddChildAtIndex(Controls.ToggleUnitFlags,     4)
        --
        optionStack:ReprocessAnchoring()
        optionStack:CalculateSize()
        optionStack:SetOffsetX(30)
        optionPanel:SetSizeX(optionStack:GetSizeX() + 45)
        isAttached = true
    end
    CuiRefreshMinimapOptions()
end

-- ===========================================================================
function CuiOnToggleImproved()
    local b = CuiSettings:ReverseAndGetBoolean(CuiSettings.SHOW_IMPROVED)
    LuaEvents.CuiToggleImprovedIcons()
    CuiRefreshMinimapOptions()
end

-- ===========================================================================
function CuiOnToggleCityBanners()
    local b = CuiSettings:ReverseAndGetBoolean(CuiSettings.SHOW_CITY_BANNER)
    ContextPtr:LookUpControl("/InGame/CityBannerManager"):SetHide(not b)
    CuiRefreshMinimapOptions()
end

-- ===========================================================================
function CuiOnToggleTrader()
    local b = CuiSettings:ReverseAndGetBoolean(CuiSettings.SHOW_TRADERS)
    LuaEvents.CuiToggleTraderIcons()
    CuiRefreshMinimapOptions()
end

-- ===========================================================================
function CuiOnToggleReligion()
  local b = CuiSettings:ReverseAndGetBoolean(CuiSettings.SHOW_RELIGIONS)
  LuaEvents.CuiToggleReligionIcons()
  CuiRefreshMinimapOptions()
end

-- ===========================================================================
function CuiOnToggleUnitFlags()
    local b = CuiSettings:ReverseAndGetBoolean(CuiSettings.SHOW_UNIT_FLAG)
    ContextPtr:LookUpControl("/InGame/UnitFlagManager"):SetHide(not b)
    CuiRefreshMinimapOptions()
end

-- ===========================================================================
function CuiRefreshMinimapOptions()
    Controls.ToggleImproved     :SetCheck(CuiSettings:GetBoolean(CuiSettings.SHOW_IMPROVED))
    Controls.ToggleCityBanners  :SetCheck(CuiSettings:GetBoolean(CuiSettings.SHOW_CITY_BANNER))
    Controls.ToggleTraderIcons  :SetCheck(CuiSettings:GetBoolean(CuiSettings.SHOW_TRADERS))
    Controls.ToggleReligionIcons:SetCheck(CuiSettings:GetBoolean(CuiSettings.SHOW_RELIGIONS))
    Controls.ToggleUnitFlags    :SetCheck(CuiSettings:GetBoolean(CuiSettings.SHOW_UNIT_FLAG))
    LuaEvents.MinimapPanel_RefreshMinimapOptions()
end

-- ===========================================================================
function CuiOnIngameAction(actionId)
    if (Game.GetLocalPlayer() == -1) then return end
    if actionId == Input.GetActionId("CuiActionToggleImproved") then
        CuiOnToggleImproved()
        UI.PlaySound("Play_UI_Click")
    end
    if actionId == Input.GetActionId("CuiActionToggleCityBanners") then
        CuiOnToggleCityBanners()
        UI.PlaySound("Play_UI_Click")
    end
    if actionId == Input.GetActionId("CuiActionToggleTraders") then
        CuiOnToggleTrader()
        UI.PlaySound("Play_UI_Click")
    end
    if actionId == Input.GetActionId("CuiActionToggleReligions") then
      CuiOnToggleReligion()
      UI.PlaySound("Play_UI_Click")
    end
    if actionId == Input.GetActionId("CuiActionToggleUnitFlags") then
        CuiOnToggleUnitFlags()
        UI.PlaySound("Play_UI_Click")
    end
end

-- ===========================================================================
function Initialize()
    ContextPtr:SetHide(true)
    Events.InputActionTriggered.Add(CuiOnIngameAction)
    Events.LoadGameViewStateDone.Add(AttachToTopOptionStack)
    -- unit and city shows on default
    CuiSettings:SetBoolean(CuiSettings.SHOW_UNIT_FLAG, true)
    CuiSettings:SetBoolean(CuiSettings.SHOW_CITY_BANNER, true)
    Controls.ToggleImproved     :RegisterCallback(Mouse.eLClick, CuiOnToggleImproved)
    Controls.ToggleCityBanners  :RegisterCallback(Mouse.eLClick, CuiOnToggleCityBanners)
    Controls.ToggleUnitFlags    :RegisterCallback(Mouse.eLClick, CuiOnToggleUnitFlags)
    Controls.ToggleTraderIcons  :RegisterCallback(Mouse.eLClick, CuiOnToggleTrader)
    Controls.ToggleReligionIcons:RegisterCallback(Mouse.eLClick, CuiOnToggleReligion)
end
Initialize()
