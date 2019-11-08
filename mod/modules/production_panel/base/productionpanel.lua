-- ===========================================================================
--	Production Panel / Purchase Panel
-- ===========================================================================

include( "ToolTipHelper" );
include( "InstanceManager" );
include( "TabSupport" );
include( "Civ6Common" );
include( "Colors") ;
include( "SupportFunctions" );
include( "AdjacencyBonusSupport");
include( "ProductionHelper" );

include( "cui_settings" ); -- CUI
include( "cui_helper" ); -- CUI
include( "cui_production_data" ); -- CUI
include( "cui_production_support" ); -- CUI
include( "cui_production_ui" ); -- CUI

-- ===========================================================================
--	Constants
-- ===========================================================================
local RELOAD_CACHE_ID	 = "ProductionPanel";
local COLOR_LOW_OPACITY	 = UI.GetColorValueFromHexLiteral(0xffffffff); -- CUI: 0x3fffffff -> 0xffffffff
local HEADER_Y				= 41;
local WINDOW_HEADER_Y		= 150;
local TOPBAR_Y				= 28;
local SEPARATOR_Y			= 20;
local DISABLED_PADDING_Y	= 10;
local TEXTURE_BASE				 = "UnitFlagBase";
local TEXTURE_CIVILIAN			 = "UnitFlagCivilian";
local TEXTURE_RELIGION			 = "UnitFlagReligion";
local TEXTURE_EMBARK			 = "UnitFlagEmbark";
local TEXTURE_FORTIFY			 = "UnitFlagFortify";
local TEXTURE_NAVAL				 = "UnitFlagNaval";
local TEXTURE_SUPPORT			 = "UnitFlagSupport";
local TEXTURE_TRADE				 = "UnitFlagTrade";
local BUILDING_IM_PREFIX		 = "buildingListingIM_";
local BUILDING_DRAWER_PREFIX	 = "buildingDrawer_";
local ICON_PREFIX				 = "ICON_";
local LISTMODE						= {PRODUCTION = 1, PURCHASE_GOLD = 2, PURCHASE_FAITH = 3, PROD_QUEUE = 4};
local EXTENDED_BUTTON_HEIGHT = 60;
local DEFAULT_BUTTON_HEIGHT = 32; -- CUI: 48 -> 32

local FIELD_LIST_BUILDING_SIZE_Y	 = "fieldListBuilingSizeY";
local FIELD_LIST_WONDER_SIZE_Y		 = "fieldListWonderSizeY";
local FIELD_LIST_UNIT_SIZE_Y		 = "fieldListUnitSizeY";

local FIELD_DISTRICT_LIST			 = "fieldDistrictList";
local FIELD_BUILDING_LIST			 = "fieldBuildingList";
local FIELD_WONDER_LIST				 = "fieldWonderList";
local FIELD_UNIT_LIST				 = "fieldUnitList";
local FIELD_PROJECTS_LIST			 = "fieldProjectsList";

local TXT_PRODUCTION_ITEM_REPAIR			 = Locale.Lookup("LOC_PRODUCTION_ITEM_REPAIR");
local TXT_PRODUCTION_ITEM_DECONTAMINATE		 = Locale.Lookup("LOC_PRODUCTION_ITEM_DECONTAMINATE");
local TXT_HUD_CITY_WILL_NOT_COMPLETE		 = Locale.Lookup("LOC_HUD_CITY_WILL_NOT_COMPLETE");
local TXT_HUD_CITY_DISTRICT_BUILT_TT		 = Locale.Lookup("LOC_HUD_CITY_DISTRICT_BUILT_TT")
local TXT_COST								 = Locale.Lookup( "LOC_HUD_PRODUCTION_COST" );
local TXT_PRODUCTION						 = Locale.Lookup( "LOC_HUD_PRODUCTION" );
local LOC_HUD_UNIT_PANEL_FLEET_SUFFIX		 = Locale.Lookup("LOC_HUD_UNIT_PANEL_FLEET_SUFFIX");
local TXT_HUD_UNIT_PANEL_CORPS_SUFFIX		 = Locale.Lookup("LOC_HUD_UNIT_PANEL_CORPS_SUFFIX");
local TXT_HUD_UNIT_PANEL_ARMADA_SUFFIX		 = Locale.Lookup("LOC_HUD_UNIT_PANEL_ARMADA_SUFFIX");
local TXT_HUD_UNIT_PANEL_ARMY_SUFFIX		 = Locale.Lookup("LOC_HUD_UNIT_PANEL_ARMY_SUFFIX");
local TXT_DISTRICT_REPAIR_LOCATION_FLOODED	 = Locale.Lookup("LOC_DISTRICT_REPAIR_LOCATION_FLOODED");

-- ===========================================================================
--	Members
-- ===========================================================================

local m_listIM              = InstanceManager:new( "NestedList",  "Top", Controls.ProductionList );
local m_purchaseListIM      = InstanceManager:new( "NestedList",  "Top", Controls.PurchaseList );
local m_purchaseFaithListIM = InstanceManager:new( "NestedList",  "Top", Controls.PurchaseFaithList );
local m_queueListIM         = InstanceManager:new( "NestedList",  "Top", Controls.QueueList );

local m_QueueInstanceIM = InstanceManager:new( "ProductionQueueItem", "Top" );

local m_tabs;
local m_productionTab;	-- Additional tracking of the tab control data so that we can select between graphical tabs and label tabs
local m_purchaseTab;
local m_faithTab;
local m_queueTab			 = {};
local m_managerTab			 = {};
local m_maxPurchaseSize			= 0;
local m_TypeNames				= {};
local m_kClickedInstance;

local m_showDisabled = true;
local m_kRecommendedItems;

local m_CurrentProductionHash = 0;
local m_PreviousProductionHash = 0;

local m_isQueueOpen = false;
local m_isManagerOpen = false;
local m_isTutorialRunning = false;

local m_selectedQueueInstance = nil;
local m_kSelectedQueueItem	= {Parent = nil, Button = nil, Index = -1};

local m_SelectedManagerIndex = -1;

local m_tutorialTestMode = false;

local m_hasProductionToShow = false;

local m_PlayerScrollPositions = {};
local m_CurrentListMode = -1;

-- ===========================================================================
local cui_prodIM  = InstanceManager:new("CuiGroupInstance", "Top", Controls.ProductionList);
local cui_goldIM  = InstanceManager:new("CuiGroupInstance", "Top", Controls.PurchaseList);
local cui_faithIM = InstanceManager:new("CuiGroupInstance", "Top", Controls.PurchaseFaithList);
local cui_queueIM = InstanceManager:new("CuiGroupInstance", "Top", Controls.QueueList);
local cui_itemIM  = InstanceManager:new("CuiItemInstance",  "Top", Controls.CuiItemContainer);

local cui_QueueOnDetault = false; -- CUI

local cui_newVersion = true;
-- ===========================================================================

------------------------------------------------------------------------------
-- Collapsible List Handling
------------------------------------------------------------------------------
function OnCollapseTheList()
  m_kClickedInstance.List:SetHide(true);
  m_kClickedInstance.ListSlide:SetSizeY(0);
  m_kClickedInstance.ListAlpha:SetSizeY(0);
  Controls.PauseCollapseList:SetToBeginning();
  m_kClickedInstance.ListSlide:SetToBeginning();
  m_kClickedInstance.ListAlpha:SetToBeginning();
end

-- ===========================================================================
function OnCollapse(instance)
  m_kClickedInstance = instance;
  instance.ListSlide:Reverse();
  instance.ListAlpha:Reverse();
  instance.ListSlide:SetSpeed(15.0);
  instance.ListAlpha:SetSpeed(15.0);
  instance.ListSlide:Play();
  instance.ListAlpha:Play();
  instance.HeaderOn:SetHide(true);
  instance.Header:SetHide(false);
  Controls.PauseCollapseList:Play();	--By doing this we can delay collapsing the list until the "out" sequence has finished playing
end

-- ===========================================================================
function OnExpand(instance)
  m_kClickedInstance = instance;
  instance.HeaderOn:SetHide(false);
  instance.Header:SetHide(true);
  instance.List:SetHide(false);
  instance.ListSlide:SetSizeY(instance.List:GetSizeY());
  instance.ListAlpha:SetSizeY(instance.List:GetSizeY());
  instance.ListSlide:SetToBeginning();
  instance.ListAlpha:SetToBeginning();
  instance.ListSlide:Play();
  instance.ListAlpha:Play();
end

-- ===========================================================================
function OnTabChangeProduction()
  CloseQueue();
  CloseManager();
  LuaEvents.ProductionPanel_IsQueueOpen(false);

  Controls.MiniProductionTab:SetSelected(true);
  Controls.MiniPurchaseTab:SetSelected(false);
  Controls.MiniPurchaseFaithTab:SetSelected(false);

  ShowProperList(LISTMODE.PRODUCTION);

  Controls.CurrentProductionContainer:SetHide(not m_hasProductionToShow);
  Controls.NoProductionContainer:SetHide(true);
  Controls.CurrentProductionButton:SetSelected(false);
  Controls.CurrentProductionButton:SetDisabled(true);
  Controls.CurrentProductionButton:SetVisState(0);

    if (Controls.SlideIn:IsStopped()) then
    UI.PlaySound("Production_Panel_ButtonClick");
        UI.PlaySound("Production_Panel_Open");
    end
end

-- ===========================================================================
function OnTabChangePurchase()
  CloseQueue();
  CloseManager();
  LuaEvents.ProductionPanel_IsQueueOpen(false);

  Controls.MiniProductionTab:SetSelected(false);
  Controls.MiniPurchaseTab:SetSelected(true);
  Controls.MiniPurchaseFaithTab:SetSelected(false);

  ShowProperList(LISTMODE.PURCHASE_GOLD);

  Controls.CurrentProductionContainer:SetHide(true);
  Controls.NoProductionContainer:SetHide(true);

  UI.PlaySound("Production_Panel_ButtonClick");
end

-- ===========================================================================
function OnTabChangePurchaseFaith()
  CloseQueue();
  CloseManager();
  LuaEvents.ProductionPanel_IsQueueOpen(false);

  Controls.MiniProductionTab:SetSelected(false);
  Controls.MiniPurchaseTab:SetSelected(false);
  Controls.MiniPurchaseFaithTab:SetSelected(true);

  ShowProperList(LISTMODE.PURCHASE_FAITH);

  Controls.CurrentProductionContainer:SetHide(true);
  Controls.NoProductionContainer:SetHide(true);

  UI.PlaySound("Production_Panel_ButtonClick");
end

-- ===========================================================================
function OnTabChangeQueue()
  OpenQueue();
  CloseManager();
  LuaEvents.ProductionPanel_IsQueueOpen(true);

  ShowProperList(LISTMODE.PROD_QUEUE);

  Controls.CurrentProductionContainer:SetHide(not m_hasProductionToShow);
  Controls.NoProductionContainer:SetHide(m_hasProductionToShow);
  Controls.CurrentProductionButton:SetSelected(false);
  Controls.CurrentProductionButton:SetDisabled(false);

  UI.PlaySound("Production_Panel_ButtonClick");
end

-- ===========================================================================
function OnTabChangeManager()
  CloseQueue();
  OpenManager();
  LuaEvents.ProductionPanel_IsQueueOpen(true);

  ShowProperList(LISTMODE.PROD_QUEUE);

  Controls.CurrentProductionContainer:SetHide(true);
  Controls.NoProductionContainer:SetHide(true);

  UI.PlaySound("Production_Panel_ButtonClick");
end

-- ===========================================================================
function ShowProperList( eListMode )
  m_CurrentListMode = eListMode;
  Controls.PurchaseMenu:SetHide(not (m_CurrentListMode == LISTMODE.PURCHASE_GOLD));
  Controls.PurchaseFaithMenu:SetHide(not (m_CurrentListMode == LISTMODE.PURCHASE_FAITH));
  Controls.ProductionListScroll:SetHide(not (m_CurrentListMode == LISTMODE.PRODUCTION));
  Controls.QueueListContainer:SetHide(not (m_CurrentListMode == LISTMODE.PROD_QUEUE));
end

-- ===========================================================================
-- This function should be called before starting any production
-- It blocks interaction with production list items while a current production
-- item is selected and also deselects the previous item
-- ===========================================================================
function CheckQueueItemSelected()
  if m_kSelectedQueueItem.Index ~= -1 then
    DeselectItem();
    return true;
  end

  if m_SelectedManagerIndex ~= -1 then
    LuaEvents.ProductionPanel_ProductionClicked();
    return true;
  end

  return false;
end

-- ===========================================================================
-- Placement/Selection
-- ===========================================================================
function BuildUnit(city, unitEntry)
  if CheckQueueItemSelected() then
    return;
  end

  local tParameters = {};
  tParameters[CityOperationTypes.PARAM_UNIT_TYPE] = unitEntry.Hash;
  GetBuildInsertMode(tParameters);
  CityManager.RequestOperation(city, CityOperationTypes.BUILD, tParameters);
  UI.PlaySound("Confirm_Production");
end

-- ===========================================================================
function BuildUnitCorps(city, unitEntry)
  if CheckQueueItemSelected() then
    return;
  end

  local tParameters = {};
  tParameters[CityOperationTypes.PARAM_UNIT_TYPE] = unitEntry.Hash;
  GetBuildInsertMode(tParameters);
  tParameters[CityOperationTypes.MILITARY_FORMATION_TYPE] = MilitaryFormationTypes.CORPS_MILITARY_FORMATION;
  CityManager.RequestOperation(city, CityOperationTypes.BUILD, tParameters);
  UI.PlaySound("Confirm_Production");
end

-- ===========================================================================
function BuildUnitArmy(city, unitEntry)
  if CheckQueueItemSelected() then
    return;
  end

  local tParameters = {};
  tParameters[CityOperationTypes.PARAM_UNIT_TYPE] = unitEntry.Hash;
  GetBuildInsertMode(tParameters);
  tParameters[CityOperationTypes.MILITARY_FORMATION_TYPE] = MilitaryFormationTypes.ARMY_MILITARY_FORMATION;
  CityManager.RequestOperation(city, CityOperationTypes.BUILD, tParameters);
  UI.PlaySound("Confirm_Production");
end

-- ===========================================================================
function BuildBuilding(city, buildingEntry)
  if CheckQueueItemSelected() then
    return;
  end

  local building					= GameInfo.Buildings[buildingEntry.Type];
  local bNeedsPlacement		= building.RequiresPlacement;

  UI.SetInterfaceMode(InterfaceModeTypes.SELECTION);

  local pBuildQueue = city:GetBuildQueue();
  if (pBuildQueue:HasBeenPlaced(buildingEntry.Hash)) then
    bNeedsPlacement = false;
  end

  -- If it's a Wonder and the city already has the building then it doesn't need to be replaced.
  if (bNeedsPlacement) then
    local cityBuildings = city:GetBuildings();
    if (cityBuildings:HasBuilding(buildingEntry.Hash)) then
      bNeedsPlacement = false;
    end
  end

  -- Does the building need to be placed?
  if ( bNeedsPlacement ) then
    -- If so, set the placement mode
    local tParameters = {};
    tParameters[CityOperationTypes.PARAM_BUILDING_TYPE] = buildingEntry.Hash;
    GetBuildInsertMode(tParameters);
    UI.SetInterfaceMode(InterfaceModeTypes.BUILDING_PLACEMENT, tParameters);
    Close();
  else
    -- If not, add it to the queue.
    local tParameters = {};
    tParameters[CityOperationTypes.PARAM_BUILDING_TYPE] = buildingEntry.Hash;
    GetBuildInsertMode(tParameters);
    CityManager.RequestOperation(city, CityOperationTypes.BUILD, tParameters);
        UI.PlaySound("Confirm_Production");
    CloseAfterNewProduction();
  end
end

-- ===========================================================================
function ZoneDistrict(city, districtEntry)
  if CheckQueueItemSelected() then
    return;
  end

  local district					= GameInfo.Districts[districtEntry.Type];
  local bNeedsPlacement		= district.RequiresPlacement;
  local pBuildQueue				= city:GetBuildQueue();

  if (pBuildQueue:HasBeenPlaced(districtEntry.Hash)) then
    bNeedsPlacement = false;
  end

  -- Almost all districts need to be placed, but just in case let's check anyway
  if (bNeedsPlacement ) then
    -- If so, set the placement mode
    local tParameters = {};
    tParameters[CityOperationTypes.PARAM_DISTRICT_TYPE] = districtEntry.Hash;
    GetBuildInsertMode(tParameters);
    UI.SetInterfaceMode(InterfaceModeTypes.DISTRICT_PLACEMENT, tParameters);
    Close();
  else
    -- If not, add it to the queue.
    local tParameters = {};
    tParameters[CityOperationTypes.PARAM_DISTRICT_TYPE] = districtEntry.Hash;
    GetBuildInsertMode(tParameters);
    CityManager.RequestOperation(city, CityOperationTypes.BUILD, tParameters);
        UI.PlaySound("Confirm_Production");
    CloseAfterNewProduction();
  end
