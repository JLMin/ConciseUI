-- ===========================================================================
function GetFormattedOperationDetailText(operation, spy, city)
    local outputString = ""
    local eOperation = GameInfo.UnitOperations[operation.Hash].Index
    local sOperationDetails = UnitManager.GetOperationDetailText(eOperation, spy, Map.GetPlot(city:GetX(), city:GetY()))
    if operation.OperationType == "UNITOPERATION_SPY_GREAT_WORK_HEIST" then
        outputString = Locale.Lookup("LOC_SPYMISSIONDETAILS_UNITOPERATION_SPY_GREAT_WORK_HEIST", sOperationDetails)
    elseif operation.OperationType == "UNITOPERATION_SPY_SIPHON_FUNDS" then
        outputString = Locale.Lookup("LOC_CUI_EP_SIPHON_FUNDS", sOperationDetails) -- CUI
    elseif operation.OperationType == "UNITOPERATION_SPY_FOMENT_UNREST" then
        outputString = Locale.Lookup("LOC_SPYMISSIONDETAILS_UNITOPERATION_SPY_FOMENT_UNREST", sOperationDetails)
    elseif operation.OperationType == "UNITOPERATION_SPY_FABRICATE_SCANDAL" then
        outputString = Locale.Lookup("LOC_SPYMISSIONDETAILS_UNITOPERATION_SPY_FABRICATE_SCANDAL", sOperationDetails)
    elseif operation.OperationType == "UNITOPERATION_SPY_NEUTRALIZE_GOVERNOR" then
        outputString = Locale.Lookup("LOC_SPYMISSIONDETAILS_UNITOPERATION_SPY_NEUTRALIZE_GOVERNOR", sOperationDetails)
    elseif sOperationDetails ~= "" then
        outputString = sOperationDetails
    else
        -- Find the loc string by OperationType if this operation doesn't use GetOperationDetailText
        outputString = Locale.Lookup("LOC_SPYMISSIONDETAILS_" .. operation.OperationType)
    end

    return outputString
end

-- ===========================================================================
function RefreshMissionStats(parentControl, operation, result, spy, city, targetPlot)
    -- Update turns to completed
    local eOperation = operation.Index
    local turnsToComplete = UnitManager.GetTimeToComplete(eOperation, spy)
    parentControl.TurnsToCompleteLabel:SetText(turnsToComplete)

    -- Update mission success chance
    if operation.Hash ~= UnitOperationTypes.SPY_COUNTERSPY then
        local resultProbability = UnitManager.GetResultProbability(eOperation, spy, targetPlot)
        if resultProbability["ESPIONAGE_SUCCESS_UNDETECTED"] then
            local probability = resultProbability["ESPIONAGE_SUCCESS_UNDETECTED"]

            -- Add ESPIONAGE_SUCCESS_MUST_ESCAPE
            if resultProbability["ESPIONAGE_SUCCESS_MUST_ESCAPE"] then
                probability = probability + resultProbability["ESPIONAGE_SUCCESS_MUST_ESCAPE"]
            end

            probability = math.floor((probability * 100) + 0.5)
            parentControl.ProbabilityLabel:SetText(probability .. "%")

            -- Set Color
            if probability > 85 then
                parentControl.ProbabilityLabel:SetColorByName("OperationChance_Green")
            elseif probability > 65 then
                parentControl.ProbabilityLabel:SetColorByName("OperationChance_YellowGreen")
            elseif probability > 45 then
                parentControl.ProbabilityLabel:SetColorByName("OperationChance_Yellow")
            elseif probability > 25 then
                parentControl.ProbabilityLabel:SetColorByName("OperationChance_Orange")
            else
                parentControl.ProbabilityLabel:SetColorByName("OperationChance_Red")
            end
        end

        parentControl.ProbabilityGrid:SetHide(false)
    else
        parentControl.ProbabilityGrid:SetHide(true)
    end

    -- result is the data bundle retruned by CanStartOperation container useful information about the operation query
    -- If the results contain a plot ID then show that as the target district
    if operation.Hash == UnitOperationTypes.SPY_COUNTERSPY then
        local kDistrictInfo = GameInfo.Districts[targetPlot:GetDistrictType()]
        parentControl.MissionDistrictName:SetText(Locale.Lookup(kDistrictInfo.Name))
        local iconString = "ICON_" .. kDistrictInfo.DistrictType
        if parentControl.MissionDistrictIcon then
            parentControl.MissionDistrictIcon:SetIcon(iconString)
        end
    elseif result and result[UnitOperationResults.PLOTS] then
        for i, districtPlotID in ipairs(result[UnitOperationResults.PLOTS]) do
            local districts = city:GetDistricts()
            for i, district in districts:Members() do
                local districtPlot = Map.GetPlot(district:GetX(), district:GetY())
                if districtPlot:GetIndex() == districtPlotID then
                    local districtInfo = GameInfo.Districts[district:GetType()]
                    parentControl.MissionDistrictName:SetText(Locale.Lookup(districtInfo.Name))
                    local iconString = "ICON_" .. districtInfo.DistrictType
                    if parentControl.MissionDistrictIcon then
                        parentControl.MissionDistrictIcon:SetIcon(iconString)
                    end
                end
            end
        end
    else -- Default to show city center
        parentControl.MissionDistrictName:SetText(Locale.Lookup("LOC_DISTRICT_CITY_CENTER_NAME"))
        parentControl.MissionDistrictIcon:SetIcon("ICON_DISTRICT_CITY_CENTER")
    end
