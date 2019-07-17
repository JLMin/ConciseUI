-- ===========================================================================
-- Cui Civilizaiton Assistant
-- eudaimonia, 3/31/2019
-- ===========================================================================

include("InstanceManager");
include("PlayerSupport");
include("cui_helper");
include("cui_settings");
include("cuiassistantsupport");

-- ===========================================================================

local isAttached = false;

local CuiAssistantTT = {};
TTManager:GetTypeControlTable("CuiAssistantTT", CuiAssistantTT);

local CuiWonderTT = {};
TTManager:GetTypeControlTable("CuiWonderTT", CuiWonderTT);

local CuiVictoryTT = {};
TTManager:GetTypeControlTable("CuiVictoryTT", CuiVictoryTT);

local resourcesInstance     = InstanceManager:new( "ResourceInstance",      "Top", Controls.ResourceInstanceContainer );
local leaderArrowInstance   = InstanceManager:new( "LeaderArrowInstance",   "Top", Controls.LeaderArrowInstanceContainer );
local leaderInstance        = InstanceManager:new( "LeaderInstance",        "Top", Controls.LeaderInstanceContainer );
local wonderInstance        = InstanceManager:new( "WonderInstance",        "Top", Controls.WonderInstanceContainer );
local colorInstance         = InstanceManager:new( "ColorInstance",         "Top", Controls.ColorInstanceContainer );
local victoryIconInstance   = InstanceManager:new( "VictoryIconInstance",   "Top", Controls.VictoryIconInstanceContainer );
local victoryLeaderInstance = InstanceManager:new( "VictoryLeaderInstance", "Top", Controls.VictoryLeaderInstanceContainer );

local msgNumber = 0;

local hasRsources    = false;
local resources      = {};
local hasPeaceDeals  = false;
local peaceLeaders   = {};
local hasOpenBorders = false;
local borderLeaders  = {};
local hasTradeRoutes = false;
local tradeLeaders   = {};

local wonderData     = {};
local colorSet       = {};

local ranks          = {};
local scienceData    = {};
local cultureData    = {};
local dominationData = {};
local religionData   = {};
local diplomaticData = {};

local aOffsetX = 56;
local vOffsetX = 72;

-- ===========================================================================
function GetSuggestionData(isDisabled)
  if isDisabled then return; end

  SupportInit();

  msgNumber = 0;

  hasRsources,    resources     = GetSurplusResources();
  hasPeaceDeals,  peaceLeaders  = GetPeaceDeals();
  hasOpenBorders, borderLeaders = GetOpenBorders();
  hasTradeRoutes, tradeLeaders  = GetTradeRoutes();

  if hasRsources    then msgNumber = msgNumber + 1; end
  if hasPeaceDeals  then msgNumber = msgNumber + 1; end
  if hasOpenBorders then msgNumber = msgNumber + 1; end
  if hasTradeRoutes then msgNumber = msgNumber + 1; end
end

-- ===========================================================================
function UpdateDealAssistantToolTip()
  local localPlayerID = Game.GetLocalPlayer();
  if localPlayerID == -1 then return; end

  resourcesInstance  :ResetInstances();
  leaderArrowInstance:ResetInstances();
  leaderInstance     :ResetInstances();

  -- surplus resources
  CuiAssistantTT.ResourceGrid:SetHide(not hasRsources);
  if hasRsources then
    for _, item in ipairs(resources) do
      local icon = resourcesInstance:GetInstance(CuiAssistantTT.ResourceStack);
      icon.Icon:SetToolTipString(item.Name);
      CuiSetIconToSize(icon.Icon, item.Icon, 36);
      icon.Text:SetText(item.Amount);
    end
  end

  -- make peace
  CuiAssistantTT.MakePeaceGrid:SetHide(not hasPeaceDeals);
  if hasPeaceDeals then
    for _, leader in ipairs(peaceLeaders) do
      local icon = leaderInstance:GetInstance(CuiAssistantTT.MakePeaceStack);
      icon.Icon:SetTexture(CuiLeaderTexture(leader.Icon, 45, true));
    end
  end

  -- open border
  CuiAssistantTT.OpenBorderGrid:SetHide(not hasOpenBorders);
  if hasOpenBorders then
    for _, leader in ipairs(borderLeaders) do
      local icon = leaderArrowInstance:GetInstance(CuiAssistantTT.OpenBorderStack);
      icon.Icon:SetTexture(CuiLeaderTexture(leader.Icon, 45, true));
      icon.OpenTo  :SetHide(not leader.OpenTo);
      icon.OpenFrom:SetHide(not leader.OpenFrom);
    end
  end

  -- trade route
  CuiAssistantTT.TradeRouteGrid:SetHide(not hasTradeRoutes);
  if hasTradeRoutes then
    for _, leader in ipairs(tradeLeaders) do
      local icon = leaderInstance:GetInstance(CuiAssistantTT.TradeRouteStack);
      icon.Icon:SetTexture(CuiLeaderTexture(leader.Icon, 45, true));
    end
  end

  CuiAssistantTT.BG:DoAutoSize();
