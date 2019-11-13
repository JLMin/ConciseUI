----------------------------------------------------------------
-- MapPinPopup
--
-- Popup used for creating and editting map pins.
----------------------------------------------------------------
include("PlayerTargetLogic")
include("ToolTipHelper") -- CUI
include("cui_settings") -- CUI

----------------------------------------------------------------
-- Globals
----------------------------------------------------------------
local COLOR_YELLOW = UI.GetColorValue("COLOR_YELLOW")
local COLOR_WHITE = UI.GetColorValue("COLOR_WHITE")

local NO_EDIT_PIN_ID = -1
local g_editPinID = NO_EDIT_PIN_ID
local g_iconOptionEntries = {}
local g_visibilityTargetEntries = {}

local g_desiredIconName = ""

-- Default player target is self only.
local g_playerTarget = {targetType = ChatTargetTypes.CHATTARGET_PLAYER, targetID = Game.GetLocalPlayer()}
local g_cachedChatPanelTarget = nil -- Cached player target for ingame chat panel

-- When we aren't quite so crunched on time, it would be good to add the map pins table to the database
-- CUI: change "name" to "name", name == nil
local defaultIcons = {
  {icon = "ICON_MAP_PIN_STRENGTH"}, {icon = "ICON_MAP_PIN_RANGED"}, {icon = "ICON_MAP_PIN_BOMBARD"}, {icon = "ICON_MAP_PIN_DISTRICT"},
  {icon = "ICON_MAP_PIN_CHARGES"}, {icon = "ICON_MAP_PIN_DEFENSE"}, {icon = "ICON_MAP_PIN_MOVEMENT"}, {icon = "ICON_MAP_PIN_NO"},
  {icon = "ICON_MAP_PIN_PLUS"}, {icon = "ICON_MAP_PIN_CIRCLE"}, {icon = "ICON_MAP_PIN_TRIANGLE"}, {icon = "ICON_MAP_PIN_SUN"},
  {icon = "ICON_MAP_PIN_SQUARE"}, {icon = "ICON_MAP_PIN_DIAMOND"}
}

local g_iconPulldownOptions = {}

local sendToChatTTStr = Locale.Lookup("LOC_MAP_PIN_SEND_TO_CHAT_TT")
local sendToChatNotVisibleTTStr = Locale.Lookup("LOC_MAP_PIN_SEND_TO_CHAT_NOT_VISIBLE_TT")

-------------------------------------------------------------------------------
--
-------------------------------------------------------------------------------
function MapPinVisibilityToPlayerTarget(mapPinVisibility, playerTargetData)
  if (mapPinVisibility == ChatTargetTypes.CHATTARGET_ALL) then
    playerTargetData.targetType = ChatTargetTypes.CHATTARGET_ALL
    playerTargetData.targetID = GetNoPlayerTargetID()
  elseif (mapPinVisibility == ChatTargetTypes.CHATTARGET_TEAM) then
    local localPlayerID = Game.GetLocalPlayer()
    local localPlayer = PlayerConfigurations[localPlayerID]
    local localTeam = localPlayer:GetTeam()
    playerTargetData.targetType = ChatTargetTypes.CHATTARGET_TEAM
    playerTargetData.targetID = localTeam
  elseif (mapPinVisibility >= 0) then
    -- map pin visibility stores individual player targets as a straight positive number
    playerTargetData.targetType = ChatTargetTypes.CHATTARGET_PLAYER
    playerTargetData.targetID = mapPinVisibility
  else
    -- Unknown map pin visibility state
    playerTargetData.targetType = ChatTargetTypes.NO_CHATTARGET
    playerTargetData.targetID = GetNoPlayerTargetID()
  end
end

function PlayerTargetToMapPinVisibility(playerTargetData)
  if (playerTargetData.targetType == ChatTargetTypes.CHATTARGET_ALL) then
    return ChatTargetTypes.CHATTARGET_ALL
  elseif (playerTargetData.targetType == ChatTargetTypes.CHATTARGET_TEAM) then
    return ChatTargetTypes.CHATTARGET_TEAM
  elseif (playerTargetData.targetType == ChatTargetTypes.CHATTARGET_PLAYER) then
    -- map pin visibility stores individual player targets as a straight positive number
    return playerTargetData.targetID
  end

  return ChatTargetTypes.NO_CHATTARGET
end

