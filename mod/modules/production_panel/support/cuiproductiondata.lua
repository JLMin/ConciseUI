-- ===========================================================================
-- Cui Production Panel Data Functions
-- ---------------------------------------------------------------------------

include( "ToolTipHelper" );
include( "AdjacencyBonusSupport" );

include( "cui_helper" );
include( "cuiproductionsupport" );

-- ===========================================================================
-- Variables
-- ---------------------------------------------------------------------------

local m_playerID;
local m_player;
local m_city;
local m_queue;

local CMD = CityCommandTypes;

local UNIT_STANDARD = MilitaryFormationTypes.STANDARD_MILITARY_FORMATION;
local UNIT_CORPS    = MilitaryFormationTypes.CORPS_MILITARY_FORMATION;
local UNIT_ARMY     = MilitaryFormationTypes.ARMY_MILITARY_FORMATION;

-- ===========================================================================
-- Panel Functions
-- ---------------------------------------------------------------------------
function GetPanelData()
  local playerID = Game.GetLocalPlayer();

  local player = Players[playerID];
  if isNil(player) then return nil; end

  local city = UI.GetHeadSelectedCity();
  if isNil(city)   then return nil; end

  m_playerID = playerID;
  m_player   = player
  m_city     = city;
  m_queue    = city:GetBuildQueue();

  local d = GetCityDistricts();
  local w = GetCityWonders();
  local u = GetCityUnits();
  local p = GetCityProjects();

  if isNil(d) and isNil(w) and isNil(u) and isNil(p) then
    return nil;
  end

  local panelData = {};

  panelData.Owner  = m_playerID;
  panelData.Player = m_player;
  panelData.City   = m_city;

  panelData.Districts = d;
  panelData.Wonders   = w;
  panelData.Units     = u;
  panelData.Projects  = p;

  return panelData;
end

-- ===========================================================================
-- Districts Data
-- ---------------------------------------------------------------------------
function GetCityDistricts()
  local districts = {};
  for district in GameInfo.Districts() do
    if IsDistrictUnlocked(district) then
      local data = GetDistrictData(district);
      table.insert(districts, data);
    end
  end
  return districts;
end

-- ---------------------------------------------------------------------------
function IsDistrictUnlocked(district)
  local canProduce = m_queue:CanProduce(district.Hash, true);
  local cityDistricts = m_city:GetDistricts();
  local hasDistrict = cityDistricts:HasDistrict(district.Index);
  local isWonderD = "LOC_WONDER_NAME" == district.Name;

  return (canProduce or hasDistrict) and (not isWonderD);
end

-- ---------------------------------------------------------------------------
function GetDistrictData(district)
  local data = {};
  data.IsDistrict = true;

  -- basic data
  data.Name  = district.Name;
  data.Hash  = district.Hash;
  data.Type  = district.DistrictType;
  data.Turns = m_queue:GetTurnsLeft(district.DistrictType);

  -- produce data
  local canStart, results = CuiCanProduceDistrict(m_city, m_queue, district)
  local cost = m_queue:GetDistrictCost(district.Index);
  local progress = m_queue:GetDistrictProgress(district.Index);

  local bToolTip = ToolTipHelper.GetToolTip(district.DistrictType, playerID);
  local fToolTip = GetFailureToolTip(canStart, results);
  local cToolTip = GetProduceCostToolTip(cost, progress);

  data.Enable   = canStart;
  data.Cost     = cost;
  data.Progress = progress;
  data.BasicTT  = bToolTip;
  data.ReasonTT = fToolTip;
  data.CostTT   = cToolTip;

  -- gold data
  local goldSource = m_player:GetTreasury();
  local goldData = GetDistrictPurchaseData(district, m_city, "YIELD_GOLD", goldSource, "LOC_BUILDING_INSUFFICIENT_FUNDS");
  data.GoldUnlock   = goldData.Unlock;
  data.GoldCost     = goldData.Cost;
  data.GoldEnable   = goldData.Enable;
  data.GoldReasonTT = goldData.ReasonTT;
  data.GoldCostTT   = goldData.CostTT;

  -- faith data
  local faithSource = m_player:GetReligion();
  local faithData = GetDistrictPurchaseData(district, m_city, "YIELD_FAITH", faithSource, "LOC_BUILDING_INSUFFICIENT_FAITH");
  data.FaithUnlock   = faithData.Unlock;
  data.FaithCost     = faithData.Cost;
  data.FaithEnable   = faithData.Enable;
  data.FaithReasonTT = faithData.ReasonTT;
  data.FaithCostTT   = faithData.CostTT;

  -- additional data
  local cityDistricts = m_city:GetDistricts();
  local isContaminated = cityDistricts:IsContaminated(district.Index);
  local contaminatedTurns = 0;
  if isContaminated then
    for _, item in cityDistricts:Members() do
      local dInfo = GameInfo.Districts[item:GetType()];
      if dInfo.PrimaryKey == district.DistrictType then
        local fm = Game.GetFalloutManager();
        local plot = Map.GetPlot(item:GetX(), item:GetY());
        contaminatedTurns = fm:GetFalloutTurnsRemaining(plot:GetIndex());
      end
    end
  end
  data.Contaminated      = isContaminated;
  data.ContaminatedTurns = contaminatedTurns;
  data.IsPillaged        = cityDistricts:IsPillaged(district.Index);
  data.HasBeenBuilt      = cityDistricts:HasDistrict(district.Index);
  data.OnePerCity        = district.OnePerCity;
  data.BasicType         = GetDistrictBaseType(district);
  data.RequiresPlacement = district.RequiresPlacement;

  -- buildings
  data.Buildings = GetDistrictBuildings(district);

  return data;
