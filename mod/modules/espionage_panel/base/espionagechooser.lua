-- ===========================================================================
--
--    Slideout panel for selecting a new destination for a spy unit
--
-- ===========================================================================
include("InstanceManager")
include("AnimSidePanelSupport")
include("SupportFunctions")
include("EspionageSupport")
include("Colors")
include("cui_helper")

-- ===========================================================================
--    CONSTANTS
-- ===========================================================================
local RELOAD_CACHE_ID = "EspionageChooser" -- Must be unique (usually the same as the file name)
local MAX_BEFORE_TRUNC_CHOOSE_NEXT = 210

local EspionageChooserModes = {DESTINATION_CHOOSER = 0, MISSION_CHOOSER = 1}

local MISSION_CHOOSER_MISSIONSCROLLPANEL_RELATIVE_SIZE_Y = -132
local DESTINATION_CHOOSER_MISSIONSCROLLPANEL_RELATIVE_SIZE_Y = -267

local DISTRICT_IM = "DistrictIM"
local DISTRICT_SCROLL_POS = "DistrictScrollPos"

local MAX_DISTRICTS_TO_SHOW = 8 -- CUI: before xp2

-- ===========================================================================
--    MEMBERS
-- ===========================================================================
local m_AnimSupport  -- AnimSidePanelSupport

-- Current EspionageChooserMode
local m_currentChooserMode = -1

-- Instance managers
local m_RouteChoiceIM = InstanceManager:new("DestinationInstance", "DestinationButton", Controls.DestinationStack)
local m_MissionStackIM = InstanceManager:new("MissionInstance", "MissionButton", Controls.MissionStack)

-- Currently selected spy
local m_spy = nil

-- While in DESTINATION_CHOOSER - Currently selected destination
-- While in MISSION_CHOOSER - City where the selected spy resides
local m_city = nil

local cui_filterList = {}
local cui_playerList = {}
local cui_filterSelected = 1
local cui_filterSelectedName = "LOC_ROUTECHOOSER_FILTER_ALL"
local cui_filteredCivs = {}

local CUI_AVAILABLE_DISTRICTS = {}
CUI_AVAILABLE_DISTRICTS[1] = {button = "CityCenterSortButton", dType = "DISTRICT_CITY_CENTER"}
CUI_AVAILABLE_DISTRICTS[2] = {button = "CampusSortButton", dType = "DISTRICT_CAMPUS"}
CUI_AVAILABLE_DISTRICTS[3] = {button = "CommercialSortButton", dType = "DISTRICT_COMMERCIAL_HUB"}
CUI_AVAILABLE_DISTRICTS[4] = {button = "IndustrialSortButton", dType = "DISTRICT_INDUSTRIAL_ZONE"}
CUI_AVAILABLE_DISTRICTS[5] = {button = "NeighborhoodSortButton", dType = "DISTRICT_NEIGHBORHOOD"}
CUI_AVAILABLE_DISTRICTS[6] = {button = "TheaterSortButton", dType = "DISTRICT_THEATER"}
CUI_AVAILABLE_DISTRICTS[7] = {button = "SpacePortSortButton", dType = "DISTRICT_SPACEPORT"}
CUI_AVAILABLE_DISTRICTS[8] = {button = "DamSortButton", dType = "DISTRICT_DAM"}
local cui_sortBy = -1

-- ===========================================================================
function Refresh()
    if m_spy == nil then
        UI.DataError("m_spy is nil. Expected to be currently selected spy.")
        Close()
        return
    end

    if m_city == nil and m_currentChooserMode == EspionageChooserModes.MISSION_CHOOSER then
        UI.DataError(
            "m_city is nil while updating espionage mission chooser. Expected to be city spy currently resides in."
        )
        Close()
        return
    end

    RefreshTop()
    RefreshBottom()
end

-- ===========================================================================
function RefreshTop()
    if m_currentChooserMode == EspionageChooserModes.DESTINATION_CHOOSER then
        --
        -- DESTINATION_CHOOSER
        Controls.Title:SetText(Locale.ToUpper("LOC_ESPIONAGECHOOSER_PANEL_HEADER"))

        -- Controls that should never be visible in the DESTINATION_CHOOSER
        Controls.ActiveBoostContainer:SetHide(true)
        Controls.NoActiveBoostLabel:SetHide(true)

        -- CUI: new top
        Controls.DistrictInfo:SetHide(true)
        Controls.SelectACityMessage:SetHide(true)
        Controls.BannerBase:SetHide(true)
        Controls.DistrictsScrollLeftButton:SetHide(true)
        Controls.DistrictsScrollRightButton:SetHide(true)
        Controls.DistrictInfo:SetHide(true)
        Controls.SelectACityMessage:SetHide(true)
        Controls.CivFilterPulldown:SetHide(false)
        Controls.DistrictFilter:SetHide(false)
        CuiRefreshFilters()
    else
        --
        -- MISSION_CHOOSER
        Controls.Title:SetText(Locale.ToUpper("LOC_ESPIONAGECHOOSER_CHOOSE_MISSION"))

        -- Controls that should never be visible in the MISSION_CHOOSER
        Controls.SelectACityMessage:SetHide(true)
        Controls.DistrictInfo:SetHide(true)

        -- Controls that should always be visible in the MISSION_CHOOSER
        Controls.BannerBase:SetHide(false)

        UpdateCityBanner(m_city)

        -- Update active gain sources boost message
        local player = Players[Game.GetLocalPlayer()]
        local playerDiplomacy = player:GetDiplomacy()
        if playerDiplomacy then
            local boostedTurnsRemaining = playerDiplomacy:GetSourceTurnsRemaining(m_city)
            if boostedTurnsRemaining > 0 then
                TruncateStringWithTooltip(
                    Controls.ActiveBoostLabel,
                    MAX_BEFORE_TRUNC_CHOOSE_NEXT,
                    Locale.Lookup("LOC_ESPIONAGECHOOSER_GAIN_SOURCES_ACTIVE", boostedTurnsRemaining)
                )

                -- Controls.ActiveBoostLabel:SetText(Locale.Lookup("LOC_ESPIONAGECHOOSER_GAIN_SOURCES_ACTIVE", boostedTurnsRemaining));
                Controls.ActiveBoostContainer:SetHide(false)
                Controls.NoActiveBoostLabel:SetHide(true)
            else
                Controls.ActiveBoostContainer:SetHide(true)
                Controls.NoActiveBoostLabel:SetHide(false)
            end
        end

        -- CUI: new top
        Controls.CivFilterPulldown:SetHide(true)
        Controls.DistrictFilter:SetHide(true)
    end