function MapPinIsVisibleToChatTarget(mapPinVisibility, chatPlayerTarget)
  if (chatPlayerTarget == nil or mapPinVisibility == nil) then return false end

  if (mapPinVisibility == ChatTargetTypes.CHATTARGET_ALL) then
    -- All pins are visible to all
    return true
  elseif (mapPinVisibility == ChatTargetTypes.CHATTARGET_TEAM) then
    -- Team pins are visible in that team's chat and whispers to anyone on that team.
    local localPlayerID = Game.GetLocalPlayer()
    local localPlayer = PlayerConfigurations[localPlayerID]
    local localTeam = localPlayer:GetTeam()
    if (chatPlayerTarget.targetType == ChatTargetTypes.CHATTARGET_TEAM) then
      if (localTeam == chatPlayerTarget.targetID) then return true end
    elseif (chatPlayerTarget.targetType == ChatTargetTypes.CHATTARGET_PLAYER and chatPlayerTarget.targetID ~= NO_PLAYERTARGET_ID) then
      local chatPlayerID = chatPlayerTarget.targetID
      local chatPlayer = PlayerConfigurations[chatPlayerID]
      local chatTeam = chatPlayer:GetTeam()
      if (localTeam == chatTeam) then return true end
    end
  elseif (mapPinVisibility >= 0) then
    -- Individual map pin is only visible to that player.
    if (chatPlayerTarget.targetType == ChatTargetTypes.CHATTARGET_PLAYER and mapPinVisibility == chatPlayerTarget.targetID) then
      return true
    end
  end

  return false
end

-------------------------------------------------------------------------------
--
-------------------------------------------------------------------------------
function SetMapPinIcon(imageControl, mapPinIconName)
  if (imageControl ~= nil and mapPinIconName ~= nil) then imageControl:SetIcon(mapPinIconName) end
end

-- ===========================================================================
function PopulateIconOptions()
  g_iconOptionEntries = {}
  g_iconPulldownOptions = {}

  Controls.IconOptionStackDefault:DestroyAllChildren()
  Controls.IconOptionStackDistricts:DestroyAllChildren()
  Controls.IconOptionStackWonders:DestroyAllChildren()

  local defaultStack = Controls.IconOptionStackDefault
  local districtStack = Controls.IconOptionStackDistricts
  local wonderStack = Controls.IconOptionStackWonders

  local count = 1

  -- CUI: default icons
  for _, item in ipairs(defaultIcons) do
    CuiCreateIconEntry(defaultStack, nil, item.icon, nil, count)
    count = count + 1
  end

  -- CUI: districts icons
  if CuiSettings:GetBoolean(CuiSettings.SHOW_DISTRICTS) then
    local districtIcons = CuiGetDistrictIcons()
    for _, item in ipairs(districtIcons) do
      CuiCreateIconEntry(districtStack, item.name, item.icon, item.tooltip, count)
      count = count + 1
    end
  end

  -- CUI: wonders icons
  if CuiSettings:GetBoolean(CuiSettings.SHOW_WONDERS) then
    local wonderIcons = CuiGetWonderIcons()
    for _, item in ipairs(wonderIcons) do
      CuiCreateIconEntry(wonderStack, item.name, item.icon, item.tooltip, count)
      count = count + 1
    end
  end

  -- CUI
  Controls.IconOptionStackDefault:CalculateSize()
  Controls.IconOptionStackDefault:ReprocessAnchoring()
  Controls.IconOptionStackDistricts:CalculateSize()
  Controls.IconOptionStackDistricts:ReprocessAnchoring()
  Controls.IconOptionStackWonders:CalculateSize()
  Controls.IconOptionStackWonders:ReprocessAnchoring()
  --
  Controls.OptionsStack:CalculateSize()
  Controls.OptionsStack:ReprocessAnchoring()
  Controls.WindowContentsStack:CalculateSize()
  Controls.WindowContentsStack:ReprocessAnchoring()
  Controls.WindowStack:CalculateSize()
  Controls.WindowStack:ReprocessAnchoring()
  Controls.WindowContainer:ReprocessAnchoring()
end

-- ===========================================================================
function UpdateIconOptionColors() for iconIndex, iconEntry in pairs(g_iconOptionEntries) do UpdateIconOptionColor(iconIndex) end end