end

-- ---------------------------------------------------------------------------
function GetDistrictPurchaseData(district, city, yield, source, key)
  local data = {};

  local yieldType = GameInfo.Yields[yield].Index;
  local param = {};
    param[CMD.PARAM_DISTRICT_TYPE] = district.Hash;
    param[CMD.PARAM_YIELD_TYPE] = yieldType;

  if CityManager.CanStartCommand(city, CMD.PURCHASE, true, param, false) then
    local canStart, results = CityManager.CanStartCommand(city, CMD.PURCHASE, false, param, true);
    local tooltip = GetFailureToolTip(canStart, results);
    local canAfford = source:CanAfford(city:GetID(), district.Hash);

    if not canAfford then
      if not isNil(tooltip) then tooltip = tooltip .. "[NEWLINE]"; end
      tooltip = tooltip .. "[COLOR:Red]" .. Locale.Lookup(key) .. "[ENDCOLOR]";
    end

    local noFailure = false;
    if isNil(tooltip) then noFailure = true; end

    data.Unlock   = canStart;
    data.Cost     = city:GetGold():GetPurchaseCost(yieldType, district.Hash);
    data.Enable   = canAfford and noFailure;
    data.ReasonTT = tooltip;
    data.CostTT   = GetPurchaseCostToolTip(data.Cost, yield);
  end

  return data;
end

-- ===========================================================================
-- Buildings Data
-- ---------------------------------------------------------------------------
function GetDistrictBuildings(district)
  local buildings = {};
  for building in GameInfo.Buildings() do
    if not building.IsWonder and IsBuildingUnlocked(district, building) then
      local data = GetBuildingData(building, district);
      table.insert(buildings, data);
    end
  end
  return buildings;
end

-- ---------------------------------------------------------------------------
function IsBuildingUnlocked(district, building)
  local dType = GetDistrictBaseType(district);
  local inThisDistrict = dType == building.PrereqDistrict;
  local canProduce = m_queue:CanProduce(building.Hash, true);

  return inThisDistrict and canProduce;
end

