-- Copright 2017-2019, Firaxis Games
-- Full screen timeline of historic moments.
include("InstanceManager")
include("GameCapabilities")
include("ModalScreen_PlayerYieldsHelper")
include("cui_settings") -- CUI

-- ===========================================================================
--	CONSTANTS
-- ===========================================================================
local MOMENT_WIDTH = 530
local MIN_WIDTH_FOR_PADDING = 700

local BG_WHEEL_X_OFFSET = 125
local TIMELINE_STACK_X_OFFSET_SCROLL = 50
local TIMELINE_STACK_X_OFFSET_NO_SCROLL = -75

local MIN_INTEREST_LEVEL = 1
local AUTO_SHOW_INTEREST_LEVEL = 3

local DATA_FIELD_NUM_INSTANCES = "DATA_FIELD_NUM_INSTANCES"
local HISTORIC_MOMENT_HASH = DB.MakeHash("NOTIFICATION_PRIDE_MOMENT_RECORDED")

local DATA_TYPE_MAP = {
    [MomentDataTypes.MOMENT_DATA_BELIEF] = function(i)
        return GameInfo.Beliefs[i].BeliefType
    end,
    [MomentDataTypes.MOMENT_DATA_BUILDING] = function(i)
        return GameInfo.Buildings[i].BuildingType
    end,
    [MomentDataTypes.MOMENT_DATA_CITY_STATE_PLAYER] = function(i)
        return Players[i]
    end,
    [MomentDataTypes.MOMENT_DATA_CIVIC] = function(i)
        return GameInfo.Civics[i].CivicType
    end,
    [MomentDataTypes.MOMENT_DATA_CONTINENT] = function(i)
        return GameInfo.Continents[i].ContinentType
    end,
    [MomentDataTypes.MOMENT_DATA_DISTRICT] = function(i)
        return GameInfo.Districts[i].DistrictType
    end,
    [MomentDataTypes.MOMENT_DATA_EMERGENCY] = function(i)
        return GameInfo.EmergencyAlliances[i].EmergencyType
    end,
    [MomentDataTypes.MOMENT_DATA_FEATURE] = function(i)
        return GameInfo.Features[i].FeatureType
    end,
    [MomentDataTypes.MOMENT_DATA_GOVERNMENT] = function(i)
        return GameInfo.Governments[i].GovernmentType
    end,
    [MomentDataTypes.MOMENT_DATA_GOVERNOR] = function(i)
        return GameInfo.Governors[i].GovernorType
    end,
    [MomentDataTypes.MOMENT_DATA_GREAT_PERSON_INDIVIDUAL] = function(i)
        return GameInfo.GreatPersonIndividuals[i].GreatPersonIndividualType
    end,
    [MomentDataTypes.MOMENT_DATA_GREAT_WORK] = function(i)
        return GameInfo.GreatWorks[i].GreatWorkType
    end,
    [MomentDataTypes.MOMENT_DATA_IMPROVEMENT] = function(i)
        return GameInfo.Improvements[i].ImprovementType
    end,
    [MomentDataTypes.MOMENT_DATA_OLD_RELIGION] = function(i)
        return GameInfo.Religions[i].ReligionType
    end,
    [MomentDataTypes.MOMENT_DATA_PLAYER_ERA] = function(i)
        return GameInfo.Eras[i].EraType
    end,
    [MomentDataTypes.MOMENT_DATA_PROJECT] = function(i)
        return GameInfo.Projects[i].ProjectType
    end,
    [MomentDataTypes.MOMENT_DATA_RANDOM_EVENT] = function(i)
        return GameInfo.RandomEvents[i].RandomEventType
    end,
    [MomentDataTypes.MOMENT_DATA_RELIGION] = function(i)
        return GameInfo.Religions[i].ReligionType
    end,
    [MomentDataTypes.MOMENT_DATA_RESOURCE] = function(i)
        return GameInfo.Resources[i].ResourceType
    end,
    [MomentDataTypes.MOMENT_DATA_TARGET_PLAYER] = function(i)
        return Players[i]
    end,
    [MomentDataTypes.MOMENT_DATA_TARGET_PLAYER_ERA] = function(i)
        return GameInfo.Eras[i].EraType
    end,
    [MomentDataTypes.MOMENT_DATA_TECHNOLOGY] = function(i)
        return GameInfo.Technologies[i].TechnologyType
    end,
    [MomentDataTypes.MOMENT_DATA_UNIT] = function(i)
        return GameInfo.Units[i].UnitType
    end,
    [MomentDataTypes.MOMENT_DATA_WAR] = function(i) return WarTypes[i] end
}

