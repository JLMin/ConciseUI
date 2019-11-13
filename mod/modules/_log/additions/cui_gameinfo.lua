include("cui_helper")

-- ---------------------------------------------------------------------------
local RiseAndFall = "1B28771A-C749-434B-9053-D1380C553DE9"
local GatheringStorm = "4873eb62-8ccc-4574-b784-dda455e74e68"
local Tutorial = "17462E0F-1EE1-4819-AAAA-052B5896B02A"
local CuiGameInfo = {}

-- ---------------------------------------------------------------------------
local function GenerateModName(mod)
  local modInfo = Modding.GetModInfo(mod.Handle)
  local subID = modInfo.SubscriptionId
  local modName = ""

  if subID then
    modName = Modding.GetSubscriptionDetails(subID).Name
  else
    modName = Locale.Lookup(mod.Name)
    modName = Locale.StripTags(modName)
  end
  return modName
end

-- ---------------------------------------------------------------------------
local function GenerateModInfo(mod)
  local modInfo = {
    Id = mod.Id,
    Name = GenerateModName(mod),
    Active = false,
    Enabled = mod.Enabled,
    Official = mod.Official,
    SubID = mod.SubscriptionId,
    Update = "",
    Compatible = Modding.IsModCompatible(mod.Handle)
  }
  if not mod.Official and mod.SubscriptionId then
    local details = Modding.GetSubscriptionDetails(mod.SubscriptionId)
    if details and details.LastUpdated then modInfo.Update = Locale.Lookup("LOC_MODS_LAST_UPDATED", details.LastUpdated) end
  end
  return modInfo
end

-- ---------------------------------------------------------------------------
local function LoadGameInfo()
  CuiGameInfo.IsMultiplayer = GameConfiguration.IsAnyMultiplayer()
  CuiGameInfo.IsHotseat = GameConfiguration.IsHotseat()
  CuiGameInfo.MapSeed = MapConfiguration.GetValue("RANDOM_SEED")
  CuiGameInfo.GameSeed = GameConfiguration.GetValue("GAME_SYNC_RANDOM_SEED")
  CuiGameInfo.GameSpeed = Locale.Lookup(GameInfo.GameSpeeds[GameConfiguration.GetGameSpeedType()].Name)
  CuiGameInfo.RuleSet = GameConfiguration.GetRuleSet()
end

-- ---------------------------------------------------------------------------
local function LoadInstalledMods()
  local mods = Modding.GetInstalledMods()
  for _, mod in ipairs(mods) do
    if mod.Id ~= Tutorial and mod.Source == "Mod" then
      CuiGameInfo.InstalledAll = CuiGameInfo.InstalledAll + 1
      if mod.Official then
        CuiGameInfo.InstalledOff = CuiGameInfo.InstalledOff + 1
      else
        CuiGameInfo.InstalledCom = CuiGameInfo.InstalledCom + 1
      end
      if isNil(CuiGameInfo.Mods[mod.Id]) then CuiGameInfo.Mods[mod.Id] = {} end
      local modInfo = GenerateModInfo(mod)
      CuiGameInfo.Mods[mod.Id] = modInfo
    end
  end
end

-- ---------------------------------------------------------------------------
local function LoadActiveMods()
  local mods = Modding.GetActiveMods()
  for _, mod in ipairs(mods) do
    if mod.Id == Tutorial then CuiGameInfo.IsTutorial = mod.Enabled end
    if mod.Id == RiseAndFall then CuiGameInfo.IsRiseAndFall = mod.Enabled end
    if mod.Id == GatheringStorm then CuiGameInfo.IsGatheringStorm = mod.Enabled end
    if mod.Id ~= Tutorial and mod.Source == "Mod" then
      CuiGameInfo.ActiveAll = CuiGameInfo.ActiveAll + 1
      if mod.Official then
        CuiGameInfo.ActiveOff = CuiGameInfo.ActiveOff + 1
      else
        CuiGameInfo.ActiveCom = CuiGameInfo.ActiveCom + 1
      end
      if isNil(CuiGameInfo.Mods[mod.Id]) then
        print("[Error] unexpected mod:", mod.Name, "ID:", mod.Id)
      else
        CuiGameInfo.Mods[mod.Id].Active = true
      end
    end
  end
end

-- ---------------------------------------------------------------------------
local function SortMods(usMods)
  if isNil(usMods) then return nil end

  local mods = {}
  for _, mod in pairs(usMods) do table.insert(mods, mod) end

  table.sort(mods, function(a, b)
    local sortOverrides = {["4873eb62-8ccc-4574-b784-dda455e74e68"] = -2, ["1B28771A-C749-434B-9053-D1380C553DE9"] = -1}

    local aSort = sortOverrides[a.Id] or 0
    local bSort = sortOverrides[b.Id] or 0
    if aSort ~= bSort then return aSort < bSort end

    if a.Official ~= b.Official then return a.Official end

    return Locale.Compare(a.Name, b.Name) == -1
  end)

  return mods
end

-- ---------------------------------------------------------------------------
function GetCuiGameInfo()
  CuiGameInfo = {
    -- game
    IsRiseAndFall = false,
    IsGatheringStorm = false,
    IsTutorial = false,
    IsMultiplayer = false,
    IsHotseat = false,
    MapSeed = nil,
    GameSeed = nil,
    GameSpeed = -1,
    RuleSet = nil,
    -- mods
    InstalledAll = 0,
    InstalledOff = 0,
    InstalledCom = 0,
    ActiveAll = 0,
    ActiveOff = 0,
    ActiveCom = 0,
    Mods = {}
  }

  LoadGameInfo()
  LoadInstalledMods()
  LoadActiveMods()
  local mods = CuiGameInfo.Mods
  local sortedMods = SortMods(mods)
  CuiGameInfo.Mods = sortedMods

  return CuiGameInfo
end