-- ---------------------------------------------------------------------------
function GetBuildingData(building, district)
  local data = {};
  data.IsBuilding = true;

  -- basic data
  data.Name  = building.Name;
  data.Hash  = building.Hash;
  data.Type  = building.BuildingType;
  data.Turns = m_queue:GetTurnsLeft(building.Hash);

  -- produce data
  local canStart, results = m_queue:CanProduce(building.Hash, false, true);
  local cost = m_queue:GetBuildingCost(building.Index);
  local progress = m_queue:GetBuildingProgress(building.Index);

  local bToolTip = ToolTipHelper.GetBuildingToolTip(building.Hash, m_playerID, m_city);
  local fToolTip = GetFailureToolTip(canStart, results);
  local cToolTip = GetProduceCostToolTip(cost, progress);

  data.Enable   = canStart and (not building.MustPurchase);
  data.Cost     = cost;
  data.Progress = progress;
  data.BasicTT  = bToolTip;
  data.ReasonTT = fToolTip;
  data.CostTT   = cToolTip;

  -- gold data
  if building.PurchaseYield == "YIELD_GOLD" then
    local goldSource = m_player:GetTreasury();
    local goldData = GetBuildingPurchaseData(building, m_city, "YIELD_GOLD", goldSource, "LOC_BUILDING_INSUFFICIENT_FUNDS");
    data.GoldUnlock   = goldData.Unlock;
    data.GoldCost     = goldData.Cost;
    data.GoldEnable   = goldData.Enable;
    data.GoldReasonTT = goldData.ReasonTT;
    data.GoldCostTT   = goldData.CostTT;
  end

  -- faith data
  if building.PurchaseYield == "YIELD_FAITH" or m_city:GetGold():IsBuildingFaithPurchaseEnabled(building.Hash) then
    local faithSource = m_player:GetReligion();
    local faithData = GetBuildingPurchaseData(building, m_city, "YIELD_FAITH", faithSource, "LOC_BUILDING_INSUFFICIENT_FAITH");
    data.FaithUnlock   = faithData.Unlock;
    data.FaithCost     = faithData.Cost;
    data.FaithEnable   = faithData.Enable;
    data.FaithReasonTT = faithData.ReasonTT;
    data.FaithCostTT   = faithData.CostTT;
  end

  -- additional data
  local cityBuildings = m_city:GetBuildings();
  data.RequiresPlacement = building.RequiresPlacement;
  data.MustPurchase = building.MustPurchase;
  data.IsPillaged = cityBuildings:IsPillaged(building.Hash);
  data.PrereqType = GetDistrictBaseType(district);
  data.PrereqHash = district.Hash;

  return data;
end

-- ---------------------------------------------------------------------------
function GetBuildingPurchaseData(building, city, yield, source, key)
  local data = {};

  local yieldType = GameInfo.Yields[yield].Index;
  local param = {};
    param[CMD.PARAM_BUILDING_TYPE] = building.Hash;
    param[CMD.PARAM_YIELD_TYPE] = yieldType;

  if CityManager.CanStartCommand(city, CMD.PURCHASE, true, param, false) then
    local canStart, results = CityManager.CanStartCommand(city, CMD.PURCHASE, false, param, true);
    local tooltip = GetFailureToolTip(canStart, results);
    local canAfford = source:CanAfford(city:GetID(), building.Hash);
    if not canAfford then
      if not isNil(tooltip) then tooltip = tooltip .. "[NEWLINE]"; end
      tooltip = tooltip .. "[COLOR:Red]" .. Locale.Lookup(key) .. "[ENDCOLOR]";
    end

    local noFailure = false;
    if isNil(tooltip) then noFailure = true; end

    data.Unlock   = true;
    data.Cost     = city:GetGold():GetPurchaseCost(yieldType, building.Hash);
    data.Enable   = canAfford and noFailure;
    data.ReasonTT = tooltip;
    data.CostTT   = GetPurchaseCostToolTip(data.Cost, yield);
  end

  return data;
end

-- ===========================================================================
-- Wonders Data
-- ---------------------------------------------------------------------------
function GetCityWonders()
  local wonders = {};
  for wonder in GameInfo.Buildings() do
    if wonder.IsWonder and IsWonderUnlocked(wonder) then
      local data = GetWonderData(wonder);
      table.insert(wonders, data);
    end
  end
  return wonders;
end

-- ---------------------------------------------------------------------------
function IsWonderUnlocked(wonder)
  local canProduce = m_queue:CanProduce(wonder.Hash, true);

  return canProduce;
end

-- ---------------------------------------------------------------------------
function GetWonderData(wonder)
  local data = {};
  data.IsWonder = true;

  -- basic data
  data.Name  = wonder.Name;
  data.Hash  = wonder.Hash;
  data.Type  = wonder.BuildingType;
  data.Turns = m_queue:GetTurnsLeft(wonder.Hash);

  -- produce data
  local canStart, results = m_queue:CanProduce(wonder.Hash, false, true);

  if (not canStart) and (not isNil(results)) then
    if results[CityOperationResults.NO_SUITABLE_LOCATION] then
      local purchaseablePlots = GetCityRelatedPlotIndexesWondersAlternative(m_city, wonder.Hash);
      if not isNil(purchaseablePlots) then
        canStart = true;
      end
    end
  end

  local cost = m_queue:GetBuildingCost(wonder.Index);
  local progress = m_queue:GetBuildingProgress(wonder.Index);

  local bToolTip = ToolTipHelper.GetBuildingToolTip(wonder.Hash, m_playerID, m_city);
  local fToolTip = GetFailureToolTip(canStart, results);
  local cToolTip = GetProduceCostToolTip(cost, progress);

  data.Enable   = canStart;
  data.Cost     = cost;
  data.Progress = progress;
  data.BasicTT  = bToolTip;
  data.ReasonTT = fToolTip;
  data.CostTT   = cToolTip;

  -- additional data
  data.RequiresPlacement = wonder.RequiresPlacement;

  return data;
