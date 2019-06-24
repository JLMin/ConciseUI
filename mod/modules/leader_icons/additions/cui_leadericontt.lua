-- ===========================================================================
-- Cui leader icon tooltip
-- eudaimonia, 1/15/2019
-- ===========================================================================

include( "InstanceManager" );
include( "SupportFunctions" );
include( "CivilizationIcon" );
include( "TeamSupport" );
include( "Civ6Common" );
include( "cui_helper" );

-- ===========================================================================
local CuiLeaderIconTT = {};
TTManager:GetTypeControlTable("CuiLeaderIconTT", CuiLeaderIconTT);
local CuiRelationshipTT = {};
TTManager:GetTypeControlTable("CuiRelationshipTT", CuiRelationshipTT);

local resourcesInstance = InstanceManager:new( "ResourceInstance", "Top", Controls.ResourceInstanceContainer );
local rsresonInstance   = InstanceManager:new( "ReasonInstance",   "Top", Controls.ReasonInstanceContainer );

local localPlayer = Players[Game.GetLocalPlayer()];

-- ===========================================================================
function GetPlayerData(playerID:number)
  local data:table = {};
  local pPlayer:table = Players[playerID];
  local playerConfig:table = PlayerConfigurations[playerID];

  -- basic
  data.leaderTypeName = playerConfig:GetLeaderTypeName();
  data.leaderName     = playerConfig:GetLeaderName();
  data.civDesc        = playerConfig:GetCivilizationDescription();
  data.playerName     = Locale.Lookup(playerConfig:GetPlayerName());

  -- government
  local pGovernment:number = pPlayer:GetCulture():GetCurrentGovernment();
  data.government = (pGovernment ~= -1)
  and Locale.Lookup(GameInfo.Governments[pGovernment].Name)
  or Locale.Lookup("LOC_GOVERNMENT_ANARCHY_NAME");

  local cities:number = 0;
  for _, city in pPlayer:GetCities():Members() do cities = cities + 1; end
  data.cities = cities;

  local religionType = pPlayer:GetReligion():GetReligionTypeCreated();
  if religionType ~= -1 then data.religion = Game.GetReligion():GetName(religionType);
  else data.religion = Locale.Lookup("LOC_CUI_DB_NONE"); end

  -- score & yields
  data.score    = pPlayer      :GetScore();
  data.research = pPlayer      :GetStats()   :GetNumTechsResearched();
  data.science  = Round(pPlayer:GetTechs()   :GetScienceYield(), 1);
  data.tourism  = Round(pPlayer:GetStats()   :GetTourism(), 1);
  data.culture  = Round(pPlayer:GetCulture() :GetCultureYield(), 1);
  data.military = pPlayer      :GetStats()   :GetMilitaryStrength();
  data.faith    = Round(pPlayer:GetReligion():GetFaithYield(), 1);
  data.balance  = math.floor(pPlayer:GetTreasury():GetGoldBalance());
  data.gold     = math.floor(pPlayer:GetTreasury():GetGoldYield() - pPlayer:GetTreasury():GetTotalMaintenance());
  if isExpansion2 then
    data.favor    = pPlayer:GetFavor();
    data.favorPT  = pPlayer:GetFavorPerTurn();
  end
  return data;
end