end

-- ===========================================================================
function GetWonderData()
  SupportInit();
  wonderData, colorSet = GetWonderAndColorSet();
end

-- ===========================================================================
function UpdateWonderToolTip()
  local localPlayerID = Game.GetLocalPlayer();
  if localPlayerID == -1 then return; end

  wonderInstance:ResetInstances();
  colorInstance :ResetInstances();

  for _, wonder in ipairs(wonderData) do
    local wonderIcon = wonderInstance:GetInstance(CuiWonderTT.WonderIconStack);
    wonderIcon.Icon :SetIcon(wonder.Icon);
    local hasColor = wonder.Color1 ~= "Clear";
    local alpha = hasColor and 0.5 or 1.0;
    local back  = hasColor and "Black" or "Clear";
    wonderIcon.Icon:SetAlpha(alpha);
    wonderIcon.Back:SetColorByName(back);
    wonderIcon.Color1:SetColor(wonder.Color1);
    wonderIcon.Color2:SetColor(wonder.Color2);
  end
  CuiWonderTT.WonderIconStack:CalculateSize();

  for _, civ in ipairs(colorSet) do
    local colorIndicator = colorInstance:GetInstance(CuiWonderTT.ColorIndicatorStack);
    colorIndicator.CivName:SetText(civ.CivName);
    colorIndicator.Color1:SetColor(civ.Color1);
    colorIndicator.Color2:SetColor(civ.Color2);
  end
  CuiWonderTT.ColorIndicatorStack:CalculateSize();

  local wonderStackY = CuiWonderTT.WonderIconStack:GetSizeY();
  local colorStackY  = CuiWonderTT.ColorIndicatorStack:GetSizeY();
  local dividerY     = math.max(wonderStackY, colorStackY);
  CuiWonderTT.VerticalDivider:SetSizeY(dividerY);

  CuiWonderTT.MainStack:CalculateSize();
  CuiWonderTT.BG:DoAutoSize();
end

-- ===========================================================================
function GetVictoryData()
  SupportInit();

  local victoryTypes = GetVictoryTypes();
  for _, vType in ipairs(victoryTypes) do
    if     vType == "SCIENCE"    then scienceData,    ranks["SCIENCE"]    = GetScienceData();
    elseif vType == "CULTURE"    then cultureData,    ranks["CULTURE"]    = GetCultureData();
    elseif vType == "DOMINATION" then dominationData, ranks["DOMINATION"] = GetDominationData();
    elseif vType == "RELIGION"   then religionData,   ranks["RELIGION"]   = GetReligionData();
    elseif vType == "DIPLOMATIC" then diplomaticData, ranks["DIPLOMATIC"] = GetDiplomaticData();
    end
  end
end

-- ===========================================================================
function UpdateVictoryToolTip(vType)
  local localPlayerID = Game.GetLocalPlayer();
  if localPlayerID == -1 then return; end

  local leaders;
  if     vType == "SCIENCE"    then leaders = scienceData;
  elseif vType == "CULTURE"    then leaders = cultureData;
  elseif vType == "DOMINATION" then leaders = dominationData;
  elseif vType == "RELIGION"   then leaders = religionData;
  elseif vType == "DIPLOMATIC" then leaders = diplomaticData;
  end

  victoryLeaderInstance:ResetInstances();

  for i, leader in ipairs(leaders) do
    local leaderInstance = victoryLeaderInstance:GetInstance(CuiVictoryTT.VictoryLeaderStack);
    SetVictoryLeaderInstance(vType, leader, leaderInstance);
  end

  local title = "";
  if vType == "RELIGION" then
    title = "LOC_VICTORY_RELIGIOUS_NAME";
  else
    title = "LOC_VICTORY_" .. vType .. "_NAME";
  end

  CuiVictoryTT.Title:SetText(Locale.Lookup(title));
  CuiVictoryTT.Divider:SetSizeX(CuiVictoryTT.Title:GetSizeX() + 60);
  CuiVictoryTT.BG:DoAutoSize();
