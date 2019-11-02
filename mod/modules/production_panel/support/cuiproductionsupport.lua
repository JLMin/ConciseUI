-- ===========================================================================
-- Cui Production Panel Support Functions
-- ---------------------------------------------------------------------------

include( "cui_helper" );

-- ===========================================================================
-- Help Functions
-- ---------------------------------------------------------------------------
function GetDistrictBaseType(district)
  local dType = district.DistrictType;
  if not isNil(GameInfo.DistrictReplaces[dType]) then
    dType = GameInfo.DistrictReplaces[dType].ReplacesDistrictType;
  end
  return dType;
end

-- ---------------------------------------------------------------------------
function CuiCanProduceDistrict(city, queue, district)
  local canProduce, results = queue:CanProduce(district.Hash, false, true);

  if not canProduce then
    local notSuitable = CuiDistrictReasonCheck(results);
    --
    if notSuitable then
      local plots = GetCityRelatedPlotIndexesDistrictsAlternative(city, district.Hash);
      if not isNil(plots) then canProduce = true; end
    end
  end

  return canProduce, results;
end

-- ---------------------------------------------------------------------------
function CuiDistrictReasonCheck(results)
  local suitableTxt = "LOC_DISTRICT_ZONE_NO_SUITABLE_LOCATION";
  -- local floodedTxt  = Locale.Lookup("LOC_DISTRICT_REPAIR_LOCATION_FLOODED");
  local notSuitable = false;
  -- local isFlooded   = false;

  if not isNil(results) then
    local fReasons = results[CityCommandResults.FAILURE_REASONS];
    if not isNil(fReasons) then
      for i, v in ipairs(fReasons) do
        if v == suitableTxt then notSuitable = true; end
        -- if v == floodedTxt  then isFlooded   = true; end
      end
    end
  end

  return notSuitable;
end

-- ---------------------------------------------------------------------------
function CuiIsItemInProgress(queue, item)
  if item.Progress > 0 then return true; end
  return item.RequiresPlacement and queue:HasBeenPlaced(item.Hash);
end

-- ---------------------------------------------------------------------------
function GetFailureToolTip(canProduce, results)
  if (not canProduce) and results then
    local failureReasons = results[CityCommandResults.FAILURE_REASONS];
    if not isNil(failureReasons) then
      local allReasons = "";
      for i, v in ipairs(failureReasons) do
        if not isNil(allReasons) then allReasons = allReasons .. "[NEWLINE]"; end
        allReasons = allReasons .. "[COLOR:Red]" .. Locale.Lookup(v) .. "[ENDCOLOR]";
      end
      return allReasons;
    end
  end

  return "";
end

-- ---------------------------------------------------------------------------
function GetPurchaseCostToolTip(cost, yield)
  local tooltip = "";
  if cost ~= 0 then
    local concatString = "";
    if yield == "YIELD_GOLD" then
      concatString = " [ICON_GOLD] " .. Locale.Lookup("LOC_YIELD_GOLD_NAME");
    elseif yield == "YIELD_FAITH" then
      concatString = " [ICON_FAITH] " .. Locale.Lookup("LOC_YIELD_FAITH_NAME");
    end
    tooltip = Locale.Lookup("LOC_HUD_PURCHASE") .. ": " .. cost .. concatString;
  end
  return tooltip;
end

-- ---------------------------------------------------------------------------
function GetProduceCostToolTip(cost, progress)
  local tooltip = "";
  if cost ~= 0 then
    local concatString = " [ICON_Production] " .. Locale.Lookup("LOC_HUD_PRODUCTION");
    local costString = tostring(cost);
    if progress > 0 then
      costString = tostring(progress) .. "/" .. tostring(cost);
    end
    tooltip = Locale.Lookup("LOC_HUD_PRODUCTION_COST") .. ": " .. costString .. concatString;
  end
  return tooltip;
end

-- ---------------------------------------------------------------------------
function TurnString(t)
  local n = (t == -1) and "999+" or t;
  return t .. "[ICON_TURN]";