-- ===========================================================================
function GetRelationShip(tPlayerID:number, allianceData:table)

  local data:table = {};

  local tPlayer:table = Players[tPlayerID];
  local lPlayerID:number = Game.GetLocalPlayer();
  local lPlayer:table = Players[lPlayerID];
  local lPlayerDiplomacy:table = lPlayer:GetDiplomacy();

  local iState = tPlayer:GetDiplomaticAI():GetDiplomaticStateIndex(lPlayerID);
  local iStateEntry = GameInfo.DiplomaticStates[iState];
  local eState = iStateEntry.Hash;

  -- relationship level
  data.atWar = false;
  if (eState == DiplomaticStates.WAR) then
    local bValidAction, tResults = Players[lPlayerID]:GetDiplomacy():IsDiplomaticActionValid("DIPLOACTION_PROPOSE_PEACE_DEAL", tPlayerID, true);
    data.atWar = true;
    data.peaceDeal = bValidAction;
    data.warTurns = Game.GetGameDiplomacy():GetMinPeaceDuration() + lPlayer:GetDiplomacy():GetAtWarChangeTurn(tPlayerID) - Game.GetCurrentGameTurn();
    data.level = 0;
  elseif (eState == DiplomaticStates.ALLIED) then
    data.level = 100;
  else
    data.level = iStateEntry.RelationshipLevel;
  end

  -- relationship modification
  local modSum:number = 0;
  local modifiers:table = tPlayer:GetDiplomaticAI():GetDiplomaticModifiers(lPlayerID);
  if modifiers then
    for _, mod in ipairs(modifiers) do
      modSum = modSum + mod.Score;
    end
  end
  data.modifier = modSum;

  -- tooltip & remaining turns
  data.isAlliance = allianceData.isAlliance;
  if allianceData.isAlliance then
    data.tooltip = allianceData.tooltip;
    data.turns = allianceData.remainingTurns;
  else
    local iRemainingTurns:number = 0;
    if (GameInfo.DiplomaticStates[iState].StateType == "DIPLO_STATE_DENOUNCED") then
      local iOurDenounceTurn = lPlayerDiplomacy:GetDenounceTurn(tPlayerID);
      local iTheirDenounceTurn = Players[tPlayerID]:GetDiplomacy():GetDenounceTurn(lPlayerID);
      local iPlayerOrderAdjustment = 0;
      if (iTheirDenounceTurn >= iOurDenounceTurn) then
        if (tPlayerID > lPlayerID) then iPlayerOrderAdjustment = 1; end
      else
        if (lPlayerID > tPlayerID) then iPlayerOrderAdjustment = 1; end
      end
      if (iOurDenounceTurn >= iTheirDenounceTurn) then
        iRemainingTurns = 1 + iOurDenounceTurn + Game.GetGameDiplomacy():GetDenounceTimeLimit() - Game.GetCurrentGameTurn() + iPlayerOrderAdjustment;
      else
        iRemainingTurns = 1 + iTheirDenounceTurn + Game.GetGameDiplomacy():GetDenounceTimeLimit() - Game.GetCurrentGameTurn() + iPlayerOrderAdjustment;
      end
    elseif (GameInfo.DiplomaticStates[iState].StateType == "DIPLO_STATE_DECLARED_FRIEND") then
      local iFriendshipTurn = lPlayerDiplomacy:GetDeclaredFriendshipTurn(tPlayerID);
      iRemainingTurns = iFriendshipTurn + Game.GetGameDiplomacy():GetDenounceTimeLimit() - Game.GetCurrentGameTurn();
    end
    data.tooltip = Locale.Lookup(iStateEntry.Name);
    data.turns = iRemainingTurns;
  end

  return data;
end

-- ===========================================================================
function LocalCmpResource(a, b)
  local resourceA = GameInfo.Resources[a.ForType];
  local resourceB = GameInfo.Resources[b.ForType];
  return resourceA.ResourceClassType < resourceB.ResourceClassType;
end

-- ===========================================================================
function GetResourceList(otherPlayerID:number)
  local localPlayerID:number = Game.GetLocalPlayer();

  local otherOffer:table = {};
  local localOffer:table = {};

  local isOther = (localPlayerID ~= otherPlayerID);
  if (isOther) then

    -- local player
    local localForDeal           = DealManager.GetWorkingDeal(DealDirection.OUTGOING, localPlayerID, otherPlayerID);
    local localPossibleResources = DealManager.GetPossibleDealItems(localPlayerID, otherPlayerID, DealItemTypes.RESOURCES, localForDeal);
    local localResources         = Players[localPlayerID]:GetResources();

    -- other player
    local otherForDeal           = DealManager.GetWorkingDeal(DealDirection.OUTGOING, otherPlayerID ,localPlayerID);
    local otherPossibleResources = DealManager.GetPossibleDealItems(otherPlayerID, localPlayerID, DealItemTypes.RESOURCES, otherForDeal);
    local otherResources         = Players[otherPlayerID]:GetResources();

    -- other player offer
    if (otherPossibleResources ~= nil) then
      table.sort(otherPossibleResources, LocalCmpResource);
      for _, entry in ipairs(otherPossibleResources) do
        local resource = GameInfo.Resources[entry.ForType];
        if (resource ~= nil and (resource.ResourceClassType == "RESOURCECLASS_LUXURY" or resource.ResourceClassType == "RESOURCECLASS_STRATEGIC")) then
          local logic_AI:boolean = entry.MaxAmount > 1 and not localResources:HasResource(resource.Index) and not Players[otherPlayerID]:IsHuman();
          local logic_Human:boolean = entry.MaxAmount > 0 and not localResources:HasResource(resource.Index) and Players[otherPlayerID]:IsHuman();
          if logic_AI or logic_Human then
            local icon   = "ICON_" .. resource.ResourceType;
            local amount = logic_AI and (entry.MaxAmount - 1) or entry.MaxAmount;
            table.insert(otherOffer, {Icon = icon, Amount = amount});
          end
        end
      end
    end

    -- my offer
    if (localPossibleResources ~= nil) then
      table.sort(localPossibleResources, LocalCmpResource);
      for _, entry in ipairs(localPossibleResources) do
        local resource = GameInfo.Resources[entry.ForType];
        if (resource ~= nil and (resource.ResourceClassType == "RESOURCECLASS_LUXURY" or resource.ResourceClassType == "RESOURCECLASS_STRATEGIC")) then
          if (entry.MaxAmount > 0 and not otherResources:HasResource(resource.Index)) then
            local icon   = "ICON_" .. resource.ResourceType;
            local amount = entry.MaxAmount;
            table.insert(localOffer, {Icon = icon, Amount = amount});
          end
        end
      end
    end
  end

  return isOther, otherOffer, localOffer;
