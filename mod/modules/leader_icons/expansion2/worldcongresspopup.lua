-- ===========================================================================
-- World Congress Popup
-- ===========================================================================
include("PopupDialog")
include("LeaderIcon")
include("CivilizationIcon")
include("InstanceManager")
include("SupportFunctions")
include("WorldCrisisSupport")
include("PopupPriorityLoader_", true)
include("InputSupport")
include("Civ6Common") -- FormatTimeRemaining
include("cuileadericonsupport") -- CUI

-- ===========================================================================
-- Constants
-- ===========================================================================
local DEBUG_DATA = false -- Auto-populate voting data between hot reloads (DO NOT CHECK-IN SET TO TRUE)
local DEBUG_RESET_DATA = true
local RELOAD_CACHE_ID = "WorldCongressPopup"

local WORLD_CONGRESS_STAGE_1 = DB.MakeHash("TURNSEG_WORLDCONGRESS_1")
local WORLD_CONGRESS_STAGE_2 = DB.MakeHash("TURNSEG_WORLDCONGRESS_2")
local WORLD_CONGRESS_RESOLUTION =
    DB.MakeHash("TURNSEG_WORLDCONGRESS_RESOLUTION")

local REVIEW_TAB_RESULTS = DB.MakeHash("REVIEW_TAB_RESULTS")
local REVIEW_TAB_CURRENT_EFFECTS = DB.MakeHash("REVIEW_TAB_CURRENT_EFFECTS")
local REVIEW_TAB_AVAILABLE_PROPOSALS = DB.MakeHash(
                                           "REVIEW_TAB_AVAILABLE_PROPOSALS")

local NO_VOTE = 0
local UP_VOTE = 1
local DOWN_VOTE = -1
local PHASE_STEP_MAX = 2

local COLOR_RED = UI.GetColorValue(1, 0, 0, 1)
local COLOR_GREEN = UI.GetColorValue(97 / 255, 197 / 255, 97 / 255, 1)

-- ===========================================================================
-- Members
-- ===========================================================================
local m_CurrentPhase = 0 -- valid values are 1 (select your votes), and 2 (preview before submission)
local m_CurrentStage = 0 -- valid values are 1 (regular congress), 2 (special session) and 4 (for results)
local m_WorkingFavor = 0 -- pending favor
local m_StartingFavor = 0 -- starting favor
local m_IsInSession = false -- if m_CurrentStage == 1 or 2
local m_HasAccepted = false -- set to true when accept button is clicked if m_CurrentPhase == 2
local m_IsEmergencySession = false -- if m_CurrentStage == 2
local m_HasSpecialSessionNotification = false
local m_ReviewTab = REVIEW_TAB_RESULTS
local m_kPreviousTooltipEvaluators = {}

-- The members below store state that initialize when the screen opens
local m_kProposalVotes
local m_kResolutionVotes
local m_kResolutionChoices
local m_kResolutionsTitle

local m_kPopupDialog = PopupDialog:new("WorldCongressPopup")

local m_kLeaderBGItemIM = InstanceManager:new("LeaderBanner", "Root")
local m_kLeaderButtonIM = InstanceManager:new("LeaderButton", "Root",
                                              Controls.LeaderStack)
local m_kProposalItemIM = InstanceManager:new("ProposalItem", "Root",
                                              Controls.ResolutionStack)
local m_kResolutionItemIM = InstanceManager:new("ResolutionItem", "Root",
                                                Controls.ResolutionStack)
local m_kProposalTitleIM = InstanceManager:new("ProposalTitle", "Root",
                                               Controls.ResolutionStack)
local m_kReviewResolutionIM = InstanceManager:new("ReviewResolution", "Root",
                                                  Controls.ReviewResolutionStack)
local m_kReviewOutcomeIM = InstanceManager:new("ReviewOutcome", "Root")
local m_kReviewProposalIM = InstanceManager:new("ReviewProposal", "Root",
                                                Controls.ReviewProposalStack)
local m_kEmergencyProposalIM = InstanceManager:new("EmergencyProposalItem",
                                                   "Root",
                                                   Controls.ReviewProposalStack)
local m_ProposalVoterIM = InstanceManager:new("ProposalVoter", "Root")
local m_ResolutionVoterIM = InstanceManager:new("ResolutionVoter", "Root")
local m_VerticalPaddingReviewIM = InstanceManager:new("VerticalPaddingReview",
                                                      "Root")
local m_VerticalPaddingSmallIM = InstanceManager:new("VerticalPadding1px",
                                                     "Root")
local m_kActivePulldown

-- ===========================================================================
--	Checks the current turn segment and opens World Congress if necessary
-- ===========================================================================
function CheckShouldOpen()
    local turnSegment = Game.GetCurrentTurnSegment()
    if turnSegment == WORLD_CONGRESS_STAGE_1 then
        SetupWorldCongress(1)
    elseif turnSegment == WORLD_CONGRESS_STAGE_2 then
        SetupWorldCongress(2)
    end
end

-- ===========================================================================
-- Opens the popup
-- ===========================================================================
function SetupWorldCongress(stageNum, beginCongress)
    -- Account for AutoPlay
    if Game.GetLocalPlayer() < 0 then return end

    if SetStage(stageNum, beginCongress) then
        ShowPopup()
    else
        ClosePopup()
    end
end

-- ===========================================================================
-- Opens the DiplomacyActionView on the chosen player (if any)
-- ===========================================================================
function OpenDiplomacyLiteMode(playerID)
    if m_IsInSession then
        LuaEvents.WorldCongress_OpenDiplomacyActionViewLite(playerID)
    else
        LuaEvents.WorldCongress_OpenDiplomacyActionView(playerID)
    end
end

-- ===========================================================================
--	Defines the sizes and bounds of the data container
-- ===========================================================================
function RealizeSize(screenX, screenY)
    local bannerSize = Controls.CongressMembers:GetSizeX() +
                           Controls.CongressMembers:GetOffsetX()
    local dataSize
    if screenX < 1366 then
        dataSize = 1024 - Controls.CongressMembers:GetSizeX()
    elseif screenX < 1920 then
        dataSize = 1366 - Controls.CongressMembers:GetSizeX()
    else
        dataSize = 1640 - Controls.CongressMembers:GetSizeX()
    end

    Controls.TitleContainer:SetSizeX(dataSize)
    Controls.TitleContainer:SetOffsetX(bannerSize)
    Controls.Description:SetWrapWidth(dataSize - 60)
    Controls.DataContainer:SetSizeX(dataSize)
    Controls.DataContainer:SetOffsetX(bannerSize)
    Controls.DataContainer:SetSizeY(screenY -
                                        Controls.DataContainer:GetOffsetY())
    Controls.ButtonStack:SetOffsetX(bannerSize * 0.5)

    Controls.LaunchBacking:SetSizeX(Controls.TabBar:GetSizeX() + 144)
    Controls.LaunchBackingTile:SetSizeX(Controls.TabBar:GetSizeX() + 10)
    Controls.LaunchBarDropShadow:SetSizeX(Controls.TabBar:GetSizeX())

    local descriptionSizeY = Controls.DescriptionContainer:GetSizeY()
    Controls.DescriptionBG:SetOffsetX(bannerSize)
    Controls.DescriptionBG:SetSizeY(descriptionSizeY)

    local dataSizeY = Controls.DataContainer:GetSizeY() - descriptionSizeY -
                          (m_CurrentStage ~= 4 and 72 or 114)
    Controls.ReviewBG:SetSizeY(dataSizeY)
    Controls.ResolutionBG:SetSizeY(dataSizeY)
    Controls.ReviewScroll:SetSizeY(dataSizeY)
    Controls.ResolutionScroll:SetSizeY(dataSizeY)
    Controls.DataStack:CalculateSize()

    local maxTitleWidth = (dataSize / 2) + 170 -
                              Controls.WorkingFavor:GetSizeX()
    TruncateStringWithTooltip(Controls.Title, maxTitleWidth,
                              Controls.Title:GetText())
end

-- ===========================================================================
-- Shows and hides content relevant to the current stage
-- ===========================================================================
function SetStage(stageNum, beginCongress)

    local prevIsInSession = m_IsInSession
    local prevIsEmergencySession = m_IsEmergencySession

    m_HasAccepted = false
    m_CurrentStage = stageNum
    m_IsInSession = stageNum ~= 4
    m_IsEmergencySession = stageNum == 2

    if m_IsInSession then m_HasSpecialSessionNotification = false end

    m_kProposalVotes = m_kProposalVotes or {}
    m_kResolutionVotes = m_kResolutionVotes or {}
    m_kResolutionChoices = m_kResolutionChoices or {}
    m_StartingFavor = Players[Game.GetLocalPlayer()]:GetFavor()
    UpdateWorkingFavor()

    Controls.ReviewScroll:SetScrollValue(0)
    Controls.ResolutionScroll:SetScrollValue(0)

    Controls.ReviewContainer:SetHide(stageNum ~= 4)
    Controls.ReviewTabsContainer:SetHide(stageNum ~= 4)
    Controls.ResolutionContainer:SetHide(stageNum >= 3)

    if stageNum == 1 then
        Controls.Title:SetText(Locale.Lookup("LOC_WORLD_CONGRESS_TITLE"))
        return beginCongress and
                   SetPhase(m_CurrentPhase > 0 and m_CurrentPhase or 1)
    elseif stageNum == 2 then
        Controls.Title:SetText(Locale.Lookup(
                                   "LOC_WORLD_CONGRESS_SPECIAL_SESSION_TITLE"))
        Controls.Description:SetText(Locale.Lookup(
                                         "LOC_WORLD_CONGRESS_SPECIAL_SESSION_INSTRUCTIONS"))
        return beginCongress and
                   SetPhase(m_CurrentPhase > 0 and m_CurrentPhase or 1)
    elseif stageNum == 3 then
        UI.DataError("World Congress Stage 3 is deprecated, assign @sbatista")
        return false
    elseif stageNum == 4 then

        Controls.ReviewResolutionTitle:SetHide(true)

        if prevIsInSession then
            Controls.Title:SetText(Locale.Lookup(
                                       prevIsEmergencySession and
                                           "LOC_WORLD_CONGRESS_SPECIAL_SESSION_END" or
                                           "LOC_WORLD_CONGRESS_END"))
        else
            Controls.Title:SetText(Locale.Lookup(
                                       "LOC_WORLD_CONGRESS_NOT_IN_SESSION"))
        end

        local pCongressMeetingData = Game.GetWorldCongress():GetMeetingStatus()
        local turnsToNextCongress = pCongressMeetingData.TurnsLeft + 1
        Controls.EmptyLabel:SetText(Locale.Lookup("LOC_WORLD_CONGRESS_EMPTY",
                                                  turnsToNextCongress))

        if m_ReviewTab == REVIEW_TAB_AVAILABLE_PROPOSALS and
            HasEmergencyProposals() then
            UI.PlaySound("WC_Open")
            Controls.Description:SetText(
                Locale.Lookup(m_HasSpecialSessionNotification and
                                  "LOC_NOTIFICATION_WORLD_CONGRESS_SPECIAL_SESSION_BLOCKING_SUMMARY" or
                                  "LOC_WORLD_CONGRESS_AVAILABLE_PROPOSALS_DESCRIPTION"))
            PopulateEmergencyProposals()
        elseif m_ReviewTab == REVIEW_TAB_CURRENT_EFFECTS then
            UI.PlaySound("WC_Open")
            Controls.Description:SetText(
                Locale.Lookup("LOC_WORLD_CONGRESS_EFFECTS_DESCRIPTION"))
            PopulateActiveEffects()
        elseif m_ReviewTab == REVIEW_TAB_RESULTS then
            UI.PlaySound("WC_Open")
            Controls.Description:SetText(
                Locale.Lookup("LOC_WORLD_CONGRESS_RESULTS_DESCRIPTION",
                              turnsToNextCongress))
            PopulateReview()
        else
            UI.DataError("Invalid review tab '" .. tostring(m_ReviewTab) .. "'")
            return false
        end
    else
        UI.DataError("Invalid stage '" .. tostring(stageNum) ..
                         "', it should be 1,2 or 4")
        return false
    end

    -- If we reach this code, it means congress is not in session (it returns early if stage is 1 - 3)
    -- The EmptyLabel should only show when Congress is not in session and there is no review data
    Controls.EmptyLabel:SetShow(
        m_ReviewTab ~= REVIEW_TAB_AVAILABLE_PROPOSALS and
            m_kReviewResolutionIM.m_iAllocatedInstances == 0 and
            m_kReviewProposalIM.m_iAllocatedInstances == 0)
    Controls.DescriptionBG:SetHide(not m_IsInSession or m_CurrentPhase ~=
                                       PHASE_STEP_MAX)

    UpdateNavButtons()
    return true
end

-- ===========================================================================
-- Shows and hides content relevant to the current phase
-- ===========================================================================
function SetPhase(phaseNum)
    if phaseNum < 0 or phaseNum > PHASE_STEP_MAX then
        UI.DataError("Invalid phase '" .. phaseNum ..
                         "', it should be between 1 and " .. PHASE_STEP_MAX)
        return false
    end

    m_VerticalPaddingSmallIM:ResetInstances()
    m_CurrentPhase = phaseNum

    Controls.ResolutionContainer:SetHide(phaseNum ~= 1)

    if phaseNum == 1 then
        Controls.Description:SetText(Locale.Lookup(
                                         m_CurrentStage == 1 and
                                             "LOC_WORLD_CONGRESS_VOTE_NORMAL_SESSION_DESCRIPTION" or
                                             "LOC_WORLD_CONGRESS_VOTE_SPECIAL_SESSION_DESCRIPTION"))
        if m_CurrentStage == 1 then
            PopulateResolutions()
        else
            m_kResolutionsTitle = nil
            m_kProposalTitleIM:ResetInstances()
            m_kResolutionItemIM:ResetInstances()
        end
        PopulateProposals()

        if HasChoices() then
            m_VerticalPaddingSmallIM:GetInstance(Controls.ResolutionStack)
        else
            UI.RequestPlayerOperation(Game.GetLocalPlayer(),
                                      PlayerOperations.WORLD_CONGRESS_SUBMIT_TURN,
                                      {})
            UI.RequestAction(ActionTypes.ACTION_ENDTURN)

            if not GameConfiguration.IsHotseat() then
                LuaEvents.WorldCongressPopup_ShowWorldCongressBetweenTurns(
                    m_CurrentStage)
            end
            return false
        end
    elseif phaseNum == 2 then
        Controls.Description:SetText(Locale.Lookup(
                                         m_CurrentStage == 1 and
                                             "LOC_WORLD_CONGRESS_SUBMIT_PROPOSALS_CONFIRM" or
                                             "LOC_WORLD_CONGRESS_SPECIAL_SESSION_CONFIRM"))
        Controls.ReviewContainer:SetHide(false)
        PopulateSummary()
    end

    -- Set Phase only gets called when congress is in session - hide it
    Controls.EmptyLabel:SetHide(true)
    UpdateNavButtons()
    return true
end

-- ===========================================================================
--	Can the player do something?
-- ===========================================================================
function HasChoices()
    if not m_IsInSession then return HasEmergencyProposals() end
    return m_kResolutionItemIM.m_iAllocatedInstances ~= 0 or
               m_kProposalItemIM.m_iAllocatedInstances ~= 0
end

-- ===========================================================================
--	Is the player allowed to progress in navigation?
-- ===========================================================================
function CanMoveToNextPhase()
    for _, kVoteData in pairs(m_kResolutionVotes) do
        local choiceData = m_kResolutionChoices[kVoteData.Hash]
        if (kVoteData.A.votes + kVoteData.B.votes) <= 0 or not choiceData or
            (choiceData.choice < 0 or choiceData.target < 0) then
            return false
        end
    end

    for _, kVoteData in pairs(m_kProposalVotes) do
        if kVoteData.votes == 0 and
            not (kVoteData.voteBlocker and kVoteData.voteBlocker.NoUpvote and
                kVoteData.voteBlocker.NoDownvote) then return false end
    end

    -- Can not progress while the game is paused.
    if (GameConfiguration.IsPaused()) then return false end

    return m_CurrentPhase < PHASE_STEP_MAX
end

-- ===========================================================================
--	Is the player allowed to submit their choices? Stage 3 only
-- ===========================================================================
function CanSubmit()
    if m_CurrentStage == 4 and m_ReviewTab == REVIEW_TAB_AVAILABLE_PROPOSALS then
        if table.count(m_kProposalVotes) > 0 then
            for _, kVoteData in pairs(m_kProposalVotes) do
                if kVoteData.votes ~= 0 and not kVoteData.disabled then
                    return true
                end
            end
            return false
        else
            return m_CurrentStage ~= 4
        end
    end
    return true
end

-- ===========================================================================
-- Updates the running total of favor for the player
-- ===========================================================================
function UpdateWorkingFavor()
    local totalCost = 0

    for _, kResolutionVote in pairs(m_kResolutionVotes) do
        totalCost = totalCost + kResolutionVote.A.cost + kResolutionVote.B.cost
    end

    if m_kResolutionsTitle then
        m_kResolutionsTitle.Cost:SetText(
            Locale.Lookup("LOC_WORLD_CONGRESS_CATEGORY_FAVOR", totalCost))
        m_kResolutionsTitle.Cost:SetToolTipString(
            Locale.Lookup(
                "LOC_WORLD_CONGRESS_TT_RESOLUTIONS_FAVOR_COST_WITH_REFUND",
                totalCost))

    end

    for _, kProposalVote in pairs(m_kProposalVotes) do
        if not kProposalVote.disabled then
            totalCost = totalCost + kProposalVote.cost
        end
    end

    m_WorkingFavor = m_StartingFavor - totalCost
    Controls.WorkingFavor:SetText(Locale.Lookup(
                                      "LOC_WORLD_CONGRESS_FAVOR_TITLE",
                                      m_WorkingFavor))
    Controls.WorkingFavor:SetToolTipString(
        Locale.Lookup("LOC_WORLD_CONGRESS_TT_PLAYER_FAVOR_TO_SPEND"))