end

-- ===========================================================================
function SetVictoryLeaderInstance(vType, leader, instance)

  local shouldShowIcon = leader.isLocalPlayer or leader.isMet or leader.isHuman;

  local text1 = "";
  local text2 = "";
  if shouldShowIcon then
    if vType == "SCIENCE" then
      text1 = "[ICON_SCIENCE]" .. leader.scienceY .. " (" .. leader.techs .. ")";
      local progressText = "";
      local progress = leader.progresses;
      if isExpansion2 then
        text2 = Locale.Lookup("LOC_CUI_DB_EXOPLANET_EXPEDITION", progress[1], progress[2], progress[3], progress[4], progress[5]);
      else
        text2 = Locale.Lookup("LOC_CUI_DB_MARS_PROJECT", progress[1], progress[2], progress[3]);
      end
    elseif vType == "CULTURE" then
      text1 = "[ICON_CULTURE]" .. leader.cultureY .. " ([ICON_TOURISM]" .. leader.tourism .. ")";
      text2 = Locale.Lookup("LOC_CUI_DB_VISITING_TOURISTS", leader.visiter, leader.tourists);
    elseif vType == "DOMINATION" then
      text1 = "[ICON_STRENGTH]" .. leader.strength;
      text2 = Locale.Lookup("LOC_CUI_DB_CAPITALS_CAPTURED", leader.capture);
    elseif vType == "RELIGION" then
      text1 = "[ICON_FAITH]" .. leader.faithY;
      text2 = Locale.Lookup("LOC_CUI_DB_CIVS_CONVERTED", leader.convert, leader.totalCiv);
    elseif vType == "DIPLOMATIC" then
      text1 = "[ICON_FAVOR] " .. leader.favor .. " (+" .. leader.favorPT .. ")";
      text2 = Locale.Lookup("LOC_CUI_DB_DIPLOMATIC_POINT", leader.current, leader.total);
    end
  end

  instance.Icon:SetTexture(CuiLeaderTexture(leader.leaderIcon, 45, shouldShowIcon));
  instance.UnMet:SetHide(shouldShowIcon);
  instance.State1:SetHide(not shouldShowIcon);
  instance.State1:SetText(text1);
  instance.State2:SetHide(not shouldShowIcon);
  instance.State2:SetText(text2 .. "  ");

  if leader.isLocalPlayer then
    instance.LeaderIcon:SetOffsetX(-2);
    instance.YouIndicator:SetHide(false);
  else
    instance.LeaderIcon:SetOffsetX(0);
    instance.YouIndicator:SetHide(true);
  end

end

-- ===========================================================================
function IsAssistantDisabled()
  local isDisabled = not (Controls.SurplusResource:IsChecked() or
                          Controls.MakePeace      :IsChecked() or
                          Controls.OpenBorders    :IsChecked() or
                          Controls.TradeRoutes    :IsChecked()
                         );
  return isDisabled;
end

-- ===========================================================================
function RefreshSuggestionButton(isDisabled)
  -- Controls.AssistantButton:SetAlpha(isDisabled and 0.5 or 1);
  Controls.MsgGrid:SetHide(isDisabled);
  if not isDisabled then
    if msgNumber > 0 then
      Controls.MsgCount:SetText(msgNumber);
    else
      Controls.MsgCount:SetText("[ICON_CheckmarkBlue]");
    end
  end
end

-- ===========================================================================
function RefreshSuggestionToolTip(tControl, isDisabled)
  tControl:ClearToolTipCallback();
  if (not isDisabled) and (msgNumber > 0) then
    tControl:SetToolTipType("CuiAssistantTT");
    tControl:SetToolTipCallback(function() UpdateDealAssistantToolTip(tControl); end);
  end
end

-- ===========================================================================
function RefreshWonderToolTip(tControl)
  tControl:ClearToolTipCallback();
  if CuiSettings:GetBoolean(CuiSettings.WONDERS_TRACK) then
    tControl:SetToolTipType("CuiWonderTT");
    tControl:SetToolTipCallback(function() UpdateWonderToolTip(tControl); end);
  end
end

