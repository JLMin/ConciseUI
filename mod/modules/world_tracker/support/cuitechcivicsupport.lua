-- ===========================================================================
function CuiIsFutureTechAndGet(eTech)
    for tech in GameInfo.Technologies() do
        if tech.Index == eTech and tech.TechnologyType == "TECH_FUTURE_TECH" and
            tech.Repeatable then return tech end
    end
    return nil
end

-- ===========================================================================
function CuiIsFutureCivicAndGet(eCivic)
    for civic in GameInfo.Civics() do
        if civic.Index == eCivic and civic.CivicType == "CIVIC_FUTURE_CIVIC" and
            civic.Repeatable then return civic end
    end
    return nil
end
