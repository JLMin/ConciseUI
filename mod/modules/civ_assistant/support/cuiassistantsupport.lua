-- ---------------------------------------------------------------------------
-- Cui Assistant Support Functions
-- eudaimonia, 4/7/2019
-- ---------------------------------------------------------------------------

include("SupportFunctions");
include("TeamSupport");
include("cui_helper");

local aliveMajors    = nil;
local localPlayerID  = nil;
local localPlayer    = nil;
local localDiplomacy = nil;
local kMetPlayers    = nil;
local kUniqueLeaders = nil;

-- ---------------------------------------------------------------------------
function SupportInit()
  aliveMajors    = PlayerManager.GetAliveMajors();
  localPlayerID  = Game.GetLocalPlayer();
  localPlayer    = Players[localPlayerID];
  localDiplomacy = localPlayer:GetDiplomacy();
  kMetPlayers, kUniqueLeaders = GetMetPlayersAndUniqueLeaders();
end
SupportInit();

-- ===========================================================================
-- Victory Conditions
-- ---------------------------------------------------------------------------
function GetVictoryTypes()
  local victoryTypes = {};

  if Game.IsVictoryEnabled("VICTORY_TECHNOLOGY") then
    table.insert(victoryTypes, "SCIENCE");
  end

  if Game.IsVictoryEnabled("VICTORY_CULTURE") then
    table.insert(victoryTypes, "CULTURE");
  end

  if Game.IsVictoryEnabled("VICTORY_CONQUEST") then
    table.insert(victoryTypes, "DOMINATION");
  end

  if Game.IsVictoryEnabled("VICTORY_RELIGIOUS") then
    table.insert(victoryTypes, "RELIGION");
  end

  if Game.IsVictoryEnabled("VICTORY_DIPLOMATIC") then
    table.insert(victoryTypes, "DIPLOMATIC");
  end

  return victoryTypes;
end

-- Science ===================================================================
function GetScienceData()
  local playerData = GetPlayerBasicData();

  -- add data
  for _, pData in pairs(playerData) do
    local playerID = pData.playerID;
    local pPlayer  = Players[playerID];
    pData.techs    = pPlayer:GetStats():GetNumTechsResearched();
    pData.scienceY = Round(pPlayer:GetTechs():GetScienceYield(), 0);
    if isExpansion2 then
       pData.progresses, pData.cmp = GetGSScienceCustomData(playerID);
    else
       pData.progresses, pData.cmp = GetBGScienceCustomData(playerID);
    end
  end

  -- sort
  local comparator = function(t, a, b)
                       local n = #t[a].cmp;
                       for i = n, 1, -1 do
                         if t[a].cmp[i] ~= t[b].cmp[i] then
                           return t[a].cmp[i] > t[b].cmp[i];
                         end
                       end
                       if t[a].techs ~= t[b].techs then
                         return t[a].techs > t[b].techs;
                       end
                       return t[a].scienceY > t[b].scienceY;
                     end;

  return GetVictoryLeader(playerData, comparator);
end

