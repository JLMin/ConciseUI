-- Copyright 2018-2019, Firaxis Games

include("InstanceManager");
include("PopupDialog")
include("GameCapabilities");
include("GreatWorksSupport");

include("ModalScreen_PlayerYieldsHelper"); -- Concise UI
include("cui_settings"); -- Concise UI

-- ===========================================================================
--	CONSTANTS
-- ===========================================================================
local RELOAD_CACHE_ID:string = "GreatWorksOverview"; -- Must be unique (usually the same as the file name)

local SIZE_SLOT_TYPE_ICON:number = 40;
local SIZE_GREAT_WORK_ICON:number = 64;
local PADDING_PROVIDING_LABEL:number = 10;
local MIN_PADDING_SLOTS:number = 2;
local MAX_PADDING_SLOTS:number = 30;
local MAX_NUM_SLOTS:number = 6;
local DEFAULT_LOCK_TURNS:number = 10;

local NUM_RELIC_TEXTURES:number = 48;
local NUM_ARIFACT_TEXTURES:number = 25;
local GREAT_WORK_RELIC_TYPE:string = "GREATWORKOBJECT_RELIC";
local GREAT_WORK_ARTIFACT_TYPE:string = "GREATWORKOBJECT_ARTIFACT";

local LOC_TOURISM:string = Locale.Lookup("LOC_GREAT_WORKS_TOURISM");
local LOC_THEME_BONUS:string = Locale.Lookup("LOC_GREAT_WORKS_THEMED_BONUS");
local LOC_SCREEN_TITLE:string = Locale.Lookup("LOC_GREAT_WORKS_SCREEN_TITLE");

local DATA_FIELD_SLOT_CACHE:string = "SlotCache";
local DATA_FIELD_GREAT_WORK_IM:string = "GreatWorkIM";
local DATA_FIELD_TOURISM_YIELD:string = "TourismYield";
local DATA_FIELD_THEME_BONUS_IM:string = "ThemeBonusIM";

local DATA_FIELD_CITY_ID			:string = "DataField_CityID";
local DATA_FIELD_BUILDING_ID		:string = "DataField_BuildingID";
local DATA_FIELD_GREAT_WORK_INDEX	:string = "DataField_GreatWorkIndex";
local DATA_FIELD_SLOT_INDEX			:string = "DataField_SlotIndex";
local DATA_FIELD_GREAT_WORK_TYPE	:string = "DataField_GreatWorkType";

local YIELD_FONT_ICONS:table = {
	YIELD_FOOD				= "[ICON_FoodLarge]",
	YIELD_PRODUCTION		= "[ICON_ProductionLarge]",
	YIELD_GOLD				= "[ICON_GoldLarge]",
	YIELD_SCIENCE			= "[ICON_ScienceLarge]",
	YIELD_CULTURE			= "[ICON_CultureLarge]",
	YIELD_FAITH				= "[ICON_FaithLarge]",
	TourismYield			= "[ICON_TourismLarge]"
};

local DEFAULT_GREAT_WORKS_ICONS:table = {
	GREATWORKSLOT_WRITING	= "ICON_GREATWORKOBJECT_WRITING",
	GREATWORKSLOT_PALACE	= "ICON_GREATWORKOBJECT_SCULPTURE",
	GREATWORKSLOT_ART		= "ICON_GREATWORKOBJECT_PORTRAIT",
	GREATWORKSLOT_CATHEDRAL	= "ICON_GREATWORKOBJECT_RELIGIOUS",
	GREATWORKSLOT_ARTIFACT	= "ICON_GREATWORKOBJECT_ARTIFACT_ERA_ANCIENT",
	GREATWORKSLOT_MUSIC		= "ICON_GREATWORKOBJECT_MUSIC",
	GREATWORKSLOT_RELIC		= "ICON_GREATWORKOBJECT_RELIC"
};

-- ===========================================================================
--	SCREEN VARIABLES
-- ===========================================================================
local m_FirstGreatWork:table = nil;
local m_GreatWorkYields:table = nil;
local m_GreatWorkSelected:table = nil;
local m_GreatWorkBuildings:table = nil;
local m_GreatWorkSlotsIM:table = InstanceManager:new("GreatWorkSlot", "TopControl", Controls.GreatWorksStack);
local m_TotalResourcesIM:table = InstanceManager:new("AgregateResource", "Resource", Controls.TotalResources);

local m_kViableDropTargets:table = {};
local m_kControlToInstanceMap:table = {};
local m_uiSelectedDropTarget:table = nil;

local m_TopPanelConsideredHeight = 0; -- Concise UI

-- ===========================================================================
--	PLAYER VARIABLES
-- ===========================================================================
local m_LocalPlayer:table;
local m_LocalPlayerID:number;

local m_during_move:boolean = false;
local m_dest_building:number = 0;
local m_dest_city;
local m_isLocalPlayerTurn:boolean = true;

local cui_ThemeHelper = false; -- Concise UI

-- ===========================================================================
--	Called every time screen is shown
-- ===========================================================================
function UpdatePlayerData()
	m_LocalPlayerID = Game.GetLocalPlayer();
	if m_LocalPlayerID ~= -1 then
		m_LocalPlayer = Players[m_LocalPlayerID];
	end
end

