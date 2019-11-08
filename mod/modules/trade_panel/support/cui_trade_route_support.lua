-- ===========================================================================
-- Cui Trade Route Support Functions
-- eudaimonia, 3/22/2019
-- ===========================================================================
-- ===========================================================================
function CuiGetTradeRouteInfo(originCity, destinationCity)
    local data = {}
    local eSpeed = GameConfiguration.GetGameSpeedType()
    if GameInfo.GameSpeeds[eSpeed] == nil then eSpeed = 1 end
    local iSpeedCostMultiplier = GameInfo.GameSpeeds[eSpeed].CostMultiplier
    local tradePathLength = Map.GetPlotDistance(originCity:GetX(),
                                                originCity:GetY(),
                                                destinationCity:GetX(),
                                                destinationCity:GetY())
    local multiplierConstant = 0.1
    local tripsToDestination = 1 +
                                   math.floor(
                                       iSpeedCostMultiplier / tradePathLength *
                                           multiplierConstant)
    local turnsToCompleteRoute = (tradePathLength * 2 * tripsToDestination)
    data.length = tradePathLength
    data.trips = tripsToDestination
    data.turns = turnsToCompleteRoute
    return data
end