end

-- ===========================================================================
function AdvanceProject(city, projectEntry)
  if CheckQueueItemSelected() then
    return;
  end

  local tParameters = {};
  tParameters[CityOperationTypes.PARAM_PROJECT_TYPE] = projectEntry.Hash;
  GetBuildInsertMode(tParameters);
  CityManager.RequestOperation(city, CityOperationTypes.BUILD, tParameters);
    UI.PlaySound("Confirm_Production");
end

-- ===========================================================================
function PurchaseUnit(city, unitEntry)
  local tParameters = {};
  tParameters[CityCommandTypes.PARAM_UNIT_TYPE] = unitEntry.Hash;
  tParameters[CityCommandTypes.PARAM_MILITARY_FORMATION_TYPE] = MilitaryFormationTypes.STANDARD_MILITARY_FORMATION;
  if (unitEntry.Yield == "YIELD_GOLD") then
    tParameters[CityCommandTypes.PARAM_YIELD_TYPE] = GameInfo.Yields["YIELD_GOLD"].Index;
    UI.PlaySound("Purchase_With_Gold");
  else
    tParameters[CityCommandTypes.PARAM_YIELD_TYPE] = GameInfo.Yields["YIELD_FAITH"].Index;
    UI.PlaySound("Purchase_With_Faith");
  end
  CityManager.RequestCommand(city, CityCommandTypes.PURCHASE, tParameters);
end

-- ===========================================================================
function PurchaseUnitCorps(city, unitEntry)
  local tParameters = {};
  tParameters[CityCommandTypes.PARAM_UNIT_TYPE] = unitEntry.Hash;
  tParameters[CityCommandTypes.PARAM_MILITARY_FORMATION_TYPE] = MilitaryFormationTypes.CORPS_MILITARY_FORMATION;
  if (unitEntry.Yield == "YIELD_GOLD") then
    tParameters[CityCommandTypes.PARAM_YIELD_TYPE] = GameInfo.Yields["YIELD_GOLD"].Index;
    UI.PlaySound("Purchase_With_Gold");
  else
    tParameters[CityCommandTypes.PARAM_YIELD_TYPE] = GameInfo.Yields["YIELD_FAITH"].Index;
    UI.PlaySound("Purchase_With_Faith");
  end
  CityManager.RequestCommand(city, CityCommandTypes.PURCHASE, tParameters);
end

-- ===========================================================================
function PurchaseUnitArmy(city, unitEntry)
  local tParameters = {};
  tParameters[CityCommandTypes.PARAM_UNIT_TYPE] = unitEntry.Hash;
  tParameters[CityCommandTypes.PARAM_MILITARY_FORMATION_TYPE] = MilitaryFormationTypes.ARMY_MILITARY_FORMATION;
  if (unitEntry.Yield == "YIELD_GOLD") then
    tParameters[CityCommandTypes.PARAM_YIELD_TYPE] = GameInfo.Yields["YIELD_GOLD"].Index;
    UI.PlaySound("Purchase_With_Gold");
  else
    tParameters[CityCommandTypes.PARAM_YIELD_TYPE] = GameInfo.Yields["YIELD_FAITH"].Index;
    UI.PlaySound("Purchase_With_Faith");
  end
  CityManager.RequestCommand(city, CityCommandTypes.PURCHASE, tParameters);
end

-- ===========================================================================
function PurchaseBuilding(city, buildingEntry)
  local tParameters = {};
  tParameters[CityCommandTypes.PARAM_BUILDING_TYPE] = buildingEntry.Hash;
  if (buildingEntry.Yield == "YIELD_GOLD") then
    tParameters[CityCommandTypes.PARAM_YIELD_TYPE] = GameInfo.Yields["YIELD_GOLD"].Index;
    UI.PlaySound("Purchase_With_Gold");
  else
    tParameters[CityCommandTypes.PARAM_YIELD_TYPE] = GameInfo.Yields["YIELD_FAITH"].Index;
    UI.PlaySound("Purchase_With_Faith");
  end
  CityManager.RequestCommand(city, CityCommandTypes.PURCHASE, tParameters);
end

-- ===========================================================================
function PurchaseDistrict(city, districtEntry)
  local district					= GameInfo.Districts[districtEntry.Type];
  local bNeedsPlacement		= district.RequiresPlacement;
  local pBuildQueue				= city:GetBuildQueue();

  if (pBuildQueue:HasBeenPlaced(districtEntry.Hash)) then
    bNeedsPlacement = false;
  end

  -- Almost all districts need to be placed, but just in case let's check anyway
  if (bNeedsPlacement ) then
    -- If so, set the placement mode
    if(districtEntry.Yield == "YIELD_GOLD") then
      local tParameters = {};
      tParameters[CityOperationTypes.PARAM_DISTRICT_TYPE] = districtEntry.Hash;
      tParameters[CityCommandTypes.PARAM_YIELD_TYPE] = GameInfo.Yields["YIELD_GOLD"].Index;
      UI.SetInterfaceMode(InterfaceModeTypes.DISTRICT_PLACEMENT, tParameters);
    else
      local tParameters = {};
      tParameters[CityOperationTypes.PARAM_DISTRICT_TYPE] = districtEntry.Hash;
      tParameters[CityCommandTypes.PARAM_YIELD_TYPE] = GameInfo.Yields["YIELD_FAITH"].Index;
      UI.SetInterfaceMode(InterfaceModeTypes.DISTRICT_PLACEMENT, tParameters);
    end
  else
    if(districtEntry.Yield == "YIELD_GOLD") then
      -- If not, add it to the queue.
      local tParameters = {};
      tParameters[CityOperationTypes.PARAM_DISTRICT_TYPE] = districtEntry.Hash;
      tParameters[CityCommandTypes.PARAM_YIELD_TYPE] = GameInfo.Yields["YIELD_GOLD"].Index;
      CityManager.RequestCommand(city, CityCommandTypes.PURCHASE, tParameters);
      UI.PlaySound("Purchase_With_Gold");
    else
      -- If not, add it to the queue.
      local tParameters = {};
      tParameters[CityOperationTypes.PARAM_DISTRICT_TYPE] = districtEntry.Hash;
      tParameters[CityCommandTypes.PARAM_YIELD_TYPE] = GameInfo.Yields["YIELD_FAITH"].Index;
      CityManager.RequestCommand(city, CityCommandTypes.PURCHASE, tParameters);
      UI.PlaySound("Purchase_With_Faith");
    end
  end
end

-- ===========================================================================
--	GAME Event
--	City was selected.
-- ===========================================================================
function OnCitySelectionChanged( owner, cityID, i, j, k, isSelected, isEditable)
  local localPlayerId = Game.GetLocalPlayer();
  if owner == localPlayerId and isSelected then
    -- Already open then populate with newly selected city's data...
    if (ContextPtr:IsHidden() == false) and Controls.PauseDismissWindow:IsStopped() and Controls.AlphaIn:IsStopped() then
      Refresh();
    end
  end
end

-- ===========================================================================
--	GAME Event
--	eOldMode, mode the engine was formally in
--	eNewMode, new mode the engine has just changed to
-- ===========================================================================
function OnInterfaceModeChanged( eOldMode, eNewMode )

  -- If this is raised while the city panel is up; selecting to purchase a
  -- plot or manage citizens will close it.
  if eNewMode == InterfaceModeTypes.CITY_MANAGEMENT or eNewMode == InterfaceModeTypes.VIEW_MODAL_LENS then
    if not ContextPtr:IsHidden() then
      Close();
    end
  end
end