-- ===========================================================================
--	Called every time screen is shown
-- ===========================================================================
function UpdateGreatWorks()

	m_FirstGreatWork = nil;
	m_GreatWorkSelected = nil;
	m_GreatWorkSlotsIM:ResetInstances();
	Controls.PlacingContainer:SetHide(true);
	Controls.HeaderStatsContainer:SetHide(false);

	if (m_LocalPlayer == nil) then
		return;
	end

	m_GreatWorkYields = {};
	m_GreatWorkBuildings = {};
	local numGreatWorks:number = 0;
    local numDisplaySpaces:number = 0;

    local cui_tmpBuildings = {}; -- Concise UI

	local pCities:table = m_LocalPlayer:GetCities();
	for i, pCity in pCities:Members() do
		if pCity ~= nil and pCity:GetOwner() == m_LocalPlayerID then
			local pCityBldgs:table = pCity:GetBuildings();
			for buildingInfo in GameInfo.Buildings() do
				local buildingIndex:number = buildingInfo.Index;
				local buildingType:string = buildingInfo.BuildingType;
				if(pCityBldgs:HasBuilding(buildingIndex)) then
					local numSlots:number = pCityBldgs:GetNumGreatWorkSlots(buildingIndex);
                    if (numSlots ~= nil and numSlots > 0) then
                        --[[
						local instance:table = m_GreatWorkSlotsIM:GetInstance();
						local greatWorks:number = PopulateGreatWorkSlot(instance, pCity, pCityBldgs, buildingInfo);
						table.insert(m_GreatWorkBuildings, {Instance=instance, Type=buildingType, Index=buildingIndex, CityBldgs=pCityBldgs});
						numDisplaySpaces = numDisplaySpaces + pCityBldgs:GetNumGreatWorkSlots(buildingIndex);
                        numGreatWorks = numGreatWorks + greatWorks;
                        ]]

                        -- Concise UI >> sort
                        table.insert(
                            cui_tmpBuildings,
                            {
                                Type = buildingType,
                                Index = buildingIndex,
                                CityBldgs = pCityBldgs,
                                City = pCity,
                                Info = buildingInfo
                            }
                        )
                        -- << Concise UI
					end
				end
			end
		end
	end

    -- Concise UI >> sort
    local IsSortByCity = CuiSettings:GetBoolean(CuiSettings.SORT_BY_CITY)
    if not IsSortByCity then
        table.sort(
            cui_tmpBuildings,
            function(a, b)
                if a.Index == b.Index then
                    return a.City:GetID() < b.City:GetID();
                else
                    return a.Index < b.Index;
                end
            end
        );
    end
    for _, item in ipairs(cui_tmpBuildings) do
        local instance = m_GreatWorkSlotsIM:GetInstance();
        local greatWorks = PopulateGreatWorkSlot(instance, item.City, item.CityBldgs, item.Info);
        table.insert(
            m_GreatWorkBuildings,
            {Instance = instance, Type = item.Type, Index = item.Index, CityBldgs = item.CityBldgs}
        )
        numDisplaySpaces = numDisplaySpaces + item.CityBldgs:GetNumGreatWorkSlots(item.Index);
        numGreatWorks = numGreatWorks + greatWorks;
    end
    -- << Concise UI
	Controls.NumGreatWorks:SetText(numGreatWorks);
	Controls.NumDisplaySpaces:SetText(numDisplaySpaces);

	-- Realize stack and scrollbar
	Controls.GreatWorksStack:CalculateSize();
	Controls.GreatWorksStack:ReprocessAnchoring();
	Controls.GreatWorksScrollPanel:CalculateInternalSize();
	Controls.GreatWorksScrollPanel:ReprocessAnchoring();

	m_TotalResourcesIM:ResetInstances();

	if table.count(m_GreatWorkYields) > 0 then
		table.sort(m_GreatWorkYields, function(a,b) return a.Name < b.Name; end);

		for _, data in ipairs(m_GreatWorkYields) do
			local instance:table = m_TotalResourcesIM:GetInstance();
			instance.Resource:SetText(data.Icon .. data.Value);
			instance.Resource:SetToolTipString(data.Name);
		end

		Controls.TotalResources:CalculateSize();
		Controls.TotalResources:ReprocessAnchoring();
		Controls.ProvidingLabel:SetOffsetX(Controls.TotalResources:GetOffsetX() + Controls.TotalResources:GetSizeX() + PADDING_PROVIDING_LABEL);
		Controls.ProvidingLabel:SetHide(false);
	else
		Controls.ProvidingLabel:SetHide(true);
	end

	-- Hide "View Gallery" button if we don't have a single great work
    Controls.ViewGallery:SetHide(m_FirstGreatWork == nil);

    -- Concise UI >>
    Controls.SortGreatWork:SetHide(m_FirstGreatWork == nil);
    Controls.ThemeHelper:SetHide(m_FirstGreatWork == nil);
    -- << Concise UI
end

function PopulateGreatWorkSlot(instance:table, pCity:table, pCityBldgs:table, pBuildingInfo:table)

	instance.DefaultBG:SetHide(false);
	instance.DisabledBG:SetHide(true);
    instance.HighlightedBG:SetHide(true);

    -- Concise UI >> reset Theme label
    instance.ThemingLabel:SetText("");
    instance.ThemingLabel:SetToolTipString("");
    -- << Concise UI

	local buildingType:string = pBuildingInfo.BuildingType;
	local buildingIndex:number = pBuildingInfo.Index;
	local themeDescription = GetThemeDescription(buildingType);
	instance.CityName:SetText(Locale.Lookup(pCity:GetName()));
	instance.BuildingName:SetText(Locale.ToUpper(Locale.Lookup(pBuildingInfo.Name)));

	-- Ensure we have Instance Managers for the great works
	local greatWorkIM:table = instance[DATA_FIELD_GREAT_WORK_IM];
	if(greatWorkIM == nil) then
		greatWorkIM = InstanceManager:new("GreatWork", "TopControl", instance.GreatWorks);
		instance[DATA_FIELD_GREAT_WORK_IM] = greatWorkIM;
	else
		greatWorkIM:ResetInstances();
	end

	local index:number = 0;
	local numGreatWorks:number = 0;
	local numThemedGreatWorks:number = 0;
	local instanceCache:table = {};
	local firstGreatWork:table = nil;
	local numSlots:number = pCityBldgs:GetNumGreatWorkSlots(buildingIndex);

	if (numSlots ~= nil and numSlots > 0) then
		for _:number=0, numSlots - 1 do
			local instance:table = greatWorkIM:GetInstance();
			local greatWorkIndex:number = pCityBldgs:GetGreatWorkInSlot(buildingIndex, index);
			local greatWorkSlotType:number = pCityBldgs:GetGreatWorkSlotType(buildingIndex, index);
			local greatWorkSlotString:string = GameInfo.GreatWorkSlotTypes[greatWorkSlotType].GreatWorkSlotType;

			PopulateGreatWork(instance, pCityBldgs, pBuildingInfo, index, greatWorkIndex, greatWorkSlotString);
			index = index + 1;
			instanceCache[index] = instance;
			if greatWorkIndex ~= -1 then
				numGreatWorks = numGreatWorks + 1;
				local greatWorkType:number = pCityBldgs:GetGreatWorkTypeFromIndex(greatWorkIndex);
				local greatWorkInfo:table = GameInfo.GreatWorks[greatWorkType];
				if firstGreatWork == nil then
					firstGreatWork = greatWorkInfo;
				end
				if greatWorkInfo ~= nil and GreatWorkFitsTheme(pCityBldgs, pBuildingInfo, greatWorkIndex, greatWorkInfo) then
					numThemedGreatWorks = numThemedGreatWorks + 1;
				end
			end
		end

		if firstGreatWork ~= nil and themeDescription ~= nil then
			local slotTypeIcon:string = "ICON_" .. firstGreatWork.GreatWorkObjectType;
			if firstGreatWork.GreatWorkObjectType == GREAT_WORK_ARTIFACT_TYPE then
				slotTypeIcon = slotTypeIcon .. "_" .. firstGreatWork.EraType;
			end

			local textureOffsetX:number, textureOffsetY:number, textureSheet:string = IconManager:FindIconAtlas(slotTypeIcon, SIZE_SLOT_TYPE_ICON);
			if(textureSheet == nil or textureSheet == "") then
				UI.DataError("Could not find slot type icon in PopulateGreatWorkSlot: icon=\""..slotTypeIcon.."\", iconSize="..tostring(SIZE_SLOT_TYPE_ICON));
			else
				for i:number=0, numSlots - 1 do
					local slotIndex:number = index - i;
					instanceCache[slotIndex].SlotTypeIcon:SetTexture(textureOffsetX, textureOffsetY, textureSheet);
				end
			end
		end
	end

	instance[DATA_FIELD_SLOT_CACHE] = instanceCache;

	local numSlots:number = table.count(instanceCache);
	if(numSlots > 1) then
		local slotRange:number = MAX_NUM_SLOTS - 2;
		local paddingRange:number = MAX_PADDING_SLOTS - MIN_PADDING_SLOTS;
		local finalPadding:number = ((MAX_NUM_SLOTS - numSlots) * paddingRange / slotRange) + MIN_PADDING_SLOTS;
		instance.GreatWorks:SetStackPadding(finalPadding);
	else
		instance.GreatWorks:SetStackPadding(0);
	end

	-- Ensure we have Instance Managers for the theme bonuses
	local themeBonusIM:table = instance[DATA_FIELD_THEME_BONUS_IM];
	if(themeBonusIM == nil) then
		themeBonusIM = InstanceManager:new("Resource", "Resource", instance.ThemeBonuses);
		instance[DATA_FIELD_THEME_BONUS_IM] = themeBonusIM;
	else
		themeBonusIM:ResetInstances();
	end

	if numGreatWorks == 0 then
		if themeDescription ~= nil then
			instance.ThemingLabel:SetText(Locale.Lookup("LOC_GREAT_WORKS_THEME_BONUS_PROGRESS", numThemedGreatWorks, numSlots));
			instance.ThemingLabel:SetToolTipString(themeDescription);
		end
	else
		instance.ThemingLabel:SetText("");
		instance.ThemingLabel:SetToolTipString("");
		if pCityBldgs:IsBuildingThemedCorrectly(buildingIndex) then
			instance.ThemingLabel:SetText(LOC_THEME_BONUS);
			if m_during_move then
				if buildingIndex == m_dest_building then
                    if (m_dest_city == pCityBldgs:GetCity():GetID()) then
                        UI.PlaySound("UI_GREAT_WORKS_BONUS_ACHIEVED");
                    end
				end
			end
		else
			if themeDescription ~= nil then
                -- if we're being called due to moving a work
				if numSlots > 1 then
					instance.ThemingLabel:SetText(Locale.Lookup("LOC_GREAT_WORKS_THEME_BONUS_PROGRESS", numThemedGreatWorks, numSlots));
					if m_during_move then
						if buildingIndex == m_dest_building then
                            if (m_dest_city == pCityBldgs:GetCity():GetID()) then
                                if numThemedGreatWorks == 2 then
                                    UI.PlaySound("UI_GreatWorks_Bonus_Increased");
                                end
                            end
						end
					end
				end

				if instance.ThemingLabel:GetText() ~= "" then
					instance.ThemingLabel:SetToolTipString(themeDescription);
				end
			end
		end
	end

	for row in GameInfo.Yields() do
		local yieldValue:number = pCityBldgs:GetBuildingYieldFromGreatWorks(row.Index, buildingIndex);
		if yieldValue > 0 then
			AddYield(themeBonusIM:GetInstance(), Locale.Lookup(row.Name), YIELD_FONT_ICONS[row.YieldType], yieldValue);
		end
	end

	local regularTourism:number = pCityBldgs:GetBuildingTourismFromGreatWorks(false, buildingIndex);
	local religionTourism:number = pCityBldgs:GetBuildingTourismFromGreatWorks(true, buildingIndex);
	local totalTourism:number = regularTourism + religionTourism;

	if totalTourism > 0 then
		AddYield(themeBonusIM:GetInstance(), LOC_TOURISM, YIELD_FONT_ICONS[DATA_FIELD_TOURISM_YIELD], totalTourism);
	end

	instance.ThemeBonuses:CalculateSize();
	instance.ThemeBonuses:ReprocessAnchoring();

	return numGreatWorks;
