-- Copyright 2018-2019, Firaxis Games
include("InstanceManager")
include("PopupDialog")
include("GameCapabilities")
include("GreatWorksSupport")
include("ModalScreen_PlayerYieldsHelper") -- CUI
include("cui_settings") -- CUI

-- ===========================================================================
--	CONSTANTS
-- ===========================================================================
local RELOAD_CACHE_ID = "GreatWorksOverview" -- Must be unique (usually the same as the file name)

local SIZE_SLOT_TYPE_ICON = 40
local SIZE_GREAT_WORK_ICON = 64
local PADDING_PROVIDING_LABEL = 10
local MIN_PADDING_SLOTS = 2
local MAX_PADDING_SLOTS = 30
local MAX_NUM_SLOTS = 6
local DEFAULT_LOCK_TURNS = 10

local NUM_RELIC_TEXTURES = 24
local NUM_ARIFACT_TEXTURES = 25
local GREAT_WORK_RELIC_TYPE = "GREATWORKOBJECT_RELIC"
local GREAT_WORK_ARTIFACT_TYPE = "GREATWORKOBJECT_ARTIFACT"

local LOC_TOURISM = Locale.Lookup("LOC_GREAT_WORKS_TOURISM")
local LOC_THEME_BONUS = Locale.Lookup("LOC_GREAT_WORKS_THEMED_BONUS")
local LOC_SCREEN_TITLE = Locale.Lookup("LOC_GREAT_WORKS_SCREEN_TITLE")

local DATA_FIELD_SLOT_CACHE = "SlotCache"
local DATA_FIELD_GREAT_WORK_IM = "GreatWorkIM"
local DATA_FIELD_TOURISM_YIELD = "TourismYield"
local DATA_FIELD_THEME_BONUS_IM = "ThemeBonusIM"

local DATA_FIELD_CITY_ID = "DataField_CityID"
local DATA_FIELD_BUILDING_ID = "DataField_BuildingID"
local DATA_FIELD_GREAT_WORK_INDEX = "DataField_GreatWorkIndex"
local DATA_FIELD_SLOT_INDEX = "DataField_SlotIndex"
local DATA_FIELD_GREAT_WORK_TYPE = "DataField_GreatWorkType"

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

-- ===========================================================================
--	SCREEN VARIABLES
-- ===========================================================================
local m_FirstGreatWork = nil
local m_GreatWorkYields = nil
local m_GreatWorkSelected = nil
local m_GreatWorkBuildings = nil
local m_GreatWorkSlotsIM = InstanceManager:new("GreatWorkSlot", "TopControl", Controls.GreatWorksStack)
local m_TotalResourcesIM = InstanceManager:new("AgregateResource", "Resource", Controls.TotalResources)

local m_kViableDropTargets = {}
local m_kControlToInstanceMap = {}
local m_uiSelectedDropTarget = nil

local m_TopPanelConsideredHeight = 0 -- CUI
-- ===========================================================================
--	PLAYER VARIABLES
-- ===========================================================================
local m_LocalPlayer
local m_LocalPlayerID

local m_during_move = false
local m_dest_building = 0
local m_dest_city
local m_isLocalPlayerTurn = true

local cui_ThemeHelper = false -- CUI

-- ===========================================================================
--	Called every time screen is shown
-- ===========================================================================
function UpdatePlayerData()
  m_LocalPlayerID = Game.GetLocalPlayer()
  if m_LocalPlayerID ~= -1 then
    m_LocalPlayer = Players[m_LocalPlayerID]
  end
end

-- ===========================================================================
--	Called every time screen is shown
-- ===========================================================================
function UpdateGreatWorks()

  m_FirstGreatWork = nil
  m_GreatWorkSelected = nil
  m_GreatWorkSlotsIM:ResetInstances()
  Controls.PlacingContainer:SetHide(true)
  Controls.HeaderStatsContainer:SetHide(false)

  if (m_LocalPlayer == nil) then
    return
  end

  m_GreatWorkYields = {}
  m_GreatWorkBuildings = {}
  local numGreatWorks = 0
  local numDisplaySpaces = 0
  local cui_tmpBuildings = {} -- CUI

  local pCities = m_LocalPlayer:GetCities()
  for i, pCity in pCities:Members() do
    if pCity ~= nil and pCity:GetOwner() == m_LocalPlayerID then
      local pCityBldgs = pCity:GetBuildings()
      for buildingInfo in GameInfo.Buildings() do
        local buildingIndex = buildingInfo.Index
        local buildingType = buildingInfo.BuildingType
        if (pCityBldgs:HasBuilding(buildingIndex)) then
          local numSlots = pCityBldgs:GetNumGreatWorkSlots(buildingIndex)
          if (numSlots ~= nil and numSlots > 0) then
            --[[ CUI: sort
                        local instance = m_GreatWorkSlotsIM:GetInstance();
                        local greatWorks = PopulateGreatWorkSlot(instance, pCity, pCityBldgs, buildingInfo);
                        table.insert(m_GreatWorkBuildings, {Instance=instance, Type=buildingType, Index=buildingIndex, CityBldgs=pCityBldgs});
                        numDisplaySpaces = numDisplaySpaces + pCityBldgs:GetNumGreatWorkSlots(buildingIndex);
                        numGreatWorks = numGreatWorks + greatWorks;
                        ]]
            table.insert(cui_tmpBuildings, {
              Type = buildingType,
              Index = buildingIndex,
              CityBldgs = pCityBldgs,
              City = pCity,
              Info = buildingInfo
            })
          end
        end
      end
    end
  end

  -- CUI: sort
  local IsSortByCity = CuiSettings:GetBoolean(CuiSettings.SORT_BY_CITY)
  if not IsSortByCity then
    table.sort(cui_tmpBuildings, function(a, b)
      if a.Index == b.Index then
        return a.City:GetID() < b.City:GetID()
      else
        return a.Index < b.Index
      end
    end)
  end
  for _, item in ipairs(cui_tmpBuildings) do
    local instance = m_GreatWorkSlotsIM:GetInstance()
    local greatWorks = PopulateGreatWorkSlot(instance, item.City, item.CityBldgs, item.Info)
    table.insert(m_GreatWorkBuildings,
                 {Instance = instance, Type = item.Type, Index = item.Index, CityBldgs = item.CityBldgs})
    numDisplaySpaces = numDisplaySpaces + item.CityBldgs:GetNumGreatWorkSlots(item.Index)
    numGreatWorks = numGreatWorks + greatWorks
  end
  --
  Controls.NumGreatWorks:SetText(numGreatWorks)
  Controls.NumDisplaySpaces:SetText(numDisplaySpaces)

  -- Realize stack and scrollbar
  Controls.GreatWorksStack:CalculateSize()
  Controls.GreatWorksStack:ReprocessAnchoring()
  Controls.GreatWorksScrollPanel:CalculateInternalSize()
  Controls.GreatWorksScrollPanel:ReprocessAnchoring()

  m_TotalResourcesIM:ResetInstances()

  if table.count(m_GreatWorkYields) > 0 then
    table.sort(m_GreatWorkYields, function(a, b)
      return a.Name < b.Name
    end)

    for _, data in ipairs(m_GreatWorkYields) do
      local instance = m_TotalResourcesIM:GetInstance()
      instance.Resource:SetText(data.Icon .. data.Value)
      instance.Resource:SetToolTipString(data.Name)
    end

    Controls.TotalResources:CalculateSize()
    Controls.TotalResources:ReprocessAnchoring()
    Controls.ProvidingLabel:SetOffsetX(Controls.TotalResources:GetOffsetX() + Controls.TotalResources:GetSizeX() +
                                         PADDING_PROVIDING_LABEL)
    Controls.ProvidingLabel:SetHide(false)
  else
    Controls.ProvidingLabel:SetHide(true)
  end

  -- Hide "View Gallery" button if we don't have a single great work
  Controls.ViewGallery:SetHide(m_FirstGreatWork == nil)
  -- CUI
  Controls.SortGreatWork:SetHide(m_FirstGreatWork == nil)
  Controls.ThemeHelper:SetHide(m_FirstGreatWork == nil)
  --