-- ===========================================================================
function UpdateIconOptionColor(iconEntryIndex)
  local iconEntry = g_iconOptionEntries[iconEntryIndex]
  if (iconEntry ~= nil) then
    if (iconEntry.IconName == g_desiredIconName) then
      -- Selected icon
      iconEntry.Instance.IconOptionButton:SetSelected(true)
    else
      iconEntry.Instance.IconOptionButton:SetSelected(false)
    end
  end
end

-- ===========================================================================
function RequestMapPin(hexX, hexY)
  local activePlayerID = Game.GetLocalPlayer()
  local pPlayerCfg = PlayerConfigurations[activePlayerID]
  local pMapPin = pPlayerCfg:GetMapPin(hexX, hexY)
  if (pMapPin ~= nil) then
    g_editPinID = pMapPin:GetID()
    g_desiredIconName = pMapPin:GetIconName()
    if GameConfiguration.IsAnyMultiplayer() then
      MapPinVisibilityToPlayerTarget(pMapPin:GetVisibility(), g_playerTarget)
      UpdatePlayerTargetPulldown(Controls.VisibilityPull, g_playerTarget)
      Controls.VisibilityContainer:SetHide(false)
    else
      Controls.VisibilityContainer:SetHide(true)
    end

    Controls.PinName:SetText(pMapPin:GetName())
    Controls.PinName:TakeFocus()

    UpdateIconOptionColors()
    ShowHideSendToChatButton()

    -- CUI
    Controls.IconOptionStackDefault:CalculateSize()
    Controls.IconOptionStackDefault:ReprocessAnchoring()
    Controls.IconOptionStackDistricts:CalculateSize()
    Controls.IconOptionStackDistricts:ReprocessAnchoring()
    Controls.IconOptionStackWonders:CalculateSize()
    Controls.IconOptionStackWonders:ReprocessAnchoring()
    --
    Controls.OptionsStack:CalculateSize()
    Controls.OptionsStack:ReprocessAnchoring()
    Controls.WindowContentsStack:CalculateSize()
    Controls.WindowContentsStack:ReprocessAnchoring()
    Controls.WindowStack:CalculateSize()
    Controls.WindowStack:ReprocessAnchoring()
    Controls.WindowContainer:ReprocessAnchoring()

    UIManager:QueuePopup(ContextPtr, PopupPriority.Current)
    Controls.PopupAlphaIn:SetToBeginning()
    Controls.PopupAlphaIn:Play()
    Controls.PopupSlideIn:SetToBeginning()
    Controls.PopupSlideIn:Play()
  end
end

-- ===========================================================================
-- Returns the map pin configuration for the pin we are currently editing.
-- Do not cache the map pin configuration because it will get destroyed by other processes.  Use it and get out!
function GetEditPinConfig()
  if (g_editPinID ~= NO_EDIT_PIN_ID) then
    local activePlayerID = Game.GetLocalPlayer()
    local pPlayerCfg = PlayerConfigurations[activePlayerID]
    local pMapPin = pPlayerCfg:GetMapPinID(g_editPinID)
    return pMapPin
  end

  return nil
end

-- ===========================================================================
function OnChatPanel_PlayerTargetChanged(playerTargetTable)
  g_cachedChatPanelTarget = playerTargetTable
  if (not ContextPtr:IsHidden()) then ShowHideSendToChatButton() end
end

-- ===========================================================================
function ShowHideSendToChatButton()
  local editPin = GetEditPinConfig()
  if (editPin == nil) then return end

  local privatePin = editPin:IsPrivate()
  local showSendButton = GameConfiguration.IsNetworkMultiplayer() and not privatePin

  Controls.SendToChatButton:SetHide(not showSendButton)

  -- Send To Chat disables itself if the current chat panel target is not visible to the map pin.
  if (showSendButton) then
    local chatVisible = MapPinIsVisibleToChatTarget(editPin:GetVisibility(), g_cachedChatPanelTarget)
    Controls.SendToChatButton:SetDisabled(not chatVisible)
    if (chatVisible) then
      Controls.SendToChatButton:SetToolTipString(sendToChatTTStr)
    else
      Controls.SendToChatButton:SetToolTipString(sendToChatNotVisibleTTStr)
    end
  end
end