end

-- IMPORTANT: This logic is largely derived from GetGreatWorkTooltip() - if you make an update here, make sure to update that function as well
function GreatWorkFitsTheme(pCityBldgs:table, pBuildingInfo:table, greatWorkIndex:number, greatWorkInfo:table)
	local firstGreatWork:number = GetFirstGreatWorkInBuilding(pCityBldgs, pBuildingInfo);
	if firstGreatWork < 0 then
		return false;
	end

	local firstGreatWorkObjectTypeID:number = pCityBldgs:GetGreatWorkTypeFromIndex(firstGreatWork);
	local firstGreatWorkObjectType:string = GameInfo.GreatWorks[firstGreatWorkObjectTypeID].GreatWorkObjectType;

	if pCityBldgs:IsBuildingThemedCorrectly(GameInfo.Buildings[pBuildingInfo.BuildingType].Index) then
		return true;
	else
		if pBuildingInfo.BuildingType == "BUILDING_MUSEUM_ART" then

			if firstGreatWork == greatWorkIndex then
				return true;
			elseif not IsFirstGreatWorkByArtist(greatWorkIndex, pCityBldgs, pBuildingInfo) then
				return false;
			else
				return firstGreatWorkObjectType == greatWorkInfo.GreatWorkObjectType;
			end
		elseif pBuildingInfo.BuildingType == "BUILDING_MUSEUM_ARTIFACT" then

			if firstGreatWork == greatWorkIndex then
				return true;
			else
				if greatWorkInfo.EraType ~= GameInfo.GreatWorks[firstGreatWorkObjectTypeID].EraType then
					return false;
				else
					local greatWorkPlayer:number = Game.GetGreatWorkPlayer(greatWorkIndex);
					local greatWorks:table = GetGreatWorksInBuilding(pCityBldgs, pBuildingInfo);

					-- Find duplicates for theming description
					local hash:table = {}
					local duplicates:table = {}
					for _,index in ipairs(greatWorks) do
						local gwPlayer:number = Game.GetGreatWorkPlayer(index);
						if (not hash[gwPlayer]) then
							hash[gwPlayer] = true;
						else
							table.insert(duplicates, gwPlayer);
						end
					end

					return table.count(duplicates) == 0;
				end
			end
		end
	end
end

function GetGreatWorkIcon(greatWorkInfo:table)

	local greatWorkIcon:string;

	if greatWorkInfo.GreatWorkObjectType == GREAT_WORK_ARTIFACT_TYPE then
		local greatWorkType:string = greatWorkInfo.GreatWorkType;
		greatWorkType = greatWorkType:gsub("GREATWORK_ARTIFACT_", "");
		local greatWorkID:number = tonumber(greatWorkType);
		greatWorkID = ((greatWorkID - 1) % NUM_ARIFACT_TEXTURES) + 1;
		greatWorkIcon = "ICON_GREATWORK_ARTIFACT_" .. greatWorkID;
	elseif greatWorkInfo.GreatWorkObjectType == GREAT_WORK_RELIC_TYPE then
		local greatWorkType:string = greatWorkInfo.GreatWorkType;
		greatWorkType = greatWorkType:gsub("GREATWORK_RELIC_", "");
		local greatWorkID:number = tonumber(greatWorkType);
		greatWorkID =  ((greatWorkID - 1) % NUM_RELIC_TEXTURES) + 1;
		greatWorkIcon = "ICON_GREATWORK_RELIC_" .. greatWorkID;
	else
		greatWorkIcon = "ICON_" .. greatWorkInfo.GreatWorkType;
	end

	local textureOffsetX:number, textureOffsetY:number, textureSheet:string = IconManager:FindIconAtlas(greatWorkIcon, SIZE_GREAT_WORK_ICON);
	if(textureSheet == nil or textureSheet == "") then
		UI.DataError("Could not find slot type icon in GetGreatWorkIcon: icon=\""..greatWorkIcon.."\", iconSize="..tostring(SIZE_GREAT_WORK_ICON));
	end

	return textureOffsetX, textureOffsetY, textureSheet;
end

function GetThemeDescription(buildingType:string)
    local eBuilding = m_LocalPlayer:GetCulture():GetAutoThemedBuilding();
	if (GameInfo.Buildings[buildingType].Index == eBuilding) then
		return Locale.Lookup("LOC_BUILDING_THEMINGBONUS_FULL_MUSEUM");
	else
		for row in GameInfo.Building_GreatWorks() do
			if row.BuildingType == buildingType then
				if row.ThemingBonusDescription ~= nil then
					return Locale.Lookup(row.ThemingBonusDescription);
				end
			end
		end
	end
	return nil;
end

