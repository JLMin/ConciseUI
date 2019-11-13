-- ===========================================================================--	ReligionScreen
--	View list of slots representing districts that can house great works.
--
--	Original Authors: Sam Batista
-- ===========================================================================
include("InstanceManager")
include("cui_settings") -- CUI

-- ===========================================================================
--	CONSTANTS
-- ===========================================================================
local RELOAD_CACHE_ID = "GreatWorkShowcase" -- Must be unique (usually the same as the file name)
local GREAT_WORK_MUSIC_TYPE = "GREATWORKOBJECT_MUSIC"
local GREAT_WORK_RELIC_TYPE = "GREATWORKOBJECT_RELIC"
local GREAT_WORK_WRITING_TYPE = "GREATWORKOBJECT_WRITING"
local GREAT_WORK_ARTIFACT_TYPE = "GREATWORKOBJECT_ARTIFACT"
local GREAT_WORK_MUSIC_TEXTURE = "MUSIC"
local GREAT_WORK_WRITING_TEXTURE = "WRITING"
local LOC_NEW_GREAT_WORK = Locale.Lookup("LOC_GREAT_WORKS_NEW_GREAT_WORK")
local LOC_VIEW_GREAT_WORKS = Locale.Lookup("LOC_GREAT_WORKS_VIEW_GREAT_WORKS")
local LOC_BACK_TO_GREAT_WORKS = Locale.Lookup("LOC_GREAT_WORKS_BACK_TO_GREAT_WORKS")
local DETAILS_OFFSET_DEFAULT = -26
local DETAILS_OFFSET_WRITING = -90
local DETAILS_OFFSET_MUSIC = -277
local NUM_ARIFACT_TEXTURES = 25
local NUM_RELIC_TEXTURES = 24
local SIZE_MAX_IMAGE_HEIGHT = 467
local SIZE_BANNER_MIN = 506
local PADDING_BANNER = 120

-- ===========================================================================
--	SCREEN VARIABLES
-- ===========================================================================
local m_City
local m_CityBldgs
local m_GreatWorks
local m_BuildingID = -1
local m_GreatWorkType = -1
local m_GreatWorkIndex = -1
local m_GalleryIndex = -1
local m_isGallery = false

-- ===========================================================================
--	PLAYER VARIABLES
-- ===========================================================================
local m_LocalPlayer
local m_LocalPlayerID

-- ===========================================================================
--	Called every time screen is shown
-- ===========================================================================
function UpdatePlayerData()
  m_LocalPlayerID = Game.GetLocalPlayer()
  if m_LocalPlayerID ~= -1 then m_LocalPlayer = Players[m_LocalPlayerID] end
end

-- ===========================================================================
--	Called when viewing the Great Works Gallery
-- ===========================================================================
function UpdateGalleryData()
  if (m_LocalPlayer == nil) then return end

  m_GreatWorks = {}
  m_GalleryIndex = -1
  local pCities = m_LocalPlayer:GetCities()
  for i, pCity in pCities:Members() do
    if pCity ~= nil and pCity:GetOwner() == m_LocalPlayerID then
      local pCityBldgs = pCity:GetBuildings()
      for buildingInfo in GameInfo.Buildings() do
        local buildingIndex = buildingInfo.Index
        if (pCityBldgs:HasBuilding(buildingIndex)) then
          local numSlots = pCityBldgs:GetNumGreatWorkSlots(buildingIndex)
          for index = 0, numSlots - 1 do
            local greatWorkIndex = pCityBldgs:GetGreatWorkInSlot(buildingIndex, index)
            if greatWorkIndex ~= -1 then
              table.insert(m_GreatWorks, {Index = greatWorkIndex, Building = buildingIndex, City = pCity})
              if greatWorkIndex == m_GreatWorkIndex then m_GalleryIndex = table.count(m_GreatWorks) end
            end
          end
        end
      end
    end
  end

  local canCycleGreatWorks = m_GalleryIndex ~= -1 and table.count(m_GreatWorks) > 1
  Controls.PreviousGreatWork:SetHide(not canCycleGreatWorks)
  Controls.NextGreatWork:SetHide(not canCycleGreatWorks)
