-- ===========================================================================
--	HUD's Launch Bar XP1 
--	Copyright (c) 2017-2018 Firaxis Games
-- ===========================================================================

include("LaunchBar");
include("GameCapabilities");

-- ===========================================================================
--	CACHE BASE FUNCTIONS
-- ===========================================================================
BASE_LateInitialize         = LateInitialize;
BASE_CloseAllPopups         = CloseAllPopups;
BASE_OnInputActionTriggered = OnInputActionTriggered;
BASE_RefreshView            = RefreshView;
BASE_RealizeHookVisibility  = RealizeHookVisibility;

-- ===========================================================================
--	CONSTANTS: Keep these in sync with PrideMoments.lua
-- ===========================================================================
local MIN_INTEREST_LEVEL:number = 1; 
local PRIDE_MOMENT_HASH:number = DB.MakeHash("NOTIFICATION_PRIDE_MOMENT_RECORDED");


-- ===========================================================================
--	MEMBERS
-- ===========================================================================
local m_GovernorsInstance	:table = {};
local m_HistorianInstance	:table = {};
local m_isGovernorPanelOpen	:boolean = false;
local m_isHistoricMomentsOpen	:boolean = false;
local m_isGovernorsAvailable	:boolean = false;
local m_isHistoricMomentsAvailable:boolean = false;

local cui_LaunchItemAnimSpeed = 3; -- CUI

-- ===========================================================================
--	FUNCTIONS
-- ===========================================================================

-- ===========================================================================
function OnProcessNotification(playerID:number, notificationID:number, activatedByUser:boolean)
  if playerID == Game.GetLocalPlayer() then -- Was it for us?
    local pNotification = NotificationManager.Find(playerID, notificationID);
    if pNotification and pNotification:GetType() == PRIDE_MOMENT_HASH then
      RealizeHookVisibility();
    end
  end
end

-- ===========================================================================
--	Refresh Data and View
-- ===========================================================================
function RealizeHookVisibility()
  m_isGovernorsAvailable = isDebug or HasCapability("CAPABILITY_GOVERNORS");
  m_GovernorsInstance.LaunchItemButton:SetShow( m_isGovernorsAvailable );

  m_isHistoricMomentsAvailable = isDebug or HasCapability("CAPABILITY_HISTORIC_MOMENTS");
  m_HistorianInstance.LaunchItemButton:SetShow(m_isHistoricMomentsAvailable);

  BASE_RealizeHookVisibility();
end

-- ===========================================================================
--	Input Hotkey Event
-- ===========================================================================
function OnInputActionTriggered( actionId:number )
  BASE_OnInputActionTriggered( actionId );

  -- Always available, so advanced players can plan their acquisitions
  if ( actionId == Input.GetActionId("ToggleGovernors") ) then
    ToggleGovernors();
  end
  
  -- Always available, so players can see the new feature compared to the base game
  if ( actionId == Input.GetActionId("ToggleTimeline") ) then
    ToggleHistoricMoments();
  end
end

-- ===========================================================================
function CloseAllPopups()
  BASE_CloseAllPopups();
  LuaEvents.GovernorPanel_Close();
  LuaEvents.HistoricMoments_Close();
end

-- ===========================================================================
function ToggleGovernors()
  if not m_isGovernorPanelOpen then
    CloseAllPopups();
  end
  LuaEvents.GovernorPanel_Toggle();
end

-- ===========================================================================
function ToggleHistoricMoments()
  if not m_isHistoricMomentsOpen then
    CloseAllPopups();
  end
  LuaEvents.PrideMoments_ToggleTimeline();	
end

-- ===========================================================================
function OnGovernorPanelOpened()
  m_isGovernorPanelOpen = true;
  OnOpen();
end

-- ===========================================================================
function OnGovernorPanelClosed()
  m_isGovernorPanelOpen = false;
  RefreshGovernors();
  OnClose();
end

-- ===========================================================================
function OnHistoricMomentsOpened()
  m_isHistoricMomentsOpen = true;
  OnOpen();