end

-- ===========================================================================
function RefreshBottom()
    if m_currentChooserMode == EspionageChooserModes.DESTINATION_CHOOSER then
        -- DESTINATION_CHOOSER
        if m_city then
            -- Controls.DestinationPanel:SetHide(true);
            CuiMissionPanelMoveToRight() -- CUI
            Controls.MissionPanel:SetHide(false)
            Controls.PossibleMissionsLabel:SetHide(false)
            Controls.DestinationChooserButtons:SetHide(false)
            Controls.MissionBackground:SetParentRelativeSizeY(DESTINATION_CHOOSER_MISSIONSCROLLPANEL_RELATIVE_SIZE_Y) -- CUI
            RefreshMissionList()
            RefreshDestinationList()
        else
            Controls.DestinationPanel:SetHide(false)
            Controls.MissionPanel:SetHide(true)
            RefreshDestinationList()
        end
    else
        -- MISSION_CHOOSER
        -- Controls that should never be visible in the MISSION_CHOOSER
        CuiMissionPanelMoveToLeft() -- CUI
        Controls.DestinationPanel:SetHide(true)
        Controls.PossibleMissionsLabel:SetHide(true)
        Controls.DestinationChooserButtons:SetHide(true)

        -- Controls that should always be visible in the MISSION_CHOOSER
        Controls.MissionPanel:SetHide(false)

        Controls.MissionBackground:SetParentRelativeSizeY(MISSION_CHOOSER_MISSIONSCROLLPANEL_RELATIVE_SIZE_Y) -- CUI
        RefreshMissionList()
    end
end

-- ===========================================================================
-- Refresh the destination list with all revealed non-city state owned cities
-- ===========================================================================
function RefreshDestinationList()
    -- CUI: override
    local localPlayer = Players[Game.GetLocalPlayer()]

    m_RouteChoiceIM:ResetInstances()

    cui_playerList = {}
    -- Add each players cities to destination list
    local players = Game.GetPlayers()
    for i, player in ipairs(players) do
        -- Only show full civs
        if CuiCivCheck(player) then
            table.insert(cui_playerList, player)
        end
    end

    cui_filteredCivs = {}
    -- Filter Destinations by active Filter
    if cui_filterList[cui_filterSelected].FilterFunction ~= nil then
        cui_filterList[cui_filterSelected].FilterFunction()
    else
        for _, player in ipairs(cui_playerList) do
            table.insert(cui_filteredCivs, player)
        end
    end

    for _, player in ipairs(cui_filteredCivs) do
        AddPlayerCities(player)
    end

    Controls.DestinationPanel:CalculateInternalSize()
end

-- ===========================================================================
-- Refresh the mission list with counterspy targets for cities the player owns
-- and offensive spy operations for cities owned by other players
-- ===========================================================================
function RefreshMissionList()
    m_MissionStackIM:ResetInstances()

    -- Determine if this is a owned by the local player
    if m_city:GetOwner() == Game.GetLocalPlayer() then
        -- If we own this city show a list of possible counterspy targets
        for operation in GameInfo.UnitOperations() do
            if operation.OperationType == "UNITOPERATION_SPY_COUNTERSPY" then
                local cityPlot = Map.GetPlot(m_city:GetX(), m_city:GetY())
                local canStart, results = UnitManager.CanStartOperation(m_spy, operation.Hash, cityPlot, false, true)
                if canStart then
                    -- Check the CanStartOperation results for a target district plot
                    for i, districtPlotID in ipairs(results[UnitOperationResults.PLOTS]) do
                        AddCounterspyOperation(operation, districtPlotID)
                    end
                end
            end
        end
    else
        -- Fill mission stack with possible missions at selected city
        for operation in GameInfo.UnitOperations() do
            if operation.CategoryInUI == "OFFENSIVESPY" then
                local cityPlot = Map.GetPlot(m_city:GetX(), m_city:GetY())
                local canStart, results = UnitManager.CanStartOperation(m_spy, operation.Hash, cityPlot, false, true)
                if canStart then
                    AddAvailableOffensiveOperation(operation, results, cityPlot)
                else
                    ---- If we're provided with a failure reason then show the mission disabled
                    if results and results[UnitOperationResults.FAILURE_REASONS] then
                        AddDisabledOffensiveOperation(operation, results, cityPlot)
                    end
                end
            end
        end
    end

    Controls.MissionScrollPanel:CalculateInternalSize()
end