end

function PopulateGreatWorkSlot(instance, pCity, pCityBldgs, pBuildingInfo)

  instance.DefaultBG:SetHide(false)
  instance.DisabledBG:SetHide(true)
  instance.HighlightedBG:SetHide(true)

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
        if firstGreatWork == nil then
          firstGreatWork = greatWorkInfo
        end
        if greatWorkInfo ~= nil and GreatWorkFitsTheme(pCityBldgs, pBuildingInfo, greatWorkIndex, greatWorkInfo) then
          numThemedGreatWorks = numThemedGreatWorks + 1
        end
      end
    end

    if firstGreatWork ~= nil and themeDescription ~= nil then
      local slotTypeIcon = "ICON_" .. firstGreatWork.GreatWorkObjectType
      if firstGreatWork.GreatWorkObjectType == GREAT_WORK_ARTIFACT_TYPE then
        slotTypeIcon = slotTypeIcon .. "_" .. firstGreatWork.EraType
      end

      local textureOffsetX, textureOffsetY, textureSheet = IconManager:FindIconAtlas(slotTypeIcon, SIZE_SLOT_TYPE_ICON)
      if (textureSheet == nil or textureSheet == "") then
        UI.DataError("Could not find slot type icon in PopulateGreatWorkSlot: icon=\"" .. slotTypeIcon ..
                       "\", iconSize=" .. tostring(SIZE_SLOT_TYPE_ICON))
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
          if (m_dest_city == pCityBldgs:GetCity():GetID()) then
            UI.PlaySound("UI_GREAT_WORKS_BONUS_ACHIEVED")
          end
        end
      end
    else
      if themeDescription ~= nil then
        -- if we're being called due to moving a work
        if numSlots > 1 then
          instance.ThemingLabel:SetText(Locale.Lookup("LOC_GREAT_WORKS_THEME_BONUS_PROGRESS", numThemedGreatWorks,
                                                      numSlots))
          if m_during_move then
            if buildingIndex == m_dest_building then
              if (m_dest_city == pCityBldgs:GetCity():GetID()) then
                if numThemedGreatWorks == 2 then
                  UI.PlaySound("UI_GreatWorks_Bonus_Increased")
                end
              end
            end
          end
        end

        if instance.ThemingLabel:GetText() ~= "" then
          instance.ThemingLabel:SetToolTipString(themeDescription)
        end
      end
    end
  end

  for row in GameInfo.Yields() do
    local yieldValue = pCityBldgs:GetBuildingYieldFromGreatWorks(row.Index, buildingIndex)
    if yieldValue > 0 then
      AddYield(themeBonusIM:GetInstance(), Locale.Lookup(row.Name), YIELD_FONT_ICONS[row.YieldType], yieldValue)
    end
  end

  local regularTourism = pCityBldgs:GetBuildingTourismFromGreatWorks(false, buildingIndex)
  local religionTourism = pCityBldgs:GetBuildingTourismFromGreatWorks(true, buildingIndex)
  local totalTourism = regularTourism + religionTourism

  if totalTourism > 0 then
    AddYield(themeBonusIM:GetInstance(), LOC_TOURISM, YIELD_FONT_ICONS[DATA_FIELD_TOURISM_YIELD], totalTourism)
  end

  instance.ThemeBonuses:CalculateSize()
  instance.ThemeBonuses:ReprocessAnchoring()

  return numGreatWorks
end

-- IMPORTANT: This logic is largely derived from GetGreatWorkTooltip() - if you make an update here, make sure to update that function as well
function GreatWorkFitsTheme(pCityBldgs, pBuildingInfo, greatWorkIndex, greatWorkInfo)
  local firstGreatWork = GetFirstGreatWorkInBuilding(pCityBldgs, pBuildingInfo)
  if firstGreatWork < 0 then
    return false
  end

  local firstGreatWorkObjectTypeID = pCityBldgs:GetGreatWorkTypeFromIndex(firstGreatWork)
  local firstGreatWorkObjectType = GameInfo.GreatWorks[firstGreatWorkObjectTypeID].GreatWorkObjectType

  if pCityBldgs:IsBuildingThemedCorrectly(GameInfo.Buildings[pBuildingInfo.BuildingType].Index) then
    return true
  else
    if pBuildingInfo.BuildingType == "BUILDING_MUSEUM_ART" then

      if firstGreatWork == greatWorkIndex then
        return true
      elseif not IsFirstGreatWorkByArtist(greatWorkIndex, pCityBldgs, pBuildingInfo) then
        return false
      else
        return firstGreatWorkObjectType == greatWorkInfo.GreatWorkObjectType
      end
    elseif pBuildingInfo.BuildingType == "BUILDING_MUSEUM_ARTIFACT" then

      if firstGreatWork == greatWorkIndex then
        return true
      else
        if greatWorkInfo.EraType ~= GameInfo.GreatWorks[firstGreatWorkObjectTypeID].EraType then
          return false
        else
          local greatWorkPlayer = Game.GetGreatWorkPlayer(greatWorkIndex)
          local greatWorks = GetGreatWorksInBuilding(pCityBldgs, pBuildingInfo)

          -- Find duplicates for theming description
          local hash = {}
          local duplicates = {}
          for _, index in ipairs(greatWorks) do
            local gwPlayer = Game.GetGreatWorkPlayer(index)
            if (not hash[gwPlayer]) then
              hash[gwPlayer] = true
            else
              table.insert(duplicates, gwPlayer)
            end
          end

          return table.count(duplicates) == 0
        end
      end
    end
  end
end

function GetGreatWorkIcon(greatWorkInfo)

  local greatWorkIcon

  if greatWorkInfo.GreatWorkObjectType == GREAT_WORK_ARTIFACT_TYPE then
    local greatWorkType = greatWorkInfo.GreatWorkType
    greatWorkType = greatWorkType:gsub("GREATWORK_ARTIFACT_", "")
    local greatWorkID = tonumber(greatWorkType)
    greatWorkID = ((greatWorkID - 1) % NUM_ARIFACT_TEXTURES) + 1
    greatWorkIcon = "ICON_GREATWORK_ARTIFACT_" .. greatWorkID
  elseif greatWorkInfo.GreatWorkObjectType == GREAT_WORK_RELIC_TYPE then
    local greatWorkType = greatWorkInfo.GreatWorkType
    greatWorkType = greatWorkType:gsub("GREATWORK_RELIC_", "")
    local greatWorkID = tonumber(greatWorkType)
    greatWorkID = ((greatWorkID - 1) % NUM_RELIC_TEXTURES) + 1
    greatWorkIcon = "ICON_GREATWORK_RELIC_" .. greatWorkID
  else
    greatWorkIcon = "ICON_" .. greatWorkInfo.GreatWorkType
  end

  local textureOffsetX, textureOffsetY, textureSheet = IconManager:FindIconAtlas(greatWorkIcon, SIZE_GREAT_WORK_ICON)
  if (textureSheet == nil or textureSheet == "") then
    UI.DataError("Could not find slot type icon in GetGreatWorkIcon: icon=\"" .. greatWorkIcon .. "\", iconSize=" ..
                   tostring(SIZE_GREAT_WORK_ICON))
  end

  return textureOffsetX, textureOffsetY, textureSheet
