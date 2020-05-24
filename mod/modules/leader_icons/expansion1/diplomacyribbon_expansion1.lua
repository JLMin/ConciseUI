-- Copyright 2017-2018, Firaxis Games.

-- Base File
include("DiplomacyRibbon")
include("cuileadericonsupport") -- CUI

-- ===========================================================================
-- Cached Base Functions
-- ===========================================================================
BASE_AddLeader = AddLeader

-- ===========================================================================
function AddLeader(iconName, playerID, kProps)
    local leaderIcon, instance = BASE_AddLeader(iconName, playerID, kProps)
    local localPlayer = Players[Game.GetLocalPlayer()]

    if localPlayerID == -1 or localPlayerID == 1000 then
        return
    end

    -- CUI
    if playerID == Game.GetLocalPlayer() or localPlayer:GetDiplomacy():HasMet(playerID) then
        instance.GameEras:SetHide(false)
        local pGameEras = Game.GetEras()
        if pGameEras:HasHeroicGoldenAge(playerID) then
            instance.GameEras:SetText("[ICON_GLORY_SUPER_GOLDEN_AGE]")
        elseif pGameEras:HasGoldenAge(playerID) then
            instance.GameEras:SetText("[ICON_GLORY_GOLDEN_AGE]")
        elseif pGameEras:HasDarkAge(playerID) then
            instance.GameEras:SetText("[ICON_GLORY_DARK_AGE]")
        else
            instance.GameEras:SetText("[ICON_GLORY_NORMAL_AGE]")
        end
    end
    local allianceData = CuiGetAllianceData(playerID)
    LuaEvents.CuiLeaderIconToolTip(instance.Portrait, playerID)
    LuaEvents.CuiRelationshipToolTip(instance.Relationship, playerID, allianceData)
    --
end