-- ===========================================================================
function AddCounterspyOperation(operation, districtPlotID)
    local missionInstance = m_MissionStackIM:GetInstance()

    -- Find district
    local cityDistricts = m_city:GetDistricts()
    for i, district in cityDistricts:Members() do
        local districtPlot = Map.GetPlot(district:GetX(), district:GetY())
        if districtPlot:GetIndex() == districtPlotID then
            local districtInfo = GameInfo.Districts[district:GetType()]

            -- Update mission info
            missionInstance.MissionName:SetText(Locale.Lookup(operation.Description))
            missionInstance.MissionDetails:SetText(
                Locale.Lookup("LOC_ESPIONAGECHOOSER_COUNTERSPY", Locale.Lookup(districtInfo.Name))
            )
            missionInstance.MissionDetails:SetColorByName("White")

            -- Update mission icon
            local iconString = "ICON_" .. districtInfo.DistrictType
            missionInstance.TargetDistrictIcon:SetIcon(iconString)
            missionInstance.TargetDistrictIcon:SetHide(false)
            missionInstance.MissionIcon:SetHide(true)

            -- If this is the mission choose set callback to open up mission briefing
            if m_currentChooserMode == EspionageChooserModes.MISSION_CHOOSER then
                missionInstance.MissionButton:RegisterCallback(
                    Mouse.eLClick,
                    function()
                        OnCounterspySelected(districtPlot)
                    end
                )
            end
        end
    end

    missionInstance.MissionStatsStack:SetHide(true)

    -- While in DESTINATION_CHOOSER mode we don't want the buttons to act
    -- like buttons since they cannot be clicked in that mode
    if m_currentChooserMode == EspionageChooserModes.DESTINATION_CHOOSER then
        missionInstance.MissionButton:SetDisabled(true)
        missionInstance.MissionButton:SetVisState(0)
    else
        missionInstance.MissionButton:SetDisabled(false)
    end

    -- Default the selector brace to hidden
    missionInstance.SelectorBrace:SetColor(UI.GetColorValueFromHexLiteral(0x00FFFFFF))
end

-- ===========================================================================
function AddOffensiveOperation(operation, result, targetCityPlot)
    local missionInstance = m_MissionStackIM:GetInstance()
    missionInstance.MissionButton:SetDisabled(false)

    -- Update mission name
    missionInstance.MissionName:SetText(Locale.Lookup(operation.Description))

    -- Update mission icon
    missionInstance.MissionIcon:SetIcon(operation.Icon)
    missionInstance.MissionIcon:SetHide(false)
    missionInstance.TargetDistrictIcon:SetHide(true)

    RefreshMissionStats(missionInstance, operation, result, m_spy, m_city, targetCityPlot)

    missionInstance.MissionStatsStack:SetHide(false)
    missionInstance.MissionStatsStack:CalculateSize()

    -- Default the selector brace to hidden
    missionInstance.SelectorBrace:SetColor(UI.GetColorValueFromHexLiteral(0x00FFFFFF))

    return missionInstance
end

-- ===========================================================================
function AddDisabledOffensiveOperation(operation, result, targetCityPlot)
    local missionInstance = AddOffensiveOperation(operation, result, targetCityPlot)

    -- Update mission description with reason the mission is disabled
    if result and result[UnitOperationResults.FAILURE_REASONS] then
        local failureReasons = result[UnitOperationResults.FAILURE_REASONS]
        local missionDetails = ""

        -- Add all given reasons into mission details
        for i, reason in ipairs(failureReasons) do
            if missionDetails == "" then
                missionDetails = reason
            else
                missionDetails = missionDetails .. "[NEWLINE]" .. reason
            end
        end

        missionInstance.MissionDetails:SetText(missionDetails)
        missionInstance.MissionDetails:SetColorByName("Red")
    end

    missionInstance.MissionStack:CalculateSize()
    missionInstance.MissionButton:DoAutoSize()

    -- Disable mission button
    missionInstance.MissionButton:SetDisabled(true)
end

-- ===========================================================================
function AddAvailableOffensiveOperation(operation, result, targetCityPlot)
    local missionInstance = AddOffensiveOperation(operation, result, targetCityPlot)

    -- Update mission details
    missionInstance.MissionDetails:SetText(GetFormattedOperationDetailText(operation, m_spy, m_city))
    missionInstance.MissionDetails:SetColorByName("White")

    missionInstance.MissionStack:CalculateSize()
    missionInstance.MissionButton:DoAutoSize()

    -- If this is the mission choose set callback to open up mission briefing
    if m_currentChooserMode == EspionageChooserModes.MISSION_CHOOSER then
        missionInstance.MissionButton:RegisterCallback(
            Mouse.eLClick,
            function()
                OnMissionSelected(operation, missionInstance, targetCityPlot)
            end
        )
    end

    -- While in DESTINATION_CHOOSER mode we don't want the buttons to act
    -- like buttons since they cannot be clicked in that mode
    if m_currentChooserMode == EspionageChooserModes.DESTINATION_CHOOSER then
        missionInstance.MissionButton:SetDisabled(true)
        missionInstance.MissionButton:SetVisState(0)
    else
        missionInstance.MissionButton:SetDisabled(false)
    end
end

-- ===========================================================================
function OnCounterspySelected(districtPlot)
    local tParameters = {}
    tParameters[UnitOperationTypes.PARAM_X] = districtPlot:GetX()
    tParameters[UnitOperationTypes.PARAM_Y] = districtPlot:GetY()

    UnitManager.RequestOperation(m_spy, UnitOperationTypes.SPY_COUNTERSPY, tParameters)
end

-- ===========================================================================
function OnMissionSelected(operation, instance, targetCityPlot)
    LuaEvents.EspionageChooser_ShowMissionBriefing(operation.Hash, m_spy:GetID(), targetCityPlot)

    -- Hide all selection borders before selecting another
    for i = 1, m_MissionStackIM.m_iCount, 1 do
        local otherInstances = m_MissionStackIM:GetAllocatedInstance(i)
        if otherInstances then
            otherInstances.SelectorBrace:SetColor(UI.GetColorValue("COLOR_CLEAR"))
        end
    end

    -- Show selected border over instance
    instance.SelectorBrace:SetColor(UI.GetColorValue("COLOR_WHITE"))
