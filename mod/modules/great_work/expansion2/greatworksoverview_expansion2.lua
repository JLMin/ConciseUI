--[[
-- Created by Samuel Batista
-- Copyright (c) Firaxis Games 2018
--]] -- ===========================================================================
-- INCLUDES
-- ===========================================================================
include("GreatWorksOverview.lua")

-- ===========================================================================
-- OVERRIDE BASE FUNCTIONS
-- ===========================================================================
include("InstanceManager")
include("PopupDialog")
include("GameCapabilities")
include("GreatWorksSupport")

-- ===========================================================================
--	CONSTANTS Shoul probably switch the base game to just use globals.
-- ===========================================================================
local RELOAD_CACHE_ID = "GreatWorksOverview" -- Must be unique (usually the same as the file name)

local SIZE_SLOT_TYPE_ICON = 40
local SIZE_GREAT_WORK_ICON = 64
local PADDING_PROVIDING_LABEL = 10
local PADDING_PLACING_DETAILS = 5
local PADDING_PLACING_ICON = 10
local PADDING_BUTTON_EDGES = 20
local MIN_PADDING_SLOTS = 2
local MAX_PADDING_SLOTS = 30
local MAX_NUM_SLOTS = 6

local NUM_RELIC_TEXTURES = 24
local NUM_ARIFACT_TEXTURES = 25
local GREAT_WORK_RELIC_TYPE = "GREATWORKOBJECT_RELIC"
local GREAT_WORK_ARTIFACT_TYPE = "GREATWORKOBJECT_ARTIFACT"

local LOC_PLACING = Locale.Lookup("LOC_GREAT_WORKS_PLACING")
local LOC_TOURISM = Locale.Lookup("LOC_GREAT_WORKS_TOURISM")
local LOC_THEME_BONUS = Locale.Lookup("LOC_GREAT_WORKS_THEMED_BONUS")
local LOC_SCREEN_TITLE = Locale.Lookup("LOC_GREAT_WORKS_SCREEN_TITLE")
local LOC_ORGANIZE_GREAT_WORKS = Locale.Lookup("LOC_GREAT_WORKS_ORGANIZE_GREAT_WORKS")

local DATA_FIELD_SLOT_CACHE = "SlotCache"
local DATA_FIELD_GREAT_WORK_IM = "GreatWorkIM"
local DATA_FIELD_TOURISM_YIELD = "TourismYield"
local DATA_FIELD_THEME_BONUS_IM = "ThemeBonusIM"

local cui_ThemeHelper = false -- CUI

local YIELD_FONT_ICONS = {
  YIELD_FOOD = "[ICON_FoodLarge]",
  YIELD_PRODUCTION = "[ICON_ProductionLarge]",
  YIELD_GOLD = "[ICON_GoldLarge]",
  YIELD_SCIENCE = "[ICON_ScienceLarge]",
  YIELD_CULTURE = "[ICON_CultureLarge]",
  YIELD_FAITH = "[ICON_FaithLarge]",
  TourismYield = "[ICON_TourismLarge]"
}

local DEFAULT_GREAT_WORKS_ICONS = {
  GREATWORKSLOT_WRITING = "ICON_GREATWORKOBJECT_WRITING",
  GREATWORKSLOT_PALACE = "ICON_GREATWORKOBJECT_SCULPTURE",
  GREATWORKSLOT_ART = "ICON_GREATWORKOBJECT_PORTRAIT",
  GREATWORKSLOT_CATHEDRAL = "ICON_GREATWORKOBJECT_RELIGIOUS",
  GREATWORKSLOT_ARTIFACT = "ICON_GREATWORKOBJECT_ARTIFACT_ERA_ANCIENT",
  GREATWORKSLOT_MUSIC = "ICON_GREATWORKOBJECT_MUSIC",
  GREATWORKSLOT_RELIC = "ICON_GREATWORKOBJECT_RELIC"
}

local m_during_move = false
local m_dest_building = 0
local m_dest_city
local m_isLocalPlayerTurn = true

-- ===========================================================================
--	SCREEN VARIABLES
-- ===========================================================================
local m_FirstGreatWork = nil
local m_GreatWorkYields = nil
local m_GreatWorkSelected = nil
local m_GreatWorkBuildings = nil
local m_GreatWorkSlotsIM = InstanceManager:new("GreatWorkSlot", "TopControl", Controls.GreatWorksStack)
local m_TotalResourcesIM = InstanceManager:new("AgregateResource", "Resource", Controls.TotalResources)

-- ===========================================================================
--	PLAYER VARIABLES
-- ===========================================================================
local m_LocalPlayer
local m_LocalPlayerID