end

-- ===========================================================================
-- Updates State of Navigation Buttons
-- ===========================================================================
function UpdateNavButtons()
    Controls.PrevButton:SetHide(m_CurrentStage >= 3 or m_CurrentPhase == 1)

    local canNextPhase = CanMoveToNextPhase()
    local nextButtonTT = ""
    if (GameConfiguration.IsPaused()) then
        nextButtonTT = Locale.Lookup("LOC_WORLD_CONGRESS_TT_GAME_PAUSED")
    elseif (not canNextPhase) then
        nextButtonTT = Locale.Lookup("LOC_WORLD_CONGRESS_TT_SELECT_ALL")
    end
    Controls.NextButton:SetHide(m_CurrentStage >= 3 or m_CurrentPhase ==
                                    PHASE_STEP_MAX)
    Controls.NextButton:SetDisabled(not canNextPhase)
    Controls.NextButton:SetToolTipString(nextButtonTT)

    if m_CurrentStage == 4 then
        local hasChoices = HasEmergencyProposalChoices()
        Controls.ReturnButton:SetShow(m_ReviewTab ~=
                                          REVIEW_TAB_AVAILABLE_PROPOSALS)
        Controls.AcceptButton:SetShow(hasChoices and m_ReviewTab ==
                                          REVIEW_TAB_AVAILABLE_PROPOSALS)
        Controls.PassButton:SetShow(hasChoices and
                                        m_HasSpecialSessionNotification and
                                        m_ReviewTab ==
                                        REVIEW_TAB_AVAILABLE_PROPOSALS)

        local hasProposals = HasEmergencyProposals()
        Controls.AvailableProposalsButton:SetHide(not hasProposals)
        Controls.AvailableProposalsButton:SetToolTipString(
            hasProposals and "" or
                Locale.Lookup("LOC_WORLD_CONGRESS_NO_AVAILABLE_PROPOSALS_TT"))

        Controls.LastResultsSelected:SetHide(m_ReviewTab ~= REVIEW_TAB_RESULTS)
        Controls.CurrentEffectsSelected:SetHide(
            m_ReviewTab ~= REVIEW_TAB_CURRENT_EFFECTS)
        Controls.AvailableProposalsSelected:SetHide(
            m_ReviewTab ~= REVIEW_TAB_AVAILABLE_PROPOSALS)
    else
        Controls.AcceptButton:SetShow(m_CurrentPhase == PHASE_STEP_MAX)
        Controls.ReturnButton:SetShow(false)
        Controls.PassButton:SetShow(false)
    end

    if Controls.AcceptButton:IsVisible() then
        Controls.AcceptButton:SetDisabled(not CanSubmit())
        Controls.AcceptButton:SetToolTipString(
            Controls.AcceptButton:IsDisabled() and
                Locale.Lookup("LOC_WORLD_CONGRESS_TT_SELECT_ONE") or "")
        Controls.AcceptButton:SetText(Locale.Lookup(
                                          m_HasSpecialSessionNotification and
                                              "LOC_WORLD_CONGRESS_ADD_PROPOSALS" or
                                              "LOC_WORLD_CONGRESS_SUBMIT"))
    end
end

-- ===========================================================================
--	Populates the side bar with the sequence of congress actions we need to
--	address
-- ===========================================================================
function PopulateLeaderStack()

    local kIsUniqueLeader = {}
    local localPlayerID = Game.GetLocalPlayer()
    local aPlayers = PlayerManager.GetAliveMajors()
    local pDiplomacy = Players[localPlayerID]:GetDiplomacy()

    m_kLeaderButtonIM:ResetInstances()

    for _, pPlayer in ipairs(aPlayers) do
        local playerID = pPlayer:GetID()
        local pPlayerConfig = PlayerConfigurations[playerID]
        local isLocalPlayer = playerID == localPlayerID
        local hasMetPlayer = isLocalPlayer or pDiplomacy:HasMet(playerID)
        local instance = m_kLeaderButtonIM:GetInstance()
        local uiLeaderIcon = LeaderIcon:AttachInstance(instance.Icon)

        if hasMetPlayer or
            (GameConfiguration.IsAnyMultiplayer() and pPlayerConfig:IsHuman()) then
            local leaderName = pPlayerConfig:GetLeaderTypeName()
            if (kIsUniqueLeader[leaderName] == nil) then
                kIsUniqueLeader[leaderName] = true
            else
                kIsUniqueLeader[leaderName] = false
            end

            uiLeaderIcon:RegisterCallback(Mouse.eLClick, function()
                if playerID == localPlayerID or
                    Players[localPlayerID]:GetDiplomacy():HasMet(playerID) then
                    OpenDiplomacyLiteMode(playerID)
                end
            end)

            if hasMetPlayer then
                local favor = m_CurrentStage == 4 and pPlayer:GetFavor() or
                                  pPlayer:GetFavorEnteringCongress()
                instance.FavorLabel:SetText(
                    Locale.Lookup("LOC_WORLD_CONGRESS_FAVOR", favor))
                instance.FavorLabel:SetToolTipString(
                    Locale.Lookup(playerID == localPlayerID and
                                      "LOC_WORLD_CONGRESS_TT_PLAYER_FAVOR" or
                                      "LOC_WORLD_CONGRESS_TT_LEADER_FAVOR",
                                  favor))
                instance.FavorContainer:SetHide(false)
                --[[ CUI: use tooltip instead
        local grievanceTT = "";
        local grievances = pDiplomacy:GetGrievancesAgainst(playerID);
        if grievances > 0 then
          instance.GrievanceLabel:SetText(Locale.Lookup("LOC_WORLD_CONGRESS_GRIEVANCE_VALUE", grievances));
          instance.GrievanceLabel:SetToolTipString(Locale.Lookup("LOC_WORLD_CONGRESS_GRIEVANCE_DEFINITION", grievances));
          instance.GrievanceContainer:SetHide(false);
        else
          instance.GrievanceLabel:SetText("");
          instance.GrievanceContainer:SetHide(true);
        end
        ]]
            else
                instance.FavorContainer:SetHide(true)
                -- instance.GrievanceContainer:SetHide(true); -- CUI
            end
            instance.GrievanceContainer:SetHide(true) -- CUI

            local icon = (isLocalPlayer or pDiplomacy:HasMet(playerID)) and
                             "ICON_" .. leaderName or "ICON_LEADER_DEFAULT"
            uiLeaderIcon:UpdateIcon(icon, playerID, kIsUniqueLeader[leaderName],
                                    grievanceTT)
        else
            instance.FavorLabel:SetText("")
            instance.GrievanceLabel:SetText("")
            instance.FavorContainer:SetHide(true)
            instance.GrievanceContainer:SetHide(true)
            uiLeaderIcon:UpdateIcon("ICON_LEADER_DEFAULT", playerID)
        end

        -- CUI: use advanced tooltip
        local allianceData = CuiGetAllianceData(playerID)
        LuaEvents.CuiLeaderIconToolTip(uiLeaderIcon.Controls.Portrait, playerID)
        LuaEvents.CuiRelationshipToolTip(uiLeaderIcon.Controls.Relationship,
                                         playerID, allianceData)
        --
    end
end

function PopulateBG()

    m_kLeaderBGItemIM:ResetInstances()

    local counter = 0
    local localPlayerID = Game.GetLocalPlayer()
    local aPlayers = PlayerManager.GetAliveMajors()
    local numPlayers = PlayerManager.GetAliveMajorsCount()
    local pDiplomacy = Players[localPlayerID]:GetDiplomacy()

    local width = UIManager:GetScreenSizeVal()
    local dataWidth = Controls.DataContainer:GetSizeX() +
                          (Controls.CongressMembers:GetSizeX() - 6)
    local leftWidth = (width / 2) - (dataWidth / 2)
    local rightWidth = width - (leftWidth + Controls.CongressMembers:GetSizeX())
    local numLeftBanners = math.ceil(leftWidth / 380)
    local numRightBanners = math.ceil(rightWidth / 380)

    -- Populate BG Stack to the Left of CongressMembers
    local i = 1
    while i <= numLeftBanners do
        if AddBGElement(aPlayers, (counter % numPlayers) + 1, Controls.BGLeft) then
            i = i + 1
        end
        counter = counter + 1
    end
    Controls.BGLeft:SetOffsetX(width - leftWidth)

    -- Populate BG Stack to the Right of CongressMembers
    i = 1
    while i <= numRightBanners do
        if AddBGElement(aPlayers, (counter % numPlayers) + 1, Controls.BGRight) then
            i = i + 1
        end
        counter = counter + 1
    end
    Controls.BGRight:SetOffsetX(leftWidth + Controls.CongressMembers:GetSizeX())
end

function AddBGElement(aPlayers, aPlayersIndex, parentControl)
    local localPlayerID = Game.GetLocalPlayer()
    local pDiplomacy = Players[localPlayerID]:GetDiplomacy()
    local playerID = aPlayers[aPlayersIndex]:GetID()
    if playerID == localPlayerID or pDiplomacy:HasMet(playerID) then
        local instance = m_kLeaderBGItemIM:GetInstance(parentControl)

        if m_IsInSession then
            local civIconManager = CivilizationIcon:AttachInstance(instance)
            civIconManager:UpdateIconFromPlayerID(playerID)
        end
        instance.CivIconBG:SetShow(m_IsInSession)
        instance.CivIconBacking:SetShow(m_IsInSession)

        local screenHeight = parentControl:GetSizeY()
        local centerY = (screenHeight / 2) - 489
        instance.Center:SetOffsetY(centerY)
        instance.Top:SetOffsetY(screenHeight - centerY)
        instance.Top:SetSizeY(centerY > 0 and centerY or 1)
        instance.Bottom:SetOffsetY((screenHeight / 2) + 489)
        instance.Bottom:SetSizeY(centerY > 0 and centerY or 1)

        instance.Top:SetTexture(m_IsInSession and
                                    (m_IsEmergencySession and
                                        "WC_BGBannerTop_Special" or
                                        "WC_BGBannerTop_Normal") or
                                    "WC_BGBannerTop_NoSession")
        instance.Center:SetTexture(m_IsInSession and
                                       (m_IsEmergencySession and
                                           "WC_BGBanner_Special" or
                                           "WC_BGBanner_Normal") or
                                       "WC_BGBanner_NoSession")
        instance.Bottom:SetTexture(m_IsInSession and "WC_BGBannerBottom" or
                                       "WC_BGBannerBottom_NoSession")
        return true
    end
    return false
end

-- ===========================================================================
--	Populates resolutions (stage 1 & 2, phase 1)
-- ===========================================================================
function PopulateResolutions()
    local focusStop = 0
    local localPlayerID = Game.GetLocalPlayer()
    local pDiplomacy = Players[localPlayerID]:GetDiplomacy()
    local pWorldCongress = Game.GetWorldCongress()
    local kResolutions = pWorldCongress:GetResolutions(localPlayerID)
    local kCostData = pWorldCongress:GetVotesandFavorCost(localPlayerID)

    m_kProposalTitleIM:ResetInstances()
    m_kResolutionItemIM:ResetInstances()

    for i, kResolutionData in pairs(kResolutions) do
        if type(i) == "number" then -- There's a "Stage" key kResolutions
            if m_kProposalTitleIM.m_iAllocatedInstances == 0 then
                m_kResolutionsTitle = m_kProposalTitleIM:GetInstance(
                                          Controls.ResolutionStack)
                m_kResolutionsTitle.Title:SetText(
                    Locale.ToUpper(Locale.Lookup(
                                       "LOC_WORLD_CONGRESS_RESULTS_WORLD_EVENT_RESOLUTIONS")))
                m_kResolutionsTitle.Icon:SetIcon("ICON_STAT_RESOLUTIONS")
                UpdateWorkingFavor()
            end

            local instance = m_kResolutionItemIM:GetInstance()
            local kResolution = GameInfo.Resolutions[kResolutionData.Type]
            local kVoteData = m_kResolutionVotes[i]
            if not kVoteData then
                local makeData = function(choice)
                    return {
                        kResolutionData = kResolutionData,
                        data = kResolution,
                        instance = instance,
                        votes = DEBUG_DATA and choice - 1 or 0,
                        cost = 0,
                        choice = choice
                    }
                end
                kVoteData = {
                    A = makeData(1),
                    B = makeData(2),
                    Hash = kResolution.Hash
                }
                m_kResolutionVotes[i] = kVoteData
            else -- Refresh instance to support hot reload
                kVoteData.A.instance = instance
                kVoteData.B.instance = instance
            end

            UpdateVotingWidget(instance.Vote1, kVoteData.A, kCostData,
                               TestResolutionVote, 1)
            instance.Vote1.UpButton:RegisterCallback(Mouse.eLClick,
                                                     OnVoteResolution(1,
                                                                      UP_VOTE,
                                                                      kVoteData.A,
                                                                      kCostData))
            instance.Vote1.DownButton:RegisterCallback(Mouse.eLClick,
                                                       OnVoteResolution(1,
                                                                        DOWN_VOTE,
                                                                        kVoteData.A,
                                                                        kCostData))

            UpdateVotingWidget(instance.Vote2, kVoteData.B, kCostData,
                               TestResolutionVote, 2)
            instance.Vote2.UpButton:RegisterCallback(Mouse.eLClick,
                                                     OnVoteResolution(2,
                                                                      UP_VOTE,
                                                                      kVoteData.B,
                                                                      kCostData))
            instance.Vote2.DownButton:RegisterCallback(Mouse.eLClick,
                                                       OnVoteResolution(2,
                                                                        DOWN_VOTE,
                                                                        kVoteData.B,
                                                                        kCostData))
            EvaluateResolutionHistory(pWorldCongress, kResolutionData, instance)

            instance.Choice1Container:SetSizeY(
                kResolutionData.TargetType == "PlayerType" and 65 or 30)
            instance.Choice2Container:SetSizeY(
                kResolutionData.TargetType == "PlayerType" and 65 or 30)

            if table.count(kResolutionData.FavoredPlayerIDs) > 0 then
                local favoredTT = ""
                for _, playerID in pairs(kResolutionData.FavoredPlayerIDs) do
                    if favoredTT ~= "" then
                        favoredTT = favoredTT .. "[NEWLINE]"
                    end
                    favoredTT = favoredTT .. GetVisiblePlayerName(playerID)
                end
                instance.FavoredLabel:SetText(
                    table.count(kResolutionData.FavoredPlayerIDs))
                instance.FavoredContainer:SetToolTipString(
                    Locale.Lookup("LOC_WORLD_CONGRESS_PREFERRED_VOTES_TT",
                                  favoredTT))
                instance.FavoredContainer:SetHide(false)
            else
                instance.FavoredContainer:SetHide(true)
            end

            if table.count(kResolutionData.DisfavoredPlayerIDs) > 0 then
                local disfavotedTT = ""
                for _, playerID in pairs(kResolutionData.DisfavoredPlayerIDs) do
                    if disfavotedTT ~= "" then
                        disfavotedTT = disfavotedTT .. "[NEWLINE]"
                    end
                    disfavotedTT = disfavotedTT ..
                                       GetVisiblePlayerName(playerID)
                end
                instance.DisfavoredLabel:SetText(
                    table.count(kResolutionData.DisfavoredPlayerIDs))
                instance.DisfavoredContainer:SetToolTipString(
                    Locale.Lookup("LOC_WORLD_CONGRESS_PREFERRED_VOTES_TT",
                                  disfavotedTT))
                instance.DisfavoredContainer:SetHide(false)
            else
                instance.DisfavoredContainer:SetHide(true)
            end

            -- Populate choices
            local kResolutionChoice = m_kResolutionChoices[kResolution.Hash]
            if not kResolutionChoice then
                kResolutionChoice = {
                    instance = instance,
                    hash = kResolution.Hash,
                    choice = DEBUG_DATA and 1 or -1,
                    target = DEBUG_DATA and 1 or -1
                }
                m_kResolutionChoices[kResolution.Hash] = kResolutionChoice
            else
                kResolutionChoice.instance = instance -- Refresh instance to support hot reload
            end
            UpdateResolutionChoice(kResolutionChoice)

            -- Title
            instance.Title:SetText(Locale.ToUpper(
                                       Locale.Lookup(kResolution.Name)))

            -- Icon
            instance.Icon:SetIcon(kResolution.Icon and kResolution.Icon or
                                      "ICON_PROPOSAL_RESOLUTION")

            -- A/B Effects
            instance.Effect1:SetText(Locale.Lookup(
                                         kResolution.Effect1Description))
            instance.Effect2:SetText(Locale.Lookup(
                                         kResolution.Effect2Description))
        end
    end
end

