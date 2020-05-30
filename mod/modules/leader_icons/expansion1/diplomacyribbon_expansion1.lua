-- Copyright 2017-2019, Firaxis Games.

-- Base File
include("DiplomacyRibbon");
include("cui_leader_icon_support") -- CUI

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
    local localPlayer = Players[Game.GetLocalPlayer()]
    if playerID == Game.GetLocalPlayer() or localPlayer:GetDiplomacy():HasMet(playerID) then
        oLeaderIcon.GameEras:SetHide(false)
        local pGameEras = Game.GetEras()
        if pGameEras:HasHeroicGoldenAge(playerID) then
            oLeaderIcon.GameEras:SetText("[ICON_GLORY_SUPER_GOLDEN_AGE]")
        elseif pGameEras:HasGoldenAge(playerID) then
            oLeaderIcon.GameEras:SetText("[ICON_GLORY_GOLDEN_AGE]")
        elseif pGameEras:HasDarkAge(playerID) then
            oLeaderIcon.GameEras:SetText("[ICON_GLORY_DARK_AGE]")
        else
            oLeaderIcon.GameEras:SetText("[ICON_GLORY_NORMAL_AGE]")
        end
    end
    local allianceData = CuiGetAllianceData(playerID)
    LuaEvents.CuiLeaderIconToolTip(oLeaderIcon.Portrait, playerID)
    LuaEvents.CuiRelationshipToolTip(oLeaderIcon.Relationship, playerID, allianceData)
    --
end