-- ===========================================================================
function PopulateVictoryIcons()
  victoryIconInstance:ResetInstances();
  local victoryTypes = GetVictoryTypes();
  for _, vType in ipairs(victoryTypes) do
    if CuiSettings:GetBoolean(CuiSettings[vType]) then
      local instance = victoryIconInstance:GetInstance(Controls.VictoryButtonStack);
      local icon = "ICON_VICTORY_" .. vType;
      if icon ~= nil then
        local textureOffsetX:number, textureOffsetY:number, textureSheet:string = IconManager:FindIconAtlas(icon, 64);
        if(textureSheet == nil or textureSheet == "") then
          UI.DataError("Could not find icon in PopulateVictoryButton: icon=\""..icon.."\", iconSize=64");
        else
          -- set icon
          instance.VictoryIcon:SetTexture(textureOffsetX, textureOffsetY, textureSheet);
          -- set tooltip
          instance.VictoryIcon:ClearToolTipCallback();
          instance.VictoryIcon:SetToolTipType("CuiVictoryTT");
          instance.VictoryIcon:SetToolTipCallback(function() UpdateVictoryToolTip(vType); end);
          -- set rank
          instance.Text:SetText("#" .. ranks[vType]);
        end
      end
    end
  end
end

-- ===========================================================================
function RefreshAll()
  local isDisabled = IsAssistantDisabled();
  GetSuggestionData(isDisabled);
  RefreshSuggestionButton(isDisabled);
  RefreshSuggestionToolTip(Controls.AssistantButton, isDisabled);

  GetWonderData();
  RefreshWonderToolTip(Controls.WonderTrackIcon);

  GetVictoryData();
  PopulateVictoryIcons();
end

-- ===========================================================================
function ToggleOptions()
  local isHide = Controls.AssistantOptions:IsHidden();
  Controls.AssistantOptions:SetHide(not isHide);
end

-- ===========================================================================
function OnMinimapResize()
  if isAttached then
    local minimap = ContextPtr:LookUpControl( "/InGame/MinimapPanel/MiniMap/MinimapContainer" );
    Controls.CuiAssistant:SetOffsetX(minimap:GetSizeX() + 10);
  end
end

-- ===========================================================================
function OnSurplusResource()
  Controls.SurplusResource:SetCheck(CuiSettings:ReverseAndGetBoolean(CuiSettings.SURPLUS_RESOURCE));
  RefreshAll();
end

-- ===========================================================================
function OnMakePeace()
  Controls.MakePeace:SetCheck(CuiSettings:ReverseAndGetBoolean(CuiSettings.MAKE_PEACE));
  RefreshAll();
end

-- ===========================================================================
function OnOpenBorders()
  Controls.OpenBorders:SetCheck(CuiSettings:ReverseAndGetBoolean(CuiSettings.OPEN_BORDERS));
  RefreshAll();
end

-- ===========================================================================
function OnTradeRoutes()
  Controls.TradeRoutes:SetCheck(CuiSettings:ReverseAndGetBoolean(CuiSettings.TRADE_ROUTES));
  RefreshAll();
end

-- ===========================================================================
function OnWonderTrack()
  local isChecked = CuiSettings:ReverseAndGetBoolean(CuiSettings.WONDERS_TRACK);
  Controls.WonderTrack:SetCheck(isChecked);

  Controls.WonderTrackIcon:SetHide(not isChecked);

  local mainOffset = isChecked and aOffsetX or 0;
  Controls.AssistantButton:SetOffsetX(mainOffset);

  local victoryOffset = isChecked and (aOffsetX + vOffsetX) or vOffsetX;
  Controls.VictoryButtonStack:SetOffsetX(victoryOffset);
  RefreshAll();
end

-- ===========================================================================
function OnScience()
  Controls.SCIENCE:SetCheck(CuiSettings:ReverseAndGetBoolean(CuiSettings.SCIENCE));
  RefreshAll();
end

-- ===========================================================================
function OnCulture()
  Controls.CULTURE:SetCheck(CuiSettings:ReverseAndGetBoolean(CuiSettings.CULTURE));
  RefreshAll();
end

-- ===========================================================================
function OnDomiation()
  Controls.DOMINATION:SetCheck(CuiSettings:ReverseAndGetBoolean(CuiSettings.DOMINATION));
  RefreshAll();
end

-- ===========================================================================
function OnReligion()
  Controls.RELIGION:SetCheck(CuiSettings:ReverseAndGetBoolean(CuiSettings.RELIGION));
  RefreshAll();
end

-- ===========================================================================
function OnDiplomatic()
  Controls.DIPLOMATIC:SetCheck(CuiSettings:ReverseAndGetBoolean(CuiSettings.DIPLOMATIC));
  RefreshAll();
end

