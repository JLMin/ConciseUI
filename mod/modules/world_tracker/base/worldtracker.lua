-- Copyright 2014-2019, Firaxis Games.

--	Hotloading note: The World Tracker button check now positions based on how many hooks are showing.
--	You'll need to save "LaunchBar" to see the tracker button appear.

include("InstanceManager");
include("TechAndCivicSupport");
include("SupportFunctions");
include("GameCapabilities");

g_TrackedItems = {};		-- Populated by WorldTrackerItems_* scripts;
include("WorldTrackerItem_", true);

-- Include self contained additional tabs
g_ExtraIconData = {};
include("CivicsTreeIconLoader_", true);

include("cui_utils"); -- CUI
include("cui_settings"); -- CUI
include("cui_tracker_support"); -- CUI

-- ===========================================================================
--	CONSTANTS
-- ===========================================================================
local RELOAD_CACHE_ID					:string = "WorldTracker"; -- Must be unique (usually the same as the file name)
local CHAT_COLLAPSED_SIZE				:number = 118;
local MAX_BEFORE_TRUNC_TRACKER			:number = 180;
local MAX_BEFORE_TRUNC_CHECK			:number = 160;
local MAX_BEFORE_TRUNC_TITLE			:number = 225;
local LAUNCH_BAR_PADDING				:number = 50;
local STARTING_TRACKER_OPTIONS_OFFSET	:number = 75;
local WORLD_TRACKER_PANEL_WIDTH			:number = 300;
local MINIMAP_PADDING					:number = 40;


-- ===========================================================================
--	GLOBALS
-- ===========================================================================
g_TrackedInstances	= {};				-- Any instances created as a result of g_trackedItems

-- ===========================================================================
--	MEMBERS
-- ===========================================================================
local m_hideAll					:boolean = false;
local m_hideChat				:boolean = false;
local m_hideCivics				:boolean = false;
local m_hideResearch			:boolean = false;

local m_dropdownExpanded		:boolean = false;
local m_unreadChatMsgs			:number  = 0;		-- number of chat messages unseen due to the chat panel being hidden.

local m_researchInstance		:table	 = {};		-- Single instance wired up for the currently being researched tech
local m_civicsInstance			:table	 = {};		-- Single instance wired up for the currently being researched civic
local m_CachedModifiers			:table	 = {};

local m_currentResearchID		:number = -1;
local m_lastResearchCompletedID	:number = -1;
local m_currentCivicID			:number = -1;
local m_lastCivicCompletedID	:number = -1;
local m_minimapSize				:number = 199;
local m_numEmergencies			:number = 0;
local m_isTrackerAlwaysCollapsed:boolean = false;	-- Once the launch bar extends past the width of the world tracker, we always show the collapsed version of the backing for the tracker element
local m_isDirty					:boolean = false;	-- Note: renamed from "refresh" which is a built in Forge mechanism; this is based on a gamecore event to check not frame update
local m_isMinimapCollapsed		:boolean = false;
local m_isChatExpanded			:boolean = false;
local m_startingChatSize		:number = 0;

-- CUI >> tracker
local cui_TrackBar = {};

local wonderData = {};
local resourceData = {};
local borderData = {};
local tradeData = {};

local CuiWonderTT = {};
local CuiResourceTT = {};
local CuiBorderTT = {};
local CuiTradeTT = {};

TTManager:GetTypeControlTable("CuiWonderTT", CuiWonderTT);
TTManager:GetTypeControlTable("CuiResourceTT", CuiResourceTT);
TTManager:GetTypeControlTable("CuiBorderTT", CuiBorderTT);
TTManager:GetTypeControlTable("CuiTradeTT", CuiTradeTT);

local wonderInstance      = InstanceManager:new("WonderInstance",      "Top", Controls.WonderInstanceContainer);
local colorInstance       = InstanceManager:new("ColorInstance",       "Top", Controls.ColorInstanceContainer);
local resourceInstance    = InstanceManager:new("ResourceInstance",    "Top", Controls.ResourceInstanceContainer);
local resourceBarInstance = InstanceManager:new("ResourceBarInstance", "Top", Controls.ResourceBarInstanceContainer);
local borderInstance      = InstanceManager:new("BorderInstance",      "Top", Controls.BorderInstanceContainer);
local tradeInstance       = InstanceManager:new("TradeInstance",       "Top", Controls.TradeInstanceContainer);
-- << CUI

-- CUI >> gossip combat log
local cui_GossipPanel = {};
local cui_GossipCount = 0;
local cui_GossipLogs = {};

local cui_CombatPanel = {};
local cui_CombatCount = 0;
local cui_CombatLogs = {};

local m_useGossipLog = CuiSettings:GetBoolean(CuiSettings.WT_GOSSIP_LOG);
local m_useCombatLog = CuiSettings:GetBoolean(CuiSettings.WT_COMBAT_LOG);
local cui_MaxLog = 50;
local cui_LogPanelStatus = {};
cui_LogPanelStatus[1] = {main = 28, log = 24};
cui_LogPanelStatus[2] = {main = 82, log = 78};
cui_LogPanelStatus[3] = {main = 282, log = 278};
local cui_GossipState = CuiSettings:GetNumber(CuiSettings.GOSSIP_LOG_STATE);
local cui_CombatState = CuiSettings:GetNumber(CuiSettings.COMBAT_LOG_STATE);
-- << CUI

-- ===========================================================================
--	FUNCTIONS
-- ===========================================================================

-- ===========================================================================
--	The following are a accessors for Expansions/MODs so they can obtain status
--	of the common panels but don't have access to toggling them.
-- ===========================================================================
function IsChatHidden()			return m_hideChat;		end
function IsResearchHidden()		return m_hideResearch;	end
function IsCivicsHidden()		return m_hideCivics;	end

-- ===========================================================================
--	Checks all panels, static and dynamic as to whether or not they are hidden.
--	Returns true if they are.
-- ===========================================================================
function IsAllPanelsHidden()
	local isHide	:boolean = false;
	local uiChildren:table = Controls.PanelStack:GetChildren();
	for i,uiChild in ipairs(uiChildren) do
		if uiChild:IsVisible() then
			return false;
		end
	end
	return true;
end

-- ===========================================================================
function RealizeEmptyMessage()
	-- First a quick check if all native panels are hidden.
	if m_hideChat and m_hideCivics and m_hideResearch then
		local isAllPanelsHidden:boolean = IsAllPanelsHidden();	-- more expensive iteration
		Controls.EmptyPanel:SetHide( isAllPanelsHidden==false );
	else
		Controls.EmptyPanel:SetHide(true);
	end
end

-- ===========================================================================
function ToggleDropdown()
	if m_dropdownExpanded then
		m_dropdownExpanded = false;
		Controls.DropdownAnim:Reverse();
		Controls.DropdownAnim:Play();
		UI.PlaySound("Tech_Tray_Slide_Closed");
	else
		UI.PlaySound("Tech_Tray_Slide_Open");
		m_dropdownExpanded = true;
		Controls.DropdownAnim:SetToBeginning();
		Controls.DropdownAnim:Play();
	end
end

