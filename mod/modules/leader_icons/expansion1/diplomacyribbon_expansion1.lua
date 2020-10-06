-- Copyright 2017-2019, Firaxis Games.

-- Base File
include("DiplomacyRibbon");
include("cui_leader_icon_support"); -- CUI

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

    -- CUI >>
    local localPlayer = Players[Game.GetLocalPlayer()];
    if playerID == Game.GetLocalPlayer() or localPlayer:GetDiplomacy():HasMet(playerID) then
        oLeaderIcon.GameEras:SetHide(false);
        local pGameEras = Game.GetEras();
        if pGameEras:HasHeroicGoldenAge(playerID) then
            oLeaderIcon.GameEras:SetText("[ICON_GLORY_SUPER_GOLDEN_AGE]");
        elseif pGameEras:HasGoldenAge(playerID) then
            oLeaderIcon.GameEras:SetText("[ICON_GLORY_GOLDEN_AGE]");
        elseif pGameEras:HasDarkAge(playerID) then
            oLeaderIcon.GameEras:SetText("[ICON_GLORY_DARK_AGE]");
        else
            oLeaderIcon.GameEras:SetText("[ICON_GLORY_NORMAL_AGE]");
        end
    end
    local allianceData = CuiGetAllianceData(playerID);
    LuaEvents.CuiLeaderIconToolTip(oLeaderIcon.Portrait, playerID);
    LuaEvents.CuiRelationshipToolTip(oLeaderIcon.Relationship, playerID, allianceData);
    -- << CUI

    --[[
	if GameCapabilities.HasCapability("CAPABILITY_DISPLAY_HUD_RIBBON_RELATIONSHIPS") then
		-- Update relationship pip tool with details about our alliance if we're in one
		local localPlayerDiplomacy:table = Players[localPlayerID]:GetDiplomacy();
		if localPlayerDiplomacy then
			local allianceType = localPlayerDiplomacy:GetAllianceType(playerID);
			if allianceType ~= -1 then
				local allianceName = Locale.Lookup(GameInfo.Alliances[allianceType].Name);
				local allianceLevel = localPlayerDiplomacy:GetAllianceLevel(playerID);
				oLeaderIcon.Controls.Relationship:SetToolTipString(Locale.Lookup("LOC_DIPLOMACY_ALLIANCE_FLAG_TT", allianceName, allianceLevel));
			end
		end
	end

    return oLeaderIcon;
    ]]
end