end

function GetThemeDescription(buildingType)
  local eBuilding = m_LocalPlayer:GetCulture():GetAutoThemedBuilding()
  if (GameInfo.Buildings[buildingType].Index == eBuilding) then
    return Locale.Lookup("LOC_BUILDING_THEMINGBONUS_FULL_MUSEUM")
  else
    for row in GameInfo.Building_GreatWorks() do
      if row.BuildingType == buildingType then
        if row.ThemingBonusDescription ~= nil then
          return Locale.Lookup(row.ThemingBonusDescription)
        end
      end
    end
  end
  return nil
end

function PopulateGreatWork(instance, pCityBldgs, pBuildingInfo, slotIndex, greatWorkIndex, slotType)

  local buildingIndex = pBuildingInfo.Index
  local slotTypeIcon = DEFAULT_GREAT_WORKS_ICONS[slotType]

  local textureOffsetX, textureOffsetY, textureSheet = IconManager:FindIconAtlas(slotTypeIcon, SIZE_SLOT_TYPE_ICON)
  if (textureSheet == nil or textureSheet == "") then
    UI.DataError("Could not find slot type icon in PopulateGreatWork: icon=\"" .. slotTypeIcon .. "\", iconSize=" ..
                   tostring(SIZE_SLOT_TYPE_ICON))
  else
    instance.SlotTypeIcon:SetTexture(textureOffsetX, textureOffsetY, textureSheet)
  end

  -- CUI reset masks
  instance.LockIcon:SetHide(true)
  instance.LockMask:SetHide(true)
  instance.ThemeMask:SetHide(true)
  --
  instance[DATA_FIELD_CITY_ID] = pCityBldgs:GetCity():GetID()
  instance[DATA_FIELD_BUILDING_ID] = buildingIndex
  instance[DATA_FIELD_SLOT_INDEX] = slotIndex
  instance[DATA_FIELD_GREAT_WORK_INDEX] = greatWorkIndex
  instance[DATA_FIELD_GREAT_WORK_TYPE] = -1

  if greatWorkIndex == -1 then
    instance.GreatWorkIcon:SetHide(true)

    local validWorks = ""
    for row in GameInfo.GreatWork_ValidSubTypes() do
      if slotType == row.GreatWorkSlotType then
        if validWorks ~= "" then
          validWorks = validWorks .. "[NEWLINE]"
        end
        validWorks = validWorks .. Locale.Lookup("LOC_" .. row.GreatWorkObjectType)
      end
    end

    instance.EmptySlot:ClearCallback(Mouse.eLClick)
    instance.EmptySlot:SetToolTipString(Locale.Lookup("LOC_GREAT_WORKS_EMPTY_TOOLTIP", validWorks))
  else
    instance.GreatWorkIcon:SetHide(false)

    -- CUI setup masks
    CuiSetLockMask(instance, pCityBldgs, buildingIndex, slotIndex)
    CuiSetThemeMask(instance, pCityBldgs, buildingIndex, slotIndex)
    instance.LockMask:SetHide(cui_ThemeHelper)
    instance.ThemeMask:SetHide(not cui_ThemeHelper)
    --
    local srcGreatWork = pCityBldgs:GetGreatWorkInSlot(buildingIndex, slotIndex)
    local srcGreatWorkType = pCityBldgs:GetGreatWorkTypeFromIndex(srcGreatWork)
    local srcGreatWorkObjectType = GameInfo.GreatWorks[srcGreatWorkType].GreatWorkObjectType

    instance[DATA_FIELD_GREAT_WORK_TYPE] = srcGreatWorkType

    local greatWorkType = pCityBldgs:GetGreatWorkTypeFromIndex(greatWorkIndex)
    local textureOffsetX, textureOffsetY, textureSheet = GetGreatWorkIcon(GameInfo.GreatWorks[greatWorkType])
    instance.GreatWorkIcon:SetTexture(textureOffsetX, textureOffsetY, textureSheet)

    instance.EmptySlot:SetToolTipString(GetGreatWorkTooltip(pCityBldgs, greatWorkIndex, greatWorkType, pBuildingInfo))

    local bAllowMove = true

    -- Don't allow moving artifacts if the museum is not full
    if bAllowMove and srcGreatWorkObjectType == GREAT_WORK_ARTIFACT_TYPE then
      if not IsBuildingFull(pCityBldgs, buildingIndex) then
        instance.GreatWorkDraggable:RegisterCallback(Drag.eDragDisabled, function()
          ShowCannotMoveMessage(Locale.Lookup("LOC_GREAT_WORKS_ARTIFACT_LOCKED_FROM_MOVE"))
        end)
        bAllowMove = false
      end
    end

    -- Don't allow moving art that has been recently created
    if bAllowMove and srcGreatWorkObjectType == "GREATWORKOBJECT_SCULPTURE" or srcGreatWorkObjectType ==
      "GREATWORKOBJECT_LANDSCAPE" or srcGreatWorkObjectType == "GREATWORKOBJECT_PORTRAIT" or srcGreatWorkObjectType ==
      "GREATWORKOBJECT_RELIGIOUS" then

      local iTurnCreated = pCityBldgs:GetTurnFromIndex(greatWorkIndex)
      local iCurrentTurn = Game.GetCurrentGameTurn()
      local iTurnsBeforeMove = GlobalParameters.GREATWORK_ART_LOCK_TIME or DEFAULT_LOCK_TURNS
      local iTurnsToWait = iTurnCreated + iTurnsBeforeMove - iCurrentTurn
      if iTurnsToWait > 0 then
        instance.GreatWorkDraggable:RegisterCallback(Drag.eDragDisabled, function()
          ShowCannotMoveMessage(Locale.Lookup("LOC_GREAT_WORKS_LOCKED_FROM_MOVE", iTurnsToWait))
        end)
        bAllowMove = false
      end
    end

    if bAllowMove then
      instance.GreatWorkDraggable:SetDisabled(false)
      instance.GreatWorkDraggable:RegisterCallback(Drag.eDown, function(kDragStruct)
        OnClickGreatWork(kDragStruct, pCityBldgs, buildingIndex, greatWorkIndex, slotIndex)
      end)
      instance.GreatWorkDraggable:RegisterCallback(Drag.eDrop, function(kDragStruct)
        OnGreatWorkDrop(kDragStruct, instance)
      end)
      instance.GreatWorkDraggable:RegisterCallback(Drag.eDrag, function(kDragStruct)
        OnGreatWorkDrag(kDragStruct, instance)
      end)
    else
      instance.GreatWorkDraggable:SetDisabled(true)
    end

    if m_FirstGreatWork == nil then
      m_FirstGreatWork = {Index = greatWorkIndex, Building = buildingIndex, CityBldgs = pCityBldgs}
    end
  end
  instance.EmptySlotHighlight:SetHide(true)
