-- ---------------------------------------------------------------------------
-- Cui Tracker Support Functions
-- eudaimonia, 11/08/2019
-- ---------------------------------------------------------------------------
include("SupportFunctions")
include("PlayerSupport")
include("TeamSupport")
include("EspionageSupport")
include("cui_helper")

local localPlayerID = nil
local localPlayer = nil
local localDiplomacy = nil

-- ---------------------------------------------------------------------------
function PlayerInit()
  localPlayerID = Game.GetLocalPlayer()
  localPlayer = Players[localPlayerID]
  localDiplomacy = localPlayer:GetDiplomacy()
end
PlayerInit()

-- ===========================================================================
-- Data Function
-- ---------------------------------------------------------------------------
function GetWonderData()
  PlayerInit()

  local wonderData = {}
  local wonders = {}
  local colorSet = {}

  local tmpWonderList = {}
  for building in GameInfo.Buildings() do
    if building.IsWonder then
      local name = building.Name
      local index = building.Index
      local icon = "ICON_" .. building.BuildingType
      local wonder = {Index = index, Icon = icon, BeenBuilt = false, Color1 = "Clear", Color2 = "Clear"}
      tmpWonderList[name] = wonder
    end
  end

  local playerData = CuiGetPlayerBasicData()
  for _, pData in pairs(playerData) do
    local playerID = pData.playerID
    local player = Players[playerID]
    --
    local civName = Locale.Lookup("LOC_DIPLOPANEL_UNMET_PLAYER")
    local color1 = 0
    local color2 = 0
    --
    local visible = pData.isLocalPlayer or pData.isMet
    if visible then
      local config = PlayerConfigurations[playerID]
      civName = Locale.Lookup(config:GetCivilizationDescription())
      if pData.isLocalPlayer then
        civName = Locale.Lookup("LOC_GAMESUMMARY_CONTEXT_LOCAL", civName)
      end
      color1, color2 = UI.GetPlayerColors(playerID)
    end

    local indicator = {CivName = civName, Color1 = color1, Color2 = color2}
    table.insert(colorSet, indicator)
    --
    for _, city in player:GetCities():Members() do
      local cityPlots = Map.GetCityPlots():GetPurchasedPlots(city)
      if cityPlots ~= nil and next(cityPlots) ~= nil then
        local buds = city:GetBuildings()
        for _, plotID in pairs(cityPlots) do
          local budTypes = buds:GetBuildingsAtLocation(plotID)
          for _, budType in ipairs(budTypes) do
            local building = GameInfo.Buildings[budType]
            if building.IsWonder and buds:HasBuilding(building.Index) then
              local name = building.Name
              tmpWonderList[name].BeenBuilt = true
              tmpWonderList[name].Color1 = color1
              tmpWonderList[name].Color2 = color2
            end
          end
        end
      end
    end
  end
  --
  for _, wonder in pairs(tmpWonderList) do
    table.insert(wonders, wonder)
  end
  table.sort(wonders, function(a, b)
    return a.Index < b.Index
  end)

  wonderData.Wonders = wonders
  wonderData.Colors = colorSet
  return wonderData
end