end

-- ===========================================================================
--	Called every time screen is shown
-- ===========================================================================
function UpdateGreatWork()

  Controls.MusicDetails:SetHide(true)
  Controls.WritingDetails:SetHide(true)
  Controls.GreatWorkBanner:SetHide(true)
  Controls.GalleryBG:SetHide(true)

  local greatWorkInfo = GameInfo.GreatWorks[m_GreatWorkType]
  local greatWorkType = greatWorkInfo.GreatWorkType
  local greatWorkCreator = Locale.Lookup(m_CityBldgs:GetCreatorNameFromIndex(m_GreatWorkIndex))
  local greatWorkCreationDate = Calendar.MakeDateStr(m_CityBldgs:GetTurnFromIndex(m_GreatWorkIndex), GameConfiguration.GetCalendarType(),
                                                     GameConfiguration.GetGameSpeedType(), false)
  local greatWorkCreationCity = m_City:GetName()
  local greatWorkCreationBuilding = GameInfo.Buildings[m_BuildingID].Name
  local greatWorkObjectType = greatWorkInfo.GreatWorkObjectType

  local greatWorkTypeName
  if greatWorkInfo.EraType ~= nil then
    greatWorkTypeName = Locale.Lookup("LOC_" .. greatWorkInfo.GreatWorkObjectType .. "_" .. greatWorkInfo.EraType)
  else
    greatWorkTypeName = Locale.Lookup("LOC_" .. greatWorkInfo.GreatWorkObjectType)
  end

  if greatWorkInfo.Audio then UI.PlaySound("Play_" .. greatWorkInfo.Audio) end

  local heightAdjustment = 0
  local detailsOffset = DETAILS_OFFSET_DEFAULT
  if greatWorkObjectType == GREAT_WORK_MUSIC_TYPE then
    detailsOffset = DETAILS_OFFSET_MUSIC
    Controls.GreatWorkImage:SetOffsetY(95)
    Controls.GreatWorkImage:SetTexture(GREAT_WORK_MUSIC_TEXTURE)
    Controls.MusicName:SetText(Locale.ToUpper(Locale.Lookup(greatWorkInfo.Name)))
    Controls.MusicAuthor:SetText("-" .. greatWorkCreator)
    Controls.MusicDetails:SetHide(false)
  elseif greatWorkObjectType == GREAT_WORK_WRITING_TYPE then
    detailsOffset = DETAILS_OFFSET_WRITING
    Controls.GreatWorkImage:SetOffsetY(0)
    Controls.GreatWorkImage:SetTexture(GREAT_WORK_WRITING_TEXTURE)
    Controls.WritingName:SetText(Locale.ToUpper(Locale.Lookup(greatWorkInfo.Name)))
    local quoteKey = greatWorkInfo.Quote
    if (quoteKey ~= nil) then
      Controls.WritingLine:SetHide(false)
      Controls.WritingQuote:SetText(Locale.Lookup(quoteKey))
      Controls.WritingQuote:SetHide(false)
      Controls.WritingAuthor:SetText("-" .. greatWorkCreator)
      Controls.WritingAuthor:SetHide(false)
      Controls.WritingDeco:SetHide(true)
    else
      local titleOffset = -45
      Controls.WritingName:SetOffsetY(titleOffset)
      Controls.WritingLine:SetHide(true)
      Controls.WritingQuote:SetHide(true)
      Controls.WritingAuthor:SetHide(true)
      Controls.WritingDeco:SetHide(false)
      Controls.WritingDeco:SetOffsetY(Controls.WritingName:GetSizeY() + -20)
    end
    Controls.WritingDetails:SetHide(false)
  elseif greatWorkObjectType == GREAT_WORK_ARTIFACT_TYPE or greatWorkObjectType == GREAT_WORK_RELIC_TYPE then
    if greatWorkObjectType == GREAT_WORK_ARTIFACT_TYPE then
      greatWorkType = greatWorkType:gsub("GREATWORK_ARTIFACT_", "")
      local greatWorkID = tonumber(greatWorkType)
      greatWorkID = ((greatWorkID - 1) % NUM_ARIFACT_TEXTURES) + 1
      Controls.GreatWorkImage:SetOffsetY(0)
      Controls.GreatWorkImage:SetTexture("ARTIFACT_" .. greatWorkID)
      Controls.GreatWorkName:SetText(Locale.ToUpper(Locale.Lookup(greatWorkInfo.Name)))
    elseif greatWorkObjectType == GREAT_WORK_RELIC_TYPE then
      greatWorkType = greatWorkType:gsub("GREATWORK_RELIC_", "")
      local greatWorkID = tonumber(greatWorkType)
      greatWorkID = ((greatWorkID - 1) % NUM_RELIC_TEXTURES) + 1
      Controls.GreatWorkImage:SetOffsetY(0)
      Controls.GreatWorkImage:SetTexture("RELIC_" .. greatWorkID)
    end
    Controls.GreatWorkName:SetText(Locale.ToUpper(Locale.Lookup(greatWorkInfo.Name)))
    local nameSize = Controls.GreatWorkName:GetSizeX() + PADDING_BANNER
    local bannerSize = math.max(nameSize, SIZE_BANNER_MIN)
    Controls.GreatWorkBanner:SetSizeX(bannerSize)
    Controls.GreatWorkBanner:SetHide(false)
  else
    local greatWorkTexture = greatWorkType:gsub("GREATWORK_", "")
    Controls.GreatWorkImage:SetOffsetY(-40)
    Controls.GreatWorkImage:SetTexture(greatWorkTexture)
    Controls.GreatWorkName:SetText(Locale.ToUpper(Locale.Lookup(greatWorkInfo.Name)))
    local nameSize = Controls.GreatWorkName:GetSizeX() + PADDING_BANNER
    local bannerSize = math.max(nameSize, SIZE_BANNER_MIN)
    Controls.GreatWorkBanner:SetSizeX(bannerSize)
    Controls.GreatWorkBanner:SetHide(false)

    local imageHeight = Controls.GreatWorkImage:GetSizeY()
    if imageHeight > SIZE_MAX_IMAGE_HEIGHT then heightAdjustment = SIZE_MAX_IMAGE_HEIGHT - imageHeight end
  end

  Controls.CreatedBy:SetText(Locale.Lookup("LOC_GREAT_WORKS_CREATED_BY", greatWorkCreator))
  Controls.CreatedDate:SetText(Locale.Lookup("LOC_GREAT_WORKS_CREATED_TIME", greatWorkTypeName, greatWorkCreationDate))
  Controls.CreatedPlace:SetText(Locale.Lookup("LOC_GREAT_WORKS_CREATED_PLACE", greatWorkCreationBuilding, greatWorkCreationCity))

  Controls.GreatWorkHeader:SetText(m_isGallery and "" or LOC_NEW_GREAT_WORK)
  Controls.ViewGreatWorks:SetText(m_isGallery and LOC_BACK_TO_GREAT_WORKS or LOC_VIEW_GREAT_WORKS)

  -- Ensure image is repositioned in case its size changed
  if not Controls.GreatWorkImage:IsHidden() then
    Controls.GreatWorkImage:ReprocessAnchoring()
    Controls.DetailsContainer:ReprocessAnchoring()
  end

  Controls.DetailsContainer:SetOffsetY(detailsOffset + heightAdjustment)