local DATA_ILLUSTRATIONS_MAP = {
    [MomentDataTypes.MOMENT_DATA_RELIGION] = InstanceManager:new(
        "ReligionIllustration", "Root")
}

-- ===========================================================================
--	VARIABLES
-- ===========================================================================
local m_CurrentEra = -1
local m_CurrentMoment = -1
local m_ScreenWidth = -1
local m_MomentStackInstance = nil
local m_CachedIllustrations = {} -- 3D table indexed by [MomentIllustrationType][MomentDataType][GameDataType]
local m_TopPanelConsideredHeight = 0

local m_SmallMomentIM = InstanceManager:new("SmallMoment", "Root")
local m_LargeMomentIM = InstanceManager:new("LargeMoment", "Root",
                                            Controls.TimelineStack)

local m_NewSmallMomentIM = InstanceManager:new("NewSmallMoment", "Root")
local m_NewLargeMomentIM = InstanceManager:new("NewLargeMoment", "Root",
                                               Controls.TimelineStack)

local m_LargeIllustrationIM = InstanceManager:new("LargeIllustration", "Root")
local m_SmallMomentStackIM = InstanceManager:new("SmallMomentStack", "Root",
                                                 Controls.TimelineStack)

local m_EraLabelIM = InstanceManager:new("EraLabel", "Root",
                                         Controls.TimelineStack)
local m_TimelinePaddingIM = InstanceManager:new("TimelinePadding", "Root",
                                                Controls.TimelineStack)

local m_lastPercent = -1

local m_isLocalPlayerTurn = true
local m_isOpenFromEndGame = false

local m_kQueuedPopups = {}

-- Cause nil access on DATA_ILLUSTRATIONS_MAP to return m_LargeIllustrationIM
setmetatable(DATA_ILLUSTRATIONS_MAP,
             {__index = function() return m_LargeIllustrationIM end})

-- ===========================================================================
--	FUNCTIONS
-- ===========================================================================
function GetPopupPriority()
    return m_isOpenFromEndGame and PopupPriority.Current or PopupPriority.Medium
end

-- ===========================================================================
function GetPopupParameters()
    if m_isOpenFromEndGame then
        return {
            RenderAtCurrentParent = true,
            InputAtCurrentParent = true,
            AlwaysVisibleInQueue = true
        }
    end
    return {
        RenderAtCurrentParent = true,
        InputAtCurrentParent = true,
        AlwaysVisibleInQueue = true,
        DelayShow = true -- Adding Delay fixed: TTP 43014: The camera will become stuck in place if the user triggers the First Suzerain historical moment and reveals a Natural Wonder with auto end turn on in game.
    }
end

-- ===========================================================================
function DebugMomentData(momentData)
    local debugInfo = "(Turn = " .. momentData.Turn .. ", GameEra = " ..
                          momentData.GameEra .. ", ActingPlayer = " ..
                          momentData.ActingPlayer .. ", ExtraData = "
    for _, dataPair in ipairs(momentData.ExtraData) do
        if dataPair.DataType and dataPair.DataValue then
            local dataType = Locale.Lookup(
                                 GameInfo.MomentDataTypes[dataPair.DataType]
                                     .Name)
            debugInfo =
                debugInfo .. "{" .. (dataType and dataType or "Unknown") ..
                    " = " .. dataPair.DataValue .. "}"
        end
    end
    return debugInfo .. ")"
end

-- ===========================================================================
function ShowNewTimelineMoment(popupData)
    m_CurrentMoment = popupData.momentID
    DisplayTimeline(popupData.showAnim)
    UI.PlaySound("UI_Screen_Open")
    local localPlayerID = Game.GetLocalPlayer()
    local pPlayerConfig = PlayerConfigurations[localPlayerID]
    Controls.ModalScreenTitle:SetText(Locale.ToUpper(
                                          Locale.Lookup(
                                              "LOC_HISTORY_NEW_MOMENT",
                                              pPlayerConfig:GetCivilizationDescription())))
end

