--[[
-- Created by Keaton VanAuken, Oct 13 2017
-- Copyright (c) Firaxis Games
--]] -- ===========================================================================
-- Base File
-- ===========================================================================
include("EspionageChooser")

-- ===========================================================================
-- CACHE BASE FUNCTIONS
-- ===========================================================================
BASE_CuiCivCheck = CuiCivCheck

-- ===========================================================================
-- Refresh the destination list with all revealed non-city state owned cities
-- ===========================================================================
function CuiCivCheck(player)
    local localPlayer = Players[Game.GetLocalPlayer()]
    if (player:GetID() == localPlayer:GetID() or player:GetTeam() == -1 or
        localPlayer:GetTeam() == -1 or player:GetTeam() ~= localPlayer:GetTeam()) then
        if (not player:IsFreeCities()) then return true end
    end
    return false
end