end

-- ===========================================================================
--	Update player data and refresh the display state
-- ===========================================================================
function UpdateData()
  UpdatePlayerData()
  if m_isGallery then UpdateGalleryData() end
  UpdateGreatWork()
end

-- ===========================================================================
--	Show / Hide
-- ===========================================================================
function ShowScreen()
  UpdateData()
  ContextPtr:SetHide(false)
end
function HideScreen()
  ContextPtr:SetHide(true)
  UI.PlaySound("Stop_Great_Music")
  UI.PlaySound("Stop_Speech_GreatWriting")
  UI.PlaySound("Stop_Great_Works_Gallery_Ambience")
end

-- ===========================================================================
--	Game Event Callbacks
-- ===========================================================================
function OnShowScreen() ShowScreen() end
function OnHideScreen() HideScreen() end
function OnViewGreatWorks()
  HideScreen()
  LuaEvents.GreatWorkCreated_OpenGreatWorksOverview()
end
function OnInputHandler(pInputStruct)
  local uiMsg = pInputStruct:GetMessageType()
  if uiMsg == KeyEvents.KeyUp and pInputStruct:GetKey() == Keys.VK_ESCAPE then
    HideScreen()
    return true
  end
  return false
end
function OnGreatWorkCreated(playerID, creatorID, cityX, cityY, buildingID, greatWorkIndex)
  -- Ignore relics when responding to the GreatWorkCreated event.  Relics have a dedicated notification that will trigger this screen
  -- Thru NotificationPanel_ShowRelicCreated
  -- CUI
  if CuiSettings:GetBoolean(CuiSettings.POPUP_CREATWORK) then
    DisplayGreatWorkCreated(playerID, creatorID, cityX, cityY, buildingID, greatWorkIndex, false)
  end