end

-- ===========================================================================
-- Units Data
-- ---------------------------------------------------------------------------
function GetCityUnits()
  local units = {};
  for unit in GameInfo.Units() do
    if IsUnitUnlocked(unit) then
      local data = GetUnitData(unit, UNIT_STANDARD);
      table.insert(units, data);
    end
  end
  local SortFunc = function(a, b)
                     if a.IsCivilian ~= b.IsCivilian then return a.IsCivilian; end
                     return a.Index < b.Index;
                   end;
  if not isNil(units) then table.sort(units, SortFunc); end
  return units;
end

-- ---------------------------------------------------------------------------
function IsUnitUnlocked(unit)
  local param = {};
    param.UnitType = unit.Hash;
    param.MilitaryFormationType = UNIT_STANDARD;
  local canProduce = m_queue:CanProduce(param, true);

  return canProduce;
end

-- ---------------------------------------------------------------------------
function GetUnitData(unit, formation)
  local isStandard = formation == UNIT_STANDARD;

  local data = {};
  data.IsUnit     = true;
  data.IsStandard = formation == UNIT_STANDARD;
  data.IsCorps    = formation == UNIT_CORPS;
  data.IsArmy     = formation == UNIT_ARMY;
  data.IsCivilian = unit.FormationClass == "FORMATION_CLASS_CIVILIAN";
  data.Index      = unit.Index;

  -- basic data
  data.Name  = unit.Name;
  data.Hash  = unit.Hash;
  data.Type  = unit.UnitType;
  data.Turns = m_queue:GetTurnsLeft(unit.Hash, formation);

  -- produce data
  local param = {};
    param.UnitType = unit.Hash;
    param.MilitaryFormationType = formation;
  local canStart, results = m_queue:CanProduce(param, false, true);
  local cost = m_queue:GetUnitCost(unit.Index);
  local progress = m_queue:GetUnitProgress(unit.Index);

  local bToolTip = ToolTipHelper.GetUnitToolTip(unit.Hash, formation, m_queue);
  local fToolTip = GetFailureToolTip(canStart, results);
  local cToolTip = GetProduceCostToolTip(cost, progress);

  data.Enable   = canStart and (not unit.MustPurchase);
  data.Cost     = cost;
  data.Progress = progress;
  data.BasicTT  = bToolTip;
  data.ReasonTT = fToolTip;
  data.CostTT   = cToolTip;

  -- gold data
  if unit.PurchaseYield == "YIELD_GOLD" then
    local goldSource = m_player:GetTreasury();
    local goldData = GetUnitPurchaseData(unit, m_city, "YIELD_GOLD", goldSource, "LOC_BUILDING_INSUFFICIENT_FUNDS", formation);
    data.GoldUnlock   = goldData.Unlock;
    data.GoldCost     = goldData.Cost;
    data.GoldEnable   = goldData.Enable;
    data.GoldReasonTT = goldData.ReasonTT;
    data.GoldCostTT   = goldData.CostTT;
  end

  -- faith data
  if unit.PurchaseYield == "YIELD_FAITH" or m_city:GetGold():IsUnitFaithPurchaseEnabled(unit.Hash) then
    local faithSource = m_player:GetReligion();
    local faithData = GetUnitPurchaseData(unit, m_city, "YIELD_FAITH", faithSource, "LOC_BUILDING_INSUFFICIENT_FAITH", formation);
    data.FaithUnlock   = faithData.Unlock;
    data.FaithCost     = faithData.Cost;
    data.FaithEnable   = faithData.Enable;
    data.FaithReasonTT = faithData.ReasonTT;
    data.FaithCostTT   = faithData.CostTT;
  end

  -- additional data
  data.MustPurchase = unit.MustPurchase;
  data.Domain = unit.Domain;

  -- corps and army
  if isStandard and results then
    if results[CityOperationResults.CAN_TRAIN_CORPS] then
      data.Corps = GetUnitData(unit, UNIT_CORPS);
    end

    if results[CityOperationResults.CAN_TRAIN_ARMY] then
      data.Army = GetUnitData(unit, UNIT_ARMY);
    end
  end

  return data;