end

-- ===========================================================================
function GetGSResourceList(otherPlayerID:number)
  local localPlayerID:number = Game.GetLocalPlayer();

  local otherOffer:table = {};
  local localOffer:table = {};

  local isOther = (localPlayerID ~= otherPlayerID);
  if (isOther) then

    -- local player
    local localForDeal           = DealManager.GetWorkingDeal(DealDirection.OUTGOING, localPlayerID, otherPlayerID);
    local localPossibleResources = DealManager.GetPossibleDealItems(localPlayerID, otherPlayerID, DealItemTypes.RESOURCES, localForDeal);
    local localResources         = Players[localPlayerID]:GetResources();

    -- other player
    local otherForDeal           = DealManager.GetWorkingDeal(DealDirection.OUTGOING, otherPlayerID ,localPlayerID);
    local otherPossibleResources = DealManager.GetPossibleDealItems(otherPlayerID, localPlayerID, DealItemTypes.RESOURCES, otherForDeal);
    local otherResources         = Players[otherPlayerID]:GetResources();

    -- other player offer
    if (otherPossibleResources ~= nil) then
      table.sort(otherPossibleResources, LocalCmpResource);
      for _, entry in ipairs(otherPossibleResources) do
        local resource = GameInfo.Resources[entry.ForType];
        if resource ~= nil then
          if resource.ResourceClassType == "RESOURCECLASS_LUXURY" then
            local logic_AI:boolean = entry.MaxAmount > 1 and not localResources:HasResource(resource.Index) and not Players[otherPlayerID]:IsHuman();
            local logic_Human:boolean = entry.MaxAmount > 0 and not localResources:HasResource(resource.Index) and Players[otherPlayerID]:IsHuman();
            if logic_AI or logic_Human then
              local icon   = "ICON_" .. resource.ResourceType;
              local amount = logic_AI and (entry.MaxAmount - 1) or entry.MaxAmount;
              table.insert(otherOffer, {Icon = icon, Amount = amount});
            end
          elseif resource.ResourceClassType == "RESOURCECLASS_STRATEGIC" then
            if entry.MaxAmount > 0 and entry.IsValid then
              local icon   = "ICON_" .. resource.ResourceType;
              local amount = entry.MaxAmount;
              table.insert(otherOffer, {Icon = icon, Amount = amount});
            end
          end
        end
      end
    end

    -- my offer
    if (localPossibleResources ~= nil) then
      table.sort(localPossibleResources, LocalCmpResource);
      for _, entry in ipairs(localPossibleResources) do
        local resource = GameInfo.Resources[entry.ForType];
        if resource ~= nil then
          if resource.ResourceClassType == "RESOURCECLASS_LUXURY" then
            if (entry.MaxAmount > 0 and not otherResources:HasResource(resource.Index)) then
              local icon   = "ICON_" .. resource.ResourceType;
              local amount = entry.MaxAmount;
              table.insert(localOffer, {Icon = icon, Amount = amount});
            end
          elseif resource.ResourceClassType == "RESOURCECLASS_STRATEGIC" then
            if entry.MaxAmount > 0 and entry.IsValid then
              local icon   = "ICON_" .. resource.ResourceType;
              local amount = entry.MaxAmount;
              table.insert(localOffer, {Icon = icon, Amount = amount});
            end
          end
        end
      end
    end
  end

  return isOther, otherOffer, localOffer;
