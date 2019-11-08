-- ===========================================================================
--	Great People Popup
-- ===========================================================================
include("InstanceManager")
include("TabSupport")
include("SupportFunctions")
include("Civ6Common") -- DifferentiateCivs
include("ModalScreen_PlayerYieldsHelper")
include("GameCapabilities")
include("CivilizationIcon")

-- ===========================================================================
--	CONSTANTS
-- ===========================================================================
local COLOR_CLAIMED = UI.GetColorValueFromHexLiteral(0xffffffff)
local COLOR_AVAILABLE = UI.GetColorValueFromHexLiteral(0xbbffffff)
local COLOR_UNAVAILABLE = UI.GetColorValueFromHexLiteral(0x55ffffff)

local BOX_COLOR = UI.GetColorValueFromHexLiteral(0xFF5A360F)
local HL_BOX_COLOR = UI.GetColorValueFromHexLiteral(0xFFFFF8E8)
local COLOR_GP_UNSELECTED = UI.GetColorValueFromHexLiteral(0xffe9dfc7) -- Background for unselected background (or forground text color on non-selected).
local COLOR_GP_SELECTED = UI.GetColorValueFromHexLiteral(0xff261407) -- Background for selected background (or forground text color on non-selected).

local MAX_BIOGRAPHY_PARAGRAPHS = 9 -- maximum # of paragraphs for a biography
local MIN_WIDTH = 285 * 2 -- minimum width of screen (instance size x # of panels)
local RELOAD_CACHE_ID = "GreatPeoplePopup"
local SIZE_ACTION_ICON = 38
local MAX_BEFORE_TRUNC_IND_NAME = 220

local Portraits = {
    [1] = "ICON_GENERIC_GREAT_PERSON_INDIVIDUAL_GENERAL_F",
    [2] = "ICON_GENERIC_GREAT_PERSON_INDIVIDUAL_ADMIRAL_F",
    [3] = "ICON_GENERIC_GREAT_PERSON_INDIVIDUAL_ENGINEER_M",
    [4] = "ICON_GENERIC_GREAT_PERSON_INDIVIDUAL_MERCHANT_M",
    [5] = "ICON_GENERIC_GREAT_PERSON_INDIVIDUAL_PROPHET_M",
    [6] = "ICON_GENERIC_GREAT_PERSON_INDIVIDUAL_SCIENTIST_M",
    [7] = "ICON_GENERIC_GREAT_PERSON_INDIVIDUAL_WRITER_M",
    [8] = "ICON_GENERIC_GREAT_PERSON_INDIVIDUAL_ARTIST_M",
    [9] = "ICON_GENERIC_GREAT_PERSON_INDIVIDUAL_MUSICIAN_M"
}

-- ===========================================================================
--	VARIABLES
-- ===========================================================================

local m_TopPanelConsideredHeight = 0
local m_greatPersonPanelIM = InstanceManager:new("PanelInstance", "Top",
                                                 Controls.PeopleStack)
local m_greatPersonRowIM = InstanceManager:new("PastRecruitmentInstance",
                                               "Content",
                                               Controls.RecruitedStack)
local m_uiGreatPeople
local m_kData
local m_activeBiographyID = -1 -- Only allow one open at a time (or very quick exceed font allocation)
local m_activeRecruitInfoID = -1 -- Only allow one open at a time (or very quick exceed font allocation)
local m_tabs
local m_defaultPastRowHeight = -1 -- Default/mix height (from XML) for a previously recruited row
local m_displayPlayerID = -1 -- What player are we displaying.  Used for looking at different players in autoplay
local m_screenWidth = -1

-- ===========================================================================
function ChangeDisplayPlayerID(bBackward)

    if (bBackward == nil) then bBackward = false end

    local aPlayers = PlayerManager.GetAliveMajors()
    local playerCount = #aPlayers

    -- Anything set yet?
    if (m_displayPlayerID ~= -1) then
        -- Loop and find the current player and skip to the next
        for i, pPlayer in ipairs(aPlayers) do
            if (pPlayer:GetID() == m_displayPlayerID) then

                if (bBackward) then
                    -- Have a previous one?
                    if (i >= 2) then
                        -- Yes
                        m_displayPlayerID = aPlayers[playerCount]:GetID()
                    else
                        -- Go to the end
                        m_displayPlayerID = aPlayers[1]:GetID()
                    end
                else
                    -- Have a next one?
                    if (#aPlayer > i) then
                        -- Yes
                        m_displayPlayerID = aPlayers[i + 1]:GetID()
                    else
                        -- Back to the beginning
                        m_displayPlayerID = aPlayers[1]:GetID()
                    end
                end

                return m_displayPlayerID
            end
        end

    end

    -- No player, or didn't find the previous player, start from the beginning.
    if (playerCount > 0) then m_displayPlayerID = aPlayers[1]:GetID() end

    return m_displayPlayerID
end

-- ===========================================================================
function GetDisplayPlayerID()

    if Automation.IsActive() then
        if (m_displayPlayerID ~= -1) then return m_displayPlayerID end

        return ChangeDisplayPlayerID()
    end

    return Game.GetLocalPlayer()
end

-- ===========================================================================
function GetActivationEffectTextByGreatPersonClass(greatPersonClassID)
    local text
    if ((GameInfo.GreatPersonClasses["GREAT_PERSON_CLASS_WRITER"] ~= nil and
        greatPersonClassID ==
        GameInfo.GreatPersonClasses["GREAT_PERSON_CLASS_WRITER"].Index) or
        (GameInfo.GreatPersonClasses["GREAT_PERSON_CLASS_ARTIST"] ~= nil and
            greatPersonClassID ==
            GameInfo.GreatPersonClasses["GREAT_PERSON_CLASS_ARTIST"].Index) or
        (GameInfo.GreatPersonClasses["GREAT_PERSON_CLASS_MUSICIAN"] ~= nil and
            greatPersonClassID ==
            GameInfo.GreatPersonClasses["GREAT_PERSON_CLASS_MUSICIAN"].Index)) then
        text = Locale.Lookup("LOC_GREAT_PEOPLE_WORK_CREATED")
    else
        text = Locale.Lookup("LOC_GREAT_PEOPLE_PERSON_ACTIVATED")
    end
    return text
end

-- ===========================================================================
--	Helper to obtain biography text.
--	individualID	index of the great person
--	RETURNS:		oreder table of biography text.
-- ===========================================================================
function GetBiographyTextTable(individualID)

    if individualID == nil then return {} end

    -- LOC_PEDIA_GREATPEOPLE_PAGE_GREAT_PERSON_INDIVIDUAL_ABU_AL_QASIM_AL_ZAHRAWI_CHAPTER_HISTORY_PARA_1
    -- LOC_PEDIA_GREATPEOPLE_PAGE_GREAT_PERSON_INDIVIDUAL_ABDUS_SALAM_CHAPTER_HISTORY_PARA_3
    local bioPrefix = "LOC_PEDIA_GREATPEOPLE_PAGE_"
    local bioName = GameInfo.GreatPersonIndividuals[individualID]
                        .GreatPersonIndividualType
    local bioPostfix = "_CHAPTER_HISTORY_PARA_"

    local kBiography = {}
    for i = 1, MAX_BIOGRAPHY_PARAGRAPHS, 1 do
        local key = bioPrefix .. bioName .. bioPostfix .. tostring(i)
        if Locale.HasTextKey(key) then
            kBiography[i] = Locale.Lookup(key)
        else
            break
        end
    end
    return kBiography
end

-- ===========================================================================
--	View the great people currently available (to be purchased)
-- ===========================================================================
function ViewCurrent(data)
    if (data == nil) then
        UI.DataError(
            "GreatPeople attempting to view current timeline data but received NIL instead.")
        return
    end

    m_uiGreatPeople = {}
    m_greatPersonPanelIM:ResetInstances()
    Controls.PeopleScroller:SetHide(false)
    Controls.RecruitedArea:SetHide(true)

    local kInstanceToShow = nil
    local tGrid = {}

    for i, kPerson in ipairs(data.Timeline) do
        local instance = m_greatPersonPanelIM:GetInstance()
        CuiSetPanelToDetault(instance) -- CUI: important

        local classData = GameInfo.GreatPersonClasses[kPerson.ClassID]
        local classText = ""
        local individualName = ""

        if (kPerson.ClassID ~= nil) then
            classText = Locale.Lookup(classData.Name)
        end
        if kPerson.IndividualID ~= nil then
            individualName = Locale.ToUpper(kPerson.Name)
        end

        if classText then
            local sLabel = individualName and (individualName) or classText
            instance.IndividualName:SetText(sLabel)
            instance.ClassIcon:SetToolTipString(classText)
            instance.CivilpediaButton:RegisterCallback(Mouse.eLClick, function()
                CuiSearchInCivilpedia(kPerson.PersonType)
            end)
        end

        if kPerson.EraID then
            local iEra = kPerson.EraID + 1
            local sEraNum = Locale.ToRomanNumeral(iEra)
            local eraName = Locale.Lookup(GameInfo.Eras[kPerson.EraID].Name)
            instance.EraLabel:SetText(sEraNum)
            instance.Era:SetToolTipString(eraName)
        end

        instance.Portrait:SetIcon(Portraits[i])

        local actionIcon = classData and classData.ActionIcon
        if actionIcon ~= nil and actionIcon ~= "" then
            local textureOffsetX, textureOffsetY, textureSheet =
                IconManager:FindIconAtlas(actionIcon, SIZE_ACTION_ICON)
            if (textureSheet == nil or textureSheet == "") then
                UI.DataError("Could not find icon in ViewCurrent: icon=\"" ..
                                 actionIcon .. "\", iconSize=" ..
                                 tostring(SIZE_ACTION_ICON))
            else
                instance.GreatPersonIcon:SetTexture(textureOffsetX,
                                                    textureOffsetY, textureSheet)
                instance.GreatPersonIcon:SetHide(false)
            end
        else
            instance.GreatPersonIcon:SetHide(true)
        end
        --------------------------------------------------------
        -- Actions and Passive Ability
        --------------------------------------------------------
        local sPassiveName = kPerson.PassiveNameText
        local sActiveName = kPerson.ActionNameText
        local sPassive = kPerson.PassiveEffectText
        local sActive = kPerson.ActionEffectText
        local bTwoBoxes = false

        instance.BonusBacking1:SetHide(true)
        instance.BonusBacking2:SetHide(true)
        instance.BonusBacking3:SetHide(true)
        if (sPassiveName ~= nil and sPassiveName ~= "") and
            (sActiveName ~= nil and sActiveName ~= "") then
            instance.BonusBacking2:SetHide(false)
            instance.BonusBacking3:SetHide(false)
            bTwoBoxes = true
        else
            instance.BonusBacking1:SetHide(false)
        end

        if sPassiveName ~= nil and sPassiveName ~= "" then
            local sFullText = sPassiveName .. "[NEWLINE][NEWLINE]" .. sPassive
            instance.Bonus1:SetText(sFullText)
            instance.Bonus2:SetText(sFullText)
        end

        if (sActiveName ~= nil and sActiveName ~= "") then
            local sFullText = sActiveName
            if (kPerson.ActionCharges > 0) then
                sFullText = sFullText .. " (" ..
                                Locale.Lookup("LOC_GREATPERSON_ACTION_CHARGES",
                                              kPerson.ActionCharges) .. ")"
            end

            sFullText = sFullText .. "[NEWLINE][NEWLINE]" .. sActive

            if bTwoBoxes then
                instance.Bonus3:SetText(sFullText)
            else
                instance.Bonus1:SetText(sFullText)
            end
        end
        --------------------------------------------------------
        -- Recruiting standings
        -- Let's sort the table first by points total, then by the lower player id (to push yours toward the top of the list for readability)

        -- I've further modified this so it only shows the top 3 players,
        -- as well as the local player if they aren't in the top 3.
        --------------------------------------------------------
        local recruitTable = {}
        instance["PlayerIM"] = instance["PlayerIM"] or
                                   InstanceManager:new("PlayerInstance",
                                                       "CivIconBackingFaded",
                                                       instance.CivIconStack)
        instance["PlayerIM"]:ResetInstances()

        if kPerson.IndividualID ~= nil and kPerson.ClassID ~= nil then
            for i, kPlayerPoints in ipairs(data.PointsByClass[kPerson.ClassID]) do
                table.insert(recruitTable, kPlayerPoints)
            end
            table.sort(recruitTable, function(a, b)
                local aLeft = (kPerson.RecruitCost - a.PointsTotal) /
                                  a.PointsPerTurn
                local bLeft = (kPerson.RecruitCost - b.PointsTotal) /
                                  b.PointsPerTurn
                return aLeft < bLeft
            end)

            for i, kPlayerPoints in ipairs(recruitTable) do
                if i <= 3 or kPlayerPoints.PlayerID == Game.GetLocalPlayer() then

                    local canEarnAnotherOfThisClass = true
                    if (kPlayerPoints.MaxPlayerInstances ~= nil and
                        kPlayerPoints.NumInstancesEarned ~= nil) then
                        canEarnAnotherOfThisClass =
                            kPlayerPoints.MaxPlayerInstances >
                                kPlayerPoints.NumInstancesEarned
                    end

                    if (canEarnAnotherOfThisClass) then
                        local iPlayer = kPlayerPoints.PlayerID
                        local tPlayerInstance =
                            instance["PlayerIM"]:GetInstance()

                        local iProgress =
                            Clamp(kPlayerPoints.PointsTotal /
                                      kPerson.RecruitCost, 0, 1)
                        local sRecruitDetails =
                            Locale.Lookup("LOC_GREAT_PEOPLE_POINT_DETAILS",
                                          Round(kPlayerPoints.PointsPerTurn, 1),
                                          classData.IconString, classData.Name)

                        tPlayerInstance.LocalPlayer:SetHide(
                            iPlayer ~= Game.GetLocalPlayer())

                        --------------------------------------------------------
                        -- Faded Icon
                        --------------------------------------------------------
                        if not tPlayerInstance.FadedIcon then
                            tPlayerInstance.FadedIcon =
                                CivilizationIcon:new(
                                    {
                                        CivIconBacking = tPlayerInstance.CivIconBackingFaded,
                                        CivIcon = tPlayerInstance.CivIconFaded
                                    })

                            tPlayerInstance.UNKNOWN_COLOR =
                                UI.GetColorValue(0.4, 0.4, 0.4, 1)
                        end
                        tPlayerInstance.FadedIcon:UpdateIconFromPlayerID(iPlayer)

                        -- UpdateIconFromPlayerID also sets color, so we need to undo that
                        tPlayerInstance.CivIconBackingFaded:SetColor(
                            tPlayerInstance.UNKNOWN_COLOR)
                        tPlayerInstance.CivIconFaded:SetColor(
                            tPlayerInstance.UNKNOWN_COLOR)
                        --------------------------------------------------------
                        -- Color Icon
                        --------------------------------------------------------
                        tPlayerInstance.FullIcon =
                            tPlayerInstance.FullIcon or CivilizationIcon:new(
                                {
                                    CivIconBacking = tPlayerInstance.CivIconBacking,
                                    CivIcon = tPlayerInstance.CivIcon
                                })
                        tPlayerInstance.FullIcon:UpdateIconFromPlayerID(iPlayer)
                        -- Set Progress Percentage
                        tPlayerInstance.CivIcon:SetPercent(iProgress)
                        tPlayerInstance.CivIconBacking:SetPercent(iProgress)
                        --------------------------------------------------------
                        --------------------------------------------------------
                    end
                    --------------------------------------------------------
                    -- If this player is the local player, then we should also update recruitment info
                    --------------------------------------------------------
                    if kPlayerPoints.PlayerID == Game.GetLocalPlayer() then
                        local sRecruitText =
                            Locale.Lookup(
                                "LOC_GREAT_PEOPLE_OR_RECRUIT_WITH_PATRONAGE")
                        local sRecruitTooltip = ""

                        instance.ConnotRecruitButton:SetHide(true)
                        instance.Amount:SetHide(false)

                        if (kPerson.EarnConditions ~= nil and
                            kPerson.EarnConditions ~= "") then
                            sRecruitText =
                                "[COLOR_Civ6Red]" ..
                                    Locale.Lookup(
                                        "LOC_GREAT_PEOPLE_CANNOT_EARN_PERSON") ..
                                    "[ENDCOLOR]"
                            sRecruitTooltip =
                                "[COLOR_Civ6Red]" .. kPerson.EarnConditions ..
                                    "[ENDCOLOR]"
                            instance.ConnotRecruitButton:SetHide(false)
                            instance.ConnotRecruitButton:SetText(sRecruitText)
                            instance.ConnotRecruitButton:SetToolTipString(
                                sRecruitTooltip)
                            instance.Amount:SetHide(true)
                        end

                        if (canEarnAnotherOfThisClass) then
                            local sProgress = ""
                            local sTurns = ""
                            local pointTotal = kPerson.RecruitCost
                            local pointPlayer = kPlayerPoints.PointsTotal

                            local pointRemaining =
                                Round(pointTotal - pointPlayer, 0)
                            local pointPerturn =
                                Round(kPlayerPoints.PointsPerTurn, 1)
                            local turnsRemaining =
                                pointPerturn == 0 and 999 or
                                    math.ceil(pointRemaining / pointPerturn)
                            if turnsRemaining >= 1 then
                                sProgress =
                                    pointTotal .. " ( [COLOR_Civ6Red]-" ..
                                        pointRemaining .. "[ENDCOLOR] / " ..
                                        "[COLOR_Civ6Green]+" .. pointPerturn ..
                                        "[ENDCOLOR] )"
                                sTurns = turnsRemaining .. "[ICON_TURN]"
                            end
                            instance.Amount:SetText(
                                sProgress .. "  -  " .. sTurns)
                        end
                    end
                end
            end
        end

        instance.CivIconStack:CalculateSize()
        instance.CivIconStack_TTCatcher:SetSizeVal(
            instance.CivIconStack:GetSizeX(), instance.CivIconStack:GetSizeY())
        LuaEvents.CuiGreatPersonToolTip(instance.CivIconStack_TTCatcher,
                                        recruitTable, kPerson)

        if kPerson.IndividualID ~= nil and kPerson.ClassID ~= nil then

            -- Buy via gold
            if (HasCapability("CAPABILITY_GREAT_PEOPLE_RECRUIT_WITH_GOLD") and
                (not kPerson.CanRecruit and not kPerson.CanReject and
                    kPerson.PatronizeWithGoldCost ~= nil and
                    kPerson.PatronizeWithGoldCost < 1000000)) then
                instance.GoldButton:SetText(
                    "[ICON_Gold]" .. kPerson.PatronizeWithGoldCost)
                instance.GoldButton:SetToolTipString(
                    GetPatronizeWithGoldTT(kPerson))
                instance.GoldButton:SetVoid1(kPerson.IndividualID)
                instance.GoldButton:RegisterCallback(Mouse.eLClick,
                                                     OnGoldButtonClick)
                instance.GoldButton:SetDisabled(not kPerson.CanPatronizeWithGold)
                instance.GoldButton:SetHide(false)
            else
                instance.GoldButton:SetHide(true)
            end

            -- Buy via Faith
            if (HasCapability("CAPABILITY_GREAT_PEOPLE_RECRUIT_WITH_FAITH") and
                (not kPerson.CanRecruit and not kPerson.CanReject and
                    kPerson.PatronizeWithFaithCost ~= nil and
                    kPerson.PatronizeWithFaithCost < 1000000)) then
                instance.FaithButton:SetText(
                    "[ICON_Faith]" .. kPerson.PatronizeWithFaithCost)
                instance.FaithButton:SetToolTipString(
                    GetPatronizeWithFaithTT(kPerson))
                instance.FaithButton:SetVoid1(kPerson.IndividualID)
                instance.FaithButton:RegisterCallback(Mouse.eLClick,
                                                      OnFaithButtonClick)
                instance.FaithButton:SetDisabled(
                    not kPerson.CanPatronizeWithFaith)
                instance.FaithButton:SetHide(false)
            else
                instance.FaithButton:SetHide(true)
            end

            -- Recruiting
            if (HasCapability("CAPABILITY_GREAT_PEOPLE_CAN_RECRUIT") and
                kPerson.CanRecruit and kPerson.RecruitCost ~= nil) then
                instance.RecruitButton:SetToolTipString(
                    Locale.Lookup("LOC_GREAT_PEOPLE_RECRUIT_DETAILS",
                                  kPerson.RecruitCost))
                instance.RecruitButton:SetVoid1(kPerson.IndividualID)
                instance.RecruitButton:RegisterCallback(Mouse.eLClick,
                                                        OnRecruitButtonClick)
                instance.RecruitButton:SetHide(false)
                instance.Amount:SetHide(true)

                instance.Top:SetTexture("Governments_BackingSelected")
                instance.BonusBacking1:SetColor(HL_BOX_COLOR)
                instance.BonusBacking2:SetColor(HL_BOX_COLOR)
                instance.BonusBacking3:SetColor(HL_BOX_COLOR)
                instance.Bonus1:SetColor(COLOR_GP_SELECTED)
                instance.Bonus2:SetColor(COLOR_GP_SELECTED)
                instance.Bonus3:SetColor(COLOR_GP_SELECTED)
                instance.IndividualName:SetColor(COLOR_GP_SELECTED)
                instance.GreatPeopleIcon:SetColor(COLOR_GP_SELECTED)
            else
                instance.RecruitButton:SetHide(true)

                instance.Top:SetTexture("Governments_Backing")
                instance.BonusBacking1:SetColor(BOX_COLOR)
                instance.BonusBacking2:SetColor(BOX_COLOR)
                instance.BonusBacking3:SetColor(BOX_COLOR)
                instance.Bonus1:SetColor(COLOR_GP_UNSELECTED)
                instance.Bonus2:SetColor(COLOR_GP_UNSELECTED)
                instance.Bonus3:SetColor(COLOR_GP_UNSELECTED)
                instance.IndividualName:SetColor(COLOR_GP_UNSELECTED)
                instance.GreatPeopleIcon:SetColor(COLOR_GP_UNSELECTED)
            end

            -- Rejecting
            if (HasCapability("CAPABILITY_GREAT_PEOPLE_CAN_REJECT") and
                kPerson.CanReject and kPerson.RejectCost ~= nil) then
                instance.RejectButton:SetToolTipString(
                    Locale.Lookup("LOC_GREAT_PEOPLE_PASS_DETAILS",
                                  kPerson.RejectCost))
                instance.RejectButton:SetVoid1(kPerson.IndividualID)
                instance.RejectButton:RegisterCallback(Mouse.eLClick,
                                                       OnRejectButtonClick)
                instance.RejectButton:SetHide(false)
            else
                instance.RejectButton:SetHide(true)
            end
        end

        if instance.Amount:IsHidden() then
            instance.BonusStack:SetOffsetVal(0, 45)
        else
            instance.BonusStack:SetOffsetVal(0, 48)
        end

        local noneAvailable = (kPerson.ClassID == nil)
        instance.Contents:SetHide(noneAvailable)
        instance.ClaimedLabel:SetHide(not noneAvailable)

        table.insert(tGrid, instance)
    end

end

function FillRecruitInstance(instance, playerPoints, personData, classData)
    instance.Country:SetText(playerPoints.PlayerName)

    instance.Amount:SetText(
        tostring(Round(playerPoints.PointsTotal, 1)) .. "/" ..
            tostring(personData.RecruitCost))
    local progressPercent = Clamp(playerPoints.PointsTotal /
                                      personData.RecruitCost, 0, 1)
    instance.ProgressBar:SetPercent(progressPercent)

    local recruitColorName = "GreatPeopleCS"
    if playerPoints.IsPlayer then recruitColorName = "GreatPeopleActiveCS" end
    instance.Amount:SetColorByName(recruitColorName)
    instance.Country:SetColorByName(recruitColorName)
    instance.Country:SetColorByName(recruitColorName)
    instance.ProgressBar:SetColorByName(recruitColorName)

    DifferentiateCiv(playerPoints.PlayerID, instance.CivIcon, instance.CivIcon,
                     instance.CivBacking, nil, nil, Game.GetLocalPlayer())

    local recruitDetails = Locale.Lookup("LOC_GREAT_PEOPLE_POINT_DETAILS",
                                         Round(playerPoints.PointsPerTurn, 1),
                                         classData.IconString, classData.Name)
    instance.Top:SetToolTipString(recruitDetails)
end

function GetPatronizeWithGoldTT(kPerson)
    return Locale.Lookup("LOC_GREAT_PEOPLE_PATRONAGE_GOLD_DETAILS",
                         kPerson.PatronizeWithGoldCost)
end

function GetPatronizeWithFaithTT(kPerson)
    return Locale.Lookup("LOC_GREAT_PEOPLE_PATRONAGE_FAITH_DETAILS",
                         kPerson.PatronizeWithFaithCost)
end

-- =======================================================================================
--	Layout the data for previously recruited great people.
-- =======================================================================================
function ViewPast(data)
    if (data == nil) then
        UI.DataError(
            "GreatPeople attempting to view past timeline data but received NIL instead.")
        return
    end

    m_greatPersonRowIM:ResetInstances()
    Controls.PeopleScroller:SetHide(true)
    Controls.RecruitedArea:SetHide(false)

    local localPlayerID = Game.GetLocalPlayer()

    local PADDING_FOR_SPACE_AROUND_TEXT = 20

    -- CUI for i, kPerson in ipairs(data.Timeline) do
    for i = table.count(data.Timeline), 1, -1 do
        local kPerson = data.Timeline[i]
        local instance = m_greatPersonRowIM:GetInstance()
        local classData = GameInfo.GreatPersonClasses[kPerson.ClassID]

        if m_defaultPastRowHeight < 0 then
            m_defaultPastRowHeight = instance.Content:GetSizeY()
        end
        local rowHeight = m_defaultPastRowHeight

        local date = Calendar.MakeYearStr(kPerson.TurnGranted)
        instance.EarnDate:SetText(date)

        local classText = ""
        if kPerson.ClassID ~= nil then
            classText = Locale.Lookup(classData.Name)
        else
            UI.DataError(
                "GreatPeople previous recruited as unable to find the class text for #" ..
                    tostring(i))
        end
        instance.ClassName:SetText(Locale.ToUpper(classText))
        instance.GreatPersonInfo:SetText(kPerson.Name)
        DifferentiateCiv(kPerson.ClaimantID, instance.CivIcon, instance.CivIcon,
                         instance.CivIndicator, nil, nil, localPlayerID)
        instance.RecruitedImage:SetHide(true)
        instance.YouIndicator:SetHide(true)
        if (kPerson.ClaimantID ~= nil) then
            local playerConfig = PlayerConfigurations[kPerson.ClaimantID] -- :GetCivilizationShortDescription();
            if (playerConfig ~= nil) then
                local iconName = "ICON_" .. playerConfig:GetLeaderTypeName()
                local localPlayer = Players[localPlayerID]

                if (localPlayer ~= nil and localPlayerID == kPerson.ClaimantID) then
                    instance.RecruitedImage:SetIcon(iconName, 55)
                    instance.RecruitedImage:SetToolTipString(
                        Locale.Lookup("LOC_GREAT_PEOPLE_RECRUITED_BY_YOU"))
                    instance.RecruitedImage:SetHide(false)
                    instance.YouIndicator:SetHide(false)

                elseif (Game.GetLocalObserver() == PlayerTypes.OBSERVER or
                    (localPlayer ~= nil and localPlayer:GetDiplomacy() ~= nil and
                        localPlayer:GetDiplomacy():HasMet(kPerson.ClaimantID))) then
                    instance.RecruitedImage:SetIcon(iconName, 55)
                    instance.RecruitedImage:SetToolTipString(
                        Locale.Lookup(playerConfig:GetPlayerName()))
                    instance.RecruitedImage:SetHide(false)
                    instance.YouIndicator:SetHide(true)
                else
                    instance.RecruitedImage:SetIcon("ICON_CIVILIZATION_UNKNOWN",
                                                    55)
                    instance.RecruitedImage:SetToolTipString(
                        Locale.Lookup("LOC_GREAT_PEOPLE_RECRUITED_BY_UNKNOWN"))
                    instance.RecruitedImage:SetHide(false)
                    instance.YouIndicator:SetHide(true)
                end
            end
        end

        local isLocalPlayer =
            (kPerson.ClaimantID ~= nil and kPerson.ClaimantID == localPlayerID)
        instance.YouIndicator:SetHide(not isLocalPlayer)

        local colorName = (isLocalPlayer and "GreatPeopleRow") or
                              "GreatPeopleRowUnOwned"
        instance.Content:SetColorByName(colorName)

        -- Ability Effects

        colorName = (isLocalPlayer and "GreatPeoplePastCS") or
                        "GreatPeoplePastUnownedCS"

        if instance["m_EffectsIM"] ~= nil then
            instance["m_EffectsIM"]:ResetInstances()
        else
            instance["m_EffectsIM"] = InstanceManager:new("PastEffectInstance",
                                                          "Top",
                                                          instance.EffectStack)
        end

        if kPerson.PassiveNameText ~= nil and kPerson.PassiveNameText ~= "" then
            local effectInst = instance["m_EffectsIM"]:GetInstance()
            local effectText = kPerson.PassiveEffectText
            local fullText = kPerson.PassiveNameText .. "[NEWLINE][NEWLINE]" ..
                                 effectText
            effectInst.Text:SetText(effectText)
            effectInst.EffectTypeIcon:SetToolTipString(fullText)
            effectInst.Text:SetColorByName(colorName)

            rowHeight = math.max(rowHeight, effectInst.Text:GetSizeY() +
                                     PADDING_FOR_SPACE_AROUND_TEXT)

            effectInst.PassiveAbilityIcon:SetHide(false)
            effectInst.ActiveAbilityIcon:SetHide(true)
        end

        if (kPerson.ActionNameText ~= nil and kPerson.ActionNameText ~= "") then
            local effectInst = instance["m_EffectsIM"]:GetInstance()
            local effectText = kPerson.ActionEffectText
            local fullText = kPerson.ActionNameText
            if (kPerson.ActionCharges > 0) then
                fullText = fullText .. " (" ..
                               Locale.Lookup("LOC_GREATPERSON_ACTION_CHARGES",
                                             kPerson.ActionCharges) .. ")"
            end
            fullText = fullText .. "[NEWLINE]" .. kPerson.ActionUsageText
            fullText = fullText .. "[NEWLINE][NEWLINE]" .. effectText
            effectInst.Text:SetText(effectText)
            effectInst.EffectTypeIcon:SetToolTipString(fullText)
            effectInst.Text:SetColorByName(colorName)

            rowHeight = math.max(rowHeight, effectInst.Text:GetSizeY() +
                                     PADDING_FOR_SPACE_AROUND_TEXT)

            local actionIcon = classData.ActionIcon
            if actionIcon ~= nil and actionIcon ~= "" then
                local textureOffsetX, textureOffsetY, textureSheet =
                    IconManager:FindIconAtlas(actionIcon, SIZE_ACTION_ICON)
                if (textureSheet == nil or textureSheet == "") then
                    error("Could not find icon in ViewCurrent: icon=\"" ..
                              actionIcon .. "\", iconSize=" ..
                              tostring(SIZE_ACTION_ICON))
                else
                    effectInst.ActiveAbilityIcon:SetTexture(textureOffsetX,
                                                            textureOffsetY,
                                                            textureSheet)
                    effectInst.ActiveAbilityIcon:SetHide(false)
                    effectInst.PassiveAbilityIcon:SetHide(true)
                end
            else
                effectInst.ActiveAbilityIcon:SetHide(true)
            end
        end

        instance.Content:SetSizeY(rowHeight)

    end

    m_screenWidth = 1396
    Controls.PopupContainer:SetSizeX(m_screenWidth)
    Controls.ModalFrame:SetSizeX(m_screenWidth)

    Controls.RecruitedStack:CalculateSize()
    Controls.RecruitedScroller:CalculateSize()
end

-- =======================================================================================
-- Toggle Extended Recruit Info whether open or closed
-- =======================================================================================
function OnRecruitInfoClick(individualID)
    -- If a recruit info is open, close the last opened
    if m_activeRecruitInfoID ~= -1 and individualID ~= m_activeRecruitInfoID then
        OnRecruitInfoClick(m_activeRecruitInfoID)
    end

    local instance = m_uiGreatPeople[individualID]
    if instance == nil then
        print("WARNING: Was unable to find instance for individual \"" ..
                  tostring(individualID) .. "\"")
        return
    end

    local isShowingRecruitInfo = not instance.RecruitInfoArea:IsHidden()

    instance.BiographyArea:SetHide(true)
    instance.RecruitInfoArea:SetHide(isShowingRecruitInfo)
    instance.MainInfo:SetHide(not isShowingRecruitInfo)
    instance.FadedBackground:SetHide(isShowingRecruitInfo)
    instance.BiographyOpenButton:SetHide(not isShowingRecruitInfo)

    if isShowingRecruitInfo then
        m_activeRecruitInfoID = -1
    else
        m_activeRecruitInfoID = individualID
    end
end

-- =======================================================================================
--	Button Callback
--	Switch between biography and stats for a great person
-- =======================================================================================
function OnBiographyClick(individualID)

    -- If a biography is open, close it via recursive magic...
    if m_activeBiographyID ~= -1 and individualID ~= m_activeBiographyID then
        OnBiographyClick(m_activeBiographyID)
    end

    local instance = m_uiGreatPeople[individualID]
    if instance == nil then
        print("WARNING: Was unable to find instance for individual \"" ..
                  tostring(individualID) .. "\"")
        return
    end

    local isShowingBiography = not instance.BiographyArea:IsHidden()
    local buttonLabelText

    instance.BiographyArea:SetHide(isShowingBiography)
    instance.RecruitInfoArea:SetHide(true)
    instance.MainInfo:SetHide(not isShowingBiography)
    instance.FadedBackground:SetHide(isShowingBiography)
    instance.BiographyOpenButton:SetHide(not isShowingBiography)

    if isShowingBiography then
        -- Current showing; so hide...
        m_activeBiographyID = -1
    else
        -- Current hidden, show biography...
        m_activeBiographyID = individualID

        -- Get data
        local kBiographyText
        for k, v in pairs(m_kData.Timeline) do
            if v.IndividualID == individualID then
                kBiographyText = v.BiographyTextTable
                break
            end
        end
        if kBiographyText ~= nil then
            instance.BiographyText:SetText(
                table.concat(kBiographyText, "[NEWLINE][NEWLINE]"))
        else
            instance.BiographyText:SetText("")
            print(
                "WARNING: Couldn't find data for \"" .. tostring(individualID) ..
                    "\"")
        end

        instance.BiographyScroll:CalculateSize()
    end
end

-- =======================================================================================
--	Populate a data table with timeline information.
--		data	An allocated table to receive the timeline.
--		isPast	If the data should be from the past (instead of the current)
-- =======================================================================================
function PopulateData(data, isPast)

    if data == nil then
        error("GreatPeoplePopup received an empty data in to PopulateData")
        return
    end

    local displayPlayerID = GetDisplayPlayerID()
    if (displayPlayerID == -1) then return end

    local pGreatPeople = Game.GetGreatPeople()
    if pGreatPeople == nil then
        UI.DataError("GreatPeoplePopup received NIL great people object.")
        return
    end

    local pTimeline = nil
    if isPast then
        pTimeline = pGreatPeople:GetPastTimeline()
    else
        pTimeline = pGreatPeople:GetTimeline()
    end

    for i, entry in ipairs(pTimeline) do
        -- don't add unclaimed great people to the previously recruited tab
        if not isPast or entry.Claimant then
            local claimantName = nil
            if (entry.Claimant ~= nil) then
                claimantName = Locale.Lookup(
                                   PlayerConfigurations[entry.Claimant]:GetCivilizationShortDescription())
            end

            local canRecruit = false
            local canReject = false
            local canPatronizeWithFaith = false
            local canPatronizeWithGold = false
            local actionCharges = 0
            local patronizeWithGoldCost = nil
            local patronizeWithFaithCost = nil
            local recruitCost = entry.Cost
            local rejectCost = nil
            local earnConditions = nil
            if (entry.Individual ~= nil) then
                if (Players[displayPlayerID] ~= nil) then
                    canRecruit = pGreatPeople:CanRecruitPerson(displayPlayerID,
                                                               entry.Individual)
                    if (not isPast) then
                        canReject = pGreatPeople:CanRejectPerson(
                                        displayPlayerID, entry.Individual)
                        if (canReject) then
                            rejectCost =
                                pGreatPeople:GetRejectCost(displayPlayerID,
                                                           entry.Individual)
                        end
                    end
                    canPatronizeWithGold =
                        pGreatPeople:CanPatronizePerson(displayPlayerID,
                                                        entry.Individual,
                                                        YieldTypes.GOLD)
                    patronizeWithGoldCost =
                        pGreatPeople:GetPatronizeCost(displayPlayerID,
                                                      entry.Individual,
                                                      YieldTypes.GOLD)
                    canPatronizeWithFaith =
                        pGreatPeople:CanPatronizePerson(displayPlayerID,
                                                        entry.Individual,
                                                        YieldTypes.FAITH)
                    patronizeWithFaithCost =
                        pGreatPeople:GetPatronizeCost(displayPlayerID,
                                                      entry.Individual,
                                                      YieldTypes.FAITH)
                    earnConditions = pGreatPeople:GetEarnConditionsText(
                                         displayPlayerID, entry.Individual)
                end
                local individualInfo =
                    GameInfo.GreatPersonIndividuals[entry.Individual]
                actionCharges = individualInfo.ActionCharges
            end

            local color = COLOR_UNAVAILABLE
            if (entry.Class ~= nil) then
                if (canRecruit or canReject) then
                    color = COLOR_CLAIMED
                else
                    color = COLOR_AVAILABLE
                end
            end

            local personName = ""
            if GameInfo.GreatPersonIndividuals[entry.Individual] ~= nil then
                personName = Locale.Lookup(
                                 GameInfo.GreatPersonIndividuals[entry.Individual]
                                     .Name)
                personType = (GameInfo.GreatPersonIndividuals[entry.Individual]
                                 .GreatPersonIndividualType) -- CUI
            end

            local kPerson = {
                IndividualID = entry.Individual,
                ClassID = entry.Class,
                EraID = entry.Era,
                ClaimantID = entry.Claimant,
                ActionCharges = actionCharges,
                ActionNameText = entry.ActionNameText,
                ActionUsageText = entry.ActionUsageText,
                ActionEffectText = entry.ActionEffectText,
                BiographyTextTable = GetBiographyTextTable(entry.Individual),
                CanPatronizeWithFaith = canPatronizeWithFaith,
                CanPatronizeWithGold = canPatronizeWithGold,
                CanReject = canReject,
                ClaimantName = claimantName,
                Color = color,
                CanRecruit = canRecruit,
                EarnConditions = earnConditions,
                Name = personName,
                PassiveNameText = entry.PassiveNameText,
                PassiveEffectText = entry.PassiveEffectText,
                PatronizeWithFaithCost = patronizeWithFaithCost,
                PatronizeWithGoldCost = patronizeWithGoldCost,
                RecruitCost = recruitCost,
                RejectCost = rejectCost,
                TurnGranted = entry.TurnGranted,
                PersonType = personType -- CUI
            }
            table.insert(data.Timeline, kPerson)
        end
    end

    for classInfo in GameInfo.GreatPersonClasses() do
        local classID = classInfo.Index
        local pointsTable = {}
        local players = Game.GetPlayers{Major = true, Alive = true}
        for i, player in ipairs(players) do
            local playerName = ""
            local isPlayer = false
            if (player:GetID() == displayPlayerID) then
                playerName = playerName .. Locale.Lookup(
                                 PlayerConfigurations[player:GetID()]:GetCivilizationShortDescription())
                isPlayer = true
            elseif (Game.GetLocalObserver() == PlayerTypes.OBSERVER or
                Players[displayPlayerID]:GetDiplomacy():HasMet(player:GetID())) then
                playerName = playerName .. Locale.Lookup(
                                 PlayerConfigurations[player:GetID()]:GetCivilizationShortDescription())
            else
                playerName = playerName ..
                                 Locale.Lookup("LOC_DIPLOPANEL_UNMET_PLAYER")
            end
            local playerPoints = {
                IsPlayer = isPlayer,
                MaxPlayerInstances = classInfo.MaxPlayerInstances,
                NumInstancesEarned = pGreatPeople:CountPeopleReceivedByPlayer(
                    classID, player:GetID()),
                PlayerName = playerName,
                PointsTotal = player:GetGreatPeoplePoints():GetPointsTotal(
                    classID),
                PointsPerTurn = player:GetGreatPeoplePoints():GetPointsPerTurn(
                    classID),
                PlayerID = player:GetID()
            }
            table.insert(pointsTable, playerPoints)
        end
        table.sort(pointsTable, function(a, b)
            if (a.IsPlayer and not b.IsPlayer) then
                return true
            elseif (not a.IsPlayer and b.IsPlayer) then
                return false
            end
            return a.PointsTotal > b.PointsTotal
        end)
        data.PointsByClass[classID] = pointsTable
    end

end

-- =======================================================================================
function Open()
    if (Game.GetLocalPlayer() == -1) then return end

    -- Queue the screen as a popup, but we want it to render at a desired location in the hierarchy, not on top of everything.
    if not UIManager:IsInPopupQueue(ContextPtr) then
        local kParameters = {}
        kParameters.RenderAtCurrentParent = true
        kParameters.InputAtCurrentParent = true
        kParameters.AlwaysVisibleInQueue = true
        UIManager:QueuePopup(ContextPtr, PopupPriority.Low, kParameters)
        UI.PlaySound("UI_Screen_Open")
    end

    Refresh()

    -- From ModalScreen_PlayerYieldsHelper
    if not RefreshYields() then
        Controls.Vignette:SetSizeY(m_TopPanelConsideredHeight)
    end

    -- From Civ6_styles: FullScreenVignetteConsumer
    Controls.ScreenAnimIn:SetToBeginning()
    Controls.ScreenAnimIn:Play()

    LuaEvents.GreatPeople_OpenGreatPeople()
end

-- =======================================================================================
function Close()
    if not ContextPtr:IsHidden() then UI.PlaySound("UI_Screen_Close") end

    if UIManager:DequeuePopup(ContextPtr) then
        LuaEvents.GreatPeople_CloseGreatPeople()
    end
end

-- =======================================================================================
--	UI Handler
-- =======================================================================================
function OnClose() Close() end

-- =======================================================================================
--	LUA Event
-- =======================================================================================
function OnOpenViaNotification() Open() end

-- =======================================================================================
--	LUA Event
-- =======================================================================================
function OnOpenViaLaunchBar() Open() end

-- ===========================================================================
function OnRecruitButtonClick(individualID)
    local pLocalPlayer = Players[Game.GetLocalPlayer()]
    if (pLocalPlayer ~= nil) then
        local kParameters = {}
        kParameters[PlayerOperations.PARAM_GREAT_PERSON_INDIVIDUAL_TYPE] =
            individualID
        UI.RequestPlayerOperation(Game.GetLocalPlayer(),
                                  PlayerOperations.RECRUIT_GREAT_PERSON,
                                  kParameters)
        Close()
    end
end

-- ===========================================================================
function OnRejectButtonClick(individualID)
    local pLocalPlayer = Players[Game.GetLocalPlayer()]
    if (pLocalPlayer ~= nil) then
        local kParameters = {}
        kParameters[PlayerOperations.PARAM_GREAT_PERSON_INDIVIDUAL_TYPE] =
            individualID
        UI.RequestPlayerOperation(Game.GetLocalPlayer(),
                                  PlayerOperations.REJECT_GREAT_PERSON,
                                  kParameters)
        Close()
    end
end

-- ===========================================================================
function OnGoldButtonClick(individualID)
    local pLocalPlayer = Players[Game.GetLocalPlayer()]
    if (pLocalPlayer ~= nil) then
        local kParameters = {}
        kParameters[PlayerOperations.PARAM_GREAT_PERSON_INDIVIDUAL_TYPE] =
            individualID
        kParameters[PlayerOperations.PARAM_YIELD_TYPE] = YieldTypes.GOLD
        UI.RequestPlayerOperation(Game.GetLocalPlayer(),
                                  PlayerOperations.PATRONIZE_GREAT_PERSON,
                                  kParameters)
        UI.PlaySound("Purchase_With_Gold")
        Close()
    end
end

-- ===========================================================================
function OnFaithButtonClick(individualID)
    local pLocalPlayer = Players[Game.GetLocalPlayer()]
    if (pLocalPlayer ~= nil) then
        local kParameters = {}
        kParameters[PlayerOperations.PARAM_GREAT_PERSON_INDIVIDUAL_TYPE] =
            individualID
        kParameters[PlayerOperations.PARAM_YIELD_TYPE] = YieldTypes.FAITH
        UI.RequestPlayerOperation(Game.GetLocalPlayer(),
                                  PlayerOperations.PATRONIZE_GREAT_PERSON,
                                  kParameters)
        UI.PlaySound("Purchase_With_Faith")
        Close()
    end
end

-- ===========================================================================
--	Game Engine Event
-- ===========================================================================
function OnLocalPlayerChanged(playerID, prevLocalPlayerID)
    if playerID == -1 then return end
    m_tabs.SelectTab(Controls.ButtonGreatPeople)
end

-- ===========================================================================
--	Game Engine Event
-- ===========================================================================
function OnLocalPlayerTurnBegin()
    if (not ContextPtr:IsHidden()) then Refresh() end
end

-- ===========================================================================
--	Game Engine Event
-- ===========================================================================
function OnLocalPlayerTurnEnd()
    if (not ContextPtr:IsHidden()) and GameConfiguration.IsHotseat() then
        Close()
    end
end

-- ===========================================================================
--	Game Engine Event
-- ===========================================================================
function OnUnitGreatPersonActivated(unitOwner, unitID, greatPersonClassID,
                                    greatPersonIndividualID)
    if (unitOwner == Game.GetLocalObserver() or Game.GetLocalObserver() ==
        PlayerTypes.OBSERVER) then
        local player = Players[unitOwner]
        if (player ~= nil) then
            local unit = player:GetUnits():FindID(unitID)
            if (unit ~= nil) then
                local message = GetActivationEffectTextByGreatPersonClass(
                                    greatPersonClassID)
                UI.AddWorldViewText(EventSubTypes.PLOT, message, unit:GetX(),
                                    unit:GetY(), 0)
                UI.PlaySound("Claim_Great_Person")
            end
        end
    end
end

-- ===========================================================================
--	Game Engine Event
-- ===========================================================================
function OnGreatPeoplePointsChanged(playerID)
    -- Update for any player's change, so that the local player can see up to date information about other players' points
    if (not ContextPtr:IsHidden()) then Refresh() end
end

-- ===========================================================================
--
-- ===========================================================================
function Refresh()
    local kData = {Timeline = {}, PointsByClass = {}}
    if m_tabs.selectedControl == Controls.ButtonPreviouslyRecruited then
        PopulateData(kData, true) -- use past data
        ViewPast(kData)
    else
        PopulateData(kData, false) -- do not use past data
        ViewCurrent(kData)
    end

    m_kData = kData
end

-- ===========================================================================
--	Tab callback
-- ===========================================================================
function OnGreatPeopleClick()
    Controls.SelectGreatPeople:SetHide(false)
    Controls.ButtonGreatPeople:SetSelected(true)
    Controls.SelectPreviouslyRecruited:SetHide(true)
    Controls.ButtonPreviouslyRecruited:SetSelected(false)
    Refresh()
end

-- ===========================================================================
--	Tab callback
-- ===========================================================================
function OnPreviousRecruitedClick()
    Controls.SelectGreatPeople:SetHide(true)
    Controls.ButtonGreatPeople:SetSelected(false)
    Controls.SelectPreviouslyRecruited:SetHide(false)
    Controls.ButtonPreviouslyRecruited:SetSelected(true)
    Refresh()
end

-- =======================================================================================
--	UI Event
-- =======================================================================================
function OnInit(isHotload)
    if isHotload then LuaEvents.GameDebug_GetValues(RELOAD_CACHE_ID) end
end

-- =======================================================================================
--	UI Event
--	Input
-- =======================================================================================
-- ===========================================================================
function KeyHandler(key)
    if key == Keys.VK_ESCAPE then
        Close()
        return true
    end
    return false
end
function OnInputHandler(pInputStruct)
    local uiMsg = pInputStruct:GetMessageType()
    if (uiMsg == KeyEvents.KeyUp) then
        return KeyHandler(pInputStruct:GetKey())
    end
    return false
end

-- =======================================================================================
--	UI Event
-- =======================================================================================
function OnShutdown()
    LuaEvents.GameDebug_AddValue(RELOAD_CACHE_ID, "isHidden",
                                 ContextPtr:IsHidden())
    LuaEvents.GameDebug_AddValue(RELOAD_CACHE_ID, "isPreviousTab",
                                 (m_tabs.selectedControl ==
                                     Controls.ButtonPreviouslyRecruited))
end

-- ===========================================================================
--	LUA Event
--	Set cached values back after a hotload.
-- ===========================================================================
function OnGameDebugReturn(context, contextTable)
    if context ~= RELOAD_CACHE_ID then return end
    local isHidden = contextTable["isHidden"]
    if not isHidden then
        local isPreviouslyRecruited = contextTable["isPreviousTab"]
        if isPreviouslyRecruited then
            m_tabs.SelectTab(Controls.ButtonPreviouslyRecruited)
        else
            m_tabs.SelectTab(Controls.ButtonGreatPeople)
        end
    end
end

-- CUI ===================================================================================
function CuiSetPanelToDetault(instance)
    instance.GreatPersonIcon:SetHide(true)
    instance.BonusBacking1:SetHide(true)
    instance.BonusBacking2:SetHide(true)
    instance.BonusBacking3:SetHide(true)

    instance.ConnotRecruitButton:SetHide(true)
    instance.Amount:SetHide(true)
    instance.GoldButton:SetHide(true)
    instance.FaithButton:SetHide(true)
    instance.RecruitButton:SetHide(true)
    instance.RejectButton:SetHide(true)

    instance.Top:SetTexture("Governments_Backing")
    instance.BonusBacking1:SetColor(BOX_COLOR)
    instance.BonusBacking2:SetColor(BOX_COLOR)
    instance.BonusBacking3:SetColor(BOX_COLOR)
    instance.Bonus1:SetColor(COLOR_GP_UNSELECTED)
    instance.Bonus2:SetColor(COLOR_GP_UNSELECTED)
    instance.Bonus3:SetColor(COLOR_GP_UNSELECTED)
    instance.IndividualName:SetColor(COLOR_GP_UNSELECTED)
    instance.GreatPeopleIcon:SetColor(COLOR_GP_UNSELECTED)
end

-- CUI ===================================================================================
function CuiSearchInCivilpedia(name) LuaEvents.OpenCivilopedia(name) end

-- =======================================================================================
--
-- =======================================================================================
function Initialize()

    if (not HasCapability("CAPABILITY_GREAT_PEOPLE_VIEW")) then
        -- Great People Viewing is off, just exit
        return
    end

    -- Tab setup and setting of default tab.
    m_tabs = CreateTabs(Controls.TabContainer, 42, 34,
                        UI.GetColorValueFromHexLiteral(0xFF331D05))
    m_tabs.AddTab(Controls.ButtonGreatPeople, OnGreatPeopleClick)
    m_tabs.AddTab(Controls.ButtonPreviouslyRecruited, OnPreviousRecruitedClick)
    m_tabs.CenterAlignTabs(-10)
    m_tabs.SelectTab(Controls.ButtonGreatPeople)

    -- UI Events
    ContextPtr:SetInitHandler(OnInit)
    ContextPtr:SetInputHandler(OnInputHandler, true)
    ContextPtr:SetShutdown(OnShutdown)

    -- UI Controls
    -- We use a separate BG within the PeopleScroller control since it needs to scroll with the contents
    Controls.ModalBG:SetHide(true)
    Controls.ModalScreenClose:RegisterCallback(Mouse.eLClick, OnClose)
    Controls.ModalScreenTitle:SetText(Locale.ToUpper(
                                          Locale.Lookup("LOC_GREAT_PEOPLE_TITLE")))

    -- Game engine Events
    Events.LocalPlayerChanged.Add(OnLocalPlayerChanged)
    Events.LocalPlayerTurnBegin.Add(OnLocalPlayerTurnBegin)
    Events.LocalPlayerTurnEnd.Add(OnLocalPlayerTurnEnd)
    Events.UnitGreatPersonActivated.Add(OnUnitGreatPersonActivated)
    Events.GreatPeoplePointsChanged.Add(OnGreatPeoplePointsChanged)

    -- LUA Events
    LuaEvents.GameDebug_Return.Add(OnGameDebugReturn)
    LuaEvents.LaunchBar_OpenGreatPeoplePopup.Add(OnOpenViaLaunchBar)
    LuaEvents.NotificationPanel_OpenGreatPeoplePopup.Add(OnOpenViaNotification)
    LuaEvents.LaunchBar_CloseGreatPeoplePopup.Add(OnClose)

    -- Audio Events
    Controls.ButtonGreatPeople:RegisterCallback(Mouse.eMouseEnter, function()
        UI.PlaySound("Main_Menu_Mouse_Over")
    end)
    Controls.ButtonPreviouslyRecruited:RegisterCallback(Mouse.eMouseEnter,
                                                        function()
        UI.PlaySound("Main_Menu_Mouse_Over")
    end)

    m_TopPanelConsideredHeight = Controls.Vignette:GetSizeY() - TOP_PANEL_OFFSET
end
Initialize()
