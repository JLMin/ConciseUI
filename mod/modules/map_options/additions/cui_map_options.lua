-- ===========================================================================
-- cui_map_options.lua
-- ===========================================================================

include("cui_settings")

local isAttached = false

-- CUI -----------------------------------------------------------------------
function AttachToTopOptionStack()
    if not isAttached then
        local optionPanel = ContextPtr:LookUpControl("/InGame/MinimapPanel/MapOptionsPanel")
        local optionStack = ContextPtr:LookUpControl("/InGame/MinimapPanel/MapOptionsPanel/MapOptionsStack")
        --
        Controls.ToggleImproved:ChangeParent(optionStack)
        Controls.ToggleCityBanners:ChangeParent(optionStack)
        Controls.ToggleTraderIcons:ChangeParent(optionStack)
        Controls.ToggleReligionIcons:ChangeParent(optionStack)
        Controls.ToggleUnitFlags:ChangeParent(optionStack)
        --
        optionStack:AddChildAtIndex(Controls.ToggleImproved, 2)
        optionStack:AddChildAtIndex(Controls.ToggleCityBanners, 4)
        optionStack:AddChildAtIndex(Controls.ToggleTraderIcons, 4)
        optionStack:AddChildAtIndex(Controls.ToggleReligionIcons, 4)
        optionStack:AddChildAtIndex(Controls.ToggleUnitFlags, 4)
        --
        optionStack:ReprocessAnchoring()
        optionStack:CalculateSize()
        optionStack:SetOffsetX(30)
        optionPanel:SetSizeX(optionStack:GetSizeX() + 45)
        isAttached = true
    end
    CuiRefreshMinimapOptions()
end

-- CUI -----------------------------------------------------------------------
function CuiOnToggleImproved()
    local b = CuiSettings:ReverseAndGetBoolean(CuiSettings.SHOW_IMPROVES)
    LuaEvents.CuiToggleImprovedIcons()
    CuiRefreshMinimapOptions()
end

-- CUI -----------------------------------------------------------------------
function CuiOnToggleCityBanners()
    local b = CuiSettings:ReverseAndGetBoolean(CuiSettings.SHOW_CITYS)
    ContextPtr:LookUpControl("/InGame/CityBannerManager"):SetHide(not b)
    CuiRefreshMinimapOptions()
end

-- CUI -----------------------------------------------------------------------
function CuiOnToggleTrader()
    local b = CuiSettings:ReverseAndGetBoolean(CuiSettings.SHOW_TRADERS)
    LuaEvents.CuiToggleTraderIcons()
    CuiRefreshMinimapOptions()
end

-- CUI -----------------------------------------------------------------------
function CuiOnToggleReligion()
    local b = CuiSettings:ReverseAndGetBoolean(CuiSettings.SHOW_RELIGIONS)
    LuaEvents.CuiToggleReligionIcons()
    CuiRefreshMinimapOptions()
end

-- CUI -----------------------------------------------------------------------
function CuiOnToggleUnitFlags()
    local b = CuiSettings:ReverseAndGetBoolean(CuiSettings.SHOW_UNITS)
    ContextPtr:LookUpControl("/InGame/UnitFlagManager"):SetHide(not b)
    CuiRefreshMinimapOptions()
end

-- CUI -----------------------------------------------------------------------
function CuiRefreshMinimapOptions()
    Controls.ToggleImproved:SetCheck(CuiSettings:GetBoolean(CuiSettings.SHOW_IMPROVES))
    Controls.ToggleCityBanners:SetCheck(CuiSettings:GetBoolean(CuiSettings.SHOW_CITYS))
    Controls.ToggleTraderIcons:SetCheck(CuiSettings:GetBoolean(CuiSettings.SHOW_TRADERS))
    Controls.ToggleReligionIcons:SetCheck(CuiSettings:GetBoolean(CuiSettings.SHOW_RELIGIONS))
    Controls.ToggleUnitFlags:SetCheck(CuiSettings:GetBoolean(CuiSettings.SHOW_UNITS))
    LuaEvents.MinimapPanel_RefreshMinimapOptions()
end

-- CUI -----------------------------------------------------------------------
function CuiOnIngameAction(actionId)
    if (Game.GetLocalPlayer() == -1) then
        return
    end
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

-- CUI -----------------------------------------------------------------------
function Initialize()
    ContextPtr:SetHide(true)
    Events.InputActionTriggered.Add(CuiOnIngameAction)
    Events.LoadGameViewStateDone.Add(AttachToTopOptionStack)
    -- unit and city shows on default
    CuiSettings:SetBoolean(CuiSettings.SHOW_UNITS, true)
    CuiSettings:SetBoolean(CuiSettings.SHOW_CITYS, true)
    Controls.ToggleImproved:RegisterCallback(Mouse.eLClick, CuiOnToggleImproved)
    Controls.ToggleCityBanners:RegisterCallback(Mouse.eLClick, CuiOnToggleCityBanners)
    Controls.ToggleUnitFlags:RegisterCallback(Mouse.eLClick, CuiOnToggleUnitFlags)
    Controls.ToggleTraderIcons:RegisterCallback(Mouse.eLClick, CuiOnToggleTrader)
    Controls.ToggleReligionIcons:RegisterCallback(Mouse.eLClick, CuiOnToggleReligion)
end
Initialize()