-- ---------------------------------------------------------------------------
function GetResourceData()
  PlayerInit()

  local resourceData = {}
  local r_luxury = {}
  local r_strategic = {}
  local active = false

  for resource in GameInfo.Resources() do
    local icon = "ICON_" .. resource.ResourceType
    local amount = localPlayer:GetResources():GetResourceAmount(resource.Index)
    if resource.ResourceClassType == "RESOURCECLASS_LUXURY" then
      if amount > 0 then
        table.insert(r_luxury, {Icon = icon, Amount = amount, CanTrade = false, Duplicate = false})
      end
    elseif resource.ResourceClassType == "RESOURCECLASS_STRATEGIC" then
      local order = 0
      if resource.ResourceType == "RESOURCE_HORSES" then
        order = 1
      elseif resource.ResourceType == "RESOURCE_IRON" then
        order = 2
      elseif resource.ResourceType == "RESOURCE_NITER" then
        order = 3
      elseif resource.ResourceType == "RESOURCE_COAL" then
        order = 4
      elseif resource.ResourceType == "RESOURCE_OIL" then
        order = 5
      elseif resource.ResourceType == "RESOURCE_ALUMINUM" then
        order = 6
      elseif resource.ResourceType == "RESOURCE_URANIUM" then
        order = 7
      end

      if isExpansion2 then
        local playerResources = localPlayer:GetResources()
        local stockpileCap = playerResources:GetResourceStockpileCap(resource.ResourceType)

        local stockpileAmount = playerResources:GetResourceAmount(resource.ResourceType)
        local reservedAmount = playerResources:GetReservedResourceAmount(resource.ResourceType)
        local totalAmount = stockpileAmount + reservedAmount

        local accumulationPerTurn = playerResources:GetResourceAccumulationPerTurn(resource.ResourceType)
        local importPerTurn = playerResources:GetResourceImportPerTurn(resource.ResourceType)
        local bonusPerTurn = playerResources:GetBonusResourcePerTurn(resource.ResourceType)
        local perTurnAmount = accumulationPerTurn + importPerTurn + bonusPerTurn

        local unitConsumptionPerTurn = playerResources:GetUnitResourceDemandPerTurn(resource.ResourceType)
        local powerConsumptionPerTurn = playerResources:GetPowerResourceDemandPerTurn(resource.ResourceType)
        local totalConsumptionPerTurn = unitConsumptionPerTurn + powerConsumptionPerTurn

        table.insert(r_strategic, {
          Icon = icon,
          Amount = totalAmount,
          Cap = stockpileCap,
          APerTurn = perTurnAmount,
          MPerTurn = totalConsumptionPerTurn,
          Order = order
        })
      else
        table.insert(r_strategic, {Icon = icon, Amount = amount, Order = order})
      end
    end
  end

  local pForDeal = DealManager.GetWorkingDeal(DealDirection.OUTGOING, localPlayerID, localPlayerID)
  local possibleResources = DealManager.GetPossibleDealItems(localPlayerID, localPlayerID, DealItemTypes.RESOURCES,
                                                             pForDeal)
  if (possibleResources ~= nil) then
    for i, resource in ipairs(possibleResources) do
      local resourceDesc = GameInfo.Resources[resource.ForType]
      if (resourceDesc ~= nil and resourceDesc.ResourceClassType == "RESOURCECLASS_LUXURY") then
        local icon = "ICON_" .. resourceDesc.ResourceType
        for _, item in ipairs(r_luxury) do
          if item.Icon == icon then
            if item.Amount == 1 then
              item.CanTrade = true
            elseif item.Amount > 1 then
              item.CanTrade = true
              item.Duplicate = true
              active = true
            end
          end
        end
      end
    end
  end

  local sorted_luxury = {}
  local comparatorLuxury = function(t, a, b)
    if t[a].CanTrade ~= t[b].CanTrade then
      return t[a].CanTrade
    else
      return t[a].Amount > t[b].Amount
    end
  end
  for _, item in SortedTable(r_luxury, comparatorLuxury) do
    table.insert(sorted_luxury, item)
  end

  local sorted_strategic = {}
  local comparatorStrategic = function(t, a, b)
    return t[a].Order < t[b].Order
  end
  for _, item in SortedTable(r_strategic, comparatorStrategic) do
    table.insert(sorted_strategic, item)
  end

  resourceData.Luxury = sorted_luxury
  resourceData.Strategic = sorted_strategic
  resourceData.Active = active

  return resourceData
end