-- ---------------------------------------------------------------------------
function GetBGScienceCustomData(playerID)  -- science victory Base Game
  local EARTH_SATELLITE_PROJECT_INFOS = {
    GameInfo.Projects["PROJECT_LAUNCH_EARTH_SATELLITE"]
  };
  local MOON_LANDING_PROJECT_INFOS = {
    GameInfo.Projects["PROJECT_LAUNCH_MOON_LANDING"]
  };
  local MARS_COLONY_PROJECT_INFOS = {
    GameInfo.Projects["PROJECT_LAUNCH_MARS_REACTOR"],
    GameInfo.Projects["PROJECT_LAUNCH_MARS_HABITATION"],
    GameInfo.Projects["PROJECT_LAUNCH_MARS_HYDROPONICS"]
  };
  local pPlayer = Players[playerID];
  local pPlayerStats = pPlayer:GetStats();
  local pPlayerCities = pPlayer:GetCities();
  local progresses = { "0%", "", ""};
  local pValue = { 0, 0, 0 };
  for _, city in pPlayerCities:Members() do
    local pBuildQueue = city:GetBuildQueue();

    -- 1st milestone - satelite launch
    for i, projectInfo in ipairs(EARTH_SATELLITE_PROJECT_INFOS) do
      local projectCost = pBuildQueue:GetProjectCost(projectInfo.Index);
      local projectProgress = projectCost;
      if pPlayerStats:GetNumProjectsAdvanced(projectInfo.Index) == 0 then
        projectProgress = pBuildQueue:GetProjectProgress(projectInfo.Index);
      end
      if projectProgress ~= 0 then
        local progress = Round((projectProgress / projectCost), 2) * 100;
        progresses[1] = progress == 100 and "[ICON_CheckmarkBlue]" or (tostring(progress) .. "%");
        pValue[1]     = progress;
      end
    end

    -- 2nd milestone - moon landing
    if progresses[1] == "[ICON_CheckmarkBlue]" then
      for i, projectInfo in ipairs(MOON_LANDING_PROJECT_INFOS) do
        local projectCost = pBuildQueue:GetProjectCost(projectInfo.Index);
        local projectProgress = projectCost;
        if pPlayerStats:GetNumProjectsAdvanced(projectInfo.Index) == 0 then
          projectProgress = pBuildQueue:GetProjectProgress(projectInfo.Index);
        end
        if projectProgress ~= 0 then
          local progress = Round((projectProgress / projectCost), 2) * 100;
          progresses[2] = progress == 100 and "[ICON_CheckmarkBlue]" or (tostring(progress) .. "%");
          pValue[2]     = progress;
        end
      end
    end

    -- 3rd milestone - mars landing
    if progresses[2] == "[ICON_CheckmarkBlue]" then
      for i, projectInfo in ipairs(MARS_COLONY_PROJECT_INFOS) do
        local projectCost = pBuildQueue:GetProjectCost(projectInfo.Index);
        local projectProgress = projectCost;
        if pPlayerStats:GetNumProjectsAdvanced(projectInfo.Index) == 0 then
          projectProgress = pBuildQueue:GetProjectProgress(projectInfo.Index);
        end
        if projectProgress ~= 0 then
          local progress = Round((projectProgress / projectCost), 2) * 100;
          progresses[3] = progress == 100 and "[ICON_CheckmarkBlue]" or (tostring(progress) .. "%");
          pValue[3]     = progress;
        end
      end
    end

  end

  return progresses, pValue;
end