end

-- ===========================================================================
function OnGreatWorkDrop(kDragStruct, kInstance)
  if m_uiSelectedDropTarget ~= nil then
    if m_uiSelectedDropTarget == Controls.ViewGreatWork then
      OnViewGreatWork()
    else
      local kSelectedDropInstance = m_kControlToInstanceMap[m_uiSelectedDropTarget]
      if kSelectedDropInstance then
        MoveGreatWork(kInstance, kSelectedDropInstance)
      end
    end
  end
  ClearGreatWorkTransfer()
end

-- ===========================================================================
function OnGreatWorkDrag(kDragStruct, kInstance)
  local uiDragControl = kDragStruct:GetControl()
  local uiBestDropTarget = uiDragControl:GetBestOverlappingControl(m_kViableDropTargets)

  if uiBestDropTarget then
    HighlightDropTarget(uiBestDropTarget)
    m_uiSelectedDropTarget = uiBestDropTarget
  else
    HighlightDropTarget()
    m_uiSelectedDropTarget = nil
  end
end

-- ===========================================================================
function HighlightDropTarget(uiBestDropTarget)
  for _, uiDropTarget in ipairs(m_kViableDropTargets) do
    if uiDropTarget == Controls.ViewGreatWork then
      Controls.ViewGreatWork:SetSelected(uiBestDropTarget == Controls.ViewGreatWork)
    else
      local pDropInstance = m_kControlToInstanceMap[uiDropTarget]
      if pDropInstance ~= nil then
        pDropInstance.EmptySlotHighlight:SetHide(uiDropTarget ~= uiBestDropTarget)
      end
    end
  end
end

-- IMPORTANT: This logic is largely duplicated in GreatWorkFitsTheme() - if you make an update here, make sure to update that function as well
function GetGreatWorkTooltip(pCityBldgs, greatWorkIndex, greatWorkType, pBuildingInfo)
  local greatWorkTypeName
  local greatWorkInfo = GameInfo.GreatWorks[greatWorkType]
  local greatWorkCreator = Locale.Lookup(pCityBldgs:GetCreatorNameFromIndex(greatWorkIndex))

  local bIsThemeable = GetThemeDescription(pBuildingInfo.BuildingType) ~= nil
  local strBasicTooltip = GreatWorksSupport_GetBasicTooltip(greatWorkIndex, bIsThemeable)

  local buildingName = Locale.Lookup(GameInfo.Buildings[pBuildingInfo.BuildingType].Name)

  if greatWorkInfo.EraType ~= nil then
    greatWorkTypeName = Locale.Lookup("LOC_" .. greatWorkInfo.GreatWorkObjectType .. "_" .. greatWorkInfo.EraType)
  else
    greatWorkTypeName = Locale.Lookup("LOC_" .. greatWorkInfo.GreatWorkObjectType)
  end

  if bIsThemeable then
    local strThemeTooltip
    local firstGreatWork = GetFirstGreatWorkInBuilding(pCityBldgs, pBuildingInfo)
    if firstGreatWork < 0 then
      return strBasicTooltip
    end

    local firstGreatWorkObjectTypeID = pCityBldgs:GetGreatWorkTypeFromIndex(firstGreatWork)
    local firstGreatWorkObjectType = GameInfo.GreatWorks[firstGreatWorkObjectTypeID].GreatWorkObjectType

    if pCityBldgs:IsBuildingThemedCorrectly(GameInfo.Buildings[pBuildingInfo.BuildingType].Index) then
      strThemeTooltip = Locale.Lookup("LOC_GREAT_WORKS_ART_MATCHED_THEME", buildingName)
    else
      if pBuildingInfo.BuildingType == "BUILDING_MUSEUM_ART" then

        if firstGreatWork == greatWorkIndex then
          strThemeTooltip = Locale.Lookup("LOC_GREAT_WORKS_ART_THEME_SINGLE",
                                          Locale.Lookup("LOC_" .. firstGreatWorkObjectType))
        elseif not IsFirstGreatWorkByArtist(greatWorkIndex, pCityBldgs, pBuildingInfo) then
          -- Override the basic tooltip with the duplicate tooltip, this could be moved to GreatWorksSupport.lua depending on how it should work with artifacts
          local nTurnCreated = Game.GetGreatWorkDataFromIndex(greatWorkIndex).TurnCreated
          local greatWorkName = Locale.Lookup(greatWorkInfo.Name)
          local greatWorkCreationDate = Calendar.MakeDateStr(nTurnCreated, GameConfiguration.GetCalendarType(),
                                                             GameConfiguration.GetGameSpeedType(), false)
          strBasicTooltip = Locale.Lookup("LOC_GREAT_WORKS_TOOLTIP_DUPLICATE", greatWorkName, greatWorkTypeName,
                                          greatWorkCreator, greatWorkCreationDate)
          strThemeTooltip = Locale.Lookup("LOC_GREAT_WORKS_ART_THEME_DUPLICATE_ARTIST")
        elseif firstGreatWorkObjectType == greatWorkInfo.GreatWorkObjectType then
          strThemeTooltip = Locale.Lookup("LOC_GREAT_WORKS_ART_THEME_DUAL",
                                          Locale.Lookup("LOC_" .. firstGreatWorkObjectType))
        else
          strThemeTooltip = Locale.Lookup("LOC_GREAT_WORKS_MISMATCHED_THEME", greatWorkTypeName,
                                          Locale.Lookup("LOC_" .. firstGreatWorkObjectType .. "_PLURAL"))
        end
      elseif pBuildingInfo.BuildingType == "BUILDING_MUSEUM_ARTIFACT" then

        local artifactEraName = Locale.Lookup("LOC_" .. greatWorkInfo.GreatWorkObjectType .. "_" ..
                                                greatWorkInfo.EraType)
        if firstGreatWork == greatWorkIndex then
          strThemeTooltip = Locale.Lookup("LOC_GREAT_WORKS_ART_THEME_SINGLE", artifactEraName)
        else
          local firstArtifactEraName = Locale.Lookup("LOC_" .. firstGreatWorkObjectType .. "_" ..
                                                       GameInfo.GreatWorks[firstGreatWorkObjectTypeID].EraType ..
                                                       "_PLURAL")

          if greatWorkInfo.EraType ~= GameInfo.GreatWorks[firstGreatWorkObjectTypeID].EraType then
            strThemeTooltip = Locale.Lookup("LOC_GREAT_WORKS_MISMATCHED_ERA", artifactEraName, firstArtifactEraName)
          else
            local greatWorkPlayer = Game.GetGreatWorkPlayer(greatWorkIndex)
            local greatWorks = GetGreatWorksInBuilding(pCityBldgs, pBuildingInfo)

            -- Find duplicates for theming description
            local hash = {}
            local duplicates = {}
            for _, index in ipairs(greatWorks) do
              local gwPlayer = Game.GetGreatWorkPlayer(index)
              if (not hash[gwPlayer]) then
                hash[gwPlayer] = true
              else
                table.insert(duplicates, gwPlayer)
              end
            end

            if table.count(duplicates) > 0 then
              strThemeTooltip = Locale.Lookup("LOC_GREAT_WORKS_DUPLICATE_ARTIFACT_CIVS",
                                              PlayerConfigurations[duplicates[1]]:GetCivilizationShortDescription(),
                                              firstArtifactEraName)
            end
          end
        end
      end
    end
    if strThemeTooltip ~= nil then
      return strBasicTooltip .. "[NEWLINE][NEWLINE]" .. strThemeTooltip
    end
  end

  return strBasicTooltip