end

-- ===========================================================================
function UpdateCityBanner(city)
    local backColor, frontColor = UI.GetPlayerColors(city:GetOwner())

    Controls.BannerBase:SetColor(backColor)
    Controls.CityName:SetColor(frontColor)
    TruncateStringWithTooltip(Controls.CityName, 195, Locale.ToUpper(city:GetName()))
    Controls.BannerBase:SetHide(false)

    if m_currentChooserMode == EspionageChooserModes.DESTINATION_CHOOSER then
        -- Update travel time
        local travelTime = UnitManager.GetTravelTime(m_spy, m_city)
        local establishTime = UnitManager.GetEstablishInCityTime(m_spy, m_city)
        local totalTravelTime = travelTime + establishTime
        Controls.TravelTime:SetColor(frontColor)
        Controls.TravelTime:SetText(tostring(totalTravelTime))
        Controls.TravelTimeIcon:SetColor(frontColor)
        Controls.TravelTimeStack:SetHide(false)

        -- Update travel time tool tip string
        Controls.BannerBase:SetToolTipString(
            Locale.Lookup("LOC_ESPIONAGECHOOSER_TRAVEL_TIME_TOOLTIP", travelTime, establishTime)
        )
    else
        Controls.TravelTimeStack:SetHide(true)
        Controls.BannerBase:SetToolTipString("")
    end
end

-- ===========================================================================
function AddPlayerCities(player)
    local playerCities = player:GetCities()
    for j, city in playerCities:Members() do
        -- Check if the city is revealed
        local localPlayerVis = PlayersVisibility[Game.GetLocalPlayer()]
        if localPlayerVis:IsRevealed(city:GetX(), city:GetY()) then
            if CuiHasDistrict(city) then
                AddDestination(city)
            end
        end
    end
end

-- ===========================================================================
function AddDestination(city)
    local destinationInstance = m_RouteChoiceIM:GetInstance()

    -- Update city name and banner color
    local backColor, frontColor = UI.GetPlayerColors(city:GetOwner())

    destinationInstance.BannerBase:SetColor(backColor)
    destinationInstance.CityName:SetColor(frontColor)

    -- Update capital indicator but never show it for city-states
    if city:IsCapital() and Players[city:GetOwner()]:IsMajor() then
        TruncateStringWithTooltip(
            destinationInstance.CityName,
            185,
            "[ICON_Capital] " .. Locale.ToUpper(city:GetName())
        )
    else
        TruncateStringWithTooltip(destinationInstance.CityName, 185, Locale.ToUpper(city:GetName()))
    end

    -- Update travel time
    local travelTime = UnitManager.GetTravelTime(m_spy, city)
    local establishTime = UnitManager.GetEstablishInCityTime(m_spy, city)
    local totalTravelTime = travelTime + establishTime
    destinationInstance.TravelTime:SetColor(frontColor)
    destinationInstance.TravelTime:SetText(tostring(totalTravelTime))
    destinationInstance.TravelTimeIcon:SetColor(frontColor)

    -- Update travel time tool tip string
    destinationInstance.BannerBase:SetToolTipString(
        Locale.Lookup("LOC_ESPIONAGECHOOSER_TRAVEL_TIME_TOOLTIP", travelTime, establishTime)
    )

    AddDistrictIcons(destinationInstance, city)

    -- CUI: Update Selector Brace
    if m_city ~= nil and city:GetName() == m_city:GetName() then
        destinationInstance.SelectorBrace:SetColor(1, 1, 1, 1)
        destinationInstance.DestinationButton:SetSelected(true)
    else
        destinationInstance.SelectorBrace:SetColor(1, 1, 1, 0)
        destinationInstance.DestinationButton:SetSelected(false)
    end

    -- Set button callback
    destinationInstance.DestinationButton:RegisterCallback(
        Mouse.eLClick,
        function()
            OnSelectDestination(city)
        end
    )
end

-- ===========================================================================
function AddDistrictIcons(kParentControl, pCity)
    -- CUI: override
    if kParentControl[DISTRICT_IM] == nil then
        kParentControl[DISTRICT_IM] =
            InstanceManager:new("CityDistrictInstance", "DistrictIcon", kParentControl.DistrictIconStack)
    end

    kParentControl[DISTRICT_IM]:ResetInstances()

    local pCityDistricts = pCity:GetDistricts()

    for _, item in pairs(CUI_AVAILABLE_DISTRICTS) do
        local kDistrictInst = {}
        local pDistrict = CuiGetMatchedDistrict(item.dType, pCityDistricts)
        if pDistrict then
            kDistrictInst = AddDistrictIcon(kParentControl[DISTRICT_IM], pCity, pDistrict)
        else
            kDistrictInst = CuiAddEmptyDistrictIcon(kParentControl[DISTRICT_IM]) -- CUI
        end
    end
end

-- ===========================================================================
function UpdateVisibleDistrictIcons(kParentControl, iScrollPos)
    local kDistrictIM = kParentControl[DISTRICT_IM]
    for i = 1, kDistrictIM.m_iCount, 1 do
        local kDistrictInst = kDistrictIM:GetAllocatedInstance(i)
        if kDistrictInst ~= nil then
            if i < iScrollPos or (i > iScrollPos + MAX_DISTRICTS_TO_SHOW - 1) then
                kDistrictInst.DistrictIcon:SetHide(true)
            else
                kDistrictInst.DistrictIcon:SetHide(false)
            end
        end
    end

    kParentControl[DISTRICT_SCROLL_POS] = iScrollPos

    if iScrollPos == 1 then
        kParentControl.DistrictsScrollLeftButton:SetDisabled(true)
        kParentControl.DistrictsScrollRightButton:SetDisabled(false)
    elseif iScrollPos >= (kDistrictIM.m_iCount - MAX_DISTRICTS_TO_SHOW + 1) then
        kParentControl.DistrictsScrollLeftButton:SetDisabled(false)
        kParentControl.DistrictsScrollRightButton:SetDisabled(true)
    else
        kParentControl.DistrictsScrollLeftButton:SetDisabled(false)
        kParentControl.DistrictsScrollRightButton:SetDisabled(false)
    end