-- ===========================================================================
function ToggleAll(hideAll:boolean)

	-- Do nothing if value didn't change
	if m_hideAll == hideAll then return; end

	m_hideAll = hideAll;

	if(not hideAll) then
		Controls.PanelStack:SetHide(false);
		UI.PlaySound("Tech_Tray_Slide_Open");
	end

	Controls.ToggleAllButton:SetCheck(not m_hideAll);

	if ( not m_isTrackerAlwaysCollapsed) then
		Controls.TrackerHeading:SetHide(hideAll);
		Controls.TrackerHeadingCollapsed:SetHide(not hideAll);
	else
		Controls.TrackerHeading:SetHide(true);
		Controls.TrackerHeadingCollapsed:SetHide(false);
	end

	if( hideAll ) then
		UI.PlaySound("Tech_Tray_Slide_Closed");
		if( m_dropdownExpanded ) then
			Controls.DropdownAnim:SetToBeginning();
			m_dropdownExpanded = false;
		end
	end

	Controls.WorldTrackerAlpha:Reverse();
	Controls.WorldTrackerSlide:Reverse();
	CheckUnreadChatMessageCount();

	LuaEvents.WorldTracker_ToggleCivicPanel(m_hideCivics or m_hideAll);
	LuaEvents.WorldTracker_ToggleResearchPanel(m_hideResearch or m_hideAll);
	if m_isChatExpanded then
		ResizeExpandedChatPanel();
	end
end

-- ===========================================================================
function OnWorldTrackerAnimationFinished()
	if(m_hideAll) then
		Controls.PanelStack:SetHide(true);
	end
end

-- ===========================================================================
-- When the launch bar is resized, make sure to adjust the world tracker
-- button position/size to accommodate it
-- ===========================================================================
function OnLaunchBarResized( buttonStackSize: number)
	Controls.TrackerHeading:SetSizeX(buttonStackSize + LAUNCH_BAR_PADDING);
	Controls.TrackerHeadingCollapsed:SetSizeX(buttonStackSize + LAUNCH_BAR_PADDING);
	if( buttonStackSize > WORLD_TRACKER_PANEL_WIDTH - LAUNCH_BAR_PADDING) then
		m_isTrackerAlwaysCollapsed = true;
		Controls.TrackerHeading:SetHide(true);
		Controls.TrackerHeadingCollapsed:SetHide(false);
	else
		m_isTrackerAlwaysCollapsed = false;
		Controls.TrackerHeading:SetHide(m_hideAll);
		Controls.TrackerHeadingCollapsed:SetHide(not m_hideAll);
	end
	Controls.ToggleAllButton:SetOffsetX(buttonStackSize - 7);
end

-- ===========================================================================
function RealizeStack()
	Controls.PanelStack:CalculateSize();
	if(m_hideAll) then ToggleAll(true); end
end

-- ===========================================================================
function UpdateResearchPanel( isHideResearch:boolean )

	-- If not an actual player (observer, tuner, etc...) then we're done here...
	local ePlayer		:number = Game.GetLocalPlayer();
	if (ePlayer == PlayerTypes.NONE or ePlayer == PlayerTypes.OBSERVER) then
		return;
	end
	local pPlayerConfig : table = PlayerConfigurations[ePlayer];

	if not HasCapability("CAPABILITY_TECH_CHOOSER") or not pPlayerConfig:IsAlive() then
		isHideResearch = true;
		Controls.ResearchCheck:SetHide(true);
	end
	if isHideResearch ~= nil and isHideResearch ~= m_hideResearch then
		LuaEvents.ChatPanel_OnResetDraggedChatPanel(); --Reset the chat panel so the mouse offset is correct for dragging
	end
	if isHideResearch ~= nil then
		m_hideResearch = isHideResearch;
	end

	m_researchInstance.MainPanel:SetHide( m_hideResearch );
	Controls.ResearchCheck:SetCheck( not m_hideResearch );
	LuaEvents.WorldTracker_ToggleResearchPanel(m_hideResearch or m_hideAll);
	RealizeEmptyMessage();
	RealizeStack();

	-- Set the technology to show (or -1 if none)...
	local iTech			:number = m_currentResearchID;
	if m_currentResearchID == -1 then
		iTech = m_lastResearchCompletedID;
	end
	local pPlayer		:table  = Players[ePlayer];
	local pPlayerTechs	:table	= pPlayer:GetTechs();
	local kTech			:table	= (iTech ~= -1) and GameInfo.Technologies[ iTech ] or nil;
	local kResearchData :table = GetResearchData( ePlayer, pPlayerTechs, kTech );
	if iTech ~= -1 then
		if m_currentResearchID == iTech then
			kResearchData.IsCurrent = true;
		elseif m_lastResearchCompletedID == iTech then
			kResearchData.IsLastCompleted = true;
		end
	end

	RealizeCurrentResearch( ePlayer, kResearchData, m_researchInstance);

	-- No tech started (or finished)
	if kResearchData == nil then
		m_researchInstance.TitleButton:SetHide( false );
		TruncateStringWithTooltip(m_researchInstance.TitleButton, MAX_BEFORE_TRUNC_TITLE, Locale.ToUpper(Locale.Lookup("LOC_WORLD_TRACKER_CHOOSE_RESEARCH")) );
    else
        -- CUI: add tooltip for research
        m_researchInstance.IconButton:SetToolTipString(Locale.Lookup(kResearchData.ToolTip));
	end
	if m_isChatExpanded then
		ResizeExpandedChatPanel();
	end
end

-- ===========================================================================
function UpdateCivicsPanel(hideCivics:boolean)

	-- If not an actual player (observer, tuner, etc...) then we're done here...
	local ePlayer		:number = Game.GetLocalPlayer();
	if (ePlayer == PlayerTypes.NONE or ePlayer == PlayerTypes.OBSERVER) then
		return;
	end
	local pPlayerConfig : table = PlayerConfigurations[ePlayer];

	if not HasCapability("CAPABILITY_CIVICS_CHOOSER") or (localPlayerID ~= PlayerTypes.NONE and not pPlayerConfig:IsAlive()) then
		hideCivics = true;
		Controls.CivicsCheck:SetHide(true);
	end
	if hideCivics ~= nil and hideCivics ~= m_hideCivics then
		LuaEvents.ChatPanel_OnResetDraggedChatPanel(); --Reset the chat panel so the mouse offset is correct for dragging
	end
	if hideCivics ~= nil then
		m_hideCivics = hideCivics;
	end

	m_civicsInstance.MainPanel:SetHide(m_hideCivics);
	Controls.CivicsCheck:SetCheck(not m_hideCivics);
	LuaEvents.WorldTracker_ToggleCivicPanel(m_hideCivics or m_hideAll);
	RealizeEmptyMessage();
	RealizeStack();

	-- Set the civic to show (or -1 if none)...
	local iCivic :number = m_currentCivicID;
	if iCivic == -1 then
		iCivic = m_lastCivicCompletedID;
	end
	local pPlayer		:table  = Players[ePlayer];
	local pPlayerCulture:table	= pPlayer:GetCulture();
	local kCivic		:table	= (iCivic ~= -1) and GameInfo.Civics[ iCivic ] or nil;
	local kCivicData	:table = GetCivicData( ePlayer, pPlayerCulture, kCivic );
	if iCivic ~= -1 then
		if m_currentCivicID == iCivic then
			kCivicData.IsCurrent = true;
		elseif m_lastCivicCompletedID == iCivic then
			kCivicData.IsLastCompleted = true;
		end
	end

	for _,iconData in pairs(g_ExtraIconData) do
		iconData:Reset();
	end
	RealizeCurrentCivic( ePlayer, kCivicData, m_civicsInstance, m_CachedModifiers );

	-- No civic started (or finished)
	if kCivicData == nil then
		m_civicsInstance.TitleButton:SetHide( false );
		TruncateStringWithTooltip(m_civicsInstance.TitleButton, MAX_BEFORE_TRUNC_TITLE, Locale.ToUpper(Locale.Lookup("LOC_WORLD_TRACKER_CHOOSE_CIVIC")) );
	else
		TruncateStringWithTooltip(m_civicsInstance.TitleButton, MAX_BEFORE_TRUNC_TITLE, m_civicsInstance.TitleButton:GetText() );
        -- CUI: add tooltip for civics
        m_civicsInstance.IconButton:SetToolTipString(Locale.Lookup(kCivicData.ToolTip));
	end
	if m_isChatExpanded then
		ResizeExpandedChatPanel();
	end