end

function GetFirstGreatWorkInBuilding(pCityBldgs, pBuildingInfo)
  local index = 0
  local buildingIndex = pBuildingInfo.Index
  local numSlots = pCityBldgs:GetNumGreatWorkSlots(buildingIndex)
  for _ = 0, numSlots - 1 do
    local greatWorkIndex = pCityBldgs:GetGreatWorkInSlot(buildingIndex, index)
    if greatWorkIndex ~= -1 then
      return greatWorkIndex
    end
    index = index + 1
  end
  return -1
end

function GetGreatWorksInBuilding(pCityBldgs, pBuildingInfo)
  local index = 0
  local results = {}
  local buildingIndex = pBuildingInfo.Index
  local numSlots = pCityBldgs:GetNumGreatWorkSlots(buildingIndex)
  for _ = 0, numSlots - 1 do
    local greatWorkIndex = pCityBldgs:GetGreatWorkInSlot(buildingIndex, index)
    if greatWorkIndex ~= -1 then
      table.insert(results, greatWorkIndex)
    end
    index = index + 1
  end
  return results
end

function IsFirstGreatWorkByArtist(greatWorkIndex, pCityBldgs, pBuildingInfo)
  local greatWorks = GetGreatWorksInBuilding(pCityBldgs, pBuildingInfo)
  local artist = pCityBldgs:GetCreatorNameFromIndex(greatWorkIndex) -- no need to localize

  -- Find duplicates for theming description
  for _, index in ipairs(greatWorks) do
    if (index == greatWorkIndex) then
      -- Didn't find a duplicate before the specified great work
      return true
    end

    local creator = pCityBldgs:GetCreatorNameFromIndex(index) -- no need to localize
    if (creator == artist) then
      -- Found a duplicate before the specified great work
      return false
    end
  end

  -- The specified great work isn't in this building, if it was added it would be unique
  return true
end

function AddYield(instance, yieldName, yieldIcon, yieldValue)
  local bFoundYield = false
  for _, data in ipairs(m_GreatWorkYields) do
    if data.Name == yieldName then
      data.Value = data.Value + yieldValue
      bFoundYield = true
      break
    end
  end
  if bFoundYield == false then
    table.insert(m_GreatWorkYields, {Name = yieldName, Icon = yieldIcon, Value = yieldValue})
  end
  instance.Resource:SetText(yieldIcon .. yieldValue)
  instance.Resource:SetToolTipString(yieldName)
end

function OnClickGreatWork(kDragStruct, pCityBldgs, buildingIndex, greatWorkIndex, slotIndex)

  -- Don't allow moving great works unless it's the local player's turn
  if not m_isLocalPlayerTurn then
    return
  end

  -- Don't allow moving artifacts if the museum is not full
  if not CanMoveWorkAtAll(pCityBldgs, buildingIndex, slotIndex) then
    return
  end

  local greatWorkType = pCityBldgs:GetGreatWorkTypeFromIndex(greatWorkIndex)

  -- Subscribe to updates to keep great work icon attached to mouse
  m_GreatWorkSelected = {Index = greatWorkIndex, Slot = slotIndex, Building = buildingIndex, CityBldgs = pCityBldgs}

  -- Set placing label and details
  Controls.PlacingContainer:SetHide(false)
  Controls.HeaderStatsContainer:SetHide(true)
  Controls.PlacingName:SetText(Locale.ToUpper(Locale.Lookup(GameInfo.GreatWorks[greatWorkType].Name)))
  local textureOffsetX, textureOffsetY, textureSheet = GetGreatWorkIcon(GameInfo.GreatWorks[greatWorkType])
  Controls.PlacingIcon:SetTexture(textureOffsetX, textureOffsetY, textureSheet)

  for _, destination in ipairs(m_GreatWorkBuildings) do
    local firstValidSlot = -1
    local instance = destination.Instance
    local dstBuilding = destination.Index
    local dstBldgs = destination.CityBldgs
    local slotCache = instance[DATA_FIELD_SLOT_CACHE]
    local numSlots = dstBldgs:GetNumGreatWorkSlots(dstBuilding)
    for index = 0, numSlots - 1 do
      if CanMoveGreatWork(pCityBldgs, buildingIndex, slotIndex, dstBldgs, dstBuilding, index) then
        if firstValidSlot == -1 then
          firstValidSlot = index
        end

        local slotInstance = slotCache[index + 1]
        if slotInstance then
          table.insert(m_kViableDropTargets, slotInstance.TopControl)
          m_kControlToInstanceMap[slotInstance.TopControl] = slotInstance
        end
      end
    end

    if firstValidSlot ~= -1 then
      UI.PlaySound("UI_GreatWorks_Pick_Up")
    end

    instance.HighlightedBG:SetHide(firstValidSlot == -1)
    instance.DefaultBG:SetHide(firstValidSlot == -1)
    instance.DisabledBG:SetHide(firstValidSlot ~= -1)
  end

  -- Add ViewGreatWorks button to drop targets so we can view specific works
  table.insert(m_kViableDropTargets, Controls.ViewGreatWork)
end

-- ===========================================================================
function CanMoveWorkAtAll(srcBldgs, srcBuilding, srcSlot)
  local srcGreatWork = srcBldgs:GetGreatWorkInSlot(srcBuilding, srcSlot)
  local srcGreatWorkType = srcBldgs:GetGreatWorkTypeFromIndex(srcGreatWork)
  local srcGreatWorkObjectType = GameInfo.GreatWorks[srcGreatWorkType].GreatWorkObjectType

  -- Don't allow moving artifacts if the museum is not full
  if (srcGreatWorkObjectType == GREAT_WORK_ARTIFACT_TYPE) then
    if not IsBuildingFull(srcBldgs, srcBuilding) then
      return false
    end
  end

  -- Don't allow moving art that has been recently created
  if (srcGreatWorkObjectType == "GREATWORKOBJECT_SCULPTURE" or srcGreatWorkObjectType == "GREATWORKOBJECT_LANDSCAPE" or
    srcGreatWorkObjectType == "GREATWORKOBJECT_PORTRAIT" or srcGreatWorkObjectType == "GREATWORKOBJECT_RELIGIOUS") then

    local iTurnCreated = srcBldgs:GetTurnFromIndex(srcGreatWork)
    local iCurrentTurn = Game.GetCurrentGameTurn()
    local iTurnsBeforeMove = GlobalParameters.GREATWORK_ART_LOCK_TIME or DEFAULT_LOCK_TURNS
    local iTurnsToWait = iTurnCreated + iTurnsBeforeMove - iCurrentTurn
    if iTurnsToWait > 0 then
      return false
    end
  end

  return true
end

-- ===========================================================================
function IsBuildingFull(pBuildings, buildingIndex)
  local numSlots = pBuildings:GetNumGreatWorkSlots(buildingIndex)
  for index = 0, numSlots - 1 do
    local greatWorkIndex = pBuildings:GetGreatWorkInSlot(buildingIndex, index)
    if (greatWorkIndex == -1) then
      return false
    end
  end

  return true