-- ===========================================================================
function OnProcessNotification(playerID, notificationID, activatedByUser)
    if not CuiSettings:GetBoolean(CuiSettings.POPUP_HISTORIC) then return end -- CUI
    if playerID == Game.GetLocalPlayer() then -- Was it for us?
        local pNotification = NotificationManager.Find(playerID, notificationID)
        if pNotification and pNotification:GetType() == HISTORIC_MOMENT_HASH then
            local momentID = pNotification:GetValue("MomentID")
            if momentID then
                local popupData = {}
                popupData.showAnim = true
                popupData.momentID = momentID
                popupData.playerID = playerID
                popupData.notificationID = notificationID
                popupData.activatedByUser = activatedByUser

                -- Only automatically show moments of interest level 3 and above
                if not activatedByUser then
                    local momentData = Game.GetHistoryManager():GetMomentData(
                                           momentID)
                    local momentInfo = momentData and
                                           GameInfo.Moments[momentData.Type] or
                                           nil
                    if momentInfo and momentInfo.InterestLevel <
                        AUTO_SHOW_INTEREST_LEVEL then return end

                    UI.PlaySound("Pride_Moment")

                    -- If this is not an appropriate time, queue this.
                    if not UI.CanShowPopup(GetPopupPriority()) then
                        -- Add to queue
                        table.insert(m_kQueuedPopups, popupData)
                        return
                    end
                end

                ShowNewTimelineMoment(popupData)

            else
                UI.DataError(
                    "Moment Notification received, but is missing 'MomentID' variant. PlayerID=" ..
                        tostring(playerID) .. ", NotificationID=" ..
                        tostring(notificationID))
            end
        end
    end
end

-- ===========================================================================
function ResetTimeline()
    m_CurrentEra = -1
    m_MomentStackInstance = nil
    m_SmallMomentIM:ResetInstances()
    m_LargeMomentIM:ResetInstances()
    m_NewSmallMomentIM:ResetInstances()
    m_NewLargeMomentIM:ResetInstances()
    m_LargeIllustrationIM:ResetInstances()
    m_SmallMomentStackIM:ResetInstances()
    m_EraLabelIM:ResetInstances()
    m_TimelinePaddingIM:ResetInstances()
    for _, instanceManager in ipairs(DATA_ILLUSTRATIONS_MAP) do
        instanceManager:ResetInstances()
    end
end

-- ===========================================================================
function DisplayTimeline(showAnim)

    -- Never show
    if GameConfiguration.IsHotseat() and not m_isLocalPlayerTurn then return end

    -- Ensure screen width is valid and up to date
    if m_ScreenWidth <= 0 then m_ScreenWidth = UIManager:GetScreenSizeVal() end

    showAnim = showAnim and
                   Options.GetUserOption("Interface",
                                         "PlayHistoricMomentAnimation") ~= 0

    ResetTimeline()

    local localPlayerID = Game.GetLocalPlayer()
    local pPlayerConfig = PlayerConfigurations[localPlayerID]
    Controls.ModalScreenTitle:SetText(Locale.ToUpper(
                                          Locale.Lookup(
                                              "LOC_HISTORY_TIMELINE_TITLE",
                                              pPlayerConfig:GetCivilizationDescription())))

    local allPrideMoments = Game.GetHistoryManager():GetAllMomentsData(
                                localPlayerID, MIN_INTEREST_LEVEL)
    local numPrideMoments = table.count(allPrideMoments)
    if numPrideMoments > 0 then

        for i, momentData in ipairs(allPrideMoments) do

            if m_CurrentEra ~= momentData.GameEra then
                m_MomentStackInstance = nil
                m_CurrentEra = momentData.GameEra
                AddEraSeparator(momentData.GameEra)
            end

            AddMoment(momentData,
                      showAnim and
                          (m_CurrentMoment < 0 and i == numPrideMoments or
                              momentData.ID == m_CurrentMoment))

            if m_CurrentMoment ~= -1 and momentData.ID == m_CurrentMoment then
                break
            end
        end

        -- Add padding at the end of stack to keep last moment centered
        Controls.TimelineStack:CalculateSize()
        if Controls.TimelineStack:GetSizeX() > MIN_WIDTH_FOR_PADDING then
            AddPadding((m_ScreenWidth / 2) - (MOMENT_WIDTH / 2) -
                           TIMELINE_STACK_X_OFFSET_SCROLL)
        end
        RealizeStackSize()

        Controls.EmptyTimelineMessage:SetHide(true)
    else
        Controls.EmptyTimelineMessage:SetHide(false)
    end

    -- From Civ6_styles: FullScreenVignetteConsumer
    Controls.ScreenAnimIn:SetToBeginning()
    Controls.ScreenAnimIn:Play()
    LuaEvents.GovPan_PostOpen()

    Show()