function PopulateGreatWork(instance:table, pCityBldgs:table, pBuildingInfo:table, slotIndex:number, greatWorkIndex:number, slotType:string)

	local buildingIndex:number = pBuildingInfo.Index;
	local slotTypeIcon:string = DEFAULT_GREAT_WORKS_ICONS[slotType];

	local textureOffsetX:number, textureOffsetY:number, textureSheet:string = IconManager:FindIconAtlas(slotTypeIcon, SIZE_SLOT_TYPE_ICON);
	if(textureSheet == nil or textureSheet == "") then
		UI.DataError("Could not find slot type icon in PopulateGreatWork: icon=\""..slotTypeIcon.."\", iconSize="..tostring(SIZE_SLOT_TYPE_ICON));
	else
		instance.SlotTypeIcon:SetTexture(textureOffsetX, textureOffsetY, textureSheet);
	end

    -- Concise UI >> reset masks
    instance.LockIcon:SetHide(true);
    instance.LockMask:SetHide(true);
    instance.ThemeMask:SetHide(true);
    -- << Concise UI

	instance[DATA_FIELD_CITY_ID] = pCityBldgs:GetCity():GetID();
	instance[DATA_FIELD_BUILDING_ID] = buildingIndex;
	instance[DATA_FIELD_SLOT_INDEX]	= slotIndex;
	instance[DATA_FIELD_GREAT_WORK_INDEX] = greatWorkIndex;
	instance[DATA_FIELD_GREAT_WORK_TYPE] = -1;

	if greatWorkIndex == -1 then
		instance.GreatWorkIcon:SetHide(true);

		local validWorks:string = "";
		for row in GameInfo.GreatWork_ValidSubTypes() do
			if slotType == row.GreatWorkSlotType then
				if validWorks ~= "" then
					validWorks = validWorks .. "[NEWLINE]";
				end
				validWorks = validWorks .. Locale.Lookup("LOC_" .. row.GreatWorkObjectType);
			end
		end

		instance.EmptySlot:ClearCallback(Mouse.eLClick);
		instance.EmptySlot:SetToolTipString(Locale.Lookup("LOC_GREAT_WORKS_EMPTY_TOOLTIP", validWorks));
	else
		instance.GreatWorkIcon:SetHide(false);

		local srcGreatWork:number = pCityBldgs:GetGreatWorkInSlot(buildingIndex, slotIndex);
		local srcGreatWorkType:number = pCityBldgs:GetGreatWorkTypeFromIndex(srcGreatWork);
		local srcGreatWorkObjectType:string = GameInfo.GreatWorks[srcGreatWorkType].GreatWorkObjectType;

		instance[DATA_FIELD_GREAT_WORK_TYPE] = srcGreatWorkType;

		local greatWorkType:number = pCityBldgs:GetGreatWorkTypeFromIndex(greatWorkIndex);
		local textureOffsetX:number, textureOffsetY:number, textureSheet:string = GetGreatWorkIcon(GameInfo.GreatWorks[greatWorkType]);
		instance.GreatWorkIcon:SetTexture(textureOffsetX, textureOffsetY, textureSheet);

		instance.EmptySlot:SetToolTipString(GetGreatWorkTooltip(pCityBldgs, greatWorkIndex, greatWorkType, pBuildingInfo));

		local bAllowMove:boolean = true;

		-- Don't allow moving artifacts if the museum is not full
		if bAllowMove and srcGreatWorkObjectType == GREAT_WORK_ARTIFACT_TYPE then
			if not IsBuildingFull(pCityBldgs, buildingIndex) then
				instance.GreatWorkDraggable:RegisterCallback(Drag.eDragDisabled, function() ShowCannotMoveMessage(Locale.Lookup("LOC_GREAT_WORKS_ARTIFACT_LOCKED_FROM_MOVE")); end);
				bAllowMove = false;
			end
		end

		-- Don't allow moving art that has been recently created
		if bAllowMove and srcGreatWorkObjectType == "GREATWORKOBJECT_SCULPTURE" or
			srcGreatWorkObjectType == "GREATWORKOBJECT_LANDSCAPE" or
			srcGreatWorkObjectType == "GREATWORKOBJECT_PORTRAIT" or
			srcGreatWorkObjectType == "GREATWORKOBJECT_RELIGIOUS" then

			local iTurnCreated:number = pCityBldgs:GetTurnFromIndex(greatWorkIndex);
			local iCurrentTurn:number = Game.GetCurrentGameTurn();
			local iTurnsBeforeMove:number = GlobalParameters.GREATWORK_ART_LOCK_TIME or DEFAULT_LOCK_TURNS;
			local iTurnsToWait = iTurnCreated + iTurnsBeforeMove - iCurrentTurn;
			if iTurnsToWait > 0 then
				instance.GreatWorkDraggable:RegisterCallback(Drag.eDragDisabled, function() ShowCannotMoveMessage(Locale.Lookup("LOC_GREAT_WORKS_LOCKED_FROM_MOVE", iTurnsToWait)); end);
				bAllowMove = false;
			end
		end

		if bAllowMove then
			instance.GreatWorkDraggable:SetDisabled(false);
			instance.GreatWorkDraggable:RegisterCallback(Drag.eDown, function(kDragStruct) OnClickGreatWork( kDragStruct,pCityBldgs, buildingIndex, greatWorkIndex, slotIndex ); end);
			instance.GreatWorkDraggable:RegisterCallback(Drag.eDrop, function(kDragStruct) OnGreatWorkDrop( kDragStruct, instance ); end);
			instance.GreatWorkDraggable:RegisterCallback(Drag.eDrag, function(kDragStruct) OnGreatWorkDrag( kDragStruct, instance ); end);
		else
			instance.GreatWorkDraggable:SetDisabled(true);
		end

		if m_FirstGreatWork == nil then
			m_FirstGreatWork = {Index=greatWorkIndex, Building=buildingIndex, CityBldgs=pCityBldgs};
		end
	end
	instance.EmptySlotHighlight:SetHide(true);
end

-- ===========================================================================
function OnGreatWorkDrop( kDragStruct:table, kInstance:table )
	if m_uiSelectedDropTarget ~= nil then
		if m_uiSelectedDropTarget == Controls.ViewGreatWork then
			OnViewGreatWork()
		else
			local kSelectedDropInstance = m_kControlToInstanceMap[m_uiSelectedDropTarget];
			if kSelectedDropInstance then
				MoveGreatWork(kInstance, kSelectedDropInstance);
			end
		end
	end
	ClearGreatWorkTransfer();
end

-- ===========================================================================
function OnGreatWorkDrag( kDragStruct:table, kInstance:table )
	local uiDragControl:table = kDragStruct:GetControl();
	local uiBestDropTarget = uiDragControl:GetBestOverlappingControl( m_kViableDropTargets );

	if uiBestDropTarget then
		HighlightDropTarget(uiBestDropTarget);
		m_uiSelectedDropTarget = uiBestDropTarget;
	else
		HighlightDropTarget();
		m_uiSelectedDropTarget = nil;
	end
end

-- ===========================================================================
function HighlightDropTarget( uiBestDropTarget:table )
	for _,uiDropTarget in ipairs(m_kViableDropTargets) do
		if uiDropTarget == Controls.ViewGreatWork then
			Controls.ViewGreatWork:SetSelected(uiBestDropTarget == Controls.ViewGreatWork);
		else
			local pDropInstance = m_kControlToInstanceMap[uiDropTarget];
			if pDropInstance ~= nil then
				pDropInstance.EmptySlotHighlight:SetHide(uiDropTarget ~= uiBestDropTarget);
			end
		end
	end
end