end

-- ===========================================================================
function UpdateChatPanel(hideChat:boolean)
	m_hideChat = hideChat;
	Controls.ChatPanel:SetHide(m_hideChat);
	Controls.ChatCheck:SetCheck(not m_hideChat);
	RealizeEmptyMessage();
	RealizeStack();

	CheckUnreadChatMessageCount();
end

-- ===========================================================================
function CheckUnreadChatMessageCount()
	-- Unhiding the chat panel resets the unread chat message count.
	if(not hideAll and not m_hideChat) then
		m_unreadChatMsgs = 0;
		UpdateUnreadChatMsgs();
		LuaEvents.WorldTracker_OnChatShown();
	end
end

-- ===========================================================================
function UpdateUnreadChatMsgs()
	if(GameConfiguration.IsPlayByCloud()) then
		Controls.ChatCheck:GetTextButton():SetText(Locale.Lookup("LOC_PLAY_BY_CLOUD_PANEL"));
	elseif(m_unreadChatMsgs > 0) then
		Controls.ChatCheck:GetTextButton():SetText(Locale.Lookup("LOC_HIDE_CHAT_PANEL_UNREAD_MESSAGES", m_unreadChatMsgs));
	else
		Controls.ChatCheck:GetTextButton():SetText(Locale.Lookup("LOC_HIDE_CHAT_PANEL"));
	end
end

-- ===========================================================================
--	Obtains full refresh and views most current research and civic IDs.
-- ===========================================================================
function Refresh()
	local localPlayer :number = Game.GetLocalPlayer();
	if localPlayer < 0 then
		ToggleAll(true);
		return;
	end

	local pPlayerTechs :table = Players[localPlayer]:GetTechs();
	m_currentResearchID = pPlayerTechs:GetResearchingTech();

	-- Only reset last completed tech once a new tech has been selected
	if m_currentResearchID >= 0 then
		m_lastResearchCompletedID = -1;
	end

	UpdateResearchPanel();

	local pPlayerCulture:table = Players[localPlayer]:GetCulture();
	m_currentCivicID = pPlayerCulture:GetProgressingCivic();

	-- Only reset last completed civic once a new civic has been selected
	if m_currentCivicID >= 0 then
		m_lastCivicCompletedID = -1;
	end

	UpdateCivicsPanel();

	-- Hide world tracker by default if there are no tracker options enabled
	if IsAllPanelsHidden() then
		ToggleAll(true);
	end
end

-- ===========================================================================
--	GAME EVENT
-- ===========================================================================
function OnLocalPlayerTurnBegin()
	local localPlayer = Game.GetLocalPlayer();
	if localPlayer ~= -1 then
		m_isDirty = true;
	end
end

-- ===========================================================================
--	GAME EVENT
-- ===========================================================================
function OnCityInitialized( playerID:number, cityID:number )
	if playerID == Game.GetLocalPlayer() then
		m_isDirty = true;
	end
end

-- ===========================================================================
--	GAME EVENT
--	Buildings can change culture/science yield which can effect
--	"turns to complete" values
-- ===========================================================================
function OnBuildingChanged( plotX:number, plotY:number, buildingIndex:number, playerID:number, cityID:number, iPercentComplete:number )
	if playerID == Game.GetLocalPlayer() then
		m_isDirty = true;
	end
end

-- ===========================================================================
--	GAME EVENT
-- ===========================================================================
function OnDirtyCheck()
	if m_isDirty then
		Refresh();
		m_isDirty = false;
	end
end

-- ===========================================================================
--	GAME EVENT
--	A civic item has changed, this may not be the current civic item
--	but an item deeper in the tree that was just boosted by a player action.
-- ===========================================================================
function OnCivicChanged( ePlayer:number, eCivic:number )
	local localPlayer = Game.GetLocalPlayer();
	if localPlayer ~= -1 and localPlayer == ePlayer then
		ResetOverflowArrow( m_civicsInstance );
		local pPlayerCulture:table = Players[localPlayer]:GetCulture();
		m_currentCivicID = pPlayerCulture:GetProgressingCivic();
		m_lastCivicCompletedID = -1;
		if eCivic == m_currentCivicID then
			UpdateCivicsPanel();
		end
	end
end

-- ===========================================================================
--	GAME EVENT
-- ===========================================================================
function OnCivicCompleted( ePlayer:number, eCivic:number )
	local localPlayer = Game.GetLocalPlayer();
	if localPlayer ~= -1 and localPlayer == ePlayer then
		m_currentCivicID = -1;
		m_lastCivicCompletedID = eCivic;
		UpdateCivicsPanel();
	end
end

-- ===========================================================================
--	GAME EVENT
-- ===========================================================================
function OnCultureYieldChanged( ePlayer:number )
	local localPlayer = Game.GetLocalPlayer();
	if localPlayer ~= -1 and localPlayer == ePlayer then
		UpdateCivicsPanel();
	end
end

-- ===========================================================================
--	GAME EVENT
-- ===========================================================================
function OnInterfaceModeChanged(eOldMode:number, eNewMode:number)
	if eNewMode == InterfaceModeTypes.VIEW_MODAL_LENS then
		ContextPtr:SetHide(true);
	end
	if eOldMode == InterfaceModeTypes.VIEW_MODAL_LENS then
		ContextPtr:SetHide(false);
	end
end

-- ===========================================================================
--	GAME EVENT
--	A research item has changed, this may not be the current researched item
--	but an item deeper in the tree that was just boosted by a player action.
-- ===========================================================================
function OnResearchChanged( ePlayer:number, eTech:number )
	if ShouldUpdateResearchPanel(ePlayer, eTech) then
		ResetOverflowArrow( m_researchInstance );
		UpdateResearchPanel();
	end
end

-- ===========================================================================
--	This function was separated so behavior can be modified in mods/expasions
-- ===========================================================================
function ShouldUpdateResearchPanel(ePlayer:number, eTech:number)
	local localPlayer = Game.GetLocalPlayer();

	if localPlayer ~= -1 and localPlayer == ePlayer then
		local pPlayerTechs :table = Players[localPlayer]:GetTechs();
		m_currentResearchID = pPlayerTechs:GetResearchingTech();

		-- Only reset last completed tech once a new tech has been selected
		if m_currentResearchID >= 0 then
			m_lastResearchCompletedID = -1;
		end

		if eTech == m_currentResearchID then
			return true;
		end
	end
	return false;
end