end

-- ===========================================================================
function AddMoment(momentData, isNewMoment)
    local momentInfo = GameInfo.Moments[momentData.Type]
    if momentInfo then

        local instance
        local frameTexture

        if momentInfo.InterestLevel > MIN_INTEREST_LEVEL then
            m_MomentStackInstance = nil
            instance =
                (isNewMoment and m_NewLargeMomentIM or m_LargeMomentIM):GetInstance()
            frameTexture = "Historian_NodeLarge"
        elseif momentInfo.InterestLevel >= MIN_INTEREST_LEVEL then
            if m_MomentStackInstance == nil or
                m_MomentStackInstance.DATA_FIELD_NUM_INSTANCES >= 3 then
                m_MomentStackInstance = m_SmallMomentStackIM:GetInstance()
                m_MomentStackInstance.DATA_FIELD_NUM_INSTANCES = 0
            end
            m_MomentStackInstance.DATA_FIELD_NUM_INSTANCES =
                m_MomentStackInstance.DATA_FIELD_NUM_INSTANCES + 1
            instance =
                (isNewMoment and m_NewSmallMomentIM or m_SmallMomentIM):GetInstance(
                    m_MomentStackInstance.Root)
            frameTexture = "Historian_NodeSmall"
        else
            UI.DataError(
                "@sbatista: Adding a moment with interest level of 0, this shouldn't have happened.")
            return
        end

        if momentData.HasEverBeenCommemorated then
            frameTexture = frameTexture .. "_Com"
        end

        local momentDate = Calendar.MakeYearStr(momentData.Turn)
        local momentScore = momentData.EraScore and momentData.EraScore or 0

        instance.Frame:SetTexture(frameTexture)
        instance.Description:SetText(momentData.InstanceDescription)
        if (momentScore ~= 0) then
            instance.Effect:SetText(Locale.Lookup("LOC_HISTORY_MOMENT_EFFECTS",
                                                  momentDate, momentData.Turn,
                                                  "+" .. momentScore))
        else
            instance.Effect:SetText(Locale.Lookup(
                                        "LOC_HISTORY_MOMENT_EFFECTS_NO_SCORE",
                                        momentDate, momentData.Turn))
        end

        if momentInfo.IconTexture then
            SetIconTexture(instance, momentInfo.IconTexture,
                           momentInfo.MomentType)
        end

        if momentInfo.BackgroundTexture then
            AddIllustration(instance, momentInfo.BackgroundTexture, nil,
                            momentInfo.MomentType)
        end

        if momentInfo.MomentIllustrationType then
            local illustrations =
                m_CachedIllustrations[momentInfo.MomentIllustrationType]
            if illustrations then
                for _, dataPair in ipairs(momentData.ExtraData) do
                    local dataType = dataPair.DataType
                    local dataValue = dataPair.DataValue
                    if dataType and dataValue then
                        local illustrationData = illustrations[dataType]
                        if illustrationData then
                            local typeMap = DATA_TYPE_MAP[dataType]
                            local textureKey =
                                typeMap and typeMap(dataValue) or dataValue
                            local texture = illustrationData[textureKey]
                            if texture then
                                AddIllustration(instance, texture, dataType,
                                                momentInfo.MomentType)
                            end
                        end
                    else
                        UI.DataError("Malformed ExtraData in Moment { ID='" ..
                                         momentData.ID .. "', Type='" ..
                                         momentData.Type ..
                                         "' }, expected DataType and DataValue fields")
                    end
                end
            else
                UI.DataError(
                    "No data was found on MomentIllustrations table where MomentIllustrationType='" ..
                        momentInfo.MomentIllustrationType .. "'")
            end
        end

        -- DEBUGGING:
        -- instance.Root:SetToolTipString(DebugMomentData(momentData));
        instance.Root:SetToolTipString(Locale.Lookup(momentInfo.Description))

        if isNewMoment then
            instance.Root:Play()
            UI.PlaySound("Pride_Moment_Anim")
        end
    else
        UI.DataError("No data was found on Moments table for Moment { ID='" ..
                         tostring(momentData.ID) .. "', Type='" ..
                         tostring(momentData.Type) .. "' }")
    end
