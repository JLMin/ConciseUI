-- ===========================================================================
-- Cui Great Person Tooltip
-- eudaimonia, 2/26/2019
-- ===========================================================================
include("InstanceManager")
include("SupportFunctions")
include("CivilizationIcon")

local CuiGreatPersonTT = {}
TTManager:GetTypeControlTable("CuiGreatPersonTT", CuiGreatPersonTT)

-- ===========================================================================
function UpdateGreatPersonTooltip(tControl, tData_Player, tData_GP)

    local classData = GameInfo.GreatPersonClasses[tData_GP.ClassID]

    -- Prep Instance Managers
    if CuiGreatPersonTT["PlayerIM"] ~= nil then
        CuiGreatPersonTT["PlayerIM"]:ResetInstances()
    else
        CuiGreatPersonTT["PlayerIM"] = InstanceManager:new("CuiRecruitInstance",
                                                           "Top",
                                                           CuiGreatPersonTT.ProgressStack)
    end

    local classText = Locale.Lookup(classData.Name)
    CuiGreatPersonTT.Label:SetText(classText)
    CuiGreatPersonTT.Divider:SetSizeX(CuiGreatPersonTT.Label:GetSizeX() + 60)

    for i, kPlayerPoints in ipairs(tData_Player) do
        local canEarnAnotherOfThisClass = true
        if (kPlayerPoints.MaxPlayerInstances ~= nil and
            kPlayerPoints.NumInstancesEarned ~= nil) then
            canEarnAnotherOfThisClass = kPlayerPoints.MaxPlayerInstances >
                                            kPlayerPoints.NumInstancesEarned
        end
        if (canEarnAnotherOfThisClass) then

            local tProgressInstance = CuiGreatPersonTT["PlayerIM"]:GetInstance()

            local sProgress = ""
            local sTurns = ""
            local pointTotal = tData_GP.RecruitCost
            local pointPlayer = kPlayerPoints.PointsTotal
            local percent = Clamp(pointPlayer / pointTotal, 0, 1)

            if percent < 1 then
                local pointRemaining = Round(pointTotal - pointPlayer, 0)
                local pointPerturn = Round(kPlayerPoints.PointsPerTurn, 1)
                local turnsRemaining = pointPerturn == 0 and 999 or
                                           math.ceil(
                                               pointRemaining / pointPerturn)
                sProgress = pointTotal .. " ( [COLOR_Civ6Red]-" ..
                                pointRemaining .. "[ENDCOLOR] / " ..
                                "[COLOR_ModStatusGreen]+" .. pointPerturn ..
                                "[ENDCOLOR] )"
                sTurns = turnsRemaining .. "[ICON_TURN]"
            end

            tProgressInstance.Country:SetText(kPlayerPoints.PlayerName)
            tProgressInstance.Point:SetText(sProgress)
            tProgressInstance.TurnsRemaining:SetText(sTurns)
            tProgressInstance.ProgressBar:SetPercent(percent)
            tProgressInstance.YouIndicator:SetHide(
                not (kPlayerPoints.PlayerID == Game.GetLocalPlayer()))
            tProgressInstance.YouBacking:SetHide(
                not (kPlayerPoints.PlayerID == Game.GetLocalPlayer()))

            tProgressInstance.CivilizationIcon =
                tProgressInstance.CivilizationIcon or
                    CivilizationIcon:new(tProgressInstance)
            tProgressInstance.CivilizationIcon:UpdateIconFromPlayerID(
                kPlayerPoints.PlayerID)
        end
    end
end

-- ===========================================================================
function SetGreatPersonToolTip(tControl, tData_Player, tData_GP)
    tControl:SetToolTipType("CuiGreatPersonTT")
    tControl:ClearToolTipCallback()
    tControl:SetToolTipCallback(function()
        UpdateGreatPersonTooltip(tControl, tData_Player, tData_GP)
    end)
end

-- ===========================================================================
LuaEvents.CuiGreatPersonToolTip.Add(SetGreatPersonToolTip)