-- ---------------------------------------------------------------------------
function GetGSScienceCustomData(playerID)  -- science victory Gathering Storm
  local EARTH_SATELLITE_EXP2_PROJECT_INFOS = {
    GameInfo.Projects["PROJECT_LAUNCH_EARTH_SATELLITE"]
  };
  local MOON_LANDING_EXP2_PROJECT_INFOS = {
    GameInfo.Projects["PROJECT_LAUNCH_MOON_LANDING"]
  };
  local MARS_COLONY_EXP2_PROJECT_INFOS = {
    GameInfo.Projects["PROJECT_LAUNCH_MARS_BASE"],
  };
  local EXOPLANET_EXP2_PROJECT_INFOS = {
    GameInfo.Projects["PROJECT_LAUNCH_EXOPLANET_EXPEDITION"],
  };
  local pPlayer = Players[playerID];
  local pPlayerStats = pPlayer:GetStats();
  local pPlayerCities = pPlayer:GetCities();
  local progresses = { "0%", "", "", "", "" };
  local pValue     = { 0, 0, 0, 0, 0 };
  for _, city in pPlayerCities:Members() do
    local pBuildQueue = city:GetBuildQueue();

    -- 1st milestone - satellite launch
    for i, projectInfo in ipairs(EARTH_SATELLITE_EXP2_PROJECT_INFOS) do
      local projectCost = pBuildQueue:GetProjectCost(projectInfo.Index);
      local projectProgress = projectCost;
      if pPlayerStats:GetNumProjectsAdvanced(projectInfo.Index) == 0 then
        projectProgress = pBuildQueue:GetProjectProgress(projectInfo.Index);
      end
      if projectProgress ~= 0 then
        local progress = Round((projectProgress / projectCost), 2) * 100;
        progresses[1] = progress == 100 and "[ICON_CheckmarkBlue]" or (tostring(progress) .. "%");
        pValue[1]     = progress;
      end
    end

    -- 2nd milestone - moon landing
    if progresses[1] == "[ICON_CheckmarkBlue]" then
      for i, projectInfo in ipairs(MOON_LANDING_EXP2_PROJECT_INFOS) do
        local projectCost = pBuildQueue:GetProjectCost(projectInfo.Index);
        local projectProgress = projectCost;
        if pPlayerStats:GetNumProjectsAdvanced(projectInfo.Index) == 0 then
          projectProgress = pBuildQueue:GetProjectProgress(projectInfo.Index);
        end
        if projectProgress ~= 0 then
          local progress = Round((projectProgress / projectCost), 2) * 100;
          progresses[2] = progress == 100 and "[ICON_CheckmarkBlue]" or (tostring(progress) .. "%");
          pValue[2]     = progress;
        end
      end
    end

    -- 3rd milestone - mars landing
    if progresses[2] == "[ICON_CheckmarkBlue]" then
      for i, projectInfo in ipairs(MARS_COLONY_EXP2_PROJECT_INFOS) do
        local projectCost = pBuildQueue:GetProjectCost(projectInfo.Index);
        local projectProgress = projectCost;
        if pPlayerStats:GetNumProjectsAdvanced(projectInfo.Index) == 0 then
          projectProgress = pBuildQueue:GetProjectProgress(projectInfo.Index);
        end
        if projectProgress ~= 0 then
          local progress = Round((projectProgress / projectCost), 2) * 100;
          progresses[3] = progress == 100 and "[ICON_CheckmarkBlue]" or (tostring(progress) .. "%");
          pValue[3]     = progress;
        end
      end
    end

    -- 4th milestone - exoplanet expeditiion
    if progresses[3] == "[ICON_CheckmarkBlue]" then
      for i, projectInfo in ipairs(EXOPLANET_EXP2_PROJECT_INFOS) do
        local projectCost = pBuildQueue:GetProjectCost(projectInfo.Index);
        local projectProgress = projectCost;
        if pPlayerStats:GetNumProjectsAdvanced(projectInfo.Index) == 0 then
          projectProgress = pBuildQueue:GetProjectProgress(projectInfo.Index);
        end
        if projectProgress ~= 0 then
          local progress = Round((projectProgress / projectCost), 2) * 100;
          progresses[4] = progress == 100 and "[ICON_CheckmarkBlue]" or (tostring(progress) .. "%");
          pValue[4]     = progress;
        end
      end
    end

  end

  -- 5th - final mission
  if progresses[4] == "[ICON_CheckmarkBlue]" then
    if localPlayer then
      local lightYears        = pPlayerStats:GetScienceVictoryPoints();
      local lightYearsPerTurn = pPlayer:GetStats():GetScienceVictoryPointsPerTurn();
      local totalLightYears   = localPlayer:GetStats():GetScienceVictoryPointsTotalNeeded();
      local progress = Round((lightYears / totalLightYears), 2) * 100;
      progresses[1] = "";
      progresses[2] = "";
      progresses[3] = "";
      progresses[4] = "";
      if progress >= 100 then
        progresses[5] = "[ICON_Checkmark][ICON_Checkmark][ICON_Checkmark][ICON_Checkmark][ICON_Checkmark]";
      else
        progresses[5] = lightYears .. "([COLOR_ModStatusGreen]+" .. lightYearsPerTurn .. "[ENDCOLOR]) / " .. totalLightYears;
      end
      pValue[5]     = progress;
    end
  end

  return progresses, pValue;
end