-- ===========================================================================
-- Build the tooltip describing the previous time this resolution appeared
-- in World Congress, if it has shown up before.
-- ===========================================================================
function EvaluateResolutionHistory(pWorldCongress, kResolutionData,
                                   uiResolutionInstance)
    if pWorldCongress == nil then
        UI.DataError(
            "World Congress is nil. Something has gone incredibly wrong when Evaluating Resolution History.")
        return
    end

    -- Get the stats for the last time this resolution was seen
    if kResolutionData ~= nil then
        local kPreviousResolutionData =
            pWorldCongress:GetPreviousVotesOnResolution(kResolutionData.Type)
        if kPreviousResolutionData == nil then
            uiResolutionInstance.MoreInfoButton:SetHide(true)
            uiResolutionInstance.MoreInfoButton:SetToolTipString("")
            return
        end

        uiResolutionInstance.MoreInfoButton:SetHide(false)

        -- Our data format for evaluation
        local kEvaluationData = {
            aVotes = 0,
            bVotes = 0,
            aVoters = 0,
            bVoters = 0,
            soleAPlayerID = -1,
            soleBPlayerID = -1,
            biggestAVotes = 0,
            biggestBVotes = 0,
            biggestAVoter = -1,
            biggestBVoter = -1
        }

        -- Generate data
        for playerID, kData in pairs(kPreviousResolutionData.PlayerSelections) do
            if kData.OptionChosen == 1 then
                kEvaluationData.aVotes = kEvaluationData.aVotes + kData.Votes
                kEvaluationData.aVoters = kEvaluationData.aVoters + 1
                kEvaluationData.soleAPlayerID = playerID
                if kData.Votes > kEvaluationData.biggestAVotes then
                    kEvaluationData.biggestAVotes = kData.Votes
                    kEvaluationData.biggestAVoter = playerID
                end
            else
                kEvaluationData.bVotes = kEvaluationData.bVotes + kData.Votes
                kEvaluationData.bVoters = kEvaluationData.bVoters + 1
                kEvaluationData.soleBPlayerID = playerID
                if kData.Votes > kEvaluationData.biggestBVotes then
                    kEvaluationData.biggestBVotes = kData.Votes
                    kEvaluationData.biggestBVoter = playerID
                end
            end
        end

        -- Go through all of our evaluators and append to the tooltip string
        local chosenThingString = Locale.Lookup(
                                      kPreviousResolutionData.ChosenThing)
        if kPreviousResolutionData.TargetType == "PlayerType" then
            local playerID = tonumber(kPreviousResolutionData.ChosenThing)
            if playerID ~= PlayerTypes.NONE and playerID ~= PlayerTypes.OBSERVER then
                chosenThingString = GetVisiblePlayerName(playerID)
            end
        end
        local tooltipString =
            kEvaluationData.aVotes > kEvaluationData.bVotes and
                Locale.Lookup("LOC_WORLD_CONGRESS_PREVIOUS_TOOLTIP_A_WON",
                              chosenThingString) or
                Locale.Lookup("LOC_WORLD_CONGRESS_PREVIOUS_TOOLTIP_B_WON",
                              chosenThingString)
        for _, evaluate in pairs(m_kPreviousTooltipEvaluators) do
            tooltipString = tooltipString .. evaluate(kEvaluationData)
        end

        uiResolutionInstance.MoreInfoButton:SetToolTipString(tooltipString)
    else
        UI.DataError(
            "Resolution Data is nil! World Congress unable to evaluate Resolution History")
        return
    end
end

-- ===========================================================================
function EvaluateTiebroken(kEvaluationData)
    -- Evaluate if the last round was decided by tiebreaker
    return kEvaluationData.aVotes == kEvaluationData.bVotes and "[NEWLINE]" ..
               Locale.Lookup("LOC_WORLD_CONGRESS_PREVIOUS_TOOLTIP_WAS_TIE") or
               ""
end

-- ===========================================================================
function EvaluateSoleVoter(kEvaluationData)
    -- Did a category only have a single voter?
    local soleVoterString = ""

    if kEvaluationData.aVoters == 1 then
        soleVoterString = soleVoterString .. "[NEWLINE]" ..
                              Locale.Lookup(
                                  "LOC_WORLD_CONGRESS_PREVIOUS_TOOLTIP_A_SOLE_VOTE",
                                  GetVisiblePlayerName(
                                      kEvaluationData.soleAPlayerID))
    end

    if kEvaluationData.bVoters == 1 then
        soleVoterString = soleVoterString .. "[NEWLINE]" ..
                              Locale.Lookup(
                                  "LOC_WORLD_CONGRESS_PREVIOUS_TOOLTIP_B_SOLE_VOTE",
                                  GetVisiblePlayerName(
                                      kEvaluationData.soleBPlayerID))
    end

    return soleVoterString
end

-- ===========================================================================
function EvaluateNeckAndNeck(kEvaluationData)
    -- Evaluate if the voting was close
    local voteDelta = math.abs(kEvaluationData.aVotes - kEvaluationData.bVotes)
    local voteMargin = voteDelta /
                           math.ceil(kEvaluationData.aVotes,
                                     kEvaluationData.bVotes)

    if voteMargin <= GlobalParameters.WORLD_CONGRESS_NEARLY_TIED_RANGE / 100 then
        return "[NEWLINE]" ..
                   (kEvaluationData.aVotes > kEvaluationData.bVotes and
                       Locale.Lookup(
                           "LOC_WORLD_CONGRESS_PREVIOUS_TOOLTIP_NECK_AND_NECK_A") or
                       Locale.Lookup(
                           "LOC_WORLD_CONGRESS_PREVIOUS_TOOLTIP_NECK_AND_NECK_B"))
    end

    return ""
end

-- ===========================================================================
function EvaluateUnanimous(kEvaluationData)
    -- Was the decision unanimous?
    if kEvaluationData.aVoters > 0 and kEvaluationData.bVoters == 0 then
        return "[NEWLINE]" ..
                   Locale.Lookup(
                       "LOC_WORLD_CONGRESS_PREVIOUS_TOOLTIP_UNANIMOUS_A")
    end

    if kEvaluationData.aVoters == 0 and kEvaluationData.bVoters > 0 then
        return "[NEWLINE]" ..
                   Locale.Lookup(
                       "LOC_WORLD_CONGRESS_PREVIOUS_TOOLTIP_UNANIMOUS_B")
    end

    return ""
end

-- ===========================================================================
function EvaluateMajorityLeader(kEvaluationData)
    -- Was one player outstanding in their contribution?
    local majorityString = ""
    local aVoteMargin = -1
    local bVoteMargin = -1

    if kEvaluationData.aVotes > 0 then
        aVoteMargin = kEvaluationData.biggestAVotes / kEvaluationData.aVotes
    end

    if kEvaluationData.bVotes > 0 then
        bVoteMargin = kEvaluationData.biggestBVotes / kEvaluationData.bVotes
    end

    if aVoteMargin > GlobalParameters.WORLD_CONGRESS_MAJORITY_LEADER_MINIMUM then
        majorityString = majorityString .. "[NEWLINE]" ..
                             Locale.Lookup(
                                 "LOC_WORLD_CONGRESS_PREVIOUS_TOOLTIP_MAJORITY_A",
                                 GetVisiblePlayerName(
                                     kEvaluationData.biggestAVoter))
    end

    if bVoteMargin > GlobalParameters.WORLD_CONGRESS_MAJORITY_LEADER_MINIMUM then
        majorityString = majorityString .. "[NEWLINE]" ..
                             Locale.Lookup(
                                 "LOC_WORLD_CONGRESS_PREVIOUS_TOOLTIP_MAJORITY_B",
                                 GetVisiblePlayerName(
                                     kEvaluationData.biggestBVoter))
    end

    return majorityString
end

-- ===========================================================================
function PopulateChoicePulldown(kResolutionChoice, kVoteData)
    local kResolutionData = kVoteData.kResolutionData
    local instance = kResolutionChoice.choice == 1 and
                         kVoteData.instance.Choice1 or
                         kVoteData.instance.Choice2

    if kResolutionData.TargetType == "PlayerType" then
        instance.Pulldown:SetHide(true)
        instance.PlayerPulldown:SetHide(false)
        instance.PlayerPulldown:GetButton():RegisterCallback(Mouse.eLClick,
                                                             function()
            AssignActivePulldown(instance.PlayerPulldown)
        end)

        local metPlayers, isUniqueLeader = GetMetPlayersAndUniqueLeaders()

        instance.PlayerPulldown:ClearEntries()
        local possibleTargets = kResolutionData.PossibleTargets
        if possibleTargets and table.count(possibleTargets) > 0 then
            for i, v in pairs(possibleTargets) do
                local playerID = tonumber(v)
                local entry = {}
                instance.PlayerPulldown:BuildEntry("InstanceOne", entry)

                entry.Button:SetVoid1(i)
                local text, leaderIcon, civIcon =
                    GetPulldownNameAndIcons(kResolutionData, i)
                entry.Button:SetText(text)

                local civIconManager = CivilizationIcon:AttachInstance(
                                           entry.CivIcon)
                civIconManager:UpdateIconFromPlayerID(playerID)
                local leaderIconManager =
                    LeaderIcon:AttachInstance(entry.LeaderIcon)
                leaderIconManager:UpdateIconSimple(leaderIcon, playerID,
                                                   isUniqueLeader[playerID] or
                                                       false)
            end
            instance.PlayerPulldown:CalculateInternals() -- Is this still necessary? @kjones
        else
            UI.DataError("Resolution choice of Type '" .. kResolution.Type ..
                             "' has no PossibleTargets -  aborting WorldCongress")
        end

        local tmpID = tonumber(kResolutionChoice.target)
        local playerID = tmpID < 0 and -1 or
                             tonumber(kResolutionData.PossibleTargets[tmpID])
        local text, leaderIcon, civIcon =
            GetPulldownNameAndIcons(kResolutionData, kResolutionChoice.target)

        local civIconManager = CivilizationIcon:AttachInstance(instance.CivIcon)
        civIconManager:UpdateIconFromPlayerID(playerID)
        local leaderIconManager = LeaderIcon:AttachInstance(instance.LeaderIcon)
        leaderIconManager:UpdateIconSimple(leaderIcon, playerID,
                                           isUniqueLeader[playerID] or false)

        instance.PlayerPulldown:GetButton():SetText(text)
        instance.PlayerPulldown:GetButton():SetToolTipString(
            Locale.Lookup("LOC_WORLD_CONGRESS_TT_NO_VOTING_DOWN"))
        instance.PlayerPulldown:RegisterSelectionCallback(
            function(i)
                local playerID = tonumber(kResolutionData.PossibleTargets[i])
                kResolutionChoice.target = i
                local text, leaderIcon, civIcon =
                    GetPulldownNameAndIcons(kResolutionData, i)
                instance.PlayerPulldown:GetButton():SetText(text)
                instance.PlayerPulldown:GetButton():SetToolTipString("")

                local civIconManager = CivilizationIcon:AttachInstance(
                                           instance.CivIcon)
                civIconManager:UpdateIconFromPlayerID(playerID)
                local leaderIconManager =
                    LeaderIcon:AttachInstance(instance.LeaderIcon)
                leaderIconManager:UpdateIconSimple(leaderIcon, playerID,
                                                   isUniqueLeader[playerID] or
                                                       false)

                UpdateResolutionChoice(kResolutionChoice)
                UpdateNavButtons()
            end)
    else -- kResolutionData.TargetType ~= "PlayerType"
        instance.Pulldown:SetHide(false)
        instance.PlayerPulldown:SetHide(true)
        instance.Pulldown:GetButton():RegisterCallback(Mouse.eLClick, function()
            AssignActivePulldown(instance.Pulldown)
        end)

        instance.Pulldown:ClearEntries()
        instance.Pulldown:GetButton():SetToolTipString(
            Locale.Lookup("LOC_WORLD_CONGRESS_TT_NO_VOTING_DOWN"))
        -- Dup for sorting and save index order of targets in a reverse lookup table.
        local kSortedTargets = {}
        local kSortedIndex = {}
        local kGameIndexToName = {} -- game core's index to name
        for i, targetName in ipairs(kResolutionData.PossibleTargets) do
            table.insert(kSortedTargets, targetName)
            kSortedIndex[targetName] = i
            kGameIndexToName[i] = targetName
        end

        -- Sort based on name
        table.sort(kSortedTargets, function(a, b)
            return Locale.Lookup(a) < Locale.Lookup(b)
        end)
        if kSortedTargets and table.count(kSortedTargets) > 0 then
            for pulldownIndex, name in ipairs(kSortedTargets) do
                local entry = {}
                instance.Pulldown:BuildEntry("InstanceOne", entry)
                entry.Button:SetVoid1(pulldownIndex)
                entry.Button:SetVoid2(kSortedIndex[name])
                local text = Locale.Lookup(kSortedTargets[pulldownIndex])
                entry.Button:SetText(text)
            end
            instance.Pulldown:CalculateInternals()
        else
            UI.DataError("Resolution choice of Type '" ..
                             kResolution.ResolutionType ..
                             "' has no PossibleTargets")
        end

        if kResolutionChoice.target == nil or kResolutionChoice.target < 0 then
            instance.Pulldown:GetButton():SetText(
                Locale.Lookup("LOC_WORLD_CONGRESS_SELECT_TARGET"))
            instance.Pulldown:GetButton():SetToolTipString(
                Locale.Lookup("LOC_WORLD_CONGRESS_TT_NO_VOTING_DOWN"))
        else
            local gameIndex = kResolutionChoice.target -- Game core's index
            local name = kGameIndexToName[gameIndex] -- sorted index lookup
            instance.Pulldown:GetButton():SetText(Locale.Lookup(name))
            instance.Pulldown:GetButton():SetToolTipString("")
        end

        instance.Pulldown:RegisterSelectionCallback(
            function(pulldownIndex, gameIndex)
                kResolutionChoice.target = gameIndex
                local text = Locale.Lookup(kSortedTargets[pulldownIndex])
                instance.Pulldown:GetButton():SetText(text)
                instance.Pulldown:GetButton():SetToolTipString("")
                UpdateResolutionChoice(kResolutionChoice)
                UpdateNavButtons()
            end)
    end
end

-- ===========================================================================
function GetPulldownNameAndIcons(kResolutionData, index)
    if index == nil or index < 0 then
        return Locale.Lookup("LOC_WORLD_CONGRESS_SELECT_TARGET"),
               "ICON_LEADER_DEFAULT", "ICON_CIVILIZATION_UNKNOWN"
    end

    -- If target type is the player type then either use index to obtain target index or itself is the index:
    if kResolutionData.TargetType == "PlayerType" then
        local playerID = kResolutionData.PossibleTargets and
                             tonumber(kResolutionData.PossibleTargets[index]) or
                             index
        return GetVisiblePlayerNameAndIcons(playerID)
    end

    -- Only returning a name (no icons), the possible targets actually holds unlocalized names.
    return Locale.Lookup(kResolutionData.PossibleTargets[index])
end

-- ===========================================================================
function OnLeaderClicked(playerID)
    -- Send an event to open the leader in the diplomacy view (only if they met)
    local localPlayerID = Game.GetLocalPlayer()
    if playerID == localPlayerID or
        Players[localPlayerID]:GetDiplomacy():HasMet(playerID) then
        LuaEvents.WorldCongress_OpenDiplomacyActionView(playerID)
    end
end

-- ===========================================================================
--	Generate a callback that updates kVoteData according to boxed parameters
-- ===========================================================================
function OnVoteResolution(choice, direction, kVoteData, kCostData, isTest)
    return function()
        local nextVotes = kVoteData.votes + direction
        if nextVotes < 1 or nextVotes > table.count(kCostData) or nextVotes >
            kCostData.MaxVotes then return end

        local nextCost = kCostData[nextVotes - 1]
        local currCost =
            kVoteData.votes > 0 and kCostData[kVoteData.votes - 1] or 0

        if direction < 0 or (nextCost - currCost) <= m_WorkingFavor then
            kVoteData.votes = nextVotes

            if kVoteData.votes == 0 then
                kVoteData.voteDirection = NO_VOTE
                kVoteData.cost = 0
            else
                kVoteData.cost = kCostData[nextVotes > 0 and nextVotes - 1 or 0]
            end
        end

        if not isTest then
            local kChoiceData = m_kResolutionChoices[kVoteData.data.Hash]

            -- Reset target selection if player chooses a different option
            if kChoiceData.choice ~= choice then
                kChoiceData.target = -1
            end

            kChoiceData.choice = choice
            UpdateResolutionChoice(kChoiceData)
            PopulateChoicePulldown(kChoiceData, kVoteData)

            for _, kVoteData in pairs(m_kResolutionVotes) do
                kChoiceData = m_kResolutionChoices[kVoteData.Hash]
                if kChoiceData.choice == 1 then
                    kVoteData.B.votes = 0
                    kVoteData.B.cost = 0
                else
                    kVoteData.A.votes = 0
                    kVoteData.A.cost = 0
                end
            end

            UpdateWorkingFavor()
            UpdateNavButtons()
            UpdateAllVotingWidgets(kCostData)
        end
    end
end

-- ===========================================================================
--	Generates a callback that tests whether a vote is successful
-- ===========================================================================
function TestResolutionVote(choice, direction, kVoteData, kCostData)
    local kCopyData = {votes = kVoteData.votes, cost = kVoteData.cost}
    OnVoteResolution(choice, direction, kCopyData, kCostData, true)()
    return kCopyData.votes ~= kVoteData.votes or kCopyData.cost ~=
               kVoteData.cost
end

-- ===========================================================================
--	Debug helper
-- ===========================================================================
function TableToString(t)
    local s = ""
    if t == nil then return "NIL" end
    for k, v in pairs(t) do
        s = s .. tostring(k) .. " = " .. tostring(v) .. " \n"
    end
    return s
end