end

-- ===========================================================================
function OnDistrictLeftScroll(kParentControl)
    local iNewScrollPos = kParentControl[DISTRICT_SCROLL_POS] - 1
    UpdateVisibleDistrictIcons(kParentControl, iNewScrollPos)
end

-- ===========================================================================
function OnDistrictRightScroll(kParentControl)
    local iNewScrollPos = kParentControl[DISTRICT_SCROLL_POS] + 1
    UpdateVisibleDistrictIcons(kParentControl, iNewScrollPos)
end

-- ===========================================================================
function AddDistrictIcon(kInstanceIM, pCity, pDistrict)
    if not pDistrict:IsComplete() then
        return nil
    end

    local kDistrictDef = GameInfo.Districts[pDistrict:GetType()]

    if kDistrictDef == nil or kDistrictDef.DistrictType == "DISTRICT_WONDER" then
        return nil
    end

    local kInstance = kInstanceIM:GetInstance()

    kInstance.DistrictIcon:SetAlpha(1.0) -- CUI
    kInstance.DistrictIcon:SetIcon("ICON_" .. kDistrictDef.DistrictType)
    local sToolTip = Locale.Lookup(kDistrictDef.Name)
    kInstance.DistrictIcon:SetToolTipString(sToolTip)

    return kInstance
end

-- ===========================================================================
function RefreshDistrictIcon(city, districtType, districtIcon)
    local hasDistrict = false
    local cityDistricts = city:GetDistricts()
    for i, district in cityDistricts:Members() do
        if district:IsComplete() then
            -- gets the district type of the currently selected district
            local districtInfo = GameInfo.Districts[district:GetType()]
            local currentDistrictType = districtInfo.DistrictType

            -- assigns currentDistrictType to be the general type of district (i.e. DISTRICT_HANSA becomes DISTRICT_INDUSTRIAL_ZONE)
            local replaces = GameInfo.DistrictReplaces[districtInfo.Hash]
            if (replaces) then
                currentDistrictType = GameInfo.Districts[replaces.ReplacesDistrictType].DistrictType
            end

            -- if this district is the type we are looking for, display that
            if currentDistrictType == districtType then
                hasDistrict = true
            end
        end
    end

    if hasDistrict then
        districtIcon:SetHide(false)
    else
        districtIcon:SetHide(true)
    end
end

-- ===========================================================================
function OnSelectDestination(city)
    m_city = city

    -- Look at the selected destination
    UI.LookAtPlot(m_city:GetX(), m_city:GetY())

    Refresh()
end

-- ===========================================================================
function TeleportToSelectedCity()
    if not m_city or not m_spy then
        return
    end

    local tParameters = {}
    tParameters[UnitOperationTypes.PARAM_X] = m_city:GetX()
    tParameters[UnitOperationTypes.PARAM_Y] = m_city:GetY()

    if
        (UnitManager.CanStartOperation(
            m_spy,
            UnitOperationTypes.SPY_TRAVEL_NEW_CITY,
            Map.GetPlot(m_city:GetX(), m_city:GetY()),
            tParameters
        ))
     then
        UnitManager.RequestOperation(m_spy, UnitOperationTypes.SPY_TRAVEL_NEW_CITY, tParameters)
        UI.SetInterfaceMode(InterfaceModeTypes.SELECTION)
    end
end

-- ===========================================================================
function Open()
    -- Set chooser mode based on interface mode
    if UI.GetInterfaceMode() == InterfaceModeTypes.SPY_TRAVEL_TO_CITY then
        m_currentChooserMode = EspionageChooserModes.DESTINATION_CHOOSER
    else
        m_currentChooserMode = EspionageChooserModes.MISSION_CHOOSER
    end

    -- Cache the selected spy
    local selectedUnit = UI.GetHeadSelectedUnit()
    if selectedUnit then
        local selectedUnitInfo = GameInfo.Units[selectedUnit:GetUnitType()]
        if selectedUnitInfo and selectedUnitInfo.Spy then
            m_spy = selectedUnit
        else
            m_spy = nil
            return
        end
    else
        m_spy = nil
        return
    end

    -- Set m_city depending on the mode
    if m_currentChooserMode == EspionageChooserModes.DESTINATION_CHOOSER then
        -- Clear m_city for Destination Chooser as it will be the city the player chooses
        m_city = nil
    else
        -- Set m_city to city where in for Mission Chooser as we only want missions from this city
        local spyPlot = Map.GetPlot(m_spy:GetX(), m_spy:GetY())
        local city = Cities.GetPlotPurchaseCity(spyPlot)
        m_city = city
    end

    if not m_AnimSupport:IsVisible() then
        m_AnimSupport:Show()
    end

    Refresh()

    -- Play opening sound
    UI.PlaySound("Tech_Tray_Slide_Open")
end

-- ===========================================================================
function Close()
    if m_AnimSupport:IsVisible() then
        m_AnimSupport:Hide()
        UI.SetInterfaceMode(InterfaceModeTypes.SELECTION)
        UI.PlaySound("Tech_Tray_Slide_Closed")
    end
end