-- IMPORTANT: This logic is largely duplicated in GreatWorkFitsTheme() - if you make an update here, make sure to update that function as well
function GetGreatWorkTooltip(pCityBldgs:table, greatWorkIndex:number, greatWorkType:number, pBuildingInfo:table)
	local greatWorkTypeName:string;
	local greatWorkInfo:table = GameInfo.GreatWorks[greatWorkType];
	local greatWorkCreator:string = Locale.Lookup(pCityBldgs:GetCreatorNameFromIndex(greatWorkIndex));

	local bIsThemeable :boolean = GetThemeDescription(pBuildingInfo.BuildingType) ~= nil;
	local strBasicTooltip :string = GreatWorksSupport_GetBasicTooltip( greatWorkIndex, bIsThemeable );

	local buildingName:string = Locale.Lookup(GameInfo.Buildings[pBuildingInfo.BuildingType].Name);

	if greatWorkInfo.EraType ~= nil then
		greatWorkTypeName = Locale.Lookup("LOC_" .. greatWorkInfo.GreatWorkObjectType .. "_" .. greatWorkInfo.EraType);
	else
		greatWorkTypeName = Locale.Lookup("LOC_" .. greatWorkInfo.GreatWorkObjectType);
	end

	if bIsThemeable then
		local strThemeTooltip :string;
		local firstGreatWork:number = GetFirstGreatWorkInBuilding(pCityBldgs, pBuildingInfo);
		if firstGreatWork < 0 then
			return strBasicTooltip;
		end

		local firstGreatWorkObjectTypeID:number = pCityBldgs:GetGreatWorkTypeFromIndex(firstGreatWork);
		local firstGreatWorkObjectType:string = GameInfo.GreatWorks[firstGreatWorkObjectTypeID].GreatWorkObjectType;

		if pCityBldgs:IsBuildingThemedCorrectly(GameInfo.Buildings[pBuildingInfo.BuildingType].Index) then
			strThemeTooltip = Locale.Lookup("LOC_GREAT_WORKS_ART_MATCHED_THEME", buildingName);
		else
			if pBuildingInfo.BuildingType == "BUILDING_MUSEUM_ART" then

				if firstGreatWork == greatWorkIndex then
					strThemeTooltip = Locale.Lookup("LOC_GREAT_WORKS_ART_THEME_SINGLE", Locale.Lookup("LOC_" .. firstGreatWorkObjectType));
				elseif not IsFirstGreatWorkByArtist(greatWorkIndex, pCityBldgs, pBuildingInfo) then
					-- Override the basic tooltip with the duplicate tooltip, this could be moved to GreatWorksSupport.lua depending on how it should work with artifacts
					local nTurnCreated:number = Game.GetGreatWorkDataFromIndex(greatWorkIndex).TurnCreated;
					local greatWorkName:string = Locale.Lookup(greatWorkInfo.Name);
					local greatWorkCreationDate:string = Calendar.MakeDateStr(nTurnCreated, GameConfiguration.GetCalendarType(), GameConfiguration.GetGameSpeedType(), false);
					strBasicTooltip = Locale.Lookup("LOC_GREAT_WORKS_TOOLTIP_DUPLICATE", greatWorkName, greatWorkTypeName, greatWorkCreator, greatWorkCreationDate);
					strThemeTooltip = Locale.Lookup("LOC_GREAT_WORKS_ART_THEME_DUPLICATE_ARTIST");
				elseif firstGreatWorkObjectType == greatWorkInfo.GreatWorkObjectType then
					strThemeTooltip = Locale.Lookup("LOC_GREAT_WORKS_ART_THEME_DUAL", Locale.Lookup("LOC_" .. firstGreatWorkObjectType));
				else
					strThemeTooltip = Locale.Lookup("LOC_GREAT_WORKS_MISMATCHED_THEME",  greatWorkTypeName, Locale.Lookup("LOC_" .. firstGreatWorkObjectType .. "_PLURAL"));
				end
			elseif pBuildingInfo.BuildingType == "BUILDING_MUSEUM_ARTIFACT" then

				local artifactEraName:string = Locale.Lookup("LOC_" .. greatWorkInfo.GreatWorkObjectType .. "_" .. greatWorkInfo.EraType);
				if firstGreatWork == greatWorkIndex then
					strThemeTooltip = Locale.Lookup("LOC_GREAT_WORKS_ART_THEME_SINGLE", artifactEraName);
				else
					local firstArtifactEraName:string = Locale.Lookup("LOC_" .. firstGreatWorkObjectType .. "_" .. GameInfo.GreatWorks[firstGreatWorkObjectTypeID].EraType .. "_PLURAL");

					if greatWorkInfo.EraType ~= GameInfo.GreatWorks[firstGreatWorkObjectTypeID].EraType then
						strThemeTooltip = Locale.Lookup("LOC_GREAT_WORKS_MISMATCHED_ERA",  artifactEraName, firstArtifactEraName);
					else
						local greatWorkPlayer:number = Game.GetGreatWorkPlayer(greatWorkIndex);
						local greatWorks:table = GetGreatWorksInBuilding(pCityBldgs, pBuildingInfo);

						-- Find duplicates for theming description
						local hash:table = {}
						local duplicates:table = {}
						for _,index in ipairs(greatWorks) do
							local gwPlayer:number = Game.GetGreatWorkPlayer(index);
							if (not hash[gwPlayer]) then
								hash[gwPlayer] = true;
							else
								table.insert(duplicates, gwPlayer);
							end
						end

						if table.count(duplicates) > 0 then
							strThemeTooltip = Locale.Lookup("LOC_GREAT_WORKS_DUPLICATE_ARTIFACT_CIVS", PlayerConfigurations[duplicates[1]]:GetCivilizationShortDescription(), firstArtifactEraName);
						end
					end
				end
			end
		end
		if strThemeTooltip ~= nil then
			return strBasicTooltip .. "[NEWLINE][NEWLINE]" .. strThemeTooltip;
		end
	end

	return strBasicTooltip;
end

function GetFirstGreatWorkInBuilding(pCityBldgs:table, pBuildingInfo:table)
	local index:number = 0;
	local buildingIndex:number = pBuildingInfo.Index;
	local numSlots:number = pCityBldgs:GetNumGreatWorkSlots(buildingIndex);
	for _:number=0, numSlots - 1 do
		local greatWorkIndex:number = pCityBldgs:GetGreatWorkInSlot(buildingIndex, index);
		if greatWorkIndex ~= -1 then
			return greatWorkIndex;
		end
		index = index + 1;
	end
	return -1;
end

function GetGreatWorksInBuilding(pCityBldgs:table, pBuildingInfo:table)
	local index:number = 0;
	local results:table = {};
	local buildingIndex:number = pBuildingInfo.Index;
	local numSlots:number = pCityBldgs:GetNumGreatWorkSlots(buildingIndex);
	for _:number=0, numSlots - 1 do
		local greatWorkIndex:number = pCityBldgs:GetGreatWorkInSlot(buildingIndex, index);
		if greatWorkIndex ~= -1 then
			table.insert(results, greatWorkIndex);
		end
		index = index + 1;
	end
	return results;
end

function IsFirstGreatWorkByArtist(greatWorkIndex, pCityBldgs, pBuildingInfo)
	local greatWorks:table = GetGreatWorksInBuilding(pCityBldgs, pBuildingInfo);
	local artist = pCityBldgs:GetCreatorNameFromIndex(greatWorkIndex); -- no need to localize

	-- Find duplicates for theming description
	for _,index in ipairs(greatWorks) do
		if (index == greatWorkIndex) then
			-- Didn't find a duplicate before the specified great work
			return true;
		end

		local creator = pCityBldgs:GetCreatorNameFromIndex(index); -- no need to localize
		if (creator == artist) then
			-- Found a duplicate before the specified great work
			return false;
		end
	end

	-- The specified great work isn't in this building, if it was added it would be unique
	return true;
end

