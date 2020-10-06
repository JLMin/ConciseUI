-- ===========================================================================
-- Concise UI
-- cui_settings.lua
-- ===========================================================================

local SETTING_PREFIX = "CUI_SETTING_"

-- Concise UI ----------------------------------------------------------------
CuiSettings = {
    -- map options
    SHOW_IMPROVES     = {field = "ShowImproveS",      default = false},
    SHOW_UNITS        = {field = "ShowUnits",         default = true},
    SHOW_TRADERS      = {field = "ShowTraders",       default = true},
    SHOW_RELIGIONS    = {field = "ShowReligions",     default = true},
    SHOW_CITYS        = {field = "ShowCitys",         default = true},
    -- map pins
    SHOW_DISTRICTS    = {field = "ShowDistricts",     default = true},
    SHOW_WONDERS      = {field = "ShowWonders",       default = false},
    AUTO_NAMING       = {field = "AutoNaming",        default = true},
    -- world tracker
    WT_GOSSIP_LOG     = {field = "TrackerGossipLog",  default = false},
    WT_COMBAT_LOG     = {field = "TrackerCombatLog",  default = false},
    DF_GOSSIP_LOG     = {field = "DefaultGossipLog",  default = false},
    DF_COMBAT_LOG     = {field = "DefaultCombatLog",  default = false},
    GOSSIP_LOG_STATE  = {field = "GossipLogState",    default = 1},
    COMBAT_LOG_STATE  = {field = "CombatLogState",    default = 1},
    -- production panel
    QUEUE_BY_DEFAULT  = {field = "QueueByDefault",    default = false},
    -- great works
    SORT_BY_CITY      = {field = "SortByCity",        default = true},
    -- civ victory tracking
    SCIENCE           = {field = "ScienceVictory",    default = false},
    CULTURE           = {field = "CultureVictory",    default = false},
    DOMINATION        = {field = "DominationVictory", default = false},
    RELIGION          = {field = "ReligionVictory",   default = false},
    DIPLOMATIC        = {field = "DiplomaticVictory", default = false},
    -- popup manager
    POPUP_RESEARCH    = {field = "PopupResearch",     default = true},
    AUDIO_RESEARCH    = {field = "PlayResearchAudio", default = true},
    POPUP_HISTORIC    = {field = "PopupHistoric",     default = false},
    POPUP_CREATWORK   = {field = "PopupGreatWork",    default = false},
    POPUP_RELIC       = {field = "PopupRelic",        default = true},
    -- remind
    REMIND_TECH       = {field = "RemindTech",        default = true},
    REMIND_CIVIC      = {field = "RemindCivic",       default = true},
    REMIND_GOVERNMENT = {field = "RemindGovernment",  default = true},
    REMIND_GOVERNOR   = {field = "RemindGovernor",    default = true},
    -- quick combat & movement
    PLAYER_COMBAT     = {field = "PlayerCombat",      default = true},
    PLAYER_MOVEMENT   = {field = "PlayerMovement",    default = true},
    AI_COMBAT         = {field = "AICombat",          default = true},
    AI_MOVEMENT       = {field = "AIMovement",        default = true}
}
CuiSettings.__index = CuiSettings

-- Concise UI ----------------------------------------------------------------
local function CuiCompleteKey(field)
    return SETTING_PREFIX .. tostring(field)
end

-- Concise UI ----------------------------------------------------------------
function CuiSettings:SetBoolean(k, b)
    local key = CuiCompleteKey(k.field)
    local value = b and "true" or "false"
    PlayerConfigurations[Game.GetLocalPlayer()]:SetValue(key, value)
end

-- Concise UI ----------------------------------------------------------------
function CuiSettings:GetBoolean(k)
    local key = CuiCompleteKey(k.field)
    local value = PlayerConfigurations[Game.GetLocalPlayer()]:GetValue(key)
    if value ~= nil then
        return value == "true"
    else
        return k.default
    end
end

-- Concise UI ----------------------------------------------------------------
function CuiSettings:ReverseAndGetBoolean(k)
    local v = CuiSettings:GetBoolean(k)
    local value = v == false
    CuiSettings:SetBoolean(k, value)
    return value
end

-- Concise UI ----------------------------------------------------------------
function CuiSettings:SetNumber(k, v)
    local key = CuiCompleteKey(k.field)
    local value = v
    PlayerConfigurations[Game.GetLocalPlayer()]:SetValue(key, value)
end

-- Concise UI ----------------------------------------------------------------
function CuiSettings:GetNumber(k)
    local key = CuiCompleteKey(k.field)
    local value = PlayerConfigurations[Game.GetLocalPlayer()]:GetValue(key)
    if value ~= nil then
        return value
    else
        return k.default
    end
end

-- Concise UI ----------------------------------------------------------------
function CuiSettings:SetString(k, s)
    local key = CuiCompleteKey(k.field)
    local value = tostring(s)
    PlayerConfigurations[Game.GetLocalPlayer()]:SetValue(key, value)
end

-- Concise UI ----------------------------------------------------------------
function CuiSettings:GetString(k)
    local key = CuiCompleteKey(k.field)
    local value = PlayerConfigurations[Game.GetLocalPlayer()]:GetValue(key)
    if value ~= nil then
        return value
    else
        return k.default
    end
end