-- ===========================================================================
function OnIconOption(iconPulldownIndex, notUsed)
  local iconOptions = g_iconPulldownOptions[iconPulldownIndex]
  if (iconOptions) then
    local newIconName = iconOptions.icon
    g_desiredIconName = newIconName
    -- CUI: set default name
    local needSetName = CuiSettings:GetBoolean(CuiSettings.AUTO_NAMING)
    if needSetName then
      if iconOptions.name then
        Controls.PinName:SetText(Locale.Lookup(iconOptions.name))
      else
        Controls.PinName:SetText("")
      end
    end
    --
    UpdateIconOptionColors()
  end
end

-- ===========================================================================
function OnOk()
  if (not ContextPtr:IsHidden()) then
    local editPin = GetEditPinConfig()
    if (editPin ~= nil) then
      editPin:SetName(Controls.PinName:GetText())
      editPin:SetIconName(g_desiredIconName)

      local newMapPinVisibility = PlayerTargetToMapPinVisibility(g_playerTarget)
      editPin:SetVisibility(newMapPinVisibility)

      Network.BroadcastPlayerInfo()
      UI.PlaySound("Map_Pin_Add")
    end

    UIManager:DequeuePopup(ContextPtr)
  end
end

-- ===========================================================================
function OnSendToChatButton()
  local editPinCfg = GetEditPinConfig()
  if (editPinCfg ~= nil) then
    editPinCfg:SetName(Controls.PinName:GetText())
    LuaEvents.MapPinPopup_SendPinToChat(editPinCfg:GetPlayerID(), editPinCfg:GetID())
  end
end

-- ===========================================================================
function OnDelete()
  local editPinCfg = GetEditPinConfig()
  if (editPinCfg ~= nil) then
    local activePlayerID = Game.GetLocalPlayer()
    local pPlayerCfg = PlayerConfigurations[activePlayerID]
    local deletePinID = editPinCfg:GetID()

    g_editPinID = NO_EDIT_PIN_ID
    pPlayerCfg:DeleteMapPin(deletePinID)
    Network.BroadcastPlayerInfo()
    UI.PlaySound("Map_Pin_Remove")
  end
  UIManager:DequeuePopup(ContextPtr)
end

function OnCancel() UIManager:DequeuePopup(ContextPtr) end
----------------------------------------------------------------
-- Event Handlers
----------------------------------------------------------------
function OnMapPinPlayerInfoChanged(playerID)
  PlayerTarget_OnPlayerInfoChanged(playerID, Controls.VisibilityPull, nil, nil, g_visibilityTargetEntries, g_playerTarget, true)
end

function OnLocalPlayerChanged()
  g_playerTarget.targetID = Game.GetLocalPlayer()
  PopulateTargetPull(Controls.VisibilityPull, nil, nil, g_visibilityTargetEntries, g_playerTarget, true, OnVisibilityPull)

  if (not ContextPtr:IsHidden()) then UIManager:DequeuePopup(ContextPtr) end
end

-- ===========================================================================
--	Keyboard INPUT Handler
-- ===========================================================================
function KeyHandler(key)
  if (key == Keys.VK_ESCAPE) then
    OnCancel()
    return true
  end
  return false
end
-- ===========================================================================
--	UI Event
-- ===========================================================================
function OnInputHandler(pInputStruct)
  local uiMsg = pInputStruct:GetMessageType()
  if uiMsg == KeyEvents.KeyUp then return KeyHandler(pInputStruct:GetKey()) end
  return false
end

-- CUI =======================================================================
function CuiGetDistrictIcons()
  local icons = {}
  local pPlayer = Game.GetLocalPlayer()
  local pConfig = PlayerConfigurations[pPlayer]
  local pLeader = GameInfo.Leaders[pConfig:GetLeaderTypeID()]
  local pCiv = pLeader.CivilizationCollection[1]

  -- check leader & civ unique
  local unique = {}
  for _, item in ipairs(pLeader.TraitCollection) do unique[item.TraitType] = true end
  for _, item in ipairs(pCiv.TraitCollection) do unique[item.TraitType] = true end

  -- mark unique
  local districts = {}
  for item in GameInfo.Districts() do
    if unique[item.TraitType] then
      for _, swap in ipairs(item.ReplacesCollection) do
        local type = swap.ReplacesDistrictType
        districts[type] = item
      end
    end
  end

  -- insert
  for item in GameInfo.Districts() do
    local type = item.DistrictType
    if districts[type] then
      table.insert(icons, CuiGetIconByItem(districts[type]))
    elseif item.TraitType then
      -- do nothing;
    elseif type ~= "DISTRICT_WONDER" then
      table.insert(icons, CuiGetIconByItem(item))
    end
  end
  table.insert(icons, CuiGetIconByItem(GameInfo.Districts.DISTRICT_WONDER))

  return icons
