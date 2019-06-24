-- ===========================================================================
-- Cui Trade Route Support Functions
-- eudaimonia, 3/22/2019
-- ===========================================================================

-- ===========================================================================
function CuiGetTradeRouteInfo(originCity, destinationCity)
  local data:table = {};
  local eSpeed:number = GameConfiguration.GetGameSpeedType();
  if GameInfo.GameSpeeds[eSpeed] == nil then eSpeed = 1; end
  local iSpeedCostMultiplier = GameInfo.GameSpeeds[eSpeed].CostMultiplier;
  local tradePathLength:number = Map.GetPlotDistance(originCity:GetX(), originCity:GetY(), destinationCity:GetX(), destinationCity:GetY());
  local multiplierConstant:number = 0.1;
  local tripsToDestination = 1 + math.floor(iSpeedCostMultiplier/tradePathLength * multiplierConstant);
  local turnsToCompleteRoute = (tradePathLength * 2 * tripsToDestination);
  data.length = tradePathLength;
  data.trips  = tripsToDestination;
  data.turns  = turnsToCompleteRoute;
  return data;
end
