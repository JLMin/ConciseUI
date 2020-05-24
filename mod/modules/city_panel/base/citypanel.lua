-- Copyright 2016-2019, Firaxis Games

-- ===========================================================================
--	CityPanel v3
-- ===========================================================================

include( "AdjacencyBonusSupport" );		-- GetAdjacentYieldBonusString()
include( "CitySupport" );
include( "Civ6Common" );				-- GetYieldString()
include( "Colors" );
include( "InstanceManager" );
include( "SupportFunctions" );			-- Round(), Clamp()
include( "PortraitSupport" );
include( "ToolTipHelper" );
include( "GameCapabilities" );
include( "MapUtilities" );

include("cui_data") -- CUI
include("cui_settings") -- CUI

-- ===========================================================================
--	DEBUG
--	Toggle these for temporary debugging help.
-- ===========================================================================
local m_debugAllowMultiPanel	:boolean = false;		-- (false default) Let's multiple sub-panels show at one time.


-- ===========================================================================
--	GLOBALS
--	Accessible in overriden files.
-- ===========================================================================
g_pCity								= nil;
g_growthPlotId						= -1;
g_growthHexTextWidth				= -1;


-- ===========================================================================
--	CONSTANTS
-- ===========================================================================
local ANIM_OFFSET_OPEN						:number = -73;
local ANIM_OFFSET_OPEN_WITH_PRODUCTION_LIST	:number = -250;
local SIZE_SMALL_RELIGION_ICON				:number = 22;
local SIZE_LEADER_ICON						:number = 32;
local SIZE_PRODUCTION_ICON					:number = 32;	-- TODO: Switch this to 38 when the icons go in.
local SIZE_MAIN_ROW_LEFT_WIDE				:number = 270;
local SIZE_MAIN_ROW_LEFT_COLLAPSED			:number = 157;
local TXT_NO_PRODUCTION						:string = Locale.Lookup("LOC_HUD_CITY_PRODUCTION_NOTHING_PRODUCED");
local MAX_BEFORE_TRUNC_TURN_LABELS			:number = 160;
local MAX_BEFORE_TRUNC_STATIC_LABELS		:number	= 112;
local HEX_GROWTH_TEXT_PADDING				:number = 10;

local UV_CITIZEN_GROWTH_STATUS		:table	= {};
		UV_CITIZEN_GROWTH_STATUS[0] = {u=0, v=0  };		-- revolt
		UV_CITIZEN_GROWTH_STATUS[1] = {u=0, v=0 };		-- unrest
		UV_CITIZEN_GROWTH_STATUS[2] = {u=0, v=0};		-- unhappy
		UV_CITIZEN_GROWTH_STATUS[3] = {u=0, v=50};		-- displeased
		UV_CITIZEN_GROWTH_STATUS[4] = {u=0, v=100};		-- content (normal)
		UV_CITIZEN_GROWTH_STATUS[5] = {u=0, v=150};		-- happy
		UV_CITIZEN_GROWTH_STATUS[6] = {u=0, v=200};		-- ecstatic

local UV_HOUSING_GROWTH_STATUS		:table = {};
		UV_HOUSING_GROWTH_STATUS[0] = {u=0, v=0};		-- slowed
		UV_HOUSING_GROWTH_STATUS[1] = {u=0, v=100};		-- normal

local UV_CITIZEN_STARVING_STATUS		:table = {};
		UV_CITIZEN_STARVING_STATUS[0] = {u=0, v=0};		-- starving
		UV_CITIZEN_STARVING_STATUS[1] = {u=0, v=100};		-- normal

local PANEL_INFOLINE_LOCATIONS:table = {};
		PANEL_INFOLINE_LOCATIONS[0] = 20;
		PANEL_INFOLINE_LOCATIONS[1] = 45;
		PANEL_INFOLINE_LOCATIONS[2] = 71;
		PANEL_INFOLINE_LOCATIONS[3] = 94;

local PANEL_BUTTON_LOCATIONS:table = {};
		PANEL_BUTTON_LOCATIONS[0] = {x=85, y=18};
		PANEL_BUTTON_LOCATIONS[1] = {x=99, y=42};
		PANEL_BUTTON_LOCATIONS[2] = {x=95, y=69};
		PANEL_BUTTON_LOCATIONS[3] = {x=79, y=90};
local HOUSING_LABEL_OFFSET:number = 66;

-- Mirrored in ProductionPanel
local LISTMODE:table = {PRODUCTION = 1, PURCHASE_GOLD = 2, PURCHASE_FAITH = 3, PROD_QUEUE = 4};

m_PurchasePlot						 = UILens.CreateLensLayerHash("Purchase_Plot");
local m_CitizenManagement	: number = UILens.CreateLensLayerHash("Citizen_Management");


-- ===========================================================================
--	MEMBERS
-- ===========================================================================
local m_kData						:table	= nil;
local m_isInitializing				:boolean= false;
local m_isShowingPanels				:boolean= false;
local m_pPlayer						:table	= nil;
local m_primaryColor				:number = UI.GetColorValueFromHexLiteral(0xcafef00d);
local m_secondaryColor				:number = UI.GetColorValueFromHexLiteral(0xf00d1ace);
local m_kTutorialDisabledControls	:table	= nil;
local m_CurrentPanelLine				:number = 0;
local m_PrevInterfaceMode			:number = InterfaceModeTypes.SELECTION;


-- ===========================================================================
--
-- ===========================================================================
function Close()
	ContextPtr:SetHide( true );
end

