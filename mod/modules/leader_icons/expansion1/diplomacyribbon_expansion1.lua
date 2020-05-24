-- Copyright 2017-2019, Firaxis Games.

-- Base File
include("DiplomacyRibbon");
include("cuileadericonsupport") -- CUI

-- ===========================================================================
-- Cached Base Functions
-- ===========================================================================
BASE_AddLeader = AddLeader;

-- ===========================================================================
function AddLeader(iconName : string, playerID : number, kProps: table)
	local oLeaderIcon	:object = BASE_AddLeader(iconName, playerID, kProps);
	local localPlayerID	:number = Game.GetLocalPlayer();

	if localPlayerID == PlayerTypes.NONE or localPlayerID == PlayerTypes.OBSERVER then
		return;
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