end

-- ===========================================================================
function GetSpyRankNameByLevel(level)
    local spyRankName = ""

    if (level == 4) then
        spyRankName = "LOC_ESPIONAGE_LEVEL_4_NAME"
    elseif (level == 3) then
        spyRankName = "LOC_ESPIONAGE_LEVEL_3_NAME"
    elseif (level == 2) then
        spyRankName = "LOC_ESPIONAGE_LEVEL_2_NAME"
    else
        spyRankName = "LOC_ESPIONAGE_LEVEL_1_NAME"
    end

    return spyRankName
end

-- ===========================================================================
function GetMissionDescriptionString(mission, noloot, withloot)
    if mission.LootInfo >= 0 then
        return Locale.Lookup(withloot, GetMissionLootString(mission), mission.CityName)
    end

    return Locale.Lookup(noloot, mission.CityName)
end

-- ===========================================================================
function GetMissionOutcomeDetails(mission)
    local outcomeDetails = {}
    local kOpDef = GameInfo.UnitOperations[mission.Operation]

    if kOpDef ~= nil and kOpDef.Hash == UnitOperationTypes.SPY_COUNTERSPY then
        -- Counterspy specific
        outcomeDetails.Success = true
        outcomeDetails.Description =
            Locale.Lookup("LOC_ESPIONAGEOVERVIEW_MISSIONOUTCOME_SUCCESS_COUNTERSPY", mission.CityName)
        outcomeDetails.SpyStatus = ""
    elseif mission.InitialResult == EspionageResultTypes.SUCCESS_UNDETECTED then
        -- Success and undetected
        outcomeDetails.Success = true
        outcomeDetails.Description =
            GetMissionDescriptionString(
            mission,
            "LOC_ESPIONAGEOVERVIEW_MISSIONOUTCOME_SUCCESS_UNDETECTED",
            "LOC_ESPIONAGEOVERVIEW_MISSIONOUTCOME_SUCCESS_UNDETECTED_STOLELOOT"
        )
        outcomeDetails.SpyStatus = ""
    elseif mission.InitialResult == EspionageResultTypes.SUCCESS_MUST_ESCAPE then
        -- Success but detected
        if mission.EscapeResult == EspionageResultTypes.FAIL_MUST_ESCAPE then
            -- Success and escaped
            outcomeDetails.Success = true
            outcomeDetails.Description =
                GetMissionDescriptionString(
                mission,
                "LOC_ESPIONAGEOVERVIEW_MISSIONOUTCOME_SUCCESS_DETECTED_ESCAPED",
                "LOC_ESPIONAGEOVERVIEW_MISSIONOUTCOME_SUCCESS_DETECTED_STOLELOOT"
            )
            outcomeDetails.SpyStatus = ""
        elseif mission.EscapeResult == EspionageResultTypes.KILLED then
            -- Success and killed
            outcomeDetails.Success = false
            outcomeDetails.Description =
                GetMissionDescriptionString(
                mission,
                "LOC_ESPIONAGEOVERVIEW_MISSIONOUTCOME_SUCCESS_DETECTED_KILLED",
                "LOC_ESPIONAGEOVERVIEW_MISSIONOUTCOME_SUCCESS_DETECTED_KILLED_STOLELOOT"
            )
            outcomeDetails.SpyStatus = Locale.ToUpper("LOC_ESPIONAGEOVERVIEW_SPYKILLED")
        elseif mission.EscapeResult == EspionageResultTypes.CAPTURED then
            -- Success and captured
            outcomeDetails.Success = false
            outcomeDetails.Description =
                GetMissionDescriptionString(
                mission,
                "LOC_ESPIONAGEOVERVIEW_MISSIONOUTCOME_SUCCESS_DETECTED_CAPTURED",
                "LOC_ESPIONAGEOVERVIEW_MISSIONOUTCOME_SUCCESS_DETECTED_CAPTURED_STOLELOOT"
            )
            outcomeDetails.SpyStatus = Locale.ToUpper("LOC_ESPIONAGEOVERVIEW_SPYCAUGHT")
        end
    elseif mission.InitialResult == EspionageResultTypes.FAIL_UNDETECTED then
        -- Failure but undetected
        outcomeDetails.Success = false
        outcomeDetails.Description =
            GetMissionDescriptionString(
            mission,
            "LOC_ESPIONAGEOVERVIEW_MISSIONOUTCOME_FAILURE_UNDETECTED",
            "LOC_ESPIONAGEOVERVIEW_MISSIONOUTCOME_FAILURE_UNDETECTED_STOLELOOT"
        )
        outcomeDetails.SpyStatus = ""
    elseif mission.InitialResult == EspionageResultTypes.FAIL_MUST_ESCAPE then
        -- Failure and detected
        if mission.EscapeResult == EspionageResultTypes.FAIL_MUST_ESCAPE then
            -- Failure and escaped
            outcomeDetails.Success = false
            outcomeDetails.Description =
                GetMissionDescriptionString(
                mission,
                "LOC_ESPIONAGEOVERVIEW_MISSIONOUTCOME_FAILURE_DETECTED_ESCAPED",
                "LOC_ESPIONAGEOVERVIEW_MISSIONOUTCOME_FAILURE_DETECTED_ESCAPED_STOLELOOT"
            )
            outcomeDetails.SpyStatus = ""
        elseif mission.EscapeResult == EspionageResultTypes.KILLED then
            -- Failure and killed
            outcomeDetails.Success = false
            outcomeDetails.Description =
                GetMissionDescriptionString(
                mission,
                "LOC_ESPIONAGEOVERVIEW_MISSIONOUTCOME_FAILURE_DETECTED_KILLED",
                "LOC_ESPIONAGEOVERVIEW_MISSIONOUTCOME_FAILURE_DETECTED_KILLED_STOLELOOT"
            )
            outcomeDetails.SpyStatus = Locale.ToUpper("LOC_ESPIONAGEOVERVIEW_SPYKILLED")
        elseif mission.EscapeResult == EspionageResultTypes.CAPTURED then
            -- Failure and captured
            outcomeDetails.Success = false
            outcomeDetails.Description =
                GetMissionDescriptionString(
                mission,
                "LOC_ESPIONAGEOVERVIEW_MISSIONOUTCOME_FAILURE_DETECTED_CAPTURED",
                "LOC_ESPIONAGEOVERVIEW_MISSIONOUTCOME_FAILURE_DETECTED_CAPTURED_STOLELOOT"
            )
            outcomeDetails.SpyStatus = Locale.ToUpper("LOC_ESPIONAGEOVERVIEW_SPYCAUGHT")
        end
    elseif mission.InitialResult == EspionageResultTypes.KILLED then
        -- Killed
        outcomeDetails.Success = false
        outcomeDetails.Description =
            GetMissionDescriptionString(
            mission,
            "LOC_ESPIONAGEOVERVIEW_MISSIONOUTCOME_KILLED",
            "LOC_ESPIONAGEOVERVIEW_MISSIONOUTCOME_KILLED_STOLELOOT"
        )
        outcomeDetails.SpyStatus = Locale.ToUpper("LOC_ESPIONAGEOVERVIEW_SPYKILLED")
    elseif mission.InitialResult == EspionageResultTypes.CAPTURED then
        -- Captured
        outcomeDetails.Success = false
        outcomeDetails.Description =
            GetMissionDescriptionString(
            mission,
            "LOC_ESPIONAGEOVERVIEW_MISSIONOUTCOME_CAPTURED",
            "LOC_ESPIONAGEOVERVIEW_MISSIONOUTCOME_CAPTURED_STOLELOOT"
        )
        outcomeDetails.SpyStatus = Locale.ToUpper("LOC_ESPIONAGEOVERVIEW_SPYCAUGHT")
    end

    return outcomeDetails