-- ===========================================================================
--	Update a voting widget
-- ===========================================================================
function UpdateVotingWidget(instance, kVoteData, kCostData, TestVoteCallback,
                            resolutionChoice)

    if instance == nil then
        local msg = "Unable to UpdateVotingWidget due to nil instance.\n"
        msg = msg .. "=== kVoteData === \n" .. TableToString(kVoteData)
        msg = msg .. "=== kCostData === \n" .. TableToString(kCostData)
        UI.DataError(msg)
        return
    end

    -- Make sure we have a vote direction
    kVoteData.voteDirection = kVoteData.voteDirection and
                                  kVoteData.voteDirection or 1

    local voteIcon = kVoteData.voteDirection < 0 and "[ICON_VOTE_DOWN]" or
                         "[ICON_VOTE_UP]"
    local voteTooltip = Locale.Lookup("LOC_WORLD_CONGRESS_TT_VOTE_COST",
                                      kVoteData.voteDirection < 0 and
                                          "[ICON_VOTE_DOWN]" or "[ICON_VOTE_UP]",
                                      kVoteData.votes, kVoteData.cost)

    instance.Label:SetText(kVoteData.votes == 0 and "0" or
                               (voteIcon .. kVoteData.votes))
    instance.Label:SetToolTipString(voteTooltip)

    -- This check may become unnecessary once we only have 1 voting widget - sbatista
    if instance.Cost then
        instance.Cost:SetText(kVoteData.cost ~= 0 and
                                  Locale.Lookup("LOC_WORLD_CONGRESS_FAVOR",
                                                kVoteData.cost) or "")
        instance.Cost:SetToolTipString(voteTooltip)
    end

    if TestVoteCallback then
        if resolutionChoice then
            instance.UpButton:SetDisabled(
                not TestVoteCallback(resolutionChoice, UP_VOTE, kVoteData,
                                     kCostData))
            instance.DownButton:SetDisabled(
                not TestVoteCallback(resolutionChoice, DOWN_VOTE, kVoteData,
                                     kCostData))
        else
            instance.UpButton:SetDisabled(
                not TestVoteCallback(UP_VOTE, kVoteData, kCostData))
            instance.DownButton:SetDisabled(
                not TestVoteCallback(DOWN_VOTE, kVoteData, kCostData))
        end
    end

    local cost = 0
    local tooltip = ""
    local nextVotes = kVoteData.votes + kVoteData.voteDirection
    if nextVotes < table.count(kCostData) then
        if kVoteData.voteDirection > 0 then
            cost = kCostData[nextVotes > 0 and nextVotes - 1 or 0] -
                       kVoteData.cost
        else
            cost = kVoteData.cost -
                       kCostData[nextVotes > 0 and nextVotes - 1 or 0]
        end
        if cost ~= 0 then
            if instance.UpButton:IsDisabled() then
                tooltip = Locale.Lookup(
                              "LOC_WORLD_CONGRESS_TT_INSUFFICIENT_FAVOR_COST",
                              cost)
            else
                tooltip = Locale.Lookup(kVoteData.voteDirection >= 0 and
                                            "LOC_WORLD_CONGRESS_TT_VOTE_UP" or
                                            "LOC_WORLD_CONGRESS_TT_VOTE_DOWN",
                                        cost)
            end
        end
    end
    instance.UpCost:SetText(cost == 0 and " " or
                                Locale.Lookup("LOC_WORLD_CONGRESS_FAVOR", cost *
                                                  (kVoteData.voteDirection < 0 and
                                                      -1 or 1)))
    instance.UpButton:SetToolTipString(tooltip)

    cost = 0
    tooltip = ""
    local prevVotes = kVoteData.votes - kVoteData.voteDirection
    if prevVotes < table.count(kCostData) then
        if kVoteData.voteDirection > 0 then
            cost = kVoteData.cost -
                       kCostData[prevVotes > 0 and prevVotes - 1 or 0]
        else
            cost = kCostData[prevVotes > 0 and prevVotes - 1 or 0] -
                       kVoteData.cost
        end
        if cost ~= 0 then
            if instance.DownButton:IsDisabled() then
                tooltip = Locale.Lookup(
                              "LOC_WORLD_CONGRESS_TT_INSUFFICIENT_FAVOR_COST",
                              cost)
            else
                tooltip = Locale.Lookup(kVoteData.voteDirection >= 0 and
                                            "LOC_WORLD_CONGRESS_TT_VOTE_DOWN" or
                                            "LOC_WORLD_CONGRESS_TT_VOTE_UP",
                                        cost)
            end
        end
    end
    instance.DownCost:SetText(cost == 0 and " " or
                                  Locale.Lookup("LOC_WORLD_CONGRESS_FAVOR",
                                                cost *
                                                    (kVoteData.voteDirection > 0 and
                                                        -1 or 1)))
    instance.DownButton:SetToolTipString(tooltip)

    if kVoteData.voteBlocker then
        if kVoteData.voteBlocker.NoUpvote and kVoteData.voteBlocker.NoDownvote then
            instance.UpButton:SetDisabled(true)
            instance.DownButton:SetDisabled(true)
            instance.UpButton:SetToolTipString(
                Locale.Lookup(kVoteData.voteBlocker.Description))
            instance.DownButton:SetToolTipString(
                Locale.Lookup(kVoteData.voteBlocker.Description))
        elseif kVoteData.voteBlocker.NoUpvote and kVoteData.votes == 0 then
            instance.UpButton:SetDisabled(true)
            instance.UpButton:SetToolTipString(
                Locale.Lookup(kVoteData.voteBlocker.Description))
        elseif kVoteData.voteBlocker.NoDownvote and kVoteData.votes == 0 then
            instance.DownButton:SetDisabled(true)
            instance.DownButton:SetToolTipString(
                Locale.Lookup(kVoteData.voteBlocker.Description))
        end
    end

    if kVoteData.votes == 0 then
        if not kVoteData.voteBlocker or not kVoteData.voteBlocker.NoUpvote then
            instance.UpButton:SetToolTipString(
                Locale.Lookup(resolutionChoice and
                                  "LOC_WORLD_CONGRESS_TT_NO_VOTING_DOWN" or
                                  "LOC_WORLD_CONGRESS_TT_PLEASE_VOTE_FOR"))
        end
        if not kVoteData.voteBlocker or not kVoteData.voteBlocker.NoDownvote then
            local bIsTarget = kVoteData.data.Target == Game.GetLocalPlayer()
            if bIsTarget then
                instance.DownButton:SetToolTipString(
                    Locale.Lookup(
                        "LOC_WORLD_CONGRESS_TT_PLEASE_VOTE_AGAINST_TARGET"))
            else
                instance.DownButton:SetToolTipString(
                    Locale.Lookup(resolutionChoice and "" or
                                      "LOC_WORLD_CONGRESS_TT_PLEASE_VOTE_AGAINST"))
            end
        end
    end
end

-- ===========================================================================
--	Updates all voting widgets
-- ===========================================================================
function UpdateAllVotingWidgets(kCostData)
    for _, kVoteData in pairs(m_kResolutionVotes) do
        UpdateVotingWidget(kVoteData.A.instance.Vote1, kVoteData.A, kCostData,
                           TestResolutionVote, 1)
        UpdateVotingWidget(kVoteData.B.instance.Vote2, kVoteData.B, kCostData,
                           TestResolutionVote, 2)
    end
    for _, kVoteData in pairs(m_kProposalVotes) do
        UpdateVotingWidget(kVoteData.instance.Vote, kVoteData, kCostData,
                           TestProposalVote)
    end
end

-- ===========================================================================
-- Populate proposal items (stage 1 & 2, phase 2)
-- TODO: Merge this with PopulateResolutions
--			 Maybe name it PopulateStandardCongress
-- ===========================================================================
function PopulateProposals()
    m_kProposalItemIM:ResetInstances()

    local kSortedCategories = GetSortedProposalCategories(
                                  Game.GetWorldCongress():GetProposals(
                                      Game.GetLocalPlayer()).Proposals)

    for _, kSorted in ipairs(kSortedCategories) do
        local proposalType = kSorted.type
        local kProposalDef = kSorted.kData
        local kProposalCategory = kSorted.kCategory

        local titleInstance = m_kProposalTitleIM:GetInstance(
                                  Controls.ResolutionStack)
        local kCategoryProposals = kProposalCategory.ProposalsOfType

        local updateFn = function()
            UpdateCategoryTitle(titleInstance, kCategoryProposals, kProposalDef)
        end
        if PopulateProposalStack(kCategoryProposals, m_kProposalItemIM,
                                 kProposalCategory, updateFn) > 0 then
            updateFn()
        else
            titleInstance.Root:SetHide(true)
        end
    end
end

function GetCostOfProposals(kProposals)
    local total = 0
    for _, kProposal in pairs(kProposals) do
        local kVoteData = m_kProposalVotes[GetProposalVoteKey(kProposal)]
        total = total + (kVoteData and kVoteData.cost or 0)
    end
    return total
end

function UpdateSenderTitle(instance, titleInstance, kProposals,
                           kCategoryProposals, kProposalDef, pPlayerConfig)
    local total = GetCostOfProposals(kProposals)
    local leaderName = Locale.Lookup(pPlayerConfig:GetLeaderName())
    instance.Cost:SetText(Locale.Lookup("LOC_WORLD_CONGRESS_CATEGORY_FAVOR",
                                        total))
    instance.Cost:SetToolTipString(Locale.Lookup(
                                       (not m_IsInSession and m_ReviewTab ==
                                           REVIEW_TAB_AVAILABLE_PROPOSALS) and
                                           "LOC_WORLD_CONGRESS_TT_DISCUSIONS_FAVOR_COST_NO_REFUND" or
                                           "LOC_WORLD_CONGRESS_TT_DISCUSIONS_FAVOR_COST_WITH_REFUND",
                                       total))
    instance.Title:SetText(Locale.ToUpper(
                               Locale.Lookup("LOC_WORLD_CONGRESS_PROPOSED_BY",
                                             leaderName)))
    UpdateCategoryTitle(titleInstance, kCategoryProposals, kProposalDef)
end

function UpdateCategoryTitle(instance, kProposals, kProposalDef, costEach)
    local total = costEach or GetCostOfProposals(kProposals)
    instance.Cost:SetText(Locale.Lookup("LOC_WORLD_CONGRESS_CATEGORY_FAVOR",
                                        total))
    instance.Cost:SetToolTipString(Locale.Lookup(
                                       (not m_IsInSession and m_ReviewTab ==
                                           REVIEW_TAB_AVAILABLE_PROPOSALS) and
                                           "LOC_WORLD_CONGRESS_TT_DISCUSIONS_FAVOR_COST_NO_REFUND" or
                                           "LOC_WORLD_CONGRESS_TT_DISCUSIONS_FAVOR_COST_WITH_REFUND",
                                       total))
    instance.Title:SetText(Locale.ToUpper(Locale.Lookup(kProposalDef.Name)))
    instance.Icon:SetIcon("ICON_" .. kProposalDef.ProposalType)
end

function PopulateProposalStack(kProposals, kProposalIM, kProposalCategory,
                               updateTitleFn)
    local numAllocated = 0
    local metPlayers = nil
    local isUniqueLeader = nil
    local localPlayerID = Game.GetLocalPlayer()
    local pDiplomacy = Players[localPlayerID]:GetDiplomacy()
    local pEmergencyManager = Game.GetEmergencyManager()

    if m_IsInSession and not kProposalCategory.FavorCost then
        kProposalCategory.FavorCost =
            Game.GetWorldCongress():GetVotesandFavorCost(localPlayerID)
    end

    for _, kProposal in pairs(kProposals) do
        -- Create proposal vote data
        local voteKey = GetProposalVoteKey(kProposal)
        local kVoteData = m_kProposalVotes[voteKey]
        if not kVoteData then
            kVoteData = {
                cost = 0,
                votes = kProposal.Disabled and 1 or DEBUG_DATA and 1 or 0,
                data = kProposal,
                voteDirection = NO_VOTE,
                disabled = kProposal.Disabled and true or false,
                voteBlocker = kProposal.VotingRestriction and
                    GameInfo.VotingBlockers[kProposal.VotingRestriction] or nil,
                proposalBlocker = kProposal.ProposalBlockerType and
                    GameInfo.ProposalBlockers[kProposal.ProposalBlockerType] or
                    nil
            }
        end

        local canVote = not kVoteData.disabled and
                            not (kVoteData.voteBlocker and
                                kVoteData.voteBlocker.NoUpvote and
                                kVoteData.voteBlocker.NoDownvote)
        if canVote or
            (not m_IsInSession and m_ReviewTab == REVIEW_TAB_AVAILABLE_PROPOSALS) then
            numAllocated = numAllocated + 1
            local instance = kProposalIM:GetInstance()

            -- Only store vote data for proposals players can vote on
            kVoteData.instance = instance
            m_kProposalVotes[voteKey] = kVoteData

            -- This allows us to update the total cost
            instance.UpdateTitle = updateTitleFn

            if not metPlayers then
                metPlayers, isUniqueLeader = GetMetPlayersAndUniqueLeaders()
            end

            -- Target Icon
            local pIconManager = LeaderIcon:AttachInstance(instance.LeaderIcon)
            local pPlayerConfig = PlayerConfigurations[kProposal.Target]
            if pPlayerConfig then
                local playerTypeName = pPlayerConfig:GetLeaderTypeName()
                local isLocalPlayer = kProposal.Target == localPlayerID
                local name, leaderIcon, civIcon =
                    GetVisiblePlayerNameAndIcons(kProposal.Target)
                pIconManager:UpdateIconSimple(leaderIcon, kProposal.Target,
                                              isUniqueLeader[kProposal.Target] or
                                                  false, Locale.Lookup(
                                                  "LOC_WORLD_CONGRESS_TARGET_PROPOSAL_TT"))
                instance.Title:SetText(Locale.ToUpper(
                                           Locale.Lookup(kProposal.Name, name)))
                instance.Description:SetText(
                    Locale.Lookup(kProposal.Description, name))
                instance.LeaderIcon.SelectButton:SetHide(false)
                instance.LeaderIcon.TargetIcon:SetColor(
                    kProposal.TypeName == "WC_EMERGENCY_REQUEST_AID" and
                        COLOR_GREEN or COLOR_RED)
                instance.LeaderIcon.TargetIcon:SetTexture(
                    kProposal.TypeName == "WC_EMERGENCY_REQUEST_AID" and
                        "Emergency_TargetAid44" or "Emergency_Target44")
                instance.TypeIcon:SetHide(true)
            else
                instance.Title:SetText(Locale.ToUpper(
                                           Locale.Lookup(kProposal.Name)))
                instance.Description:SetText(
                    Locale.Lookup(kProposal.Description))
                instance.LeaderIcon.SelectButton:SetHide(true)
                instance.TypeIcon:SetIcon("ICON_" .. kProposal.TypeName)
                instance.TypeIcon:SetHide(false)
            end

            if not m_IsInSession and m_ReviewTab ==
                REVIEW_TAB_AVAILABLE_PROPOSALS then
                instance.ExpandButton:RegisterCallback(Mouse.eLClick, function()
                    UI.PlaySound("Main_Main_Panel_Collapse")
                    instance.isCollapsed = not instance.isCollapsed
                    RealizeCollapseableProposal(instance)
                end)
                instance.ExpandButton:RegisterCallback(Mouse.eMouseEnter,
                                                       function()
                    UI.PlaySound("Main_Menu_Mouse_Over")
                end)

                instance.isCollapsed = true
                RealizeCollapseableProposal(instance)
                PopulateEmergencyData(instance, kVoteData.data.Target,
                                      kVoteData.data.EmergencyType)

                UpdateAvailableProposal(kVoteData, kProposalCategory)
                instance.SelectBox:RegisterCallback(Mouse.eLClick,
                                                    OnToggleProposal(instance,
                                                                     kProposal,
                                                                     kProposalCategory))
            else
                UpdateProposal(kVoteData)
                local kCostData = kProposalCategory.FavorCost
                UpdateVotingWidget(instance.Vote, kVoteData, kCostData,
                                   TestProposalVote)
                instance.Vote.UpButton:RegisterCallback(Mouse.eLClick,
                                                        OnVoteProposal(UP_VOTE,
                                                                       kVoteData,
                                                                       kCostData))
                instance.Vote.DownButton:RegisterCallback(Mouse.eLClick,
                                                          OnVoteProposal(
                                                              DOWN_VOTE,
                                                              kVoteData,
                                                              kCostData))

                -- Emergency Data
                if m_IsInSession or m_ReviewTab ~=
                    REVIEW_TAB_AVAILABLE_PROPOSALS then
                    PopulateEmergencyData(instance, kProposal.Target,
                                          kProposal.EmergencyType)
                    instance.EmergencyContainer:SetHide(false)
                    instance.EmergencyButton:SetHide(true)
                end
            end
        end
    end
    return numAllocated
end