end

-- CUI =======================================================================
function CuiGetWonderIcons()
  local icons = {}

  for item in GameInfo.Buildings() do if item.IsWonder then table.insert(icons, CuiGetIconByItem(item)) end end

  return icons
end

-- CUI =======================================================================
function CuiGetIconByItem(item)
  local name = nil
  local icon = nil
  local tooltip = nil

  if item.DistrictType then
    icon = "ICON_" .. item.DistrictType
    if item.CityCenter or item.InternalOnly then
      tooltip = item.Name
    else
      tooltip = item.DistrictType
    end
  elseif item.BuildingType then
    icon = "ICON_" .. item.BuildingType
    tooltip = item.BuildingType
  end
  name = item.Name

  return {name = name, icon = icon, tooltip = tooltip}
end

-- CUI =======================================================================
function CuiCreateIconEntry(instance, name, icon, tooltip, index)
  local controlTable = {}
  local newIconEntry = {}
  ContextPtr:BuildInstanceForControl("IconOptionInstance", controlTable, instance)
  SetMapPinIcon(controlTable.Icon, icon)
  controlTable.IconOptionButton:SetVoids(index, -1)
  controlTable.IconOptionButton:RegisterCallback(Mouse.eLClick, OnIconOption)

  if (tooltip ~= nil) then
    local finalTT = ToolTipHelper.GetToolTip(tooltip, Game.GetLocalPlayer()) or Locale.Lookup(tooltip)
    controlTable.IconOptionButton:SetToolTipString(finalTT)
  end

  table.insert(g_iconPulldownOptions, {name = name, icon = icon, tooltip = tooltip})

  newIconEntry.IconName = icon
  newIconEntry.Instance = controlTable
  g_iconOptionEntries[index] = newIconEntry

  UpdateIconOptionColor(index)
end

-- CUI =======================================================================
function CuiRefresh()
  PopulateIconOptions()
  local ShowDistricts = CuiSettings:GetBoolean(CuiSettings.SHOW_DISTRICTS)
  local ShowWonders = CuiSettings:GetBoolean(CuiSettings.SHOW_WONDERS)
  Controls.DistrictsDivider:SetHide(not ShowDistricts)
  Controls.WondersDivider:SetHide(not ShowWonders)
end

-- ===========================================================================
--	INITIALIZE
-- ===========================================================================
function Initialize()
  ContextPtr:SetInputHandler(OnInputHandler, true)

  -- CUI
  LuaEvents.CuiMapPinSettingChange.Add(CuiRefresh)
  CuiRefresh()
  -- PopulateIconOptions();
  PopulateTargetPull(Controls.VisibilityPull, nil, nil, g_visibilityTargetEntries, g_playerTarget, true, OnVisibilityPull)
  Controls.DeleteButton:RegisterCallback(Mouse.eLClick, OnDelete)
  Controls.DeleteButton:RegisterCallback(Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over") end)
  Controls.SendToChatButton:RegisterCallback(Mouse.eLClick, OnSendToChatButton)
  Controls.SendToChatButton:RegisterCallback(Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over") end)
  Controls.OkButton:RegisterCallback(Mouse.eLClick, OnOk)
  Controls.OkButton:RegisterCallback(Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over") end)
  Controls.PinName:RegisterCommitCallback(OnOk)

  LuaEvents.MapPinPopup_RequestMapPin.Add(RequestMapPin)
  LuaEvents.ChatPanel_PlayerTargetChanged.Add(OnChatPanel_PlayerTargetChanged)

  -- When player info is changed, this pulldown needs to know so it can update itself if it becomes invalid.
  Events.PlayerInfoChanged.Add(OnMapPinPlayerInfoChanged)
  Events.LocalPlayerChanged.Add(OnLocalPlayerChanged)

  -- Request the chat panel's player target so we have an initial value.
  -- We have to do this because the map pin's context is loaded after the chat panel's
  -- and the chat panel's show/hide handler is not triggered as expected.
  LuaEvents.MapPinPopup_RequestChatPlayerTarget()

  local canChangeName = GameCapabilities.HasCapability("CAPABILITY_RENAME")
  if (not canChangeName) then Controls.PinFrame:SetHide(true) end

end
Initialize()
