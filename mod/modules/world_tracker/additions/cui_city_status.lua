-- ===========================================================================
-- Cui City Manager
-- eudaimonia, 2019/11/17
-- ---------------------------------------------------------------------------
include("CitySupport")
include("Civ6Common")
include("InstanceManager")
include("SupportFunctions")
include("TabSupport")

include("cui_data")
include("cui_helper")
include("cui_settings")

-- ---------------------------------------------------------------------------

local cui_CityIM = InstanceManager:new("CityInstance", "Top", Controls.CityListStack)
local cui_DistrictsIM = InstanceManager:new("DistrictInstance", "Top", Controls.DistrictInstanceContainer)
local m_tabs
local PopulationTrack = {}

-- ===========================================================================
-- Support functions
-- ---------------------------------------------------------------------------
function GetPercentGrowthColor(percent)
  if percent == 0 then return "Error" end
  if percent <= 0.25 then return "WarningMajor" end
  if percent <= 0.5 then return "WarningMinor" end
  return "White"
end

-- ---------------------------------------------------------------------------
function GetHappinessColor(eHappiness)
  local happinessInfo = GameInfo.Happinesses[eHappiness]
  if (happinessInfo ~= nil) then
    if (happinessInfo.GrowthModifier < 0) then return "StatBadCS" end
    if (happinessInfo.GrowthModifier > 0) then return "StatGoodCS" end
  end
  return "White"
end

-- ===========================================================================
-- UI functions
-- ---------------------------------------------------------------------------
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