end

-- ===========================================================================
function AddIllustration(instance, texture, dataType, momentType)
    if instance.Illustrations then
        local instanceManager = DATA_ILLUSTRATIONS_MAP[dataType]
        instanceManager:GetInstance(instance.Illustrations).Root:SetTexture(
            texture)
    else
        UI.DataError("Moment '" .. momentType ..
                         "' attempted to load illustration '" .. texture ..
                         "' into a nil control. Check Moments data to ensure 'BackgroundTexture' only exists on InterestLevel 2 and 3 moments")
    end
end

-- ===========================================================================
function AddEraSeparator(era)
    local eraData = GameInfo.Eras[era]
    if eraData then
        local instance = m_EraLabelIM:GetInstance()
        instance.EraTitle:SetText(Locale.ToUpper(Locale.Lookup(eraData.Name)))
        instance.EraTitle:SetOffsetY(25 + instance.EraTitle:GetSizeX() / 2)
    end
end

-- ===========================================================================
function AddPadding(width) m_TimelinePaddingIM:GetInstance().Root
    :SetSizeX(width) end

-- ===========================================================================
function SetIconTexture(instance, texture, momentType)
    if instance.Icon then
        instance.Icon:SetTexture(texture)
    else
        UI.DataError("Moment '" .. momentType .. "' attempted to load icon '" ..
                         texture ..
                         "' into a nil control. Check Moments data to ensure 'IconTexture' only exists on InterestLevel 1 moments")
    end
end

-- ===========================================================================
function OnScroll(scrollPanel, scrollAmount)
    if scrollAmount == 0 or scrollAmount == 1.0 then
        if m_lastPercent == scrollAmount then return end
        UI.PlaySound("UI_TechTree_ScrollTick_End")
    else
        UI.PlaySound("UI_TechTree_ScrollTick")
    end
    m_lastPercent = scrollAmount
end

-- ===========================================================================
function RealizeStackSize()
    Controls.TimelineStack:CalculateSize()

    local stackSizeX = Controls.TimelineStack:GetSizeX()
    local shouldScroll = stackSizeX > m_ScreenWidth
    local bgSize = math.max(stackSizeX + TIMELINE_STACK_X_OFFSET_SCROLL,
                            m_ScreenWidth)

    Controls.TopPattern:SetSizeX(bgSize)
    Controls.BottomPattern:SetSizeX(bgSize)

    Controls.TimelineStack:SetAnchor(shouldScroll and "L,C" or "C,C")
    Controls.TimelineStack:SetOffsetX(shouldScroll and
                                          TIMELINE_STACK_X_OFFSET_SCROLL or
                                          TIMELINE_STACK_X_OFFSET_NO_SCROLL)
    Controls.TimelineScroller:HideScrollBar(not shouldScroll)

    if shouldScroll then Controls.TimelineScroller:SetScrollValue(1) end
end

-- ===========================================================================
-- Show the next the queue
function ShowNextQueuedPopup()

    -- Find first entry in table, display that, then remove it from the internal queue
    for i, entry in ipairs(m_kQueuedPopups) do
        ShowNewTimelineMoment(entry)
        table.remove(m_kQueuedPopups, i)
        break
    end

end

-- ===========================================================================
function Show()
    if ContextPtr:IsHidden() then
        UI.PlaySound("UI_Screen_Open")

        local priority = GetPopupPriority()
        local kParameters = GetPopupParameters()
        UIManager:QueuePopup(ContextPtr, priority, kParameters)

        -- Change our parent to be 'Screens' when raised from an active game so the navigational hooks draw on top of it
        ContextPtr:ChangeParent(ContextPtr:LookUpControl(
                                    "/InGame/" ..
                                        (m_isOpenFromEndGame and
                                            "AdditionalUserInterfaces" or
                                            "Screens")))

        -- From ModalScreen_PlayerYieldsHelper
        if not RefreshYields() then
            Controls.Vignette:SetSizeY(m_TopPanelConsideredHeight)
        else
            Controls.YieldsContainer:SetHide(m_isOpenFromEndGame)
        end
        LuaEvents.HistoricMoments_Opened()
    end
end

-- ===========================================================================
function Close()
    if ContextPtr:IsVisible() then
        UIManager:DequeuePopup(ContextPtr)
        UI.PlaySound("UI_Screen_Close")
        LuaEvents.HistoricMoments_Closed()
    end