-- ===========================================================================
function PopulateEmergencyData(instance, emergencyTarget, emergencyType)
    local emergency = Game.GetEmergencyManager():GetSingleEmergency(
                          emergencyTarget, emergencyType)
    if emergency then
        local crisisData = ProcessEmergency_WorldCongressPopup(emergency)

        -- Title and subtitles
        instance.Description:SetText(emergency.ShortDescriptionText)

        -- Populate our initial data block
        PopulateWorldCrisisText(g_kCrisisManagers, crisisData.crisisDetails,
                                instance.Emergency.CrisisDetailsStack)

        -- Populate our bottom block of data
        PopulateWorldCrisisText(g_kRewardsManagers, crisisData.rewardsDetails,
                                instance.Emergency.RewardsDetailsStack)

        if instance.TurnsLeft then
            if not m_IsInSession then
                instance.TurnsLeft:SetText("[ICON_TURN]" .. emergency.TurnsLeft)
                instance.TurnsLeft:SetToolTipString(
                    Locale.Lookup("LOC_WORLD_CONGRESS_TURNS_LEFT_TT",
                                  emergency.TurnsLeft))
            else
                instance.TurnsLeft:SetText("")
            end
        end
    elseif not emergency then
        UI.DataError(
            'Failed to get emergency data, assign @draabe: EmergencyType=' ..
                kProposal.EmergencyType .. ', Target=' .. kProposal.Target)
    end
end

-- ===========================================================================
--	Generate a unique "key" for later lookups based on the proposal attrubtes
-- ===========================================================================
function GetProposalVoteKey(kProposal)
    return tostring(kProposal.TypeName) .. "_" .. kProposal.Target .. "_" ..
               (kProposal.Sender ~= nil and kProposal.Sender or "NONE")
end

-- ===========================================================================
-- Select proposal items (stage 1, phase 2)
-- ===========================================================================
function OnToggleProposal(instance, kProposal, kProposalCategory)
    return function()

        local kVoteData = m_kProposalVotes[GetProposalVoteKey(kProposal)]

        if kVoteData.votes == 0 and m_WorkingFavor >=
            kProposalCategory.FavorCost then
            kVoteData.votes = 1
            kVoteData.cost = kProposalCategory.FavorCost
            instance.SelectBox:SetSelected(true)
            instance.Root:SetTexture("WC_ProposalFrame_Selected")
            instance.SelectCheck:SetTexture("WC_ProposalCheck_On")
        else
            kVoteData.votes = 0
            kVoteData.cost = 0
            instance.SelectBox:SetSelected(false)
            instance.Root:SetTexture("WC_ProposalFrame_Normal")
            instance.SelectCheck:SetTexture("WC_ProposalCheck_Off")
        end

        UpdateWorkingFavor()
        instance.UpdateTitle()
        for _, kInnerVoteData in pairs(m_kProposalVotes) do
            UpdateAvailableProposal(kInnerVoteData, kProposalCategory)
        end
        UpdateNavButtons()
    end
end

-- ===========================================================================
function UpdateAvailableProposal(kVoteData, kProposalCategory)
    local instance = kVoteData.instance

    --[[ We need an exposure to set 9 slice values in order to use WC_ProposalFrameOpen_* texture
  if instance.isCollapsed then
    instance.Root:SetTexture(not kVoteData.disabled and kVoteData.votes == 0 and "WC_ProposalFrame_Normal" or "WC_ProposalFrame_Selected");
  else
    instance.Root:SetTexture(not kVoteData.disabled and kVoteData.votes == 0 and "WC_ProposalFrameOpen_Normal" or "WC_ProposalFrameOpen_Selected");
  end
  ]]
    instance.Root:SetTexture(not kVoteData.disabled and kVoteData.votes == 0 and
                                 "WC_ProposalFrame_Normal" or
                                 "WC_ProposalFrame_Selected")

    instance.SelectCheck:SetTexture(
        not kVoteData.disabled and kVoteData.votes == 0 and
            "WC_ProposalCheck_Off" or "WC_ProposalCheck_On")
    instance.SelectBox:SetSelected(kVoteData.votes ~= 0)

    -- Check to make sure there isn't already a proposal with this target
    local isTargetSelected = false
    for _, kInnerVoteData in pairs(m_kProposalVotes) do
        if kVoteData ~= kInnerVoteData and kInnerVoteData.votes > 0 then
            if kInnerVoteData.data.Target == kVoteData.data.Target then
                isTargetSelected = true
                instance.SelectBox:SetDisabled(true)
                instance.SelectBox:SetToolTipString(
                    Locale.Lookup("LOC_WORLD_CONGRESS_TT_MAX_ONE_PROPOSAL"))
                break
            end
        end
    end

    if not isTargetSelected then
        instance.SelectBox:SetDisabled(kVoteData.disabled or
                                           (kVoteData.votes == 0 and
                                               m_WorkingFavor <
                                               kProposalCategory.FavorCost))
        if instance.SelectBox:IsDisabled() then
            instance.SelectBox:SetToolTipString(
                kVoteData.disabled and "" or
                    Locale.Lookup(
                        "LOC_WORLD_CONGRESS_TT_INSUFFICIENT_FAVOR_COST",
                        kProposalCategory.FavorCost))
        elseif instance.SelectBox:IsSelected() then
            instance.SelectBox:SetToolTipString(
                Locale.Lookup("LOC_WORLD_CONGRESS_TT_PROPOSAL_REFUND",
                              kProposalCategory.FavorCost))
        else
            instance.SelectBox:SetToolTipString(
                Locale.Lookup("LOC_WORLD_CONGRESS_TT_PROPOSAL_COST",
                              kProposalCategory.FavorCost))
        end
    end

    if kVoteData.proposalBlocker then
        instance.SelectBox:SetToolTipString(
            Locale.Lookup(kVoteData.proposalBlocker.Description))
    end

    local lineColor =
        kVoteData.votes ~= 0 and {220 / 255, 190 / 255, 161 / 255} or
            {102 / 255, 91 / 255, 63 / 255}
    instance.Line:SetColor(lineColor[1], lineColor[2], lineColor[3], 1)
end

-- ===========================================================================
--	Generates a callback that tests whether a vote is successful
-- ===========================================================================
function TestProposalVote(direction, kVoteData, kCostData)
    local kCopyData = {
        votes = kVoteData.votes,
        cost = kVoteData.cost,
        voteDirection = kVoteData.voteDirection
    }
    OnVoteProposal(direction, kCopyData, kCostData, true)()
    return kCopyData.votes ~= kVoteData.votes or kCopyData.cost ~=
               kVoteData.cost
end

-- ===========================================================================
-- Vote on proposal items (stage 2, phase 2)
-- ===========================================================================
function OnVoteProposal(direction, kVoteData, kCostData, isTest)
    return function()

        if kVoteData.voteDirection == NO_VOTE then
            kVoteData.voteDirection = direction
        end

        local voteDirection = kVoteData.voteDirection * direction
        local nextVotes = kVoteData.votes + voteDirection
        if nextVotes > table.count(kCostData) or nextVotes > kCostData.MaxVotes then
            return
        end

        local nextCost = kCostData[nextVotes - 1]
        local currCost = kVoteData.votes == 0 and 0 or
                             kCostData[kVoteData.votes - 1]

        if voteDirection < 0 or (nextCost - currCost) <= m_WorkingFavor then
            kVoteData.votes = nextVotes

            if kVoteData.votes == 0 then
                kVoteData.voteDirection = NO_VOTE
                kVoteData.cost = 0
            else
                kVoteData.cost = kCostData[nextVotes > 0 and nextVotes - 1 or 0]
            end
        end

        if not isTest then
            UpdateWorkingFavor()
            kVoteData.instance.UpdateTitle()
            for _, kInnerVoteData in pairs(m_kProposalVotes) do
                UpdateProposal(kInnerVoteData, kProposalCategory)
            end
            UpdateAllVotingWidgets(kCostData)
            UpdateNavButtons()
        end
    end
end

-- ===========================================================================
function UpdateProposal(kVoteData)
    local canVote = not kVoteData.disabled and
                        not (kVoteData.voteBlocker ~= nil and
                            kVoteData.voteBlocker.NoUpvote and
                            kVoteData.voteBlocker.NoDownvote)
    kVoteData.instance.Root:SetTexture(canVote and kVoteData.votes == 0 and
                                           "WC_ProposalFrameOpen_Normal" or
                                           "WC_ProposalFrameOpen_Selected")
end

-- ===========================================================================
--	Gets proposal categories and sorts them
-- ===========================================================================
function GetSortedProposalCategories(kProposals)
    local kSortedCategories = {}
    if kProposals ~= nil then
        for proposalType, kProposalCategory in pairs(kProposals) do
            local kProposalDef = GameInfo.ProposalTypes[proposalType]
            if kProposalDef and table.count(kProposalCategory.ProposalsOfType) >
                0 then

                local kSorted = {
                    type = proposalType,
                    kData = kProposalDef,
                    kCategory = kProposalCategory
                }
                table.insert(kSortedCategories, kSorted)

            elseif kProposalDef == nil then
                UI.DataError("Undefined Proposal Category: " .. proposalType ..
                                 " in World Congress Step 2!")
            end
        end

        table.sort(kSortedCategories,
                   function(a, b) return a.kData.Sort < b.kData.Sort end)
    end
    return kSortedCategories
end

-- ===========================================================================
--	Both summary and review instances use the same container
-- ===========================================================================
function ResetReviewInstances()
    m_kResolutionsTitle = nil
    m_kProposalTitleIM:ResetInstances()
    m_kReviewResolutionIM:ResetInstances()
    m_kReviewProposalIM:ResetInstances()
    m_kEmergencyProposalIM:ResetInstances()
    m_ProposalVoterIM:ResetInstances()
    m_ResolutionVoterIM:ResetInstances()
    m_kReviewOutcomeIM:ResetInstances()
    m_VerticalPaddingReviewIM:ResetInstances()
    ResetEmergencyInstances()
end

-- ===========================================================================
--	Updates the stage one summary screen when we navigate there
-- ===========================================================================
function PopulateSummary()
    local localPlayerID = Game.GetLocalPlayer()
    local pDiplomacy = Players[localPlayerID]:GetDiplomacy()
    local metPlayers, isUniqueLeader = GetMetPlayersAndUniqueLeaders()

    ResetReviewInstances()

    if m_CurrentStage == 1 then
        local kResolutions = Game.GetWorldCongress():GetResolutions(
                                 localPlayerID)

        local resolutionCost = 0
        for i, kResolutionData in pairs(kResolutions) do
            if type(i) == "number" then -- There's a "Stage" key kResolutions
                local instance = m_kReviewResolutionIM:GetInstance()
                local kVoteData = m_kResolutionVotes[i]
                local kResolution = GameInfo.Resolutions[kResolutionData.Type]
                local kResolutionChoice = m_kResolutionChoices[kResolution.Hash]

                local aVotes = kResolutionChoice.choice == 1 and
                                   kVoteData.A.votes or 0
                local aTT = kResolutionChoice.choice == 1 and
                                Locale.Lookup(
                                    "LOC_WORLD_CONGRESS_A_VOTES_TT_SUMMARY",
                                    aVotes) or ""

                local bVotes = kResolutionChoice.choice ~= 1 and
                                   kVoteData.B.votes or 0
                local bTT = kResolutionChoice.choice ~= 1 and
                                Locale.Lookup(
                                    "LOC_WORLD_CONGRESS_B_VOTES_TT_SUMMARY",
                                    bVotes) or ""

                instance.UpVoteLabel:SetText(bVotes)
                instance.DownVoteLabel:SetText(aVotes)

                instance.UpVoteIcon:SetToolTipString(bTT)
                instance.UpVoteLabel:SetToolTipString(bTT)
                instance.DownVoteIcon:SetToolTipString(aTT)
                instance.DownVoteLabel:SetToolTipString(aTT)

                instance.UpVoteStack:SetHide(bVotes == 0)
                instance.DownVoteStack:SetHide(aVotes == 0)
                instance.ExpandButton:SetHide(true)

                for i = 1, 4 do
                    instance["Line" .. i]:SetHide(false)
                end
                instance.CostContainer:SetHide(false)

                if kResolutionData.TargetType == "PlayerType" then
                    local playerID = tonumber(
                                         kResolutionData.PossibleTargets[kResolutionChoice.target] or
                                             -1)
                    local pIconManager =
                        LeaderIcon:AttachInstance(instance.LeaderIcon)
                    local pPlayerConfig = PlayerConfigurations[playerID]
                    if pPlayerConfig then
                        local playerTypeName = pPlayerConfig:GetLeaderTypeName()
                        local isLocalPlayer = playerID == localPlayerID
                        local pDiplomacy = Players[localPlayerID]:GetDiplomacy()
                        local icon = (isLocalPlayer or
                                         pDiplomacy:HasMet(playerID)) and
                                         "ICON_" .. playerTypeName or
                                         "ICON_LEADER_DEFAULT"
                        pIconManager:UpdateIconSimple(icon, playerID,
                                                      isUniqueLeader[playerID] or
                                                          false, Locale.Lookup(
                                                          "LOC_WORLD_CONGRESS_TARGET_RESOLUTION_TT"))
                    end
                    instance.LeaderIcon.SelectButton:SetHide(not pPlayerConfig)
                    instance.TypeIcon:SetHide(pPlayerConfig ~= nil)
                else
                    instance.LeaderIcon.SelectButton:SetHide(true)
                    instance.TypeIcon:SetHide(false)
                end

                local text, icon = GetPulldownNameAndIcons(kResolutionData,
                                                           kResolutionChoice.target) or
                                       "", ""
                instance.ChosenThing:SetText(text)
                instance.Title:SetText(Locale.ToUpper(
                                           Locale.Lookup(kResolution.Name)))
                instance.Status:SetText("")
                instance.TargetLabel:SetText(
                    Locale.Lookup("LOC_WORLD_CONGRESS_PREVIEW_PROPOSAL_TARGET"))
                instance.ChoiceLabel:SetText(
                    Locale.Lookup("LOC_WORLD_CONGRESS_PREVIEW_PROPOSAL_OUTCOME",
                                  kResolutionChoice.choice == 1 and
                                      Locale.Lookup(
                                          "LOC_WORLD_CONGRESS_CHOICE_A") or
                                      Locale.Lookup(
                                          "LOC_WORLD_CONGRESS_CHOICE_B")))
                instance.Description:SetText(
                    Locale.Lookup(kResolutionChoice.choice == 1 and
                                      kResolution.Effect1Description or
                                      kResolution.Effect2Description))
                instance.Cost:SetText(Locale.Lookup("LOC_WORLD_CONGRESS_FAVOR",
                                                    kVoteData.A.cost +
                                                        kVoteData.B.cost))
                instance.Cost:SetToolTipString(
                    Locale.Lookup("LOC_WORLD_CONGRESS_TT_PROPOSAL_COST",
                                  kVoteData.A.cost + kVoteData.B.cost))
                instance.TurnsLeft:SetText("")
                instance.IconNew:SetHide(true)

                resolutionCost = resolutionCost + kVoteData.A.cost +
                                     kVoteData.B.cost
            end
        end
        Controls.ReviewResolutionFavor:SetText(
            Locale.Lookup("LOC_WORLD_CONGRESS_CATEGORY_FAVOR", resolutionCost))
        Controls.ReviewResolutionFavor:SetToolTipString(
            Locale.Lookup(
                "LOC_WORLD_CONGRESS_TT_RESOLUTIONS_FAVOR_COST_WITH_REFUND",
                resolutionCost))
    end

    local kSortedCategories = GetSortedProposalCategories(
                                  Game.GetWorldCongress():GetProposals(
                                      localPlayerID).Proposals)
    for _, kSorted in ipairs(kSortedCategories) do
        local proposalType = kSorted.type
        local kProposalDef = kSorted.kData
        local kProposalCategory = kSorted.kCategory

        local titleInstance = m_kProposalTitleIM:GetInstance(
                                  Controls.ReviewProposalStack)
        local kCategoryProposals = kProposalCategory.ProposalsOfType

        PopulateSummaryProposals(kCategoryProposals, m_kReviewProposalIM)
        UpdateCategoryTitle(titleInstance, kCategoryProposals, kProposalDef)
    end

    Controls.ReviewResolutionTitle:SetHide(
        m_kReviewResolutionIM.m_iAllocatedInstances == 0)
end