function AddYield(instance:table, yieldName:string, yieldIcon:string, yieldValue:number)
	local bFoundYield:boolean = false;
	for _,data in ipairs(m_GreatWorkYields) do
		if data.Name == yieldName then
			data.Value = data.Value + yieldValue;
			bFoundYield = true;
			break;
		end
	end
	if bFoundYield == false then
		table.insert(m_GreatWorkYields, {Name=yieldName, Icon=yieldIcon, Value=yieldValue});
	end
	instance.Resource:SetText(yieldIcon .. yieldValue);
	instance.Resource:SetToolTipString(yieldName);
end

function OnClickGreatWork(kDragStruct:table, pCityBldgs:table, buildingIndex:number, greatWorkIndex:number, slotIndex:number)

	-- Don't allow moving great works unless it's the local player's turn
	if not m_isLocalPlayerTurn then return; end

	-- Don't allow moving artifacts if the museum is not full
	if not CanMoveWorkAtAll(pCityBldgs, buildingIndex, slotIndex) then
		return;
	end

	local greatWorkType:number = pCityBldgs:GetGreatWorkTypeFromIndex(greatWorkIndex);

	-- Subscribe to updates to keep great work icon attached to mouse
	m_GreatWorkSelected = {Index=greatWorkIndex, Slot=slotIndex, Building=buildingIndex, CityBldgs=pCityBldgs};

	-- Set placing label and details
	Controls.PlacingContainer:SetHide(false);
	Controls.HeaderStatsContainer:SetHide(true);
	Controls.PlacingName:SetText(Locale.ToUpper(Locale.Lookup(GameInfo.GreatWorks[greatWorkType].Name)));
	local textureOffsetX:number, textureOffsetY:number, textureSheet:string = GetGreatWorkIcon(GameInfo.GreatWorks[greatWorkType]);
	Controls.PlacingIcon:SetTexture(textureOffsetX, textureOffsetY, textureSheet);

	for _:number, destination:table in ipairs(m_GreatWorkBuildings) do
		local firstValidSlot:number = -1;
		local instance:table = destination.Instance;
		local dstBuilding:number = destination.Index;
		local dstBldgs:table = destination.CityBldgs;
		local slotCache:table = instance[DATA_FIELD_SLOT_CACHE];
		local numSlots:number = dstBldgs:GetNumGreatWorkSlots(dstBuilding);
		for index:number = 0, numSlots - 1 do
			if CanMoveGreatWork(pCityBldgs, buildingIndex, slotIndex, dstBldgs, dstBuilding, index) then
				if firstValidSlot == -1 then
					firstValidSlot = index;
				end

				local slotInstance:table = slotCache[index + 1];
				if slotInstance then
					table.insert(m_kViableDropTargets, slotInstance.TopControl);
					m_kControlToInstanceMap[slotInstance.TopControl] = slotInstance;
				end
			end
		end

		if firstValidSlot ~= -1 then
            UI.PlaySound("UI_GreatWorks_Pick_Up");
		end

		instance.HighlightedBG:SetHide(firstValidSlot == -1);
		instance.DefaultBG:SetHide(firstValidSlot == -1);
		instance.DisabledBG:SetHide(firstValidSlot ~= -1);
	end

	-- Add ViewGreatWorks button to drop targets so we can view specific works
	table.insert(m_kViableDropTargets, Controls.ViewGreatWork);
end

-- ===========================================================================
function CanMoveWorkAtAll(srcBldgs:table, srcBuilding:number, srcSlot:number)
	local srcGreatWork:number = srcBldgs:GetGreatWorkInSlot(srcBuilding, srcSlot);
	local srcGreatWorkType:number = srcBldgs:GetGreatWorkTypeFromIndex(srcGreatWork);
	local srcGreatWorkObjectType:string = GameInfo.GreatWorks[srcGreatWorkType].GreatWorkObjectType;

	-- Don't allow moving artifacts if the museum is not full
	if (srcGreatWorkObjectType == GREAT_WORK_ARTIFACT_TYPE) then
		if not IsBuildingFull(srcBldgs, srcBuilding) then
			return false;
		end
	end

	-- Don't allow moving art that has been recently created
	if (srcGreatWorkObjectType == "GREATWORKOBJECT_SCULPTURE" or
	    srcGreatWorkObjectType == "GREATWORKOBJECT_LANDSCAPE" or
		srcGreatWorkObjectType == "GREATWORKOBJECT_PORTRAIT" or
		srcGreatWorkObjectType == "GREATWORKOBJECT_RELIGIOUS") then

		local iTurnCreated:number = srcBldgs:GetTurnFromIndex(srcGreatWork);
		local iCurrentTurn:number = Game.GetCurrentGameTurn();
		local iTurnsBeforeMove:number = GlobalParameters.GREATWORK_ART_LOCK_TIME or DEFAULT_LOCK_TURNS;
		local iTurnsToWait = iTurnCreated + iTurnsBeforeMove - iCurrentTurn;
		if iTurnsToWait > 0 then
			return false;
		end
	end

	return true;
end

-- ===========================================================================
function IsBuildingFull( pBuildings:table, buildingIndex:number )
	local numSlots:number = pBuildings:GetNumGreatWorkSlots(buildingIndex);
	for index:number = 0, numSlots - 1 do
		local greatWorkIndex:number = pBuildings:GetGreatWorkInSlot(buildingIndex, index);
		if (greatWorkIndex == -1) then
			return false;
		end
	end

	return true;
end

-- ===========================================================================
function ShowCannotMoveMessage(sMessage:string)
	local cannotMoveWorkDialog = PopupDialogInGame:new("CannotMoveWork");
	cannotMoveWorkDialog:ShowOkDialog(sMessage);
end

-- ===========================================================================
function CanMoveToSlot(destBldgs:table, destBuilding:number)

	-- Don't allow moving artifacts if the museum is not full
	local srcGreatWorkType:number = m_GreatWorkSelected.CityBldgs:GetGreatWorkTypeFromIndex(m_GreatWorkSelected.Index);
	local srcGreatWorkObjectType:string = GameInfo.GreatWorks[srcGreatWorkType].GreatWorkObjectType;
	if (srcGreatWorkObjectType ~= GREAT_WORK_ARTIFACT_TYPE) then
	    return true;
	end

	-- Don't allow moving artifacts if the museum is not full
	local numSlots:number = destBldgs:GetNumGreatWorkSlots(destBuilding);
	for index:number = 0, numSlots - 1 do
		local greatWorkIndex:number = destBldgs:GetGreatWorkInSlot(destBuilding, index);
		if (greatWorkIndex == -1) then
			return false;
		end
	end

	return true;
end