-- ---------------------------------------------------------------------------
function GetBorderData()
  PlayerInit()

  local borderData = {}
  local leaders = {}
  local active = false

  local playerData = CuiGetPlayerBasicData()
  for _, pData in pairs(playerData) do
    local playerID = pData.playerID
    local visible = (not pData.isLocalPlayer) and pData.isMet
    if visible then
      local hasImport = false
      local hasExport = false
      local canImport = false
      local canExport = false

      -- has import
      hasImport = localDiplomacy:HasOpenBordersFrom(playerID)
      -- has export
      local otherDiplomacy = Players[playerID]:GetDiplomacy()
      hasExport = otherDiplomacy:HasOpenBordersFrom(localPlayerID)
      -- can import
      if not hasImport then
        local pForDealFrom = DealManager.GetWorkingDeal(DealDirection.OUTGOING, playerID, localPlayerID)
        local possibleAgreementsFrom = DealManager.GetPossibleDealItems(playerID, localPlayerID,
                                                                        DealItemTypes.AGREEMENTS, pForDealFrom)
        if (possibleAgreementsFrom ~= nil) then
          for i, entry in ipairs(possibleAgreementsFrom) do
            if entry.SubTypeName == "LOC_DIPLOACTION_OPEN_BORDERS_NAME" then
              canImport = true
            end
          end
        end
      end
      -- can export
      if not hasExport then
        local pForDealTo = DealManager.GetWorkingDeal(DealDirection.OUTGOING, localPlayerID, playerID)
        local possibleAgreementsTo = DealManager.GetPossibleDealItems(localPlayerID, playerID, DealItemTypes.AGREEMENTS,
                                                                      pForDealTo)
        if (possibleAgreementsTo ~= nil) then
          for i, entry in ipairs(possibleAgreementsTo) do
            if entry.SubTypeName == "LOC_DIPLOACTION_OPEN_BORDERS_NAME" then
              canExport = true
            end
          end
        end
      end
      -- logic end
      table.insert(leaders, {
        Icon = pData.leaderIcon,
        HasImport = hasImport,
        HasExport = hasExport,
        CanImport = canImport,
        CanExport = canExport,
        IsMet = pData.isMet
      })
      if canImport or canExport then
        active = true
      end
    end
  end

  borderData.Leaders = leaders
  borderData.Active = active

  return borderData
end

-- ---------------------------------------------------------------------------
function GetTradeData()
  PlayerInit()

  local tradeData = {}
  local leaders = {}
  local active = false

  if not GameCapabilities.HasCapability("CAPABILITY_TRADE") then
    return nil
  end

  local playerTrade = localPlayer:GetTrade()
  local routesActive = playerTrade:GetNumOutgoingRoutes()
  local routesCap = playerTrade:GetOutgoingRouteCapacity()
  if routesCap > 0 and routesCap > routesActive then
    active = true
  end

  local playerData = CuiGetPlayerBasicData()
  for _, pData in pairs(playerData) do
    local playerID = pData.playerID
    local player = Players[playerID]
    local visible = (not pData.isLocalPlayer) and pData.isMet
    if visible then
      local isTraded = false
      local playerCities = player:GetCities()
      for _, city in playerCities:Members() do
        if city:GetTrade():HasTradeRouteFrom(localPlayerID) then
          isTraded = true
        end
      end
      local isWar = IsAtWar(localPlayerID, playerID)
      table.insert(leaders, {Icon = pData.leaderIcon, IsTraded = isTraded, IsWar = isWar, IsMet = pData.isMet})
    end
  end

  tradeData.Routes = routesActive
  tradeData.Cap = routesCap
  tradeData.Leaders = leaders
  tradeData.Active = active

  return tradeData
end

-- ===========================================================================
-- Help Function
-- ---------------------------------------------------------------------------
function IsAtWar(lPlayerID, tPlayerID)

  local tPlayer = Players[tPlayerID]
  local lPlayerID = Game.GetLocalPlayer()
  local lPlayer = Players[lPlayerID]
  local lPlayerDiplomacy = lPlayer:GetDiplomacy()
  local iState = tPlayer:GetDiplomaticAI():GetDiplomaticStateIndex(lPlayerID)
  local iStateEntry = GameInfo.DiplomaticStates[iState]
  local eState = iStateEntry.Hash

  return eState == DiplomaticStates.WAR
end