end

-- ===========================================================================
function ShowCannotMoveMessage(sMessage)
  local cannotMoveWorkDialog = PopupDialogInGame:new("CannotMoveWork")
  cannotMoveWorkDialog:ShowOkDialog(sMessage)
end

-- ===========================================================================
function CanMoveToSlot(destBldgs, destBuilding)

  -- Don't allow moving artifacts if the museum is not full
  local srcGreatWorkType = m_GreatWorkSelected.CityBldgs:GetGreatWorkTypeFromIndex(m_GreatWorkSelected.Index)
  local srcGreatWorkObjectType = GameInfo.GreatWorks[srcGreatWorkType].GreatWorkObjectType
  if (srcGreatWorkObjectType ~= GREAT_WORK_ARTIFACT_TYPE) then
    return true
  end

  -- Don't allow moving artifacts if the museum is not full
  local numSlots = destBldgs:GetNumGreatWorkSlots(destBuilding)
  for index = 0, numSlots - 1 do
    local greatWorkIndex = destBldgs:GetGreatWorkInSlot(destBuilding, index)
    if (greatWorkIndex == -1) then
      return false
    end
  end

  return true
end

-- ===========================================================================
function CanMoveGreatWork(srcBldgs, srcBuilding, srcSlot, dstBldgs, dstBuilding, dstSlot)

  local srcGreatWork = srcBldgs:GetGreatWorkInSlot(srcBuilding, srcSlot)
  local srcGreatWorkType = srcBldgs:GetGreatWorkTypeFromIndex(srcGreatWork)
  local srcGreatWorkObjectType = GameInfo.GreatWorks[srcGreatWorkType].GreatWorkObjectType

  local dstGreatWork = dstBldgs:GetGreatWorkInSlot(dstBuilding, dstSlot)
  local dstSlotType = dstBldgs:GetGreatWorkSlotType(dstBuilding, dstSlot)
  local dstSlotTypeString = GameInfo.GreatWorkSlotTypes[dstSlotType].GreatWorkSlotType

  for row in GameInfo.GreatWork_ValidSubTypes() do
    -- Ensure source great work can be placed into destination slot
    if dstSlotTypeString == row.GreatWorkSlotType and srcGreatWorkObjectType == row.GreatWorkObjectType then
      if dstGreatWork == -1 then
        -- Artifacts can never be moved to an empty slot as
        -- they can only be swapped between other full museums
        return row.GreatWorkObjectType ~= GREAT_WORK_ARTIFACT_TYPE
      else -- If destination slot has a great work, ensure it can be swapped to the source slot
        local srcSlotType = srcBldgs:GetGreatWorkSlotType(srcBuilding, srcSlot)
        local srcSlotTypeString = GameInfo.GreatWorkSlotTypes[srcSlotType].GreatWorkSlotType

        local dstGreatWorkType = dstBldgs:GetGreatWorkTypeFromIndex(dstGreatWork)
        local dstGreatWorkObjectType = GameInfo.GreatWorks[dstGreatWorkType].GreatWorkObjectType

        for row in GameInfo.GreatWork_ValidSubTypes() do
          if srcSlotTypeString == row.GreatWorkSlotType and dstGreatWorkObjectType == row.GreatWorkObjectType then
            return CanMoveWorkAtAll(dstBldgs, dstBuilding, dstSlot)
          end
        end
      end
    end
  end
  return false
end

-- ===========================================================================
function MoveGreatWork(kSrcInstance, kDestInstance)
  if kSrcInstance ~= nil and kDestInstance ~= nil then
    -- Don't try to move the great work if it was dropped on the slot it was already in
    if kSrcInstance[DATA_FIELD_CITY_ID] == kDestInstance[DATA_FIELD_CITY_ID] and kSrcInstance[DATA_FIELD_BUILDING_ID] ==
      kDestInstance[DATA_FIELD_BUILDING_ID] and kSrcInstance[DATA_FIELD_SLOT_INDEX] ==
      kDestInstance[DATA_FIELD_SLOT_INDEX] then

      kSrcInstance.EmptySlotHighlight:SetHide(true)
      return
    end

    -- Swap instance great work icons while we wait for the game core to update
    local sourceGreatWorkType = kSrcInstance[DATA_FIELD_GREAT_WORK_TYPE]
    local destGreatWorkType = kDestInstance[DATA_FIELD_GREAT_WORK_TYPE]

    if destGreatWorkType == -1 then
      kSrcInstance.GreatWorkIcon:SetHide(true)
    else
      local textureOffsetX, textureOffsetY, textureSheet = GetGreatWorkIcon(GameInfo.GreatWorks[destGreatWorkType])
      kSrcInstance.GreatWorkIcon:SetHide(false)
      kSrcInstance.GreatWorkIcon:SetTexture(textureOffsetX, textureOffsetY, textureSheet)
    end

    if sourceGreatWorkType == -1 then
      kDestInstance.GreatWorkIcon:SetHide(true)
    else
      local textureOffsetX, textureOffsetY, textureSheet = GetGreatWorkIcon(GameInfo.GreatWorks[sourceGreatWorkType])
      kDestInstance.GreatWorkIcon:SetHide(false)
      kDestInstance.GreatWorkIcon:SetTexture(textureOffsetX, textureOffsetY, textureSheet)
    end

    m_dest_building = kDestInstance[DATA_FIELD_BUILDING_ID]
    m_dest_city = kDestInstance[DATA_FIELD_CITY_ID]

    local tParameters = {}
    tParameters[PlayerOperations.PARAM_PLAYER_ONE] = Game.GetLocalPlayer()
    tParameters[PlayerOperations.PARAM_CITY_SRC] = kSrcInstance[DATA_FIELD_CITY_ID]
    tParameters[PlayerOperations.PARAM_CITY_DEST] = kDestInstance[DATA_FIELD_CITY_ID]
    tParameters[PlayerOperations.PARAM_BUILDING_SRC] = kSrcInstance[DATA_FIELD_BUILDING_ID]
    tParameters[PlayerOperations.PARAM_BUILDING_DEST] = kDestInstance[DATA_FIELD_BUILDING_ID]
    tParameters[PlayerOperations.PARAM_GREAT_WORK_INDEX] = kSrcInstance[DATA_FIELD_GREAT_WORK_INDEX]
    tParameters[PlayerOperations.PARAM_SLOT] = kDestInstance[DATA_FIELD_SLOT_INDEX]
    UI.RequestPlayerOperation(Game.GetLocalPlayer(), PlayerOperations.MOVE_GREAT_WORK, tParameters)

    UI.PlaySound("UI_GreatWorks_Put_Down")
  end
  ContextPtr:ClearUpdate()
end

-- ===========================================================================
function ClearGreatWorkTransfer()
  m_GreatWorkSelected = nil
  m_kViableDropTargets = {}
  m_kControlToInstanceMap = {}

  for _, destination in ipairs(m_GreatWorkBuildings) do
    local instance = destination.Instance
    instance.HighlightedBG:SetHide(true)
    instance.DefaultBG:SetHide(false)
    instance.DisabledBG:SetHide(true)
  end

  Controls.PlacingContainer:SetHide(true)
  Controls.HeaderStatsContainer:SetHide(false)

  ContextPtr:ClearUpdate()
