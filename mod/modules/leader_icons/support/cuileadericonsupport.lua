-- ===========================================================================
-- Cui Leader Icon Support Functions
-- eudaimonia, 3/22/2019
-- ===========================================================================
include("cui_helper")

function CuiGetAllianceData(otherPlayerID)
    local localPlayer = Players[Game.GetLocalPlayer()]
    local localPlayerDiplomacy = localPlayer:GetDiplomacy()
    local allianceData = {}

    allianceData.isAlliance = false
    allianceData.tooltip = ""
    allianceData.remainingTurns = 0

    if (isExpansion1 or isExpansion2) and localPlayerDiplomacy then
        local allianceType = localPlayerDiplomacy:GetAllianceType(otherPlayerID)
        if allianceType ~= -1 then
            local allianceName = Locale.Lookup(GameInfo.Alliances[allianceType].Name)
            local allianceLevel = localPlayerDiplomacy:GetAllianceLevel(otherPlayerID)
            allianceData.isAlliance = true
            allianceData.tooltip = Locale.Lookup("LOC_DIPLOMACY_ALLIANCE_FLAG_TT", allianceName, allianceLevel)
            allianceData.remainingTurns = localPlayerDiplomacy:GetAllianceTurnsUntilExpiration(otherPlayerID)
        end
    end

    return allianceData
end
