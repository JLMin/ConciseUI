-- ===========================================================================
-- Concise UI
-- cui_city_status.lua
-- ===========================================================================

include("CitySupport")
include("Civ6Common")
include("InstanceManager")
include("SupportFunctions")
include("TabSupport")

include("cui_data")
include("cui_helper")
include("cui_settings")

-- Concise UI ----------------------------------------------------------------
local cui_CityIM = InstanceManager:new("CityInstance", "Top", Controls.CityListStack)
local cui_DistrictsIM = InstanceManager:new("DistrictInstance", "Top", Controls.DistrictInstanceContainer)
local m_tabs
local PopulationTrack = {}
local DistrictsTypes = {
    "HOLY_SITE",
    "CAMPUS",
    "THEATER",
    "ENCAMPMENT",
    "COMMERCIAL_HUB",
    "HARBOR",
    "INDUSTRIAL_ZONE",
    "ENTERTAINMENT_COMPLEX",
    "AERODROME",
    "SPACEPORT"
}

-- ===========================================================================
-- Support functions
-- ===========================================================================

-- Concise UI ----------------------------------------------------------------
function GetPercentGrowthColor(percent)
    if percent == 0 then
        return "Error"
    end
    if percent <= 0.25 then
        return "WarningMajor"
    end
    if percent <= 0.5 then
        return "WarningMinor"
    end
    return "White"
end

-- Concise UI ----------------------------------------------------------------
function GetHappinessColor(eHappiness)
    local happinessInfo = GameInfo.Happinesses[eHappiness]
    if (happinessInfo ~= nil) then
        if (happinessInfo.GrowthModifier < 0) then
            return "StatBadCS"
        end
        if (happinessInfo.GrowthModifier > 0) then
            return "StatGoodCS"
        end
    end
    return "White"
end

-- Concise UI ----------------------------------------------------------------
function GetLoyaltyColor(loyalty)
    if loyalty < 0 then
        return "StatBadCS"
    end
    if loyalty > 0 then
        return "StatGoodCS"
    end
    return "White"
end

-- ===========================================================================
-- UI functions
-- ===========================================================================

-- Concise UI ----------------------------------------------------------------
function PopulateTabs()
    m_tabs = CreateTabs(Controls.TabRow, 44, UI.GetColorValueFromHexLiteral(0xFF331D05))
    m_tabs.AddTab(Controls.CitizenTab, Foo)
    m_tabs.AddTab(Controls.HouseTab, Foo)
    m_tabs.AddTab(Controls.ProductionTab, Foo)
    m_tabs.AddTab(Controls.GoldTab, Foo)
    m_tabs.AddTab(Controls.ScienceTab, Foo)
    m_tabs.AddTab(Controls.CultureTab, Foo)
    m_tabs.AddTab(Controls.FaithTab, Foo)

    m_tabs.SelectTab(Controls.CitizenTab)
    m_tabs.CenterAlignTabs(0, 350, 44)
    m_tabs.AddAnimDeco(Controls.TabAnim, Controls.TabArrow)
end