-- Culture ===================================================================
function GetCultureData()
  local playerData = GetPlayerBasicData();

  -- add data
  for _, pData in pairs(playerData) do
    local playerID = pData.playerID;
    local pPlayer  = Players[playerID];
    pData.tourism  = Round(pPlayer:GetStats():GetTourism(), 0);
    pData.cultureY = Round(pPlayer:GetCulture():GetCultureYield(), 0);
    local customData = GetCultureCustomData(playerID);
    pData.visiter  = customData.visiter;
    pData.tourists = customData.tourists;
  end

  -- sort
  local comparator = function(t, a, b)
                       local aPercent = t[a].visiter / t[a].tourists;
                       local bPercent = t[b].visiter / t[b].tourists;
                       if aPercent ~= bPercent then
                         return aPercent > bPercent;
                       end
                       if t[a].tourism ~= t[b].tourism then
                         return t[a].tourism > t[b].tourism;
                       end
                       return t[a].cultureY > t[b].cultureY;
                     end;

  return GetVictoryLeader(playerData, comparator);
end

-- ---------------------------------------------------------------------------
function GetCultureCustomData(playerID)
  local data = {};
  local pPlayer = Players[playerID];
  local requiredTourists = 0;
  for i, player in ipairs(Players) do
    if i ~= playerID and IsAliveAndMajor(i) and player:GetTeam() ~= pPlayer:GetTeam() then
      local iStaycationers = player:GetCulture():GetStaycationers();
      if iStaycationers >= requiredTourists then
        requiredTourists = iStaycationers + 1;
      end
    end
  end
  data.visiter  = pPlayer:GetCulture():GetTouristsTo();
  data.tourists = requiredTourists;
  return data;
end

-- Domination ================================================================
function GetDominationData()
  local playerData = GetPlayerBasicData();

  -- add data
  for _, pData in pairs(playerData) do
    local playerID = pData.playerID;
    local pPlayer  = Players[playerID];
    pData.strength = pPlayer:GetStats():GetMilitaryStrengthWithoutTreasury();
    local customData = GetMilitaryCustomData(playerID);
    pData.cities   = customData.cities;
    pData.capture  = customData.capture;
  end

  -- sort
  local comparator = function(t, a, b)
                       if t[a].capture ~= t[b].capture then
                         return t[a].capture > t[b].capture;
                       end
                       return t[a].strength > t[b].strength;
                     end;

  return GetVictoryLeader(playerData, comparator);
end

-- ---------------------------------------------------------------------------
function GetMilitaryCustomData(playerID)
  local data = {};
  local pPlayer = Players[playerID];
  local cities = 0;
  local capitals = 0;
  for _, city in pPlayer:GetCities():Members() do
    cities = cities + 1;
    local originalOwnerID = city:GetOriginalOwner();
    local pOriginalOwner = Players[originalOwnerID];
    if(playerID ~= originalOwnerID and pOriginalOwner:IsMajor() and city:IsOriginalCapital()) then
      capitals = capitals + 1;
    end
  end
  data.cities  = cities;
  data.capture = capitals;
  return data;
end

-- Religion ==================================================================
function GetReligionData()
  local playerData = GetPlayerBasicData();

  -- add data
  for _, pData in pairs(playerData) do
    local playerID = pData.playerID;
    local pPlayer  = Players[playerID];
    pData.faithY   = Round(pPlayer:GetReligion():GetFaithYield(), 0);
    local customData = GetReligionCustomData(playerID);
    pData.convert   = customData.convert;
    pData.totalCiv  = customData.totalCiv;
  end

  -- sort
  local comparator = function(t, a, b)
                       if t[a].convert ~= t[b].convert then
                         return t[a].convert > t[b].convert;
                       end
                       return t[a].faithY > t[b].faithY;
                     end;

  return GetVictoryLeader(playerData, comparator);
end