end
function OnShowRelicCreated(playerID, creatorID, cityX, cityY, buildingID, greatWorkIndex)
  -- CUI
  if CuiSettings:GetBoolean(CuiSettings.POPUP_RELIC) then
    DisplayGreatWorkCreated(playerID, creatorID, cityX, cityY, buildingID, greatWorkIndex, true)
  end
end
function DisplayGreatWorkCreated(playerID, creatorID, cityX, cityY, buildingID, greatWorkIndex, showRelics)
  if playerID ~= Game.GetLocalPlayer() then return end
  m_isGallery = false
  m_BuildingID = buildingID
  m_GreatWorkIndex = greatWorkIndex
  m_City = Cities.GetCityInPlot(Map.GetPlotIndex(cityX, cityY))
  if m_City ~= nil then
    m_CityBldgs = m_City:GetBuildings()
    m_GreatWorkType = m_CityBldgs:GetGreatWorkTypeFromIndex(m_GreatWorkIndex)

    if (not showRelics and m_GreatWorkType == GREAT_WORK_RELIC_TYPE) then
      -- Ignore relics if showRelics is false.
      return
    end

    ShowScreen()
  end
end
function OnViewGreatWork(city, buildingID, greatWorkIndex)

  m_isGallery = true
  m_BuildingID = buildingID
  m_GreatWorkIndex = greatWorkIndex
  m_City = city
  if m_City ~= nil then
    m_CityBldgs = m_City:GetBuildings()
    m_GreatWorkType = m_CityBldgs:GetGreatWorkTypeFromIndex(m_GreatWorkIndex)
    ShowScreen()
  end
end
function OnPreviousGreatWork()
  local numGreatWorks = table.count(m_GreatWorks)
  if numGreatWorks > 1 then

    UI.PlaySound("Stop_Great_Music")
    UI.PlaySound("Stop_Speech_GreatWriting")
    UI.PlaySound("UI_Click_Sweetener_Metal_Button_Small")

    m_GalleryIndex = m_GalleryIndex - 1
    if m_GalleryIndex <= 0 then m_GalleryIndex = numGreatWorks end
    local greatWorkData = m_GreatWorks[m_GalleryIndex]
    OnViewGreatWork(greatWorkData.City, greatWorkData.Building, greatWorkData.Index)
  end
end
function OnNextGreatWork()
  local numGreatWorks = table.count(m_GreatWorks)
  if numGreatWorks > 1 then

    UI.PlaySound("Stop_Great_Music")
    UI.PlaySound("Stop_Speech_GreatWriting")
    UI.PlaySound("UI_Click_Sweetener_Metal_Button_Small")

    m_GalleryIndex = m_GalleryIndex + 1
    if m_GalleryIndex > numGreatWorks then m_GalleryIndex = 1 end

    local greatWorkData = m_GreatWorks[m_GalleryIndex]
    OnViewGreatWork(greatWorkData.City, greatWorkData.Building, greatWorkData.Index)
  end