end

-- ---------------------------------------------------------------------------
function ComposeTT( ... )
  local args = { ... };
  if isNil(args) then return ""; end

  local t = "";
  local r = "[NEWLINE][NEWLINE]";
  for _, v in ipairs(args) do
    if not isNil(v) then
      if isNil(t) then t = v;
                  else t = t .. r .. v;
      end
    end
  end
  return t;
end

-- ===========================================================================
-- Repeat Project
-- ---------------------------------------------------------------------------
RepeatableProject = {
  GameInfo.Projects["PROJECT_ENHANCE_DISTRICT_HOLY_SITE"].Hash,
  GameInfo.Projects["PROJECT_ENHANCE_DISTRICT_CAMPUS"].Hash,
  GameInfo.Projects["PROJECT_ENHANCE_DISTRICT_ENCAMPMENT"].Hash,
  GameInfo.Projects["PROJECT_ENHANCE_DISTRICT_HARBOR"].Hash,
  GameInfo.Projects["PROJECT_ENHANCE_DISTRICT_COMMERCIAL_HUB"].Hash,
  GameInfo.Projects["PROJECT_ENHANCE_DISTRICT_THEATER"].Hash,
  GameInfo.Projects["PROJECT_ENHANCE_DISTRICT_INDUSTRIAL_ZONE"].Hash,
  GameInfo.Projects["PROJECT_CARNIVAL"].Hash
}

if isExpansion1 then
  table.insert(RepeatableProject, GameInfo.Projects["PROJECT_BREAD_AND_CIRCUSES"].Hash);
  table.insert(RepeatableProject, GameInfo.Projects["PROJECT_WATER_CARNIVAL"].Hash);
end

if isExpansion2 then
  table.insert(RepeatableProject, GameInfo.Projects["PROJECT_CARBON_RECAPTURE"].Hash);
  table.insert(RepeatableProject, GameInfo.Projects["PROJECT_TRAIN_ATHLETES"].Hash);
  table.insert(RepeatableProject, GameInfo.Projects["PROJECT_TRAIN_ASTRONAUTS"].Hash);
  table.insert(RepeatableProject, GameInfo.Projects["PROJECT_ORBITAL_LASER"].Hash);
  table.insert(RepeatableProject, GameInfo.Projects["PROJECT_TERRESTRIAL_LASER"].Hash);
end

function CuiIsProjectRepeatable(project)
  for _, h in ipairs(RepeatableProject) do
    if project.Hash == h then return true; end
  end
  return false
end

function AddProjectToRepeatList(city, projectHash)
  local cityName = city:GetName();
  RepeatedProjectsList[cityName] = projectHash;
end

function StopRepeatProject(city)
  local cityName = city:GetName();
  if RepeatedProjectsList[cityName] then
    RepeatedProjectsList[cityName] = nil;
  end
end

function RepeatProjects()
  local playerID = Game.GetLocalPlayer();
  local player = Players[playerID];
  if player == nil then return; end

  for i, city in player:GetCities():Members() do
    local cityName = city:GetName();
    if RepeatedProjectsList[cityName] then
      projectHash = RepeatedProjectsList[cityName]
      local tParameters = {};
      tParameters[CityOperationTypes.PARAM_PROJECT_TYPE] = projectHash;
      GetBuildInsertMode(tParameters);
      CityManager.RequestOperation(city, CityOperationTypes.BUILD, tParameters);
    end
  end
end

-- ===========================================================================
-- Test & Debug
-- ---------------------------------------------------------------------------
function PPD(data)
 --
end

function isItem(item, name)
  local locName = Locale.Lookup(item.Name);
  return locName == name;
end

function pItem(item, extraInfo)
  print(Locale.Lookup(item.Name), extraInfo);
end

-- ===========================================================================
-- Initialize
-- ---------------------------------------------------------------------------
function Initialize()
  RepeatedProjectsList = {};
  Events.PlayerTurnActivated.Add(RepeatProjects);
end
Initialize()