-- ===========================================================================
function PopulateSummaryProposals(kProposals, kProposalIM)
    local metPlayers = GetMetPlayersAndUniqueLeaders()
    local localPlayerID = Game.GetLocalPlayer()
    local pDiplomacy = Players[localPlayerID]:GetDiplomacy()
    local pEmergencyManager = Game.GetEmergencyManager()

    for _, kProposal in pairs(kProposals) do
        local kVoteData = m_kProposalVotes[GetProposalVoteKey(kProposal)]
        if not m_IsInSession or kVoteData then
            local instance = kProposalIM:GetInstance()
            instance.IconNew:SetShow(kProposal.IsNew and kProposal.IsNew ~= 0)

            -- Target Icon
            local pIconManager = LeaderIcon:AttachInstance(instance.LeaderIcon)
            local pPlayerConfig = PlayerConfigurations[kProposal.Target]
            if pPlayerConfig then
                local playerTypeName = pPlayerConfig:GetLeaderTypeName()
                local isLocalPlayer = kProposal.Target == localPlayerID
                local icon = (isLocalPlayer or
                                 pDiplomacy:HasMet(kProposal.Target)) and
                                 "ICON_" .. playerTypeName or
                                 "ICON_LEADER_DEFAULT"
                pIconManager:UpdateIconSimple(icon, kProposal.Target,
                                              metPlayers[kProposal.Target],
                                              Locale.Lookup(
                                                  "LOC_WORLD_CONGRESS_TARGET_PROPOSAL_TT"))
                instance.Title:SetText(Locale.ToUpper(
                                           Locale.Lookup(kProposal.Name,
                                                         pPlayerConfig:GetLeaderName())))
                instance.Status:SetText("")
                instance.Description:SetText(
                    Locale.Lookup(kProposal.Description,
                                  pPlayerConfig:GetLeaderName()))
                instance.LeaderIcon.SelectButton:SetHide(false)
                instance.LeaderIcon.TargetIcon:SetColor(
                    kProposal.TypeName == "WC_EMERGENCY_REQUEST_AID" and
                        COLOR_GREEN or COLOR_RED)
                instance.LeaderIcon.TargetIcon:SetTexture(
                    kProposal.TypeName == "WC_EMERGENCY_REQUEST_AID" and
                        "Emergency_TargetAid44" or "Emergency_Target44")
                instance.TypeIcon:SetHide(true)
            else
                instance.Title:SetText(Locale.ToUpper(
                                           Locale.Lookup(kProposal.Name)))
                instance.Status:SetText("")
                instance.Description:SetText(
                    Locale.Lookup(kProposal.Description))
                instance.LeaderIcon.SelectButton:SetHide(true)
                instance.TypeIcon:SetIcon("ICON_" .. kProposal.TypeName)
                instance.TypeIcon:SetHide(false)
            end

            local cost = nil
            local votes = nil
            local voteDirection = nil
            if kVoteData then
                cost = kVoteData.cost
                votes = kVoteData.votes
                voteDirection = kVoteData.voteDirection
            end
            instance.Cost:SetText(cost ~= nil and
                                      Locale.Lookup("LOC_WORLD_CONGRESS_FAVOR",
                                                    cost) or "")
            instance.Cost:SetToolTipString(
                cost ~= nil and
                    Locale.Lookup("LOC_WORLD_CONGRESS_TT_PROPOSAL_COST", cost) or
                    "")

            local upTT = votes and
                             Locale.Lookup(
                                 "LOC_WORLD_CONGRESS_TT_VOTE_UP_SUMMARY", votes) or
                             ""
            local downTT = votes and
                               Locale.Lookup(
                                   "LOC_WORLD_CONGRESS_TT_VOTE_DOWN_SUMMARY",
                                   votes) or ""

            instance.UpVoteIcon:SetToolTipString(upTT)
            instance.UpVoteLabel:SetToolTipString(upTT)
            instance.DownVoteIcon:SetToolTipString(downTT)
            instance.DownVoteLabel:SetToolTipString(downTT)

            instance.UpVoteLabel:SetText(votes and tostring(votes) or "")
            instance.DownVoteLabel:SetText(votes and tostring(votes) or "")

            instance.UpVoteStack:SetHide(
                not voteDirection or voteDirection < 0 or votes <= 0)
            instance.DownVoteStack:SetHide(
                not voteDirection or voteDirection > 0 or votes <= 0)

            if m_IsInSession then
                for i = 1, 4 do
                    instance["Line" .. i]:SetHide(false)
                end
            else
                for i = 1, 4 do
                    instance["Line" .. i]:SetHide(i > 2)
                end
            end
            instance.CostContainer:SetHide(false)

            PopulateEmergencyData(instance, kProposal.Target,
                                  kProposal.EmergencyType)
            instance.EmergencyButton:SetHide(m_IsInSession)
            instance.ExpandButton:SetHide(m_IsInSession)
            instance.EmergencyContainer:SetHide(false)

            instance.ExpandButton:RegisterCallback(Mouse.eLClick, function()
                UI.PlaySound("Main_Main_Panel_Collapse")
                instance.isCollapsed = not instance.isCollapsed
                RealizeCollapseableProposal(instance)
            end)
            instance.ExpandButton:RegisterCallback(Mouse.eMouseEnter, function()
                UI.PlaySound("Main_Menu_Mouse_Over")
            end)

            instance.isCollapsed = true
            RealizeCollapseableProposal(instance)

            if not m_IsInSession then
                instance.EmergencyButton:RegisterCallback(Mouse.eLClick,
                                                          function()
                    local emergency =
                        Game.GetEmergencyManager():GetSingleEmergency(
                            kProposal.Target, kProposal.EmergencyType)
                    LuaEvents.WorldCongress_ShowEmergency(emergency.TargetID,
                                                          emergency.EmergencyType)
                    ClosePopup()
                end)
            end
        end
    end
end

function UpdateResolutionChoice(kResolutionChoice)
    local hasTarget = kResolutionChoice.target ~= -1
    local hasChoice = kResolutionChoice.choice ~= -1

    kResolutionChoice.instance.Choice1.Root:SetShow(
        kResolutionChoice.choice == 1)
    kResolutionChoice.instance.Choice2.Root:SetShow(
        kResolutionChoice.choice == 2)

    kResolutionChoice.instance.Choice1Slot:SetTexture(
        hasTarget and kResolutionChoice.choice == 1 and "WC_ProposalSlot_On" or
            "WC_ProposalSlot_Off")
    kResolutionChoice.instance.Choice2Slot:SetTexture(
        hasTarget and kResolutionChoice.choice == 2 and "WC_ProposalSlot_On" or
            "WC_ProposalSlot_Off")

    local kVoteData
    for _, kInnerVoteData in pairs(m_kResolutionVotes) do
        if kInnerVoteData.Hash == kResolutionChoice.hash then
            kVoteData = kInnerVoteData
            break
        end
    end

    local isSelected = hasTarget and hasChoice and kVoteData and
                           (kVoteData.A.votes ~= 0 or kVoteData.B.votes ~= 0)
    kResolutionChoice.instance.Root:SetTexture(
        isSelected and "WC_ProposalFrameOpen_Selected" or
            "WC_ProposalFrameOpen_Normal")

    local lineColor = isSelected and {220 / 255, 190 / 255, 161 / 255} or
                          {102 / 255, 91 / 255, 63 / 255}
    kResolutionChoice.instance.Line:SetColor(lineColor[1], lineColor[2],
                                             lineColor[3], 1)
end

-- ===========================================================================
--	Populates options that allow players to request a special session
-- ===========================================================================
function PopulateEmergencyProposals()
    ResetReviewInstances()

    local kSortedCategories = GetSortedProposalCategories(
                                  Game.GetWorldCongress():GetEmergencies(
                                      Game.GetLocalPlayer()).Proposals)
    for _, kSorted in ipairs(kSortedCategories) do
        local proposalType = kSorted.type
        local kProposalDef = kSorted.kData
        local kProposalCategory = kSorted.kCategory

        local titleInstance = m_kProposalTitleIM:GetInstance(
                                  Controls.ReviewProposalStack)
        local kCategoryProposals = kProposalCategory.ProposalsOfType

        local updateFn = function()
            UpdateCategoryTitle(titleInstance, kCategoryProposals, kProposalDef,
                                kProposalCategory.FavorCost)
        end
        if PopulateProposalStack(kCategoryProposals, m_kEmergencyProposalIM,
                                 kProposalCategory, updateFn) > 0 then
            updateFn()
        else
            titleInstance.Root:SetHide(true)
        end
    end
end

-- ===========================================================================
--	Returns true if there are any available Emergency Proposals
-- ===========================================================================
function HasEmergencyProposals()
    local kSortedCategories = GetSortedProposalCategories(
                                  Game.GetWorldCongress():GetEmergencies(
                                      Game.GetLocalPlayer()).Proposals)
    for _, kSorted in ipairs(kSortedCategories) do
        if kSorted.kCategory.ProposalsOfType and
            table.count(kSorted.kCategory.ProposalsOfType) > 0 then
            return true
        end
    end
    return false
end

-- ===========================================================================
--	Returns true if there are any available Emergency Proposals
-- ===========================================================================
function HasEmergencyProposalChoices()
    local kSortedCategories = GetSortedProposalCategories(
                                  Game.GetWorldCongress():GetEmergencies(
                                      Game.GetLocalPlayer()).Proposals)
    for _, kSorted in ipairs(kSortedCategories) do
        if kSorted.kCategory.ProposalsOfType and
            table.count(kSorted.kCategory.ProposalsOfType) > 0 then
            for _, kProposal in pairs(kSorted.kCategory.ProposalsOfType) do
                local kVoteData =
                    m_kProposalVotes[GetProposalVoteKey(kProposal)]
                if kVoteData and not kVoteData.instance.SelectBox:IsDisabled() then
                    return true
                end
            end
        end
    end
    return false
end

-- ===========================================================================
--	Populates the stage 4 review
-- ===========================================================================
function PopulateReview()
    local localPlayerID = Game.GetLocalPlayer()
    local pDiplomacy = Players[localPlayerID]:GetDiplomacy()
    local kReviewData = Game.GetWorldCongress():GetReview(localPlayerID)
    local metPlayers, isUniqueLeader = GetMetPlayersAndUniqueLeaders()

    ResetReviewInstances()

    for i, kResolutionData in pairs(kReviewData.Resolutions) do
        if type(kResolutionData) == "table" then -- There's a "Stage" key in kResolutions
            local instance = m_kReviewResolutionIM:GetInstance()
            local kResolution = GameInfo.Resolutions[kResolutionData.Type]

            instance.Title:SetText(Locale.ToUpper(
                                       Locale.Lookup(kResolution.Name)))
            instance.Description:SetText(
                Locale.Lookup(kResolutionData.ChosenOption))
            instance.Cost:SetText("")
            instance.TurnsLeft:SetText("")

            local aVotes = 0
            local bVotes = 0
            for _, kData in pairs(kResolutionData.PlayerSelections) do
                if kData.OptionChosen == 1 then
                    aVotes = aVotes + kData.Votes
                else
                    bVotes = bVotes + kData.Votes
                end
            end

            instance.UpVoteLabel:SetText(bVotes)
            instance.DownVoteLabel:SetText(aVotes)

            local aTT = Locale.Lookup("LOC_WORLD_CONGRESS_REVIEW_A_VOTES_TT",
                                      aVotes)
            local bTT = Locale.Lookup("LOC_WORLD_CONGRESS_REVIEW_B_VOTES_TT",
                                      bVotes)
            if aVotes == bVotes then
                instance.Status:SetText(Locale.Lookup(
                                            "LOC_WORLD_CONGRESS_PROPOSAL_PASSED_TIE"))
                instance.Status:SetToolTipString(
                    Locale.Lookup("LOC_WORLD_CONGRESS_TT_TIE_EXPLANATION"))
            else
                instance.Status:SetText(Locale.Lookup(
                                            "LOC_WORLD_CONGRESS_PROPOSAL_PASSED"))
                instance.Status:SetToolTipString("")
            end
            instance.UpVoteIcon:SetToolTipString(bTT)
            instance.UpVoteLabel:SetToolTipString(bTT)
            instance.DownVoteIcon:SetToolTipString(aTT)
            instance.DownVoteLabel:SetToolTipString(aTT)

            instance.UpVoteStack:SetHide(bVotes == 0)
            instance.DownVoteStack:SetHide(aVotes == 0)
            instance.ExpandButton:SetHide(false)

            for i = 1, 4 do instance["Line" .. i]:SetHide(i == 2) end
            instance.CostContainer:SetHide(true)

            if kResolutionData.TargetType == "PlayerType" then
                local playerID = tonumber(kResolutionData.ChosenThing)
                local text, icon = playerID ~= -1 and
                                       GetPulldownNameAndIcons(kResolutionData,
                                                               playerID) or "",
                                   ""
                instance.ChosenThing:SetText(text)

                local pIconManager = LeaderIcon:AttachInstance(
                                         instance.LeaderIcon)
                local pPlayerConfig = PlayerConfigurations[playerID]
                if pPlayerConfig then
                    local playerTypeName = pPlayerConfig:GetLeaderTypeName()
                    local isLocalPlayer = playerID == localPlayerID
                    local pDiplomacy = Players[localPlayerID]:GetDiplomacy()
                    local icon =
                        (isLocalPlayer or pDiplomacy:HasMet(playerID)) and
                            "ICON_" .. playerTypeName or "ICON_LEADER_DEFAULT"
                    pIconManager:UpdateIconSimple(icon, playerID,
                                                  isUniqueLeader[playerID] or
                                                      false, Locale.Lookup(
                                                      "LOC_WORLD_CONGRESS_TARGET_RESOLUTION_TT"))
                end
                instance.LeaderIcon.SelectButton:SetHide(not pPlayerConfig)
                instance.TypeIcon:SetHide(pPlayerConfig ~= nil)
            else
                instance.ChosenThing:SetText(
                    Locale.Lookup(kResolutionData.ChosenThing))
                instance.LeaderIcon.SelectButton:SetHide(true)
                instance.TypeIcon:SetHide(false)
            end

            instance.TargetLabel:SetText(
                Locale.Lookup("LOC_WORLD_CONGRESS_REVIEW_PROPOSAL_TARGET"))
            instance.ChoiceLabel:SetText(
                Locale.Lookup("LOC_WORLD_CONGRESS_REVIEW_PROPOSAL_OUTCOME",
                              kResolutionData.ChosenLabel))
            instance.IconNew:SetShow(kResolutionData.IsNew and
                                         kResolutionData.IsNew ~= 0)

            instance.ExpandButton:RegisterCallback(Mouse.eLClick, function()
                UI.PlaySound("Main_Main_Panel_Collapse")
                instance.isCollapsed = not instance.isCollapsed
                RealizeCollapseableVoters(instance)
            end)
            instance.ExpandButton:RegisterCallback(Mouse.eMouseEnter, function()
                UI.PlaySound("Main_Menu_Mouse_Over")
            end)

            -- Player Votes (visible when expanded)
            if table.count(kResolutionData.PlayerSelections) > 0 then

                local rejectedOutcome = m_kReviewOutcomeIM:GetInstance(
                                            instance.VoterStack)
                rejectedOutcome.ChoiceLabel:SetText(
                    Locale.Lookup(
                        "LOC_WORLD_CONGRESS_REVIEW_PROPOSAL_REJECTED_OUTCOME",
                        kResolutionData.RejectedLabel))
                rejectedOutcome.Description:SetText(
                    Locale.Lookup(kResolutionData.RejectedOption))

                local dataContainerWidth = instance.VoterStack:GetSizeX()
                for _, kData in pairs(kResolutionData.PlayerSelections) do
                    local voterInstance =
                        m_ResolutionVoterIM:GetInstance(instance.VoterStack)
                    local playerID = tonumber(kData.PlayerID)

                    voterInstance.UpVoteLabel:SetText(
                        kData.OptionChosen ~= 1 and kData.Votes or 0)
                    voterInstance.DownVoteLabel:SetText(
                        kData.OptionChosen == 1 and kData.Votes or 0)
                    voterInstance.UpVoteStack:SetHide(
                        kData.OptionChosen == 1 or kData.Votes == 0)
                    voterInstance.DownVoteStack:SetHide(
                        kData.OptionChosen ~= 1 or kData.Votes == 0)

                    local playerName = GetVisiblePlayerName(playerID)
                    local aTT = Locale.Lookup(
                                    "LOC_WORLD_CONGRESS_REVIEW_A_VOTES_PLAYER_TT",
                                    playerName, kData.Votes)
                    local bTT = Locale.Lookup(
                                    "LOC_WORLD_CONGRESS_REVIEW_B_VOTES_PLAYER_TT",
                                    playerName, kData.Votes)
                    voterInstance.UpVoteIcon:SetToolTipString(bTT)
                    voterInstance.UpVoteLabel:SetToolTipString(bTT)
                    voterInstance.DownVoteIcon:SetToolTipString(aTT)
                    voterInstance.DownVoteLabel:SetToolTipString(aTT)

                    for i = 1, 4 do
                        voterInstance["Line" .. i]:SetHide(i == 2)
                    end
                    voterInstance.CostContainer:SetHide(true)

                    if kResolutionData.TargetType == "PlayerType" then
                        local targetPlayerID = tonumber(kData.ResolutionTarget)
                        local text, icon =
                            targetPlayerID ~= -1 and
                                GetPulldownNameAndIcons(kResolutionData,
                                                        targetPlayerID) or "",
                            ""
                        voterInstance.ChosenThing:SetText(text)
                    else
                        voterInstance.ChosenThing:SetText(
                            Locale.Lookup(kData.ResolutionTarget))
                        voterInstance.LeaderIcon.SelectButton:SetHide(true)
                        voterInstance.TypeIcon:SetHide(false)
                    end

                    local pIconManager =
                        LeaderIcon:AttachInstance(voterInstance.LeaderIcon)
                    local pPlayerConfig = PlayerConfigurations[playerID]
                    if pPlayerConfig then
                        local playerTypeName = pPlayerConfig:GetLeaderTypeName()
                        local isLocalPlayer = playerID == localPlayerID
                        local pDiplomacy = Players[localPlayerID]:GetDiplomacy()
                        local icon = (isLocalPlayer or
                                         pDiplomacy:HasMet(playerID)) and
                                         "ICON_" .. playerTypeName or
                                         "ICON_LEADER_DEFAULT"
                        pIconManager:UpdateIconSimple(icon, playerID,
                                                      isUniqueLeader[playerID] or
                                                          false)
                    end
                    voterInstance.LeaderIcon.SelectButton:SetHide(
                        not pPlayerConfig)
                    voterInstance.TypeIcon:SetHide(pPlayerConfig ~= nil)

                    voterInstance.ChoiceLabel:SetText(
                        Locale.Lookup("LOC_WORLD_CONGRESS_REVIEW_VOTER_OUTCOME",
                                      kData.OptionChosenLabel))
                end

                m_VerticalPaddingReviewIM:GetInstance(instance.VoterStack)
            end

            instance.isCollapsed = true
            RealizeCollapseableVoters(instance)
        end
    end

    local kSortedCategories = GetSortedProposalCategories(
                                  kReviewData.Discussions)
    for _, kSorted in ipairs(kSortedCategories) do
        local proposalType = kSorted.type
        local kProposalDef = kSorted.kData
        local kProposalCategory = kSorted.kCategory

        local titleInstance = m_kProposalTitleIM:GetInstance(
                                  Controls.ReviewProposalStack)
        titleInstance.Title:SetText(Locale.ToUpper(
                                        Locale.Lookup(kProposalDef.Name)))
        titleInstance.Icon:SetIcon("ICON_" .. kProposalDef.ProposalType)
        titleInstance.Cost:SetToolTipString("")
        titleInstance.Cost:SetText("")

        PopulateReviewProposals(kProposalCategory.ProposalsOfType,
                                m_kReviewProposalIM)
    end

    Controls.ReviewResolutionFavor:SetText("")
    Controls.ReviewResolutionTitle:SetHide(
        m_kReviewResolutionIM.m_iAllocatedInstances == 0)