end

-- ===========================================================================
--	Update player data and refresh the display state
-- ===========================================================================
function UpdateData()
  UpdatePlayerData()
  UpdateGreatWorks()
end

-- ===========================================================================
--	Show / Hide
-- ===========================================================================
function Open()
  if (Game.GetLocalPlayer() == -1) then
    return
  end

  cui_ThemeHelper = false -- CUI

  -- CUI
  if not UIManager:IsInPopupQueue(ContextPtr) then
    local kParameters = {}
    kParameters.RenderAtCurrentParent = true
    kParameters.InputAtCurrentParent = true
    kParameters.AlwaysVisibleInQueue = true
    UIManager:QueuePopup(ContextPtr, PopupPriority.Low, kParameters)
    UI.PlaySound("UI_Screen_Open")
  end
  --
  UpdateData()
  ContextPtr:SetHide(false)

  Controls.Vignette:SetSizeY(m_TopPanelConsideredHeight) -- CUI

  -- From Civ6_styles: FullScreenVignetteConsumer
  Controls.ScreenAnimIn:SetToBeginning()
  Controls.ScreenAnimIn:Play()

  LuaEvents.GreatWorks_OpenGreatWorks()
end

function Close()

  cui_ThemeHelper = false -- CUI

  -- CUI
  if not ContextPtr:IsHidden() then
    UI.PlaySound("UI_Screen_Close")
  end

  if UIManager:DequeuePopup(ContextPtr) then
    LuaEvents.GreatPeople_CloseGreatPeople()
  end
  --
  ContextPtr:SetHide(true)
  ContextPtr:ClearUpdate()
end

function ViewGreatWork(greatWorkData)
  local city = greatWorkData.CityBldgs:GetCity()
  local buildingID = greatWorkData.Building
  local greatWorkIndex = greatWorkData.Index
  LuaEvents.GreatWorksOverview_ViewGreatWork(city, buildingID, greatWorkIndex)
end

-- ===========================================================================
--	Game Event Callbacks
-- ===========================================================================
function OnShowScreen()
  if (Game.GetLocalPlayer() == -1) then
    return
  end

  Open()
  -- CUI UI.PlaySound("UI_Screen_Open");
end

-- ===========================================================================
function OnHideScreen()
  if not ContextPtr:IsHidden() then
    UI.PlaySound("UI_Screen_Close")
  end

  Close()
  LuaEvents.GreatWorks_CloseGreatWorks()
end

-- ===========================================================================
function OnInputHandler(pInputStruct)
  local uiMsg = pInputStruct:GetMessageType()
  if uiMsg == KeyEvents.KeyUp and pInputStruct:GetKey() == Keys.VK_ESCAPE then
    if m_GreatWorkSelected ~= nil then
      ClearGreatWorkTransfer()
    else
      OnHideScreen()
    end
    return true
  end
  return false
end

-- ===========================================================================
function OnViewGallery()
  if m_FirstGreatWork ~= nil then
    ViewGreatWork(m_FirstGreatWork)
    if m_GreatWorkSelected ~= nil then
      ClearGreatWorkTransfer()
    end
    UI.PlaySound("Play_GreatWorks_Gallery_Ambience")
  end
end

-- ===========================================================================
function OnViewGreatWork()
  if m_GreatWorkSelected ~= nil then
    ViewGreatWork(m_GreatWorkSelected)
    ClearGreatWorkTransfer()
    UpdateData()
    UI.PlaySound("Play_GreatWorks_Gallery_Ambience")
  end
end

------------------------------------------------------------------------------
-- A great work was moved.
function OnGreatWorkMoved(fromCityOwner, fromCityID, toCityOwner, toCityID, buildingID, greatWorkType)
  if (not ContextPtr:IsHidden() and (fromCityOwner == Game.GetLocalPlayer() or toCityOwner == Game.GetLocalPlayer())) then
    m_during_move = true
    UpdateData()
    m_during_move = false
  end
end

-- ===========================================================================
--	Hot Reload Related Events
-- ===========================================================================
function OnInit(isReload)
  if isReload then
    LuaEvents.GameDebug_GetValues(RELOAD_CACHE_ID)
  end
end
function OnShutdown()
  LuaEvents.GameDebug_AddValue(RELOAD_CACHE_ID, "isHidden", ContextPtr:IsHidden())

  LuaEvents.GameDebug_Return.Remove(OnGameDebugReturn)
  LuaEvents.LaunchBar_OpenGreatWorksOverview.Remove(OnShowScreen)
  LuaEvents.GreatWorkCreated_OpenGreatWorksOverview.Remove(OnShowScreen)
  LuaEvents.LaunchBar_CloseGreatWorksOverview.Remove(OnHideScreen)

  Events.GreatWorkMoved.Remove(OnGreatWorkMoved)
  Events.LocalPlayerTurnBegin.Remove(OnLocalPlayerTurnBegin)
  Events.LocalPlayerTurnEnd.Remove(OnLocalPlayerTurnEnd)
end
function OnGameDebugReturn(context, contextTable)
  if context == RELOAD_CACHE_ID and contextTable["isHidden"] ~= nil and not contextTable["isHidden"] then
    Open()
  end
end

-- ===========================================================================
--	Player Turn Events
-- ===========================================================================
function OnLocalPlayerTurnBegin()
  m_isLocalPlayerTurn = true
end
function OnLocalPlayerTurnEnd()
  m_isLocalPlayerTurn = false
  if (GameConfiguration.IsHotseat()) then
    OnHideScreen()
  end
end

-- CUI =======================================================================
function CuiSetThemeMask(instance, srcBldgs, srcBuilding, srcSlot)
  local srcGreatWork = srcBldgs:GetGreatWorkInSlot(srcBuilding, srcSlot)
  local srcGreatWorkType = srcBldgs:GetGreatWorkTypeFromIndex(srcGreatWork)
  local srcGreatWorkObjectType = GameInfo.GreatWorks[srcGreatWorkType].GreatWorkObjectType
  local greatWorkInfo = GameInfo.GreatWorks[srcGreatWorkType]

  local artist = 0
  if greatWorkInfo.GreatPersonReference then
    artist = greatWorkInfo.GreatPersonReference.Index
  elseif greatWorkInfo.EraType then
    artist = Game.GetGreatWorkPlayer(srcGreatWork)
  end
  instance.ThemeText:SetText(artist)
  instance.ThemeBacking:SetHide(false)

  if srcGreatWorkObjectType == "GREATWORKOBJECT_ARTIFACT" then
    if greatWorkInfo.EraType == "ERA_ANCIENT" then
      instance.ThemeColor:SetColorByName("Civ6Blue")
    elseif greatWorkInfo.EraType == "ERA_CLASSICAL" then
      instance.ThemeColor:SetColorByName("Civ6DarkRed")
    elseif greatWorkInfo.EraType == "ERA_MEDIEVAL" then
      instance.ThemeColor:SetColorByName("Civ6Green")
    elseif greatWorkInfo.EraType == "ERA_RENAISSANCE" then
      instance.ThemeColor:SetColorByName("Civ6LightBlue")
    elseif greatWorkInfo.EraType == "ERA_INDUSTRIAL" then
      instance.ThemeColor:SetColorByName("Civ6Red")
    end
  elseif srcGreatWorkObjectType == "GREATWORKOBJECT_SCULPTURE" then
    instance.ThemeColor:SetColorByName("COLOR_FLOAT_CULTURE")
  elseif srcGreatWorkObjectType == "GREATWORKOBJECT_LANDSCAPE" then
    instance.ThemeColor:SetColorByName("COLOR_FLOAT_FOOD")
  elseif srcGreatWorkObjectType == "GREATWORKOBJECT_PORTRAIT" then
    instance.ThemeColor:SetColorByName("COLOR_FLOAT_GOLD")
  elseif srcGreatWorkObjectType == "GREATWORKOBJECT_RELIGIOUS" then
    instance.ThemeColor:SetColorByName("COLOR_FLOAT_PRODUCTION")
  else
    instance.ThemeColor:SetColorByName("Clear")
    instance.ThemeBacking:SetHide(true)
    instance.ThemeText:SetText(" ")
  end