-- Concise UI ----------------------------------------------------------------
function PopulateCityStack()
    cui_CityIM:ResetInstances()
    cui_DistrictsIM:ResetInstances()

    local playerID = Game.GetLocalPlayer()
    local player = Players[playerID]
    local cities = player:GetCities()
    for i, city in cities:Members() do
        local cityInstance = cui_CityIM:GetInstance()
        local cityData = GetCityData(city)

        -- city button
        cityInstance.CapitalIcon:SetHide(not cityData.IsCapital)
        cityInstance.CityName:SetText(Locale.Lookup(city:GetName()))
        if cityData.ProductionQueue then
            local currentProduction = cityData.ProductionQueue[1]
            if currentProduction and currentProduction.Icons then
                cityInstance.ProductionProgressGrid:SetHide(false)
                for _, iconName in ipairs(currentProduction.Icons) do
                    if iconName and cityInstance.Icon:TrySetIcon(iconName) then
                        break
                    end
                end
                cityInstance.ProductionProgress:SetPercent(currentProduction.PercentComplete)
                cityInstance.ProductionTurn:SetText(currentProduction.Turns .. "[ICON_TURN]")
            else
                cityInstance.ProductionProgressGrid:SetHide(true)
            end
        end

        cityInstance.CityButton:RegisterCallback(
            Mouse.eLClick,
            function()
                UI.LookAtPlot(cityData.City:GetX(), cityData.City:GetY())
                UI.SelectCity(cityData.City)
            end
        )
        cityInstance.CityButton:RegisterCallback(
            Mouse.eMouseEnter,
            function()
                UI.PlaySound("Main_Menu_Mouse_Over")
            end
        )
        -- if population changed
        cityInstance.CityButton:SetTexture("Controls_ButtonControl")
        cityInstance.NewPopulation:SetHide(true)
        if PopulationTrack[playerID] and PopulationTrack[playerID][city:GetName()] then
            local cpData = PopulationTrack[playerID][city:GetName()]
            if cpData.HasChanged then
                local amount = ""
                if cpData.Amount > 0 then
                    amount = "[COLOR_Civ6Green]+" .. cpData.Amount .. "[ENDCOLOR]"
                else
                    amount = "[COLOR_Civ6Red]" .. cpData.Amount .. "[ENDCOLOR]"
                end
                local cpToolTip = Locale.Lookup("LOC_RAZE_CITY_POPULATION_LABEL") .. amount
                cityInstance.CityButton:SetTexture("Controls_ButtonControl_Tan")
                cityInstance.NewPopulation:SetHide(false)
                cityInstance.NewPopulation:SetToolTipString(cpToolTip)
            end
        end

        cityInstance.GrowthTurnsBar:SetPercent(cityData.CurrentFoodPercent)
        local iconColor = cityData.Occupied and "Red" or "White"
        cityInstance.CitizenIcon:SetColorByName(iconColor)
        local growthArrow = cityData.TurnsUntilGrowth >= 0 and "[ICON_PressureUp]" or "[ICON_PressureDown]"
        cityInstance.GrowthArrow:SetText(growthArrow)
        cityInstance.GrowthTurn:SetText(math.abs(cityData.TurnsUntilGrowth) .. "[ICON_TURN]")

        local colorName = "White"
        --
        cityInstance.HousingNum:SetText(cityData.Population .. "/" .. cityData.Housing)
        colorName = GetPercentGrowthColor(cityData.HousingMultiplier)
        cityInstance.HousingNum:SetColorByName(colorName)
        --
        local amenitiesNumText = cityData.AmenitiesNetAmount
        if cityData.AmenitiesNetAmount > 0 then
            amenitiesNumText = "+" .. amenitiesNumText
        end
        cityInstance.AmenitiesNum:SetText(amenitiesNumText)
        colorName = GetHappinessColor(cityData.Happiness)
        cityInstance.AmenitiesNum:SetColorByName(colorName)
        --
        cityInstance.ReligionNum:SetText(cityData.ReligionFollowers)
        --
        if isExpansion1 or isExpansion2 then
            local culturalIdentity = cityData.City:GetCulturalIdentity()
            local loyaltyPerTurn = culturalIdentity:GetLoyaltyPerTurn()
            colorName = GetLoyaltyColor(loyaltyPerTurn)
            cityInstance.SwitchableIcon:SetIcon("ICON_STAT_CULTURAL_FLAG")
            cityInstance.SwitchableNum:SetText(toPlusMinusString(loyaltyPerTurn))
            cityInstance.SwitchableNum:SetColorByName(colorName)
        else
            cityInstance.SwitchableIcon:SetIcon("ICON_BUILDINGS")
            cityInstance.SwitchableNum:SetText(cityData.DistrictsNum .. "/" .. cityData.DistrictsPossibleNum)
            cityInstance.SwitchableNum:SetColorByName("White")
        end
        --
        PopulateDistrict(cityInstance, cityData)

        -- yields
        local yields = CuiGetCityYield(city)
        cityInstance.CityFood:SetText(yields.Food)
        cityInstance.CityProduction:SetText(yields.Production)
        cityInstance.CityGold:SetText(yields.Gold)
        cityInstance.CityScience:SetText(yields.Science)
        cityInstance.CityCulture:SetText(yields.Culture)
        cityInstance.CityFaith:SetText(yields.Faith)
    end
end

-- Concise UI ----------------------------------------------------------------
function PopulateDistrict(instance, data)
    for _, district in ipairs(data.BuildingsAndDistricts) do
        if district.isBuilt and district.Type == "DISTRICT_GOVERNMENT" then
            CuiSetIconToSize(instance.GovernmentIcon, "ICON_DISTRICT_GOVERNMENT", 22)
            break
        end
    end

    for _, groupName in ipairs(DistrictsTypes) do
        local dGroup = GameDistrictsTypes[groupName]
        local districtInstance = cui_DistrictsIM:GetInstance(instance.DistrictStack)
        CuiSetIconToSize(districtInstance.Icon, "ICON_" .. dGroup[1], 22)
        districtInstance.Icon:SetAlpha(0.1)
        for _, dType in ipairs(dGroup) do
            for _, district in ipairs(data.BuildingsAndDistricts) do
                if district.isBuilt and district.Type == dType then
                    CuiSetIconToSize(districtInstance.Icon, "ICON_" .. dType, 22)
                    districtInstance.Icon:SetAlpha(1)
                    break
                end
            end
        end
    end
    instance.DistrictStack:CalculateSize()