end

-- ===========================================================================
function GetGrievanceTooltip(otherPlayerID:number)
  local localPlayerID   :number = Game.GetLocalPlayer();
  local kGameDiplomacy	:table  = Game.GetGameDiplomacy();
  local kLocalPlayer		:table  = Players[localPlayerID];
  local kPlayerDiplomacy:table  = kLocalPlayer:GetDiplomacy();
  local totalGrievances	:number = kPlayerDiplomacy:GetGrievancesAgainst(otherPlayerID);
  local grievancePerTurn:number = kGameDiplomacy:GetGrievanceChangePerTurn(otherPlayerID, localPlayerID);
  local tooltip:string = "";

  if totalGrievances == 0 then
    tooltip = Locale.Lookup("LOC_CUI_DB_GRIEVANCES_NONE");
  else
    local color:string = totalGrievances > 0 and "ModStatusGreen" or "Civ6Red";
    local txt:string = "[COLOR_" .. color .. "]" .. math.abs(totalGrievances) .. "[ENDCOLOR]"
    tooltip = Locale.Lookup("LOC_CUI_DB_GRIEVANCES", txt) .. " (" .. grievancePerTurn .. ")";
  end

  return tooltip;
end

-- ===========================================================================
function GetAccessLevelTooltip(otherPlayerID:number)
  local tooltip:string = "";
  local localPlayerDiplomacy:table = localPlayer:GetDiplomacy();
  local iAccessLevel = localPlayerDiplomacy:GetVisibilityOn(otherPlayerID);
  tooltip = Locale.Lookup("LOC_DIPLOMACY_OVERVIEW_ACCESS_LEVEL") ..
            Locale.Lookup("LOC_CUI_COLON") ..
            Locale.Lookup(GameInfo.Visibilities[iAccessLevel].Name);
  return tooltip;
end