-- ===========================================================================
--	Helper, display the 3-way state of a yield based on the enum.
--	yieldData,	A YIELD_STATE
--	yieldName,	The name tied used in the check and ignore controls.
-- ===========================================================================
function RealizeYield3WayCheck( yieldData:number, yieldType, yieldToolTip )

	local yieldInfo = GameInfo.Yields[yieldType];
	if(yieldInfo) then

		local controlLookup = {
			YIELD_FOOD = "Food",
			YIELD_PRODUCTION = "Production",
			YIELD_GOLD = "Gold",
			YIELD_SCIENCE = "Science",
			YIELD_CULTURE = "Culture",
			YIELD_FAITH = "Faith",
		};

		local yieldName = controlLookup[yieldInfo.YieldType];
		if(yieldName) then

			local checkControl = Controls[yieldName.."Check"];
			local ignoreControl = Controls[yieldName.."Ignore"];
			local gridControl = Controls[yieldName.."Grid"];

			if(checkControl and ignoreControl and gridControl) then

				local toolTip = "";

				if yieldData == YIELD_STATE.FAVORED then
					checkControl:SetCheck(true);	-- Just visual, no callback!
					checkControl:SetDisabled(false);
					ignoreControl:SetHide(true);

					toolTip = Locale.Lookup("LOC_HUD_CITY_YIELD_FOCUSING", yieldInfo.Name) .. "[NEWLINE][NEWLINE]";
				elseif yieldData == YIELD_STATE.IGNORED then
					checkControl:SetCheck(false);	-- Just visual, no callback!
					checkControl:SetDisabled(true);
					ignoreControl:SetHide(false);

					toolTip = Locale.Lookup("LOC_HUD_CITY_YIELD_IGNORING", yieldInfo.Name) .. "[NEWLINE][NEWLINE]";
				else
					checkControl:SetCheck(false);
					checkControl:SetDisabled(false);
					ignoreControl:SetHide(true);

					toolTip = Locale.Lookup("LOC_HUD_CITY_YIELD_CITIZENS", yieldInfo.Name) .. "[NEWLINE][NEWLINE]";
				end

				if(#yieldToolTip > 0) then
					toolTip = toolTip .. yieldToolTip;
				else
					toolTip = toolTip .. Locale.Lookup("LOC_HUD_CITY_YIELD_NOTHING");
				end

				gridControl:SetToolTipString(toolTip);
			end
		end

	end
end

-- ===========================================================================
--	Set the health meter
-- ===========================================================================
function RealizeHealthMeter( control:table, percent:number )
	if	( percent > 0.7 )	then
		control:SetColor( COLORS.METER_HP_GOOD );
	elseif ( percent > 0.4 )	then
		control:SetColor( COLORS.METER_HP_OK );
	else
		control:SetColor( COLORS.METER_HP_BAD );
	end

	-- Meter control is half circle, so add enough to start at half point and condense % into the half area
	percent			= (percent * 0.5) + 0.5;
	control:SetPercent( percent );
end

-- ===========================================================================
--	Main city panel
-- ===========================================================================
function ViewMain( data:table )
	m_primaryColor, m_secondaryColor  = UI.GetPlayerColors( m_pPlayer:GetID() );

	if(m_primaryColor == nil or m_secondaryColor == nil or m_primaryColor == 0 or m_secondaryColor == 0) then
		UI.DataError("Couldn't find player colors for player - " .. (m_pPlayer and tostring(m_pPlayer:GetID()) or "nil"));
	end

	local darkerBackColor = UI.DarkenLightenColor(m_primaryColor,-85,100);
	local brighterBackColor = UI.DarkenLightenColor(m_primaryColor,90,255);
	m_CurrentPanelLine = 0;

	-- Name data
	Controls.CityName:SetText((data.IsCapital and "[ICON_Capital]" or "") .. Locale.ToUpper( Locale.Lookup(data.CityName)));
	Controls.CityName:SetToolTipString(data.IsCapital and Locale.Lookup("LOC_HUD_CITY_IS_CAPITAL") or nil );

	-- Banner and icon colors
	Controls.Banner:SetColor(m_primaryColor);
	Controls.BannerLighter:SetColor(brighterBackColor);
	Controls.BannerDarker:SetColor(darkerBackColor);
	Controls.CircleBacking:SetColor(m_primaryColor);
	Controls.CircleLighter:SetColor(brighterBackColor);
	Controls.CircleDarker:SetColor(darkerBackColor);
	Controls.CityName:SetColor(m_secondaryColor);
	Controls.CivIcon:SetColor(m_secondaryColor);

	-- Set Population --
	Controls.PopulationNumber:SetText(data.Population);

	-- Damage meters ---
	RealizeHealthMeter( Controls.CityHealthMeter, data.HitpointPercent );
	if(data.CityWallTotalHP > 0) then
		Controls.CityWallHealthMeters:SetHide(false);
		--RealizeHealthMeter( Controls.WallHealthMeter, data.CityWallHPPercent );
		local percent			= (data.CityWallHPPercent * 0.5) + 0.5;
		Controls.WallHealthMeter:SetPercent( percent );
	else
		Controls.CityWallHealthMeters:SetHide(true);
	end

	-- Update city health tooltip
	local tooltip:string = Locale.Lookup("LOC_HUD_UNIT_PANEL_HEALTH_TOOLTIP", data.HitpointsCurrent, data.HitpointsTotal);
	if (data.CityWallTotalHP > 0) then
		tooltip = tooltip .. "[NEWLINE]" .. Locale.Lookup("LOC_HUD_UNIT_PANEL_WALL_HEALTH_TOOLTIP", data.CityWallCurrentHP, data.CityWallTotalHP);
	end
	Controls.CityHealthMeters:SetToolTipString(tooltip);

	local civType:string = PlayerConfigurations[data.Owner]:GetCivilizationTypeName();
	if civType ~= nil then
		Controls.CivIcon:SetIcon("ICON_" .. civType);
	else
		UI.DataError("Invalid type name returned by GetCivilizationTypeName");
    end

    -- CUI: Start
    -- Set icons and values for the yield checkboxes
    Controls.FoodCheck:GetTextButton():SetText("[ICON_Food]" .. toPlusMinusString(CuiGetFoodPerTurn(data)))
    Controls.ProductionCheck:GetTextButton():SetText("[ICON_Production]" .. toPlusMinusString(data.ProductionPerTurn))
    Controls.GoldCheck:GetTextButton():SetText("[ICON_Gold]" .. toPlusMinusString(data.GoldPerTurn))
    Controls.ScienceCheck:GetTextButton():SetText("[ICON_Science]" .. toPlusMinusString(data.SciencePerTurn))
    Controls.CultureCheck:GetTextButton():SetText("[ICON_Culture]" .. toPlusMinusString(data.CulturePerTurn))
    Controls.FaithCheck:GetTextButton():SetText("[ICON_Faith]" .. toPlusMinusString(data.FaithPerTurn))
    -- Set the Yield checkboxes based on the game state
    RealizeYield3WayCheck(data.YieldFilters[YieldTypes.FOOD], YieldTypes.FOOD, CuiGetFoodToolTip(data)) -- CUI
    RealizeYield3WayCheck(
        data.YieldFilters[YieldTypes.PRODUCTION],
        YieldTypes.PRODUCTION,
        data.ProductionPerTurnToolTip
    )
    RealizeYield3WayCheck(data.YieldFilters[YieldTypes.GOLD], YieldTypes.GOLD, data.GoldPerTurnToolTip)
    RealizeYield3WayCheck(data.YieldFilters[YieldTypes.SCIENCE], YieldTypes.SCIENCE, data.SciencePerTurnToolTip)
    RealizeYield3WayCheck(data.YieldFilters[YieldTypes.CULTURE], YieldTypes.CULTURE, data.CulturePerTurnToolTip)
    RealizeYield3WayCheck(data.YieldFilters[YieldTypes.FAITH], YieldTypes.FAITH, data.FaithPerTurnToolTip)
    -- CUI: End

	if m_isShowingPanels then
		Controls.LabelButtonRows:SetSizeX( SIZE_MAIN_ROW_LEFT_COLLAPSED );
	else
		Controls.LabelButtonRows:SetSizeX( SIZE_MAIN_ROW_LEFT_WIDE );
	end

	-- Custom religion icon:
	if data.Religions[DATA_DOMINANT_RELIGION] ~= nil then
		local kReligion		:table	= GameInfo.Religions[data.Religions[DATA_DOMINANT_RELIGION].ReligionType];
		if (kReligion ~= nil) then
			local iconName		:string = "ICON_" .. kReligion.ReligionType;
			Controls.ReligionIcon:SetIcon(iconName);
		end
	end


	Controls.BreakdownNum:SetText( data.BuildingsNum );
	Controls.BreakdownGrid:SetOffsetY(PANEL_INFOLINE_LOCATIONS[m_CurrentPanelLine]);
	Controls.BreakdownButton:SetOffsetX(PANEL_BUTTON_LOCATIONS[m_CurrentPanelLine].x);
	Controls.BreakdownButton:SetOffsetY(PANEL_BUTTON_LOCATIONS[m_CurrentPanelLine].y);
	m_CurrentPanelLine = m_CurrentPanelLine + 1;

	-- Hide Religion / Faith UI in some scenarios
	if not GameCapabilities.HasCapability("CAPABILITY_CITY_HUD_RELIGION_TAB") then
		Controls.ReligionGrid:SetHide(true);
		Controls.ReligionIcon:SetHide(true);
		Controls.ReligionButton:SetHide(true);
	else
		Controls.ReligionGrid:SetOffsetY(PANEL_INFOLINE_LOCATIONS[m_CurrentPanelLine]);
		Controls.ReligionButton:SetOffsetX(PANEL_BUTTON_LOCATIONS[m_CurrentPanelLine].x);
		Controls.ReligionButton:SetOffsetY(PANEL_BUTTON_LOCATIONS[m_CurrentPanelLine].y);
		m_CurrentPanelLine = m_CurrentPanelLine + 1;
	end

	if not GameCapabilities.HasCapability("CAPABILITY_FAITH") then
		Controls.ProduceWithFaithCheck:SetHide(true);
		Controls.FaithGrid:SetHide(true);
	end

	local amenitiesNumText = data.AmenitiesNetAmount;
	if (data.AmenitiesNetAmount > 0) then
		amenitiesNumText = "+" .. amenitiesNumText;
	end
	Controls.AmenitiesNum:SetText( amenitiesNumText );
	local colorName:string = GetHappinessColor( data.Happiness );
	Controls.AmenitiesNum:SetColorByName( colorName );
	Controls.AmenitiesGrid:SetOffsetY(PANEL_INFOLINE_LOCATIONS[m_CurrentPanelLine]);
	Controls.AmenitiesButton:SetOffsetX(PANEL_BUTTON_LOCATIONS[m_CurrentPanelLine].x);
	Controls.AmenitiesButton:SetOffsetY(PANEL_BUTTON_LOCATIONS[m_CurrentPanelLine].y);
	m_CurrentPanelLine = m_CurrentPanelLine + 1;


	Controls.ReligionNum:SetText( data.ReligionFollowers );

	Controls.HousingNum:SetText( data.Population );
	colorName = GetPercentGrowthColor( data.HousingMultiplier );
	Controls.HousingNum:SetColorByName( colorName );
	Controls.HousingMax:SetText( data.Housing );
	Controls.HousingLabels:SetOffsetX(PANEL_BUTTON_LOCATIONS[m_CurrentPanelLine].x - HOUSING_LABEL_OFFSET);
	Controls.HousingGrid:SetOffsetY(PANEL_INFOLINE_LOCATIONS[m_CurrentPanelLine]);
	Controls.HousingButton:SetOffsetX(PANEL_BUTTON_LOCATIONS[m_CurrentPanelLine].x);
	Controls.HousingButton:SetOffsetY(PANEL_BUTTON_LOCATIONS[m_CurrentPanelLine].y);

	Controls.BreakdownLabel:SetHide( m_isShowingPanels );
	Controls.ReligionLabel:SetHide( m_isShowingPanels );
	Controls.AmenitiesLabel:SetHide( m_isShowingPanels );
	Controls.HousingLabel:SetHide( m_isShowingPanels );
	Controls.PanelStackShadow:SetHide( not m_isShowingPanels );
	Controls.ProductionNowLabel:SetHide( m_isShowingPanels );


	-- Determine size of progress bars at the bottom, as well as sub-panel offset.
	local OFF_BOTTOM_Y						:number = 9;
	local OFF_ROOM_FOR_PROGRESS_Y			:number = 36;
	local OFF_GROWTH_BAR_PUSH_RIGHT_X		:number = 2;
	local OFF_GROWTH_BAR_DEFAULT_RIGHT_X	:number = 32;
	local widthNumLabel				:number = 0;

	-- Growth
	Controls.GrowthTurnsSmall:SetHide( not m_isShowingPanels );
	Controls.GrowthTurns:SetHide( m_isShowingPanels );

	Controls.GrowthTurnsBar:SetPercent( data.CurrentFoodPercent );
	Controls.GrowthTurnsBar:SetShadowPercent( data.FoodPercentNextTurn );
	Controls.GrowthTurnsBarSmall:SetPercent( data.CurrentFoodPercent );
	Controls.GrowthTurnsBarSmall:SetShadowPercent( data.FoodPercentNextTurn );
	Controls.GrowthNum:SetText( math.abs(data.TurnsUntilGrowth) );
	Controls.GrowthNumSmall:SetText( math.abs(data.TurnsUntilGrowth).."[Icon_Turn]" );
	if data.Occupied then
		Controls.GrowthLabel:SetColorByName("StatBadCS");
		Controls.GrowthLabel:SetText( Locale.ToUpper( Locale.Lookup("LOC_HUD_CITY_GROWTH_OCCUPIED") ) );
	elseif data.TurnsUntilGrowth >= 0 then
		Controls.GrowthLabel:SetColorByName("StatGoodCS");
		Controls.GrowthLabel:SetText( Locale.ToUpper( Locale.Lookup("LOC_HUD_CITY_TURNS_UNTIL_GROWTH",data.TurnsUntilGrowth)) );
	else
		Controls.GrowthLabel:SetColorByName("StatBadCS");
		Controls.GrowthLabel:SetText( Locale.ToUpper( Locale.Lookup("LOC_HUD_CITY_TURNS_UNTIL_LOSS", math.abs(data.TurnsUntilGrowth))) );
	end

	widthNumLabel = Controls.GrowthNum:GetSizeX();
	TruncateStringWithTooltip(Controls.GrowthLabel, MAX_BEFORE_TRUNC_TURN_LABELS-widthNumLabel, Controls.GrowthLabel:GetText());

	--Production

	Controls.ProductionTurns:SetHide( m_isShowingPanels );
	Controls.ProductionTurnsBar:SetPercent(Clamp(data.CurrentProdPercent, 0.0, 1.0));
	Controls.ProductionTurnsBar:SetShadowPercent(Clamp(data.ProdPercentNextTurn, 0.0, 1.0));
	Controls.ProductionNum:SetText( data.CurrentTurnsLeft );
	Controls.ProductionNowLabel:SetText( data.CurrentProductionName );

	Controls.ProductionDescriptionString:SetText( data.CurrentProductionDescription );
	--Controls.ProductionDescription:SetText( "There was a young lady from Venus, who's body was shaped like a, THAT'S ENOUGH DATA." );
	if( data.CurrentProductionStats ~= "") then
		Controls.ProductionStatString:SetText( data.CurrentProductionStats );
	end
	Controls.ProductionDataStack:CalculateSize();
	Controls.ProductionDataScroll:CalculateSize();

	local isIconSet:boolean = false;
	if data.CurrentProductionIcons then
		for _,iconName in ipairs(data.CurrentProductionIcons) do
			if iconName ~= nil and Controls.ProductionIcon:TrySetIcon(iconName) then
				isIconSet = true;
				break;
			end
		end
	end
	Controls.ProductionIcon:SetHide( not isIconSet );
	Controls.ProductionNum:SetHide( data.CurrentTurnsLeft < 0 );

	if data.CurrentTurnsLeft < 0 then
		Controls.ProductionLabel:SetText( Locale.ToUpper( Locale.Lookup("LOC_HUD_CITY_NOTHING_PRODUCED")) );
		widthNumLabel = 0;
	else
		Controls.ProductionLabel:SetText( Locale.ToUpper( Locale.Lookup("LOC_HUD_CITY_TURNS_UNTIL_COMPLETED", data.CurrentTurnsLeft)) );
		widthNumLabel = Controls.ProductionNum:GetSizeX();
	end

	TruncateStringWithTooltip(Controls.ProductionLabel, MAX_BEFORE_TRUNC_TURN_LABELS-widthNumLabel, Controls.ProductionLabel:GetText());

	-- Tutorial lockdown
	if m_kTutorialDisabledControls ~= nil then
		for _,name in ipairs(m_kTutorialDisabledControls) do
			if Controls[name] ~= nil then
				Controls[name]:SetDisabled(true);
			end
		end
	end

end




-- ===========================================================================
--	Return ColorSet name
-- ===========================================================================
function GetHappinessColor( eHappiness:number )
	local happinessInfo = GameInfo.Happinesses[eHappiness];
	if (happinessInfo ~= nil) then
		if (happinessInfo.GrowthModifier < 0) then return "StatBadCS"; end
		if (happinessInfo.GrowthModifier > 0) then return "StatGoodCS"; end
	end
	return "StatNormalCS";
end

-- ===========================================================================
--	Return ColorSet name
-- ===========================================================================
function GetTurnsUntilGrowthColor( turns:number )
	if	turns < 1	then return "StatBadCS"; end
	return "StatGoodCS";
end

function GetPercentGrowthColor( percent:number )
	if percent == 0 then return "Error"; end
	if percent <= 0.25 then return "WarningMajor"; end
	if percent <= 0.5 then return "WarningMinor"; end
	return "StatNormalCS";
end


-- ===========================================================================
--	Changes the yield focus.
-- ===========================================================================
function SetYieldFocus( yieldType:number )
	local pCitizens		:table = g_pCity:GetCitizens();
	local tParameters	:table = {};
	tParameters[CityCommandTypes.PARAM_FLAGS]		= 0;			-- Set Favored
	tParameters[CityCommandTypes.PARAM_YIELD_TYPE]	= yieldType;	-- Yield type
	if pCitizens:IsFavoredYield(yieldType) then
		tParameters[CityCommandTypes.PARAM_DATA0]= 0;				-- boolean (1=true, 0=false)
	else
		if pCitizens:IsDisfavoredYield(yieldType) then
			SetYieldIgnore(yieldType);
		end
		tParameters[CityCommandTypes.PARAM_DATA0] = 1;				-- boolean (1=true, 0=false)
	end
	CityManager.RequestCommand(g_pCity, CityCommandTypes.SET_FOCUS, tParameters);
end

-- ===========================================================================
--	Changes what yield type(s) should be ignored by citizens
-- ===========================================================================
function SetYieldIgnore( yieldType:number )
	local pCitizens		:table = g_pCity:GetCitizens();
	local tParameters	:table = {};
	tParameters[CityCommandTypes.PARAM_FLAGS]		= 1;			-- Set Ignored
	tParameters[CityCommandTypes.PARAM_YIELD_TYPE]	= yieldType;	-- Yield type
	if pCitizens:IsDisfavoredYield(yieldType) then
		tParameters[CityCommandTypes.PARAM_DATA0]= 0;				-- boolean (1=true, 0=false)
	else
		if ( pCitizens:IsFavoredYield(yieldType) ) then
			SetYieldFocus(yieldType);
		end
		tParameters[CityCommandTypes.PARAM_DATA0] = 1;				-- boolean (1=true, 0=false)
	end
	CityManager.RequestCommand(g_pCity, CityCommandTypes.SET_FOCUS, tParameters);
end


-- ===========================================================================
--	Update both the data & view for the selected city.
-- ===========================================================================
function Refresh()
	local eLocalPlayer :number = Game.GetLocalPlayer();
	m_pPlayer= Players[eLocalPlayer];
	g_pCity	 = UI.GetHeadSelectedCity();

	if m_pPlayer ~= nil and g_pCity ~= nil then
		m_kData = GetCityData( g_pCity );
		if m_kData == nil then
			return;
		end

		ViewMain( m_kData );

		-- Tell others (e.g., CityPanelOverview) that the selected city data has changed.
		-- Passing this large table across contexts via LuaEvent is *much*
		-- more effecient than recomputing the entire set of yields a second time,
		-- despite the large size.
		LuaEvents.CityPanel_LiveCityDataChanged( m_kData, true );
	end
end


-- ===========================================================================
function RefreshIfMatch( ownerPlayerID:number, cityID:number )
	if g_pCity ~= nil and ownerPlayerID == g_pCity:GetOwner() and cityID == g_pCity:GetID() then
		Refresh();
	end
end

-- ===========================================================================
--	GAME Event
-- ===========================================================================
function OnCityAddedToMap( ownerPlayerID:number, cityID:number )
	if Game.GetLocalPlayer() ~= nil then
		if ownerPlayerID == Game.GetLocalPlayer() then
			local pSelectedCity:table = UI.GetHeadSelectedCity();
			if pSelectedCity ~= nil then
				Refresh();
			else
				UI.DeselectAllCities();
			end
		end
	end
end

function OnCityNameChanged( playerID:number, cityID:number )
	local city = UI.GetHeadSelectedCity();
	if(city and city:GetOwner() == playerID and city:GetID() == cityID) then
		local name = city:IsCapital() and "[ICON_Capital]" or "";
		name = name .. Locale.ToUpper(Locale.Lookup(city:GetName()));
		Controls.CityName:SetText(name);
	end
end

-- ===========================================================================
--	GAME Event
--	Yield changes
-- ===========================================================================
function OnCityFocusChange(ownerPlayerID:number, cityID:number)
	RefreshIfMatch(ownerPlayerID, cityID);
end

-- ===========================================================================
--	GAME Event
-- ===========================================================================
function OnCityWorkerChanged(ownerPlayerID:number, cityID:number)
	RefreshIfMatch(ownerPlayerID, cityID);
end

-- ===========================================================================
--	GAME Event
-- ===========================================================================
function OnCityProductionChanged(ownerPlayerID:number, cityID:number)
    -- CUI
    if Controls.ChangeProductionCheck:IsChecked() then
        Controls.ChangeProductionCheck:SetCheck(false)
    end
    --
	RefreshIfMatch(ownerPlayerID, cityID);
end

-- ===========================================================================
--	GAME Event
-- ===========================================================================
function OnCityProductionCompleted(ownerPlayerID:number, cityID:number)
	RefreshIfMatch(ownerPlayerID, cityID);
end

-- ===========================================================================
--	GAME Event
-- ===========================================================================
function OnCityProductionUpdated( ownerPlayerID:number, cityID:number, eProductionType, eProductionObject)
	RefreshIfMatch(ownerPlayerID, cityID);
end

-- ===========================================================================
--	GAME Event
-- ===========================================================================
function OnPlayerResourceChanged( ownerPlayerID:number, resourceTypeID:number)
	if (Game.GetLocalPlayer() ~= nil and ownerPlayerID == Game.GetLocalPlayer()) then
		Refresh();
	end
end

-- ===========================================================================
--	GAME Event
-- ===========================================================================
function OnToggleOverviewPanel()
	if Controls.ToggleOverviewPanel:IsChecked() then
		LuaEvents.CityPanel_ShowOverviewPanel(true);
	else
		LuaEvents.CityPanel_ShowOverviewPanel(false);
	end
end

-- ===========================================================================
function OnCitySelectionChanged( ownerPlayerID:number, cityID:number, i:number, j:number, k:number, isSelected:boolean, isEditable:boolean)
	if ownerPlayerID == Game.GetLocalPlayer() then
		if (isSelected) then
			-- Determine if we should switch to the SELECTION interface mode
			local shouldSwitchToSelection:boolean = UI.GetInterfaceMode() ~= InterfaceModeTypes.CITY_SELECTION;
			if UI.GetInterfaceMode() == InterfaceModeTypes.CITY_MANAGEMENT then
				HideGrowthTile();
				shouldSwitchToSelection = false;
			end
			if UI.GetInterfaceMode() == InterfaceModeTypes.ICBM_STRIKE then
				-- During ICBM_STRIKE only switch to SELECTION if we're selecting a city
				-- which doesn't own the active missile silo
				local siloPlotX:number = UI.GetInterfaceModeParameter(CityCommandTypes.PARAM_X0);
				local siloPlotY:number = UI.GetInterfaceModeParameter(CityCommandTypes.PARAM_Y0);
				local siloPlot:table = Map.GetPlot(siloPlotX, siloPlotY);
				if siloPlot then
					local owningCity = Cities.GetPlotPurchaseCity(siloPlot);
					if owningCity:GetID() == cityID then
						shouldSwitchToSelection = false;
					end
				end
			end
			if UI.GetInterfaceMode() == InterfaceModeTypes.CITY_RANGE_ATTACK then
				-- During CITY_RANGE_ATTACK only switch to SELECTION if we're selecting a city
				-- which can't currently perform a ranged attack
				if CityManager.CanStartCommand( CityManager.GetCity(owningPlayerID, cityID), CityCommandTypes.RANGE_ATTACK ) then
						shouldSwitchToSelection = false;
						--we switch to selection mode briefly so that we can go back into CITY_RANGE_ATTACK with the correct settings
						UI.SetInterfaceMode(InterfaceModeTypes.SELECTION);
						UI.SetInterfaceMode(InterfaceModeTypes.CITY_RANGE_ATTACK);
				end
			end
			if shouldSwitchToSelection then
				UI.SetInterfaceMode(InterfaceModeTypes.SELECTION);
			end

			OnToggleOverviewPanel();
			ContextPtr:SetHide(false);

			-- Handle case where production panel is opened from clicking a city banener directly.
			local isProductionOpen:boolean = false;
			local uiProductionPanel:table = ContextPtr:LookUpControl("/InGame/ProductionPanel");
			if uiProductionPanel and uiProductionPanel:IsHidden()==false then
				isProductionOpen = true;
			end
			if isProductionOpen then
				AnimateToWithProductionQueue();
			else
				AnimateFromCloseToOpen();
			end


			Refresh();
			if UI.GetInterfaceMode() == InterfaceModeTypes.CITY_MANAGEMENT then
				DisplayGrowthTile();
			end
		else
			Close();
			-- Tell the CityPanelOverview a city was deselected
			LuaEvents.CityPanel_LiveCityDataChanged( nil, false );
		end
	end
end

-- ===========================================================================
function AnimateFromCloseToOpen()
	Controls.CityPanelAlpha:SetToBeginning();
	Controls.CityPanelAlpha:Play();
	Controls.CityPanelSlide:SetBeginVal(0,0);
	Controls.CityPanelSlide:SetEndVal(ANIM_OFFSET_OPEN,0);
	Controls.CityPanelSlide:SetToBeginning();
	Controls.CityPanelSlide:Play();
end

-- ===========================================================================
function AnimateToWithProductionQueue()
	if IsRoomToPushOutPanel() then
		Controls.CityPanelSlide:SetEndVal(ANIM_OFFSET_OPEN_WITH_PRODUCTION_LIST,0);
		Controls.CityPanelSlide:RegisterEndCallback( function() Controls.CityPanelSlide:SetBeginVal(ANIM_OFFSET_OPEN_WITH_PRODUCTION_LIST,0); end );
		Controls.CityPanelSlide:SetToBeginning();
		Controls.CityPanelSlide:Play();
	end
end

-- ===========================================================================
function AnimateToOpenFromWithProductionQueue()
	if IsRoomToPushOutPanel() then
		Controls.CityPanelSlide:SetEndVal(ANIM_OFFSET_OPEN,0);
		Controls.CityPanelSlide:RegisterEndCallback( function() Controls.CityPanelSlide:SetBeginVal(ANIM_OFFSET_OPEN,0); end );
		Controls.CityPanelSlide:SetToBeginning();
		Controls.CityPanelSlide:Play();
	end
end

-- ===========================================================================
--	Is there enough room to push out the CityPanel, rather than just have
--	the production list overlap it?
-- ===========================================================================
function IsRoomToPushOutPanel()
	local width, height	= UIManager:GetScreenSizeVal();
	-- Minimap showing; subtract how much space it takes up
	local uiMinimap:table = ContextPtr:LookUpControl("/InGame/MinimapPanel/MinimapContainer");
	if uiMinimap then
		local minimapWidth, minimapHeight = uiMinimap:GetSizeVal();
		width = width - minimapWidth;
	end
	return ( width > 850);	-- Does remaining width have enough space for both?
end

-- ===========================================================================
--	GAME Event
-- ===========================================================================
function OnUnitSelectionChanged( playerID:number, unitID:number, hexI:number, hexJ:number, hexK:number, isSelected:boolean, isEditable:boolean )
	if playerID == Game.GetLocalPlayer() then
		if ContextPtr:IsHidden()==false then
			Close();
			Controls.ToggleOverviewPanel:SetAndCall(false);
		end
	end
end

-- ===========================================================================
function LateInitialize()
	-- Override in DLC, Expansion, and MODs for special initialization.
end

-- ===========================================================================
--	UI Event
-- ===========================================================================
function OnInit( isHotload:boolean )
	LateInitialize();
	if isHotload then
		LuaEvents.GameDebug_GetValues( "CityPanel");
	end
	m_isInitializing = false;
	Refresh();
end

-- ===========================================================================
--	UI EVENT
-- ===========================================================================
function OnShutdown()
	-- Cache values for hotloading...
	LuaEvents.GameDebug_AddValue("CityPanel", "isHidden",				ContextPtr:IsHidden() );

	-- Game Core Events
	Events.CityAddedToMap.Remove(			OnCityAddedToMap );
	Events.CityNameChanged.Remove(			OnCityNameChanged );
	Events.CitySelectionChanged.Remove(		OnCitySelectionChanged );
	Events.CityFocusChanged.Remove(			OnCityFocusChange );
	Events.CityProductionCompleted.Remove(	OnCityProductionCompleted );
	Events.CityProductionUpdated.Remove(	OnCityProductionUpdated );
	Events.CityProductionChanged.Remove(	OnCityProductionChanged );
	Events.CityWorkerChanged.Remove(		OnCityWorkerChanged );
	Events.DistrictDamageChanged.Remove(	OnCityProductionChanged );
	Events.LocalPlayerTurnBegin.Remove(		OnLocalPlayerTurnBegin );
	Events.ImprovementChanged.Remove(		OnCityProductionChanged );
	Events.InterfaceModeChanged.Remove(		OnInterfaceModeChanged );
	Events.LocalPlayerChanged.Remove(		OnLocalPlayerChanged );
	Events.PlayerResourceChanged.Remove(	OnPlayerResourceChanged );
	Events.UnitSelectionChanged.Remove(		OnUnitSelectionChanged );

	-- LUA Events
	LuaEvents.CityPanelOverview_CloseButton.Remove(		OnCloseOverviewPanel );
	LuaEvents.CityPanel_SetOverViewState.Remove(		OnCityPanelSetOverViewState );
	LuaEvents.CityPanel_ToggleManageCitizens.Remove(	OnCityPanelToggleManageCitizens );
	LuaEvents.GameDebug_Return.Remove(					OnGameDebugReturn );
	LuaEvents.ProductionPanel_Close.Remove(				OnProductionPanelClose );
	LuaEvents.ProductionPanel_ListModeChanged.Remove(	OnProductionPanelListModeChanged );
	LuaEvents.ProductionPanel_Open.Remove(				OnProductionPanelOpen );
	LuaEvents.Tutorial_CityPanelOpen.Remove(			OnTutorialOpen );
	LuaEvents.Tutorial_ContextDisableItems.Remove(		OnTutorial_ContextDisableItems );
end

-- ===========================================================================
--	LUA Event
--	Set cached values back after a hotload.
-- ===========================================================================
function OnGameDebugReturn( context:string, contextTable:table )
	function RunWithNoError()
		if context ~= "CityPanel" or contextTable == nil then
			return;
		end
		local isHidden:boolean = contextTable["isHidden"];
		ContextPtr:SetHide( isHidden );
	end
	pcall( RunWithNoError );
end

-- ===========================================================================
--	LUA Event
-- ===========================================================================
function OnProductionPanelClose()
	-- If no longer checked, make sure the side Production Panel closes.
	-- Clear the checks, even if hidden, the Production Pane can close after the City Panel has already been closed.
	Controls.ChangeProductionCheck:SetCheck( false );
	Controls.ProduceWithFaithCheck:SetCheck( false );
	Controls.ProduceWithGoldCheck:SetCheck( false );

	AnimateToOpenFromWithProductionQueue();
end

-- ===========================================================================
--	LUA Event
-- ===========================================================================
function OnProductionPanelOpen()
	AnimateToWithProductionQueue();
end

-- ===========================================================================
--	LUA Event
-- ===========================================================================
function OnTutorialOpen()
	ContextPtr:SetHide(false);
	Refresh();
end



-- ===========================================================================
function OnBreakdown()
	LuaEvents.CityPanel_ShowBreakdownTab();
end

-- ===========================================================================
function OnReligion()
	LuaEvents.CityPanel_ShowReligionTab();
end

-- ===========================================================================
function OnAmenities()
	LuaEvents.CityPanel_ShowAmenitiesTab();
end

-- ===========================================================================
function OnHousing()
	LuaEvents.CityPanel_ShowHousingTab();
end

-- ===========================================================================
--function OnCheckQueue()
--	if m_isInitializing then return; end
--	if not m_debugAllowMultiPanel then
--		UILens.ToggleLayerOff("Adjacency_Bonus_Districts");
--		UILens.ToggleLayerOff("Districts");
--	end
--	Refresh();
--end

-- ===========================================================================
function OnCitizensGrowth()
	LuaEvents.CityPanel_ShowCitizensTab();
end


-- ===========================================================================
--	Set a yield to one of 3 check states.
--	yieldType	Enum from game engine on the yield
--	yieldName	Name of the yield used in the UI controls
-- ===========================================================================
function OnCheckYield( yieldType:number, yieldName:string )
	if Controls.YieldsArea:IsDisabled() then return; end	-- Via tutorial event
	if Controls[yieldName.."Check"]:IsChecked() then
		SetYieldFocus( yieldType );
	else
		SetYieldIgnore( yieldType );
		Controls[yieldName.."Ignore"]:SetHide( false );
		Controls[yieldName.."Check"]:SetDisabled( true );
	end
end

-- ===========================================================================
--	Reset a yield to not be favored nor ignored
--	yieldType	Enum from game engine on the yield
--	yieldName	Name of the yield used in the UI controls
-- ===========================================================================
function OnResetYieldToNormal( yieldType:number, yieldName:string )
	if Controls.YieldsArea:IsDisabled() then return; end	-- Via tutorial event
	Controls[yieldName.."Ignore"]:SetHide( true );
	Controls[yieldName.."Check"]:SetDisabled( false );
	SetYieldIgnore( yieldType );		-- One more ignore to flip it off
end

-- ===========================================================================
--	Cycle to the next city
-- ===========================================================================
function OnNextCity()
	local kCity:table = UI.GetHeadSelectedCity();
	UI.SelectNextCity(kCity);
	UI.PlaySound("UI_Click_Sweetener_Metal_Button_Small");
end

-- ===========================================================================
--	Cycle to the previous city
-- ===========================================================================
function OnPreviousCity()
	local kCity:table = UI.GetHeadSelectedCity();
	UI.SelectPrevCity(kCity);
	UI.PlaySound("UI_Click_Sweetener_Metal_Button_Small");
end

-- ===========================================================================
--	Recenter camera on city
-- ===========================================================================
function RecenterCameraOnCity()
	local kCity:table = UI.GetHeadSelectedCity();
	UI.LookAtPlot( kCity:GetX(), kCity:GetY() );
end

-- CUI =======================================================================
-- combine purchase tile and manage cityzens
function CuiOnToggleManageTile()
    if Controls.ManageTileCheck:IsChecked() then
        UI.SetInterfaceMode(InterfaceModeTypes.CITY_MANAGEMENT)
        CuiForceHideCityBanner()
        RecenterCameraOnCity()
        UILens.ToggleLayerOn(m_CitizenManagement)
        if GameCapabilities.HasCapability("CAPABILITY_GOLD") then
            UILens.ToggleLayerOn(m_PurchasePlot)
        end
    else
        UI.SetInterfaceMode(InterfaceModeTypes.SELECTION)
        CuiForceShowCityBanner()
        UILens.ToggleLayerOff(m_CitizenManagement)
        UILens.ToggleLayerOff(m_PurchasePlot)
    end
end

-- ===========================================================================
--	Turn on/off layers and switch the interface mode based on what is checked.
--	Interface mode is changed first as the Lens system may inquire as to the
--	current state in deciding what is populate in a lens layer.
-- ===========================================================================
function OnTogglePurchaseTile()
	if Controls.PurchaseTileCheck:IsChecked() then
		if not Controls.ManageCitizensCheck:IsChecked() then
			m_PrevInterfaceMode = UI.GetInterfaceMode();
			UI.SetInterfaceMode(InterfaceModeTypes.CITY_MANAGEMENT);	-- Enter mode
		end
		RecenterCameraOnCity();
		UILens.ToggleLayerOn( m_PurchasePlot );
	else
		if not Controls.ManageCitizensCheck:IsChecked() and UI.GetInterfaceMode() == InterfaceModeTypes.CITY_MANAGEMENT then
			UI.SetInterfaceMode(m_PrevInterfaceMode);			-- Exit mode
			m_PrevInterfaceMode = InterfaceModeTypes.SELECTION;
		end
		UILens.ToggleLayerOff( m_PurchasePlot );
	end
end

-- ===========================================================================
function OnToggleProduction()
	if Controls.ChangeProductionCheck:IsChecked() then
		RecenterCameraOnCity();
		LuaEvents.CityPanel_ProductionOpen();
        -- CUI
        Controls.ProduceWithFaithCheck:SetCheck(false)
        Controls.ProduceWithGoldCheck:SetCheck(false)
        --
	else
		LuaEvents.CityPanel_ProductionClose();
	end
end

-- ===========================================================================
function OnTogglePurchaseWithGold()
    if Controls.ProduceWithGoldCheck:IsChecked() then
		RecenterCameraOnCity();
		LuaEvents.CityPanel_PurchaseGoldOpen();
        -- CUI
        Controls.ChangeProductionCheck:SetCheck(false)
        Controls.ProduceWithFaithCheck:SetCheck(false)
        --
	else
		LuaEvents.CityPanel_ProductionClose();
	end
end

-- ===========================================================================
function OnTogglePurchaseWithFaith()
    if Controls.ProduceWithFaithCheck:IsChecked() then
		RecenterCameraOnCity();
		LuaEvents.CityPanel_PurchaseFaithOpen();
        -- CUI
        Controls.ChangeProductionCheck:SetCheck(false)
        Controls.ProduceWithGoldCheck:SetCheck(false)
        --
	else
		LuaEvents.CityPanel_ProductionClose();
	end
end

-- ===========================================================================
function OnCloseOverviewPanel()
	Controls.ToggleOverviewPanel:SetCheck(false);
end

-- ===========================================================================
--	Turn on/off layers and switch the interface mode based on what is checked.
--	Interface mode is changed first as the Lens system may inquire as to the
--	current state in deciding what is populate in a lens layer.
-- ===========================================================================
function OnToggleManageCitizens()
	if Controls.ManageCitizensCheck:IsChecked() then
		if not Controls.PurchaseTileCheck:IsChecked() then
			m_PrevInterfaceMode = UI.GetInterfaceMode();
			UI.SetInterfaceMode(InterfaceModeTypes.CITY_MANAGEMENT);	-- Enter mode
		end
		RecenterCameraOnCity();
		UILens.ToggleLayerOn( m_CitizenManagement );
	else
		if not Controls.PurchaseTileCheck:IsChecked() and UI.GetInterfaceMode() == InterfaceModeTypes.CITY_MANAGEMENT then
			UI.SetInterfaceMode(m_PrevInterfaceMode);			-- Exit mode
			m_PrevInterfaceMode = InterfaceModeTypes.SELECTION;
		end
		UILens.ToggleLayerOff( m_CitizenManagement );
	end
end

-- ===========================================================================
function OnLocalPlayerTurnBegin()
	Refresh();
end

-- ===========================================================================
--	Enable a control unless it's in the tutorial lock down list.
-- ===========================================================================
function EnableIfNotTutorialBlocked( controlName:string )
	local isDisabled :boolean = false;
	if m_kTutorialDisabledControls ~= nil then
		for _,name in ipairs(m_kTutorialDisabledControls) do
			if name == controlName then
				isDisabled = true;
				break;
			end
		end
	end
	Controls[ controlName ]:SetDisabled( isDisabled );
end

function OnCameraUpdate( vFocusX:number, vFocusY:number, fZoomLevel:number )
	if g_growthPlotId ~= -1 then

		if fZoomLevel and fZoomLevel > 0.5 then
			local delta:number = (fZoomLevel - 0.3);
			local alpha:number = delta / 0.7;
			Controls.GrowthHexAlpha:SetProgress(alpha);
		else
			Controls.GrowthHexAlpha:SetProgress(0);
		end

		local plotX:number, plotY:number = Map.GetPlotLocation(g_growthPlotId);
		local worldX:number, worldY:number, worldZ:number = UI.GridToWorld(plotX, plotY);
		Controls.GrowthHexAnchor:SetWorldPositionVal(worldX, worldY + HEX_GROWTH_TEXT_PADDING, worldZ);
	end
end

function DisplayGrowthTile()
	if g_pCity ~= nil and HasCapability("CAPABILITY_CULTURE") then
		local cityCulture:table = g_pCity:GetCulture();
		if cityCulture ~= nil then
			local newGrowthPlot:number = cityCulture:GetNextPlot();
			if(newGrowthPlot ~= -1 and newGrowthPlot ~= g_growthPlotId) then
				g_growthPlotId = newGrowthPlot;

				local cost:number = cityCulture:GetNextPlotCultureCost();
				local currentCulture:number = cityCulture:GetCurrentCulture();
				local currentYield:number = cityCulture:GetCultureYield();
				local currentGrowth:number = math.max(math.min(currentCulture / cost, 1.0), 0);
				local nextTurnGrowth:number = math.max(math.min((currentCulture + currentYield) / cost, 1.0), 0);

				UILens.SetLayerGrowthHex(m_PurchasePlot, Game.GetLocalPlayer(), g_growthPlotId, 1, "GrowthHexBG");
				UILens.SetLayerGrowthHex(m_PurchasePlot, Game.GetLocalPlayer(), g_growthPlotId, nextTurnGrowth, "GrowthHexNext");
				UILens.SetLayerGrowthHex(m_PurchasePlot, Game.GetLocalPlayer(), g_growthPlotId, currentGrowth, "GrowthHexCurrent");

				local turnsRemaining:number = cityCulture:GetTurnsUntilExpansion();
				Controls.TurnsLeftDescription:SetText(Locale.ToUpper(Locale.Lookup("LOC_HUD_CITY_TURNS_UNTIL_BORDER_GROWTH", turnsRemaining)));
				Controls.TurnsLeftLabel:SetText(turnsRemaining);
				Controls.GrowthHexStack:CalculateSize();
				g_growthHexTextWidth = Controls.GrowthHexStack:GetSizeX();

				Events.Camera_Updated.Add(OnCameraUpdate);
				Events.CityMadePurchase.Add(OnCityMadePurchase);
				Controls.GrowthHexAnchor:SetHide(false);
				OnCameraUpdate();
			end
		end
	end
end

function HideGrowthTile()
	if g_growthPlotId ~= -1 then
		Controls.GrowthHexAnchor:SetHide(true);
		Events.Camera_Updated.Remove(OnCameraUpdate);
		Events.CityMadePurchase.Remove(OnCityMadePurchase);
		UILens.ClearHex(m_PurchasePlot, g_growthPlotId);
		g_growthPlotId = -1;
	end
end

function OnCityMadePurchase(owner:number, cityID:number, plotX:number, plotY:number, purchaseType, objectType)
	if g_growthPlotId ~= -1 then
		local growthPlotX:number, growthPlotY:number = Map.GetPlotLocation(g_growthPlotId);

		if (growthPlotX == plotX and growthPlotY == plotY) then
			HideGrowthTile();
			DisplayGrowthTile();
		end
	end
end

-- ===========================================================================
function OnProductionPanelListModeChanged( listMode:number )
	Controls.ChangeProductionCheck:SetCheck(listMode == LISTMODE.PRODUCTION or listMode == LISTMODE.PROD_QUEUE);
	Controls.ProduceWithGoldCheck:SetCheck(listMode == LISTMODE.PURCHASE_GOLD);
	Controls.ProduceWithFaithCheck:SetCheck(listMode == LISTMODE.PURCHASE_FAITH);
end

-- ===========================================================================
function OnCityPanelSetOverViewState( isOpened:boolean )
	Controls.ToggleOverviewPanel:SetCheck(isOpened);
end

-- ===========================================================================
function OnCityPanelToggleManageCitizens()
	Controls.ManageCitizensCheck:SetAndCall(not Controls.ManageCitizensCheck:IsChecked());
end

-- ===========================================================================
--	GAME Event
--	eOldMode, mode the engine was formally in
--	eNewMode, new mode the engine has just changed to
-- ===========================================================================
function OnInterfaceModeChanged( eOldMode:number, eNewMode:number )

	if eOldMode == InterfaceModeTypes.CITY_MANAGEMENT then
        -- CUI: combine buttons.
        if Controls.ManageTileCheck:IsChecked() then
            Controls.ManageTileCheck:SetAndCall(false)
        end
        -- if Controls.PurchaseTileCheck:IsChecked()   then Controls.PurchaseTileCheck:SetAndCall( false ); end
        -- if Controls.ManageCitizensCheck:IsChecked() then Controls.ManageCitizensCheck:SetAndCall( false ); end
        --
		UI.SetFixedTiltMode( false );
		HideGrowthTile();
	elseif eOldMode == InterfaceModeTypes.DISTRICT_PLACEMENT or eOldMode == InterfaceModeTypes.BUILDING_PLACEMENT then
		HideGrowthTile();
	end

	if eNewMode == InterfaceModeTypes.CITY_MANAGEMENT then
		DisplayGrowthTile();
	end

	if eNewMode == InterfaceModeTypes.CITY_RANGE_ATTACK or eNewMode == InterfaceModeTypes.DISTRICT_RANGE_ATTACK then
		if ContextPtr:IsHidden()==false then
			Close();
		end
	elseif eOldMode == InterfaceModeTypes.CITY_RANGE_ATTACK or eOldMode == InterfaceModeTypes.DISTRICT_RANGE_ATTACK then
		-- If we leave CITY_RANGE_ATTACK with a city selected then show the city panel again
		if UI.GetHeadSelectedCity() then
			ContextPtr:SetHide(false);
		end
	end

	if eNewMode == InterfaceModeTypes.SELECTION or eNewMode == InterfaceModeTypes.CITY_MANAGEMENT then
        -- CUI: combine buttons.
        EnableIfNotTutorialBlocked("ManageTileCheck")
        -- EnableIfNotTutorialBlocked("PurchaseTileCheck");
        -- EnableIfNotTutorialBlocked("ManageCitizensCheck");
        --
		EnableIfNotTutorialBlocked("ProduceWithFaithCheck");
		EnableIfNotTutorialBlocked("ProduceWithGoldCheck");
		EnableIfNotTutorialBlocked("ChangeProductionCheck");

	elseif eNewMode == InterfaceModeTypes.DISTRICT_PLACEMENT then
        -- CUI: combine buttons.
        Controls.ManageTileCheck:SetDisabled(true)
        -- Controls.PurchaseTileCheck:SetDisabled( true );
        -- Controls.ManageCitizensCheck:SetDisabled( true );
        --
		Controls.ChangeProductionCheck:SetDisabled( true );
		Controls.ProduceWithFaithCheck:SetDisabled( true );
		Controls.ProduceWithGoldCheck:SetDisabled( true );
		local newGrowthPlot:number = g_pCity:GetCulture():GetNextPlot();	--show the growth tile if the district can be placed there
		if(newGrowthPlot ~= -1) then
			local districtHash:number	= UI.GetInterfaceModeParameter(CityOperationTypes.PARAM_DISTRICT_TYPE);
			local district:table		= GameInfo.Districts[districtHash];
			local kPlot		:table			= Map.GetPlotByIndex(newGrowthPlot);
			if kPlot:CanHaveDistrict(district.Index, g_pCity:GetOwner(), g_pCity:GetID()) then
				DisplayGrowthTile();
			end
		end

	elseif eNewMode == InterfaceModeTypes.BUILDING_PLACEMENT then
		local newGrowthPlot:number = g_pCity:GetCulture():GetNextPlot();
		if(newGrowthPlot ~= -1) then
			local buildingHash :number = UI.GetInterfaceModeParameter(CityOperationTypes.PARAM_BUILDING_TYPE);
			local building = GameInfo.Buildings[buildingHash];
			local kPlot		:table			= Map.GetPlotByIndex(newGrowthPlot);
			if kPlot:CanHaveWonder(building.Index, g_pCity:GetOwner(), g_pCity:GetID()) then
				DisplayGrowthTile();
			end
		end
	end

	if not ContextPtr:IsHidden() then
		ViewMain( m_kData );
	end
end


-- ===========================================================================
--	Engine EVENT
--	Local player changed; likely a hotseat game
-- ===========================================================================
function OnLocalPlayerChanged( eLocalPlayer:number , ePrevLocalPlayer:number )
	if eLocalPlayer == -1 then
		m_pPlayer = nil;
		return;
	end
	m_pPlayer = Players[eLocalPlayer];
	if ContextPtr:IsHidden()==false then
		Close();
	end
end


-- ===========================================================================
--	Show/hide an area based on the status of a checkbox control
--	checkBoxControl		A checkbox control that when selected is open
--	buttonControl		(optional) button control that toggles the state
--	areaControl			The area to be shown/hidden
--	kParentControls		DEPRECATED, not needed
-- ===========================================================================
function SetupCollapsibleToggle( pCheckBoxControl:table, pButtonControl:table, pAreaControl:table, kParentControls:table )
	pCheckBoxControl:RegisterCheckHandler(
		function()
			pAreaControl:SetHide( pCheckBoxControl:IsChecked() );
		end
	);
	if pButtonControl ~= nil then
		pButtonControl:RegisterCallback( Mouse.eLClick,
			function()
				pCheckBoxControl:SetAndCall( not pCheckBoxControl:IsChecked() );
			end
		);
	end
end


-- ===========================================================================
--	LUA Event
--	Tutorial requests controls that should always be locked down.
--	Send nil to clear.
-- ===========================================================================
function OnTutorial_ContextDisableItems( contextName:string, kIdsToDisable:table )

	if contextName~="CityPanel" then return; end

	-- Enable any existing controls that are disabled
	if m_kTutorialDisabledControls ~= nil then
		for _,name in ipairs(m_kTutorialDisabledControls) do
			if Controls[name] ~= nil then
				Controls[name]:SetDisabled(false);
			end
		end
	end

	m_kTutorialDisabledControls = kIdsToDisable;

	-- Immediate set disabled
	if m_kTutorialDisabledControls ~= nil then
		for _,name in ipairs(m_kTutorialDisabledControls) do
			if Controls[name] ~= nil then
				Controls[name]:SetDisabled(true);
			else
				UI.DataError("Tutorial requested the control '"..name.."' be disabled in the city panel, but no such control exists in that context.");
			end
		end
	end
end

-- CUI =======================================================================
function CuiGetFoodToolTip(data)
    local foodToolTip =
    -- vanila tooltip
    data.FoodPerTurnToolTip ..
    "[NEWLINE][NEWLINE]" ..
    -- food consumption
    toPlusMinusString(-(data.FoodPerTurn - data.FoodSurplus)) ..
    " " ..
    Locale.Lookup("LOC_HUD_CITY_FOOD_CONSUMPTION") ..
    "[NEWLINE]------------------[NEWLINE]" ..
    -- happiness
    GetColorPercentString(1 + data.HappinessGrowthModifier / 100, 2) ..
    " " ..
    Locale.Lookup("LOC_HUD_CITY_HAPPINESS_GROWTH_BONUS") ..
    "[NEWLINE]" ..
    -- other
    GetColorPercentString(1 + Round(data.OtherGrowthModifiers, 2), 2) ..
    " " ..
    Locale.Lookup("LOC_HUD_CITY_OTHER_GROWTH_BONUSES") ..
    "[NEWLINE]" .. -- housing
    GetColorPercentString(data.HousingMultiplier, 2) ..
    " " .. Locale.Lookup("LOC_HUD_CITY_HOUSING_CAPACITY")

    if data.Occupied then
        foodToolTip =
            foodToolTip ..
            "[NEWLINE]" .. "x" .. data.OccupationMultiplier .. Locale.Lookup("LOC_HUD_CITY_OCCUPATION_MULTIPLIER")
    end
    return foodToolTip
end

-- CUI =======================================================================
function CuiForceHideCityBanner()
    CuiSettings:SetBoolean(CuiSettings.SHOW_CITYS, false)
    ContextPtr:LookUpControl("/InGame/CityBannerManager"):SetHide(true)
    LuaEvents.MinimapPanel_RefreshMinimapOptions()
end

-- CUI =======================================================================
function CuiForceShowCityBanner()
    CuiSettings:SetBoolean(CuiSettings.SHOW_CITYS, true)
    ContextPtr:LookUpControl("/InGame/CityBannerManager"):SetHide(false)
    LuaEvents.MinimapPanel_RefreshMinimapOptions()
end

-- ===========================================================================
--	CTOR
-- ===========================================================================
function Initialize()

	LuaEvents.CityPanel_OpenOverview();

	m_isInitializing = true;

	-- Context Events
	ContextPtr:SetInitHandler( OnInit );
	ContextPtr:SetShutdown( OnShutdown );

	-- Control Events
	Controls.BreakdownButton:RegisterCallback(		Mouse.eLClick,	OnBreakdown );
	Controls.ReligionButton:RegisterCallback(		Mouse.eLClick,	OnReligion );
	Controls.AmenitiesButton:RegisterCallback(		Mouse.eLClick,	OnAmenities );
	Controls.HousingButton:RegisterCallback(		Mouse.eLClick,	OnHousing );
	Controls.CitizensGrowthButton:RegisterCallback(	Mouse.eLClick,	OnCitizensGrowth );

	Controls.CultureCheck:RegisterCheckHandler(					function() OnCheckYield( YieldTypes.CULTURE,	"Culture"); end );
	Controls.FaithCheck:RegisterCheckHandler(					function() OnCheckYield( YieldTypes.FAITH,		"Faith"); end );
	Controls.FoodCheck:RegisterCheckHandler(					function() OnCheckYield( YieldTypes.FOOD,		"Food"); end );
	Controls.GoldCheck:RegisterCheckHandler(					function() OnCheckYield( YieldTypes.GOLD,		"Gold"); end );
	Controls.ProductionCheck:RegisterCheckHandler(				function() OnCheckYield( YieldTypes.PRODUCTION, "Production"); end );
	Controls.ScienceCheck:RegisterCheckHandler(					function() OnCheckYield( YieldTypes.SCIENCE,	"Science"); end );
	Controls.CultureIgnore:RegisterCallback(	Mouse.eLClick,	function() OnResetYieldToNormal( YieldTypes.CULTURE,	"Culture"); end);
	Controls.FaithIgnore:RegisterCallback(		Mouse.eLClick,	function() OnResetYieldToNormal( YieldTypes.FAITH,		"Faith"); end);
	Controls.FoodIgnore:RegisterCallback(		Mouse.eLClick,	function() OnResetYieldToNormal( YieldTypes.FOOD,		"Food"); end);
	Controls.GoldIgnore:RegisterCallback(		Mouse.eLClick,	function() OnResetYieldToNormal( YieldTypes.GOLD,		"Gold"); end);
	Controls.ProductionIgnore:RegisterCallback(	Mouse.eLClick,	function() OnResetYieldToNormal( YieldTypes.PRODUCTION,	"Production"); end);
	Controls.ScienceIgnore:RegisterCallback(	Mouse.eLClick,	function() OnResetYieldToNormal( YieldTypes.SCIENCE,	"Science"); end);
	Controls.NextCityButton:RegisterCallback(	Mouse.eLClick,	OnNextCity);
	Controls.PrevCityButton:RegisterCallback(	Mouse.eLClick,	OnPreviousCity);


	if GameCapabilities.HasCapability("CAPABILITY_GOLD") then
        -- CUI: combine buttons.
        -- Controls.PurchaseTileCheck:RegisterCheckHandler(OnTogglePurchaseTile );
        -- Controls.PurchaseTileCheck:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
        --
		Controls.ProduceWithGoldCheck:RegisterCheckHandler( OnTogglePurchaseWithGold );
		Controls.ProduceWithGoldCheck:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
	else
		Controls.PurchaseTileCheck:SetHide(true);
		Controls.ProduceWithGoldCheck:SetHide(true);
	end

    -- CUI: combine buttons.
    Controls.ManageTileCheck:RegisterCheckHandler(CuiOnToggleManageTile)
    Controls.ManageTileCheck:RegisterCallback(
        Mouse.eMouseEnter,
        function()
            UI.PlaySound("Main_Menu_Mouse_Over")
        end
    )
    -- Controls.ManageCitizensCheck:RegisterCheckHandler(    OnToggleManageCitizens );
    -- Controls.ManageCitizensCheck:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
    --
	Controls.ChangeProductionCheck:RegisterCheckHandler( OnToggleProduction );
	Controls.ChangeProductionCheck:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
	Controls.ProduceWithFaithCheck:RegisterCheckHandler( OnTogglePurchaseWithFaith );
	Controls.ProduceWithFaithCheck:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
	Controls.ToggleOverviewPanel:RegisterCheckHandler( OnToggleOverviewPanel );
	Controls.ToggleOverviewPanel:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);

	-- Game Core Events
	Events.CityAddedToMap.Add(			OnCityAddedToMap );
	Events.CityNameChanged.Add(			OnCityNameChanged );
	Events.CitySelectionChanged.Add(	OnCitySelectionChanged );
	Events.CityFocusChanged.Add(		OnCityFocusChange );
	Events.CityProductionCompleted.Add(	OnCityProductionCompleted );
	Events.CityProductionUpdated.Add(	OnCityProductionUpdated );
	Events.CityProductionChanged.Add(	OnCityProductionChanged );
	Events.CityWorkerChanged.Add(		OnCityWorkerChanged );
	Events.DistrictDamageChanged.Add(	OnCityProductionChanged );
	Events.LocalPlayerTurnBegin.Add(	OnLocalPlayerTurnBegin );
	Events.ImprovementChanged.Add(		OnCityProductionChanged );
	Events.InterfaceModeChanged.Add(	OnInterfaceModeChanged );
	Events.LocalPlayerChanged.Add(		OnLocalPlayerChanged );
	Events.PlayerResourceChanged.Add(	OnPlayerResourceChanged );
	Events.UnitSelectionChanged.Add(	OnUnitSelectionChanged );

    -- LUA Events
	LuaEvents.CityPanelOverview_CloseButton.Add(	OnCloseOverviewPanel );
	LuaEvents.CityPanel_SetOverViewState.Add(		OnCityPanelSetOverViewState );

    -- CUI: combine buttons.
    LuaEvents.CityPanel_ToggleManageCitizens.Add(
        function()
            Controls.ManageTileCheck:SetAndCall(not Controls.ManageTileCheck:IsChecked())
        end
    )

	LuaEvents.GameDebug_Return.Add(					OnGameDebugReturn );
	LuaEvents.ProductionPanel_Close.Add(			OnProductionPanelClose );
	LuaEvents.ProductionPanel_ListModeChanged.Add(	OnProductionPanelListModeChanged );
	LuaEvents.ProductionPanel_Open.Add(				OnProductionPanelOpen );
	LuaEvents.Tutorial_CityPanelOpen.Add(			OnTutorialOpen );
	LuaEvents.Tutorial_ContextDisableItems.Add(		OnTutorial_ContextDisableItems );

	-- Truncate possible static text overflows
	TruncateStringWithTooltip(Controls.BreakdownLabel,	MAX_BEFORE_TRUNC_STATIC_LABELS,	Controls.BreakdownLabel:GetText());
	TruncateStringWithTooltip(Controls.ReligionLabel,	MAX_BEFORE_TRUNC_STATIC_LABELS,	Controls.ReligionLabel:GetText());
	TruncateStringWithTooltip(Controls.AmenitiesLabel,	MAX_BEFORE_TRUNC_STATIC_LABELS,	Controls.AmenitiesLabel:GetText());
	TruncateStringWithTooltip(Controls.HousingLabel,	MAX_BEFORE_TRUNC_STATIC_LABELS,	Controls.HousingLabel:GetText());
end
Initialize();