end

-- ===========================================================================
function OnClose() Close() end

-- ===========================================================================
function OnUpdateUI(type, tag, iData1, iData2, strData1)
    if type == SystemUpdateUI.ScreenResize then
        m_ScreenWidth = UIManager:GetScreenSizeVal()
    end
end

-- ===========================================================================
function OnInputHandler(pInputStruct)
    local uiMsg = pInputStruct:GetMessageType()
    if (uiMsg == KeyEvents.KeyUp and pInputStruct:GetKey() == Keys.VK_ESCAPE) then
        Close()
        return true
    end
    return false
end

-- ===========================================================================
function CacheMomentIllustrations()
    for illustration in GameInfo.MomentIllustrations() do
        -- First table is indexed by MomentIllustrationType in Moments database table
        local illustrationType =
            m_CachedIllustrations[illustration.MomentIllustrationType]
        if not illustrationType then
            illustrationType = {}
            m_CachedIllustrations[illustration.MomentIllustrationType] =
                illustrationType
        end
        -- Second table is indexed by DataType derived from moment's ExtraData table
        local typeHash = DB.MakeHash(illustration.MomentDataType)
        local dataType = illustrationType[typeHash]
        if not dataType then
            dataType = {}
            illustrationType[typeHash] = dataType
        end
        -- Third table is indexed via DataValue derived from moment's ExtraData table
        dataType[illustration.GameDataType] = illustration.Texture
    end
end

-- ===========================================================================
function ToggleHistoricMomentsScreen(showAnim)
    if (ContextPtr:IsHidden()) then
        m_isOpenFromEndGame = false
        m_CurrentMoment = -1
        DisplayTimeline(showAnim)
    else
        Close()
    end
end

-- ===========================================================================
function ToggleFromEndGame(parentControl)
    if (ContextPtr:IsHidden()) then
        m_isOpenFromEndGame = true
        m_CurrentMoment = -1
        DisplayTimeline()
    else
        Close()
    end
end

-- ===========================================================================
function OnUIIdle()
    -- The UI is idle, are we waiting to show a popup?
    if UI.CanShowPopup(GetPopupPriority()) then ShowNextQueuedPopup() end
end

-- ===========================================================================
function OnLocalPlayerTurnBegin() m_isLocalPlayerTurn = true end

-- ===========================================================================
function OnLocalPlayerTurnEnd()
    m_isLocalPlayerTurn = false
    if GameConfiguration.IsHotseat() and ContextPtr:IsVisible() then Close() end
end

-- ===========================================================================
function OnEndGame()
    if UIManager:IsInPopupQueue(ContextPtr) then
        UIManager:DequeuePopup(ContextPtr)
    end
end

-- ===========================================================================
function Initialize()
    ContextPtr:SetHide(true)
    ContextPtr:SetInputHandler(OnInputHandler, true)

    Controls.Close:RegisterCallback(Mouse.eLClick, OnClose)
    Controls.RightClickCloser:RegisterCallback(Mouse.eRClick, OnClose)
    Controls.TimelineScroller:RegisterScrollCallback(OnScroll)

    Events.SystemUpdateUI.Add(OnUpdateUI)
    Events.NotificationActivated.Add(OnProcessNotification)
    Events.LocalPlayerTurnBegin.Add(OnLocalPlayerTurnBegin)
    Events.LocalPlayerTurnEnd.Add(OnLocalPlayerTurnEnd)
    Events.TeamVictory.Add(OnEndGame)
    Events.UIIdle.Add(OnUIIdle)

    LuaEvents.PrideMoments_ToggleTimeline.Add(ToggleHistoricMomentsScreen)
    LuaEvents.Advisor_ToggleTimeline.Add(ToggleHistoricMomentsScreen)
    LuaEvents.EndGameMenu_OpenHistoricMoments.Add(ToggleFromEndGame)
    LuaEvents.HistoricMoments_Close.Add(OnClose) -- LaunchBar
    LuaEvents.ShowEndGame.Add(OnEndGame)

    CacheMomentIllustrations()

    m_TopPanelConsideredHeight = Controls.Vignette:GetSizeY() - TOP_PANEL_OFFSET
end
if HasCapability("CAPABILITY_HISTORIC_MOMENTS") then Initialize() end