-- ===========================================================================
function UpdateLeaderIconTooltip(tControl, playerID)

  local pData:table = GetPlayerData(playerID);
  if pData.leaderTypeName ~= nil then
    -- update leader icon
    local textureOffsetX:number, textureOffsetY:number, textureSheet:string = IconManager:FindIconAtlas("ICON_"..pData.leaderTypeName, 55);
    if(textureSheet == nil or textureSheet == "") then
      UI.DataError("Could not find icon in UpdateLeaderTooltip: icon=\"".."ICON_"..leaderTypeName.."\", iconSize=55");
    else
      CuiLeaderIconTT.Icon:SetTexture(textureOffsetX, textureOffsetY, textureSheet);
    end
    -- update description
    local desc:string = "";
    if GameConfiguration.IsAnyMultiplayer() and Players[playerID]:IsHuman() then
      desc = Locale.Lookup("LOC_DIPLOMACY_DEAL_PLAYER_PANEL_TITLE", pData.leaderName, pData.civDesc) .. "[NEWLINE]" .. " (" .. pData.playerName .. ")";
      CuiLeaderIconTT.Desc:SetOffsetY(2);
    else
      desc = Locale.Lookup("LOC_DIPLOMACY_DEAL_PLAYER_PANEL_TITLE", pData.leaderName, pData.civDesc);
      CuiLeaderIconTT.Desc:SetOffsetY(10);
    end
    CuiLeaderIconTT.Desc:SetText(desc);

    -- update info
    -- 1st section, basic info
    local sGovernment:string = Locale.Lookup("LOC_TOOLTIP_UNLOCKS_GOVERNMENT", pData.government);
    local sCities    :string = Locale.Lookup("LOC_CUI_DB_CITY", pData.cities);
    local sReligion  :string = Locale.Lookup("LOC_CUI_DB_RELIGION", pData.religion);
    CuiLeaderIconTT.Government:SetText(sGovernment);
    CuiLeaderIconTT.Cities    :SetText(sCities);
    CuiLeaderIconTT.Religion  :SetText(sReligion);

    -- 2nd section, (A) score and yields
    local pTitle   :string = Locale.Lookup("LOC_CUI_DB_SCORE_AND_YIELDS");
    CuiLeaderIconTT.ScoreAndYields:SetText(pTitle);

    local pScore   :string = "[ICON_Capital] "                          .. pData.score;
    CuiLeaderIconTT.Score:SetText(pScore);

    local pMilitary:string = "[ICON_Strength] " .. "[COLOR_Military]"   .. pData.military .. "[ENDCOLOR]";
    CuiLeaderIconTT.Strength:SetText(pMilitary);

    local pScience :string = "[ICON_Science] "  .. "[COLOR_Science]+"   .. pData.science  .. "[ENDCOLOR]";
    CuiLeaderIconTT.Science:SetText(pScience);

    local pCulture :string = "[ICON_Culture] "  .. "[COLOR_Culture]+"   .. pData.culture  .. "[ENDCOLOR]";
    CuiLeaderIconTT.Culture:SetText(pCulture);

    local pTourism :string = "[ICON_Tourism] "  .. "[COLOR_Tourism]+"   .. pData.tourism  .. "[ENDCOLOR]";
    CuiLeaderIconTT.Tourism:SetText(pTourism);

    local pFaith   :string = "[ICON_Faith] "    .. "[COLOR_FaithDark]+" .. pData.faith    .. "[ENDCOLOR]";
    CuiLeaderIconTT.Faith:SetText(pFaith);

    -- 2nd section, (A) gold  and favor
    local pGold:string = "[ICON_Gold] " .. pData.balance .. " ( " .. TwoColorNumber(pData.gold, "GoldDark", "Civ6Red") .. " )";
    CuiLeaderIconTT.Gold:SetText(pGold);
    if isExpansion2 then
      local pFavor:string = "[ICON_Favor] " .. pData.favor .. " ( " .. TwoColorNumber(pData.favorPT, "GoldDark", "Civ6Red") .. " )";
      CuiLeaderIconTT.GoldAndFavor:SetText(Locale.Lookup("LOC_CUI_DB_GOLD_AND_FAVOR"));
      CuiLeaderIconTT.Favor:SetText(pFavor);
    else
      CuiLeaderIconTT.GoldAndFavor:SetText(Locale.Lookup("LOC_CUI_DB_GOLD"));
    end

    -- 2nd section, (B) possible deals
    resourcesInstance:ResetInstances();
    local isOther    = false;
    local otherOffer = {};
    local localOffer = {};

    if isExpansion2 then
      isOther, otherOffer, localOffer = GetGSResourceList(playerID);
    else
      isOther, otherOffer, localOffer = GetResourceList(playerID);
    end

    if isOther then
      -- their offer
      CuiLeaderIconTT.OtherOffer:SetHide(table.count(otherOffer) < 1);
      for _, item in ipairs(otherOffer) do
        local icon = resourcesInstance:GetInstance(CuiLeaderIconTT.OtherStack);
        icon.Icon:SetToolTipString(item.Name);
        CuiSetIconToSize(icon.Icon, item.Icon, 36);
        icon.Text:SetText(item.Amount);
      end

      CuiLeaderIconTT.OtherStack:CalculateSize();
      CuiLeaderIconTT.OtherStack:ReprocessAnchoring();

      -- my offer
      CuiLeaderIconTT.LocalOffer:SetHide(table.count(localOffer) < 1);
      for _, item in ipairs(localOffer) do
        local icon = resourcesInstance:GetInstance(CuiLeaderIconTT.LocalStack);
        icon.Icon:SetToolTipString(item.Name);
        CuiSetIconToSize(icon.Icon, item.Icon, 36);
        icon.Text:SetText(item.Amount);
      end

      CuiLeaderIconTT.LocalStack:CalculateSize();
      CuiLeaderIconTT.LocalStack:ReprocessAnchoring();

    else
      CuiLeaderIconTT.OtherOffer:SetHide(true);
      CuiLeaderIconTT.LocalOffer:SetHide(true);
    end

    CuiLeaderIconTT.PossibleDeals:CalculateSize();
    CuiLeaderIconTT.PossibleDeals:ReprocessAnchoring();
    CuiLeaderIconTT.BG:DoAutoSize();
  end
end