end

-- ===========================================================================
--	Set a group to it's proper collapse/open state
--	Set + - in group row
-- ===========================================================================
function RealizeCollapseableVoters(instance)
    instance.ExpandButton:SetTexture(
        instance.isCollapsed and "WC_ExpandButton" or "WC_CollapseButton")
    instance.VoterScroll:SetHide(instance.isCollapsed)
end

-- ===========================================================================
--	Set a group to it's proper collapse/open state
--	Set + - in group row
-- ===========================================================================
function RealizeCollapseableProposal(instance)
    instance.ExpandButton:SetTexture(
        instance.isCollapsed and "WC_ExpandButton" or "WC_CollapseButton")
    instance.EmergencyContainer:SetHide(instance.isCollapsed)
end

-- ===========================================================================
--	Populates the stage 4 active effects
-- ===========================================================================
function PopulateActiveEffects()
    local localPlayerID = Game.GetLocalPlayer()
    local pDiplomacy = Players[localPlayerID]:GetDiplomacy()
    local pCongressData = Game.GetWorldCongress():GetMeetingStatus()
    local kResolutions = Game.GetWorldCongress():GetResolutions(localPlayerID)

    ResetReviewInstances()

    -- These tables are cached so they only get computed once
    local metPlayers = nil
    local isUniqueLeader = nil

    for i, kResolutionData in pairs(kResolutions) do
        if type(kResolutionData) == "table" then -- There's a "Stage" key in kResolutions
            local instance = m_kReviewResolutionIM:GetInstance()
            local kResolution = GameInfo.Resolutions[kResolutionData.Type]

            instance.Title:SetText(Locale.ToUpper(
                                       Locale.Lookup(kResolution.Name)))
            instance.Status:SetText("")
            instance.Description:SetText(
                Locale.Lookup(kResolutionData.ChosenOption))
            instance.TurnsLeft:SetText(
                "[ICON_TURN]" .. pCongressData.TurnsLeft + 1)
            instance.TurnsLeft:SetToolTipString(
                Locale.Lookup("LOC_WORLD_CONGRESS_TURNS_LEFT_TT",
                              pCongressData.TurnsLeft + 1))

            instance.Cost:SetText("")
            instance.UpVoteLabel:SetText("")
            instance.DownVoteLabel:SetText("")
            instance.UpVoteIcon:SetToolTipString("")
            instance.UpVoteLabel:SetToolTipString("")
            instance.DownVoteIcon:SetToolTipString("")
            instance.DownVoteLabel:SetToolTipString("")
            instance.UpVoteStack:SetHide(true)
            instance.DownVoteStack:SetHide(true)
            instance.ExpandButton:SetHide(true)

            for i = 1, 4 do instance["Line" .. i]:SetHide(i > 2) end
            instance.CostContainer:SetHide(false)

            if kResolutionData.TargetType == "PlayerType" then
                if not metPlayers then
                    metPlayers, isUniqueLeader = GetMetPlayersAndUniqueLeaders()
                end

                local playerID = tonumber(kResolutionData.ChosenThing)
                local text, icon = playerID ~= -1 and
                                       GetPulldownNameAndIcons(kResolutionData,
                                                               playerID) or "",
                                   ""
                instance.ChosenThing:SetText(text)

                local pIconManager = LeaderIcon:AttachInstance(
                                         instance.LeaderIcon)
                local pPlayerConfig = PlayerConfigurations[playerID]
                if pPlayerConfig then
                    local playerTypeName = pPlayerConfig:GetLeaderTypeName()
                    local isLocalPlayer = playerID == localPlayerID
                    local pDiplomacy = Players[localPlayerID]:GetDiplomacy()
                    local icon =
                        (isLocalPlayer or pDiplomacy:HasMet(playerID)) and
                            "ICON_" .. playerTypeName or "ICON_LEADER_DEFAULT"
                    pIconManager:UpdateIconSimple(icon, playerID,
                                                  isUniqueLeader[playerID] or
                                                      false, Locale.Lookup(
                                                      "LOC_WORLD_CONGRESS_TARGET_RESOLUTION_TT"))
                end
                instance.LeaderIcon.SelectButton:SetHide(not pPlayerConfig)
                instance.TypeIcon:SetHide(pPlayerConfig ~= nil)
            else
                instance.ChosenThing:SetText(
                    Locale.Lookup(kResolutionData.ChosenThing))
                instance.LeaderIcon.SelectButton:SetHide(true)
                instance.TypeIcon:SetHide(false)
            end

            instance.TargetLabel:SetText(
                Locale.Lookup("LOC_WORLD_CONGRESS_REVIEW_PROPOSAL_TARGET"))
            instance.ChoiceLabel:SetText(
                Locale.Lookup("LOC_WORLD_CONGRESS_REVIEW_PROPOSAL_OUTCOME",
                              kResolutionData.ChosenLabel))
            instance.IconNew:SetShow(kResolutionData.IsNew and
                                         kResolutionData.IsNew ~= 0)
        end
    end

    local kSortedCategories = GetSortedProposalCategories(
                                  Game.GetWorldCongress():GetProposals(
                                      Game.GetLocalPlayer()).Proposals)
    for _, kSorted in ipairs(kSortedCategories) do
        local proposalType = kSorted.type
        local kProposalDef = kSorted.kData
        local kProposalCategory = kSorted.kCategory

        local titleInstance = m_kProposalTitleIM:GetInstance(
                                  Controls.ReviewProposalStack)
        titleInstance.Title:SetText(Locale.ToUpper(
                                        Locale.Lookup(kProposalDef.Name)))
        titleInstance.Icon:SetIcon("ICON_" .. kProposalDef.ProposalType)
        titleInstance.Cost:SetToolTipString("")
        titleInstance.Cost:SetText("")

        PopulateSummaryProposals(kProposalCategory.ProposalsOfType,
                                 m_kReviewProposalIM)
    end

    Controls.ReviewResolutionFavor:SetText("")
    Controls.ReviewResolutionTitle:SetHide(
        m_kReviewResolutionIM.m_iAllocatedInstances == 0)
end

-- ===========================================================================
-- Accept the voting setup as presented
-- ===========================================================================
function PopulateReviewProposals(kProposals, kProposalIM)
    local metPlayers = GetMetPlayersAndUniqueLeaders()
    local localPlayerID = Game.GetLocalPlayer()
    local pDiplomacy = Players[localPlayerID]:GetDiplomacy()
    local pEmergencyManager = Game.GetEmergencyManager()

    for _, kProposal in pairs(kProposals) do
        local instance = kProposalIM:GetInstance()
        instance.IconNew:SetShow(kProposal.IsNew and kProposal.IsNew ~= 0)
        instance.Status:SetText("")

        local upVotes = 0
        local downVotes = 0
        for p, v in pairs(kProposal.PlayerVotes) do
            if v.Votes > 0 then
                upVotes = upVotes + v.Votes
            elseif v.Votes < 0 then
                downVotes = downVotes + (v.Votes * -1)
            end
        end

        instance.UpVoteLabel:SetText(upVotes)
        instance.DownVoteLabel:SetText(downVotes)
        instance.UpVoteStack:SetHide(upVotes == 0)
        instance.DownVoteStack:SetHide(downVotes == 0)

        local upTT = Locale.Lookup("LOC_WORLD_CONGRESS_REVIEW_UP_VOTES_TT",
                                   upVotes)
        local downTT = Locale.Lookup("LOC_WORLD_CONGRESS_REVIEW_DOWN_VOTES_TT",
                                     downVotes)
        instance.UpVoteIcon:SetToolTipString(upTT)
        instance.UpVoteLabel:SetToolTipString(upTT)
        instance.DownVoteIcon:SetToolTipString(downTT)
        instance.DownVoteLabel:SetToolTipString(downTT)

        instance.ExpandButton:SetHide(false)

        instance.ExpandButton:RegisterCallback(Mouse.eLClick, function()
            UI.PlaySound("Main_Main_Panel_Collapse")
            instance.isCollapsed = not instance.isCollapsed
            RealizeCollapseableVoters(instance)
        end)
        instance.ExpandButton:RegisterCallback(Mouse.eMouseEnter, function()
            UI.PlaySound("Main_Menu_Mouse_Over")
        end)

        -- Title + Target Icon
        local proposalResult = upVotes > downVotes and
                                   "LOC_WORLD_CONGRESS_PROPOSAL_PASSED" or
                                   "LOC_WORLD_CONGRESS_PROPOSAL_FAILED"
        local pIconManager = LeaderIcon:AttachInstance(instance.LeaderIcon)
        local pPlayerConfig = PlayerConfigurations[kProposal.TargetPlayer]
        if pPlayerConfig then
            local playerTypeName = pPlayerConfig:GetLeaderTypeName()
            local isLocalPlayer = kProposal.TargetPlayer == localPlayerID
            local icon = (isLocalPlayer or
                             pDiplomacy:HasMet(kProposal.TargetPlayer)) and
                             "ICON_" .. playerTypeName or "ICON_LEADER_DEFAULT"
            pIconManager:UpdateIconSimple(icon, kProposal.TargetPlayer,
                                          metPlayers[kProposal.TargetPlayer],
                                          Locale.Lookup(
                                              "LOC_WORLD_CONGRESS_TARGET_PROPOSAL_TT"))

            local proposalName = Locale.ToUpper(
                                     Locale.Lookup(kProposal.Name,
                                                   pPlayerConfig:GetLeaderName()))
            instance.Title:SetText(proposalName)
            instance.Status:SetText(Locale.Lookup(proposalResult))
            instance.Description:SetText(
                Locale.Lookup(kProposal.Description,
                              pPlayerConfig:GetLeaderName()))
            instance.LeaderIcon.SelectButton:SetHide(false)
            instance.LeaderIcon.TargetIcon:SetColor(
                kProposal.TypeName == "WC_EMERGENCY_REQUEST_AID" and COLOR_GREEN or
                    COLOR_RED)
            instance.LeaderIcon.TargetIcon:SetTexture(
                kProposal.TypeName == "WC_EMERGENCY_REQUEST_AID" and
                    "Emergency_TargetAid44" or "Emergency_Target44")
            instance.TypeIcon:SetHide(true)
        else
            instance.Title:SetText(Locale.ToUpper(Locale.Lookup(kProposal.Name)))
            instance.Status:SetText(Locale.Lookup(proposalResult))
            instance.Description:SetText(Locale.Lookup(kProposal.Description))
            instance.LeaderIcon.SelectButton:SetHide(true)
            instance.TypeIcon:SetIcon("ICON_" .. kProposal.TypeName)
            instance.TypeIcon:SetHide(false)
        end

        for i = 1, 4 do instance["Line" .. i]:SetHide(i == 2) end
        instance.CostContainer:SetHide(true)

        -- Player Votes (visible when expanded)
        if table.count(kProposal.PlayerVotes) > 0 then
            local dataContainerWidth = instance.VoterStack:GetSizeX()
            for _, kData in pairs(kProposal.PlayerVotes) do
                local instance = m_ProposalVoterIM:GetInstance(
                                     instance.VoterStack)
                local playerID = tonumber(kData.PlayerType)

                instance.UpVoteLabel:SetText(kData.Votes)
                instance.DownVoteLabel:SetText(kData.Votes * -1)
                instance.UpVoteStack:SetHide(kData.Votes <= 0)
                instance.DownVoteStack:SetHide(kData.Votes >= 0)

                -- Target Icon
                local pIconManager = LeaderIcon:AttachInstance(
                                         instance.LeaderIcon)
                local pPlayerConfig = PlayerConfigurations[playerID]
                local playerName = GetVisiblePlayerName(playerID)
                if pPlayerConfig then
                    local playerTypeName = pPlayerConfig:GetLeaderTypeName()
                    local icon = (playerID == localPlayerID or
                                     pDiplomacy:HasMet(playerID)) and "ICON_" ..
                                     playerTypeName or "ICON_LEADER_DEFAULT"
                    pIconManager:UpdateIconSimple(icon, playerID,
                                                  metPlayers[playerID])
                    instance.Title:SetText(Locale.Lookup(playerName))
                    -- TODO: Set truncate width of Reason field
                    instance.Reason:SetText(
                        (kData.Votes == 0 and playerID == localPlayerID) and
                            Locale.Lookup(
                                "LOC_WC_VOTING_BLOCKER_NOT_INVITED_TO_EMERGENCY_DESC") or
                            "")
                end

                local upTT = Locale.Lookup(
                                 "LOC_WORLD_CONGRESS_REVIEW_UP_VOTES_PLAYER_TT",
                                 playerName, kData.Votes)
                local downTT = Locale.Lookup(
                                   "LOC_WORLD_CONGRESS_REVIEW_DOWN_VOTES_PLAYER_TT",
                                   playerName, kData.Votes * -1)
                instance.UpVoteIcon:SetToolTipString(upTT)
                instance.UpVoteLabel:SetToolTipString(upTT)
                instance.DownVoteIcon:SetToolTipString(downTT)
                instance.DownVoteLabel:SetToolTipString(downTT)
            end

            m_VerticalPaddingReviewIM:GetInstance(instance.VoterStack)
        end

        instance.EmergencyButton:SetHide(true)
        instance.EmergencyContainer:SetHide(true)

        instance.isCollapsed = true
        RealizeCollapseableVoters(instance)
    end
end

-- ===========================================================================
-- Accept the voting setup as presented
-- ===========================================================================
function OnAccept()

    local kParameters = {}
    local playerID = Game.GetLocalPlayer()

    if m_CurrentStage == 1 or m_CurrentStage == 2 then
        if m_CurrentStage == 1 and table.count(m_kResolutionVotes) == 0 then
            UI.DataError(
                "Clicked OnAccept() in Stage 1 of WorldCongress but have an empty m_kResolutionVotes table")
        end

        if m_CurrentStage == 2 and table.count(m_kProposalVotes) == 0 then
            UI.DataError(
                "Clicked OnAccept() in Stage 1 of WorldCongress but have an empty m_kProposalVotes table")
        end

        if m_CurrentStage == 1 then
            for _, kVoteData in pairs(m_kResolutionVotes) do
                if kVoteData.A.votes + kVoteData.B.votes > 0 then
                    local kParameters = {}
                    kParameters[PlayerOperations.PARAM_RESOLUTION_TYPE] =
                        kVoteData.Hash
                    kParameters[PlayerOperations.PARAM_WORLD_CONGRESS_VOTES] =
                        kVoteData.A.votes + kVoteData.B.votes

                    local kChoiceData = m_kResolutionChoices[kVoteData.Hash]
                    if kChoiceData then
                        kParameters[PlayerOperations.PARAM_RESOLUTION_OPTION] =
                            kChoiceData.choice
                        kParameters[PlayerOperations.PARAM_RESOLUTION_SELECTION] =
                            kChoiceData.target - 1
                    end

                    UI.RequestPlayerOperation(playerID,
                                              PlayerOperations.WORLD_CONGRESS_RESOLUTION_VOTE,
                                              kParameters)
                end
            end
        end

        for _, kVoteData in pairs(m_kProposalVotes) do
            local kParameters = {}
            kParameters[PlayerOperations.PARAM_PLAYER_ONE] =
                kVoteData.data.Sender
            kParameters[PlayerOperations.PARAM_PLAYER_TWO] =
                kVoteData.data.Target
            kParameters[PlayerOperations.PARAM_WORLD_CONGRESS_VOTES] =
                kVoteData.votes * kVoteData.voteDirection
            UI.RequestPlayerOperation(playerID,
                                      PlayerOperations.WORLD_CONGRESS_DISCUSSION_VOTE,
                                      kParameters)
        end

        m_CurrentStage = 0
        m_CurrentPhase = 0
        m_kProposalVotes = {}
        m_kResolutionVotes = {}
        m_kResolutionChoices = {}

        UI.RequestPlayerOperation(Game.GetLocalPlayer(),
                                  PlayerOperations.WORLD_CONGRESS_SUBMIT_TURN,
                                  {})
        UI.RequestAction(ActionTypes.ACTION_ENDTURN)
        Controls.AcceptButton:SetDisabled(true)

    elseif not m_IsInSession and m_ReviewTab == REVIEW_TAB_AVAILABLE_PROPOSALS then

        local totalCost = 0
        for _, kVoteData in pairs(m_kProposalVotes) do
            totalCost = totalCost + kVoteData.cost
        end
        local dialogText = Locale.Lookup(
                               "LOC_WORLD_CONGRESS_CONFIRM_SUBMIT_PROPOSALS",
                               totalCost)

        m_kPopupDialog:Close() -- clear out the popup incase it is already open.
        m_kPopupDialog:ShowOkCancelDialog(dialogText, function()
            Controls.AcceptButton:SetDisabled(true)
            for _, kVoteData in pairs(m_kProposalVotes) do
                if not kVoteData.disabled and kVoteData.votes > 0 then
                    local kParameters = {}
                    kParameters[PlayerOperations.PARAM_OTHER_PLAYER] =
                        kVoteData.data.Target
                    kParameters[PlayerOperations.PARAM_DISCUSSION_TYPE] =
                        kVoteData.data.Type
                    UI.RequestPlayerOperation(playerID,
                                              PlayerOperations.WORLD_CONGRESS_DISCUSSION_SELECTION,
                                              kParameters)
                end
            end

            m_CurrentStage = 0
            m_CurrentPhase = 0
            m_kProposalVotes = {}

            ClosePopup()

            if m_HasSpecialSessionNotification then
                LuaEvents.WorldCongressPopup_DismissSpecialSessionNotification()
            end
        end)
        m_kPopupDialog:Open()
    else
        UI.DataError(
            "Invalid stage in OnAccept: '" .. tostring(m_CurrentStage) .. "'")
    end

    if m_CurrentStage < 3 and not GameConfiguration.IsHotseat() then
        m_HasAccepted = true
        LuaEvents.WorldCongressPopup_ShowWorldCongressBetweenTurns(
            m_CurrentStage)
        ClosePopup()
    end