function GetThemeDescription(buildingType)
  local localPlayerID = Game.GetLocalPlayer()
  local localPlayer = Players[localPlayerID]

  if (localPlayer == nil) then return nil end

  local eBuilding = localPlayer:GetCulture():GetAutoThemedBuilding()
  local bAutoTheme = localPlayer:GetCulture():IsAutoThemedEligible(GameInfo.Buildings[buildingType].Hash)

  if (GameInfo.Buildings[buildingType].Index == eBuilding) then
    return Locale.Lookup("LOC_BUILDING_THEMINGBONUS_FULL_MUSEUM")
  elseif (bAutoTheme == true) then
    return Locale.Lookup("LOC_BUILDING_THEMINGBONUS_FULL_MUSEUM")
  else
    for row in GameInfo.Building_GreatWorks() do
      if row.BuildingType == buildingType then
        if row.ThemingBonusDescription ~= nil then return Locale.Lookup(row.ThemingBonusDescription) end
      end
    end
  end
  return nil
end

function PopulateGreatWorkSlot(instance, pCity, pCityBldgs, pBuildingInfo)

  instance.DefaultBG:SetHide(false)
  instance.DisabledBG:SetHide(true)
  instance.HighlightedBG:SetHide(true)
  instance.DefaultBG:RegisterCallback(Mouse.eLClick, function() end) -- clear callback
  instance.HighlightedBG:RegisterCallback(Mouse.eLClick, function() end) -- clear callback

  -- CUI: reset Theme label
  instance.ThemingLabel:SetText("")
  instance.ThemingLabel:SetToolTipString("")
  --
  local buildingType = pBuildingInfo.BuildingType
  local buildingIndex = pBuildingInfo.Index
  local themeDescription = GetThemeDescription(buildingType)
  instance.CityName:SetText(Locale.Lookup(pCity:GetName()))
  instance.BuildingName:SetText(Locale.ToUpper(Locale.Lookup(pBuildingInfo.Name)))

  -- Ensure we have Instance Managers for the great works
  local greatWorkIM = instance[DATA_FIELD_GREAT_WORK_IM]
  if (greatWorkIM == nil) then
    greatWorkIM = InstanceManager:new("GreatWork", "TopControl", instance.GreatWorks)
    instance[DATA_FIELD_GREAT_WORK_IM] = greatWorkIM
  else
    greatWorkIM:ResetInstances()
  end

  local index = 0
  local numGreatWorks = 0
  local numThemedGreatWorks = 0
  local instanceCache = {}
  local firstGreatWork = nil
  local numSlots = pCityBldgs:GetNumGreatWorkSlots(buildingIndex)
  local localPlayerID = Game.GetLocalPlayer()
  local localPlayer = Players[localPlayerID]

  if (localPlayer == nil) then return nil end

  local bAutoTheme = localPlayer:GetCulture():IsAutoThemedEligible()

  if (numSlots ~= nil and numSlots > 0) then
    for _ = 0, numSlots - 1 do
      local instance = greatWorkIM:GetInstance()
      local greatWorkIndex = pCityBldgs:GetGreatWorkInSlot(buildingIndex, index)
      local greatWorkSlotType = pCityBldgs:GetGreatWorkSlotType(buildingIndex, index)
      local greatWorkSlotString = GameInfo.GreatWorkSlotTypes[greatWorkSlotType].GreatWorkSlotType

      PopulateGreatWork(instance, pCityBldgs, pBuildingInfo, index, greatWorkIndex, greatWorkSlotString)
      index = index + 1
      instanceCache[index] = instance
      if greatWorkIndex ~= -1 then
        numGreatWorks = numGreatWorks + 1
        local greatWorkType = pCityBldgs:GetGreatWorkTypeFromIndex(greatWorkIndex)
        local greatWorkInfo = GameInfo.GreatWorks[greatWorkType]
        if firstGreatWork == nil then firstGreatWork = greatWorkInfo end
        if greatWorkInfo ~= nil and GreatWorkFitsTheme(pCityBldgs, pBuildingInfo, greatWorkIndex, greatWorkInfo) then
          numThemedGreatWorks = numThemedGreatWorks + 1
        end
      end
    end

    if firstGreatWork ~= nil and themeDescription ~= nil and buildingType ~= "BUILDING_QUEENS_BIBLIOTHEQUE" then
      local slotTypeIcon = "ICON_" .. firstGreatWork.GreatWorkObjectType
      if firstGreatWork.GreatWorkObjectType == "GREATWORKOBJECT_ARTIFACT" then
        slotTypeIcon = slotTypeIcon .. "_" .. firstGreatWork.EraType
      end

      local textureOffsetX, textureOffsetY, textureSheet = IconManager:FindIconAtlas(slotTypeIcon, SIZE_SLOT_TYPE_ICON)
      if (textureSheet == nil or textureSheet == "") then
        UI.DataError("Could not find slot type icon in PopulateGreatWorkSlot: icon=\"" .. slotTypeIcon .. "\", iconSize=" ..
                         tostring(SIZE_SLOT_TYPE_ICON))
      else
        for i = 0, numSlots - 1 do
          local slotIndex = index - i
          instanceCache[slotIndex].SlotTypeIcon:SetTexture(textureOffsetX, textureOffsetY, textureSheet)
        end
      end
    end
  end

  instance[DATA_FIELD_SLOT_CACHE] = instanceCache

  local numSlots = table.count(instanceCache)
  if (numSlots > 1) then
    local slotRange = MAX_NUM_SLOTS - 2
    local paddingRange = MAX_PADDING_SLOTS - MIN_PADDING_SLOTS
    local finalPadding = ((MAX_NUM_SLOTS - numSlots) * paddingRange / slotRange) + MIN_PADDING_SLOTS
    instance.GreatWorks:SetStackPadding(finalPadding)
  else
    instance.GreatWorks:SetStackPadding(0)
  end

  -- Ensure we have Instance Managers for the theme bonuses
  local themeBonusIM = instance[DATA_FIELD_THEME_BONUS_IM]
  if (themeBonusIM == nil) then
    themeBonusIM = InstanceManager:new("Resource", "Resource", instance.ThemeBonuses)
    instance[DATA_FIELD_THEME_BONUS_IM] = themeBonusIM
  else
    themeBonusIM:ResetInstances()
  end

  if numGreatWorks == 0 then
    if themeDescription ~= nil then
      instance.ThemingLabel:SetText(Locale.Lookup("LOC_GREAT_WORKS_THEME_BONUS_PROGRESS", numThemedGreatWorks, numSlots))
      instance.ThemingLabel:SetToolTipString(themeDescription)
    end
  else
    instance.ThemingLabel:SetText("")
    instance.ThemingLabel:SetToolTipString("")
    if pCityBldgs:IsBuildingThemedCorrectly(buildingIndex) then
      instance.ThemingLabel:SetText(LOC_THEME_BONUS)
      if m_during_move then
        if buildingIndex == m_dest_building then
          if (m_dest_city == pCityBldgs:GetCity():GetID()) then UI.PlaySound("UI_GREAT_WORKS_BONUS_ACHIEVED") end
        end
      end
    else
      if themeDescription ~= nil then
        -- if we're being called due to moving a work
        if numSlots > 1 then
          if (bAutoTheme == true) then
            instance.ThemingLabel:SetText(Locale.Lookup("LOC_GREAT_WORKS_THEME_BONUS_PROGRESS", numGreatWorks, numSlots))
          else
            instance.ThemingLabel:SetText(Locale.Lookup("LOC_GREAT_WORKS_THEME_BONUS_PROGRESS", numThemedGreatWorks, numSlots))
          end

          if m_during_move then
            if buildingIndex == m_dest_building then
              if (m_dest_city == pCityBldgs:GetCity():GetID()) then
                if numThemedGreatWorks == 2 then UI.PlaySound("UI_GreatWorks_Bonus_Increased") end
              end
            end
          end
        end

        if instance.ThemingLabel:GetText() ~= "" then instance.ThemingLabel:SetToolTipString(themeDescription) end
      end
    end
  end

  for row in GameInfo.Yields() do
    local yieldValue = pCityBldgs:GetBuildingYieldFromGreatWorks(row.Index, buildingIndex)
    if yieldValue > 0 then AddYield(themeBonusIM:GetInstance(), Locale.Lookup(row.Name), YIELD_FONT_ICONS[row.YieldType], yieldValue) end
  end

  local regularTourism = pCityBldgs:GetBuildingTourismFromGreatWorks(false, buildingIndex)
  local religionTourism = pCityBldgs:GetBuildingTourismFromGreatWorks(true, buildingIndex)
  local totalTourism = regularTourism + religionTourism

  if totalTourism > 0 then AddYield(themeBonusIM:GetInstance(), LOC_TOURISM, YIELD_FONT_ICONS[DATA_FIELD_TOURISM_YIELD], totalTourism) end

  instance.ThemeBonuses:CalculateSize()
  instance.ThemeBonuses:ReprocessAnchoring()

  return numGreatWorks
end