-- ===========================================================================
function CanMoveGreatWork(srcBldgs:table, srcBuilding:number, srcSlot:number, dstBldgs:table, dstBuilding:number, dstSlot:number)

	local srcGreatWork:number = srcBldgs:GetGreatWorkInSlot(srcBuilding, srcSlot);
	local srcGreatWorkType:number = srcBldgs:GetGreatWorkTypeFromIndex(srcGreatWork);
	local srcGreatWorkObjectType:string = GameInfo.GreatWorks[srcGreatWorkType].GreatWorkObjectType;

	local dstGreatWork:number = dstBldgs:GetGreatWorkInSlot(dstBuilding, dstSlot);
	local dstSlotType:number = dstBldgs:GetGreatWorkSlotType(dstBuilding, dstSlot);
	local dstSlotTypeString:string = GameInfo.GreatWorkSlotTypes[dstSlotType].GreatWorkSlotType;

	for row in GameInfo.GreatWork_ValidSubTypes() do
		-- Ensure source great work can be placed into destination slot
		if dstSlotTypeString == row.GreatWorkSlotType and srcGreatWorkObjectType == row.GreatWorkObjectType then
			if dstGreatWork == -1 then
				-- Artifacts can never be moved to an empty slot as
				-- they can only be swapped between other full museums
				return row.GreatWorkObjectType ~= GREAT_WORK_ARTIFACT_TYPE;
			else -- If destination slot has a great work, ensure it can be swapped to the source slot
				local srcSlotType:number = srcBldgs:GetGreatWorkSlotType(srcBuilding, srcSlot);
				local srcSlotTypeString:string = GameInfo.GreatWorkSlotTypes[srcSlotType].GreatWorkSlotType;

				local dstGreatWorkType:number = dstBldgs:GetGreatWorkTypeFromIndex(dstGreatWork);
				local dstGreatWorkObjectType:string = GameInfo.GreatWorks[dstGreatWorkType].GreatWorkObjectType;

				for row in GameInfo.GreatWork_ValidSubTypes() do
					if srcSlotTypeString == row.GreatWorkSlotType and dstGreatWorkObjectType == row.GreatWorkObjectType then
						return CanMoveWorkAtAll(dstBldgs, dstBuilding, dstSlot);
					end
				end
			end
		end
	end
	return false;
end

-- ===========================================================================
function MoveGreatWork( kSrcInstance:table, kDestInstance:table )
	if kSrcInstance ~= nil and kDestInstance ~= nil then
		-- Don't try to move the great work if it was dropped on the slot it was already in
		if kSrcInstance[DATA_FIELD_CITY_ID] == kDestInstance[DATA_FIELD_CITY_ID] and
			kSrcInstance[DATA_FIELD_BUILDING_ID] == kDestInstance[DATA_FIELD_BUILDING_ID] and
			kSrcInstance[DATA_FIELD_SLOT_INDEX] == kDestInstance[DATA_FIELD_SLOT_INDEX] then

			kSrcInstance.EmptySlotHighlight:SetHide(true);
			return;
		end

		-- Swap instance great work icons while we wait for the game core to update
		local sourceGreatWorkType:number = kSrcInstance[DATA_FIELD_GREAT_WORK_TYPE];
		local destGreatWorkType:number = kDestInstance[DATA_FIELD_GREAT_WORK_TYPE];

		if destGreatWorkType == -1 then
			kSrcInstance.GreatWorkIcon:SetHide(true);
		else
			local textureOffsetX:number, textureOffsetY:number, textureSheet:string = GetGreatWorkIcon(GameInfo.GreatWorks[destGreatWorkType]);
			kSrcInstance.GreatWorkIcon:SetHide(false);
			kSrcInstance.GreatWorkIcon:SetTexture(textureOffsetX, textureOffsetY, textureSheet);
		end

		if sourceGreatWorkType == -1 then
			kDestInstance.GreatWorkIcon:SetHide(true);
		else
			local textureOffsetX:number, textureOffsetY:number, textureSheet:string = GetGreatWorkIcon(GameInfo.GreatWorks[sourceGreatWorkType]);
			kDestInstance.GreatWorkIcon:SetHide(false);
			kDestInstance.GreatWorkIcon:SetTexture(textureOffsetX, textureOffsetY, textureSheet);
		end

		m_dest_building = kDestInstance[DATA_FIELD_BUILDING_ID];
		m_dest_city = kDestInstance[DATA_FIELD_CITY_ID];

		local tParameters = {};
		tParameters[PlayerOperations.PARAM_PLAYER_ONE] = Game.GetLocalPlayer();
		tParameters[PlayerOperations.PARAM_CITY_SRC] = kSrcInstance[DATA_FIELD_CITY_ID];
		tParameters[PlayerOperations.PARAM_CITY_DEST] = kDestInstance[DATA_FIELD_CITY_ID];
		tParameters[PlayerOperations.PARAM_BUILDING_SRC] = kSrcInstance[DATA_FIELD_BUILDING_ID];
		tParameters[PlayerOperations.PARAM_BUILDING_DEST] = kDestInstance[DATA_FIELD_BUILDING_ID];
		tParameters[PlayerOperations.PARAM_GREAT_WORK_INDEX] = kSrcInstance[DATA_FIELD_GREAT_WORK_INDEX];
		tParameters[PlayerOperations.PARAM_SLOT] = kDestInstance[DATA_FIELD_SLOT_INDEX];
		UI.RequestPlayerOperation(Game.GetLocalPlayer(), PlayerOperations.MOVE_GREAT_WORK, tParameters);

		UI.PlaySound("UI_GreatWorks_Put_Down");
	end
	ContextPtr:ClearUpdate();
end

-- ===========================================================================
function ClearGreatWorkTransfer()
	m_GreatWorkSelected = nil;
	m_kViableDropTargets = {};
	m_kControlToInstanceMap = {};

	for _:number, destination:table in ipairs(m_GreatWorkBuildings) do
		local instance:table = destination.Instance;
		instance.HighlightedBG:SetHide(true);
		instance.DefaultBG:SetHide(false);
		instance.DisabledBG:SetHide(true);
	end

	Controls.PlacingContainer:SetHide(true);
	Controls.HeaderStatsContainer:SetHide(false);

	ContextPtr:ClearUpdate();
end

-- ===========================================================================
--	Update player data and refresh the display state
-- ===========================================================================
function UpdateData()
	UpdatePlayerData();
	UpdateGreatWorks();
end

-- ===========================================================================
--	Show / Hide
-- ===========================================================================
function Open()
	if (Game.GetLocalPlayer() == -1) then
		return
	end

    -- Concise UI >>
    cui_ThemeHelper = false;
    if not UIManager:IsInPopupQueue(ContextPtr) then
        local kParameters = {};
        kParameters.RenderAtCurrentParent = true;
        kParameters.InputAtCurrentParent = true;
        kParameters.AlwaysVisibleInQueue = true;
        UIManager:QueuePopup(ContextPtr, PopupPriority.Low, kParameters);
        UI.PlaySound("UI_Screen_Open");
    end
    -- << Concise UI

	UpdateData();
	ContextPtr:SetHide(false);

	-- From Civ6_styles: FullScreenVignetteConsumer
	Controls.ScreenAnimIn:SetToBeginning();
	Controls.ScreenAnimIn:Play();
	LuaEvents.GreatWorks_OpenGreatWorks();
end

function Close()
    -- Concise UI >>
    cui_ThemeHelper = false;
    if not ContextPtr:IsHidden() then
        UI.PlaySound("UI_Screen_Close");
    end

    if UIManager:DequeuePopup(ContextPtr) then
        LuaEvents.GreatPeople_CloseGreatPeople();
    end
    -- << Concise UI

	ContextPtr:SetHide(true);
	ContextPtr:ClearUpdate();
end
function ViewGreatWork(greatWorkData:table)
	local city:table = greatWorkData.CityBldgs:GetCity();
	local buildingID:number = greatWorkData.Building;
	local greatWorkIndex:number = greatWorkData.Index;
	LuaEvents.GreatWorksOverview_ViewGreatWork(city, buildingID, greatWorkIndex);
end

-- ===========================================================================
--	Game Event Callbacks
-- ===========================================================================
function OnShowScreen()
	if (Game.GetLocalPlayer() == -1) then
		return
	end

	Open();
    -- UI.PlaySound("UI_Screen_Open"); -- Concise UI
end