-- ===========================================================================
function OnResearchCompleted( ePlayer:number, eTech:number )
	if (ePlayer == Game.GetLocalPlayer()) then
		m_currentResearchID = -1;
		m_lastResearchCompletedID = eTech;
		UpdateResearchPanel();
	end
end

-- ===========================================================================
function OnUpdateDueToCity(ePlayer:number, cityID:number, plotX:number, plotY:number)
	if (ePlayer == Game.GetLocalPlayer()) then
		UpdateResearchPanel();
		UpdateCivicsPanel();
	end
end

-- ===========================================================================
function OnResearchYieldChanged( ePlayer:number )
	local localPlayer = Game.GetLocalPlayer();
	if localPlayer ~= -1 and localPlayer == ePlayer then
		UpdateResearchPanel();
	end
end


-- ===========================================================================
function OnMultiplayerChat( fromPlayer, toPlayer, text, eTargetType )
	-- If the chat panels are hidden, indicate there are unread messages waiting on the world tracker panel toggler.
	if(m_hideAll or m_hideChat) then
		m_unreadChatMsgs = m_unreadChatMsgs + 1;
		UpdateUnreadChatMsgs();
	end
end

-- ===========================================================================
--	UI Callback
-- ===========================================================================
function OnInit(isReload:boolean)
	LateInitialize();
	if isReload then
		LuaEvents.GameDebug_GetValues(RELOAD_CACHE_ID);
	else
		Refresh();	-- Standard refresh.
	end
end

-- ===========================================================================
--	UI Callback
-- ===========================================================================
function OnShutdown()
	Unsubscribe();

	LuaEvents.GameDebug_AddValue(RELOAD_CACHE_ID, "m_currentResearchID",		m_currentResearchID);
	LuaEvents.GameDebug_AddValue(RELOAD_CACHE_ID, "m_lastResearchCompletedID",	m_lastResearchCompletedID);
	LuaEvents.GameDebug_AddValue(RELOAD_CACHE_ID, "m_currentCivicID",			m_currentCivicID);
	LuaEvents.GameDebug_AddValue(RELOAD_CACHE_ID, "m_lastCivicCompletedID",		m_lastCivicCompletedID);
end

-- ===========================================================================
function OnGameDebugReturn(context:string, contextTable:table)
	if context == RELOAD_CACHE_ID then
		m_currentResearchID			= contextTable["m_currentResearchID"];
		m_lastResearchCompletedID	= contextTable["m_lastResearchCompletedID"];
		m_currentCivicID			= contextTable["m_currentCivicID"];
		m_lastCivicCompletedID		= contextTable["m_lastCivicCompletedID"];

		if m_currentResearchID == nil		then m_currentResearchID = -1; end
		if m_lastResearchCompletedID == nil then m_lastResearchCompletedID = -1; end
		if m_currentCivicID == nil			then m_currentCivicID = -1; end
		if m_lastCivicCompletedID == nil	then m_lastCivicCompletedID = -1; end

		-- Don't call refresh, use cached data from last hotload.
		UpdateResearchPanel();
		UpdateCivicsPanel();
	end
end

-- ===========================================================================
function OnTutorialGoalsShowing()
	RealizeStack();
end

-- ===========================================================================
function OnTutorialGoalsHiding()
	RealizeStack();
end

-- ===========================================================================
function Tutorial_ShowFullTracker()
	Controls.ToggleAllButton:SetHide(true);
	Controls.ToggleDropdownButton:SetHide(true);
	UpdateCivicsPanel(false);
	UpdateResearchPanel(false);
	ToggleAll(false);
end

-- ===========================================================================
function Tutorial_ShowTrackerOptions()
	Controls.ToggleAllButton:SetHide(false);
	Controls.ToggleDropdownButton:SetHide(false);
end

-- ===========================================================================
-- CUI Tracker Functions
-- ===========================================================================

-- CUI -----------------------------------------------------------------------
function CuiRefreshWonderToolTip(tControl)
    tControl:ClearToolTipCallback()
    tControl:SetToolTipType("CuiWonderTT")
    tControl:SetToolTipCallback(
        function()
            CuiUpdateWonderToolTip(tControl)
        end
    )
end

-- CUI -----------------------------------------------------------------------
function CuiUpdateWonderToolTip()
    local localPlayerID = Game.GetLocalPlayer()
    if localPlayerID == -1 then
        return
    end

    wonderInstance:ResetInstances()
    colorInstance:ResetInstances()

    for _, wonder in ipairs(wonderData.Wonders) do
        local wonderIcon = wonderInstance:GetInstance(CuiWonderTT.WonderIconStack)
        wonderIcon.Icon:SetIcon(wonder.Icon)
        local beenBuilt = wonder.BeenBuilt
        local alpha = beenBuilt and 0.5 or 1.0
        local back = beenBuilt and "Black" or "Clear"
        wonderIcon.Icon:SetAlpha(alpha)
        wonderIcon.Back:SetColorByName(back)
        wonderIcon.Color1:SetColor(wonder.Color1)
        wonderIcon.Color2:SetColor(wonder.Color2)
    end
    CuiWonderTT.WonderIconStack:CalculateSize()

    for _, civ in ipairs(wonderData.Colors) do
        local colorIndicator = colorInstance:GetInstance(CuiWonderTT.ColorIndicatorStack)
        colorIndicator.CivName:SetText(civ.CivName)
        colorIndicator.Color1:SetColor(civ.Color1)
        colorIndicator.Color2:SetColor(civ.Color2)
    end
    CuiWonderTT.ColorIndicatorStack:CalculateSize()

    local wonderStackY = CuiWonderTT.WonderIconStack:GetSizeY()
    local colorStackY = CuiWonderTT.ColorIndicatorStack:GetSizeY()
    local dividerY = math.max(wonderStackY, colorStackY)
    CuiWonderTT.VerticalDivider:SetSizeY(dividerY)

    CuiWonderTT.MainStack:CalculateSize()
    CuiWonderTT.BG:DoAutoSize()
end

-- CUI -----------------------------------------------------------------------
function CuiRefreshResourceToolTip(tControl)
    tControl:ClearToolTipCallback()
    tControl:SetToolTipType("CuiResourceTT")
    tControl:SetToolTipCallback(
        function()
            CuiUpdateResourceToolTip(tControl)
        end
    )
end

