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
  m_tabs.AddTab(Controls.CitizenTab, Dummy)
  m_tabs.AddTab(Controls.HouseTab, Dummy)
  m_tabs.AddTab(Controls.ProductionTab, Dummy)
  m_tabs.AddTab(Controls.GoldTab, Dummy)
  m_tabs.AddTab(Controls.ScienceTab, Dummy)
  m_tabs.AddTab(Controls.CultureTab, Dummy)
  m_tabs.AddTab(Controls.FaithTab, Dummy)

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
        cityInstance.Icon:SetHide(false)
        cityInstance.ProgressStack:SetHide(false)
        for _, iconName in ipairs(currentProduction.Icons) do
          if iconName and cityInstance.Icon:TrySetIcon(iconName) then break end
        end
        cityInstance.ProductionProgress:SetPercent(currentProduction.PercentComplete)
        cityInstance.ProductionName:SetText(currentProduction.Name)
        cityInstance.ProductionTurn:SetText(currentProduction.Turns .. "[ICON_TURN]")
      else
        cityInstance.Icon:SetHide(true)
        cityInstance.ProgressStack:SetHide(true)
      end
    end

    cityInstance.CityButton:RegisterCallback(Mouse.eLClick, function()
      UI.LookAtPlot(cityData.City:GetX(), cityData.City:GetY())
      UI.SelectCity(cityData.City)
    end)
    cityInstance.CityButton:RegisterCallback(Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over") end)

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

    --
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
function Dummy() end

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
  LuaEvents.CuiOnToggleCityManager.Add(OnToggleCityManager)

  Controls.CloseButton:RegisterCallback(Mouse.eLClick, Close)
  Controls.CloseButton:RegisterCallback(Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over") end)
  Controls.PauseDismissWindow:RegisterEndCallback(OnCloseEnd)
  Refresh()
  LuaEvents.CityPanelOverview_Opened.Add(Close)
end
Initialize()