end

-- CUI =======================================================================
function CuiSetLockMask(instance, srcBldgs, srcBuilding, srcSlot)
  local srcGreatWork = srcBldgs:GetGreatWorkInSlot(srcBuilding, srcSlot)
  local srcGreatWorkType = srcBldgs:GetGreatWorkTypeFromIndex(srcGreatWork)
  local srcGreatWorkObjectType = GameInfo.GreatWorks[srcGreatWorkType].GreatWorkObjectType

  instance.LockIcon:SetHide(true)
  instance.LockMask:SetHide(true)
  instance.LockColor:SetColorByName("Clear")
  instance.LockText:SetText(" ")

  -- lock no turns
  if (srcGreatWorkObjectType == "GREATWORKOBJECT_ARTIFACT") then
    local numSlots = srcBldgs:GetNumGreatWorkSlots(srcBuilding)
    for index = 0, numSlots - 1 do
      local greatWorkIndex = srcBldgs:GetGreatWorkInSlot(srcBuilding, index)
      if (greatWorkIndex == -1) then
        instance.LockIcon:SetHide(false)
        instance.LockMask:SetHide(false)
        instance.LockColor:SetColorByName("Black")
        instance.LockText:SetText(" ")
      end
    end
    -- lock with turns
  elseif (srcGreatWorkObjectType == "GREATWORKOBJECT_SCULPTURE" or srcGreatWorkObjectType == "GREATWORKOBJECT_LANDSCAPE" or
    srcGreatWorkObjectType == "GREATWORKOBJECT_PORTRAIT" or srcGreatWorkObjectType == "GREATWORKOBJECT_RELIGIOUS") then
    local iTurnCreated = srcBldgs:GetTurnFromIndex(srcGreatWork)
    local iCurrentTurn = Game.GetCurrentGameTurn()
    local iTurnsBeforeMove = GlobalParameters.GREATWORK_ART_LOCK_TIME or 10
    local iTurnsToWait = iTurnCreated + iTurnsBeforeMove - iCurrentTurn
    if iTurnsToWait > 0 then
      instance.LockIcon:SetHide(false)
      instance.LockMask:SetHide(false)
      instance.LockColor:SetColorByName("Black")
      instance.LockText:SetText(iTurnsToWait .. "[ICON_TURN]")
    end
  end
end

-- CUI =======================================================================
function CuiOnSortButtonClick()
  local IsSortByCity = CuiSettings:ReverseAndGetBoolean(CuiSettings.SORT_BY_CITY)
  if IsSortByCity then
    Controls.SortGreatWork:SetText(Locale.Lookup("LOC_CUI_GW_SORT_BY_BUILDING"))
  else
    Controls.SortGreatWork:SetText(Locale.Lookup("LOC_CUI_GW_SORT_BY_CITY"))
  end
  UpdateData()
end

-- CUI =======================================================================
function CuiOnThemeButtonClick()
  cui_ThemeHelper = not cui_ThemeHelper
  UpdateData()
end

-- CUI =======================================================================
function CuiInit()
  local IsSortByCity = CuiSettings:GetBoolean(CuiSettings.SORT_BY_CITY)
  if IsSortByCity then
    Controls.SortGreatWork:SetText(Locale.Lookup("LOC_CUI_GW_SORT_BY_BUILDING"))
  else
    Controls.SortGreatWork:SetText(Locale.Lookup("LOC_CUI_GW_SORT_BY_CITY"))
  end
  Controls.SortGreatWork:RegisterCallback(Mouse.eLClick, CuiOnSortButtonClick)
  Controls.SortGreatWork:RegisterCallback(Mouse.eMouseEnter, function()
    UI.PlaySound("Main_Menu_Mouse_Over")
  end)
  Controls.ThemeHelper:RegisterCallback(Mouse.eLClick, CuiOnThemeButtonClick)
  Controls.ThemeHelper:RegisterCallback(Mouse.eMouseEnter, function()
    UI.PlaySound("Main_Menu_Mouse_Over")
  end)
  Controls.ThemeHelper:SetToolTipString(Locale.Lookup("LOC_CUI_GW_THEMING_HELPER_TOOLTIP"))
end

-- ===========================================================================
--	INIT
-- ===========================================================================
function Initialize()

  if (not HasCapability("CAPABILITY_GREAT_WORKS_VIEW")) then
    -- Viewing Great Works is off, just exit
    return
  end

  CuiInit() -- CUI

  ContextPtr:SetInitHandler(OnInit)
  ContextPtr:SetShutdown(OnShutdown)
  ContextPtr:SetInputHandler(OnInputHandler, true)

  Controls.ModalBG:SetTexture("GreatWorks_Background")
  Controls.ModalScreenTitle:SetText(Locale.ToUpper(LOC_SCREEN_TITLE))
  Controls.ModalScreenClose:RegisterCallback(Mouse.eLClick, OnHideScreen)
  Controls.ModalScreenClose:RegisterCallback(Mouse.eMouseEnter, function()
    UI.PlaySound("Main_Menu_Mouse_Over")
  end)
  Controls.ViewGallery:RegisterCallback(Mouse.eLClick, OnViewGallery)
  Controls.ViewGallery:RegisterCallback(Mouse.eMouseEnter, function()
    UI.PlaySound("Main_Menu_Mouse_Over")
  end)
  Controls.ViewGreatWork:RegisterCallback(Mouse.eLClick, OnViewGreatWork)
  Controls.ViewGreatWork:RegisterCallback(Mouse.eMouseEnter, function()
    UI.PlaySound("Main_Menu_Mouse_Over")
  end)

  LuaEvents.GameDebug_Return.Add(OnGameDebugReturn)
  LuaEvents.LaunchBar_OpenGreatWorksOverview.Add(OnShowScreen)
  LuaEvents.GreatWorkCreated_OpenGreatWorksOverview.Add(OnShowScreen)
  LuaEvents.LaunchBar_CloseGreatWorksOverview.Add(OnHideScreen)

  Events.GreatWorkMoved.Add(OnGreatWorkMoved)
  Events.LocalPlayerTurnBegin.Add(OnLocalPlayerTurnBegin)
  Events.LocalPlayerTurnEnd.Add(OnLocalPlayerTurnEnd)

  m_TopPanelConsideredHeight = Controls.Vignette:GetSizeY() - TOP_PANEL_OFFSET -- CUI
end
Initialize()