-- ===========================================================================
function OnConfirmPlacement()
    -- If we're selecting a city we own and we're already there switch to the counterspy mission chooser
    local spyPlot = Map.GetPlot(m_spy:GetX(), m_spy:GetY())
    local spyCity = Cities.GetPlotPurchaseCity(spyPlot)
    if
        m_city:GetOwner() == Game.GetLocalPlayer() and spyCity:GetID() == m_city:GetID() and
            m_city:GetOwner() == spyCity:GetOwner()
     then
        m_currentChooserMode = EspionageChooserModes.MISSION_CHOOSER
        Refresh()
    else
        TeleportToSelectedCity()
        UI.PlaySound("UI_Spy_Confirm_Placement")
    end
end

-- ===========================================================================
function OnCancel()
    m_city = nil
    Refresh()
end

-- ===========================================================================
function OnInterfaceModeChanged(oldMode, newMode)
    if oldMode == InterfaceModeTypes.SPY_CHOOSE_MISSION and newMode ~= InterfaceModeTypes.SPY_TRAVEL_TO_CITY then
        if m_AnimSupport:IsVisible() then
            Close()
        end
    end
    if oldMode == InterfaceModeTypes.SPY_TRAVEL_TO_CITY and newMode ~= InterfaceModeTypes.SPY_CHOOSE_MISSION then
        if m_AnimSupport:IsVisible() then
            Close()
        end
    end

    if newMode == InterfaceModeTypes.SPY_TRAVEL_TO_CITY then
        Open()
    end
    if newMode == InterfaceModeTypes.SPY_CHOOSE_MISSION then
        Open()
    end
end

-- ===========================================================================
function OnUnitSelectionChanged(playerID, unitID, hexI, hexJ, hexK, bSelected, bEditable)
    -- Make sure we're the local player and not observing
    if playerID ~= Game.GetLocalPlayer() or playerID == -1 then
        return
    end

    -- Make sure the selected unit is a spy and that we don't have a current spy operation
    GoToProperInterfaceMode(UI.GetHeadSelectedUnit())
end

------------------------------------------------------------------
function OnUnitActivityChanged(playerID, unitID, eActivityType)
    -- Make sure we're the local player and not observing
    if playerID ~= Game.GetLocalPlayer() or playerID == -1 then
        return
    end

    GoToProperInterfaceMode(UI.GetHeadSelectedUnit())
end

-- ===========================================================================
function GoToProperInterfaceMode(spyUnit)
    local desiredInterfaceMode = nil

    if spyUnit and spyUnit:IsReadyToMove() then
        local spyUnitInfo = GameInfo.Units[spyUnit:GetUnitType()]
        if spyUnitInfo.Spy then
            -- Make sure the spy is awake
            local activityType = UnitManager.GetActivityType(spyUnit)
            if activityType == ActivityTypes.ACTIVITY_AWAKE then
                local spyPlot = Map.GetPlot(spyUnit:GetX(), spyUnit:GetY())
                local city = Cities.GetPlotPurchaseCity(spyPlot)
                if city and city:GetOwner() == Game.GetLocalPlayer() then
                    -- UI.SetInterfaceMode(InterfaceModeTypes.SPY_TRAVEL_TO_CITY);
                    desiredInterfaceMode = InterfaceModeTypes.SPY_TRAVEL_TO_CITY
                else
                    -- UI.SetInterfaceMode(InterfaceModeTypes.SPY_CHOOSE_MISSION);
                    desiredInterfaceMode = InterfaceModeTypes.SPY_CHOOSE_MISSION
                end
            end
        end
    end

    if desiredInterfaceMode then
        if UI.GetInterfaceMode() == desiredInterfaceMode then
            -- If already in the right interfacec mode then just refresh
            Open()
        else
            UI.SetInterfaceMode(desiredInterfaceMode)
        end
    else
        -- If not going to an espionage interface mode then close if we're open
        if m_AnimSupport:IsVisible() then
            Close()
        end
    end
end

------------------------------------------------------------------------------------------------
function OnLocalPlayerTurnEnd()
    if (GameConfiguration.IsHotseat()) then
        Close()
    end
end

-- ===========================================================================
function OnMissionBriefingClosed()
    if m_AnimSupport:IsVisible() then
        -- If we're shown and we close a mission briefing hide the selector brace for all to make sure it gets hidden probably
        for i = 1, m_MissionStackIM.m_iCount, 1 do
            local instance = m_MissionStackIM:GetAllocatedInstance(i)
            if instance then
                instance.SelectorBrace:SetColor(UI.GetColorValue("COLOR_CLEAR"))
            end
        end
    end
end

-- ===========================================================================
--    LUA Event
--    Explicit close (from partial screen hooks), part of closing everything,
-- ===========================================================================
function OnCloseAllExcept(contextToStayOpen)
    if contextToStayOpen == ContextPtr:GetID() then
        return
    end
    Close()
end

-- ===========================================================================
function OnClose()
    Close()
end

-- ===========================================================================
--    UI EVENT
-- ===========================================================================
function OnInit(isReload)
    if isReload then
        LuaEvents.GameDebug_GetValues(RELOAD_CACHE_ID)
    end
end

-- ===========================================================================
--    UI EVENT
-- ===========================================================================
function OnShutdown()
    LuaEvents.GameDebug_AddValue(RELOAD_CACHE_ID, "isVisible", m_AnimSupport:IsVisible())
    LuaEvents.GameDebug_AddValue(RELOAD_CACHE_ID, "selectedCity", m_city)
    LuaEvents.GameDebug_AddValue(RELOAD_CACHE_ID, "selectedSpy", m_spy)
    LuaEvents.GameDebug_AddValue(RELOAD_CACHE_ID, "currentChooserMode", m_currentChooserMode)
end