end

-- ---------------------------------------------------------------------------
function GetUnitPurchaseData(unit, city, yield, source, key, formation)
  local data = {};

  local yieldType = GameInfo.Yields[yield].Index;

  local standard = {};
    standard[CMD.PARAM_UNIT_TYPE] = unit.Hash;
    standard[CMD.PARAM_YIELD_TYPE] = yieldType;
  local corpsAndArmy = {};
    corpsAndArmy[CMD.PARAM_UNIT_TYPE] = unit.Hash;
    corpsAndArmy[CMD.PARAM_YIELD_TYPE] = yieldType;
    corpsAndArmy[CMD.PARAM_MILITARY_FORMATION_TYPE] = formation;

  local param = formation == UNIT_STANDARD and standard or corpsAndArmy;

  if CityManager.CanStartCommand(city, CMD.PURCHASE, true, standard, false) then
    local canStart, results = CityManager.CanStartCommand(city, CMD.PURCHASE, false, param, true);
    local tooltip = GetFailureToolTip(canStart, results);

    local canAfford = true;
    if formation == UNIT_STANDARD then
      canAfford = source:CanAfford(city:GetID(), unit.Hash);
    else
      canAfford = source:CanAfford(city:GetID(), unit.Hash, formation);
    end

    if not canAfford then
      if not isNil(tooltip) then tooltip = tooltip .. "[NEWLINE]"; end
      tooltip = tooltip .. "[COLOR:Red]" .. Locale.Lookup(key) .. "[ENDCOLOR]";
    end

    local noFailure = false;
    if isNil(tooltip) then noFailure = true; end

    data.Unlock   = true;
    data.Cost     = city:GetGold():GetPurchaseCost(yieldType, unit.Hash, formation);
    data.Enable   = canAfford and noFailure;
    data.ReasonTT = tooltip;
    data.CostTT   = GetPurchaseCostToolTip(data.Cost, yield);
  end

  return data;
end

-- ===========================================================================
-- Projects Data
-- ---------------------------------------------------------------------------
function GetCityProjects()
  local projects = {};
  local sortedProjects = {};
  for project in GameInfo.Projects() do
    if IsProjectUnlocked(project) then
      local data = GetProjectData(project);
      table.insert(projects, data);
    end
  end
  
  local comparator = function(t, a, b)
                       if t[a].IsRepeatable ~= t[b].IsRepeatable then
                         return not t[a].IsRepeatable;
                       else
                         return t[a].Cost < t[b].Cost;
                       end
                     end
  
  for _, p in SortedTable(projects, comparator) do
    table.insert(sortedProjects, p);
  end
  return sortedProjects;
end

-- ---------------------------------------------------------------------------
function IsProjectUnlocked(project)
  local canProduce = m_queue:CanProduce(project.Hash, true);

  return canProduce;
end

-- ---------------------------------------------------------------------------
function GetProjectData(project)
  local data = {};
  data.IsProject = true;

  -- basic data
  data.Name  = project.Name;
  data.Hash  = project.Hash;
  data.Type  = project.ProjectType;
  data.Turns = m_queue:GetTurnsLeft(project.Hash);

  -- produce data
  local canStart, results = m_queue:CanProduce(project.Hash, false, true);

  local cost = m_queue:GetProjectCost(project.Index);
  local progress = m_queue:GetProjectProgress(project.Index);

  local bToolTip = ToolTipHelper.GetProjectToolTip(project.Hash, m_playerID, m_city);
  local fToolTip = GetFailureToolTip(canStart, results);
  local cToolTip = GetProduceCostToolTip(cost, progress);

  data.Enable   = canStart;
  data.Cost     = cost;
  data.Progress = progress;
  data.BasicTT  = bToolTip;
  data.ReasonTT = fToolTip;
  data.CostTT   = cToolTip;

  -- additional data
  data.IsRepeatable = CuiIsProjectRepeatable(project)

  return data;
end