-- CUI -----------------------------------------------------------------------
function CuiUpdateResourceToolTip()
    local localPlayerID = Game.GetLocalPlayer()
    if localPlayerID == -1 then
        return
    end

    resourceInstance:ResetInstances()
    resourceBarInstance:ResetInstances()

    r_luxury = resourceData.Luxury
    r_strategic = resourceData.Strategic

    -- luxury
    CuiResourceTT.LuxuryIconStack:SetHide(#r_luxury == 0)
    CuiResourceTT.Divider:SetHide(#r_luxury == 0)

    if not isExpansion2 and #r_luxury < 9 then
        CuiResourceTT.Divider:SetSizeX(264)
    else
        CuiResourceTT.Divider:SetSizeX(346)
    end

    for _, item in ipairs(r_luxury) do
        local icon = resourceInstance:GetInstance(CuiResourceTT.LuxuryIconStack)
        CuiSetIconToSize(icon.Icon, item.Icon, 36)
        icon.Text:SetText(item.Amount)
        if item.Duplicate then
            icon.Text:SetColorByName("ModStatusGreen")
        elseif item.CanTrade then
            icon.Text:SetColorByName("Black")
        else
            icon.Text:SetColorByName("Red")
        end
    end
    CuiResourceTT.LuxuryIconStack:CalculateSize()

    -- strategic
    if isExpansion2 then
        for _, item in ipairs(r_strategic) do
            local icon = resourceBarInstance:GetInstance(CuiResourceTT.StrategicIconStack)
            CuiSetIconToSize(icon.Icon, item.Icon, 36)
            local perTurn = item.APerTurn - item.MPerTurn
            local perTurnText = ""
            if perTurn < 0 then
                perTurnText = "[COLOR_Civ6Red]" .. perTurn .. "[ENDCOLOR]"
            elseif perTurn > 0 then
                perTurnText = "[COLOR_ModStatusGreen]+" .. perTurn .. "[ENDCOLOR]"
            else
                perTurnText = "-"
            end
            icon.PerTurn:SetText(perTurnText)
            if item.Amount > item.Cap then
                item.Amount = item.Cap
            end
            icon.Amount:SetText(item.Amount .. " / " .. item.Cap)
            local percent = item.Amount / item.Cap
            icon.PercentBar:SetPercent(percent)
        end
        CuiResourceTT.StrategicIconStack:CalculateSize()
    else
        for _, item in ipairs(r_strategic) do
            local icon = resourceInstance:GetInstance(CuiResourceTT.StrategicIconStack)
            CuiSetIconToSize(icon.Icon, item.Icon, 36)
            icon.Text:SetText(item.Amount)
        end
    end

    CuiResourceTT.MainStack:CalculateSize()
    CuiResourceTT.BG:DoAutoSize()
end

-- CUI -----------------------------------------------------------------------
function CuiRefreshBorderToolTip(tControl)
    tControl:ClearToolTipCallback()
    if #borderData.Leaders > 0 then
        tControl:SetToolTipType("CuiBorderTT")
        tControl:SetToolTipCallback(
            function()
                CuiUpdateBorderToolTip(tControl)
            end
        )
    end
end

-- CUI -----------------------------------------------------------------------
function CuiUpdateBorderToolTip()
    local localPlayerID = Game.GetLocalPlayer()
    if localPlayerID == -1 then
        return
    end

    borderInstance:ResetInstances()

    CuiBorderTT.OpenBorderIcon:SetTexture(IconManager:FindIconAtlas("ICON_DIPLOACTION_OPEN_BORDERS", 50))

    for _, leader in ipairs(borderData.Leaders) do
        local icon = borderInstance:GetInstance(CuiBorderTT.OpenBorderStack)
        icon.Icon:SetTexture(CuiLeaderTexture(leader.Icon, 45, leader.IsMet))

        -- setup images
        local importColor = leader.HasImport and "Green" or "White"
        local exportColor = leader.HasExport and "Green" or "White"

        icon.Import:SetColorByName(importColor)
        icon.Export:SetColorByName(exportColor)

        local isRestricted =
            not leader.HasImport and not leader.CanImport and not leader.HasExport and not leader.CanImport

        icon.Import:SetHide(isRestricted)
        icon.Export:SetHide(isRestricted)
        icon.Disable:SetHide(not isRestricted)
    end
    CuiBorderTT.OpenBorderStack:CalculateSize()

    -- divider height
    CuiBorderTT.Divider:SetHide(#borderData.Leaders == 0)
    local stackHeight = CuiBorderTT.OpenBorderStack:GetSizeY()
    CuiBorderTT.Divider:SetSizeY(math.max(190, stackHeight))

    CuiBorderTT.MainStack:DoAutoSize()
    CuiBorderTT.BG:DoAutoSize()
end

-- CUI -----------------------------------------------------------------------
function CuiRefreshTradeToolTip(tControl)
    tControl:ClearToolTipCallback()
    if tradeData.Cap > 0 then
        tControl:SetToolTipType("CuiTradeTT")
        tControl:SetToolTipCallback(
            function()
                CuiUpdateTradeToolTip(tControl)
            end
        )
    end
end

-- CUI -----------------------------------------------------------------------
function CuiUpdateTradeToolTip()
    local localPlayerID = Game.GetLocalPlayer()
    if localPlayerID == -1 then
        return
    end

    if isNil(tradeData) then
        return
    end

    local textActive = tradeData.Routes
    if tradeData.Routes < tradeData.Cap then
        textActive = "[COLOR_GREEN]" .. tradeData.Routes .. "[ENDCOLOR]"
    elseif tradeData.Routes > tradeData.Cap then
        textActive = "[COLOR_RED]" .. tradeData.Routes .. "[ENDCOLOR]"
    end
    CuiTradeTT.RoutesActive:SetText(textActive)
    CuiTradeTT.RoutesCap:SetText("/" .. tradeData.Cap)

    tradeInstance:ResetInstances()

    CuiTradeTT.TraderIcon:SetTexture(IconManager:FindIconAtlas("ICON_UNIT_TRADER_PORTRAIT", 50))
    for _, leader in ipairs(tradeData.Leaders) do
        local icon = tradeInstance:GetInstance(CuiTradeTT.TradeRouteStack)
        icon.Icon:SetTexture(CuiLeaderTexture(leader.Icon, 45, leader.IsMet))
        if leader.IsTraded then
            icon.TradeState:SetTexture("icon_yes.dds")
        elseif not leader.IsMet or leader.IsWar then
            icon.TradeState:SetTexture("icon_no.dds")
        else
            icon.TradeState:SetTexture("Espionage_OverlayFound")
        end
    end
    CuiTradeTT.TradeRouteStack:CalculateSize()

    -- divider height
    CuiTradeTT.Divider:SetHide(#tradeData.Leaders == 0)
    local stackHeight = CuiTradeTT.TradeRouteStack:GetSizeY()
    CuiTradeTT.Divider:SetSizeY(math.max(190, stackHeight))

    CuiTradeTT.MainStack:DoAutoSize()
    CuiTradeTT.BG:DoAutoSize()
end

-- ===========================================================================
-- CUI City Manager Functions
-- ===========================================================================

-- CUI -----------------------------------------------------------------------
function CuiOnCityManager()
    LuaEvents.CuiOnToggleCityManager()
end

-- ===========================================================================
-- CUI Log Functions
-- ===========================================================================

-- CUI -----------------------------------------------------------------------
function CuiUpdateLog(logString, displayTime, logType)
    if logType == ReportingStatusTypes.GOSSIP then
        CuiAddGossipLog(logString)
    elseif logType == ReportingStatusTypes.DEFAULT then
        CuiAddCombatLog(logString)
    end
end

-- CUI -----------------------------------------------------------------------
function CuiTurnString()
    local turnLookup = Locale.Lookup("{LOC_TOP_PANEL_CURRENT_TURN:upper} ")
    turnString = "[COLOR_FLOAT_GOLD]" .. turnLookup .. Game.GetCurrentGameTurn() .. "[ENDCOLOR]"
    return turnString
end

-- CUI -----------------------------------------------------------------------
function CuiAddGossipLog(logString)
    if cui_GossipCount == 0 then
        CuiAddLog(CuiTurnString(), cui_GossipPanel, cui_GossipLogs)
    end
    CuiAddLog(logString, cui_GossipPanel, cui_GossipLogs)
    cui_GossipCount = cui_GossipCount + 1
    cui_GossipPanel.NewLogNumber:SetText("[ICON_NEW] " .. cui_GossipCount)
end

-- CUI -----------------------------------------------------------------------
function CuiAddCombatLog(logString)
    if cui_CombatCount == 0 then
        CuiAddLog(CuiTurnString(), cui_CombatPanel, cui_CombatLogs)
    end
    CuiAddLog(logString, cui_CombatPanel, cui_CombatLogs)
    cui_CombatCount = cui_CombatCount + 1
    cui_CombatPanel.NewLogNumber:SetText("[ICON_NEW] " .. cui_CombatCount)
end

-- CUI -----------------------------------------------------------------------
function CuiAddLog(logString, logPanel, entries)
    local instance = {}
    ContextPtr:BuildInstanceForControl("LogInstance", instance, logPanel.LogStack)
    instance.String:SetText(logString)
    instance.LogRoot:SetSizeY(instance.String:GetSizeY() + 6)
    table.insert(entries, instance)

    -- Remove the earliest entry if the log limit has been reached
    if #entries > cui_MaxLog then
        logPanel.LogStack:ReleaseChild(entries[1].LogRoot)
        table.remove(entries, 1)
    end

    -- Refresh log and reprocess size
    logPanel.LogStack:CalculateSize()
    logPanel.LogStack:ReprocessAnchoring()
end

-- CUI -----------------------------------------------------------------------
function CuiLogPanelResize(instance, state)
    local status = cui_LogPanelStatus[state]
    instance.MainPanel:SetSizeY(status.main)
    instance.LogPanel:SetSizeY(status.log)
    instance.LogStack:SetHide(state == 1)
    instance.ButtomDivider:SetHide(state == 1)
end

-- CUI -----------------------------------------------------------------------
function CuiContractGossipLog()
    cui_GossipState = cui_GossipState - 1
    if cui_GossipState == 0 then
        cui_GossipState = 3
    end
    CuiSettings:SetNumber(CuiSettings.GOSSIP_LOG_STATE, cui_GossipState)
    CuiLogPanelResize(cui_GossipPanel, cui_GossipState)
end

-- CUI -----------------------------------------------------------------------
function CuiExpandGossipLog()
    cui_GossipState = cui_GossipState + 1
    if cui_GossipState == 4 then
        cui_GossipState = 1
    end
    CuiSettings:SetNumber(CuiSettings.GOSSIP_LOG_STATE, cui_GossipState)
    CuiLogPanelResize(cui_GossipPanel, cui_GossipState)
end

-- CUI -----------------------------------------------------------------------
function CuiContractCombatLog()
    cui_CombatState = cui_CombatState - 1
    if cui_CombatState == 0 then
        cui_CombatState = 3
    end
    CuiSettings:SetNumber(CuiSettings.COMBAT_LOG_STATE, cui_CombatState)
    CuiLogPanelResize(cui_CombatPanel, cui_CombatState)
end

-- CUI -----------------------------------------------------------------------
function CuiExpandCombatLog()
    cui_CombatState = cui_CombatState + 1
    if cui_CombatState == 4 then
        cui_CombatState = 1
    end
    CuiSettings:SetNumber(CuiSettings.COMBAT_LOG_STATE, cui_CombatState)
    CuiLogPanelResize(cui_CombatPanel, cui_CombatState)
end

-- ===========================================================================
-- CUI Panel Functions
-- ===========================================================================

-- CUI -----------------------------------------------------------------------
function CuiLogPanelSetup()
    CuiRegCallback(cui_GossipPanel.TitleButton, CuiExpandGossipLog, CuiContractGossipLog)
    CuiRegCallback(cui_CombatPanel.TitleButton, CuiExpandCombatLog, CuiContractCombatLog)
    Controls.GossipLogCheck:RegisterCheckHandler(CuiOnLogCheckClick)
    Controls.CombatLogCheck:RegisterCheckHandler(CuiOnLogCheckClick)
end

-- CUI -----------------------------------------------------------------------
function CuiTrackPanelSetup()
    cui_TrackBar.WonderIcon:SetTexture(IconManager:FindIconAtlas("ICON_DISTRICT_WONDER", 32))
    cui_TrackBar.ResourceIcon:SetTexture(IconManager:FindIconAtlas("ICON_DIPLOACTION_REQUEST_ASSISTANCE", 38))
    cui_TrackBar.BorderIcon:SetTexture(IconManager:FindIconAtlas("ICON_DIPLOACTION_OPEN_BORDERS", 38))
    cui_TrackBar.TradeIcon:SetTexture(IconManager:FindIconAtlas("ICON_DIPLOACTION_VIEW_TRADE", 38))
    cui_TrackBar.TempAIcon:SetTexture(IconManager:FindIconAtlas("ICON_DIPLOACTION_DECLARE_SURPRISE_WAR", 38))
    cui_TrackBar.TempBIcon:SetTexture(IconManager:FindIconAtlas("ICON_DIPLOACTION_ALLIANCE", 38))
    cui_TrackBar.CityIcon:SetTexture(IconManager:FindIconAtlas("ICON_DISTRICT_CITY_CENTER", 32))
    cui_TrackBar.CuiCityManager:RegisterCallback(Mouse.eLClick, CuiOnCityManager)
end

-- CUI -----------------------------------------------------------------------
function CuiOnPopulationChanged(isChanged)
    CuiChangeIconColor(cui_TrackBar.CityIcon, isChanged)
end

-- CUI -----------------------------------------------------------------------
function CuiChangeIconColor(icon, isActive)
    if isActive then
        icon:SetColorByName("ModStatusGreenCS")
    else
        icon:SetColorByName("White")
    end
end

-- CUI -----------------------------------------------------------------------
function CuiLogPanelRefresh()
    m_useGossipLog = CuiSettings:GetBoolean(CuiSettings.WT_GOSSIP_LOG)
    m_useCombatLog = CuiSettings:GetBoolean(CuiSettings.WT_COMBAT_LOG)

    cui_GossipPanel.MainPanel:SetHide(not m_useGossipLog)
    cui_CombatPanel.MainPanel:SetHide(not m_useCombatLog)

    CuiLogPanelResize(cui_CombatPanel, cui_CombatState)
    CuiLogPanelResize(cui_GossipPanel, cui_GossipState)

    Controls.GossipLogCheck:SetCheck(m_useGossipLog)
    Controls.CombatLogCheck:SetCheck(m_useCombatLog)
end

-- CUI -----------------------------------------------------------------------
function CuiLogCounterReset()
    cui_GossipCount = 0
    cui_GossipPanel.NewLogNumber:SetText("")
    cui_CombatCount = 0
    cui_CombatPanel.NewLogNumber:SetText("")
end

-- CUI -----------------------------------------------------------------------
function CuiTrackerRefresh()
    local localPlayer = Players[Game.GetLocalPlayer()]
    if localPlayer == nil then
        return
    end

    wonderData = CuiGetWonderData()
    resourceData = CuiGetResourceData()
    borderData = CuiGetBorderData()
    tradeData = CuiGetTradeData()

    CuiRefreshWonderToolTip(cui_TrackBar.WonderIcon)
    CuiRefreshResourceToolTip(cui_TrackBar.ResourceIcon)
    CuiRefreshBorderToolTip(cui_TrackBar.BorderIcon)
    CuiRefreshTradeToolTip(cui_TrackBar.TradeIcon)

    CuiChangeIconColor(cui_TrackBar.ResourceIcon, resourceData.Active)
    CuiChangeIconColor(cui_TrackBar.BorderIcon, borderData.Active)
    CuiChangeIconColor(cui_TrackBar.TradeIcon, tradeData.Active)
end

-- CUI -----------------------------------------------------------------------
function CuiOnLogCheckClick()
    m_useGossipLog = Controls.GossipLogCheck:IsChecked()
    m_useCombatLog = Controls.CombatLogCheck:IsChecked()
    CuiSettings:SetBoolean(CuiSettings.WT_GOSSIP_LOG, m_useGossipLog)
    CuiSettings:SetBoolean(CuiSettings.WT_COMBAT_LOG, m_useCombatLog)
    CuiLogPanelRefresh()
    RealizeEmptyMessage()
    RealizeStack()
end

-- CUI -----------------------------------------------------------------------
function CuiInit()
    ContextPtr:BuildInstanceForControl("CuiTrackerInstance", cui_TrackBar, Controls.PanelStack)
    CuiTrackPanelSetup()

    ContextPtr:BuildInstanceForControl("GossipLogInstance", cui_GossipPanel, Controls.PanelStack)
    ContextPtr:BuildInstanceForControl("CombatLogInstance", cui_CombatPanel, Controls.PanelStack)
    CuiLogPanelSetup()

    -- Log Events
    Events.StatusMessage.Add(CuiUpdateLog)
    Events.LocalPlayerTurnEnd.Add(CuiLogCounterReset)

    -- Tracker Events
    Events.ImprovementAddedToMap.Add(CuiTrackerRefresh)
    Events.ImprovementRemovedFromMap.Add(CuiTrackerRefresh)
    Events.LoadGameViewStateDone.Add(CuiTrackerRefresh)
    Events.LocalPlayerTurnBegin.Add(CuiTrackerRefresh)
    LuaEvents.DiplomacyActionView_ShowIngameUI.Add(CuiTrackerRefresh)

    -- Refresh
    CuiLogPanelRefresh()
    CuiTrackerRefresh()

    LuaEvents.CuiLogSettingChange.Add(CuiLogPanelRefresh)
    LuaEvents.CuiPlayerPopulationChanged.Add(CuiOnPopulationChanged)
end

-- ===========================================================================
-- Handling chat panel expansion
-- ===========================================================================
function OnChatPanel_OpenExpandedPanels()
	m_isChatExpanded = true;
	ResizeExpandedChatPanel();
end

-- ===========================================================================
function OnChatPanel_CloseExpandedPanels()
	m_isChatExpanded = false;
	Controls.ChatPanel:SetSizeY( CHAT_COLLAPSED_SIZE );
	RealizeStack();
end

-- ===========================================================================
function ResizeExpandedChatPanel()
	Controls.ChatPanel:SetHide(true);							-- Hide so it's not part of stack computation.
	RealizeStack();

	local uiMinimap			:table  = ContextPtr:LookUpControl("/InGame/MinimapPanel/MinimapContainer");
	local defaultMinimapSize:number = 376;						-- Size of the minimap when the height > width (ex. Nubia/BlackDeath scenarios).
	local stackSection		:number = 96;
	local crisisSize		:number = 50;
	local chatSize			:number = 199;
	local stackSize			:number	= Controls.PanelStack:GetSizeY() - m_startingChatSize;
	local width, height				= UIManager:GetScreenSizeVal();

	if uiMinimap then
		m_minimapSize = uiMinimap:GetSizeY() + GetMinimapPadding();
	else
		m_minimapSize = defaultMinimapSize;
	end
	if not m_hideCivics then
		stackSize = stackSize + stackSection;
	end
	if not m_hideResearch then
		stackSize = stackSize + stackSection;
	end

	crisisSize = crisisSize * m_numEmergencies;

	if m_isMinimapCollapsed then
		m_minimapSize = 100;
	end

	chatSize = math.max(199, height-(stackSize + m_minimapSize + crisisSize));

	if (stackSize + m_minimapSize + chatSize + crisisSize) >= height then
		chatSize = height - m_minimapSize - stackSize - crisisSize - 25;
	end
	Controls.ChatPanel:SetHide(m_hideChat);
	LuaEvents.ChatPanel_SetChatPanelSize(chatSize);			--Sets chat panel pulldown size
	Controls.ChatPanel:SetSizeY(chatSize);					--Sets chat stack for placement of emergencies if present
end

-- ===========================================================================
function OnSetMinimapCollapsed(isMinimapCollapsed:boolean)
	m_isMinimapCollapsed = isMinimapCollapsed;
	if m_isChatExpanded then
		ResizeExpandedChatPanel();
	end
end

-- ===========================================================================
function OnSetNumberOfEmergencies(numEmergencies:number)
	m_numEmergencies = numEmergencies;
end

-- ===========================================================================
--	Add any UI from tracked items that are loaded.
--	Items are expected to be tables with the following fields:
--		Name			localization key for the title name of panel
--		InstanceType	the instance (in XML) to create for the control
--		SelectFunc		if instance has "IconButton" the callback when pressed
-- ===========================================================================
function AttachDynamicUI()
	for i,kData in ipairs(g_TrackedItems) do
		local uiInstance:table = {};
		ContextPtr:BuildInstanceForControl( kData.InstanceType, uiInstance, Controls.PanelStack );
		if uiInstance.IconButton then
			uiInstance.IconButton:RegisterCallback(Mouse.eLClick, function() kData.SelectFunc() end);
		end
		table.insert(g_TrackedInstances, uiInstance);

		if(uiInstance.TitleButton) then
			uiInstance.TitleButton:LocalizeAndSetText(kData.Name);
		end
	end
end

-- ===========================================================================
function OnForceHide()
	ContextPtr:SetHide(true);
end

-- ===========================================================================
function OnForceShow()
	ContextPtr:SetHide(false);
end

-- ===========================================================================
function OnStartObserverMode()
	UpdateResearchPanel();
	UpdateCivicsPanel();
end

-- ===========================================================================
-- FOR OVERRIDE
-- ===========================================================================
function GetMinimapPadding()
	return MINIMAP_PADDING;
end

-- ===========================================================================
function Subscribe()
	Events.CityInitialized.Add(OnCityInitialized);
	Events.BuildingChanged.Add(OnBuildingChanged);
	Events.CivicChanged.Add(OnCivicChanged);
	Events.CivicCompleted.Add(OnCivicCompleted);
	Events.CultureYieldChanged.Add(OnCultureYieldChanged);
	Events.InterfaceModeChanged.Add( OnInterfaceModeChanged );
	Events.LocalPlayerTurnBegin.Add(OnLocalPlayerTurnBegin);
	Events.MultiplayerChat.Add( OnMultiplayerChat );
	Events.ResearchChanged.Add(OnResearchChanged);
	Events.ResearchCompleted.Add(OnResearchCompleted);
	Events.ResearchYieldChanged.Add(OnResearchYieldChanged);
	Events.GameCoreEventPublishComplete.Add( OnDirtyCheck ); --This event is raised directly after a series of gamecore events.
	Events.CityWorkerChanged.Add( OnUpdateDueToCity );
	Events.CityFocusChanged.Add( OnUpdateDueToCity );

	LuaEvents.LaunchBar_Resize.Add(OnLaunchBarResized);

	LuaEvents.CivicChooser_ForceHideWorldTracker.Add(	OnForceHide );
	LuaEvents.CivicChooser_RestoreWorldTracker.Add(		OnForceShow);
	LuaEvents.EndGameMenu_StartObserverMode.Add(		OnStartObserverMode );
	LuaEvents.ResearchChooser_ForceHideWorldTracker.Add(OnForceHide);
	LuaEvents.ResearchChooser_RestoreWorldTracker.Add(	OnForceShow);
	LuaEvents.Tutorial_ForceHideWorldTracker.Add(		OnForceHide);
	LuaEvents.Tutorial_RestoreWorldTracker.Add(			Tutorial_ShowFullTracker);
	LuaEvents.Tutorial_EndTutorialRestrictions.Add(		Tutorial_ShowTrackerOptions);
	LuaEvents.TutorialGoals_Showing.Add(				OnTutorialGoalsShowing );
	LuaEvents.TutorialGoals_Hiding.Add(					OnTutorialGoalsHiding );
	LuaEvents.ChatPanel_OpenExpandedPanels.Add(			OnChatPanel_OpenExpandedPanels);
	LuaEvents.ChatPanel_CloseExpandedPanels.Add(		OnChatPanel_CloseExpandedPanels);
	LuaEvents.WorldTracker_SetEmergencies.Add(			OnSetNumberOfEmergencies);
	LuaEvents.WorldTracker_OnScreenResize.Add(			ResizeExpandedChatPanel );
	LuaEvents.WorldTracker_OnSetMinimapCollapsed.Add(	OnSetMinimapCollapsed );
end

-- ===========================================================================
function Unsubscribe()
	Events.CityInitialized.Remove(OnCityInitialized);
	Events.BuildingChanged.Remove(OnBuildingChanged);
	Events.CivicChanged.Remove(OnCivicChanged);
	Events.CivicCompleted.Remove(OnCivicCompleted);
	Events.CultureYieldChanged.Remove(OnCultureYieldChanged);
	Events.InterfaceModeChanged.Remove( OnInterfaceModeChanged );
	Events.LocalPlayerTurnBegin.Remove(OnLocalPlayerTurnBegin);
	Events.MultiplayerChat.Remove( OnMultiplayerChat );
	Events.ResearchChanged.Remove(OnResearchChanged);
	Events.ResearchCompleted.Remove(OnResearchCompleted);
	Events.ResearchYieldChanged.Remove(OnResearchYieldChanged);
	Events.GameCoreEventPublishComplete.Remove( OnDirtyCheck ); --This event is raised directly after a series of gamecore events.
	Events.CityWorkerChanged.Remove( OnUpdateDueToCity );
	Events.CityFocusChanged.Remove( OnUpdateDueToCity );

	LuaEvents.LaunchBar_Resize.Remove(OnLaunchBarResized);

	LuaEvents.CivicChooser_ForceHideWorldTracker.Remove(	OnForceHide );
	LuaEvents.CivicChooser_RestoreWorldTracker.Remove(		OnForceShow);
	LuaEvents.EndGameMenu_StartObserverMode.Remove(			OnStartObserverMode );
	LuaEvents.ResearchChooser_ForceHideWorldTracker.Remove(	OnForceHide);
	LuaEvents.ResearchChooser_RestoreWorldTracker.Remove(	OnForceShow);
	LuaEvents.Tutorial_ForceHideWorldTracker.Remove(		OnForceHide);
	LuaEvents.Tutorial_RestoreWorldTracker.Remove(			Tutorial_ShowFullTracker);
	LuaEvents.Tutorial_EndTutorialRestrictions.Remove(		Tutorial_ShowTrackerOptions);
	LuaEvents.TutorialGoals_Showing.Remove(					OnTutorialGoalsShowing );
	LuaEvents.TutorialGoals_Hiding.Remove(					OnTutorialGoalsHiding );
	LuaEvents.ChatPanel_OpenExpandedPanels.Remove(			OnChatPanel_OpenExpandedPanels);
	LuaEvents.ChatPanel_CloseExpandedPanels.Remove(			OnChatPanel_CloseExpandedPanels);
	LuaEvents.WorldTracker_SetEmergencies.Remove(			OnSetNumberOfEmergencies);
	LuaEvents.WorldTracker_OnScreenResize.Remove(			ResizeExpandedChatPanel );
	LuaEvents.WorldTracker_OnSetMinimapCollapsed.Remove(	OnSetMinimapCollapsed );
end

-- ===========================================================================
function LateInitialize()

	Subscribe();

	-- InitChatPanel
	if(UI.HasFeature("Chat")
		and (GameConfiguration.IsNetworkMultiplayer() or GameConfiguration.IsPlayByCloud()) ) then
		UpdateChatPanel(false);
	else
		UpdateChatPanel(true);
		Controls.ChatCheck:SetHide(true);
	end

	UpdateUnreadChatMsgs();
	AttachDynamicUI();
end

-- ===========================================================================
function Initialize()

	if not GameCapabilities.HasCapability("CAPABILITY_WORLD_TRACKER") then
		ContextPtr:SetHide(true);
		return;
	end

	m_CachedModifiers = TechAndCivicSupport_BuildCivicModifierCache();

	-- Create semi-dynamic instances; hack: change parent back to self for ordering:
	ContextPtr:BuildInstanceForControl( "ResearchInstance", m_researchInstance, Controls.PanelStack );
    ContextPtr:BuildInstanceForControl( "CivicInstance",	m_civicsInstance,	Controls.PanelStack );
	m_researchInstance.IconButton:RegisterCallback(	Mouse.eLClick,	function() LuaEvents.WorldTracker_OpenChooseResearch(); end);
	m_civicsInstance.IconButton:RegisterCallback(	Mouse.eLClick,	function() LuaEvents.WorldTracker_OpenChooseCivic(); end);

    CuiInit(); -- CUI

	Controls.ChatPanel:ChangeParent( Controls.PanelStack );
	Controls.TutorialGoals:ChangeParent( Controls.PanelStack );

	-- Handle any text overflows with truncation and tooltip
	local fullString :string = Controls.WorldTracker:GetText();
	Controls.DropdownScroll:SetOffsetY(Controls.WorldTrackerHeader:GetSizeY() + STARTING_TRACKER_OPTIONS_OFFSET);

	-- Hot-reload events
	ContextPtr:SetInitHandler(OnInit);
	ContextPtr:SetShutdown(OnShutdown);
	LuaEvents.GameDebug_Return.Add(OnGameDebugReturn);

	Controls.ChatCheck:SetCheck(true);
	Controls.CivicsCheck:SetCheck(true);
	Controls.ResearchCheck:SetCheck(true);
	Controls.ToggleAllButton:SetCheck(true);

	Controls.ChatCheck:RegisterCheckHandler(						function() UpdateChatPanel(not m_hideChat); end);
	Controls.CivicsCheck:RegisterCheckHandler(						function() UpdateCivicsPanel(not m_hideCivics); end);
	Controls.ResearchCheck:RegisterCheckHandler(					function() UpdateResearchPanel(not m_hideResearch); end);
	Controls.ToggleAllButton:RegisterCheckHandler(					function() ToggleAll(not Controls.ToggleAllButton:IsChecked()) end);
	Controls.ToggleDropdownButton:RegisterCallback(	Mouse.eLClick, ToggleDropdown);
	Controls.WorldTrackerAlpha:RegisterEndCallback( OnWorldTrackerAnimationFinished );

	m_startingChatSize = Controls.ChatPanel:GetSizeY();
end
Initialize();