-- ===========================================================================
--    LUA EVENT
--    Reload support
-- ===========================================================================
function OnGameDebugReturn(context, contextTable)
    if context == RELOAD_CACHE_ID then
        if contextTable["currentChooserMode"] ~= nil then
            m_currentChooserMode = contextTable["currentChooserMode"]
        end
        if contextTable["selectedCity"] ~= nil then
            m_city = contextTable["selectedCity"]
        end
        if contextTable["selectedSpy"] ~= nil then
            m_spy = contextTable["selectedSpy"]
        end
        if contextTable["isVisible"] ~= nil and contextTable["isVisible"] then
            m_AnimSupport:Show()
            Refresh()
        end
    end
end

-- CUI =======================================================================
function CuiCivCheck(player)
    local localPlayer = Players[Game.GetLocalPlayer()]
    if player:IsMajor() then
        if
            (player:GetID() == localPlayer:GetID() or player:GetTeam() == -1 or localPlayer:GetTeam() == -1 or
                player:GetTeam() ~= localPlayer:GetTeam())
         then
            return true
        end
    end
    return false
end

-- CUI =======================================================================
function CuiOnFilterSelected(index, filterIndex)
    cui_filterSelected = filterIndex
    cui_filterSelectedName = cui_filterList[cui_filterSelected].FilterText
    Controls.FilterButton:SetText(cui_filterSelectedName)
    Refresh()
end

-- CUI =======================================================================
function CuiUpdateFilterArrow()
    if Controls.CivFilterPulldown:IsOpen() then
        Controls.PulldownOpenedArrow:SetHide(true)
        Controls.PulldownClosedArrow:SetHide(false)
    else
        Controls.PulldownOpenedArrow:SetHide(false)
        Controls.PulldownClosedArrow:SetHide(true)
    end
end

-- CUI =======================================================================
function CuiFilterByCiv(civTypeID)
    -- Clear Filter
    cui_filteredCivs = {}

    -- Filter by Civ Type ID
    for _, player in ipairs(cui_playerList) do
        local playerConfig = PlayerConfigurations[player:GetID()]
        if playerConfig:GetCivilizationTypeID() == civTypeID then
            table.insert(cui_filteredCivs, player)
        end
    end
end

-- CUI =======================================================================
function CuiFilterByCityStates()
    -- Clear Filter
    cui_filteredCivs = {}

    -- Filter only cities which aren't full civs meaning they're city-states
    for _, player in ipairs(cui_playerList) do
        local playerConfig = PlayerConfigurations[player:GetID()]
        if playerConfig:GetCivilizationLevelTypeID() ~= CivilizationLevelTypes.CIVILIZATION_LEVEL_FULL_CIV then
            table.insert(cui_filteredCivs, player)
        end
    end
end

-- CUI =======================================================================
function CuiRefreshFilters()
    local localPlayer = Players[Game.GetLocalPlayer()]

    -- Clear entries
    Controls.CivFilterPulldown:ClearEntries()
    cui_filterList = {}

    -- Add All Filter
    CuiAddFilter(Locale.Lookup("LOC_ROUTECHOOSER_FILTER_ALL"), nil)

    -- Add Filters by Civ
    local players = Game.GetPlayers()
    for i, player in ipairs(players) do
        -- Only show full civs
        if player:IsMajor() then
            if
                (player:GetID() == localPlayer:GetID() or player:GetTeam() == -1 or localPlayer:GetTeam() == -1 or
                    player:GetTeam() ~= localPlayer:GetTeam())
             then
                -- CUI todo
                local playerConfig = PlayerConfigurations[player:GetID()]
                local name = Locale.Lookup(GameInfo.Civilizations[playerConfig:GetCivilizationTypeID()].Name)
                CuiAddFilter(
                    name,
                    function()
                        CuiFilterByCiv(playerConfig:GetCivilizationTypeID())
                    end
                )
            end
        end
    end

    -- Add City State Filter
    for i, player in ipairs(players) do
        local pPlayerInfluence = Players[player:GetID()]:GetInfluence()
        if pPlayerInfluence:CanReceiveInfluence() then
            -- If the city's owner can receive influence then it is a city state so add the city state filter
            CuiAddFilter(Locale.Lookup("LOC_ROUTECHOOSER_FILTER_CITYSTATES"), CuiFilterByCityStates)
            break
        end
    end

    -- Add filters to pulldown
    for index, filter in ipairs(cui_filterList) do
        CuiBuildFilterEntry(index)
    end

    -- Different traders have different filters and filter orders
    cui_filterSelected = CuiGetFilterIndex(cui_filterSelectedName) or 1
    cui_filterSelectedName = cui_filterList[cui_filterSelected].FilterText
    Controls.FilterButton:SetText(cui_filterSelectedName)

    -- Calculate Internals
    Controls.CivFilterPulldown:CalculateInternals()

    CuiUpdateFilterArrow()
end

-- CUI =======================================================================
function CuiGetFilterIndex(filterName)
    for index, filter in ipairs(cui_filterList) do
        if filter.FilterText == filterName then
            return index
        end
    end
    return nil
end

-- CUI =======================================================================
function CuiAddFilter(filterName, filterFunction)
    -- Make sure we don't add duplicate filters
    if not CuiGetFilterIndex(filterName) then
        table.insert(cui_filterList, {FilterText = filterName, FilterFunction = filterFunction})
    end
end

-- CUI =======================================================================
function CuiBuildFilterEntry(filterIndex)
    local filterEntry = {}
    Controls.CivFilterPulldown:BuildEntry("FilterEntry", filterEntry)
    filterEntry.Button:SetText(cui_filterList[filterIndex].FilterText)
    filterEntry.Button:SetVoids(i, filterIndex)
end

