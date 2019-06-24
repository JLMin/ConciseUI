-- ===========================================================================
--	HUD's Launch Bar XP2
--	Copyright (c) 2018-2019 Firaxis Games
-- ===========================================================================

include("LaunchBar_Expansion1");


-- ===========================================================================
--	CACHE BASE FUNCTIONS
-- ===========================================================================
XP1_LateInitialize			= LateInitialize;
XP1_CloseAllPopups			= CloseAllPopups;
XP1_OnInputActionTriggered  = OnInputActionTriggered;
XP1_RefreshView				= RefreshView;

-- ===========================================================================
--	MEMBERS
-- ===========================================================================
local m_isClimateOpen		:boolean = false;
local m_uiClimateInstance	:table = {};

local cui_LaunchItemAnimSpeed = 3; -- CUI

-- ===========================================================================
--	Lua Event
-- ===========================================================================
function OnClimateScreenOpened()
  m_isClimateOpen = true;
  if m_uiClimateInstance ~= nil then
    -- CUI
    m_uiClimateInstance.LaunchItemAnim:SetSpeed(0);
    m_uiClimateInstance.LaunchItemAnim:SetToBeginning();
    m_uiClimateInstance.LaunchItemAnim:Stop();
    --
    m_uiClimateInstance.AlertIndicator:SetHide(true);
  end
  OnOpen();
end


-- ===========================================================================
--	Lua Event
-- ===========================================================================
function OnClimateScreenClosed()
  m_isClimateOpen = false;
  OnClose();
end


-- ===========================================================================
--	UI Callback
-- ===========================================================================
function OnToggleClimateScreen()
  if not m_isClimateOpen then
    CloseAllPopups();
  end
  LuaEvents.Launchbar_ToggleClimateScreen();	
end

-- ===========================================================================
function CloseAllPopups()
  XP1_CloseAllPopups();
  LuaEvents.Launchbar_Expansion2_ClimateScreen_Close();
end

-- ===========================================================================
function RefreshClimate()
  local kCurrentEvent:table = GameRandomEvents.GetCurrentTurnEvent();
  if kCurrentEvent ~= nil then
    local kCurrentEventDef:table = GameInfo.RandomEvents[kCurrentEvent.RandomEvent];
    if kCurrentEventDef ~= nil then
      if kCurrentEventDef.EffectOperatorType == "SEA_LEVEL" then
        m_uiClimateInstance.AlertIndicator:SetHide(false);
      end
    end
  end
end

-- ===========================================================================
function RefreshView()
  XP1_RefreshView();
  RefreshClimate();
  if XP2_RefreshView == nil then	-- No (more) MODs, then wrap this up.
    RealizeBacking();
  end
end

-- ===========================================================================
--	Input Hotkey Event
-- ===========================================================================
function OnInputActionTriggered( actionId:number )
  XP1_OnInputActionTriggered( actionId );

  -- Always available, so advanced players can plan their acquisitions
  if ( actionId == Input.GetActionId("ToggleWorldClimate") ) then
    OnToggleClimateScreen();
  end
end

-- ===========================================================================
function LateInitialize()

  -- Climate Related:
  if GameCapabilities.HasCapability("CAPABILITY_WORLD_CLIMATE_VIEW") then
    ContextPtr:BuildInstanceForControl("LaunchBarItem", m_uiClimateInstance, Controls.ButtonStack );
    m_uiClimateInstance.LaunchItemButton:RegisterCallback(Mouse.eLClick, OnToggleClimateScreen);
    m_uiClimateInstance.LaunchItemButton:SetTexture("LaunchBar_Hook_GovernmentButton");
    m_uiClimateInstance.LaunchItemButton:SetToolTipString(Locale.Lookup("LOC_LAUNCHBAR_CLIMATE_PROGRESS_TOOLTIP"));
    m_uiClimateInstance.LaunchItemIcon:SetTexture("LaunchBar_Hook_Climate");
    m_uiClimateInstance.AlertIndicator:SetToolTipString(Locale.Lookup("LOC_CLIMATE_LAUNCHBAR_BANG_TOOLTIP"));

    ContextPtr:BuildInstanceForControl( "LaunchBarPinInstance", {}, Controls.ButtonStack );

    LuaEvents.ClimateScreen_Opened.Add( OnClimateScreenOpened );
    LuaEvents.ClimateScreen_Closed.Add( OnClimateScreenClosed );
  end

  XP1_LateInitialize();	-- This forces a refresh view so only call after the above has occurred.
end