end

-- ===========================================================================
function OnHistoricMomentsClosed()
  m_isHistoricMomentsOpen = false;
  OnClose();
end

-- ===========================================================================
function RefreshGovernors()
  if (Game.GetLocalPlayer() == -1) then return; end	-- Autoplay
  local pPlayer			:table   = Players[Game.GetLocalPlayer()];
  local pPlayerGovernors	:table	 = pPlayer:GetGovernors();
  local bCanAppoint		:boolean = pPlayerGovernors:CanAppoint();
  local bCanPromote		:boolean = pPlayerGovernors:CanPromote();
  -- CUI: blink anim
  if bCanAppoint or bCanPromote then
    m_GovernorsInstance.LaunchItemAnim:SetSpeed(cui_LaunchItemAnimSpeed);
    m_GovernorsInstance.LaunchItemAnim:Play();
  else
    m_GovernorsInstance.LaunchItemAnim:SetSpeed(0);
    m_GovernorsInstance.LaunchItemAnim:SetToBeginning();
    m_GovernorsInstance.LaunchItemAnim:Stop();
  end
  --
  m_GovernorsInstance.AlertIndicator:SetShow(bCanAppoint or bCanPromote);
  m_GovernorsInstance.AlertIndicator:SetToolTipString((bCanAppoint or bCanPromote) and Locale.Lookup("LOC_GOVERNOR_ACTION_AVAILABLE") or nil );
end

-- ===========================================================================
function RefreshView()
  if Game.GetLocalPlayer() == -1 then return; end	-- Autoplay
  BASE_RefreshView();
  RefreshGovernors();
  if XP1_RefreshView == nil then		-- No MODs, then wrap this up.
    RealizeBacking();
  end
end

-- ===========================================================================
function LateInitialize()

  -- Governors Realted:
  ContextPtr:BuildInstanceForControl("LaunchBarItem", m_GovernorsInstance, Controls.ButtonStack );
  m_GovernorsInstance.LaunchItemButton:RegisterCallback(Mouse.eLClick, ToggleGovernors);
  m_GovernorsInstance.LaunchItemButton:SetTexture("LaunchBar_Hook_GovernorsButton");
  m_GovernorsInstance.LaunchItemButton:SetToolTipString(Locale.Lookup("LOC_HUD_LAUNCHBAR_GOVERNOR_BUTTON"));
  m_GovernorsInstance.LaunchItemIcon:SetTexture("LaunchBar_Hook_Governors");	
  ContextPtr:BuildInstanceForControl( "LaunchBarPinInstance", {}, Controls.ButtonStack );

  -- Historic Momements Related:
  ContextPtr:BuildInstanceForControl("LaunchBarItem", m_HistorianInstance, Controls.ButtonStack );
  m_HistorianInstance.LaunchItemButton:RegisterCallback(Mouse.eLClick, ToggleHistoricMoments);
  m_HistorianInstance.LaunchItemButton:SetTexture("LaunchBar_Hook_TimelineButton");
  m_HistorianInstance.LaunchItemButton:SetToolTipString(Locale.Lookup("LOC_HUD_LAUNCHBAR_HISTORIAN_BUTTON"));
  m_HistorianInstance.LaunchItemIcon:SetTexture("LaunchBar_Hook_Timeline");
  
  ContextPtr:BuildInstanceForControl( "LaunchBarPinInstance", {}, Controls.ButtonStack );

  Events.NotificationActivated.Add( OnProcessNotification );
  LuaEvents.GovernorPanel_Opened.Add( OnGovernorPanelOpened );
  LuaEvents.GovernorPanel_Closed.Add( OnGovernorPanelClosed );	
  LuaEvents.HistoricMoments_Opened.Add( OnHistoricMomentsOpened );
  LuaEvents.HistoricMoments_Closed.Add( OnHistoricMomentsClosed );	

  BASE_LateInitialize();	-- This forces a refresh view so only call after the above has occurred.
end
