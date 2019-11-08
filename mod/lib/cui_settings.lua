-- ===========================================================================
-- Cui Settings Help Functions
-- eudaimonia, 1/30/2019
-- ===========================================================================
local SETTING_PREFIX = "CUI_SETTING_"

CuiSettings = {
    -- map options
    SHOW_IMPROVES      = {field = "ShowImproveS",      default = true},
    SHOW_UNITS         = {field = "ShowUnits",         default = true},
    SHOW_TRADERS       = {field = "ShowTraders",       default = true},
    SHOW_RELIGIONS     = {field = "ShowReligions",     default = true},
    SHOW_CITYS         = {field = "ShowCitys",         default = true},
    -- map pins
    SHOW_DISTRICTS     = {field = "ShowDistricts",     default = true},
    SHOW_WONDERS       = {field = "ShowWonders",       default = false},
    AUTO_NAMING        = {field = "AutoNaming",        default = true},
    -- world tracker
    HIDE_GOSSIP_LOG    = {field = "HideGossipLog",     default = false},
    HIDE_COMBAT_LOG    = {field = "HideCombatLog",     default = false},
    GOSSIP_LOG_STATE   = {field = "GossipLogState",    default = 1},
    COMBAT_LOG_STATE   = {field = "CombatLogState",    default = 1},
    -- unit list
    SHOW_UNIT_DETAILS  = {field = "ShowUnitDetails",   default = true},
    -- production panel
    QUEUE_BY_DEFAULT   = {field = "QueueByDefault",    default = false},
    -- great works
    SORT_BY_CITY       = {field = "SortByCity",        default = true},
    -- civ assistant
    SCIENCE            = {field = "ScienceVictory",    default = true},
    CULTURE            = {field = "CultureVictory",    default = true},
    DOMINATION         = {field = "DominationVictory", default = false},
    RELIGION           = {field = "ReligionVictory",   default = false},
    DIPLOMATIC         = {field = "DiplomaticVictory", default = false}
}
CuiSettings.__index = CuiSettings

-- ===========================================================================
local function CuiCompleteKey(field) return SETTING_PREFIX .. tostring(field) end

-- ===========================================================================
function CuiSettings:SetBoolean(k, b)
    local key = CuiCompleteKey(k.field)
    local value = b and "true" or "false"
    PlayerConfigurations[Game.GetLocalPlayer()]:SetValue(key, value)
end

-- ===========================================================================
function CuiSettings:GetBoolean(k)
    local key = CuiCompleteKey(k.field)
    local value = PlayerConfigurations[Game.GetLocalPlayer()]:GetValue(key)
    if value ~= nil then
        return value == "true"
    else
        return k.default
    end
end

-- ===========================================================================
function CuiSettings:ReverseAndGetBoolean(k)
    local v = CuiSettings:GetBoolean(k)
    local value = v == false
    CuiSettings:SetBoolean(k, value)
    return value
end

-- ===========================================================================
function CuiSettings:SetNumber(k, v)
    local key = CuiCompleteKey(k.field)
    local value = v
    PlayerConfigurations[Game.GetLocalPlayer()]:SetValue(key, value)
end

-- ===========================================================================
function CuiSettings:GetNumber(k)
    local key = CuiCompleteKey(k.field)
    local value = PlayerConfigurations[Game.GetLocalPlayer()]:GetValue(key)
    if value ~= nil then
        return value
    else
        return k.default
    end
end

-- ===========================================================================
function CuiSettings:SetString(k, s)
    local key = CuiCompleteKey(k.field)
    local value = tostring(s)
    PlayerConfigurations[Game.GetLocalPlayer()]:SetValue(key, value)
end

-- ===========================================================================
function CuiSettings:GetString(k)
    local key = CuiCompleteKey(k.field)
    local value = PlayerConfigurations[Game.GetLocalPlayer()]:GetValue(key)
    if value ~= nil then
        return value
    else
        return k.default
    end
end
