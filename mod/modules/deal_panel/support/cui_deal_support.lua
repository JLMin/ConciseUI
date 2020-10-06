-- ===========================================================================
-- cui_deal_support.lua
-- ===========================================================================

include("cui_utils")

-- ===========================================================================
-- Tooltips
-- ===========================================================================

-- CUI -----------------------------------------------------------------------
local CuiRedColor = "ModStatusRedCS"
local CuiYellowColor = "ModStatusYellowCS"
local CuiGreenColor = "ModStatusGreenCS"

-- luxury tooltip
local WeHaveTT = "[NEWLINE]" .. Locale.Lookup("LOC_CUI_DP_WE_HAVE_ITEM_TOOLTIP")
local BlockedTT = "[NEWLINE]" .. Locale.Lookup("LOC_DIPLO_DEAL_UNACCEPTABLE_ITEM_TOOLTIP")
local TheyHaveTT = "[NEWLINE]" .. Locale.Lookup("LOC_CUI_DP_THEY_HAVE_ITEM_TOOLTIP")
local OnlyOneTT = "[NEWLINE]" .. Locale.Lookup("LOC_CUI_DP_WE_HAVE_ONLY_ONE_TOOLTIP")

-- strategic tooltip
local PlayerNoCapTT = Locale.Lookup("LOC_DEAL_PLAYER_HAS_NO_CAP_ROOM")
local AINoCapTT = Locale.Lookup("LOC_DEAL_AI_HAS_NO_CAP_ROOM")

-- ===========================================================================
-- Vanilla & Expansion 1
-- ===========================================================================

-- CUI -----------------------------------------------------------------------
function CuiGetResourceData(player, localPlayer, otherPlayer, entry)
    local data = {}

    -- other inventory
    local weHave = false
    local blocked = false
    -- local inventory
    local theyHave = false
    local onlyOne = false

    local resourceType = entry.ForType
    local resource = GameInfo.Resources[resourceType]
    local localResources = Players[localPlayer:GetID()]:GetResources()
    local otherResources = Players[otherPlayer:GetID()]:GetResources()

    if
        resource and resource.ResourceClassType == "RESOURCECLASS_LUXURY" or
            resource.ResourceClassType == "RESOURCECLASS_STRATEGIC"
     then
        -- their inventory
        if player == otherPlayer then
            -- if we alredy have
            weHave = localResources:HasResource(resource.Index)
            -- blocked deal, for AI only
            blocked = entry.MaxAmount == 1 and not Players[otherPlayer:GetID()]:IsHuman()
        end

        -- our inventory
        if player == localPlayer then
            -- if they already have
            theyHave = otherResources:HasResource(resource.Index)
            -- if we have only one copy of this resource
            if resource.ResourceClassType == "RESOURCECLASS_LUXURY" then
                onlyOne = localResources:GetResourceAmount(resource.Index) == 1
            end
        end
    end

    data.WeHave = weHave
    data.Blocked = blocked
    data.TheyHave = theyHave
    data.OnlyOne = onlyOne

    return data
end

-- ===========================================================================
-- Expansion 2
-- ===========================================================================

-- CUI -----------------------------------------------------------------------
function CuiGetLuxuryData(player, localPlayer, otherPlayer, entry)
    local data = {}

    -- other inventory
    local weHave = false
    local blocked = false
    -- local inventory
    local theyHave = false
    local onlyOne = false

    local resourceType = entry.ForType
    local resource = GameInfo.Resources[resourceType]
    local localResources = Players[localPlayer:GetID()]:GetResources()
    local otherResources = Players[otherPlayer:GetID()]:GetResources()

    -- luxury only
    if resource and resource.ResourceClassType == "RESOURCECLASS_LUXURY" then
        -- their inventory
        if player == otherPlayer then
            -- if we alredy have
            weHave = localResources:HasResource(resource.Index)
            -- blocked deal, for AI only
            blocked = entry.MaxAmount == 1 and not Players[otherPlayer:GetID()]:IsHuman()
        end

        -- our inventory
        if player == localPlayer then
            -- if they already have
            theyHave = otherResources:HasResource(resource.Index)
            -- if we have only one copy of this resource
            onlyOne = localResources:GetResourceAmount(resource.Index) == 1
        end
    end

    data.WeHave = weHave
    data.Blocked = blocked
    data.TheyHave = theyHave
    data.OnlyOne = onlyOne

    return data
end

-- CUI -----------------------------------------------------------------------
function CuiGetStrategicData(player, localPlayer, entry)
    local data = {}
    data.IsLocal = player == localPlayer
    data.IsValid = entry.IsValid
    return data
end

-- ===========================================================================
-- UI Functions
-- ===========================================================================

-- CUI -----------------------------------------------------------------------
function CuiGetButtonStyleByData(data)
    local color = CuiRedColor
    local tooltip = ""

    if data.WeHave or data.Blocked or data.TheyHave then
        color = CuiRedColor
    elseif data.OnlyOne then
        color = CuiYellowColor
    else
        color = CuiGreenColor
    end

    if data.WeHave then
        tooltip = tooltip .. WeHaveTT
    end
    if data.Blocked then
        tooltip = tooltip .. BlockedTT
    end
    if data.TheyHave then
        tooltip = tooltip .. TheyHaveTT
    end
    if data.OnlyOne then
        tooltip = tooltip .. OnlyOneTT
    end

    if not isNil(tooltip) then
        tooltip = "[COLOR_Red]" .. tooltip .. "[ENDCOLOR]"
    end
    return color, tooltip
end

-- CUI -----------------------------------------------------------------------
function CuiGetButtonStyleByDataXP2(data)
    local color = CuiRedColor
    local tooltip = ""

    if data.IsValid then
        color = CuiGreenColor
    else
        color = CuiRedColor
        if data.IsLocal then
            tooltip = tooltip .. AINoCapTT
        else
            tooltip = tooltip .. PlayerNoCapTT
        end
    end

    if not isNil(tooltip) then
        tooltip = "[NEWLINE][COLOR_Red]" .. tooltip .. "[ENDCOLOR]"
    end
    return color, tooltip
end
