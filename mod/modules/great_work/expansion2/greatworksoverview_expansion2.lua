-- Copyright 2018-2020, Firaxis Games

-- This file is being included into the base GreatWorksOverview file using the wildcard include setup in GreatWorksOverview.lua
-- Refer to the bottom of GreatWorksOverview.lua to see how that's happening
-- DO NOT include any GreatWorksOverview files here or it will cause problems
-- include("GreatWorksOverview");

include("InstanceManager");
include("PopupDialog")
include("GreatWorksSupport");

-- ===========================================================================
--	CONSTANTS Shoul probably switch the base game to just use globals.
-- ===========================================================================

local SIZE_SLOT_TYPE_ICON:number = 40;
local MIN_PADDING_SLOTS:number = 2;
local MAX_PADDING_SLOTS:number = 30;
local MAX_NUM_SLOTS:number = 6;

local LOC_TOURISM:string = Locale.Lookup("LOC_GREAT_WORKS_TOURISM");
local LOC_THEME_BONUS:string = Locale.Lookup("LOC_GREAT_WORKS_THEMED_BONUS");

local DATA_FIELD_SLOT_CACHE:string = "SlotCache";
local DATA_FIELD_GREAT_WORK_IM:string = "GreatWorkIM";
local DATA_FIELD_TOURISM_YIELD:string = "TourismYield";
local DATA_FIELD_THEME_BONUS_IM:string = "ThemeBonusIM";

local cui_ThemeHelper = false; -- CUI
local YIELD_FONT_ICONS:table = {
	YIELD_FOOD				= "[ICON_FoodLarge]",
	YIELD_PRODUCTION		= "[ICON_ProductionLarge]",
	YIELD_GOLD				= "[ICON_GoldLarge]",
	YIELD_SCIENCE			= "[ICON_ScienceLarge]",
	YIELD_CULTURE			= "[ICON_CultureLarge]",
	YIELD_FAITH				= "[ICON_FaithLarge]",
	TourismYield			= "[ICON_TourismLarge]"
};

-- ===========================================================================
function GetThemeDescription(buildingType:string)
	local localPlayerID = Game.GetLocalPlayer();
	local localPlayer = Players[localPlayerID];

	if(localPlayer == nil) then
		return nil;
	end

    local eBuilding = localPlayer:GetCulture():GetAutoThemedBuilding();
	local bAutoTheme = localPlayer:GetCulture():IsAutoThemedEligible(GameInfo.Buildings[buildingType].Hash);

	if (GameInfo.Buildings[buildingType].Index == eBuilding) then
		return Locale.Lookup("LOC_BUILDING_THEMINGBONUS_FULL_MUSEUM");
	elseif(bAutoTheme == true) then
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

-- ===========================================================================
function PopulateGreatWorkSlot(instance:table, pCity:table, pCityBldgs:table, pBuildingInfo:table)
	
	instance.DefaultBG:SetHide(false);
	instance.DisabledBG:SetHide(true);
	instance.HighlightedBG:SetHide(true);
	instance.DefaultBG:RegisterCallback(Mouse.eLClick, function() end); -- clear callback
	instance.HighlightedBG:RegisterCallback(Mouse.eLClick, function() end); -- clear callback

    -- CUI >> reset Theme label
    instance.ThemingLabel:SetText("");
    instance.ThemingLabel:SetToolTipString("");
    -- << CUI

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
	local localPlayerID = Game.GetLocalPlayer();
	local localPlayer = Players[localPlayerID];

	if(localPlayer == nil) then
		return nil;
	end

	local bAutoTheme = localPlayer:GetCulture():IsAutoThemedEligible();

	if (numSlots ~= nil and numSlots > 0) then
		for _:number=0, numSlots - 1 do
			local instance:table = greatWorkIM:GetInstance();
			local greatWorkIndex:number = pCityBldgs:GetGreatWorkInSlot(buildingIndex, index);
			local greatWorkSlotType:number = pCityBldgs:GetGreatWorkSlotType(buildingIndex, index);
			if greatWorkSlotType >= 0 then
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
		end                            

		if firstGreatWork ~= nil and themeDescription ~= nil and buildingType ~= "BUILDING_QUEENS_BIBLIOTHEQUE" then
			local slotTypeIcon:string = "ICON_" .. firstGreatWork.GreatWorkObjectType;
			if firstGreatWork.GreatWorkObjectType == "GREATWORKOBJECT_ARTIFACT" then
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
			if IsDuringMove() then
				if buildingIndex == GetDestBuilding() then
                    if (GetDestCity() == pCityBldgs:GetCity():GetID()) then
                        UI.PlaySound("UI_GREAT_WORKS_BONUS_ACHIEVED");
                    end
				end
			end
		else
			if themeDescription ~= nil then
                -- if we're being called due to moving a work
				if numSlots > 1 then
					if(bAutoTheme == true) then
						instance.ThemingLabel:SetText(Locale.Lookup("LOC_GREAT_WORKS_THEME_BONUS_PROGRESS", numGreatWorks, numSlots));
					else
						instance.ThemingLabel:SetText(Locale.Lookup("LOC_GREAT_WORKS_THEME_BONUS_PROGRESS", numThemedGreatWorks, numSlots));
					end

					if IsDuringMove() then
						if buildingIndex == GetDestBuilding() then
                            if (GetDestCity() == pCityBldgs:GetCity():GetID()) then
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