-- ---------------------------------------------------------------------------
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
        cityInstance.ProgressStack:SetHide(false)
        for _, iconName in ipairs(currentProduction.Icons) do
          if iconName and cityInstance.Icon:TrySetIcon(iconName) then break end
        end
        cityInstance.ProductionProgress:SetPercent(currentProduction.PercentComplete)
        cityInstance.ProductionName:SetText(currentProduction.Name)
        cityInstance.ProductionTurn:SetText(currentProduction.Turns .. "[ICON_TURN]")
      else
        cityInstance.ProgressStack:SetHide(true)
      end
    end

    cityInstance.CityButton:RegisterCallback(Mouse.eLClick, function()
      UI.LookAtPlot(cityData.City:GetX(), cityData.City:GetY())
      UI.SelectCity(cityData.City)
    end)
    cityInstance.CityButton:RegisterCallback(Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over") end)
    -- if population changed
    cityInstance.CityButton:SetTexture("Controls_ButtonControl")
    cityInstance.CurrentProductionGrid:SetTexture("Controls_ButtonControl_Gray")
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
        cityInstance.CurrentProductionGrid:SetTexture("Controls_ButtonControl_Brown")
        cityInstance.NewPopulation:SetHide(false)
        cityInstance.NewPopulation:SetToolTipString(cpToolTip)
      end
    end

    cityInstance.GrowthTurnsBar:SetPercent(cityData.CurrentFoodPercent)
    cityInstance.GrowthTurnsBar:SetShadowPercent(cityData.FoodPercentNextTurn)
    cityInstance.GrowthNum:SetText(math.abs(cityData.TurnsUntilGrowth))
    if cityData.Occupied then
      cityInstance.GrowthLabel:SetColorByName("StatBadCS")
      cityInstance.GrowthLabel:SetText(Locale.ToUpper(Locale.Lookup("LOC_HUD_CITY_GROWTH_OCCUPIED")))
    elseif cityData.TurnsUntilGrowth >= 0 then
      cityInstance.GrowthLabel:SetColorByName("StatGoodCS")
      cityInstance.GrowthLabel:SetText(Locale.ToUpper(Locale.Lookup("LOC_HUD_CITY_TURNS_UNTIL_GROWTH",
                                                                    cityData.TurnsUntilGrowth)))
    else
      cityInstance.GrowthLabel:SetColorByName("StatBadCS")
      cityInstance.GrowthLabel:SetText(Locale.ToUpper(Locale.Lookup("LOC_HUD_CITY_TURNS_UNTIL_LOSS",
                                                                    math.abs(cityData.TurnsUntilGrowth))))
    end

    local colorName = "White"
    --
    cityInstance.HousingNum:SetText(cityData.Population .. "/" .. cityData.Housing)
    colorName = GetPercentGrowthColor(cityData.HousingMultiplier)
    cityInstance.HousingNum:SetColorByName(colorName)
    --
    local amenitiesNumText = cityData.AmenitiesNetAmount
    if cityData.AmenitiesNetAmount > 0 then amenitiesNumText = "+" .. amenitiesNumText end
    cityInstance.AmenitiesNum:SetText(amenitiesNumText)
    colorName = GetHappinessColor(cityData.Happiness)
    cityInstance.AmenitiesNum:SetColorByName(colorName)
    --
    cityInstance.ReligionNum:SetText(cityData.ReligionFollowers)
    --
    cityInstance.DistrickNum:SetText(cityData.DistrictsNum .. "/" .. cityData.DistrictsPossibleNum)
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
    cityInstance.CityTourism:SetText(yields.Tourism)
    
  end
end

-- ---------------------------------------------------------------------------
function PopulateDistrict(instance, data)
  for _, district in ipairs(data.BuildingsAndDistricts) do
    if district.isBuilt then
      if "DISTRICT_CITY_CENTER" ~= district.Type then
        local districtInstance = cui_DistrictsIM:GetInstance(instance.DistrictStack)
        CuiSetIconToSize(districtInstance.Icon, district.Icon, 22)
      end
    end
  end
  instance.DistrictStack:CalculateSize()
end

-- ---------------------------------------------------------------------------
function Foo() end

-- ===========================================================================
-- Population functions
-- ---------------------------------------------------------------------------
function BuildPopulationData(playerID)
  PopulationTrack[playerID] = {}
  local player = Players[playerID]
  local cities = player:GetCities()
  local data = {}
  for i, city in cities:Members() do
    local name = city:GetName()
    data[name] = {
      Owner = city:GetOwner(),
      Population = city:GetPopulation(),
      HasChanged = false,
      Amount = 0
    }
  end
  PopulationTrack[playerID] = data
end

-- ---------------------------------------------------------------------------
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
-- ---------------------------------------------------------------------------
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

-- ---------------------------------------------------------------------------
function Close()
  UI.PlaySound("Production_Panel_Closed")
  Controls.SlideIn:Reverse()
  Controls.AlphaIn:Reverse()
  Controls.PauseDismissWindow:Play()

  LuaEvents.CuiCityManager_Close()
end

-- ---------------------------------------------------------------------------
function OnCloseEnd()
  ContextPtr:SetHide(true)
  Controls.PauseDismissWindow:SetToBeginning()
end

-- ---------------------------------------------------------------------------
function OnToggleCityManager()
  if ContextPtr:IsHidden() then
    Open()
  else
    Close()
  end
end

-- ---------------------------------------------------------------------------
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

-- ---------------------------------------------------------------------------
function OnPlayerTurnEnd()
  local playerID = Game.GetLocalPlayer()
  if playerID == PlayerTypes.NONE then
    return
  end
  BuildPopulationData(playerID)
end

-- ===========================================================================
function Refresh()
  local playerID = Game.GetLocalPlayer()
  local player = Players[playerID]
  if isNil(player) then return end
  PopulateTabs()
  PopulateCityStack()
end

-- ===========================================================================
function Initialize()
  Controls.CloseButton:RegisterCallback(Mouse.eLClick, Close)
  Controls.CloseButton:RegisterCallback(Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over") end)
  Controls.PauseDismissWindow:RegisterEndCallback(OnCloseEnd)
  
  LuaEvents.CuiOnToggleCityManager.Add(OnToggleCityManager)
  LuaEvents.CityPanelOverview_Opened.Add(Close)
  Events.PlayerTurnActivated.Add(OnPlayerTurnActivated)
  Events.LocalPlayerTurnEnd.Add(OnPlayerTurnEnd)
end
Initialize()