-- ---------------------------------------------------------------------------
function GetReligionCustomData(playerID)
  local data = {};
  local pPlayer = Players[playerID];
  local convertCount = 0;
  local totalCiv = 0;
  local playerReligionType = pPlayer:GetReligion():GetReligionTypeCreated();
  for i, otherPlayer in ipairs(Players) do
    if IsAliveAndMajor(i) then
      totalCiv = totalCiv + 1;
      if playerReligionType ~= -1 then
        local otherReligion = otherPlayer:GetReligion();
        if otherReligion ~= nil then
          local otherReligionType = otherReligion:GetReligionInMajorityOfCities();
          if otherReligionType == playerReligionType then
            convertCount = convertCount + 1;
          end
        end
      end
    end
  end
  data.convert  = convertCount;
  data.totalCiv = totalCiv;
  return data;
end

-- Diplomatic ================================================================
function GetDiplomaticData()
  local playerData = GetPlayerBasicData();

  -- add data
  for _, pData in pairs(playerData) do
    local playerID = pData.playerID;
    local pPlayer  = Players[playerID];
    local customData = GetDiplomaticCustomData(playerID);
    pData.favor     = customData.favor;
    pData.favorPT   = customData.favorPT;
    pData.current   = customData.current;
    pData.total     = customData.total;
  end

  -- sort
  local comparator = function(t, a, b)
                       if t[a].current ~= t[b].current then
                         return t[a].current > t[b].current;
                       end
                       if t[a].favor ~= t[b].favor then
                         return t[a].favor > t[b].favor;
                       end
                       return t[a].favorPT > t[b].favorPT;
                     end;

  return GetVictoryLeader(playerData, comparator);
end

-- ---------------------------------------------------------------------------
function GetDiplomaticCustomData(playerID)
  local data = {};
  local pPlayer = Players[playerID];
  data.favor   = pPlayer:GetFavor();
  data.favorPT = pPlayer:GetFavorPerTurn();
  data.current = pPlayer:GetStats():GetDiplomaticVictoryPoints();
  data.total = GlobalParameters.DIPLOMATIC_VICTORY_POINTS_REQUIRED;
  return data;
end


-- ===========================================================================
-- Help Function
-- ---------------------------------------------------------------------------
function GetPlayerBasicData()
  local playerData = {};

  for _, pPlayer in ipairs(aliveMajors) do
    local playerID = pPlayer:GetID();
    local pPlayerConfig = PlayerConfigurations[playerID];
    playerData[playerID] = {
      playerID      = playerID;
      isLocalPlayer = playerID == Game.GetLocalPlayer();
      isHuman       = GameConfiguration.IsAnyMultiplayer() and pPlayerConfig:IsHuman();
      isMet         = kMetPlayers[playerID];
      leaderName    = pPlayerConfig:GetLeaderTypeName();
      leaderIcon    = "ICON_" .. pPlayerConfig:GetLeaderTypeName();
    };
  end

  return playerData;
end

-- ---------------------------------------------------------------------------
function GetVictoryLeader(playerData, comparator)
  local sortedLeader = {};
  local rank = 0;
  local localLeader = {};
  local localRank = 0;
  for id, leader in SortedTable(playerData, comparator) do
    rank = rank + 1;
    if rank < 4 then
      table.insert(sortedLeader, leader);
    end
    if id == localPlayerID then
      localLeader = leader;
      localRank   = rank;
    end
  end
  if localRank > 3 then
    table.insert(sortedLeader, localLeader);
  end
  return sortedLeader, localRank;
end

-- ---------------------------------------------------------------------------
function CuiLeaderTexture(icon, size, shouldShow)
  local x, y, sheet;
  x, y, sheet = IconManager:FindIconAtlas(icon, size);
  if (sheet == nil or sheet == "" or (not shouldShow)) then
    x, y, sheet = IconManager:FindIconAtlas("ICON_LEADER_DEFAULT", size);
  end
  return x, y, sheet;
end

-- ---------------------------------------------------------------------------
function CuiSetIconToSize(iconControl, iconName, iconSize)
  if iconSize == nil then iconSize = 36; end
  local x, y, szIconName, iconSize = IconManager:FindIconAtlasNearestSize(iconName, iconSize, true);
  iconControl:SetTexture(x, y, szIconName);
  iconControl:SetSizeVal(iconSize, iconSize);
end

