-- ===========================================================================
-- cui_log.lua
-- ===========================================================================

include("cui_utils")
include("cui_gameinfo")

-- CUI -----------------------------------------------------------------------
local ShowModsList = true
local ShowActiveOnly = true
local ShowOfficial = false

-- CUI -----------------------------------------------------------------------
LogC = {}
LogC.__index = LogC

-- CUI -----------------------------------------------------------------------
function LogC:createLog(sL, cL)
    o = o or {}
    setmetatable(o, self)
    self.sL = sL or 50
    self.cL = cL or 72
    return o
end

-- CUI -----------------------------------------------------------------------
function LogC:line(l)
    if l == "=" or l == "-" then
        print(string.rep(l, self.cL))
    elseif isNil(l) then
        print("")
    else
        print(l)
    end
end

-- CUI -----------------------------------------------------------------------
function LogC:property(p, v)
    if isNil(v) then
        v = "."
    end
    local pL = string.len(p)
    local mL = self.sL - pL
    local m = string.rep(".", mL)
    local line = p .. " " .. m .. " [ " .. tostring(v) .. " ]"
    print(line)
end

-- CUI -----------------------------------------------------------------------
function LogC:value3(p, v1, v2, v3)
    local s1, s2, s3 = string.len(v1), string.len(v2), string.len(v3)
    local vL = math.max(s1, s2, s3)
    local t1 = "T:" .. string.rep(" ", vL - s1) .. v1
    local t2 = "O:" .. string.rep(" ", vL - s2) .. v2
    local t3 = "C:" .. string.rep(" ", vL - s3) .. v3
    local v = t1 .. " " .. t2 .. " " .. t3
    LogC:property(p, v)
end

-- CUI -----------------------------------------------------------------------
function LogC:mod(mod)
    if ShowActiveOnly and not mod.Active then
        return
    end
    if mod.Official and not ShowOfficial then
        return
    end

    --[[
    Id         = mod.Id,
    Name       = GenerateModName(mod),
    Active     = false,
    Enabled    = mod.Enabled,
    Official   = mod.Official,
    SubID      = mod.SubscriptionId,
    Update     = "";
    Compatible = Modding.IsModCompatible(mod.Handle)
    ]]
    -- title
    local mType = mod.Official and "[O]" or "[C]"
    local title = ""
    if ShowOfficial then
        title = mType .. " " .. mod.Name
    else
        title = mod.Name
    end
    LogC:line(title)
    -- update
    if not isNil(mod.Update) then
        LogC:line("[" .. mod.Update .. "]")
    end
    -- link
    if not mod.Official then
        if mod.SubID then
            print("https://steamcommunity.com/sharedfiles/filedetails/?id=" .. mod.SubID)
        else
            print("This is not a Steam Workshop Mod.")
        end
    end
    -- properties
    LogC:property("Enabled", mod.Enabled)
    if not ShowActiveOnly then
        LogC:property("Active", mod.Active)
    end
    if not mod.Official then
        LogC:property("Compatible", mod.Compatible)
    end
    LogC:line()
end

-- CUI -----------------------------------------------------------------------
function LogGameInfo()
    local CuiGameInfo = GetCuiGameInfo()
    local Log = LogC:createLog()

    Log:line()
    Log:line("=")
    Log:line()
    Log:line("Game Information:")
    Log:line("Version: " .. CuiGameInfo.Version)
    Log:line("-")

    Log:property("Rise and Fall",   CuiGameInfo.IsRiseAndFall)
    Log:property("Gathering Storm", CuiGameInfo.IsGatheringStorm)
    Log:property("Tutorial",        CuiGameInfo.IsTutorial)
    Log:property("Multiplayer",     CuiGameInfo.IsMultiplayer)
    Log:property("Hotseat",         CuiGameInfo.IsHotseat)
    Log:property("Map Seed",        CuiGameInfo.MapSeed)
    Log:property("Game Seed",       CuiGameInfo.GameSeed)
    Log:property("Game Speed",      CuiGameInfo.GameSpeed)
    -- Log:property("Rule Set",        CuiGameInfo.RuleSet)
    local i1, i2, i3 = CuiGameInfo.InstalledAll, CuiGameInfo.InstalledOff, CuiGameInfo.InstalledCom
    Log:value3("Mods Installed", i1, i2, i3)
    local a1, a2, a3 = CuiGameInfo.ActiveAll, CuiGameInfo.ActiveOff, CuiGameInfo.ActiveCom
    Log:value3("Mods Active", a1, a2, a3)

    if ShowModsList then
        local mods = CuiGameInfo.Mods
        if isNil(mods) then
            return
        end

        Log:line()
        Log:line("Mods List:")
        Log:property("Active Mods Only", ShowActiveOnly)
        Log:property("Show Official Content", ShowOfficial)
        Log:line("-")
        for _, mod in ipairs(mods) do
            Log:mod(mod)
        end
    else
        Log:line()
    end

    Log:line("=")
    Log:line()
end

-- CUI -----------------------------------------------------------------------
function Initialize()
    Events.LoadGameViewStateDone.Add(LogGameInfo)
end
Initialize()