-- ===========================================================================
function SetupUI()
  SetupOptions();

  local optionStackX  = Controls.OptionStack :GetSizeX();
  local optionStackY  = Controls.OptionStack :GetSizeY();
  local victoryStackX = Controls.VictoryStack:GetSizeX();
  local victoryStackY = Controls.VictoryStack:GetSizeY();

  Controls.AssistantOptions:SetSizeX(optionStackX + victoryStackX + 50);
  Controls.AssistantOptions:SetSizeY(math.max(optionStackY, victoryStackY) + 66);
  Controls.AssistantOptions:SetHide(true);

  Controls.OptionStack :SetOffsetX(24);
  Controls.VictoryStack:SetOffsetX(30 + optionStackX);

  -- wonder track
  local isWonderTrack = CuiSettings:GetBoolean(CuiSettings.WONDERS_TRACK);
  Controls.WonderTrackIcon:SetHide(not isWonderTrack);

  local mainOffset = isWonderTrack and aOffsetX or 0;
  Controls.AssistantButton:SetOffsetX(mainOffset);

  local victoryOffset = isWonderTrack and (aOffsetX + vOffsetX) or vOffsetX;
  Controls.VictoryButtonStack:SetOffsetX(victoryOffset);

  local x, y, sheet = IconManager:FindIconAtlas("ICON_NOTIFICATION_WONDER_COMPLETED", 40);
  Controls.WonderIcon:SetTexture(x, y, sheet);
  Controls.WonderIcon:SetColorByName("White");
end

-- ===========================================================================
function SetupOptions()
  -- left part
  Controls.SurplusResource:SetCheck(CuiSettings:GetBoolean(CuiSettings.SURPLUS_RESOURCE));
  Controls.MakePeace      :SetCheck(CuiSettings:GetBoolean(CuiSettings.MAKE_PEACE));
  Controls.OpenBorders    :SetCheck(CuiSettings:GetBoolean(CuiSettings.OPEN_BORDERS));
  Controls.TradeRoutes    :SetCheck(CuiSettings:GetBoolean(CuiSettings.TRADE_ROUTES));
  Controls.WonderTrack    :SetCheck(CuiSettings:GetBoolean(CuiSettings.WONDERS_TRACK));

  Controls.SurplusResource:RegisterCheckHandler(OnSurplusResource);
  Controls.MakePeace      :RegisterCheckHandler(OnMakePeace);
  Controls.OpenBorders    :RegisterCheckHandler(OnOpenBorders);
  Controls.TradeRoutes    :RegisterCheckHandler(OnTradeRoutes);
  Controls.WonderTrack    :RegisterCheckHandler(OnWonderTrack);

  -- right part
  local victoryTypes = GetVictoryTypes();
  for _, vType in ipairs(victoryTypes) do
    Controls[vType]:SetHide(false);
    Controls[vType]:SetCheck(CuiSettings:GetBoolean(CuiSettings[vType]));
  end
  Controls.SCIENCE   :RegisterCheckHandler(OnScience);
  Controls.CULTURE   :RegisterCheckHandler(OnCulture);
  Controls.DOMINATION:RegisterCheckHandler(OnDomiation);
  Controls.RELIGION  :RegisterCheckHandler(OnReligion);
  Controls.DIPLOMATIC:RegisterCheckHandler(OnDiplomatic);

  Controls.OptionStack :CalculateSize();
  Controls.OptionStack :ReprocessAnchoring();
  Controls.VictoryStack:CalculateSize();
  Controls.VictoryStack:ReprocessAnchoring();
end

-- ===========================================================================
function AttachToMinimap()
  if not isAttached then
    local minimap = ContextPtr:LookUpControl( "/InGame/MinimapPanel/MiniMap/MinimapContainer" );
    Controls.CuiAssistant:ChangeParent(minimap);
    Controls.CuiAssistant:SetOffsetX(minimap:GetSizeX() + 10);
    SetupUI();
    RefreshAll();
    isAttached = true;
  end
end

-- ===========================================================================
function Initialize()
  ContextPtr:SetHide(true);

  CuiRegCallback(Controls.AssistantButton,
    ToggleOptions,
    RefreshAll
  );

  Events.LoadGameViewStateDone.Add(AttachToMinimap);
  LuaEvents.CuiOnMinimapResize.Add(OnMinimapResize);
  LuaEvents.DiplomacyActionView_ShowIngameUI.Add(RefreshAll);
  Events.TurnBegin.Add(RefreshAll);
end
Initialize();