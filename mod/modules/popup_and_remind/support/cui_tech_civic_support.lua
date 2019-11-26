-- ---------------------------------------------------------------------------
function CuiIsFutureTechAndGet(eTech)
  for tech in GameInfo.Technologies() do
    if tech.Index == eTech and tech.TechnologyType == "TECH_FUTURE_TECH" and tech.Repeatable then
      return tech
    end
  end
  return nil
end

-- ---------------------------------------------------------------------------
function CuiIsFutureCivicAndGet(eCivic)
  for civic in GameInfo.Civics() do
    if civic.Index == eCivic and civic.CivicType == "CIVIC_FUTURE_CIVIC" and civic.Repeatable then
      return civic
    end
  end
  return nil
end

-- ---------------------------------------------------------------------------
function CuiIsTechReady(playerID)
  local player = Players[playerID]
  local playerTechs = player:GetTechs()
  local iTech = playerTechs:GetResearchingTech()
  local kTech = (iTech ~= -1) and GameInfo.Technologies[iTech] or nil
  local eTech = GetResearchData(playerID, playerTechs, kTech)

  if eTech and eTech.TechType then
    local boostAmount = eTech.Progress + eTech.BoostAmount
    return eTech.Boostable and (not eTech.BoostTriggered) and (boostAmount >= 1)
  end

  return false
end

-- ---------------------------------------------------------------------------
function CuiIsCivicReady(playerID)
  local player = Players[playerID]
  local playerCulture = player:GetCulture()
  local iCivic = playerCulture:GetProgressingCivic()
  local kCivic = (iCivic ~= -1) and GameInfo.Civics[iCivic] or nil
  local eCiciv = GetCivicData(playerID, playerCulture, kCivic)

  if eCiciv and eCiciv.CivicType then
    local boostAmount = eCiciv.Progress + eCiciv.BoostAmount
    return eCiciv.Boostable and (not eCiciv.BoostTriggered) and (boostAmount >= 1)
  end

  return false
end

-- ---------------------------------------------------------------------------
function GetResearchData(localPlayer, pPlayerTechs, kTech)

  if kTech == nil then -- Immediate return if there is no tech to inspect; likely first turn.
    return nil
  end

  local iTech = kTech.Index
  local isBoostable = false
  local boostAmount = 0
  local isRepeatable = kTech.Repeatable
  local researchCost = pPlayerTechs:GetResearchCost(iTech)
  local techType = kTech.TechnologyType
  local triggerDesc = ""

  for row in GameInfo.Boosts() do
    if row.TechnologyType == techType then
      isBoostable = true
      boostAmount = (row.Boost * .01) * researchCost -- Convert the boost value to decimal and determine the actual boost amount.
      triggerDesc = row.TriggerDescription
      break
    end
  end

  local kData = {
    ID = iTech,
    Boostable = isBoostable,
    BoostAmount = boostAmount / researchCost,
    BoostTriggered = pPlayerTechs:HasBoostBeenTriggered(iTech),
    Hash = kTech.Hash,
    Name = Locale.Lookup(kTech.Name),
    IsCurrent = false, -- caller needs to update upon return
    IsLastCompleted = false, -- caller needs to update upon return
    Repeatable = isRepeatable,
    ResearchCost = researchCost,
    Progress = pPlayerTechs:GetResearchProgress(iTech) / researchCost,
    TechType = techType,
    TriggerDesc = triggerDesc,
    TurnsLeft = pPlayerTechs:GetTurnsToResearch(iTech)
  }

  return kData
end

-- ---------------------------------------------------------------------------
function GetCivicData(localPlayer, pPlayerCulture, kCivic)

  if kCivic == nil then -- Immediate return if there is no tech to inspect; likely first turn.
    return nil
  end

  local iCivic = kCivic.Index
  local isBoostable = false
  local boostAmount = 0
  local isRepeatable = kCivic.Repeatable
  local progressCost = pPlayerCulture:GetCultureCost(iCivic)
  local civicType = kCivic.CivicType
  local triggerDesc = ""

  for row in GameInfo.Boosts() do
    if row.CivicType == civicType then
      isBoostable = true
      boostAmount = (row.Boost * .01) * progressCost -- Convert the boost value to decimal and determine the actual boost amount.
      triggerDesc = row.TriggerDescription
      break
    end
  end

  local kData = {
    ID = iCivic,
    Boostable = isBoostable,
    BoostAmount = boostAmount / progressCost,
    BoostTriggered = pPlayerCulture:HasBoostBeenTriggered(iCivic),
    Cost = progressCost,
    Hash = kCivic.Hash,
    Name = Locale.Lookup(kCivic.Name),
    IsCurrent = false, -- caller needs to update upon return
    IsLastCompleted = false, -- caller needs to update upon return
    Repeatable = isRepeatable,
    Progress = (pPlayerCulture:GetCulturalProgress(iCivic) / progressCost),
    CivicType = civicType,
    TriggerDesc = triggerDesc,
    TurnsLeft = pPlayerCulture:GetTurnsToProgressCivic(iCivic)
  }

  return kData
end

-- ---------------------------------------------------------------------------
function CuiIsGovernmentReady(playerID)
  local player = Players[playerID]
  local pCulture = player:GetCulture()
  if pCulture:GetNumPoliciesUnlocked() <= 0 then
    return false
  elseif pCulture:IsInAnarchy() then
    return false
  else
    return pCulture:GetCostToUnlockPolicies() == 0 and pCulture:PolicyChangeMade() == false
  end
end

-- ---------------------------------------------------------------------------
function CuiIsGovernorReady(playerID)
  local player = Players[playerID]
  local governors = player:GetGovernors()
  local bCanAppoint = governors:CanAppoint()
  local bCanPromote = governors:CanPromote()

  return bCanAppoint or bCanPromote
end

