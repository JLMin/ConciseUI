-- Copyright 2017-2019, Firaxis Games.
-- Leader container list on top of the HUD
include("InstanceManager")
include("LeaderIcon")
include("PlayerSupport")
include("SupportFunctions")
include("GameCapabilities")
include("cui_settings")
include("cuileadericonsupport")

-- ===========================================================================
--	CONSTANTS
-- ===========================================================================
local SCROLL_SPEED = 3
local UPDATE_FRAMES = 2 -- HACK: Require 2 frames to update size change :(
local LEADER_ART_OFFSET_X = -4
local LEADER_ART_OFFSET_Y = -9

-- ===========================================================================
--	GLOBALS
-- ===========================================================================
g_maxNumLeaders = 0 -- Number of leaders that can fit in the ribbon
g_kRefreshRequesters = {} -- Who requested a (refresh of stats)

-- ===========================================================================
--	MEMBERS
-- ===========================================================================
local m_kLeaderIM = InstanceManager:new("LeaderInstance", "LeaderContainer", Controls.LeaderStack)
local m_leadersMet = 0 -- Number of leaders in the ribbon
local m_scrollIndex = 0 -- Index of leader that is supposed to be on the far right.  TODO: Remove this and instead scroll based on visible area.
local m_scrollPercent = 0 -- Necessary for scroll lerp
local m_isScrolling = false
local m_uiLeadersByID = {} -- map of (entire) leader controls based on player id
local m_uiLeadersByPortrait = {} -- map of leader portraits based on player id
local m_uiChatIconsVisible = {}
local m_leaderInstanceHeight = 0 -- How tall is an instantiated leader instance.
local m_ribbonStats = -1 -- From Options menu, enum of how this should display.
local m_isIniting = true -- Tracking if initialization is occuring.
local m_kActiveIds = {} -- Which player(s) are active.
local m_isYieldsSubscribed = false -- Are yield events subscribed to?

-- ===========================================================================
--	Cleanup leaders
-- ===========================================================================
function ResetLeaders()
  m_kLeaderIM:ResetInstances()
  m_leadersMet = 0
  m_uiLeadersByID = {}
  m_uiLeadersByPortrait = {}
  m_scrollPercent = 0
  m_scrollIndex = 0
  m_leaderInstanceHeight = 0
  RealizeScroll()
end

-- ===========================================================================
function OnLeaderClicked(playerID)
  -- Send an event to open the leader in the diplomacy view (only if they met)
  local localPlayerID = Game.GetLocalPlayer()
  if playerID == localPlayerID or Players[localPlayerID]:GetDiplomacy():HasMet(playerID) then
    LuaEvents.DiplomacyRibbon_OpenDiplomacyActionView(playerID)
  end
end

-- ===========================================================================
function ShowStats(uiLeader)
  uiLeader.StatStack:SetHide(false)
  uiLeader.StatStack:CalculateSize()
  uiLeader.StatBacking:SetColorByName("HUDRIBBON_STATS_SHOW")
  uiLeader.ActiveLeaderAndStats:SetHide(false)
end

-- ===========================================================================
function HideStats(uiLeader)
  uiLeader.StatStack:SetHide(true)
  uiLeader.StatBacking:SetColorByName("HUDRIBBON_STATS_HIDE")
  uiLeader.ActiveLeaderAndStats:SetHide(true)
end

-- ===========================================================================
--	UI Callback
-- ===========================================================================
function OnLeaderSizeChanged(uiLeader)
  --	local pSize = uiLeader.LeaderContainer:GetSize();
  --	uiLeader.ActiveLeaderAndStats:SetSizeVal( pSize.x + LEADER_ART_OFFSET_X, pSize.y + LEADER_ART_OFFSET_Y );
end

-- ===========================================================================
--	Add a leader (from right to left)
--	iconName,	What icon to draw for the leader portrait
--	playerID,	gamecore's player ID
--	kProps,		(optional) properties about the leader
--					isUnique, no other leaders are like this one
--					isMasked, even if stats are show, hide their values.
-- ===========================================================================
function AddLeader(iconName, playerID, kProps)

  local isUnique = false
  if kProps == nil then kProps = {} end
  if kProps.isUnqiue then isUnqiue = kProps.isUnqiue end

  m_leadersMet = m_leadersMet + 1

  -- Create a new leader instance
  local leaderIcon, uiLeader = LeaderIcon:GetInstance(m_kLeaderIM)
  local uiPortraitButton = leaderIcon.Controls.SelectButton
  m_uiLeadersByID[playerID] = uiLeader
  m_uiLeadersByPortrait[uiPortraitButton] = uiLeader

  leaderIcon:UpdateIcon(iconName, playerID, isUnqiue)
  leaderIcon:RegisterCallback(Mouse.eLClick, function() OnLeaderClicked(playerID) end)

  --[[ CUI: disable vanilla events
    -- If using focus, setup mouse in/out callbacks... otherwise clear them.
    if 	m_ribbonStats == RibbonHUDStats.FOCUS then
    uiPortraitButton:RegisterMouseEnterCallback(
    function( uiControl )
    ShowStats( uiLeader );
    end
    );
    uiPortraitButton:RegisterMouseExitCallback(
    function( uiControl )
    HideStats( uiLeader );
    end
    );
    else
    uiPortraitButton:ClearMouseEnterCallback();
    uiPortraitButton:ClearMouseExitCallback();
    end
    ]]
  -- CUI: use advenced tooltip
  local allianceData = CuiGetAllianceData(playerID)
  LuaEvents.CuiLeaderIconToolTip(leaderIcon.Controls.Portrait, playerID)
  LuaEvents.CuiRelationshipToolTip(leaderIcon.Controls.Relationship, playerID, allianceData)
  --
  uiLeader.LeaderContainer:RegisterSizeChanged(function(uiControl) OnLeaderSizeChanged(uiLeader) end)

  FinishAddingLeader(playerID, uiLeader, kProps)

  -- Returning these so mods can override them and modify the icons
  return leaderIcon, uiLeader
end

-- ===========================================================================
--	Complete adding a leader.
--	Two steps for allowing easier MOD overrides/explansion.
-- ===========================================================================
function FinishAddingLeader(playerID, uiLeader, kProps)

  local isMasked = false
  if kProps.isMasked then isMasked = kProps.isMasked end

  -- Show fields for enabled victory types.
  local isHideScore = isMasked or (not (Game.IsVictoryEnabled("VICTORY_SCORE") or (not HasCapability("VICTORY_SCORE"))))
  local isHideMilitary = isMasked or
                             (not Game.IsVictoryEnabled("VICTORY_CONQUEST") or
                                 not GameCapabilities.HasCapability("CAPABILITY_DISPLAY_TOP_PANEL_YIELDS"))
  local isHideScience = isMasked or
                            (not HasCapability("CAPABILITY_SCIENCE") or
                                not GameCapabilities.HasCapability("CAPABILITY_DISPLAY_TOP_PANEL_YIELDS"))
  local isHideCulture = isMasked or
                            (not HasCapability("CAPABILITY_CULTURE") or
                                not GameCapabilities.HasCapability("CAPABILITY_DISPLAY_TOP_PANEL_YIELDS"))
  local isHideGold = isMasked or
                         (not HasCapability("CAPABILITY_GOLD") or not GameCapabilities.HasCapability("CAPABILITY_DISPLAY_TOP_PANEL_YIELDS"))
  local isHideFaith = isMasked or
                          (not HasCapability("CAPABILITY_RELIGION") or
                              not GameCapabilities.HasCapability("CAPABILITY_DISPLAY_TOP_PANEL_YIELDS"))

  uiLeader.Score:SetHide(isHideScore)
  uiLeader.Military:SetHide(isHideMilitary)
  uiLeader.Science:SetHide(isHideScience)
  uiLeader.Culture:SetHide(isHideCulture)
  uiLeader.Gold:SetHide(isHideGold)
  uiLeader.Faith:SetHide(isHideFaith)

  UpdateStatValues(playerID, uiLeader)
end

-- ===========================================================================
--	Clears leaders and re-adds them to the stack
-- ===========================================================================
function UpdateLeaders()

  ResetLeaders()

  m_ribbonStats = Options.GetUserOption("Interface", "RibbonStats")

  -- Add entries for everyone we know (Majors only)
  local kPlayers = PlayerManager.GetAliveMajors()
  local kMetPlayers = {}
  local kUniqueLeaders = {}

  local localPlayerID = Game.GetLocalPlayer()
  if localPlayerID ~= -1 then
    local localPlayer = Players[localPlayerID]
    local localDiplomacy = localPlayer:GetDiplomacy()
    table.sort(kPlayers, function(a, b) return localDiplomacy:GetMetTurn(a:GetID()) < localDiplomacy:GetMetTurn(b:GetID()) end)

    AddLeader("ICON_" .. PlayerConfigurations[localPlayerID]:GetLeaderTypeName(), localPlayerID, {}) -- First, add local player.
    kMetPlayers, kUniqueLeaders = GetMetPlayersAndUniqueLeaders() -- Fill table for other players.
  else
    -- No local player so assume it's auto-playing; show everyone.
    for _, pPlayer in ipairs(kPlayers) do
      local playerID = pPlayer:GetID()
      kMetPlayers[playerID] = true
      if (kUniqueLeaders[playerID] == nil) then
        kUniqueLeaders[playerID] = true
      else
        kUniqueLeaders[playerID] = false
      end
    end
  end

  -- Then, add the leader icons.
  for _, pPlayer in ipairs(kPlayers) do
    local playerID = pPlayer:GetID()
    if (playerID ~= localPlayerID) then
      local isMet = kMetPlayers[playerID]
      local pPlayerConfig = PlayerConfigurations[playerID]
      local isHumanMP = (GameConfiguration.IsAnyMultiplayer() and pPlayerConfig:IsHuman())
      if (isMet or isHumanMP) then
        local leaderName = pPlayerConfig:GetLeaderTypeName()
        local isMasked = (isMet == false) and isHumanMP -- Multiplayer human but haven't met
        local isUnique = kUniqueLeaders[leaderName]
        local iconName = "ICON_LEADER_DEFAULT"

        -- If in an MP game and a player leaves the name returned will be NIL.
        if isMet and (leaderName ~= nil) then iconName = "ICON_" .. leaderName end

        AddLeader(iconName, playerID, {isMasked = isMasked, isUnique = isUnique})
      end
    end
  end

  RealizeSize()
end

-- ===========================================================================
--	Updates size and location of BG and Scroll controls
--	additionalElementsWidth, from MODS that add additional content.
-- ===========================================================================
function RealizeSize(additionalElementsWidth)

  if additionalElementsWidth == nil then additionalElementsWidth = 0 end

  local MIN_LEFT_HOOKS = 260
  local RIGHT_HOOKS_INITIAL = 163
  local WORLD_TRACKER_OFFSET = 80 -- Amount of additional space the World Tracker check-box takes up.
  local launchBarWidth = MIN_LEFT_HOOKS
  local partialScreenBarWidth = RIGHT_HOOKS_INITIAL -- Width of the upper right-hand of screen.

  -- Loop through leaders in determining size.
  m_leaderInstanceHeight = 0
  for _, uiLeader in ipairs(m_uiLeadersByID) do
    -- If all are shown  then use max size.
    if m_ribbonStats == RibbonHUDStats.SHOW then
      m_leaderInstanceHeight = math.max(uiLeader.LeaderContainer:GetSizeY(), m_leaderInstanceHeight)
    else
      -- just the leader portrait.
      m_leaderInstanceHeight = uiLeader.SelectButton:GetSizeY()
    end
  end

  -- When not showing stats, leaders can be pushed closer together.
  if m_ribbonStats == RibbonHUDStats.SHOW then
    Controls.LeaderStack:SetStackPadding(0)
  else
    Controls.LeaderStack:SetStackPadding(-8)
  end
  Controls.LeaderStack:CalculateSize()

  -- Obtain controls
  local uiPartialScreenHookRoot = ContextPtr:LookUpControl("/InGame/PartialScreenHooks/RootContainer")
  local uiPartialScreenHookBar = ContextPtr:LookUpControl("/InGame/PartialScreenHooks/ButtonStack")
  local uiLaunchBar = ContextPtr:LookUpControl("/InGame/LaunchBar/ButtonStack")

  if (uiLaunchBar ~= nil) then launchBarWidth = math.max(uiLaunchBar:GetSizeX() + WORLD_TRACKER_OFFSET, MIN_LEFT_HOOKS) end
  if (uiPartialScreenHookBar ~= nil) then
    if uiPartialScreenHookRoot and uiPartialScreenHookRoot:IsVisible() then
      partialScreenBarWidth = uiPartialScreenHookBar:GetSizeX()
    else
      partialScreenBarWidth = 0 -- There are no partial screen hooks at all; backing is invisible.
    end
  end

  local screenWidth, screenHeight = UIManager:GetScreenSizeVal() -- Cache screen dimensions

  local SIZE_LEADER = 63 -- Size of leader icon and border.
  local paddingLeader = Controls.LeaderStack:GetStackPadding()
  local maxSize = screenWidth - launchBarWidth - partialScreenBarWidth
  local size = maxSize

  g_maxNumLeaders = math.floor(maxSize / (SIZE_LEADER + paddingLeader))

  if m_leadersMet > 0 then
    -- Compute size of the background shadow
    local BG_PADDING_EDGE = 50 -- Account for the (tons of) alpha on edges of shadow graphic.
    local MINIMUM_BG_SIZE = 100
    local bgSize = 0
    if (m_leadersMet > g_maxNumLeaders) then
      bgSize = g_maxNumLeaders * (SIZE_LEADER + paddingLeader) + additionalElementsWidth + BG_PADDING_EDGE
    else
      bgSize = m_leadersMet * (SIZE_LEADER + paddingLeader) + additionalElementsWidth + BG_PADDING_EDGE
    end
    bgSize = math.max(bgSize, MINIMUM_BG_SIZE)
    Controls.RibbonContainer:SetSizeX(bgSize)

    -- Compute actual size of the container
    local PADDING_EDGE = 8
    size = g_maxNumLeaders * (SIZE_LEADER + paddingLeader) + PADDING_EDGE + additionalElementsWidth
  end
  Controls.ScrollContainer:SetSizeX(size)
  Controls.ScrollContainer:SetSizeY(m_leaderInstanceHeight)
  Controls.LeaderScroll:SetSizeX(size)
  Controls.RibbonContainer:SetOffsetX(partialScreenBarWidth)
  Controls.LeaderScroll:CalculateSize()
  RealizeScroll()
end

-- ===========================================================================
--	Updates visibility of previous and next buttons
-- ===========================================================================
function RealizeScroll()
  Controls.NextButtonContainer:SetHide(not CanScrollLeft())
  Controls.PreviousButtonContainer:SetHide(not CanScrollRight())
end

-- ===========================================================================
function CanScrollLeft() return m_scrollIndex > 0 end
-- ===========================================================================
function CanScrollRight() return m_leadersMet - m_scrollIndex > g_maxNumLeaders end

-- ===========================================================================
--	Initialize scroll animation in a particular direction
-- ===========================================================================
function Scroll(direction)

  m_scrollPercent = 0
  m_scrollIndex = m_scrollIndex + direction

  if (m_scrollIndex < 0) then m_scrollIndex = 0 end

  if (not m_isScrolling) then
    ContextPtr:SetUpdate(UpdateScroll)
    m_isScrolling = true
  end

  RealizeScroll()
end

-- ===========================================================================
--	Update scroll animation (only called while animating)
-- ===========================================================================
function UpdateScroll(deltaTime)

  local start = Controls.LeaderScroll:GetScrollValue()
  local destination = 1.0 - (m_scrollIndex / (m_leadersMet - g_maxNumLeaders))

  m_scrollPercent = m_scrollPercent + (SCROLL_SPEED * deltaTime)
  if (m_scrollPercent >= 1) then
    m_scrollPercent = 1
    EndScroll()
  end

  Controls.LeaderScroll:SetScrollValue(start + (destination - start) * m_scrollPercent)
end

-- ===========================================================================
--	Cleans up scroll update callback when done scrollin
-- ===========================================================================
function EndScroll()
  ContextPtr:ClearUpdate()
  m_isScrolling = false
  RealizeScroll()
end

-- ===========================================================================
--	SystemUpdateUI Callback
-- ===========================================================================
function OnUpdateUI(type, tag, iData1, iData2, strData1) if (type == SystemUpdateUI.ScreenResize) then RealizeSize() end end

-- ===========================================================================
--	EVENT
--	Options menu changed
-- ===========================================================================
function OnUserOptionChanged(eOptionSet, hOptionKey, newOptionValue)
  local ribbonStatsHash = DB.MakeHash("RibbonStats")
  if hOptionKey == ribbonStatsHash then

    RealizeYieldEvents() -- Change subscription to events (if necessary)
    m_kLeaderIM:DestroyInstances() -- Look is changing, start with new instances.
    m_scrollIndex = 0 -- Reset scroll position to start.
    UpdateLeaders() -- Now update all the leaders.
    RealizeScroll()

    -- Play appropriate animations
    for id, _ in pairs(m_kActiveIds) do if Players[id] and Players[id]:IsTurnActive() then OnTurnBegin(id) end end
  end
end

-- ===========================================================================
--	EVENT
--	Diplomacy Callback
-- ===========================================================================
function OnDiplomacyMeet(player1ID, player2ID)

  local localPlayerID = Game.GetLocalPlayer()
  -- Have a local player?
  if (localPlayerID ~= -1) then
    -- Was the local player involved?
    if (player1ID == localPlayerID or player2ID == localPlayerID) then UpdateLeaders() end
  end
end

-- ===========================================================================
--	EVENT
--	Diplomacy Callback
-- ===========================================================================
function OnDiplomacyWarStateChange(player1ID, player2ID)

  local localPlayerID = Game.GetLocalPlayer()
  -- Have a local player?
  if (localPlayerID ~= -1) then
    -- Was the local player involved?
    if (player1ID == localPlayerID or player2ID == localPlayerID) then UpdateLeaders() end
  end
end

-- ===========================================================================
--	EVENT
--	Diplomacy Callback
-- ===========================================================================
function OnDiplomacySessionClosed(sessionID)

  local localPlayerID = Game.GetLocalPlayer()
  -- Have a local player?
  if (localPlayerID ~= -1) then
    -- Was the local player involved?
    local diplomacyInfo = DiplomacyManager.GetSessionInfo(sessionID)
    if (diplomacyInfo ~= nil and (diplomacyInfo.FromPlayer == localPlayerID or diplomacyInfo.ToPlayer == localPlayerID)) then
      UpdateLeaders()
    end
  end
end

-- ===========================================================================
--	EVENT
-- ===========================================================================
function OnInterfaceModeChanged(eOldMode, eNewMode)
  if eNewMode == InterfaceModeTypes.VIEW_MODAL_LENS then ContextPtr:SetHide(true) end
  if eOldMode == InterfaceModeTypes.VIEW_MODAL_LENS then ContextPtr:SetHide(false) end
end

-- ===========================================================================
function UpdateStatValues(playerID, uiLeader)

  local pPlayer = Players[playerID]

  if uiLeader.Score:IsVisible() then
    local score = Round(pPlayer:GetScore())
    uiLeader.Score:SetText("[ICON_Capital]" .. tostring(score))
  end

  if uiLeader.Military:IsVisible() then
    local military = Round(Players[playerID]:GetStats():GetMilitaryStrengthWithoutTreasury())
    uiLeader.Military:SetText("[ICON_Strength]" .. tostring(military))
  end

  if uiLeader.Science:IsVisible() then
    local science = Round(pPlayer:GetTechs():GetScienceYield())
    uiLeader.Science:SetText("[ICON_Science]" .. tostring(science))
  end

  if uiLeader.Culture:IsVisible() then
    local culture = Round(pPlayer:GetCulture():GetCultureYield())
    uiLeader.Culture:SetText("[ICON_Culture]" .. tostring(culture))
  end

  if uiLeader.Gold:IsVisible() then
    local pTreasury = pPlayer:GetTreasury()
    local gold = math.floor(pTreasury:GetGoldBalance())
    uiLeader.Gold:SetText("[ICON_Gold]" .. tostring(gold))
  end

  if uiLeader.Faith:IsVisible() then
    local faith = Round(Players[playerID]:GetReligion():GetFaithBalance())
    uiLeader.Faith:SetText("[ICON_Faith]" .. tostring(faith))
  end

  -- Show or hide all stats based on options.
  if m_ribbonStats == RibbonHUDStats.SHOW then
    if uiLeader.StatStack:IsHidden() or m_isIniting then ShowStats(uiLeader) end
  elseif m_ribbonStats == RibbonHUDStats.FOCUS or m_ribbonStats == RibbonHUDStats.HIDE then
    if uiLeader.StatStack:IsVisible() or m_isIniting then HideStats(uiLeader) end
  end

end

-- ===========================================================================
--	EVENT
-- ===========================================================================
function OnTurnBegin(playerID)
  local uiLeader = m_uiLeadersByID[playerID]
  if (uiLeader ~= nil) then
    UpdateStatValues(playerID, uiLeader)

    local localPlayerID = Game.GetLocalPlayer()
    if (localPlayerID == PlayerTypes.NONE or localPlayerID == PlayerTypes.OBSERVER) then return end
    -- Update the approripate animation (alpha vs slide) based on what mode is being used.
    if m_ribbonStats == RibbonHUDStats.SHOW then
      if (not (playerID == localPlayerID or Players[localPlayerID]:GetDiplomacy():HasMet(playerID))) then
        uiLeader.LeaderContainer:SetSizeVal(63, 63)
      end
      local pSize = uiLeader.LeaderContainer:GetSize()
      uiLeader.ActiveLeaderAndStats:SetSizeVal(pSize.x + LEADER_ART_OFFSET_X, pSize.y + LEADER_ART_OFFSET_Y)
      uiLeader.ActiveLeaderAndStats:SetToBeginning()
      uiLeader.ActiveLeaderAndStats:Play()
    else
      uiLeader.ActiveSlide:SetToBeginning()
      uiLeader.ActiveSlide:Play()
    end
  end

  -- Kluge: autoplay layout will frequently size ribbon before other panels and place it behind them in t he HUD.
  local isAutoPlay = (Game.GetLocalPlayer() == -1)
  if isAutoPlay then RealizeSize() end

  m_kActiveIds[playerID] = true
  UpdateLeaders()
end

-- ===========================================================================
function ResetActiveAnim(playerID)
  local uiLeader = m_uiLeadersByID[playerID]
  if (uiLeader ~= nil) then
    uiLeader.ActiveLeaderAndStats:SetToBeginning()
    uiLeader.ActiveSlide:SetToBeginning()
  end
end

-- ===========================================================================
--	EVENT
-- ===========================================================================
function OnTurnEnd(playerID)
  local uiLeader = m_uiLeadersByID[playerID]
  if (uiLeader ~= nil) then
    if m_ribbonStats == RibbonHUDStats.SHOW then
      uiLeader.ActiveLeaderAndStats:Reverse()
    else
      uiLeader.ActiveSlide:Reverse()
    end
  end
  m_kActiveIds[playerID] = nil
end

-- ===========================================================================
--	EVENT
-- ===========================================================================
function OnLocalTurnBegin()
  local playerID = Game.GetLocalPlayer()
  if playerID == -1 then return end
  OnTurnBegin(playerID)
end

-- ===========================================================================
--	EVENT
-- ===========================================================================
function OnLocalTurnEnd()
  local playerID = Game.GetLocalPlayer()
  if playerID == -1 then return end
  OnTurnEnd(playerID)
end

-- ===========================================================================
--	LUAEvent
-- ===========================================================================
function OnLaunchBarResized(width) RealizeSize() end

-- ===========================================================================
--	UI Callback
-- ===========================================================================
function OnScrollLeft() if CanScrollLeft() then Scroll(-1) end end

-- ===========================================================================
--	UI Callback
-- ===========================================================================
function OnScrollRight() if CanScrollRight() then Scroll(1) end end

-- ===========================================================================
function OnChatReceived(fromPlayer, stayOnScreen)
  local instance = m_uiLeadersByID[fromPlayer]
  if instance == nil then return end
  if stayOnScreen then
    Controls.ChatIndicatorWaitTimer:Stop()
    instance.ChatIndicatorFade:RegisterEndCallback(function() end)
    table.insert(m_uiChatIconsVisible, instance.ChatIndicatorFade)
  else
    Controls.ChatIndicatorWaitTimer:Stop()

    instance.ChatIndicatorFade:RegisterEndCallback(function()
      Controls.ChatIndicatorWaitTimer:RegisterEndCallback(function()
        instance.ChatIndicatorFade:RegisterEndCallback(function() instance.ChatIndicatorFade:SetToBeginning() end)
        instance.ChatIndicatorFade:Reverse()
      end)
      Controls.ChatIndicatorWaitTimer:SetToBeginning()
      Controls.ChatIndicatorWaitTimer:Play()
    end)
  end
  instance.ChatIndicatorFade:Play()
end

-- ===========================================================================
function OnChatPanelShown(fromPlayer, stayOnScreen)
  for _, chatIndicatorFade in ipairs(m_uiChatIconsVisible) do
    chatIndicatorFade:RegisterEndCallback(function() chatIndicatorFade:SetToBeginning() end)
    chatIndicatorFade:Reverse()
  end
  chatIndicatorFade = {}
end

-- ===========================================================================
function OnLoadGameViewStateDone()
  if (GameConfiguration.IsAnyMultiplayer()) then
    for leaderID, uiLeader in pairs(m_uiLeadersByID) do
      if Players[leaderID]:IsTurnActive() then
        uiLeader.ActiveLeaderAndStats:SetToBeginning()
        uiLeader.ActiveLeaderAndStats:Play()
      end
    end
  end
end

-- ===========================================================================
--	UI Callback
--	Refresh the stats.
-- ===========================================================================
function OnRefresh()
  ContextPtr:ClearRequestRefresh()

  if table.count(g_kRefreshRequesters) > 0 then
    local localPlayerID = Game.GetLocalPlayer()
    if localPlayerID ~= -1 and Players[localPlayerID]:IsTurnActive() then
      local uiLeader = m_uiLeadersByID[localPlayerID]
      if uiLeader ~= nil then UpdateStatValues(localPlayerID, uiLeader) end
    end
  else
    UI.DataError("Attempt to refresh diplomacy ribbon stats but no event triggered the refresh!")
  end
  g_kRefreshRequesters = {} -- Clear out for next refresh
end
-- ===========================================================================
--	Event
--	Special from most other yield events as this may trigger on players other
--	than the local player for actions such as making a deal.
-- ===========================================================================
function OnTreasuryChanged(playerID, yield, balance)
  local uiLeader = m_uiLeadersByID[playerID]
  if uiLeader ~= nil then UpdateStatValues(playerID, uiLeader) end
  -- If refresh is pending for local player, it can be cleared.
  if playerID == Game.GetLocalPlayer() and table.count(g_kRefreshRequesters) > 0 then ContextPtr:ClearRequestRefresh() end
end

-- ===========================================================================
--	Only the local player's yields should be update by event to prevent
--	multiplay changes that telgraph to others what is occuring.
-- ===========================================================================
function OnLocalStatUpdateRequest(eventName)
  table.insert(g_kRefreshRequesters, eventName)
  ContextPtr:RequestRefresh()
end

-- ===========================================================================
--	Define EVENT callback functions so they can be added/removed based on
--	whether or not yield stats are being shown.
-- ===========================================================================
OnAnarchyBegins = function() OnLocalStatUpdateRequest("OnAnarchyBegins") end
OnAnarchyEnds = function() OnLocalStatUpdateRequest("OnAnarchyEnds") end
OnCityFocusChanged = function() OnLocalStatUpdateRequest("OnCityFocusChanged") end
OnCityInitialized = function() OnLocalStatUpdateRequest("OnCityInitialized") end
OnCityProductionChanged = function() OnLocalStatUpdateRequest("OnCityProductionChanged") end
OnCityWorkerChanged = function() OnLocalStatUpdateRequest("OnCityWorkerChanged") end
OnDiplomacySessionClosed = function() OnLocalStatUpdateRequest("OnDiplomacySessionClosed") end
OnFaithChanged = function() OnLocalStatUpdateRequest("OnFaithChanged") end
OnGovernmentChanged = function() OnLocalStatUpdateRequest("OnGovernmentChanged") end
OnGovernmentPolicyChanged = function() OnLocalStatUpdateRequest("OnGovernmentPolicyChanged") end
OnGovernmentPolicyObsoleted = function() OnLocalStatUpdateRequest("OnGovernmentPolicyObsoleted") end
OnGreatWorkCreated = function() OnLocalStatUpdateRequest("OnGreatWorkCreated") end
OnImprovementAddedToMap = function() OnLocalStatUpdateRequest("OnImprovementAddedToMap") end
OnImprovementRemovedFromMap = function() OnLocalStatUpdateRequest("OnImprovementRemovedFromMap") end
OnPantheonFounded = function() OnLocalStatUpdateRequest("OnPantheonFounded") end
OnPlayerAgeChanged = function() OnLocalStatUpdateRequest("OnPlayerAgeChanged") end
OnResearchCompleted = function() OnLocalStatUpdateRequest("OnResearchCompleted") end
OnUnitAddedToMap = function() OnLocalStatUpdateRequest("OnUnitAddedToMap") end
OnUnitGreatPersonActivated = function() OnLocalStatUpdateRequest("OnUnitGreatPersonActivated") end
OnUnitKilledInCombat = function() OnLocalStatUpdateRequest("OnUnitKilledInCombat") end
OnUnitRemovedFromMap = function() OnLocalStatUpdateRequest("OnUnitRemovedFromMap") end

-- ===========================================================================
function SubscribeYieldEvents()
  m_isYieldsSubscribed = true

  Events.AnarchyBegins.Add(OnAnarchyBegins)
  Events.AnarchyEnds.Add(OnAnarchyEnds)
  Events.CityFocusChanged.Add(OnCityFocusChanged)
  Events.CityInitialized.Add(OnCityInitialized)
  Events.CityProductionChanged.Add(OnCityProductionChanged)
  Events.CityWorkerChanged.Add(OnCityWorkerChanged)
  Events.FaithChanged.Add(OnFaithChanged)
  Events.GovernmentChanged.Add(OnGovernmentChanged)
  Events.GovernmentPolicyChanged.Add(OnGovernmentPolicyChanged)
  Events.GovernmentPolicyObsoleted.Add(OnGovernmentPolicyObsoleted)
  Events.GreatWorkCreated.Add(OnGreatWorkCreated)
  Events.ImprovementAddedToMap.Add(OnImprovementAddedToMap)
  Events.ImprovementRemovedFromMap.Add(OnImprovementRemovedFromMap)
  Events.PantheonFounded.Add(OnPantheonFounded)
  Events.PlayerAgeChanged.Add(OnPlayerAgeChanged)
  Events.ResearchCompleted.Add(OnResearchCompleted)
  Events.TreasuryChanged.Add(OnTreasuryChanged)
  Events.UnitAddedToMap.Add(OnUnitAddedToMap)
  Events.UnitGreatPersonActivated.Add(OnUnitGreatPersonActivated)
  Events.UnitKilledInCombat.Add(OnUnitKilledInCombat)
  Events.UnitRemovedFromMap.Add(OnUnitRemovedFromMap)
end

-- ===========================================================================
function UnsubscribeYieldEvents()
  m_isYieldsSubscribed = false

  Events.AnarchyBegins.Remove(OnAnarchyBegins)
  Events.AnarchyEnds.Remove(OnAnarchyEnds)
  Events.CityFocusChanged.Remove(OnCityFocusChanged)
  Events.CityInitialized.Remove(OnCityInitialized)
  Events.CityProductionChanged.Remove(OnCityProductionChanged)
  Events.CityWorkerChanged.Remove(OnCityWorkerChanged)
  Events.FaithChanged.Remove(OnFaithChanged)
  Events.GovernmentChanged.Remove(OnGovernmentChanged)
  Events.GovernmentPolicyChanged.Remove(OnGovernmentPolicyChanged)
  Events.GovernmentPolicyObsoleted.Remove(OnGovernmentPolicyObsoleted)
  Events.GreatWorkCreated.Remove(OnGreatWorkCreated)
  Events.ImprovementAddedToMap.Remove(OnImprovementAddedToMap)
  Events.ImprovementRemovedFromMap.Remove(OnImprovementRemovedFromMap)
  Events.PantheonFounded.Remove(OnPantheonFounded)
  Events.PlayerAgeChanged.Remove(OnPlayerAgeChanged)
  Events.ResearchCompleted.Remove(OnResearchCompleted)
  Events.TreasuryChanged.Remove(OnTreasuryChanged)
  Events.UnitAddedToMap.Remove(OnUnitAddedToMap)
  Events.UnitGreatPersonActivated.Remove(OnUnitGreatPersonActivated)
  Events.UnitKilledInCombat.Remove(OnUnitKilledInCombat)
  Events.UnitRemovedFromMap.Remove(OnUnitRemovedFromMap)
end

-- ===========================================================================
--	Only listen for events related to yield updates if they are showing.
-- ===========================================================================
function RealizeYieldEvents()
  if m_ribbonStats == RibbonHUDStats.HIDE then
    if m_isYieldsSubscribed == false then
      return -- Already un-subscribed.
    end
    UnsubscribeYieldEvents()
  else
    if m_isYieldsSubscribed then return end -- Already subscribed.
    SubscribeYieldEvents()
  end
end

-- ===========================================================================
--	CALLBACK
-- ===========================================================================
function OnShutdown()
  if m_isYieldsSubscribed then UnsubscribeYieldEvents() end

  Events.DiplomacyDeclareWar.Remove(OnDiplomacyWarStateChange)
  Events.DiplomacyMakePeace.Remove(OnDiplomacyWarStateChange)
  Events.DiplomacyMeet.Remove(OnDiplomacyMeet)
  Events.DiplomacyRelationshipChanged.Remove(UpdateLeaders)
  Events.DiplomacySessionClosed.Remove(OnDiplomacySessionClosed)
  Events.InterfaceModeChanged.Remove(OnInterfaceModeChanged)
  Events.LoadGameViewStateDone.Remove(OnLoadGameViewStateDone)
  Events.LocalPlayerChanged.Remove(UpdateLeaders)
  Events.LocalPlayerTurnBegin.Remove(OnLocalTurnBegin)
  Events.LocalPlayerTurnEnd.Remove(OnLocalTurnEnd)
  Events.MultiplayerPlayerConnected.Remove(UpdateLeaders)
  Events.MultiplayerPostPlayerDisconnected.Remove(UpdateLeaders)
  Events.PlayerInfoChanged.Remove(UpdateLeaders)
  Events.PlayerDefeat.Remove(UpdateLeaders)
  Events.PlayerRestored.Remove(UpdateLeaders)
  Events.RemotePlayerTurnBegin.Remove(OnTurnBegin)
  Events.RemotePlayerTurnEnd.Remove(OnTurnEnd)
  Events.SystemUpdateUI.Remove(OnUpdateUI)
  Events.UserOptionChanged.Remove(OnUserOptionChanged)

  LuaEvents.ChatPanel_OnChatReceived.Remove(OnChatReceived)
  LuaEvents.LaunchBar_Resize.Remove(OnLaunchBarResized)
  LuaEvents.PartialScreenHooks_Realize.Remove(RealizeSize)
  LuaEvents.WorldTracker_OnChatShown.Remove(OnChatPanelShown)
end

-- ===========================================================================
function LateInitialize()
  RealizeYieldEvents()

  ContextPtr:SetRefreshHandler(OnRefresh)

  Controls.NextButton:RegisterCallback(Mouse.eLClick, OnScrollLeft)
  Controls.PreviousButton:RegisterCallback(Mouse.eLClick, OnScrollRight)
  Controls.LeaderScroll:SetScrollValue(1)

  Events.DiplomacyDeclareWar.Add(OnDiplomacyWarStateChange)
  Events.DiplomacyMakePeace.Add(OnDiplomacyWarStateChange)
  Events.DiplomacyMeet.Add(OnDiplomacyMeet)
  Events.DiplomacyRelationshipChanged.Add(UpdateLeaders)
  Events.DiplomacySessionClosed.Add(OnDiplomacySessionClosed)
  Events.InterfaceModeChanged.Add(OnInterfaceModeChanged)
  Events.LoadGameViewStateDone.Add(OnLoadGameViewStateDone)
  Events.LocalPlayerChanged.Add(UpdateLeaders)
  Events.LocalPlayerTurnBegin.Add(OnLocalTurnBegin)
  Events.LocalPlayerTurnEnd.Add(OnLocalTurnEnd)
  Events.MultiplayerPlayerConnected.Add(UpdateLeaders)
  Events.MultiplayerPostPlayerDisconnected.Add(UpdateLeaders)
  Events.PlayerInfoChanged.Add(UpdateLeaders)
  Events.PlayerDefeat.Add(UpdateLeaders)
  Events.PlayerRestored.Add(UpdateLeaders)
  Events.RemotePlayerTurnBegin.Add(OnTurnBegin)
  Events.RemotePlayerTurnEnd.Add(OnTurnEnd)
  Events.SystemUpdateUI.Add(OnUpdateUI)
  Events.UserOptionChanged.Add(OnUserOptionChanged)

  LuaEvents.ChatPanel_OnChatReceived.Add(OnChatReceived)
  LuaEvents.LaunchBar_Resize.Add(OnLaunchBarResized)
  LuaEvents.PartialScreenHooks_Realize.Add(RealizeSize)
  LuaEvents.WorldTracker_OnChatShown.Add(OnChatPanelShown)

  if not BASE_LateInitialize then -- Only update leaders if this is the last in the call chain.
    UpdateLeaders()
  end
end

-- ===========================================================================
function OnInit(isReload)
  LateInitialize()
  m_isIniting = false

  local localPlayerID = Game.GetLocalPlayer()
  if localPlayerID ~= -1 and Players[localPlayerID]:IsTurnActive() then OnLocalTurnBegin() end
end

-- ===========================================================================
--	Main Initialize
-- ===========================================================================
function Initialize()
  ContextPtr:SetInitHandler(OnInit)
  ContextPtr:SetShutdown(OnShutdown)
end
Initialize()