end

-- ===========================================================================
function GetMissionLootString(mission)
    local lootString = ""

    local operationInfo = GameInfo.UnitOperations[mission.Operation]
    if operationInfo.Hash == UnitOperationTypes.SPY_STEAL_TECH_BOOST then
        local techInfo = GameInfo.Technologies[mission.LootInfo]
        lootString = techInfo.Name
    elseif operationInfo.Hash == UnitOperationTypes.SPY_GREAT_WORK_HEIST then
        local greatWorkType = Game.GetGreatWorkTypeFromIndex(mission.LootInfo)
        local greatWorkInfo = GameInfo.GreatWorks[greatWorkType]
        lootString = greatWorkInfo.Name
    elseif operationInfo.Hash == UnitOperationTypes.SPY_SIPHON_FUNDS then
        if mission.LootInfo <= 0 then
            lootString = Locale.Lookup("LOC_ESPIONAGEOVERVIEW_MISSIONOUTCOME_NO_GOLD")
        else
            lootString = Locale.Lookup("LOC_ESPIONAGEOVERVIEW_MISSIONOUTCOME_GOLD", mission.LootInfo)
        end
    end

    return lootString
end

-- ===========================================================================
function CanMissionBeRenewed(mission)
    local kOperationInfo = GameInfo.UnitOperations[mission.Operation]
    if
        kOperationInfo.Hash == UnitOperationTypes.SPY_LISTENING_POST or
            kOperationInfo.Hash == UnitOperationTypes.SPY_COUNTERSPY
     then
        return true
    end

    return false
end