end

-- Concise UI ----------------------------------------------------------------
function Foo()
end

-- ===========================================================================
-- Population functions
-- ===========================================================================

-- Concise UI ----------------------------------------------------------------
function BuildPopulationData(playerID)
    PopulationTrack[playerID] = {}
    local player = Players[playerID]
    local cities = player:GetCities()
    local data = {}
    for i, city in cities:Members() do
        local name = city:GetName()
        data[name] = {Owner = city:GetOwner(), Population = city:GetPopulation(), HasChanged = false, Amount = 0}
    end
    PopulationTrack[playerID] = data
end

-- Concise UI ----------------------------------------------------------------
function UpdatePopulationChanged(playerID)
    local data = PopulationTrack[playerID]
    local player = Players[playerID]
    local cities = player:GetCities()
    local hasChanged = false
    for i, city in cities:Members() do
        local name = city:GetName()
        if data[name] and data[name].Owner == city:GetOwner() then
            if data[name].Population ~= city:GetPopulation() then
                data[name].Amount = city:GetPopulation() - data[name].Population
                hasChanged = true
                data[name].HasChanged = true
            end
        end
    end
    PopulationTrack[playerID] = data

    return hasChanged
end

-- ===========================================================================
-- Event functions
-- ===========================================================================

-- Concise UI ----------------------------------------------------------------
function Open()
    UI.PlaySound("Production_Panel_Open")

    Controls.AlphaIn:SetToBeginning()
    Controls.SlideIn:SetToBeginning()
    Controls.AlphaIn:Play()
    Controls.SlideIn:Play()

    ContextPtr:SetHide(false)
    Refresh()

    LuaEvents.CuiCityManager_Open()
end

-- Concise UI ----------------------------------------------------------------
function Close()
    UI.PlaySound("Production_Panel_Closed")
    Controls.SlideIn:Reverse()
    Controls.AlphaIn:Reverse()
    Controls.PauseDismissWindow:Play()

    LuaEvents.CuiCityManager_Close()
end

-- Concise UI ----------------------------------------------------------------
function OnCloseEnd()
    ContextPtr:SetHide(true)
    Controls.PauseDismissWindow:SetToBeginning()
end

-- Concise UI ----------------------------------------------------------------
function OnToggleCityManager()
    if ContextPtr:IsHidden() then
        Open()
    else
        Close()
    end
end

-- Concise UI ----------------------------------------------------------------
function OnPlayerTurnActivated()
    local playerID = Game.GetLocalPlayer()
    if playerID == PlayerTypes.NONE then
        return
    end
    if isNil(PopulationTrack[playerID]) then
        LuaEvents.CuiPlayerPopulationChanged(false)
    else
        local hasChanged = UpdatePopulationChanged(playerID)
        LuaEvents.CuiPlayerPopulationChanged(hasChanged)
    end
end

-- Concise UI ----------------------------------------------------------------
function OnPlayerTurnEnd()
    local playerID = Game.GetLocalPlayer()
    if playerID == PlayerTypes.NONE then
        return
    end
    BuildPopulationData(playerID)
end

-- Concise UI ----------------------------------------------------------------
function Refresh()
    local playerID = Game.GetLocalPlayer()
    local player = Players[playerID]
    if isNil(player) then
        return
    end
    PopulateTabs()
    PopulateCityStack()
end

-- Concise UI ----------------------------------------------------------------
function Initialize()
    Controls.CloseButton:RegisterCallback(Mouse.eLClick, Close)
    Controls.CloseButton:RegisterCallback(
        Mouse.eMouseEnter,
        function()
            UI.PlaySound("Main_Menu_Mouse_Over")
        end
    )
    Controls.PauseDismissWindow:RegisterEndCallback(OnCloseEnd)

    LuaEvents.CuiOnToggleCityManager.Add(OnToggleCityManager)
    LuaEvents.CityPanelOverview_Opened.Add(Close)
    Events.PlayerTurnActivated.Add(OnPlayerTurnActivated)
    Events.LocalPlayerTurnEnd.Add(OnPlayerTurnEnd)
end
Initialize()