-- ===========================================================================
--	GAME Event
--	Unit was selected (impossible for a production panel to be up; close it
-- ===========================================================================
function OnUnitSelectionChanged( playerID , unitID , hexI , hexJ , hexK , bSelected, bEditable )
  local localPlayer = Game.GetLocalPlayer();
  if playerID == localPlayer then
    -- If a unit is selected and this is showing; hide it.
    local pSelectedUnit = UI.GetHeadSelectedUnit();
    if pSelectedUnit ~= nil and not ContextPtr:IsHidden() then
      Close();
    end
  end
end

-- ===========================================================================
--	Actual closing function, may have been called via click, keyboard input,
--	or an external system call.
-- ===========================================================================
function Close()
  if (Controls.SlideIn:IsStopped()) then			-- Need to check to make sure that we have not already begun the transition before attempting to close the panel.
    UI.PlaySound("Production_Panel_Closed");
    Controls.SlideIn:Reverse();
    Controls.AlphaIn:Reverse();
    Controls.PauseDismissWindow:Play();
    LuaEvents.ProductionPanel_CloseManager();
    LuaEvents.ProductionPanel_Close();
  end
end

-- ===========================================================================
--	Close via click
function OnClose()
  Close();
end

-- ===========================================================================
--	Open the panel
-- ===========================================================================
function Open()
  if ContextPtr:IsHidden() then					-- The ContextPtr is only hidden as a callback to the finished SlideIn animation, so this check should be sufficient to ensure that we are not animating.
    -- Sets up proper selection AND the associated lens so it's not stuck "on".
    UI.PlaySound("Production_Panel_Open");
    LuaEvents.ProductionPanel_Open();
    UI.SetInterfaceMode(InterfaceModeTypes.SELECTION);
    Refresh();
    ContextPtr:SetHide(false);
    Controls.ProductionListScroll:SetScrollValue(GetScrollPosition(LISTMODE.PRODUCTION));

    -- Size the panel to the maximum Y value of the expanded content
    Controls.AlphaIn:SetToBeginning();
    Controls.SlideIn:SetToBeginning();
    Controls.AlphaIn:Play();
    Controls.SlideIn:Play();
  end
end

-- ===========================================================================
function OnHide()
  ContextPtr:SetHide(true);
  Controls.PauseDismissWindow:SetToBeginning();
end

-- ===========================================================================
function UpdateQueueTabText( queueSize )
  -- CUI Controls.QueueTab:SetText("[ICON_ProductionQueue] " .. Locale.Lookup("LOC_PRODUCTION_PANEL_QUEUE_WITH_COUNT", queueSize));
end

-- ===========================================================================
--	Initialize, Refresh, Populate, View
--	Update the layout based on the view model
-- ===========================================================================
function View(data)
  local pSelectedCity	= UI.GetHeadSelectedCity();

  -- Get the hashes for the top three recommended items
  -- Convert to a BuildItemHash indexed table for easier look up
  m_kRecommendedItems = {};
  for _,kItem in ipairs(pSelectedCity:GetCityAI():GetBuildRecommendations()) do
    m_kRecommendedItems[kItem.BuildItemHash] = kItem.BuildItemScore;
  end

  -- TODO there is a ton of duplicated code between producing, buying with gold, and buying with faith
  -- there is also a ton of duplicated code between districts, buildings, units, wonders, etc
  -- I think this could be a prime candidate for a refactor if there is time, currently, care must
  -- be taken to copy any changes in several places to keep it functioning consistently

  PopulateList(data, LISTMODE.PRODUCTION, m_listIM);
  Controls.ProductionListScroll:SetScrollValue(GetScrollPosition(LISTMODE.PRODUCTION));
  PopulateList(data, LISTMODE.PURCHASE_GOLD, m_purchaseListIM);
  Controls.PurchaseListScroll:SetScrollValue(GetScrollPosition(LISTMODE.PURCHASE_GOLD));
  PopulateList(data, LISTMODE.PURCHASE_FAITH, m_purchaseFaithListIM);
  Controls.PurchaseFaithListScroll:SetScrollValue(GetScrollPosition(LISTMODE.PURCHASE_FAITH));
  PopulateList(data, LISTMODE.PROD_QUEUE, m_queueListIM);
  Controls.QueueListScroll:SetScrollValue(GetScrollPosition(LISTMODE.PROD_QUEUE));

  if m_isTutorialRunning or m_tutorialTestMode then
    Controls.QueueContainer:SetHide(true);
    Controls.ScrollToButtonContainer:SetHide(true);
  end

  RefreshQueue(data.Owner, data.City:GetID())

  Controls.PurchaseList:CalculateSize();
  if( Controls.PurchaseList:GetSizeY() == 0 ) then
    Controls.NoGoldContent:SetHide(false);
  else
    Controls.NoGoldContent:SetHide(true);
  end

  Controls.PurchaseFaithList:CalculateSize();
  if( Controls.PurchaseFaithList:GetSizeY() == 0 ) then
    Controls.NoFaithContent:SetHide(false);
  else
    Controls.NoFaithContent:SetHide(true);
  end
end

-- ===========================================================================
function ResetInstanceVisibility(productionItem)
  if (productionItem.ArmyCorpsDrawer ~= nil) then
    productionItem.ArmyCorpsDrawer:SetHide(true);
    productionItem.CorpsArmyArrow:SetSelected(true);
    productionItem.CorpsRecommendedIcon:SetHide(true);
    productionItem.CorpsButtonContainer:SetHide(true);
    productionItem.CorpsDisabled:SetHide(true);
    productionItem.ArmyRecommendedIcon:SetHide(true);
    productionItem.ArmyButtonContainer:SetHide(true);
    productionItem.ArmyDisabled:SetHide(true);
    productionItem.CorpsArmyDropdownArea:SetHide(true);
  end
  if (productionItem.BuildingDrawer ~= nil) then
    productionItem.BuildingDrawer:SetHide(true);
    productionItem.CompletedArea:SetHide(true);
  end
  productionItem.RecommendedIcon:SetHide(true);
  productionItem.Disabled:SetHide(true);
end

-- ===========================================================================
function ResizeProductionScrollList()
  local contentOffset = Controls.TabContainer:GetSizeY() + Controls.TabContainer:GetOffsetY();
  Controls.WindowContent:SetOffsetY(contentOffset);

  local contentSize = Controls.ProductionPanel:GetSizeY() - contentOffset;
  Controls.WindowContent:SetSizeY(contentSize);

  local scrollSize = contentSize - Controls.TopStackContainer:GetSizeY();
  Controls.ProductionListScroll:SetSizeY(scrollSize);
  Controls.QueueListScroll:SetSizeY(scrollSize);
  Controls.PurchaseListScroll:SetSizeY(scrollSize);
  Controls.PurchaseFaithListScroll:SetSizeY(scrollSize);
end

-- ===========================================================================
function OnTopStackContainerSizeChanged()
  ResizeProductionScrollList();
end

-- ===========================================================================
function OnTabContainerSizeChanged()
  ResizeProductionScrollList();
end

-- ===========================================================================
function PopulateGenericItemData( kInstance, kItem )
  ResetInstanceVisibility(kInstance);

  -- Recommended check
  if m_kRecommendedItems[kItem.Hash] ~= nil then
    kInstance.RecommendedIcon:SetHide(false);
  end

  -- Item Name
  local sName = Locale.Lookup(kItem.Name);
  if (kItem.Repair) then
    sName = sName .. "[NEWLINE]" .. TXT_PRODUCTION_ITEM_REPAIR;
  end

  kInstance.LabelText:SetText(sName);

  -- Tooltips
  kInstance.Button:SetToolTipString(kItem.ToolTip);
  kInstance.Disabled:SetToolTipString(kItem.ToolTip);

  -- Icon
  kInstance.Icon:SetIcon(ICON_PREFIX..kItem.Type);

  -- Is item disabled?
  if (kItem.Disabled) then
    if(m_showDisabled) then
      kInstance.Disabled:SetHide(false);
      kInstance.Button:SetColor(COLOR_LOW_OPACITY);
    else
      kInstance.Button:SetHide(true);
    end
  else
    kInstance.Button:SetHide(false);
    kInstance.Disabled:SetHide(true);
    kInstance.Button:SetColor(UI.GetColorValue("COLOR_WHITE"));
  end
  kInstance.Button:SetDisabled(kItem.Disabled);
end

-- ===========================================================================
function PopulateGenericBuildData( kInstance, kItem )
  PopulateGenericItemData(kInstance, kItem);

  -- Progress
  if kItem.Progress > 0 then
    local iItemProgress = kItem.Progress/kItem.Cost;
    if iItemProgress < 1 then
      kInstance.ProductionProgress:SetPercent(iItemProgress);
      kInstance.ProductionProgressArea:SetHide(false);
    else
      kInstance.ProductionProgressArea:SetHide(true);
    end
  else
    kInstance.ProductionProgressArea:SetHide(true);
  end
end

-- ===========================================================================
function PopulateGenericPurchaseData( kInstance, kItem )
  PopulateGenericItemData(kInstance, kItem);

  kInstance.ProductionProgressArea:SetHide(true);
end

-- ===========================================================================
function PopulateCurrentProduction(data)
  m_hasProductionToShow = RefreshCurrentProduction( Controls, data.Owner, data.City:GetID() );
end

-- ===========================================================================
function PopulateWonders(data, listMode, listIM)
  local wonderList = listIM:GetInstance();

  local sHeaderText = Locale.ToUpper("LOC_HUD_CITY_WONDERS");
  wonderList.Header:SetText(sHeaderText);
  wonderList.HeaderOn:SetText(sHeaderText);

  if ( wonderList.wonderListIM ~= nil ) then
    wonderList.wonderListIM:ResetInstances()
  else
    wonderList.wonderListIM = InstanceManager:new( "BuildingListInstance", "Root", wonderList.List);
  end

  for i, item in ipairs(data.BuildingItems) do
    -- CUI: fix the wonders logic
    local shouldShow = false;
    if item.IsWonder then
      if listMode ~= LISTMODE.PROD_QUEUE then
        shouldShow = true;
      else
        shouldShow = not CuiIsBuildingInQueue(item);
      end
    end
    --
    if shouldShow then
      local wonderListing = wonderList.wonderListIM:GetInstance();

      PopulateGenericBuildData(wonderListing, item);

      local turnsStrTT = "";
      local turnsStr = "";
      local numberOfTurns = item.TurnsLeft;
      if numberOfTurns == -1 then
        numberOfTurns = "999+";
        turnsStrTT = TXT_HUD_CITY_WILL_NOT_COMPLETE;
      else
        turnsStrTT = numberOfTurns .. Locale.Lookup("LOC_HUD_CITY_TURNS_TO_COMPLETE", item.TurnsLeft);
      end
      turnsStr = numberOfTurns .. "[ICON_Turn]";
      wonderListing.CostText:SetText(turnsStr);
      wonderListing.CostText:SetToolTipString(turnsStrTT);

            wonderListing.Button:RegisterCallback( Mouse.eMouseEnter,	function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
      wonderListing.Button:RegisterCallback( Mouse.eLClick, function()
        BuildBuilding(data.City, item);
      end);

      if not m_isTutorialRunning then
        wonderListing.Button:RegisterCallback( Mouse.eRClick, function()
          LuaEvents.OpenCivilopedia(item.Type);
        end);
      else
        wonderListing.Button:SetTag(UITutorialManager:GetHash(item.Type));
      end
    end
  end

  if (wonderList.wonderListIM.m_iAllocatedInstances <= 0) then
    wonderList.Top:SetHide(true);
  else
        wonderList.Header:RegisterCallback( Mouse.eMouseEnter,	function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
    wonderList.Header:RegisterCallback( Mouse.eLClick, function()
      OnExpand(wonderList);
      end);
        wonderList.HeaderOn:RegisterCallback( Mouse.eMouseEnter,	function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
    wonderList.HeaderOn:RegisterCallback( Mouse.eLClick, function()
      OnCollapse(wonderList);
      end);
  end

  wonderList.Top:RegisterSizeChanged(function() OnWonderListSizeChanged(listIM, wonderList.Top:GetSizeY()); end);
  OnWonderListSizeChanged(listIM, wonderList.Top:GetSizeY());

  OnExpand(wonderList);
end

-- ===========================================================================
function PopulateProjects(data, listMode, listIM)
  local projectList = listIM:GetInstance();

  local sHeaderText = Locale.ToUpper("LOC_HUD_PROJECTS");
  projectList.Header:SetText(sHeaderText);
  projectList.HeaderOn:SetText(sHeaderText);

  if ( projectList.projectListIM ~= nil ) then
    projectList.projectListIM:ResetInstances();
  else
    projectList.projectListIM = InstanceManager:new( "ProjectListInstance", "Root", projectList.List);
  end

  for i, item in ipairs(data.ProjectItems) do
    -- CUI: fix the project logic
    local shouldShow = false;
    if listMode ~= LISTMODE.PROD_QUEUE then
      shouldShow = not item.IsCurrentProduction;
    else
      shouldShow = CuiIsProjectRepeatable(item) or not CuiIsProjectInQueue(item);
    end
    --
    if shouldShow then
      local projectListing = projectList.projectListIM:GetInstance();

      PopulateGenericBuildData(projectListing, item);

      local numberOfTurns = item.TurnsLeft;
      if numberOfTurns == -1 then
        numberOfTurns = "999+";
      end;

      local turnsStr = numberOfTurns .. "[ICON_Turn]";
      projectListing.CostText:SetText(turnsStr);

      projectListing.Button:RegisterCallback( Mouse.eLClick, function()
        AdvanceProject(data.City, item);
        CloseAfterNewProduction();
      end);

      if not m_isTutorialRunning then
        projectListing.Button:RegisterCallback( Mouse.eRClick, function()
          LuaEvents.OpenCivilopedia(item.Type);
        end);
      else
        projectListing.Button:SetTag(UITutorialManager:GetHash(item.Type));
      end
    end
  end

  if (projectList.projectListIM.m_iAllocatedInstances <= 0) then
    projectList.Top:SetHide(true);
  else
    projectList.Header:RegisterCallback( Mouse.eLClick, function()
      OnExpand(projectList);
      end);
    projectList.HeaderOn:RegisterCallback( Mouse.eLClick, function()
      OnCollapse(projectList);
      end);
  end

  OnExpand(projectList);
end

-- ===========================================================================
function PopulateDistrictsWithNestedBuildings(data, listMode, listIM)
  local districtList = listIM:GetInstance();

  local sHeaderText = Locale.ToUpper("LOC_HUD_DISTRICTS_BUILDINGS");
  districtList.Header:SetText(sHeaderText);
  districtList.HeaderOn:SetText(sHeaderText);

  if ( districtList.districtListIM ~= nil ) then
    districtList.districtListIM:ResetInstances();
  else
    districtList.districtListIM = InstanceManager:new( "DistrictListInstance", "Root", districtList.List);
  end

  -- In the interest of performance, we're keeping the instances that we created and resetting the data.
  -- This requires a little bit of footwork to remember the instances that have been modified and to manually reset them.
  for _,type in ipairs(m_TypeNames) do
    local sBuildingIM = BUILDING_IM_PREFIX..type;
    if ( districtList[sBuildingIM] ~= nil) then		--Reset the states for the building instance managers
      districtList[sBuildingIM]:ResetInstances();
    end
    local sBuildingDrawer = BUILDING_DRAWER_PREFIX..type;
    if ( districtList[sBuildingDrawer] ~= nil) then	--Reset the states of the drawers
      districtList[sBuildingDrawer]:SetHide(true);
    end
  end

  local CuiShouldShowChild = {}; -- CUI: for buildings
  for i, item in ipairs(data.DistrictItems) do
    -- CUI: fix the district logic
    local shouldShow = false;
    if listMode ~= LISTMODE.PROD_QUEUE then
      shouldShow = true;
    else
      shouldShow = not CuiIsDistrictInQueue(item);
    end
    if(GameInfo.DistrictReplaces[item.Type] ~= nil) then
      districtType = GameInfo.DistrictReplaces[item.Type].ReplacesDistrictType;
      CuiShouldShowChild[districtType] = shouldShow;
    end
    CuiShouldShowChild[item.Type] = shouldShow;
    --
    if shouldShow then
      local districtListing = districtList.districtListIM:GetInstance();

      PopulateGenericBuildData(districtListing, item);

      local turnsStrTT = "";
      local turnsStr = "";

      if(item.HasBeenBuilt and GameInfo.Districts[item.Type].OnePerCity == true and not item.Repair and not item.Contaminated and item.Progress == 0) then
        turnsStrTT = TXT_HUD_CITY_DISTRICT_BUILT_TT;
        turnsStr = "[ICON_Checkmark]";
      elseif item.ContaminatedTurns > 0 then
        turnsStrTT = Locale.Lookup("LOC_TOOLTIP_PLOT_CONTAMINATED_TEXT", item.ContaminatedTurns);
        turnsStr = item.TurnsLeft .. "[ICON_Turn]";
      else
        local numberOfTurns = item.TurnsLeft;
        if numberOfTurns == -1 then
          numberOfTurns = "999+";
          turnsStrTT = TXT_HUD_CITY_WILL_NOT_COMPLETE;
        else
          turnsStrTT = numberOfTurns .. Locale.Lookup("LOC_HUD_CITY_TURNS_TO_COMPLETE", item.TurnsLeft);
        end
        turnsStr = numberOfTurns .. "[ICON_Turn]";
      end

      districtListing.CostText:SetToolTipString(turnsStrTT);
      districtListing.CostText:SetText(turnsStr);

      local districtType = item.Type;
      -- Check to see if this is a unique district that will be substituted for another kind of district
      if(GameInfo.DistrictReplaces[item.Type] ~= nil) then
        districtType = 	GameInfo.DistrictReplaces[item.Type].ReplacesDistrictType;
      end
      local uniqueBuildingIMName = BUILDING_IM_PREFIX..districtType;
      local uniqueBuildingAreaName = BUILDING_DRAWER_PREFIX..districtType;

      table.insert(m_TypeNames, districtType);

      if districtList[uniqueBuildingIMName] == nil then
        districtList[uniqueBuildingIMName] = InstanceManager:new( "BuildingListInstance", "Root", districtListing.BuildingStack);
      else
        districtList[uniqueBuildingIMName]:ResetInstances();
        districtList[uniqueBuildingIMName].m_ParentControl = districtListing.BuildingStack;
      end

      districtList[uniqueBuildingAreaName] = districtListing.BuildingDrawer;
      districtListing.CompletedArea:SetHide(true);

      if (item.Disabled) then
        if(item.HasBeenBuilt and GameInfo.Districts[item.Type].OnePerCity == true and not item.Repair) then
          districtListing.CompletedArea:SetHide(false);
          districtListing.Disabled:SetHide(true);
        end
      end

      districtListing.Button:RegisterCallback( Mouse.eMouseEnter,	function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
      districtListing.Button:RegisterCallback( Mouse.eLClick, function()
        ZoneDistrict(data.City, item);
      end);

      if not m_isTutorialRunning then
        districtListing.Button:RegisterCallback( Mouse.eRClick, function()
          LuaEvents.OpenCivilopedia(item.Type);
        end);
      else
        districtListing.Root:SetTag(UITutorialManager:GetHash(item.Type));
      end
    end
  end

  if (districtList.districtListIM.m_iAllocatedInstances <= 0) then
    districtList.Top:SetHide(true);
  else
    districtList.Header:RegisterCallback( Mouse.eLClick, function()
      OnExpand(districtList);
      end);
        districtList.Header:RegisterCallback( Mouse.eMouseEnter,	function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
    districtList.HeaderOn:RegisterCallback( Mouse.eLClick, function()
      OnCollapse(districtList);
      end);
        districtList.HeaderOn:RegisterCallback(	Mouse.eMouseEnter,	function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
  end

  -- Populate Nested Buildings -----------------

  for i, buildingItem in ipairs(data.BuildingItems) do
    -- CUI: fix the building logic
    local shouldShow = false;
    if not buildingItem.IsWonder then
      if listMode ~= LISTMODE.PROD_QUEUE then
        shouldShow = true;
      else
        if CuiIsBuildingInQueue(buildingItem) then
          shouldShow = false;
        else
          shouldShow = CuiShouldShowChild[buildingItem.PrereqDistrict];
        end
      end
    end
    --
    if shouldShow then
      local uniqueDrawerName = BUILDING_DRAWER_PREFIX..buildingItem.PrereqDistrict;
      local uniqueIMName = BUILDING_IM_PREFIX..buildingItem.PrereqDistrict;
      local pDistrictBuildingIM = districtList[uniqueIMName];
      if (pDistrictBuildingIM ~= nil) then

        local buildingListing = pDistrictBuildingIM:GetInstance();

        PopulateGenericBuildData(buildingListing, buildingItem);

        buildingListing.Root:SetSizeX(305);
        buildingListing.Button:SetSizeX(305);
        local districtBuildingAreaControl = districtList[uniqueDrawerName];
        districtBuildingAreaControl:SetHide(false);

        local turnsStrTT = "";
        local turnsStr = "";
        local numberOfTurns = buildingItem.TurnsLeft;
        if numberOfTurns == -1 then
          numberOfTurns = "999+";
          turnsStrTT = TXT_HUD_CITY_WILL_NOT_COMPLETE;
        else
          turnsStrTT = numberOfTurns .. Locale.Lookup("LOC_HUD_CITY_TURNS_TO_COMPLETE", buildingItem.TurnsLeft);
        end
        turnsStr = numberOfTurns .. "[ICON_Turn]";
        buildingListing.CostText:SetToolTipString(turnsStrTT);
        buildingListing.CostText:SetText(turnsStr);

                buildingListing.Button:RegisterCallback( Mouse.eMouseEnter,	function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
        buildingListing.Button:RegisterCallback( Mouse.eLClick, function()
          BuildBuilding(data.City, buildingItem);
        end);

        if not m_isTutorialRunning then
          buildingListing.Button:RegisterCallback( Mouse.eRClick, function()
            LuaEvents.OpenCivilopedia(buildingItem.Type);
          end);
        else
          buildingListing.Button:SetTag(UITutorialManager:GetHash(buildingItem.Type));
        end
      end
    end
  end

  districtList.Top:RegisterSizeChanged( function() OnBuildingListSizeChanged(listIM, districtList.Top:GetSizeY()); end);
  OnBuildingListSizeChanged(listIM, districtList.Top:GetSizeY());

  OnExpand(districtList);
end

-- ===========================================================================
function PopulateDistrictsWithoutNestedBuildings(data, listMode, listIM)
  local districtList = listIM:GetInstance();

  local sHeaderText = Locale.ToUpper("LOC_HUD_DISTRICTS");
  districtList.Header:SetText(sHeaderText);
  districtList.HeaderOn:SetText(sHeaderText);

  if ( districtList.districtListIM ~= nil) then
    districtList.districtListIM:ResetInstances();
  else
    districtList.districtListIM = InstanceManager:new( "DistrictListInstance", "Root", districtList.List);
  end

  for i, item in ipairs(data.DistrictPurchases) do
    if ((item.Yield == "YIELD_GOLD" and listMode == LISTMODE.PURCHASE_GOLD) or (item.Yield == "YIELD_FAITH" and listMode == LISTMODE.PURCHASE_FAITH)) then
      local districtListing = districtList.districtListIM:GetInstance();

      PopulateGenericPurchaseData(districtListing, item);

      local costStr;
      if (item.Yield == "YIELD_GOLD") then
        costStr = Locale.Lookup("LOC_PRODUCTION_PURCHASE_GOLD_TEXT", item.Cost);
      else
        costStr = Locale.Lookup("LOC_PRODUCTION_PURCHASE_FAITH_TEXT", item.Cost);
      end
      if (item.CantAfford) then
        costStr = "[COLOR:Red]" .. costStr .. "[ENDCOLOR]";
      end

      districtListing.CostText:SetText(costStr);

      districtListing.Button:RegisterCallback( Mouse.eMouseEnter,	function() UI.PlaySound("Main_Menu_Mouse_Over"); end);

      districtListing.Button:RegisterCallback( Mouse.eLClick, function()
          PurchaseDistrict(data.City, item);
          Close();
        end);

    end
  end

  if (districtList.districtListIM.m_iAllocatedInstances <= 0) then
    districtList.Top:SetHide(true);
  else
    m_maxPurchaseSize = m_maxPurchaseSize + HEADER_Y + SEPARATOR_Y;
        districtList.Header:RegisterCallback( Mouse.eMouseEnter,	function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
    districtList.Header:RegisterCallback( Mouse.eLClick, function()
      OnExpand(districtList);
      end);
        districtList.HeaderOn:RegisterCallback( Mouse.eMouseEnter,	function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
    districtList.HeaderOn:RegisterCallback( Mouse.eLClick, function()
      OnCollapse(districtList);
      end);
  end

  OnExpand(districtList);

  -- Populate Buildings ------------------------
  local buildingList = listIM:GetInstance();

  local sHeaderText = Locale.ToUpper("LOC_HUD_BUILDINGS");
  buildingList.Header:SetText(sHeaderText);
  buildingList.HeaderOn:SetText(sHeaderText);

  if ( buildingList.buildingListIM ~= nil ) then
    buildingList.buildingListIM:ResetInstances();
  else
    buildingList.buildingListIM = InstanceManager:new( "BuildingListInstance", "Root", buildingList.List);
  end

  for i, item in ipairs(data.BuildingPurchases) do
    if ((item.Yield == "YIELD_GOLD" and listMode == LISTMODE.PURCHASE_GOLD) or (item.Yield == "YIELD_FAITH" and listMode == LISTMODE.PURCHASE_FAITH)) then
      local buildingListing = buildingList.buildingListIM:GetInstance();

      PopulateGenericPurchaseData(buildingListing, item);

      local costStr;
      if (item.Yield == "YIELD_GOLD") then
        costStr = Locale.Lookup("LOC_PRODUCTION_PURCHASE_GOLD_TEXT", item.Cost);
      else
        costStr = Locale.Lookup("LOC_PRODUCTION_PURCHASE_FAITH_TEXT", item.Cost);
      end
      if item.CantAfford then
        costStr = "[COLOR:Red]" .. costStr .. "[ENDCOLOR]";
      end

      buildingListing.CostText:SetText(costStr);

      if not m_isTutorialRunning then
        buildingListing.Button:RegisterCallback( Mouse.eRClick, function()
          LuaEvents.OpenCivilopedia(item.Type);
        end);
      end

            buildingListing.Button:RegisterCallback( Mouse.eMouseEnter,	function() UI.PlaySound("Main_Menu_Mouse_Over"); end);

      buildingListing.Button:RegisterCallback( Mouse.eLClick, function()
          PurchaseBuilding(data.City, item);
          Close();
        end);
      end
  end

  if (buildingList.buildingListIM.m_iAllocatedInstances <= 0) then
    buildingList.Top:SetHide(true);
  else
    m_maxPurchaseSize = m_maxPurchaseSize + HEADER_Y + SEPARATOR_Y;
        buildingList.Header:RegisterCallback( Mouse.eMouseEnter,	function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
    buildingList.Header:RegisterCallback( Mouse.eLClick, function()
      OnExpand(buildingList);
      end);
        buildingList.HeaderOn:RegisterCallback( Mouse.eMouseEnter,	function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
    buildingList.HeaderOn:RegisterCallback( Mouse.eLClick, function()
      OnCollapse(buildingList);
      end);
  end

  districtList.Top:RegisterSizeChanged( function() OnBuildingListSizeChanged(listIM, districtList.Top:GetSizeY()); end);
  OnBuildingListSizeChanged(listIM, districtList.Top:GetSizeY());

  OnExpand(buildingList);
end

-- ===========================================================================
function GetTurnsToCompleteStrings( turnsToComplete )
  local turnsStr = "";
  local turnsStrTT = "";

  if turnsToComplete == -1 then
    turnsStr = "999+[ICON_Turn]";
    turnsStrTT = TXT_HUD_CITY_WILL_NOT_COMPLETE;
  else
    turnsStr = turnsToComplete .. "[ICON_Turn]";
    turnsStrTT = turnsToComplete .. Locale.Lookup("LOC_HUD_CITY_TURNS_TO_COMPLETE", turnsToComplete);
  end

  return turnsStr, turnsStrTT;
end

-- ===========================================================================
function PopulateUnits(data, listMode, listIM)
  local unitList = listIM:GetInstance();

  local primaryColor, secondaryColor  = UI.GetPlayerColors( Players[Game.GetLocalPlayer()]:GetID() );
  local darkerFlagColor    = UI.DarkenLightenColor(primaryColor,(-85),255);
  local brighterFlagColor  = UI.DarkenLightenColor(primaryColor,90,255);
  local brighterIconColor  = UI.DarkenLightenColor(secondaryColor,20,255);
  local darkerIconColor    = UI.DarkenLightenColor(secondaryColor,-30,255);

  local sHeaderText = Locale.ToUpper("LOC_TECH_FILTER_UNITS");
  unitList.Header:SetText(sHeaderText);
  unitList.HeaderOn:SetText(sHeaderText);

  if ( unitList.unitListIM ~= nil ) then
    unitList.unitListIM:ResetInstances();
  else
    unitList.unitListIM = InstanceManager:new( "UnitListInstance", "Root", unitList.List);
  end
  if ( unitList.civilianListIM ~= nil ) then
    unitList.civilianListIM:ResetInstances();
  else
    unitList.civilianListIM = InstanceManager:new( "CivilianListInstance",	"Root", unitList.List);
  end

  local unitData;
  if (listMode == LISTMODE.PRODUCTION or listMode == LISTMODE.PROD_QUEUE) then
    unitData = data.UnitItems;
  else
    unitData = data.UnitPurchases;
  end
  for i, item in ipairs(unitData) do
    local unitListing ;
    if ((item.Yield == "YIELD_GOLD" and listMode == LISTMODE.PURCHASE_GOLD) or (item.Yield == "YIELD_FAITH" and listMode == LISTMODE.PURCHASE_FAITH) or (listMode == LISTMODE.PRODUCTION and item.IsCurrentProduction == false) or listMode == LISTMODE.PROD_QUEUE) then
      if (item.Civilian) then
        unitListing = unitList["civilianListIM"]:GetInstance();
      else
        unitListing = unitList["unitListIM"]:GetInstance();
      end

      local costStr = "";
      local costStrTT = "";
      if (listMode == LISTMODE.PRODUCTION or listMode == LISTMODE.PROD_QUEUE) then
        PopulateGenericBuildData(unitListing, item);

        costStr, costStrTT = GetTurnsToCompleteStrings(item.TurnsLeft);
      else
        PopulateGenericPurchaseData(unitListing, item);

        if (item.Yield == "YIELD_GOLD") then
          costStr = Locale.Lookup("LOC_PRODUCTION_PURCHASE_GOLD_TEXT", item.Cost);
        else
          costStr = Locale.Lookup("LOC_PRODUCTION_PURCHASE_FAITH_TEXT", item.Cost);
        end
        if item.CantAfford then
          costStr = "[COLOR:Red]" .. costStr .. "[ENDCOLOR]";
        end
      end

      unitListing.CostText:SetText(costStr);
      if(costStrTT ~= "") then
        unitListing.CostText:SetToolTipString(costStrTT);
      end

      -- Show/hide religion indicator icon
      if unitListing.ReligionIcon then
        local showReligionIcon = false;

        if item.ReligiousStrength and item.ReligiousStrength > 0 then
          if unitListing.ReligionIcon then
            local religionType = data.City:GetReligion():GetMajorityReligion();
            if religionType > 0 then
              local religion = GameInfo.Religions[religionType];
              local religionIcon = "ICON_" .. religion.ReligionType;
              local religionColor = UI.GetColorValue(religion.Color);
              local religionName = Game.GetReligion():GetName(religion.Index);

              unitListing.ReligionIcon:SetIcon(religionIcon);
              unitListing.ReligionIcon:SetColor(religionColor);
              unitListing.ReligionIcon:LocalizeAndSetToolTip( religionName );
              unitListing.ReligionIcon:SetHide(false);
              showReligionIcon = true;
            end
          end
        end

        unitListing.ReligionIcon:SetHide(not showReligionIcon);
      end

      -- Set Icon color and backing
      local textureName = TEXTURE_BASE;
      if item.Type ~= -1 then
        local kUnitDef = GameInfo.Units[item.Type];
        if (kUnitDef.Combat ~= 0 or kUnitDef.RangedCombat ~= 0) then		-- Need a simpler what to test if the unit is a combat unit or not.
          if "DOMAIN_SEA" == kUnitDef.Domain then
            textureName = TEXTURE_NAVAL;
          else
            textureName =  TEXTURE_BASE;
          end
        else
          if kUnitDef.MakeTradeRoute then
            textureName = TEXTURE_TRADE;
          elseif "FORMATION_CLASS_SUPPORT" == kUnitDef.FormationClass then
            textureName = TEXTURE_SUPPORT;
          elseif item.ReligiousStrength > 0 then
            textureName = TEXTURE_RELIGION;
          else
            textureName = TEXTURE_CIVILIAN;
          end
        end
      end

      -- Set colors and icons for the flag instance
      unitListing.FlagBase:SetTexture(textureName);
      unitListing.FlagBaseOutline:SetTexture(textureName);
      unitListing.FlagBaseDarken:SetTexture(textureName);
      unitListing.FlagBaseLighten:SetTexture(textureName);
      unitListing.FlagBase:SetColor( primaryColor );
      unitListing.FlagBaseOutline:SetColor( primaryColor );
      unitListing.FlagBaseDarken:SetColor( darkerFlagColor );
      unitListing.FlagBaseLighten:SetColor( brighterFlagColor );
      unitListing.Icon:SetColor( UI.GetColorValue("COLOR_WHITE") ); -- CUI

      unitListing.Button:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
      if (listMode == LISTMODE.PRODUCTION or listMode == LISTMODE.PROD_QUEUE) then
        unitListing.Button:RegisterCallback( Mouse.eLClick, function()
          BuildUnit(data.City, item);
          CloseAfterNewProduction();
          end);
      else
        unitListing.Button:RegisterCallback( Mouse.eLClick, function()
          PurchaseUnit(data.City, item);
          Close();
          end);
      end

      if not m_isTutorialRunning then
        unitListing.Button:RegisterCallback( Mouse.eRClick, function()
          LuaEvents.OpenCivilopedia(item.Type);
        end);
      else
        unitListing.Button:SetTag(UITutorialManager:GetHash(item.Type));
      end

      -- Controls for training unit corps and armies.
      -- Want a special text string for this!! #NEW TEXT #LOCALIZATION - "You can only directly build corps and armies once you have constructed a military academy."
      -- LOC_UNIT_TRAIN_NEED_MILITARY_ACADEMY
      if item.Corps or item.Army then
        if (item.CorpsDisabled) then
          unitListing.CorpsDisabled:SetHide(false);
        end
        if (item.ArmyDisabled) then
          unitListing.ArmyDisabled:SetHide(false);
        end
        unitListing.CorpsArmyDropdownArea:SetHide(false);

        unitListing.CorpsArmyArrow:RegisterCallback( Mouse.eLClick, function() OnCorpsToggle( unitList, unitListing ); end );
        unitListing.CorpsArmyDropdownButton:RegisterCallback( Mouse.eLClick, function() OnCorpsToggle( unitList, unitListing ); end );
      end

      if item.Corps then
        unitListing.CorpsButtonContainer:SetHide(false);
        -- Production meter progress for corps unit
        if (listMode == LISTMODE.PRODUCTION or listMode == LISTMODE.PROD_QUEUE) then
          if(item.Progress > 0) then
            unitListing.ProductionCorpsProgressArea:SetHide(false);
            local unitProgress = item.Progress/item.CorpsCost;
            if (unitProgress < 1) then
              unitListing.ProductionCorpsProgress:SetPercent(unitProgress);
            else
              unitListing.ProductionCorpsProgressArea:SetHide(true);
            end
          else
            unitListing.ProductionCorpsProgressArea:SetHide(true);
          end

          local turnsStr, turnsStrTT = GetTurnsToCompleteStrings(item.CorpsTurnsLeft);
          unitListing.CorpsCostText:SetText(turnsStr);
          unitListing.CorpsCostText:SetToolTipString(turnsStrTT);
        else
          unitListing.ProductionCorpsProgressArea:SetHide(true);
          if (item.Yield == "YIELD_GOLD") then
            costStr = Locale.Lookup("LOC_PRODUCTION_PURCHASE_GOLD_TEXT", item.CorpsCost);
          else
            costStr = Locale.Lookup("LOC_PRODUCTION_PURCHASE_FAITH_TEXT", item.CorpsCost);
          end
          if (item.CorpsDisabled) then
            if (m_showDisabled) then
              unitListing.CorpsDisabled:SetHide(false);
            end
            costStr = "[COLOR:Red]" .. costStr .. "[ENDCOLOR]";
          end
          unitListing.CorpsCostText:SetText(costStr);
        end


        unitListing.CorpsLabelIcon:SetText(item.CorpsName);
        unitListing.CorpsLabelText:SetText(""); -- CUI

        unitListing.CorpsFlagBase:SetTexture(textureName);
        unitListing.CorpsFlagBaseOutline:SetTexture(textureName);
        unitListing.CorpsFlagBaseDarken:SetTexture(textureName);
        unitListing.CorpsFlagBaseLighten:SetTexture(textureName);
        unitListing.CorpsFlagBase:SetColor( primaryColor );
        unitListing.CorpsFlagBaseOutline:SetColor( primaryColor );
        unitListing.CorpsFlagBaseDarken:SetColor( darkerFlagColor );
        unitListing.CorpsFlagBaseLighten:SetColor( brighterFlagColor );
        unitListing.CorpsIcon:SetColor( UI.GetColorValue("COLOR_WHITE") ); -- CUI
        unitListing.CorpsIcon:SetIcon(ICON_PREFIX..item.Type);
        unitListing.TrainCorpsButton:SetToolTipString(item.CorpsTooltip);
        unitListing.CorpsDisabled:SetToolTipString(item.CorpsTooltip);
        if (listMode == LISTMODE.PRODUCTION or listMode == LISTMODE.PROD_QUEUE) then
          unitListing.TrainCorpsButton:RegisterCallback( Mouse.eLClick, function()
            BuildUnitCorps(data.City, item);
            CloseAfterNewProduction();
          end);
        else
          unitListing.TrainCorpsButton:RegisterCallback( Mouse.eLClick, function()
            PurchaseUnitCorps(data.City, item);
            Close();
          end);
        end
      end
      if item.Army then
        unitListing.ArmyButtonContainer:SetHide(false);

        if (listMode == LISTMODE.PRODUCTION or listMode == LISTMODE.PROD_QUEUE) then
          if(item.Progress > 0) then
            unitListing.ProductionArmyProgressArea:SetHide(false);
            local unitProgress = item.Progress/item.ArmyCost;
            unitListing.ProductionArmyProgress:SetPercent(unitProgress);
            if (unitProgress < 1) then
              unitListing.ProductionArmyProgress:SetPercent(unitProgress);
            else
              unitListing.ProductionArmyProgressArea:SetHide(true);
            end
          else
            unitListing.ProductionArmyProgressArea:SetHide(true);
          end

          local turnsStr, turnsStrTT = GetTurnsToCompleteStrings(item.ArmyTurnsLeft);
          unitListing.ArmyCostText:SetText(turnsStr);
          unitListing.ArmyCostText:SetToolTipString(turnsStrTT);
        else
          unitListing.ProductionArmyProgressArea:SetHide(true);
          if (item.Yield == "YIELD_GOLD") then
            costStr = Locale.Lookup("LOC_PRODUCTION_PURCHASE_GOLD_TEXT", item.ArmyCost);
          else
            costStr = Locale.Lookup("LOC_PRODUCTION_PURCHASE_FAITH_TEXT", item.ArmyCost);
          end
          if (item.ArmyDisabled) then
            if (m_showDisabled) then
              unitListing.ArmyDisabled:SetHide(false);
            end
            costStr = "[COLOR:Red]" .. costStr .. "[ENDCOLOR]";
          end
          unitListing.ArmyCostText:SetText(costStr);
        end

        unitListing.ArmyLabelIcon:SetText(item.ArmyName);
        unitListing.ArmyLabelText:SetText(""); -- CUI
        unitListing.ArmyFlagBase:SetTexture(textureName);
        unitListing.ArmyFlagBaseOutline:SetTexture(textureName);
        unitListing.ArmyFlagBaseDarken:SetTexture(textureName);
        unitListing.ArmyFlagBaseLighten:SetTexture(textureName);
        unitListing.ArmyFlagBase:SetColor( primaryColor );
        unitListing.ArmyFlagBaseOutline:SetColor( primaryColor );
        unitListing.ArmyFlagBaseDarken:SetColor( darkerFlagColor );
        unitListing.ArmyFlagBaseLighten:SetColor( brighterFlagColor );
        unitListing.ArmyIcon:SetColor( UI.GetColorValue("COLOR_WHITE") ); -- CUI
        unitListing.ArmyIcon:SetIcon(ICON_PREFIX..item.Type);
        unitListing.TrainArmyButton:SetToolTipString(item.ArmyTooltip);
        unitListing.ArmyDisabled:SetToolTipString(item.ArmyTooltip);
        if (listMode == LISTMODE.PRODUCTION or listMode == LISTMODE.PROD_QUEUE) then
          unitListing.TrainArmyButton:RegisterCallback( Mouse.eLClick, function()
            BuildUnitArmy(data.City, item);
            CloseAfterNewProduction();
            end);
        else
          unitListing.TrainArmyButton:RegisterCallback( Mouse.eLClick, function()
            PurchaseUnitArmy(data.City, item);
            Close();
            end);
        end
      end
    end -- end faith/gold check
  end -- end iteration through units

  if (unitList.unitListIM.m_iAllocatedInstances <= 0 and unitList.civilianListIM.m_iAllocatedInstances <= 0) then
    unitList.Top:SetHide(true);
  else
    unitList.Header:RegisterCallback( Mouse.eLClick, function()
      OnExpand(unitList);
      end);
    unitList.HeaderOn:RegisterCallback( Mouse.eLClick, function()
      OnCollapse(unitList);
      end);
  end

  unitList.Top:RegisterSizeChanged(function() OnUnitListSizeChanged(listIM, unitList.Top:GetSizeY()); end);
  OnUnitListSizeChanged(listIM, unitList.Top:GetSizeY());

  OnExpand(unitList);
end

-- ===========================================================================
function OnCorpsToggle( unitList, unitListing )
  local isExpanded = unitListing.CorpsArmyArrow:IsSelected();
  unitListing.CorpsArmyArrow:SetSelected(not isExpanded);
  unitListing.ArmyCorpsDrawer:SetHide(not isExpanded);
  unitList.List:CalculateSize();
  unitList.Top:CalculateSize();
  if(m_CurrentListMode == LISTMODE.PRODUCTION) then
    Controls.ProductionList:CalculateSize();
    Controls.ProductionListScroll:CalculateSize();
  elseif(m_CurrentListMode == LISTMODE.PURCHASE_GOLD) then
    Controls.PurchaseList:CalculateSize();
    Controls.PurchaseListScroll:CalculateSize();
  elseif(m_CurrentListMode == LISTMODE.PURCHASE_FAITH) then
    Controls.PurchaseFaithList:CalculateSize();
    Controls.PurchaseFaithListScroll:CalculateSize();
  end
end

-- ===========================================================================
function ResetFields(pListIM)
  local pParentControl = pListIM.m_ParentControl;
  if pParentControl then
    pParentControl[FIELD_LIST_BUILDING_SIZE_Y]	= 0;
    pParentControl[FIELD_LIST_WONDER_SIZE_Y]	= 0;
    pParentControl[FIELD_LIST_UNIT_SIZE_Y]		= 0;
    pParentControl[FIELD_DISTRICT_LIST]			= nil;
    pParentControl[FIELD_BUILDING_LIST]			= nil;
    pParentControl[FIELD_WONDER_LIST]			= nil;
    pParentControl[FIELD_UNIT_LIST]				= nil;
    pParentControl[FIELD_PROJECTS_LIST]			= nil;
  end
end

-- ===========================================================================
function PopulateList(data, listMode, listIM)
  listIM:ResetInstances();

  Controls.PauseCollapseList:Stop();

  ResetFields(listIM);

  if (listMode == LISTMODE.PRODUCTION or listMode == LISTMODE.PROD_QUEUE) then
    PopulateCurrentProduction(data);

    ResizeProductionScrollList();

    PopulateDistrictsWithNestedBuildings(data, listMode, listIM);
    PopulateWonders(data, listMode, listIM);
  end

  --If we are purchasing, then buildings don't have to be displayed in a nested way
  if (listMode == LISTMODE.PURCHASE_FAITH or listMode == LISTMODE.PURCHASE_GOLD) then
    PopulateDistrictsWithoutNestedBuildings(data, listMode, listIM);
  end

  PopulateUnits(data, listMode, listIM);

  --Projects can only be produced, not purchased
  if (listMode == LISTMODE.PRODUCTION or listMode == LISTMODE.PROD_QUEUE) then
    PopulateProjects(data, listMode, listIM);
  end
end

-- ===========================================================================
function OnLocalPlayerChanged()
  Refresh();
end

-- ===========================================================================
-- Returns ( allReasons )
function ComposeFailureReasonStrings( isDisabled, results )
  if isDisabled and results ~= nil then
    -- Are there any failure reasons?
    local pFailureReasons  = results[CityCommandResults.FAILURE_REASONS];
    if pFailureReasons ~= nil and table.count( pFailureReasons ) > 0 then
      -- Collect them all!
      local allReasons = "";
      for i,v in ipairs(pFailureReasons) do
        allReasons = allReasons .. "[NEWLINE][NEWLINE][COLOR:Red]" .. Locale.Lookup(v) .. "[ENDCOLOR]";
      end
      return allReasons;
    end
  end
  return "";
end
function ComposeProductionCostString( iProductionProgress, iProductionCost)
  -- Show production progress only if there is progress present
  if iProductionCost ~= 0 then
    local costString		 = tostring(iProductionCost);

    if iProductionProgress > 0 then -- Only show fraction if build progress has been made.
      costString = tostring(iProductionProgress) .. "/" .. costString;
    end
    return "[NEWLINE][NEWLINE]" .. TXT_COST .. ": " .. costString .. " [ICON_Production] " .. TXT_PRODUCTION;
  end
  return "";
end

-- Returns ( tooltip, subtitle )
function ComposeUnitCorpsStrings( unit, iProdProgress, pBuildQueue )

  local tooltip = ToolTipHelper.GetUnitToolTip( unit.Hash, MilitaryFormationTypes.CORPS_MILITARY_FORMATION, pBuildQueue );

  local subtitle	 = "";
  if unit.Domain == "DOMAIN_SEA" then
    subtitle = "(" .. LOC_HUD_UNIT_PANEL_FLEET_SUFFIX .. ")";
  else
    subtitle = "(" .. TXT_HUD_UNIT_PANEL_CORPS_SUFFIX .. ")";
  end
  tooltip = tooltip .. ComposeProductionCostString( iProdProgress, pBuildQueue:GetUnitCorpsCost( unit.Index ) );
  return tooltip, subtitle;
end
function ComposeUnitArmyStrings( unit, iProdProgress, pBuildQueue )

  local tooltip = ToolTipHelper.GetUnitToolTip( unit.Hash, MilitaryFormationTypes.ARMY_MILITARY_FORMATION, pBuildQueue );

  local subtitle	 = "";
  if unit.Domain == "DOMAIN_SEA" then
    subtitle = "(" .. TXT_HUD_UNIT_PANEL_ARMADA_SUFFIX .. ")";
  else
    subtitle = "(" .. TXT_HUD_UNIT_PANEL_ARMY_SUFFIX .. ")";
  end
  tooltip = tooltip .. ComposeProductionCostString( iProdProgress, pBuildQueue:GetUnitArmyCost( unit.Index ) );
  return tooltip, subtitle;
end

-- Returns ( isPurchaseable, kEntry )
function ComposeUnitForPurchase( row, pCity, sYield, pYieldSource, sCantAffordKey )
  local YIELD_TYPE 	 = GameInfo.Yields[sYield].Index;

  -- Should we display this option to the player?
  local tParameters = {};
  tParameters[CityCommandTypes.PARAM_UNIT_TYPE] = row.Hash;
  tParameters[CityCommandTypes.PARAM_YIELD_TYPE] = YIELD_TYPE;
  if CityManager.CanStartCommand( pCity, CityCommandTypes.PURCHASE, true, tParameters, false ) then
    local isCanStart, results			 = CityManager.CanStartCommand( pCity, CityCommandTypes.PURCHASE, false, tParameters, true );
    local isDisabled			 = not isCanStart;
    local allReasons			  = ComposeFailureReasonStrings( isDisabled, results );
    local sToolTip 				  = ToolTipHelper.GetUnitToolTip( row.Hash, MilitaryFormationTypes.STANDARD_MILITARY_FORMATION, pCity:GetBuildQueue() ) .. allReasons;
    local isCantAfford			 = false;
    --print ( "UnitBuy ", row.UnitType,isCanStart );

    -- Collect some constants so we don't need to keep calling out to get them.
    local nCityID				 = pCity:GetID();
    local pCityGold				  = pCity:GetGold();
    local TXT_INSUFFIENT_YIELD	 = "[NEWLINE][NEWLINE][COLOR:Red]" .. Locale.Lookup( sCantAffordKey ) .. "[ENDCOLOR]";

    -- Affordability check
    if not pYieldSource:CanAfford( nCityID, row.Hash ) then
      sToolTip = sToolTip .. TXT_INSUFFIENT_YIELD;
      isDisabled = true;
      isCantAfford = true;
    end

    local pBuildQueue			  = pCity:GetBuildQueue();
    local nProductionCost		 = pBuildQueue:GetUnitCost( row.Index );
    local nProductionProgress	 = pBuildQueue:GetUnitProgress( row.Index );
    sToolTip = sToolTip .. "[NEWLINE]---" .. ComposeProductionCostString( nProductionProgress, nProductionCost );

    local kUnit	  = {
      Type				= row.UnitType;
      Name				= row.Name;
      ToolTip				= sToolTip;
      Hash				= row.Hash;
      Kind				= row.Kind;
      Civilian			= row.FormationClass == "FORMATION_CLASS_CIVILIAN";
      Disabled			= isDisabled;
      CantAfford			= isCantAfford,
      Yield				= sYield;
      Cost				= pCityGold:GetPurchaseCost( YIELD_TYPE, row.Hash, MilitaryFormationTypes.STANDARD_MILITARY_FORMATION );
      ReligiousStrength	= row.ReligiousStrength;

      CorpsTurnsLeft	= 0;
      ArmyTurnsLeft	= 0;
      Progress		= 0;
    };

    -- Should we present options for building Corps or Army versions?
    if results ~= nil then
      kUnit.Corps = results[CityOperationResults.CAN_TRAIN_CORPS];
      kUnit.Army = results[CityOperationResults.CAN_TRAIN_ARMY];

      local nProdProgress	 = pBuildQueue:GetUnitProgress( row.Index );
      if kUnit.Corps then
        kUnit.CorpsCost	= pCityGold:GetPurchaseCost( YIELD_TYPE, row.Hash, MilitaryFormationTypes.CORPS_MILITARY_FORMATION );
        kUnit.CorpsTooltip, kUnit.CorpsName = ComposeUnitCorpsStrings( row, nProdProgress, pBuildQueue );
        kUnit.CorpsDisabled = not pYieldSource:CanAfford( nCityID, row.Hash, MilitaryFormationTypes.CORPS_MILITARY_FORMATION );
        if kUnit.CorpsDisabled then
          kUnit.CorpsTooltip = kUnit.CorpsTooltip .. TXT_INSUFFIENT_YIELD;
        end
        tParameters[CityCommandTypes.PARAM_MILITARY_FORMATION_TYPE] = MilitaryFormationTypes.CORPS_MILITARY_FORMATION;
        local bCanPurchase, kResults = CityManager.CanStartCommand( pCity, CityCommandTypes.PURCHASE, false, tParameters, true );
        kUnit.CorpsDisabled = not bCanPurchase;
        if (not bCanPurchase) then
          local sFailureReasons = ComposeFailureReasonStrings( kUnit.CorpsDisabled, kResults );
          kUnit.CorpsTooltip = kUnit.CorpsTooltip .. sFailureReasons;
        end
      end

      if kUnit.Army then
        kUnit.ArmyCost	= pCityGold:GetPurchaseCost( YIELD_TYPE, row.Hash, MilitaryFormationTypes.ARMY_MILITARY_FORMATION );
        kUnit.ArmyTooltip, kUnit.ArmyName = ComposeUnitArmyStrings( row, nProdProgress, pBuildQueue );
        kUnit.ArmyDisabled = not pYieldSource:CanAfford( nCityID, row.Hash, MilitaryFormationTypes.ARMY_MILITARY_FORMATION );
        if kUnit.ArmyDisabled then
          kUnit.ArmyTooltip = kUnit.ArmyTooltip .. TXT_INSUFFIENT_YIELD;
        end
        tParameters[CityCommandTypes.PARAM_MILITARY_FORMATION_TYPE] = MilitaryFormationTypes.ARMY_MILITARY_FORMATION;
        local bCanPurchase, kResults = CityManager.CanStartCommand( pCity, CityCommandTypes.PURCHASE, false, tParameters, true );
        kUnit.ArmyDisabled = not bCanPurchase;
        if (not bCanPurchase) then
          local sFailureReasons = ComposeFailureReasonStrings( kUnit.ArmyDisabled, kResults );
          kUnit.ArmyTooltip = kUnit.ArmyTooltip .. sFailureReasons;
        end
      end
    end

    return true, kUnit;
  end
  return false, nil;
end
function ComposeBldgForPurchase( pRow, pCity, sYield, pYieldSource, sCantAffordKey )
  local YIELD_TYPE 	 = GameInfo.Yields[sYield].Index;

  local tParameters = {};
  tParameters[CityCommandTypes.PARAM_BUILDING_TYPE] = pRow.Hash;
  tParameters[CityCommandTypes.PARAM_YIELD_TYPE] = YIELD_TYPE;
  if CityManager.CanStartCommand( pCity, CityCommandTypes.PURCHASE, true, tParameters, false ) then
    local isCanStart, pResults		 = CityManager.CanStartCommand( pCity, CityCommandTypes.PURCHASE, false, tParameters, true );
    local isDisabled		 = not isCanStart;
    local sAllReasons		  = ComposeFailureReasonStrings( isDisabled, pResults );
    local sToolTip 			  = ToolTipHelper.GetBuildingToolTip( pRow.Hash, playerID, pCity ) .. sAllReasons;
    local isCantAfford		 = false;

    -- Affordability check
    if not pYieldSource:CanAfford( pCity:GetID(), pRow.Hash ) then
      sToolTip = sToolTip .. "[NEWLINE][NEWLINE][COLOR:Red]" .. Locale.Lookup(sCantAffordKey) .. "[ENDCOLOR]";
      isDisabled = true;
      isCantAfford = true;
    end

    local pBuildQueue			  = pCity:GetBuildQueue();
    local iProductionCost		 = pBuildQueue:GetBuildingCost( pRow.Index );
    local iProductionProgress	 = pBuildQueue:GetBuildingProgress( pRow.Index );
    sToolTip = sToolTip .. ComposeProductionCostString( iProductionProgress, iProductionCost );

    local kBuilding  = {
      Type			= pRow.BuildingType,
      Name			= pRow.Name,
      ToolTip			= sToolTip,
      Hash			= pRow.Hash,
      Kind			= pRow.Kind,
      Disabled		= isDisabled,
      CantAfford		= isCantAfford,
      Cost			= pCity:GetGold():GetPurchaseCost( YIELD_TYPE, pRow.Hash ),
      Yield			= sYield
    };
    return true, kBuilding;
  end
  return false, nil;
end

function ComposeDistrictForPurchase( pRow, pCity, sYield, pYieldSource, sCantAffordKey )
  local YIELD_TYPE 	 = GameInfo.Yields[sYield].Index;

  local tParameters = {};
  tParameters[CityCommandTypes.PARAM_DISTRICT_TYPE] = pRow.Hash;
  tParameters[CityCommandTypes.PARAM_YIELD_TYPE] = YIELD_TYPE;
  if CityManager.CanStartCommand( pCity, CityCommandTypes.PURCHASE, true, tParameters, false ) then
    local isCanStart, pResults		 = CityManager.CanStartCommand( pCity, CityCommandTypes.PURCHASE, false, tParameters, true );
    local isDisabled		 = not isCanStart;
    local sAllReasons		 = ComposeFailureReasonStrings( isDisabled, pResults );
    local sToolTip 			 = ToolTipHelper.GetDistrictToolTip( pRow.Hash ) .. sAllReasons;
    local isCantAfford		 = false;

    -- Affordability check
    if not pYieldSource:CanAfford( pCity:GetID(), pRow.Hash ) then
      sToolTip = sToolTip .. "[NEWLINE][NEWLINE][COLOR:Red]" .. Locale.Lookup(sCantAffordKey) .. "[ENDCOLOR]";
      isDisabled = true;
      isCantAfford = true;
    end

    local pBuildQueue			  = pCity:GetBuildQueue();
    local iProductionCost		 = pBuildQueue:GetDistrictCost( pRow.Index );
    local iProductionProgress	 = pBuildQueue:GetDistrictProgress( pRow.Index );
    sToolTip = sToolTip .. ComposeProductionCostString( iProductionProgress, iProductionCost );

    local kDistrict  = {
      Type			= pRow.DistrictType,
      Name			= pRow.Name,
      ToolTip			= sToolTip,
      Hash			= pRow.Hash,
      Kind			= pRow.Kind,
      Disabled		= isDisabled,
      CantAfford		= isCantAfford,
      Cost			= pCity:GetGold():GetPurchaseCost( YIELD_TYPE, pRow.Hash ),
      Yield			= sYield
    };
    return true, kDistrict;
  end
  return false, nil;
end

-- CUI =======================================================================
function Refresh()
  local playerID = Game.GetLocalPlayer();

  local player = Players[playerID];
  if isNil(player) then return; end

  local city = UI.GetHeadSelectedCity();
  if isNil(city)   then return; end

  local data = {};
  if cui_newVersion then
    data = GetPanelData();
    if not isNil(data) then
      CuiResetAllInstances();
      CuiNewVersionView(data);
    else
      Close();
    end
  else
    data = GetData();
    if not isNil(data) then
      CuiResetAllInstances();
      View(data);
    else
      Close();
    end
  end
  --
end

-- ===========================================================================
function GetData()
  local playerID	 = Game.GetLocalPlayer();
  local pPlayer	 = Players[playerID];
  if (pPlayer == nil) then
    Close();
    return nil;
  end

  local pSelectedCity = UI.GetHeadSelectedCity();
  if pSelectedCity == nil then
    Close();
    return nil;
  end

  local cityGrowth	= pSelectedCity:GetGrowth();
  local cityCulture	= pSelectedCity:GetCulture();
  local buildQueue	= pSelectedCity:GetBuildQueue();
  local playerTreasury= pPlayer:GetTreasury();
  local playerReligion= pPlayer:GetReligion();
  local cityGold		= pSelectedCity:GetGold();
  local cityBuildings = pSelectedCity:GetBuildings();
  local cityDistricts = pSelectedCity:GetDistricts();
  local cityID		= pSelectedCity:GetID();

  local new_data = {
    City				= pSelectedCity,
    Population			= pSelectedCity:GetPopulation(),
    Owner				= pSelectedCity:GetOwner(),
    Damage				= pPlayer:GetDistricts():FindID( pSelectedCity:GetDistrictID() ):GetDamage(),
    TurnsUntilGrowth	= cityGrowth:GetTurnsUntilGrowth(),
    CurrentTurnsLeft	= buildQueue:GetTurnsLeft(),
    FoodSurplus			= cityGrowth:GetFoodSurplus(),
    CulturePerTurn		= cityCulture:GetCultureYield(),
    TurnsUntilExpansion = cityCulture:GetTurnsUntilExpansion(),
    DistrictItems		= {},
    BuildingItems		= {},
    UnitItems			= {},
    ProjectItems		= {},
    BuildingPurchases	= {},
    UnitPurchases		= {},
    DistrictPurchases	= {},
  };

  m_CurrentProductionHash = buildQueue:GetCurrentProductionTypeHash();
  m_PreviousProductionHash = buildQueue:GetPreviousProductionTypeHash();

  --Must do districts before buildings
  for row in GameInfo.Districts() do
    if row.Hash == m_CurrentProductionHash then
      new_data.CurrentProduction = row.Name;

      if(GameInfo.DistrictReplaces[row.DistrictType] ~= nil) then
        new_data.CurrentProductionType = GameInfo.DistrictReplaces[row.DistrictType].ReplacesDistrictType;
      else
        new_data.CurrentProductionType = row.DistrictType;
      end
    end

    local isInPanelList 		 = (row.Hash ~= m_CurrentProductionHash or not row.OnePerCity) and not row.InternalOnly;
    local bHasProducedDistrict	 = cityDistricts:HasDistrict( row.Index );
    if isInPanelList and ( buildQueue:CanProduce( row.Hash, true ) or bHasProducedDistrict ) then
      local isCanProduceExclusion, results = buildQueue:CanProduce( row.Hash, false, true );
      local isDisabled			 = not isCanProduceExclusion;

      -- If at least one valid plot is found where the district can be built, consider it buildable.
      local plots  = GetCityRelatedPlotIndexesDistrictsAlternative( pSelectedCity, row.Hash );
      if plots == nil or table.count(plots) == 0 then
        -- No plots available for district. Has player had already started building it?
        local isPlotAllocated  = false;
        local pDistricts 		 = pSelectedCity:GetDistricts();
        for _, pCityDistrict in pDistricts:Members() do
          if row.Index == pCityDistrict:GetType() then
            isPlotAllocated = true;
            break;
          end
        end
        -- If not, this district can't be built. Guarantee that isDisabled is set.
        if not isPlotAllocated then
          isDisabled = true;
        elseif results ~= nil then
          local pFailureReasons  = results[CityCommandResults.FAILURE_REASONS];
          if pFailureReasons ~= nil and table.count( pFailureReasons ) > 0 then
            for i,v in ipairs(pFailureReasons) do
              if v == TXT_DISTRICT_REPAIR_LOCATION_FLOODED then
                isDisabled = true;
                break;
              end
            end
          end
        end
      elseif isDisabled and results ~= nil then
        -- TODO this should probably be handled in the exposure, for example:
        -- BuildQueue::CanProduce(nDistrictHash, bExclusionTest, bReturnResults, bAllowPurchasingPlots)
        local pFailureReasons  = results[CityCommandResults.FAILURE_REASONS];
        if pFailureReasons ~= nil and table.count( pFailureReasons ) > 0 then
          -- There are available plots to purchase, it could still be available
          isDisabled = false;
          for i,v in ipairs(pFailureReasons) do
            -- If its disabled for another reason, keep it disabled
            if v ~= "LOC_DISTRICT_ZONE_NO_SUITABLE_LOCATION" then
              isDisabled = true;
              break;
            end
          end
        end
      end

      local allReasons			 = ComposeFailureReasonStrings( isDisabled, results );
      local sToolTip				 = ToolTipHelper.GetToolTip(row.DistrictType, Game.GetLocalPlayer()) .. allReasons;

      local iProductionCost		 = buildQueue:GetDistrictCost( row.Index );
      local iProductionProgress	 = buildQueue:GetDistrictProgress( row.Index );
      sToolTip = sToolTip .. ComposeProductionCostString( iProductionProgress, iProductionCost );

      local bIsContaminated = cityDistricts:IsContaminated( row.Index );
      local iContaminatedTurns = 0;
      if bIsContaminated then
        for _, pDistrict in cityDistricts:Members() do
          local kDistrictDef = GameInfo.Districts[pDistrict:GetType()];
          if kDistrictDef.PrimaryKey == row.DistrictType then
            local kFalloutManager = Game.GetFalloutManager();
            local pDistrictPlot = Map.GetPlot(pDistrict:GetX(), pDistrict:GetY());
            iContaminatedTurns = kFalloutManager:GetFalloutTurnsRemaining(pDistrictPlot:GetIndex());
          end
        end
      end

      table.insert( new_data.DistrictItems, {
        Type				= row.DistrictType,
        Name				= row.Name,
        ToolTip				= sToolTip,
        Hash				= row.Hash,
        Kind				= row.Kind,
        TurnsLeft			= buildQueue:GetTurnsLeft( row.DistrictType ),
        Disabled			= isDisabled,
        Repair				= cityDistricts:IsPillaged( row.Index ),
        Contaminated		= bIsContaminated,
        ContaminatedTurns	= iContaminatedTurns,
        Cost				= iProductionCost,
        Progress			= iProductionProgress,
        HasBeenBuilt		= bHasProducedDistrict
      });
    end

    -- Can it be purchased with gold?
    local isAllowed, kDistrict = ComposeDistrictForPurchase( row, pSelectedCity, "YIELD_GOLD", playerTreasury, "LOC_BUILDING_INSUFFICIENT_FUNDS" );
    if isAllowed then
      table.insert( new_data.DistrictPurchases, kDistrict );
    end

    -- Can it be purchased with faith?
    local isAllowed, kDistrict = ComposeDistrictForPurchase( row, pSelectedCity, "YIELD_FAITH", playerReligion, "LOC_BUILDING_INSUFFICIENT_FAITH" );
    if isAllowed then
      table.insert( new_data.DistrictPurchases, kDistrict );
    end
  end

  --Must do buildings after districts
  for row in GameInfo.Buildings() do
    if row.Hash == m_CurrentProductionHash then
      new_data.CurrentProduction = row.Name;
      new_data.CurrentProductionType= row.BuildingType;
    end

    local bCanProduce = buildQueue:CanProduce( row.Hash, true );
    local iPrereqDistrict = "";
    if row.PrereqDistrict ~= nil then
      iPrereqDistrict = row.PrereqDistrict;

      --Only add buildings if the prereq district is not the current production (this can happen when repairing)
      if new_data.CurrentProductionType == row.PrereqDistrict then
        bCanProduce = false;
      end
    end

    if row.Hash ~= m_CurrentProductionHash and (not row.MustPurchase or cityBuildings:IsPillaged(row.Hash)) and bCanProduce then
      local isCanStart, results			 = buildQueue:CanProduce( row.Hash, false, true );
      local isDisabled			 = not isCanStart;

      -- Did it fail and it is a Wonder?  If so, if it failed because of *just* NO_SUITABLE_LOCATION, we can look for an alternate.
      if (isDisabled and row.IsWonder and results ~= nil and results[CityOperationResults.NO_SUITABLE_LOCATION] ~= nil and results[CityOperationResults.NO_SUITABLE_LOCATION] == true) then
        local pPurchaseablePlots  = GetCityRelatedPlotIndexesWondersAlternative( pSelectedCity, row.Hash );
        if (pPurchaseablePlots and #pPurchaseablePlots > 0) then
          isDisabled = false;
        end
      end

      local allReasons			  = ComposeFailureReasonStrings( isDisabled, results );
      local sToolTip 				  = ToolTipHelper.GetBuildingToolTip( row.Hash, playerID, pSelectedCity ) .. allReasons;

      local iProductionCost		 = buildQueue:GetBuildingCost( row.Index );
      local iProductionProgress	 = buildQueue:GetBuildingProgress( row.Index );
      sToolTip = sToolTip .. ComposeProductionCostString( iProductionProgress, iProductionCost );

      table.insert( new_data.BuildingItems, {
        Type			= row.BuildingType,
        Name			= row.Name,
        ToolTip			= sToolTip,
        Hash			= row.Hash,
        Kind			= row.Kind,
        TurnsLeft		= buildQueue:GetTurnsLeft( row.Hash ),
        Disabled		= isDisabled,
        Repair			= cityBuildings:IsPillaged( row.Hash ),
        Cost			= iProductionCost,
        Progress		= iProductionProgress,
        IsWonder		= row.IsWonder,
        PrereqDistrict	= iPrereqDistrict,
        PrereqBuildings	= row.PrereqBuildingCollection
      });
    end

    -- Can it be purchased with gold?
    if row.PurchaseYield == "YIELD_GOLD" then
      local isAllowed, kBldg = ComposeBldgForPurchase( row, pSelectedCity, "YIELD_GOLD", playerTreasury, "LOC_BUILDING_INSUFFICIENT_FUNDS" );
      if isAllowed then
        table.insert( new_data.BuildingPurchases, kBldg );
      end
    end
    -- Can it be purchased with faith?
    if row.PurchaseYield == "YIELD_FAITH" or cityGold:IsBuildingFaithPurchaseEnabled( row.Hash ) then
      local isAllowed, kBldg = ComposeBldgForPurchase( row, pSelectedCity, "YIELD_FAITH", playerReligion, "LOC_BUILDING_INSUFFICIENT_FAITH" );
      if isAllowed then
        table.insert( new_data.BuildingPurchases, kBldg );
      end
    end
  end

  -- Sort BuildingItems to ensure Buildings are placed behind any Prereqs for that building
  table.sort(new_data.BuildingItems,
    function(a, b)
      if a.IsWonder then
        return false;
      end
      if a.Disabled == false and b.Disabled == true then
        return true;
      end
      return false;
    end
  );

  for row in GameInfo.Units() do
    if row.Hash == m_CurrentProductionHash then
      new_data.CurrentProduction = row.Name;
      new_data.CurrentProductionType= row.UnitType;
    end

    local kBuildParameters = {};
    kBuildParameters.UnitType = row.Hash;
    kBuildParameters.MilitaryFormationType = MilitaryFormationTypes.STANDARD_MILITARY_FORMATION;

    -- Can it be built normally?
    if not row.MustPurchase and buildQueue:CanProduce( kBuildParameters, true ) then
      local isCanProduceExclusion, results	 = buildQueue:CanProduce( kBuildParameters, false, true );
      local isDisabled				 = not isCanProduceExclusion;
      local sAllReasons				  = ComposeFailureReasonStrings( isDisabled, results );
      local sToolTip					  = ToolTipHelper.GetUnitToolTip( row.Hash, MilitaryFormationTypes.STANDARD_MILITARY_FORMATION, buildQueue ) .. sAllReasons;

      local nProductionCost		 = buildQueue:GetUnitCost( row.Index );
      local nProductionProgress	 = buildQueue:GetUnitProgress( row.Index );
      sToolTip = sToolTip .. ComposeProductionCostString( nProductionProgress, nProductionCost );

      local kUnit  = {
        Type				= row.UnitType,
        Name				= row.Name,
        ToolTip				= sToolTip,
        Hash				= row.Hash,
        Kind				= row.Kind,
        TurnsLeft			= buildQueue:GetTurnsLeft( row.Hash ),
        Disabled			= isDisabled,
        Civilian			= row.FormationClass == "FORMATION_CLASS_CIVILIAN",
        Cost				= nProductionCost,
        Progress			= nProductionProgress,
        Corps				= false,
        CorpsCost			= 0,
        CorpsTurnsLeft		= 1,
        CorpsTooltip		= "",
        CorpsName			= "",
        Army				= false,
        ArmyCost			= 0,
        ArmyTurnsLeft		= 1,
        ArmyTooltip			= "",
        ArmyName			= "",
        ReligiousStrength	= row.ReligiousStrength,
        IsCurrentProduction = row.Hash == m_CurrentProductionHash
      };

      -- Should we present options for building Corps or Army versions?
      if results ~= nil then
        if results[CityOperationResults.CAN_TRAIN_CORPS] then
          kBuildParameters.MilitaryFormationType = MilitaryFormationTypes.CORPS_MILITARY_FORMATION;
          local bCanProduceCorps, kResults = buildQueue:CanProduce( kBuildParameters, false, true);
          kUnit.Corps			= true;
          kUnit.CorpsDisabled = not bCanProduceCorps;
          kUnit.CorpsCost		= buildQueue:GetUnitCorpsCost( row.Index );
          kUnit.CorpsTurnsLeft	= buildQueue:GetTurnsLeft( row.Hash, MilitaryFormationTypes.CORPS_MILITARY_FORMATION );
          kUnit.CorpsTooltip, kUnit.CorpsName = ComposeUnitCorpsStrings( row, nProductionProgress, buildQueue );
          local sFailureReasons = ComposeFailureReasonStrings( kUnit.CorpsDisabled, kResults );
          kUnit.CorpsTooltip = kUnit.CorpsTooltip .. sFailureReasons;
        end
        if results[CityOperationResults.CAN_TRAIN_ARMY] then
          kBuildParameters.MilitaryFormationType = MilitaryFormationTypes.ARMY_MILITARY_FORMATION;
          local bCanProduceArmy, kResults = buildQueue:CanProduce( kBuildParameters, false, true );
          kUnit.Army			= true;
          kUnit.ArmyDisabled	= not bCanProduceArmy;
          kUnit.ArmyCost		= buildQueue:GetUnitArmyCost( row.Index );
          kUnit.ArmyTurnsLeft	= buildQueue:GetTurnsLeft( row.Hash, MilitaryFormationTypes.ARMY_MILITARY_FORMATION );
          kUnit.ArmyTooltip, kUnit.ArmyName = ComposeUnitArmyStrings( row, nProductionProgress, buildQueue );
          local sFailureReasons = ComposeFailureReasonStrings( kUnit.ArmyDisabled, kResults );
          kUnit.ArmyTooltip = kUnit.ArmyTooltip .. sFailureReasons;
        end
      end

      table.insert(new_data.UnitItems, kUnit );
    end

    -- Can it be purchased with gold?
    if row.PurchaseYield == "YIELD_GOLD" then
      local isAllowed, kUnit = ComposeUnitForPurchase( row, pSelectedCity, "YIELD_GOLD", playerTreasury, "LOC_BUILDING_INSUFFICIENT_FUNDS" );
      if isAllowed then
        table.insert( new_data.UnitPurchases, kUnit );
      end
    end
    -- Can it be purchased with faith?
    if row.PurchaseYield == "YIELD_FAITH" or cityGold:IsUnitFaithPurchaseEnabled( row.Hash ) then
      local isAllowed, kUnit = ComposeUnitForPurchase( row, pSelectedCity, "YIELD_FAITH", playerReligion, "LOC_BUILDING_INSUFFICIENT_FAITH" );
      if isAllowed then
        table.insert( new_data.UnitPurchases, kUnit );
      end
    end
  end

  if (pBuildQueue == nil) then
    pBuildQueue = pSelectedCity:GetBuildQueue();
  end

  for row in GameInfo.Projects() do
    if row.Hash == m_CurrentProductionHash then
      new_data.CurrentProduction = row.Name;
      new_data.CurrentProductionType= row.ProjectType;
    end

    if buildQueue:CanProduce( row.Hash, true ) then
      local isCanProduceExclusion, results = buildQueue:CanProduce( row.Hash, false, true );
      local isDisabled			 = not isCanProduceExclusion;

      local allReasons			= ComposeFailureReasonStrings( isDisabled, results );
      local sToolTip			 = ToolTipHelper.GetProjectToolTip( row.Hash) .. allReasons;

      local iProductionCost		 = buildQueue:GetProjectCost( row.Index );
      local iProductionProgress	 = buildQueue:GetProjectProgress( row.Index );
      sToolTip = sToolTip .. ComposeProductionCostString( iProductionProgress, iProductionCost );

      table.insert(new_data.ProjectItems, {
        Type				= row.ProjectType,
        Name				= row.Name,
        ToolTip				= sToolTip,
        Hash				= row.Hash,
        Kind				= row.Kind,
        TurnsLeft			= buildQueue:GetTurnsLeft( row.ProjectType ),
        Disabled			= isDisabled,
        Cost				= iProductionCost,
        Progress			= iProductionProgress,
        IsCurrentProduction = row.Hash == m_CurrentProductionHash,
        IsRepeatable		= row.MaxPlayerInstances ~= 1 and true or false,
      });
    end
  end

  return new_data;
end

-- ===========================================================================
function ShowHideDisabled()
  m_showDisabled = not m_showDisabled;
  Refresh();
end

-- ===========================================================================
--	LUA Event
-- ===========================================================================
function OnCityPanelChooseProduction()
  if (ContextPtr:IsHidden()) then
    Refresh();
  else
    if (m_tabs.selectedControl ~= m_productionTab) then
      m_tabs.SelectTab(m_productionTab);
    end
  end
end

-- ===========================================================================
--	LUA Event
-- ===========================================================================
function OnNotificationPanelChooseProduction()
  if ContextPtr:IsHidden() then
    Open();
    -- CUI
    if cui_QueueOnDetault then
      m_tabs.SelectTab(m_queueTab);
    else
      m_tabs.SelectTab(m_productionTab);
    end
    --
  end
end

-- ===========================================================================
--	LUA Event
-- ===========================================================================
function OnCityPanelChoosePurchase()
  if (ContextPtr:IsHidden()) then
    Refresh();
    OnTabChangePurchase();
    m_tabs.SelectTab(m_purchaseTab);
  else
    if (m_tabs.selectedControl ~= m_purchaseTab) then
      OnTabChangePurchase();
      m_tabs.SelectTab(m_purchaseTab);
    end
  end
end

-- ===========================================================================
--	LUA Event
-- ===========================================================================
function OnCityPanelChoosePurchaseFaith()
  if (ContextPtr:IsHidden()) then
    Refresh();
    OnTabChangePurchaseFaith();
    m_tabs.SelectTab(m_faithTab);
  else
    if (m_tabs.selectedControl ~= m_faithTab) then
      OnTabChangePurchaseFaith();
      m_tabs.SelectTab(m_faithTab);
    end
  end
end

-- ===========================================================================
--	LUA Event
--	Outside source is signaling production should be closed if open.
-- ===========================================================================
function OnProductionClose()
  if not ContextPtr:IsHidden() then
    Close();
  end
end

-- ===========================================================================
--	LUA Event
--	Production opened from city banner (anchored to world view)
-- ===========================================================================
function OnCityBannerManagerProductionToggle()
  if(ContextPtr:IsHidden()) then
    Open();
    -- CUI
    if cui_QueueOnDetault then
      m_tabs.SelectTab(m_queueTab);
    else
      m_tabs.SelectTab(m_productionTab);
    end
    --
  else
    Close();
  end
end

-- ===========================================================================
--	LUA Event
--	Production opened from city information panel
-- ===========================================================================
function OnCityPanelProductionOpen()
  Open();
  -- CUI
  if cui_QueueOnDetault then
    m_tabs.SelectTab(m_queueTab);
  else
    m_tabs.SelectTab(m_productionTab);
  end
  --
end

-- ===========================================================================
--	LUA Event
--	Production opened from city information panel - Purchase with faith check
-- ===========================================================================
function OnCityPanelPurchaseFaithOpen()
  Open();
  m_tabs.SelectTab(m_faithTab);
end

-- ===========================================================================
--	LUA Event
--	Production opened from city information panel - Purchase with gold check
-- ===========================================================================
function OnCityPanelPurchaseGoldOpen()
  Open();
  m_tabs.SelectTab(m_purchaseTab);
end
-- ===========================================================================
--	LUA Event
--	Production opened from a placement
-- ===========================================================================
function OnStrategicViewMapPlacementProductionOpen( bWasCancelled )
  if m_isQueueOpen then
    Open();
    m_tabs.SelectTab(m_queueTab);
  elseif m_isManagerOpen then
    Open();
    m_tabs.SelectTab(m_managerTab);
  elseif bWasCancelled then
    Open();
  end
end

-- ===========================================================================
--	LUA Event
-- ===========================================================================
function OnTutorialProductionOpen()
  Open();
end

-- ===========================================================================
--	LUA Event
-- ===========================================================================
function OnProductionOpenForQueue()
  Open();
end

-- ===========================================================================
--	LUA Event
-- ===========================================================================
function OnCityPanelPurchasePlot()
  Close();
end

-- ===========================================================================
--	LUA Event
--	Set cached values back after a hotload.
-- ===========================================================================
function OnGameDebugReturn( context, contextTable )
  if context ~= RELOAD_CACHE_ID then return; end

  local isHidden = contextTable["isHidden"];
  if not isHidden then
    Refresh();

    local listMode = contextTable["listMode"];
    if listMode then
      if listMode == LISTMODE.PRODUCTION then
        m_tabs.SelectTab( m_productionTab );
      elseif listMode == LISTMODE.PURCHASE_GOLD then
        m_tabs.SelectTab( m_purchaseTab );
      elseif listMode == LISTMODE.PURCHASE_FAITH then
        m_tabs.SelectTab( m_faithTab );
      elseif listMode == LISTMODE.PROD_QUEUE then
        m_tabs.SelectTab( m_queueTab );
      end
    end
  end
end

-- ===========================================================================
--	Keyboard INPUT Handler
-- ===========================================================================
function KeyHandler( key )
  if (key == Keys.VK_ESCAPE) then
    if m_kSelectedQueueItem.Index ~= -1 then
      DeselectItem();
    elseif m_SelectedManagerIndex ~= -1 then
      LuaEvents.ProductionPanel_CancelManagerSelection();
    else
      Close();
    end
    return true;
  end
  return false;
end

-- ===========================================================================
--	UI Event
-- ===========================================================================
function OnInputHandler( pInputStruct )
  local uiMsg = pInputStruct:GetMessageType();
  if uiMsg == KeyEvents.KeyUp then
    return KeyHandler( pInputStruct:GetKey() );
  end;
  return false;
end

-- ===========================================================================
--	UI Event
-- ===========================================================================
function OnInit( isReload )
  if isReload then
    LuaEvents.GameDebug_GetValues( RELOAD_CACHE_ID );
  end
end

-- ===========================================================================
--	UI Event
-- ===========================================================================
function OnShutdown()
  LuaEvents.GameDebug_AddValue(RELOAD_CACHE_ID,  "isHidden",		ContextPtr:IsHidden() );
  LuaEvents.GameDebug_AddValue(RELOAD_CACHE_ID,  "listMode",		m_CurrentListMode );
end

-- ===========================================================================
-- ===========================================================================
function CreateCorrectTabs()
  local MAX_TAB_LABEL_WIDTH = 273;
  local productionLabelX = Controls.ProductionTab:GetTextControl():GetSizeX();
  local purchaseLabelX = Controls.PurchaseTab:GetTextControl():GetSizeX();
  local purchaseFaithLabelX = Controls.PurchaseFaithTab:GetTextControl():GetSizeX();
  local tabAnimControl;
  local tabArrowControl;
  local tabSizeX;
  local tabSizeY;

    Controls.ProductionTab:RegisterCallback( Mouse.eMouseEnter,	function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
    Controls.PurchaseTab:RegisterCallback( Mouse.eMouseEnter,	function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
    Controls.PurchaseFaithTab:RegisterCallback( Mouse.eMouseEnter,	function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
    Controls.MiniProductionTab:RegisterCallback( Mouse.eMouseEnter,	function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
    Controls.MiniPurchaseTab:RegisterCallback( Mouse.eMouseEnter,	function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
    Controls.MiniPurchaseFaithTab:RegisterCallback( Mouse.eMouseEnter,	function() UI.PlaySound("Main_Menu_Mouse_Over"); end);

  Controls.MiniProductionTab:SetHide(true);
  Controls.MiniPurchaseTab:SetHide(true);
  Controls.MiniPurchaseFaithTab:SetHide(true);
  Controls.ProductionTab:SetHide(true);
  Controls.PurchaseTab:SetHide(true);
  Controls.PurchaseFaithTab:SetHide(true);
  Controls.QueueTab:SetHide(true);
  Controls.ManagerTab:SetHide(true);
  Controls.MiniTabAnim:SetHide(true);
  Controls.MiniTabArrow:SetHide(true);
  Controls.TabAnim:SetHide(true);
  Controls.TabArrow:SetHide(true);

  local labelWidth = productionLabelX + purchaseLabelX;
  if GameCapabilities.HasCapability("CAPABILITY_FAITH") then
    labelWidth = labelWidth + purchaseFaithLabelX;
  end
  -- CUI
  -- if(labelWidth > MAX_TAB_LABEL_WIDTH) then
  if (false) then
  --
    tabSizeX = 44;
    tabSizeY = 44;
    Controls.MiniProductionTab:SetHide(false);
    Controls.MiniPurchaseTab:SetHide(false);
    Controls.MiniPurchaseFaithTab:SetHide(false);
    Controls.MiniTabAnim:SetHide(false);
    Controls.MiniTabArrow:SetHide(false);
    m_productionTab = Controls.MiniProductionTab;
    m_purchaseTab	= Controls.MiniPurchaseTab;
    m_faithTab		= Controls.MiniPurchaseFaithTab;
    tabAnimControl	= Controls.MiniTabAnim;
    tabArrowControl = Controls.MiniTabArrow;
  else
    -- CUI
    tabSizeX = 44;
    tabSizeY = 44;
    --
    Controls.ProductionTab:SetHide(false);
    Controls.PurchaseTab:SetHide(false);
    Controls.PurchaseFaithTab:SetHide(false);
    if not m_isTutorialRunning and not m_tutorialTestMode then
      Controls.QueueTab:SetHide(false);
      Controls.ManagerTab:SetHide(false);
    end
    Controls.TabAnim:SetHide(false);
    Controls.TabArrow:SetHide(false);
    m_productionTab = Controls.ProductionTab;
    m_purchaseTab	  = Controls.PurchaseTab;
    m_faithTab		  = Controls.PurchaseFaithTab;
    m_queueTab		  = Controls.QueueTab;
    m_managerTab	  = Controls.ManagerTab;
    tabAnimControl	= Controls.TabAnim;
    tabArrowControl = Controls.TabArrow;
  end

  m_tabs = CreateTabs( Controls.TabRow, tabSizeX, UI.GetColorValueFromHexLiteral(0xFF331D05) );
  m_tabs.AddTab( m_productionTab,	OnTabChangeProduction );
  if GameCapabilities.HasCapability("CAPABILITY_GOLD") then
    m_tabs.AddTab( m_purchaseTab,	OnTabChangePurchase );
  else
    Controls.PurchaseTab:SetHide(true);
    Controls.MiniPurchaseTab:SetHide(true);
  end
  if GameCapabilities.HasCapability("CAPABILITY_FAITH") then
    m_tabs.AddTab( m_faithTab,	OnTabChangePurchaseFaith );
  else
    Controls.MiniPurchaseFaithTab:SetHide(true);
    Controls.PurchaseFaithTab:SetHide(true);
  end
  if not m_isTutorialRunning and not m_tutorialTestMode then
    m_tabs.AddTab( m_queueTab,		OnTabChangeQueue );
    m_tabs.AddTab( m_managerTab,	OnTabChangeManager );
  end

  -- CUI
  m_tabs.CenterAlignTabs(-10, 350, 44);
  if cui_QueueOnDetault then
    m_tabs.SelectTab(m_queueTab);
  else
    m_tabs.SelectTab(m_productionTab);
  end
  --
  m_tabs.AddAnimDeco(tabAnimControl, tabArrowControl);
end

---------------------------------------------------
function SetScrollPosition(modeIndex, scrollAmount)
  if m_PlayerScrollPositions[Game.GetLocalPlayer()] == nil then
    m_PlayerScrollPositions[Game.GetLocalPlayer()] = {};
  end

  local scrollPosTable = m_PlayerScrollPositions[Game.GetLocalPlayer()];

  scrollPosTable[modeIndex] = scrollAmount;
end

---------------------------------------------------
function GetScrollPosition(modeIndex)
  local scrollPosTable = m_PlayerScrollPositions[Game.GetLocalPlayer()];
  if scrollPosTable ~= nil then
    return scrollPosTable[modeIndex];
  end

  return 0;
end

-- ===========================================================================
function OnProductionListScrolled(scrollPanel, scrollAmount)
  if not ContextPtr:IsHidden() then
    SetScrollPosition(LISTMODE.PRODUCTION, scrollAmount);
  end
end

-- ===========================================================================
function OnPurchaseListScrolled(scrollPanel, scrollAmount)
  if not ContextPtr:IsHidden() then
    SetScrollPosition(LISTMODE.PURCHASE_GOLD, scrollAmount);
  end
end

-- ===========================================================================
function OnPurchaseFaithListScrolled(scrollPanel, scrollAmount)
  if not ContextPtr:IsHidden() then
    SetScrollPosition(LISTMODE.PURCHASE_FAITH, scrollAmount);
  end
end

-- ===========================================================================
function OnQueueListScrolled(scrollPanel, scrollAmount)
  if not ContextPtr:IsHidden() then
    SetScrollPosition(LISTMODE.PROD_QUEUE, scrollAmount);
  end
end

-- ===========================================================================
function OpenManager()
  m_isManagerOpen = true;
  LuaEvents.ProductionPanel_OpenManager();
end

-- ===========================================================================
function CloseManager()
  m_isManagerOpen = false;
  LuaEvents.ProductionPanel_CloseManager();
end

-- ===========================================================================
function CloseAfterNewProduction()
  if not m_isQueueOpen and not m_isManagerOpen then
    Close();
  end
end

-- ===========================================================================
function OpenQueue()
  m_isQueueOpen = true;
  Controls.QueueContainer:SetHide(false);
end

-- ===========================================================================
function CloseQueue()
  m_isQueueOpen = false;
  Controls.QueueContainer:SetHide(true);
end

-- ===========================================================================
function RefreshQueue(playerID, cityID)
  if m_isTutorialRunning or m_tutorialTestMode then
    return;
  end

  DeselectItem();

  local pCity = CityManager.GetCity(playerID, cityID);
  local pBuildQueue = pCity:GetBuildQueue();

  -- Subtract one so we don't count the current production as queued
  local offsetQueueSize = pBuildQueue:GetSize() - 1;
  UpdateQueueTabText(offsetQueueSize >= 0 and offsetQueueSize or 0);

  m_QueueInstanceIM:ResetInstances();

  -- Display queues items after the first which is shown as the current production
  for i = 1, MAX_QUEUE_SIZE do
    local entry = pBuildQueue:GetAt(i);
    local queueInstance = CreateQueueInstance( m_QueueInstanceIM, Controls.QueueStack, playerID, cityID, i, entry );
    queueInstance.Top:RegisterCallback( Mouse.eLClick, function() OnItemClicked( queueInstance, queueInstance.Top ); end );
    queueInstance.Top:RegisterCallback( Mouse.eRClick, function() RemoveQueueItem(i); end );
    queueInstance.Num:SetText( tostring(i+1) );		-- Start at 2
  end

  UpdateDisabledButtons();
end

-- ===========================================================================
function DeselectItem()
  if m_kSelectedQueueItem.Parent ~= nil then
    local kParentControl = m_kSelectedQueueItem.Parent;
    if kParentControl.ProductionIcon ~= nil then
      kParentControl.ProductionIcon:SetAlpha(1.0);
    end
  end

  m_kSelectedQueueItem.Parent = nil;
  m_kSelectedQueueItem.Button = nil;
  m_kSelectedQueueItem.Index = -1;

  DisableMouseIcon();
  HighlightButtons(false);
end

-- ===========================================================================
function SelectItem( kParentControl, kButtonControl )
  if kParentControl ~= nil and kParentControl[FIELD_QUEUE_INDEX] then
    if kParentControl.ProductionIcon ~= nil then
      kParentControl.ProductionIcon:SetAlpha(SELECTED_ICON_ALPHA);
    end

    m_kSelectedQueueItem.Parent = kParentControl;
    m_kSelectedQueueItem.Button = kButtonControl;
    m_kSelectedQueueItem.Index = kParentControl[FIELD_QUEUE_INDEX];

    EnableMouseIcon(kParentControl[FIELD_ICON_TEXTURE]);
    HighlightButtons(true);
  end
end

-- ===========================================================================
function OnTrashClicked()
  if m_kSelectedQueueItem.Index ~= -1 then
    RemoveQueueItem(m_kSelectedQueueItem.Index);
  end
end

-- ===========================================================================
function UpdateDisabledButtons()
  for i=1, m_QueueInstanceIM.m_iCount, 1 do
    local instance = m_QueueInstanceIM:GetAllocatedInstance(i);
    if instance then
      instance.Top:SetSelected(false);
      instance.Top:SetDisabled( instance[FIELD_QUEUE_INDEX] == -1 );
    end
  end
end

-- ===========================================================================
function OnItemClicked( kParentControl, kButtonControl )
  if m_kSelectedQueueItem.Index == -1 then
    SelectItem(kParentControl, kButtonControl);
  elseif m_kSelectedQueueItem.Index ~= kParentControl[FIELD_QUEUE_INDEX] then
    SwapQueueItem(m_kSelectedQueueItem.Index, kParentControl[FIELD_QUEUE_INDEX]);
  else
    DeselectItem();
  end
end

-- ===========================================================================
function HighlightButtons( bShouldHighlight )

  Controls.CurrentProductionButton:SetSelected(bShouldHighlight);

  for i=1, m_QueueInstanceIM.m_iCount, 1 do
    local instance = m_QueueInstanceIM:GetAllocatedInstance(i);
    if instance then
      if instance[FIELD_QUEUE_INDEX] ~= -1 then
        instance.Top:SetSelected(bShouldHighlight);
      end
    end
  end

  Controls.TrashButton:SetSelected(bShouldHighlight);
  Controls.TrashButton:SetDisabled(not bShouldHighlight);
end

-- ===========================================================================
function OnBuildingListSizeChanged(listIM, sizeY)
  local kListParent = listIM.m_ParentControl;
  if kListParent then
    kListParent[FIELD_LIST_BUILDING_SIZE_Y] = sizeY;
  end
end

-- ===========================================================================
function OnWonderListSizeChanged(listIM, sizeY)
  local kListParent = listIM.m_ParentControl;
  if kListParent then
    kListParent[FIELD_LIST_WONDER_SIZE_Y] = sizeY;
  end
end

-- ===========================================================================
function OnUnitListSizeChanged(listIM, sizeY)
  local kListParent = listIM.m_ParentControl;
  if kListParent then
    kListParent[FIELD_LIST_UNIT_SIZE_Y] = sizeY;
  end
end

-- ===========================================================================
function OnBuildingsButtonClicked()
  -- Building/District list is always at the top
  if m_CurrentListMode == LISTMODE.PRODUCTION then
    Controls.ProductionListScroll:SetScrollValue(0.0);
  elseif m_CurrentListMode == LISTMODE.PROD_QUEUE then
    Controls.QueueListScroll:SetScrollValue(0.0);
  elseif m_CurrentListMode == LISTMODE.PURCHASE_GOLD then
    Controls.PurchaseListScroll:SetScrollValue(0.0);
  elseif m_CurrentListMode == LISTMODE.PURCHASE_FAITH then
    Controls.PurchaseFaithListScroll:SetScrollValue(0.0);
  end
end

-- ===========================================================================
function OnWondersButtonClicked()
  if m_CurrentListMode == LISTMODE.PRODUCTION then
    ScrollToWonderList(Controls.ProductionList, Controls.ProductionListScroll);
  elseif m_CurrentListMode == LISTMODE.PROD_QUEUE then
    ScrollToWonderList(Controls.QueueList, Controls.QueueListScroll);
  end
end

-- ===========================================================================
function ScrollToWonderList(kListStack, kListScroll)
  local desiredScrollValue = kListStack[FIELD_LIST_BUILDING_SIZE_Y] / (kListStack:GetSizeY() - kListScroll:GetSizeY());
  kListScroll:SetScrollValue(desiredScrollValue);
end

-- ===========================================================================
function OnUnitsButtonClicked()
  if m_CurrentListMode == LISTMODE.PRODUCTION then
    ScrollToUnitList(Controls.ProductionList, Controls.ProductionListScroll);
  elseif m_CurrentListMode == LISTMODE.PROD_QUEUE then
    ScrollToUnitList(Controls.QueueList, Controls.QueueListScroll);
  elseif m_CurrentListMode == LISTMODE.PURCHASE_GOLD then
    ScrollToUnitList(Controls.PurchaseList, Controls.PurchaseListScroll);
  elseif m_CurrentListMode == LISTMODE.PURCHASE_FAITH then
    ScrollToUnitList(Controls.PurchaseFaithList, Controls.PurchaseFaithListScroll);
  end
end

-- ===========================================================================
function ScrollToUnitList(kListStack, kListScroll)
  local desiredScrollValue = (kListStack[FIELD_LIST_BUILDING_SIZE_Y] + kListStack[FIELD_LIST_WONDER_SIZE_Y]) / (kListStack:GetSizeY() - kListScroll:GetSizeY());
  kListScroll:SetScrollValue(desiredScrollValue);
end

-- ===========================================================================
function OnProjectsButtonClicked()
  if m_CurrentListMode == LISTMODE.PRODUCTION then
    ScrollToProjectList(Controls.ProductionList, Controls.ProductionListScroll);
  elseif m_CurrentListMode == LISTMODE.PROD_QUEUE then
    ScrollToProjectList(Controls.QueueList, Controls.QueueListScroll);
  end
end

-- ===========================================================================
function ScrollToProjectList(kListStack, kListScroll)
  local desiredScrollValue = (kListStack[FIELD_LIST_BUILDING_SIZE_Y] + kListStack[FIELD_LIST_WONDER_SIZE_Y] + kListStack[FIELD_LIST_UNIT_SIZE_Y]) / (kListStack:GetSizeY() - kListScroll:GetSizeY());
  kListScroll:SetScrollValue(desiredScrollValue);
end

-- ===========================================================================
function OnMoveItemLeftButtonClicked()
  if m_selectedQueueInstance ~= nil then
    local selectedItemIndex = m_selectedQueueInstance[FIELD_QUEUE_INDEX];
    SwapQueueItem(selectedItemIndex, selectedItemIndex - 1);
  end
end

-- ===========================================================================
function GetBuildInsertMode( tParameters )
  if m_isQueueOpen or m_isManagerOpen then
    if IsBuildQueueFull(city) then
      -- Replace last itme if queue is full
      tParameters[CityOperationTypes.PARAM_INSERT_MODE] = CityOperationTypes.VALUE_REPLACE_AT;
      tParameters[CityOperationTypes.PARAM_QUEUE_DESTINATION_LOCATION] = MAX_QUEUE_SIZE;
    else
      -- Append to end of queue
      tParameters[CityOperationTypes.PARAM_INSERT_MODE] = CityOperationTypes.VALUE_APPEND;
    end
  else
    tParameters[CityOperationTypes.PARAM_INSERT_MODE] = CityOperationTypes.VALUE_REPLACE_AT;
    tParameters[CityOperationTypes.PARAM_QUEUE_DESTINATION_LOCATION] = 0;
  end
end

-- ===========================================================================
function OnCityProductionQueueChanged(playerID, cityID, changeType, queueIndex)
  if playerID ~= Game.GetLocalPlayer() then
    return;
  end

  Refresh();

  -- Make sure we show the current production if we're in queue mode and adding the very first production to the city
  if m_isQueueOpen then
    Controls.CurrentProductionContainer:SetHide(not m_hasProductionToShow);
    Controls.NoProductionContainer:SetHide(m_hasProductionToShow);
  end
end

-- ===========================================================================
function IsBuildQueueFull()
  local pSelectedCity	= UI.GetHeadSelectedCity();
  if pSelectedCity then
    local pBuildQueue = pSelectedCity:GetBuildQueue();
    if pBuildQueue ~= nil then
      local iQueueSize = pBuildQueue:GetSize();
      if iQueueSize - 1 >= MAX_QUEUE_SIZE then
        return true;
      end
    end
  end

  return false;
end

-- ===========================================================================
function OnManagerSelectedIndexChanged( newIndex )
  m_SelectedManagerIndex = newIndex;
end

-- CUI =======================================================================
function CuiIsDistrictInQueue(item)
  local pSelectedCity	= UI.GetHeadSelectedCity();
  if pSelectedCity then
    local pBuildQueue = pSelectedCity:GetBuildQueue();
    if pBuildQueue ~= nil then
      for i = 1, MAX_QUEUE_SIZE do
        local queueEntry = pBuildQueue:GetAt(i);
        if queueEntry and queueEntry.DistrictType then
          local pDistrictDef = GameInfo.Districts[queueEntry.DistrictType];
          if pDistrictDef and pDistrictDef.DistrictType then
            if pDistrictDef.DistrictType == item.Type then
	      return pDistrictDef.OnePerCity;
            end
          end
        end
      end
    end
  end
  return false;
end

-- CUI =======================================================================
function CuiIsBuildingInQueue(item)
  local pSelectedCity	= UI.GetHeadSelectedCity();
  if pSelectedCity then
    local pBuildQueue = pSelectedCity:GetBuildQueue();
    if pBuildQueue ~= nil then
      for i = 1, MAX_QUEUE_SIZE do
        local queueEntry = pBuildQueue:GetAt(i);
        if queueEntry and queueEntry.BuildingType then
          local pBuildingDef = GameInfo.Buildings[queueEntry.BuildingType];
          if pBuildingDef and pBuildingDef.BuildingType then
            if pBuildingDef.BuildingType == item.Type then return true; end
          end
        end
      end
    end
  end
  return false;
end

-- CUI =======================================================================
function CuiIsProjectInQueue(item)
  local pSelectedCity  = UI.GetHeadSelectedCity();
  if pSelectedCity then
    local pBuildQueue = pSelectedCity:GetBuildQueue();
    if pBuildQueue ~= nil then
      for i = 1, MAX_QUEUE_SIZE do
        local queueEntry = pBuildQueue:GetAt(i);
        if queueEntry and queueEntry.ProjectType then
          local pProjectDef = GameInfo.Projects[queueEntry.ProjectType];
          if pProjectDef and pProjectDef.ProjectType then
            if pProjectDef.ProjectType == item.Type then return true; end
          end
        end
      end
    end
  end
  return false;
end

-- CUI =======================================================================
function CuiOnDetaultClick()
  cui_QueueOnDetault = Controls.QueueOnDetault:IsChecked();
  CuiSettings:SetBoolean(CuiSettings.QUEUE_BY_DEFAULT, cui_QueueOnDetault);
end

-- CUI =======================================================================
function CuiOnNewModeClick()
  cui_newVersion = not cui_newVersion;
  CuiNewVersionToggle(cui_newVersion);
  Refresh();
end

-- CUI =======================================================================
function CuiNewVersionToggle(isV2)
  local color   = isV2 and "StatGoodCS" or "StatBadCS";
  local version = isV2 and "v2" or "v1";
  Controls.SwitchVersionButton:SetColorByName(color);
  Controls.PanelVersion:SetText(version);
end

-- CUI =======================================================================
function CuiResetAllInstances()
  -- V1
  m_listIM:ResetInstances();
  m_purchaseListIM:ResetInstances();
  m_purchaseFaithListIM:ResetInstances();
  m_queueListIM:ResetInstances();

  -- V2
  cui_prodIM :ResetInstances();
  cui_goldIM :ResetInstances();
  cui_faithIM:ResetInstances();
  cui_queueIM:ResetInstances();
  cui_itemIM :ResetInstances();
end

-- CUI =======================================================================
function CuiNewVersionView(data)
  Controls.PauseCollapseList:Stop();
  PopulateCurrentProduction(data);
  ResizeProductionScrollList();

  PupulatePanel(cui_prodIM, cui_itemIM, data, LISTMODE.PRODUCTION);
  Controls.ProductionListScroll:SetScrollValue(GetScrollPosition(LISTMODE.PRODUCTION));

  PupulatePanel(cui_goldIM, cui_itemIM, data, LISTMODE.PURCHASE_GOLD);
  Controls.PurchaseListScroll:SetScrollValue(GetScrollPosition(LISTMODE.PURCHASE_GOLD));

  PupulatePanel(cui_faithIM, cui_itemIM, data, LISTMODE.PURCHASE_FAITH);
  Controls.PurchaseFaithListScroll:SetScrollValue(GetScrollPosition(LISTMODE.PURCHASE_FAITH));

  PupulatePanel(cui_queueIM, cui_itemIM, data, LISTMODE.PROD_QUEUE);
  Controls.QueueListScroll:SetScrollValue(GetScrollPosition(LISTMODE.PROD_QUEUE));

  RefreshQueue(data.Owner, data.City:GetID());
end

-- CUI =======================================================================
function CuiInit()
  cui_QueueOnDetault = CuiSettings:GetBoolean(CuiSettings.QUEUE_BY_DEFAULT);
  Controls.QueueOnDetault:SetCheck(cui_QueueOnDetault);
  Controls.QueueOnDetault:RegisterCheckHandler(CuiOnDetaultClick);
  -- new version
  Controls.SwitchVersionButton:RegisterCallback(Mouse.eLClick, CuiOnNewModeClick);
  CuiNewVersionToggle(cui_newVersion);
end

-- ===========================================================================
function Initialize()
  -- Cache tutorial status
  m_isTutorialRunning = IsTutorialRunning();

  Controls.PauseCollapseList:Stop();
  Controls.PauseDismissWindow:Stop();
  CreateCorrectTabs();

  CuiInit(); -- CUI

  Controls.ProductionListScroll:RegisterScrollCallback(OnProductionListScrolled);
  Controls.PurchaseListScroll:RegisterScrollCallback(OnPurchaseListScrolled);
  Controls.PurchaseFaithListScroll:RegisterScrollCallback(OnPurchaseFaithListScrolled);
  Controls.QueueListScroll:RegisterScrollCallback(OnQueueListScrolled);

  Controls.CloseButton:RegisterCallback(Mouse.eLClick, OnClose);
  Controls.CloseButton:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
  Controls.PauseCollapseList:RegisterEndCallback( OnCollapseTheList );
  Controls.PauseDismissWindow:RegisterEndCallback( OnHide );
  Controls.TopStackContainer:RegisterSizeChanged( OnTopStackContainerSizeChanged );
  Controls.TabContainer:RegisterSizeChanged( OnTabContainerSizeChanged );
  Controls.BuildingsButton:RegisterCallback( Mouse.eLClick, OnBuildingsButtonClicked );
  Controls.WondersButton:RegisterCallback( Mouse.eLClick, OnWondersButtonClicked );
  Controls.UnitsButton:RegisterCallback( Mouse.eLClick, OnUnitsButtonClicked );
  Controls.ProjectsButton:RegisterCallback( Mouse.eLClick, OnProjectsButtonClicked );
  Controls.CurrentProductionButton:RegisterCallback( Mouse.eLClick, function() OnItemClicked( Controls, Controls.CurrentProductionButton ); end);
  Controls.CurrentProductionButton:RegisterCallback( Mouse.eRClick, function() RemoveQueueItem(0); end );
  Controls.TrashButton:RegisterCallback( Mouse.eLClick, OnTrashClicked );

  UpdateQueueTabText(0);
  -- CUI Controls.ManagerTab:SetText("[ICON_ProductionQueue] " .. Locale.Lookup("LOC_PRODUCTION_PANEL_MULTI_QUEUE"))

  ContextPtr:SetInitHandler( OnInit  );
  ContextPtr:SetInputHandler( OnInputHandler, true );
  ContextPtr:SetShutdown( OnShutdown );

  Events.CityProductionQueueChanged.Add( OnCityProductionQueueChanged );
  Events.CitySelectionChanged.Add( OnCitySelectionChanged );
  Events.InterfaceModeChanged.Add( OnInterfaceModeChanged );
  Events.UnitSelectionChanged.Add( OnUnitSelectionChanged );
  Events.LocalPlayerChanged.Add( OnLocalPlayerChanged );

  LuaEvents.CityBannerManager_ProductionToggle.Add( OnCityBannerManagerProductionToggle );
  LuaEvents.CityPanel_ChooseProduction.Add( OnCityPanelChooseProduction );
  LuaEvents.CityPanel_ChoosePurchase.Add( OnCityPanelChoosePurchase );
  LuaEvents.CityPanel_ProductionClose.Add( OnProductionClose );
  LuaEvents.CityPanel_ProductionOpen.Add( OnCityPanelProductionOpen );
  LuaEvents.CityPanel_PurchaseGoldOpen.Add( OnCityPanelPurchaseGoldOpen );
  LuaEvents.CityPanel_PurchaseFaithOpen.Add( OnCityPanelPurchaseFaithOpen );
  LuaEvents.CityPanel_ProductionOpenForQueue.Add( OnProductionOpenForQueue );
  LuaEvents.CityPanel_PurchasePlot.Add( OnCityPanelPurchasePlot );
  LuaEvents.GameDebug_Return.Add( OnGameDebugReturn );
  LuaEvents.NotificationPanel_ChooseProduction.Add( OnNotificationPanelChooseProduction );
  LuaEvents.StrageticView_MapPlacement_ProductionOpen.Add( OnStrategicViewMapPlacementProductionOpen );
  LuaEvents.Tutorial_ProductionOpen.Add( OnTutorialProductionOpen );
  LuaEvents.ProductionManager_SelectedIndexChanged.Add( OnManagerSelectedIndexChanged );
end
Initialize();