-- CUI =======================================================================
function CuiGetMatchedDistrict(dType, districts)
    for _, district in districts:Members() do
        if district:IsComplete() then
            local districtInfo = GameInfo.Districts[district:GetType()]
            local currentDistrictType = districtInfo.DistrictType
            local replaces = GameInfo.DistrictReplaces[districtInfo.Hash]

            if replaces then
                currentDistrictType = GameInfo.Districts[replaces.ReplacesDistrictType].DistrictType
            end
            if currentDistrictType == dType then
                return district
            end
        end
    end
    return nil
end

-- CUI =======================================================================
function CuiAddEmptyDistrictIcon(kInstanceIM)
    local kInstance = kInstanceIM:GetInstance()
    kInstance.DistrictIcon:SetAlpha(0.0)
    kInstance.DistrictIcon:SetIcon("")
    kInstance.DistrictIcon:SetToolTipString("")
    return kInstance
end

-- CUI =======================================================================
function CuiMissionPanelMoveToRight()
    Controls.MissionPanel:SetOffsetX(293)
    Controls.MissionPanel:SetOffsetY(132)
    Controls.MissionBackground:SetTexture("Controls_BlueGradient")
end

-- CUI =======================================================================
function CuiMissionPanelMoveToLeft()
    Controls.MissionPanel:SetOffsetX(0)
    Controls.MissionPanel:SetOffsetY(135)
    Controls.MissionBackground:SetTexture("")
end

-- CUI =======================================================================
function CuiHasDistrict(city)
    if cui_sortBy == -1 then
        return true
    else
        local dType = CUI_AVAILABLE_DISTRICTS[cui_sortBy].dType
        local districts = city:GetDistricts()
        if CuiGetMatchedDistrict(dType, districts) then
            return true
        end
    end
    return false
end

-- CUI =======================================================================
function CuiOnSortButtonClick(index)
    if Controls[CUI_AVAILABLE_DISTRICTS[index].button]:GetAlpha() < 1 then
        CuiResetSorter()
        Controls[CUI_AVAILABLE_DISTRICTS[index].button]:SetAlpha(1.0)
        cui_sortBy = index
    else
        CuiResetSorter()
    end
    OnCancel()
end

-- CUI =======================================================================
function CuiResetSorter()
    for _, item in pairs(CUI_AVAILABLE_DISTRICTS) do
        if Controls[item.button] and item.dType ~= "DISTRICT_CITY_CENTER" then
            Controls[item.button]:SetAlpha(0.4)
        end
    end
    cui_sortBy = -1
end

-- CUI =======================================================================
function CuiInit()
    Controls.FilterButton:RegisterCallback(Mouse.eLClick, CuiUpdateFilterArrow)
    Controls.CivFilterPulldown:RegisterSelectionCallback(CuiOnFilterSelected)

    Controls.CampusSortButton:RegisterCallback(
        Mouse.eLClick,
        function()
            CuiOnSortButtonClick(2)
        end
    )
    Controls.CommercialSortButton:RegisterCallback(
        Mouse.eLClick,
        function()
            CuiOnSortButtonClick(3)
        end
    )
    Controls.IndustrialSortButton:RegisterCallback(
        Mouse.eLClick,
        function()
            CuiOnSortButtonClick(4)
        end
    )
    Controls.NeighborhoodSortButton:RegisterCallback(
        Mouse.eLClick,
        function()
            CuiOnSortButtonClick(5)
        end
    )
    Controls.TheaterSortButton:RegisterCallback(
        Mouse.eLClick,
        function()
            CuiOnSortButtonClick(6)
        end
    )
    Controls.SpacePortSortButton:RegisterCallback(
        Mouse.eLClick,
        function()
            CuiOnSortButtonClick(7)
        end
    )
end

-- ===========================================================================
--    INIT
-- ===========================================================================
function Initialize()
    -- Lua Events
    LuaEvents.EspionagePopup_MissionBriefingClosed.Add(OnMissionBriefingClosed)

    -- Control Events
    Controls.ConfirmButton:RegisterCallback(Mouse.eLClick, OnConfirmPlacement)
    Controls.ConfirmButton:RegisterCallback(
        Mouse.eMouseEnter,
        function()
            UI.PlaySound("Main_Menu_Mouse_Over")
        end
    )
    Controls.CancelButton:RegisterCallback(Mouse.eLClick, OnCancel)
    Controls.CancelButton:RegisterCallback(
        Mouse.eMouseEnter,
        function()
            UI.PlaySound("Main_Menu_Mouse_Over")
        end
    )
    Controls.CloseButton:RegisterCallback(Mouse.eLClick, OnClose)
    Controls.CloseButton:RegisterCallback(
        Mouse.eMouseEnter,
        function()
            UI.PlaySound("Main_Menu_Mouse_Over")
        end
    )

    CuiInit() -- CUI

    -- Game Engine Events
    Events.InterfaceModeChanged.Add(OnInterfaceModeChanged)
    Events.UnitSelectionChanged.Add(OnUnitSelectionChanged)
    Events.UnitActivityChanged.Add(OnUnitActivityChanged)
    Events.LocalPlayerTurnEnd.Add(OnLocalPlayerTurnEnd)

    -- Animation controller
    m_AnimSupport = CreateScreenAnimation(Controls.SlideAnim)

    -- Animation controller events
    Events.SystemUpdateUI.Add(m_AnimSupport.OnUpdateUI)
    ContextPtr:SetInputHandler(m_AnimSupport.OnInputHandler, true)

    -- Hot-Reload Events
    ContextPtr:SetInitHandler(OnInit)
    ContextPtr:SetShutdown(OnShutdown)
    LuaEvents.GameDebug_Return.Add(OnGameDebugReturn)
end
Initialize()