end

-- ===========================================================================
-- Next Page Sequence Button
-- ===========================================================================
function OnNext()
    if CanMoveToNextPhase() and SetPhase(m_CurrentPhase + 1) then return true end
end

-- ===========================================================================
-- Previous Page Sequence Button
-- ===========================================================================
function OnPrev()
    if m_CurrentPhase > 1 and SetPhase(m_CurrentPhase - 1) then return true end
end

-- ===========================================================================
-- Deal with changing phases
-- ===========================================================================
function OnWorldCongressStageChange(playerID, stageNum)
    -- Account for Autoplay
    if playerID == Game.GetLocalPlayer() then -- Problematic check? -sbatista
        SetupWorldCongress(stageNum)
    end
end

-- ===========================================================================
-- Deal with changing phases
-- ===========================================================================
function OnWorldCongressResults(selectedTab, delayShow)

    -- Ensure we're on the Active effects tab of WorldCongress
    if selectedTab then m_ReviewTab = selectedTab end

    -- Account for AutoPlay
    if Game.GetLocalPlayer() >= 0 and SetStage(4) then ShowPopup(delayShow) end
end

-- ===========================================================================
--	The load screen has closed.  Check to see if we have to restore our state
-- ===========================================================================
function OnLoadScreenClose() CheckShouldOpen() end

-- ===========================================================================
-- Open the Diplo Screen
-- ===========================================================================
function OnDiploButtonClicked() OpenDiplomacyLiteMode(Game.GetLocalPlayer()) end

-- ===========================================================================
-- Shows the popup
-- ===========================================================================
function ShowPopup(delayShow, fromHotLoad)
    if (GameConfiguration.IsPaused()) then return end
    if ContextPtr:IsHidden() or fromHotLoad then
        UIManager:QueuePopup(ContextPtr, PopupPriority.WorldCongressPopup, {
            AlwaysVisibleInQueue = true,
            DelayShow = delayShow
        })
        Input.PushActiveContext(InputContext.Popup)

        RealizeSize(UIManager:GetScreenSizeVal())
        PopulateLeaderStack()
        PopulateBG()
    end
end

-- ===========================================================================
-- Closes the popup
-- ===========================================================================
function ClosePopup()
    if ContextPtr:IsVisible() then
        UIManager:DequeuePopup(ContextPtr)
        Input.PopContext()
        UI.PlaySound("WC_Exit")

        -- Notify game core so turn blocker can be deactivated
        if not m_IsInSession then
            UI.RequestPlayerOperation(Game.GetLocalPlayer(),
                                      PlayerOperations.WORLD_CONGRESS_LOOKED_AT_AVAILABLE,
                                      {})
        end
    end
end

-- ===========================================================================
-- Reload support
-- ===========================================================================
function OnGameDebugReturn(context, contextTable)
    if context == RELOAD_CACHE_ID then
        if contextTable.IsVisible or ContextPtr:IsVisible() then
            m_ReviewTab = contextTable.ReviewTab
            m_kProposalVotes = contextTable.ProposalVotes
            m_kResolutionVotes = contextTable.ResolutionVotes
            m_kResolutionChoices = contextTable.ResolutionChoices
            m_HasSpecialSessionNotification =
                contextTable.HasSpecialSessionNotification
            SetStage(contextTable.CurrentStage, true)
            SetPhase(contextTable.CurrentPhase)
            ShowPopup(false, true)
        end
    end
end

-- ===========================================================================
-- Reload support
-- ===========================================================================
function OnInit(isReload)
    LateInitialize()
    if isReload then LuaEvents.GameDebug_GetValues(RELOAD_CACHE_ID) end
end

-- ===========================================================================
-- Reload support
-- ===========================================================================
function OnShutdown()
    -- Stop listening
    LuaEvents.GameDebug_Return.Remove(OnGameDebugReturn)
    LuaEvents.WorldCongressIntro_ShowWorldCongress.Remove(OnShowFromIntro)
    LuaEvents.CongressButton_ShowCongressResults.Remove(OnWorldCongressResults)
    LuaEvents.DiplomacyActionView_ShowCongressResults.Remove(
        OnWorldCongressResults)
    LuaEvents.NotificationPanel_ResumeCongress.Remove(OnResumeCongress)
    LuaEvents.CongressButton_ResumeCongress.Remove(OnResumeCongress)
    LuaEvents.DiplomacyActionView_ResumeCongress.Remove(OnResumeCongress)
    LuaEvents.WorldCongressBetweenTurns_ResumeCongress.Remove(OnResumeCongress)
    LuaEvents.DiplomacyActionView_HideCongress.Remove(OnCloseFromDiplomacy)
    LuaEvents.DiploBasePopup_HideUI.Remove(OnCloseFromDiplomacy)
    LuaEvents.NotificationPanel_OpenWorldCongressProposeEmergencies.Remove(
        OnWorldCongressEmergencyProposals)
    LuaEvents.NotificationPanel_OpenWorldCongressResults.Remove(
        OnOpenWorldCongressResultsNotification)
    LuaEvents.WorldCongressPopup_OnSpecialSessionNotificationAdded.Remove(
        OnSpecialSessionNotificationAdded)
    LuaEvents.WorldCongressPopup_OnSpecialSessionNotificationDismissed.Remove(
        OnSpecialSessionNotificationDismissed)
    LuaEvents.GameDebug_AddValue(RELOAD_CACHE_ID, "IsVisible",
                                 ContextPtr:IsVisible())
    LuaEvents.GameDebug_AddValue(RELOAD_CACHE_ID, "ReviewTab", m_ReviewTab)
    LuaEvents.GameDebug_AddValue(RELOAD_CACHE_ID, "CurrentStage", m_CurrentStage)
    LuaEvents.GameDebug_AddValue(RELOAD_CACHE_ID, "CurrentPhase", m_CurrentPhase)
    LuaEvents.GameDebug_AddValue(RELOAD_CACHE_ID,
                                 "HasSpecialSessionNotification",
                                 m_HasSpecialSessionNotification)
    LuaEvents.GameDebug_AddValue(RELOAD_CACHE_ID, "ResolutionVotes",
                                 DEBUG_RESET_DATA and {} or m_kResolutionVotes)
    LuaEvents.GameDebug_AddValue(RELOAD_CACHE_ID, "ProposalVotes",
                                 DEBUG_RESET_DATA and {} or m_kProposalVotes)
    LuaEvents.GameDebug_AddValue(RELOAD_CACHE_ID, "ResolutionChoices",
                                 DEBUG_RESET_DATA and {} or m_kResolutionChoices)

    if ContextPtr:IsVisible() then Input.PopContext() end
end

-- ===========================================================================
-- Consume all input except VK_ESCAPE
-- ===========================================================================
function OnInputHandler(pInputStruct)
    local uiMsg = pInputStruct:GetMessageType()
    local key = pInputStruct:GetKey()
    if uiMsg == KeyEvents.KeyUp then
        if key == Keys.VK_ESCAPE then
            ClosePopup()
            return true
        elseif key == Keys.VK_RETURN then
            if m_CurrentStage == 4 then
                if m_ReviewTab == REVIEW_TAB_AVAILABLE_PROPOSALS then
                    if CanSubmit() then OnAccept() end
                else
                    ClosePopup()
                end
            elseif m_CurrentPhase == PHASE_STEP_MAX then
                OnAccept()
            elseif CanMoveToNextPhase() then
                SetPhase(m_CurrentPhase + 1)
            end
            return true
        end
    end
    return false
end

-- ===========================================================================
--	Callback that gets fired when WorldCongressIntro is closed
-- ===========================================================================
function OnShowFromIntro()
    UI.PlaySound("WC_BeginVoting")
    if m_IsInSession then SetupWorldCongress(m_CurrentStage, true) end
end

-- ===========================================================================
--	Callback that closes popup
-- ===========================================================================
function OnClose() ClosePopup() end

-- ===========================================================================
--	LUA Event
-- ===========================================================================
function OnCloseFromDiplomacy() ClosePopup() end

function OnPass()
    ClosePopup()
    LuaEvents.WorldCongressPopup_DismissSpecialSessionNotification()
end

-- ===========================================================================
-- Reopen the screen
-- ===========================================================================
function OnResumeCongress()
    PopulateLeaderStack()
    if not m_HasAccepted and (not m_IsInSession or HasChoices()) then
        UIManager:QueuePopup(ContextPtr, PopupPriority.WorldCongressPopup,
                             {AlwaysVisibleInQueue = true})
        Input.PushActiveContext(InputContext.Popup)
    elseif not GameConfiguration.IsHotseat() then
        LuaEvents.WorldCongressPopup_ShowWorldCongressBetweenTurns(
            m_CurrentStage)
    end
end

-- ===========================================================================
-- Open the screen in the Emergency Proposals tab
-- ===========================================================================
function OnWorldCongressEmergencyProposals()
    if HasEmergencyProposals() then
        OnWorldCongressResults(REVIEW_TAB_AVAILABLE_PROPOSALS)
    end
end

-- ===========================================================================
-- Flush vote data to ensure every congress has isolated data
-- ===========================================================================
function OnLocalPlayerTurnEnd()
    m_kProposalVotes = nil
    m_kResolutionVotes = nil
    m_kResolutionChoices = nil
    m_kProposalItemIM:ResetInstances()
    m_kEmergencyProposalIM:ResetInstances()

    ClosePopup() -- Always close due to timeout in MP not reseting all data
end

-- ===========================================================================
-- Update Turn Timers
-- ===========================================================================
function OnTurnTimerUpdated(elapsedTime, maxTurnTime)
    if ContextPtr:IsHidden() then return end
    if maxTurnTime <= 0 then
        -- We're in a state where there isn't a turn time, hide all the turn timer elements.
        Controls.NextButton:SetText(Locale.Lookup("LOC_WORLD_CONGRESS_NEXT"))
        Controls.AcceptButton:SetText(Locale.Lookup("LOC_WORLD_CONGRESS_SUBMIT"))
        Controls.ReturnButton:SetText(Locale.Lookup("LOC_WORLD_CONGRESS_RETURN"))
    else
        local timeLeft = SoftRound(maxTurnTime - elapsedTime)
        local timeLeftLabel = " (" .. FormatTimeRemaining(timeLeft, true) .. ")"
        Controls.NextButton:SetText(Locale.Lookup("LOC_WORLD_CONGRESS_NEXT") ..
                                        timeLeftLabel)
        Controls.AcceptButton:SetText(
            Locale.Lookup("LOC_WORLD_CONGRESS_SUBMIT") .. timeLeftLabel)
        Controls.ReturnButton:SetText(
            Locale.Lookup("LOC_WORLD_CONGRESS_RETURN") .. timeLeftLabel)
    end
end

-- ===========================================================================
function OnGameConfigChanged()
    if (ContextPtr:IsVisible()) then
        -- Update the navigation buttons.  The pause state might have changed.
        UpdateNavButtons()
    end
end

-- ===========================================================================
function OnUpdateUI(type, tag, iData1, iData2, strData1)
    if type == SystemUpdateUI.ScreenResize then
        RealizeSize(UIManager:GetScreenSizeVal())
        PopulateLeaderStack()
        PopulateBG()
    end
end

-- ===========================================================================
function AssignActivePulldown(pulldown) m_kActivePulldown = pulldown end

-- ===========================================================================
function CloseActivePulldown()
    if (m_kActivePulldown ~= nil) then
        if (m_kActivePulldown:IsOpen()) then
            m_kActivePulldown:ForceClose()
        end
    end
end

-- ===========================================================================
--	Initialize
-- ===========================================================================
function LateInitialize()
    Controls.AcceptButton:RegisterCallback(Mouse.eLClick, OnAccept)
    Controls.ReturnButton:RegisterCallback(Mouse.eLClick, OnClose)
    Controls.PassButton:RegisterCallback(Mouse.eLClick, OnPass)
    Controls.NextButton:RegisterCallback(Mouse.eLClick, OnNext)
    Controls.PrevButton:RegisterCallback(Mouse.eLClick, OnPrev)
    Controls.DiploButton:RegisterCallback(Mouse.eLClick, OnDiploButtonClicked)
    Controls.HideButton:RegisterCallback(Mouse.eLClick, OnClose)
    Controls.LastResultsButton:RegisterCallback(Mouse.eLClick, function()
        OnWorldCongressResults(REVIEW_TAB_RESULTS)
    end)
    Controls.CurrentEffectsButton:RegisterCallback(Mouse.eLClick, function()
        OnWorldCongressResults(REVIEW_TAB_CURRENT_EFFECTS)
    end)
    Controls.AvailableProposalsButton:RegisterCallback(Mouse.eLClick, function()
        OnWorldCongressResults(REVIEW_TAB_AVAILABLE_PROPOSALS)
    end)
    Controls.DescriptionContainer:RegisterSizeChanged(
        function() RealizeSize(UIManager:GetScreenSizeVal()) end)

    LuaEvents.GameDebug_Return.Add(OnGameDebugReturn)
    LuaEvents.WorldCongressIntro_ShowWorldCongress.Add(OnShowFromIntro)
    LuaEvents.CongressButton_ShowCongressResults.Add(OnWorldCongressResults)
    LuaEvents.DiplomacyActionView_ShowCongressResults
        .Add(OnWorldCongressResults)
    LuaEvents.NotificationPanel_ResumeCongress.Add(OnResumeCongress)
    LuaEvents.CongressButton_ResumeCongress.Add(OnResumeCongress)
    LuaEvents.DiplomacyActionView_ResumeCongress.Add(OnResumeCongress)
    LuaEvents.WorldCongressBetweenTurns_ResumeCongress.Add(OnResumeCongress)
    LuaEvents.DiplomacyActionView_HideCongress.Add(OnCloseFromDiplomacy)
    LuaEvents.DiploBasePopup_HideUI.Add(OnCloseFromDiplomacy)
    LuaEvents.NotificationPanel_OpenWorldCongressProposeEmergencies.Add(
        OnWorldCongressEmergencyProposals)
    LuaEvents.NotificationPanel_OpenWorldCongressResults.Add(
        OnOpenWorldCongressResultsNotification)
    LuaEvents.WorldCongressPopup_OnSpecialSessionNotificationAdded.Add(
        OnSpecialSessionNotificationAdded)
    LuaEvents.WorldCongressPopup_OnSpecialSessionNotificationDismissed.Add(
        OnSpecialSessionNotificationDismissed)

    table.insert(m_kPreviousTooltipEvaluators, EvaluateTiebroken)
    table.insert(m_kPreviousTooltipEvaluators, EvaluateNeckAndNeck)
    table.insert(m_kPreviousTooltipEvaluators, EvaluateUnanimous)
    table.insert(m_kPreviousTooltipEvaluators, EvaluateMajorityLeader)
    table.insert(m_kPreviousTooltipEvaluators, EvaluateSoleVoter)
end

-- ===========================================================================
--	Callback Helpers
-- ===========================================================================
function OnOpenWorldCongressResultsNotification()
    OnWorldCongressResults(REVIEW_TAB_RESULTS, true)
end

function OnSpecialSessionNotificationAdded()
    m_HasSpecialSessionNotification = true
end

function OnSpecialSessionNotificationDismissed()
    m_HasSpecialSessionNotification = false
end

-- ===========================================================================
--	Initialize
-- ===========================================================================
function Initialize()
    ContextPtr:SetInputHandler(OnInputHandler, true)
    ContextPtr:SetInitHandler(OnInit)
    ContextPtr:SetShutdown(OnShutdown)

    Events.SystemUpdateUI.Add(OnUpdateUI)
    Events.LoadScreenClose.Add(OnLoadScreenClose)
    Events.WorldCongressStage1.Add(function(i)
        OnWorldCongressStageChange(i, 1)
    end)
    Events.WorldCongressStage2.Add(function(i)
        OnWorldCongressStageChange(i, 2)
    end)
    Events.LocalPlayerTurnEnd.Add(OnLocalPlayerTurnEnd)
    Events.TurnTimerUpdated.Add(OnTurnTimerUpdated)
    Events.GameConfigChanged.Add(OnGameConfigChanged)
    Events.UserRequestClose.Add(CloseActivePulldown)
end

-- No capability means never initialize this so it can never be used.
if GameCapabilities.HasCapability("CAPABILITY_WORLD_CONGRESS") then Initialize() end