-- ===========================================================================
function UpdateRelationShipTooltip(tControl, playerID, allianceData)

  local data:table = GetRelationShip(playerID, allianceData);

  -- relationship
  local relationship:string =
    Locale.Lookup("LOC_CUI_DB_RELATIONSHIP", data.level) ..
    " (" .. TwoColorNumber(data.modifier, "ModStatusGreen", "Civ6Red") .. ")";
  CuiRelationshipTT.Relationship:SetText(relationship);
  local selectedPlayerDiplomaticAI = Players[playerID]:GetDiplomaticAI();
  local toolTips = selectedPlayerDiplomaticAI:GetDiplomaticModifiers(Game.GetLocalPlayer());
  rsresonInstance:ResetInstances();
  if(toolTips) then
    table.sort(toolTips, function(a,b) return a.Score > b.Score; end);
    for i, tip in ipairs(toolTips) do
      local score = tip.Score;
      local text = tip.Text;
      if(score ~= 0) then
        local relationshipReason = rsresonInstance:GetInstance(CuiRelationshipTT.RelationshipReason);
        local scoreText = Locale.Lookup("{1_Score : number +#,###.##;-#,###.##}", score);
        local color = score > 0 and "[COLOR_ModStatusGreen]" or "[COLOR_Civ6Red]";
        relationshipReason.Score:SetText(color .. scoreText .. "[ENDCOLOR]");
        relationshipReason.Text:SetText(Locale.Lookup(text));
      end
    end
  end
  CuiRelationshipTT.RelationshipReason:CalculateSize();
  CuiRelationshipTT.RelationshipReason:ReprocessAnchoring();

  -- grivance
  CuiRelationshipTT.Grievance:SetHide(not isExpansion2);
  if isExpansion2 then
    CuiRelationshipTT.Grievance:SetText(GetGrievanceTooltip(playerID));
  end

  -- access level
  CuiRelationshipTT.AccessLevel:SetText(GetAccessLevelTooltip(playerID));

  -- states
  local states:string = "";
  if data.isAlliance or data.turns ~= 0 then
    states = data.tooltip .. "[NEWLINE][" .. Locale.Lookup("LOC_ESPIONAGEPOPUP_TURNS_REMAINING", data.turns) .. "]";
  else
    if data.atWar then
      if data.peaceDeal then
        states = data.tooltip .. "[NEWLINE]" .. Locale.Lookup("LOC_CUI_DB_PEACE_DEAL_AVAILABLE");
      else
        states = data.tooltip .. "[NEWLINE]" .. Locale.Lookup("LOC_CUI_DB_PEACE_DEAL_NOT_AVAILABLE", data.warTurns);
      end
    else
      states = data.tooltip;
    end
  end
  CuiRelationshipTT.States:SetText(states);

  CuiRelationshipTT.RelationshipStack:CalculateSize();
  CuiRelationshipTT.RelationshipStack:ReprocessAnchoring();
  CuiRelationshipTT.BG:DoAutoSize();
end

-- ===========================================================================
function SetLeaderIconToolTip(tControl, playerID)
  if playerID == Game.GetLocalPlayer() or localPlayer:GetDiplomacy():HasMet(playerID) then
    tControl:SetToolTipType("CuiLeaderIconTT");
    tControl:ClearToolTipCallback();
    tControl:SetToolTipCallback(function() UpdateLeaderIconTooltip(tControl, playerID); end);
  end
end

-- ===========================================================================
function SetRelationShipToolTip(tControl, playerID, allianceData)
  if playerID ~= Game.GetLocalPlayer() and localPlayer:GetDiplomacy():HasMet(playerID) then
    if tControl:IsHidden() then
      tControl:SetHide(false);
      tControl:SetVisState(3);
    end
    tControl:SetToolTipType("CuiRelationshipTT");
    tControl:ClearToolTipCallback();
    tControl:SetToolTipCallback(function() UpdateRelationShipTooltip(tControl, playerID, allianceData); end);
  end
end

-- ===========================================================================
function TwoColorNumber(num, color1, color2)
    if num > 0 then
    return "[COLOR_" .. color1 .. "]+" .. tostring(num) .. "[ENDCOLOR]";
  elseif num < 0 then
    return "[COLOR_" .. color2 .. "]" .. tostring(num) .. "[ENDCOLOR]";
  else
    return tostring(num);
  end
end

-- ===========================================================================
function CuiSetIconToSize(iconControl, iconName, iconSize)
  if iconSize == nil then iconSize = 36; end
  local x, y, szIconName, iconSize = IconManager:FindIconAtlasNearestSize(iconName, iconSize, true);
  iconControl:SetTexture(x, y, szIconName);
  iconControl:SetSizeVal(iconSize, iconSize);
end

-- ===========================================================================
LuaEvents.CuiLeaderIconToolTip.Add(SetLeaderIconToolTip);
LuaEvents.CuiRelationshipToolTip.Add(SetRelationShipToolTip);