end

-- ===========================================================================
--	Hot Reload Related Events
-- ===========================================================================
function OnInit(isReload) if isReload then LuaEvents.GameDebug_GetValues(RELOAD_CACHE_ID) end end
function OnShutdown()
  LuaEvents.GameDebug_AddValue(RELOAD_CACHE_ID, "isHidden", ContextPtr:IsHidden())
  LuaEvents.GameDebug_AddValue(RELOAD_CACHE_ID, "isGallery", m_isGallery)
  LuaEvents.GameDebug_AddValue(RELOAD_CACHE_ID, "playerID", Game.GetLocalPlayer())
  LuaEvents.GameDebug_AddValue(RELOAD_CACHE_ID, "cityX", m_City ~= nil and m_City:GetX() or -1)
  LuaEvents.GameDebug_AddValue(RELOAD_CACHE_ID, "cityY", m_City ~= nil and m_City:GetY() or -1)
  LuaEvents.GameDebug_AddValue(RELOAD_CACHE_ID, "buildingID", m_BuildingID)
  LuaEvents.GameDebug_AddValue(RELOAD_CACHE_ID, "greatWorkIndex", m_GreatWorkIndex)
end
function OnGameDebugReturn(context, data)
  if context == RELOAD_CACHE_ID and data["isHidden"] ~= nil and not data["isHidden"] then
    if data["isGallery"] then
      OnViewGreatWork(Cities.GetCityInPlot(Map.GetPlotIndex(data["cityX"], data["cityY"])), data["buildingID"], data["greatWorkIndex"])
    else
      OnGreatWorkCreated(data["playerID"], nil, data["cityX"], data["cityY"], data["buildingID"], data["greatWorkIndex"])
    end
  end
end

-- ===========================================================================
--	Hot-seat functionality
-- ===========================================================================
function OnLocalPlayerTurnEnd()
  if (GameConfiguration.IsHotseat()) then
    HideScreen()
    m_GreatWorks = {}
    m_GreatWorkIndex = -1
    Controls.PreviousGreatWork:SetHide(true)
    Controls.NextGreatWork:SetHide(true)
  end
end

-- ===========================================================================
--	INIT
-- ===========================================================================
function Initialize()

  ContextPtr:SetInitHandler(OnInit)
  ContextPtr:SetShutdown(OnShutdown)
  ContextPtr:SetInputHandler(OnInputHandler, true)

  Events.GreatWorkCreated.Add(OnGreatWorkCreated)
  Events.LocalPlayerTurnEnd.Add(OnLocalPlayerTurnEnd)
  LuaEvents.GameDebug_Return.Add(OnGameDebugReturn)
  LuaEvents.LaunchBar_OpenGreatWorksShowcase(OnShowScreen)
  LuaEvents.GreatWorksOverview_ViewGreatWork.Add(OnViewGreatWork)
  LuaEvents.NotificationPanel_ShowRelicCreated.Add(OnShowRelicCreated)

  Controls.ModalBG:SetTexture("GreatWorks_Background")
  Controls.ModalScreenClose:RegisterCallback(Mouse.eLClick, OnHideScreen)
  Controls.ModalScreenClose:RegisterCallback(Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over") end)
  Controls.ModalScreenClose:ChangeParent(Controls.BannerBG)
  Controls.ModalScreenClose:SetAnchor("R,T")
  Controls.ModalScreenClose:SetOffsetX(-5)

  Controls.NextGreatWork:RegisterCallback(Mouse.eLClick, OnNextGreatWork)
  Controls.PreviousGreatWork:RegisterCallback(Mouse.eLClick, OnPreviousGreatWork)
  Controls.ViewGreatWorks:RegisterCallback(Mouse.eLClick, OnViewGreatWorks)
  Controls.ViewGreatWorks:RegisterCallback(Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over") end)
end
Initialize()
