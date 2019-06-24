-- Copyright 2017-2018, Firaxis Games.

-- Base File
include("DiplomacyRibbon");
include("cuileadericonsupport"); -- CUI

-- ===========================================================================
-- Cached Base Functions
-- ===========================================================================
BASE_AddLeader = AddLeader;

-- ===========================================================================
function AddLeader(iconName : string, playerID : number, kProps: table)
  local leaderIcon, instance = BASE_AddLeader(iconName, playerID, kProps);
  local localPlayer:table = Players[Game.GetLocalPlayer()];

  -- CUI
  if playerID == Game.GetLocalPlayer() or localPlayer:GetDiplomacy():HasMet(playerID) then
    instance.GameEras:SetHide(false);
    local pGameEras:table = Game.GetEras();
    if pGameEras:HasHeroicGoldenAge(playerID) then
      instance.GameEras:SetText("[ICON_GLORY_SUPER_GOLDEN_AGE]");
    elseif pGameEras:HasGoldenAge(playerID) then
      instance.GameEras:SetText("[ICON_GLORY_GOLDEN_AGE]");
    elseif pGameEras:HasDarkAge(playerID) then
      instance.GameEras:SetText("[ICON_GLORY_DARK_AGE]");
    else
      instance.GameEras:SetText("[ICON_GLORY_NORMAL_AGE]");
    end
  end
  local allianceData:table = CuiGetAllianceData(playerID);
  LuaEvents.CuiLeaderIconToolTip(instance.Portrait, playerID);
  LuaEvents.CuiRelationshipToolTip(instance.Relationship, playerID, allianceData);
  --
end