-- ===========================================================================
function OnHideScreen()
	if not ContextPtr:IsHidden() then
		UI.PlaySound("UI_Screen_Close");
	end

	Close();
	LuaEvents.GreatWorks_CloseGreatWorks();
end

-- ===========================================================================
function OnInputHandler(pInputStruct:table)
	local uiMsg = pInputStruct:GetMessageType();
	if uiMsg == KeyEvents.KeyUp and pInputStruct:GetKey() == Keys.VK_ESCAPE then
		if m_GreatWorkSelected ~= nil then
			ClearGreatWorkTransfer();
		else
			OnHideScreen();
		end
		return true;
	end
	return false;
end

-- ===========================================================================
function OnViewGallery()
	if m_FirstGreatWork ~= nil then
		ViewGreatWork(m_FirstGreatWork);
		if m_GreatWorkSelected ~= nil then
			ClearGreatWorkTransfer();
		end
        UI.PlaySound("Play_GreatWorks_Gallery_Ambience");
	end
end

-- ===========================================================================
function OnViewGreatWork()
	if m_GreatWorkSelected ~= nil then
		ViewGreatWork(m_GreatWorkSelected);
		ClearGreatWorkTransfer();
		UpdateData();
        UI.PlaySound("Play_GreatWorks_Gallery_Ambience");
	end
end

------------------------------------------------------------------------------
-- A great work was moved.
function OnGreatWorkMoved(fromCityOwner, fromCityID, toCityOwner, toCityID, buildingID, greatWorkType)
	if (not ContextPtr:IsHidden() and (fromCityOwner == Game.GetLocalPlayer() or toCityOwner == Game.GetLocalPlayer())) then
        m_during_move = true;
		UpdateData();
        m_during_move = false;
	end
end

-- ===========================================================================
--	Hot Reload Related Events
-- ===========================================================================
function OnInit(isReload:boolean)
	if isReload then
		LuaEvents.GameDebug_GetValues(RELOAD_CACHE_ID);
	end
end
function OnShutdown()
	LuaEvents.GameDebug_AddValue(RELOAD_CACHE_ID, "isHidden", ContextPtr:IsHidden());

	LuaEvents.GameDebug_Return.Remove(OnGameDebugReturn);
	LuaEvents.LaunchBar_OpenGreatWorksOverview.Remove(OnShowScreen);
	LuaEvents.GreatWorkCreated_OpenGreatWorksOverview.Remove(OnShowScreen);
	LuaEvents.LaunchBar_CloseGreatWorksOverview.Remove(OnHideScreen);

	Events.GreatWorkMoved.Remove(OnGreatWorkMoved);
	Events.LocalPlayerTurnBegin.Remove(OnLocalPlayerTurnBegin);
	Events.LocalPlayerTurnEnd.Remove(OnLocalPlayerTurnEnd);
end
function OnGameDebugReturn(context:string, contextTable:table)
	if context == RELOAD_CACHE_ID and contextTable["isHidden"] ~= nil and not contextTable["isHidden"] then
		Open();
	end
end

-- ===========================================================================
--	Player Turn Events
-- ===========================================================================
function OnLocalPlayerTurnBegin()
	m_isLocalPlayerTurn = true;
end
function OnLocalPlayerTurnEnd()
	m_isLocalPlayerTurn = false;
	if(GameConfiguration.IsHotseat()) then
		OnHideScreen();
	end
end

-- Concise UI ----------------------------------------------------------------
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

-- Concise UI ----------------------------------------------------------------
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
        -- lock with turns
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
    elseif
        (srcGreatWorkObjectType == "GREATWORKOBJECT_SCULPTURE" or srcGreatWorkObjectType == "GREATWORKOBJECT_LANDSCAPE" or
            srcGreatWorkObjectType == "GREATWORKOBJECT_PORTRAIT" or
            srcGreatWorkObjectType == "GREATWORKOBJECT_RELIGIOUS")
     then
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

-- Concise UI ----------------------------------------------------------------
function CuiOnSortButtonClick()
    local IsSortByCity = CuiSettings:ReverseAndGetBoolean(CuiSettings.SORT_BY_CITY)
    if IsSortByCity then
        Controls.SortGreatWork:SetText(Locale.Lookup("LOC_CUI_GW_SORT_BY_BUILDING"))
    else
        Controls.SortGreatWork:SetText(Locale.Lookup("LOC_CUI_GW_SORT_BY_CITY"))
    end
    UpdateData()
end

-- Concise UI ----------------------------------------------------------------
function CuiOnThemeButtonClick()
    cui_ThemeHelper = not cui_ThemeHelper
    UpdateData()
end

-- Concise UI ----------------------------------------------------------------
function CuiInit()
    local IsSortByCity = CuiSettings:GetBoolean(CuiSettings.SORT_BY_CITY)
    if IsSortByCity then
        Controls.SortGreatWork:SetText(Locale.Lookup("LOC_CUI_GW_SORT_BY_BUILDING"))
    else
        Controls.SortGreatWork:SetText(Locale.Lookup("LOC_CUI_GW_SORT_BY_CITY"))
    end
    Controls.SortGreatWork:RegisterCallback(Mouse.eLClick, CuiOnSortButtonClick)
    Controls.SortGreatWork:RegisterCallback(
        Mouse.eMouseEnter,
        function()
            UI.PlaySound("Main_Menu_Mouse_Over")
        end
    )
    Controls.ThemeHelper:RegisterCallback(Mouse.eLClick, CuiOnThemeButtonClick)
    Controls.ThemeHelper:RegisterCallback(
        Mouse.eMouseEnter,
        function()
            UI.PlaySound("Main_Menu_Mouse_Over")
        end
    )
    Controls.ThemeHelper:SetToolTipString(Locale.Lookup("LOC_CUI_GW_THEMING_HELPER_TOOLTIP"))
end

-- ===========================================================================
--	INIT
-- ===========================================================================
function Initialize()

	if (not HasCapability("CAPABILITY_GREAT_WORKS_VIEW")) then
		-- Viewing Great Works is off, just exit
		return;
	end

    CuiInit(); -- Concise UI

	ContextPtr:SetInitHandler(OnInit);
	ContextPtr:SetShutdown(OnShutdown);
	ContextPtr:SetInputHandler(OnInputHandler, true);

	Controls.ModalBG:SetTexture("GreatWorks_Background");
	Controls.ModalScreenTitle:SetText(Locale.ToUpper(LOC_SCREEN_TITLE));
	Controls.ModalScreenClose:RegisterCallback(Mouse.eLClick, OnHideScreen);
	Controls.ModalScreenClose:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
	Controls.ViewGallery:RegisterCallback(Mouse.eLClick, OnViewGallery);
	Controls.ViewGallery:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
	Controls.ViewGreatWork:RegisterCallback(Mouse.eLClick, OnViewGreatWork);
	Controls.ViewGreatWork:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);

	LuaEvents.GameDebug_Return.Add(OnGameDebugReturn);
	LuaEvents.LaunchBar_OpenGreatWorksOverview.Add(OnShowScreen);
	LuaEvents.GreatWorkCreated_OpenGreatWorksOverview.Add(OnShowScreen);
	LuaEvents.LaunchBar_CloseGreatWorksOverview.Add(OnHideScreen);

	Events.GreatWorkMoved.Add(OnGreatWorkMoved);
	Events.LocalPlayerTurnBegin.Add(OnLocalPlayerTurnBegin);
	Events.LocalPlayerTurnEnd.Add(OnLocalPlayerTurnEnd);

    m_TopPanelConsideredHeight = Controls.Vignette:GetSizeY() - TOP_PANEL_OFFSET; -- Concise UI
end
Initialize();
