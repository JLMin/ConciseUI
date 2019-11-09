-- ===========================================================================
-- Cui Production Panel UI Functions
-- ---------------------------------------------------------------------------
include("InstanceManager")

include("cui_helper")
include("cui_production_support")

-- ===========================================================================
-- Variables
-- ---------------------------------------------------------------------------

local m_playerID
local m_player
local m_city
local m_queue

local UNIT_STANDARD = MilitaryFormationTypes.STANDARD_MILITARY_FORMATION
local UNIT_CORPS = MilitaryFormationTypes.CORPS_MILITARY_FORMATION
local UNIT_ARMY = MilitaryFormationTypes.ARMY_MILITARY_FORMATION

local Y_GOLD = "YIELD_GOLD"
local Y_FAITH = "YIELD_FAITH"

local MODE = {PROD = 1, GOLD = 2, FAITH = 3, QUEUE = 4}

local GROUP = {
    DISTRICT = "LOC_HUD_DISTRICTS_BUILDINGS",
    WONDER = "LOC_HUD_CITY_WONDERS",
    UNIT = "LOC_TECH_FILTER_UNITS",
    PROJECT = "LOC_HUD_PROJECTS"
}

-- ===========================================================================
-- Populate Functions
-- ---------------------------------------------------------------------------
function PupulatePanel(groupIM, itemIM, data, mode)
    m_playerID = data.Owner
    m_player = data.Player
    m_city = data.City
    m_queue = data.City:GetBuildQueue()

    PopulateGroup(groupIM, itemIM, data.Districts, GROUP.DISTRICT, mode)
    PopulateGroup(groupIM, itemIM, data.Wonders, GROUP.WONDER, mode)
    PopulateGroup(groupIM, itemIM, data.Units, GROUP.UNIT, mode)
    PopulateGroup(groupIM, itemIM, data.Projects, GROUP.PROJECT, mode)
end

-- ---------------------------------------------------------------------------
function PopulateGroup(groupIM, itemIM, data, group, mode)
    if isNil(data) then return end

    local groupInstance = {}

    if mode == MODE.PROD or mode == MODE.QUEUE then
        groupInstance = groupIM:GetInstance()
        local groupList = groupInstance.List
        for _, item in ipairs(data) do
            if item.IsUnit and item.MustPurchase then
                PopulatePurchaseItem(groupList, itemIM, item, mode)
            else
                PopulateProduceItem(groupList, itemIM, item, mode)
            end
        end
    elseif mode == MODE.GOLD or mode == MODE.FAITH then
        local items = {}
        if mode == MODE.GOLD then
            items = GetPurchaseItemsByYield(data, Y_GOLD)
        end
        if mode == MODE.FAITH then
            items = GetPurchaseItemsByYield(data, Y_FAITH)
        end
        if isNil(items) then return end
        groupInstance = groupIM:GetInstance()
        local groupList = groupInstance.List
        for _, item in ipairs(items) do
            PopulatePurchaseItem(groupList, itemIM, item, mode)
        end
    end

    if not isNil(groupInstance) then
        SetupHeader(groupInstance, group)
        groupInstance.List:CalculateSize()

        local OnSizeChangeFunc
        if group == GROUP.DISTRICT then
            OnSizeChangeFunc = OnBuildingListSizeChanged
        elseif group == GROUP.WONDER then
            OnSizeChangeFunc = OnWonderListSizeChanged
        elseif group == GROUP.UNIT then
            OnSizeChangeFunc = OnUnitListSizeChanged
        end
        if OnSizeChangeFunc then
            groupInstance.Top:RegisterSizeChanged(
                function()
                    OnSizeChangeFunc(groupIM, groupInstance.Top:GetSizeY())
                end)
            OnSizeChangeFunc(groupIM, groupInstance.Top:GetSizeY())
        end
    end
end

-- ---------------------------------------------------------------------------
function PopulateProduceItem(parent, itemIM, item, mode)
    local skipItem = false
    if mode == MODE.PROD then skipItem = ItemDisabledInProdu(item, m_queue) end
    if mode == MODE.QUEUE then skipItem = ItemDisabledInQueue(item, m_queue) end

    local canPurchase = false
    if skipItem then
        canPurchase = CanPurchaseItem(item)
        if not canPurchase then return end
    end

    local instance = itemIM:GetInstance(parent)
    SetBasicItemInstance(instance, item)
    SetupProduceButtons(instance, item)
    RegisterProduceButtons(instance, item)

    if skipItem and canPurchase then
        instance.Button:SetDisabled(true)
    else
        instance.Button:SetDisabled(not item.Enable)
    end

    -- progress
    if CuiIsItemInProgress(m_queue, item) then
        local progress = item.Progress / item.Cost
        if progress < 1 then
            instance.ProductionProgress:SetPercent(progress)
            instance.ProductionProgressArea:SetHide(false)
        end
    end
    --
    if item.IsDistrict then
        local completed = not item.Enable and item.HasBeenBuilt and
                              item.OnePerCity and not item.IsPillaged
        instance.CompletedArea:SetHide(not completed)

        local turnsStr = ""
        local checkMark =
            completed and not item.Contaminated and item.Progress == 0
        if checkMark then
            turnsStr = "[ICON_Checkmark]"
        elseif item.Contaminated then
            turnsStr = TurnString(item.ContaminatedTurns)
        else
            turnsStr = TurnString(item.Turns)
        end
        instance.CostText:SetText(turnsStr)

        -- buildings in this district
        if not isNil(item.Buildings) then
            for _, building in ipairs(item.Buildings) do
                PopulateProduceItem(parent, itemIM, building, mode)
            end
        end
    end
    --
    if item.IsBuilding then
        if not item.MustPurchase then
            instance.CostText:SetText(TurnString(item.Turns))
        end
    end
    --
    if item.IsWonder then instance.CostText:SetText(TurnString(item.Turns)) end
    --
    if item.IsUnit then
        if not item.MustPurchase then
            instance.CostText:SetText(TurnString(item.Turns))
        end
        --
        local corps = item.Corps
        if not isNil(corps) then
            PopulateProduceItem(parent, itemIM, corps, mode)
        end
        --
        local army = item.Army
        if not isNil(army) then
            PopulateProduceItem(parent, itemIM, army, mode)
        end
    end
    --
    if item.IsProject then instance.CostText:SetText(TurnString(item.Turns)) end
end

-- ---------------------------------------------------------------------------
function PopulatePurchaseItem(parent, itemIM, item, mode)
    local isG
    if mode == MODE.GOLD or mode == MODE.FAITH then
        isG = mode == MODE.GOLD
    else
        if item.GoldUnlock then
            isG = true
        elseif item.FaithUnlock then
            isG = false
        else
            return
        end
    end

    local instance = itemIM:GetInstance(parent)
    SetBasicItemInstance(instance, item)
    local yield = isG and Y_GOLD or Y_FAITH
    RegisterPurchaseButtons(instance, item, yield)

    local enable = false
    if isG then
        enable = item.GoldEnable
    else
        enable = item.FaithEnable
    end
    instance.Button:SetDisabled(not enable)

    local reasonTT = isG and item.GoldReasonTT or item.FaithReasonTT
    local purchaseTT = ComposeTT(item.BasicTT, reasonTT)
    instance.Button:SetToolTipString(purchaseTT)

    local cost = -1
    if isG then
        cost = item.GoldCost
    else
        cost = item.FaithCost
    end
    local icon = isG and "[ICON_GOLD]" or "[ICON_FAITH]"
    instance.CostText:SetText(cost .. icon)
end

-- ===========================================================================
-- Instances Functions
-- ---------------------------------------------------------------------------
function SetupHeader(instance, title)
    instance.Header:SetText(Locale.Lookup(title))
    instance.Header:RegisterCallback(Mouse.eMouseEnter, function()
        UI.PlaySound("Main_Menu_Mouse_Over")
    end)
    instance.Header:RegisterCallback(Mouse.eLClick,
                                     function() OnExpand(instance) end)

    instance.HeaderOn:SetText(Locale.Lookup(title))
    instance.HeaderOn:RegisterCallback(Mouse.eMouseEnter, function()
        UI.PlaySound("Main_Menu_Mouse_Over")
    end)
    instance.HeaderOn:RegisterCallback(Mouse.eLClick,
                                       function() OnCollapse(instance) end)

    OnExpand(instance)
end

-- ---------------------------------------------------------------------------
function SetBasicItemInstance(instance, item)
    instance.ProductionProgressArea:SetHide(true)
    instance.CompletedArea:SetHide(true)
    instance.CostText:SetText(nil)
    instance.Button:SetSizeX(320)
    instance.Icon:SetHide(false)
    instance.Branch:SetHide(true)
    instance.Wrench:SetHide(true)

    instance.GoldButton:SetHide(true)
    instance.GoldButton:SetDisabled(false)
    instance.GoldButton:SetToolTipString(nil)
    instance.GoldIconOnly:SetHide(false)
    instance.GoldCost:SetText(nil)
    instance.GoldCost:SetHide(true)

    instance.FaithButton:SetHide(true)
    instance.FaithButton:SetDisabled(false)
    instance.FaithButton:SetToolTipString(nil)
    instance.FaithIconOnly:SetHide(false)
    instance.FaithCost:SetText(nil)
    instance.FaithCost:SetHide(true)

    instance.RepeatButton:SetHide(true)

    instance.Icon:SetIcon("ICON_" .. item.Type)
    local name = Locale.Lookup(item.Name)
    if item.IsCorps then name = name .. " [ICON_Corps]" end
    if item.IsArmy then name = name .. " [ICON_Army]" end
    instance.Name:SetText(name)
end

-- ---------------------------------------------------------------------------
function SetupProduceButtons(instance, item)
    local default = 320
    local small = 32
    local neste = 3

    local dSize = 0

    instance.Wrench:SetHide(not item.IsPillaged)
    instance.Icon:SetHide(item.IsPillaged)

    if item.IsBuilding then
        dSize = dSize + neste
        instance.Branch:SetHide(false)
    end

    if item.GoldUnlock then
        dSize = dSize + small
        instance.GoldButton:SetHide(false)
        instance.GoldButton:SetDisabled(not item.GoldEnable)
        if not item.GoldEnable then
            local goldTT = ComposeTT(item.GoldReasonTT, item.GoldCostTT)
            instance.GoldButton:SetToolTipString(goldTT)
        end

        instance.GoldCost:SetText(item.GoldCost .. "[ICON_GOLD]")

        instance.GoldButton:RegisterMouseEnterCallback(
            function() OnGoldCostButtonMouse(instance, "Enter") end)

        instance.GoldButton:RegisterMouseExitCallback(
            function() OnGoldCostButtonMouse(instance, "Exit") end)
    end

    if item.FaithUnlock then
        dSize = dSize + small
        instance.FaithButton:SetHide(false)
        instance.FaithButton:SetDisabled(not item.FaithEnable)
        if not item.FaithEnable then
            local faithTT = ComposeTT(item.FaithReasonTT, item.FaithCostTT)
            instance.FaithButton:SetToolTipString(faithTT)
        end

        instance.FaithCost:SetText(item.FaithCost .. "[ICON_FAITH]")

        instance.FaithButton:RegisterMouseEnterCallback(
            function() OnFaithCostButtonMouse(instance, "Enter") end)

        instance.FaithButton:RegisterMouseExitCallback(
            function() OnFaithCostButtonMouse(instance, "Exit") end)
    end

    if item.IsProject and item.IsRepeatable then
        dSize = dSize + small
        instance.RepeatButton:SetHide(false)
        instance.RepeatButton:SetDisabled(not item.Enable)
    end

    instance.Button:SetSizeX(default - dSize)
    local producTT = ComposeTT(item.BasicTT, item.ReasonTT, item.CostTT)
    instance.Button:SetToolTipString(producTT)
end

-- ---------------------------------------------------------------------------
function RegisterProduceButtons(instance, item)
    instance.Button:RegisterCallback(Mouse.eRClick, function()
        LuaEvents.OpenCivilopedia(item.Type)
    end)
    --
    if item.IsDistrict then
        instance.Button:RegisterCallback(Mouse.eLClick, function()
            OnBuildDistrict(m_city, item)
        end)

        instance.GoldButton:RegisterCallback(Mouse.eLClick, function()
            OnPurchaseDistrict(m_city, item, Y_GOLD)
        end)

        instance.FaithButton:RegisterCallback(Mouse.eLClick, function()
            OnPurchaseDistrict(m_city, item, Y_FAITH)
        end)
    end
    --
    if item.IsBuilding or item.IsWonder then
        instance.Button:RegisterCallback(Mouse.eLClick, function()
            OnBuildBuilding(m_city, item)
        end)

        instance.GoldButton:RegisterCallback(Mouse.eLClick, function()
            OnPurchaseBuilding(m_city, item, Y_GOLD)
        end)

        instance.FaithButton:RegisterCallback(Mouse.eLClick, function()
            OnPurchaseBuilding(m_city, item, Y_FAITH)
        end)
    end
    --
    if item.IsUnit then
        local formation
        if item.IsStandard then
            formation = UNIT_STANDARD
        elseif item.IsCorps then
            formation = UNIT_CORPS
        elseif item.IsArmy then
            formation = UNIT_ARMY
        end

        instance.Button:RegisterCallback(Mouse.eLClick, function()
            OnBuildUnit(m_city, item, formation)
        end)

        instance.GoldButton:RegisterCallback(Mouse.eLClick, function()
            OnPurchaseUnit(m_city, item, formation, Y_GOLD)
        end)

        instance.FaithButton:RegisterCallback(Mouse.eLClick, function()
            OnPurchaseUnit(m_city, item, formation, Y_FAITH)
        end)
    end
    --
    if item.IsProject then
        instance.Button:RegisterCallback(Mouse.eLClick, function()
            OnBuildProject(m_city, item)
        end)

        instance.RepeatButton:RegisterCallback(Mouse.eLClick, function()
            OnRepeatProject(m_city, item)
        end)
    end
end

-- ---------------------------------------------------------------------------
function RegisterPurchaseButtons(instance, item, yield)
    instance.Button:RegisterCallback(Mouse.eRClick, function()
        LuaEvents.OpenCivilopedia(item.Type)
    end)

    if item.IsDistrict then
        instance.Button:RegisterCallback(Mouse.eLClick, function()
            OnPurchaseDistrict(m_city, item, yield)
        end)
    end
    --
    if item.IsBuilding or item.IsWonder then
        instance.Button:RegisterCallback(Mouse.eLClick, function()
            OnPurchaseBuilding(m_city, item, yield)
        end)
    end
    --
    if item.IsUnit then
        local formation
        if item.IsStandard then
            formation = UNIT_STANDARD
        elseif item.IsCorps then
            formation = UNIT_CORPS
        elseif item.IsArmy then
            formation = UNIT_ARMY
        end

        instance.Button:RegisterCallback(Mouse.eLClick, function()
            OnPurchaseUnit(m_city, item, formation, yield)
        end)
    end
    --
    if item.IsProject then
        -- can't be ?
    end
end

-- ===========================================================================
-- UI Events
-- ---------------------------------------------------------------------------
function OnGoldCostButtonMouse(instance, action)
    local isEnter = action == "Enter"
    local dSize = isEnter and 36 or -36

    local buttonSize = instance.Button:GetSizeX()
    instance.Button:SetSizeX(buttonSize - dSize)

    local goldSize = instance.GoldButton:GetSizeX()
    instance.GoldButton:SetSizeX(goldSize + dSize)

    instance.GoldIconOnly:SetHide(isEnter)
    instance.GoldCost:SetHide(not isEnter)
end

-- ---------------------------------------------------------------------------
function OnFaithCostButtonMouse(instance, action)
    local isEnter = action == "Enter"
    local dSize = isEnter and 36 or -36

    local buttonSize = instance.Button:GetSizeX()
    instance.Button:SetSizeX(buttonSize - dSize)

    local faithSize = instance.FaithButton:GetSizeX()
    instance.FaithButton:SetSizeX(faithSize + dSize)

    instance.FaithIconOnly:SetHide(isEnter)
    instance.FaithCost:SetHide(not isEnter)
end

-- ---------------------------------------------------------------------------
function OnBuildDistrict(city, districtEntry)
    StopRepeatProject(city)

    if CheckQueueItemSelected() then return end

    local bNeedsPlacement = districtEntry.RequiresPlacement

    if m_queue:HasBeenPlaced(districtEntry.Hash) then bNeedsPlacement = false end

    if bNeedsPlacement then
        local tParameters = {}
        tParameters[CityOperationTypes.PARAM_DISTRICT_TYPE] = districtEntry.Hash
        GetBuildInsertMode(tParameters)
        UI.SetInterfaceMode(InterfaceModeTypes.DISTRICT_PLACEMENT, tParameters)
        Close()
    else
        local tParameters = {}
        tParameters[CityOperationTypes.PARAM_DISTRICT_TYPE] = districtEntry.Hash
        GetBuildInsertMode(tParameters)
        CityManager.RequestOperation(city, CityOperationTypes.BUILD, tParameters)
        UI.PlaySound("Confirm_Production")
        CloseAfterNewProduction()
    end
end

-- ---------------------------------------------------------------------------
function OnPurchaseDistrict(city, districtEntry, yield)
    local bNeedsPlacement = districtEntry.RequiresPlacement

    if m_queue:HasBeenPlaced(districtEntry.Hash) then bNeedsPlacement = false end

    if bNeedsPlacement then
        local tParameters = {}
        tParameters[CityOperationTypes.PARAM_DISTRICT_TYPE] = districtEntry.Hash
        tParameters[CityCommandTypes.PARAM_YIELD_TYPE] =
            GameInfo.Yields[yield].Index
        UI.SetInterfaceMode(InterfaceModeTypes.DISTRICT_PLACEMENT, tParameters)
    else
        local tParameters = {}
        tParameters[CityOperationTypes.PARAM_DISTRICT_TYPE] = districtEntry.Hash
        tParameters[CityCommandTypes.PARAM_YIELD_TYPE] =
            GameInfo.Yields[yield].Index
        CityManager.RequestCommand(city, CityCommandTypes.PURCHASE, tParameters)
        if yield == Y_GOLD then
            UI.PlaySound("Purchase_With_Gold")
        else
            UI.PlaySound("Purchase_With_Faith")
        end
    end

    Close()
end

-- ---------------------------------------------------------------------------
function OnBuildBuilding(city, buildingEntry)
    StopRepeatProject(city)

    if CheckQueueItemSelected() then return end

    local bNeedsPlacement = buildingEntry.RequiresPlacement

    UI.SetInterfaceMode(InterfaceModeTypes.SELECTION)

    if m_queue:HasBeenPlaced(buildingEntry.Hash) then bNeedsPlacement = false end

    if bNeedsPlacement then
        local cityBuildings = city:GetBuildings()
        if cityBuildings:HasBuilding(buildingEntry.Hash) then
            bNeedsPlacement = false
        end
    end

    if bNeedsPlacement then
        local tParameters = {}
        tParameters[CityOperationTypes.PARAM_BUILDING_TYPE] = buildingEntry.Hash
        GetBuildInsertMode(tParameters)
        UI.SetInterfaceMode(InterfaceModeTypes.BUILDING_PLACEMENT, tParameters)
        Close()
    else
        local tParameters = {}
        tParameters[CityOperationTypes.PARAM_BUILDING_TYPE] = buildingEntry.Hash
        GetBuildInsertMode(tParameters)
        CityManager.RequestOperation(city, CityOperationTypes.BUILD, tParameters)
        UI.PlaySound("Confirm_Production")
        CloseAfterNewProduction()
    end
end

-- ---------------------------------------------------------------------------
function OnPurchaseBuilding(city, buildingEntry, yield)
    local tParameters = {}
    tParameters[CityCommandTypes.PARAM_BUILDING_TYPE] = buildingEntry.Hash
    tParameters[CityCommandTypes.PARAM_YIELD_TYPE] =
        GameInfo.Yields[yield].Index
    if yield == Y_GOLD then
        UI.PlaySound("Purchase_With_Gold")
    else
        UI.PlaySound("Purchase_With_Faith")
    end
    CityManager.RequestCommand(city, CityCommandTypes.PURCHASE, tParameters)

    Close()
end

-- ---------------------------------------------------------------------------
function OnBuildUnit(city, unitEntry, formation)
    StopRepeatProject(city)

    if CheckQueueItemSelected() then return end

    local tParameters = {}
    tParameters[CityOperationTypes.PARAM_UNIT_TYPE] = unitEntry.Hash
    GetBuildInsertMode(tParameters)
    tParameters[CityOperationTypes.MILITARY_FORMATION_TYPE] = formation
    CityManager.RequestOperation(city, CityOperationTypes.BUILD, tParameters)
    UI.PlaySound("Confirm_Production")

    CloseAfterNewProduction()
end

-- ---------------------------------------------------------------------------
function OnPurchaseUnit(city, unitEntry, formation, yield)
    local tParameters = {}
    tParameters[CityCommandTypes.PARAM_UNIT_TYPE] = unitEntry.Hash
    tParameters[CityCommandTypes.PARAM_MILITARY_FORMATION_TYPE] = formation
    tParameters[CityCommandTypes.PARAM_YIELD_TYPE] =
        GameInfo.Yields[yield].Index
    if yield == Y_GOLD then
        UI.PlaySound("Purchase_With_Gold")
    else
        UI.PlaySound("Purchase_With_Faith")
    end
    CityManager.RequestCommand(city, CityCommandTypes.PURCHASE, tParameters)

    Close()
end

-- ---------------------------------------------------------------------------
function OnBuildProject(city, projectEntry)
    StopRepeatProject(city)

    if CheckQueueItemSelected() then return end

    local tParameters = {}
    tParameters[CityOperationTypes.PARAM_PROJECT_TYPE] = projectEntry.Hash
    GetBuildInsertMode(tParameters)
    CityManager.RequestOperation(city, CityOperationTypes.BUILD, tParameters)
    UI.PlaySound("Confirm_Production")

    CloseAfterNewProduction()
end

-- ---------------------------------------------------------------------------
function OnRepeatProject(city, projectEntry)
    AddProjectToRepeatList(city, projectEntry.Hash)

    if CheckQueueItemSelected() then return end

    local tParameters = {}
    tParameters[CityOperationTypes.PARAM_PROJECT_TYPE] = projectEntry.Hash
    GetBuildInsertMode(tParameters)
    CityManager.RequestOperation(city, CityOperationTypes.BUILD, tParameters)
    UI.PlaySound("Confirm_Production")

    CloseAfterNewProduction()
end

-- ===========================================================================
-- Help Functions
-- ---------------------------------------------------------------------------
function ItemDisabledInProdu(item, queue)

    local hash = queue:GetCurrentProductionTypeHash()
    if item.IsDistrict or item.IsWonder or item.IsUnit or item.IsProject then
        return item.Hash == hash
    end

    if item.IsBuilding then
        if item.Hash == hash then return true end
        return item.PrereqHash == hash
    end

    return false
end

-- ---------------------------------------------------------------------------
function ItemDisabledInQueue(item, queue)
    if item.IsDistrict then
        return IsItemInQueue(item, queue) and item.OnePerCity
    end
    if item.IsWonder then return IsItemInQueue(item, queue) end
    if item.IsUnit then return false end
    if item.IsProject then
        return IsItemInQueue(item, queue) and not item.IsRepeatable
    end

    if item.IsBuilding then
        if IsItemInQueue(item, queue) then return true end
        local district = GameInfo.Districts[item.PrereqType]
        local fakeDistrict = {
            IsDistrict = true,
            BasicType = GetDistrictBaseType(district)
        }
        return IsItemInQueue(fakeDistrict, queue) and district.OnePerCity
    end
end

-- ---------------------------------------------------------------------------
function IsItemInQueue(item, queue)

    if item.IsUnit then return false end

    local hash = queue:GetCurrentProductionTypeHash()
    if item.Hash == hash then return true end

    for i = 1, 7 do
        local queueEntry = queue:GetAt(i)
        --
        if item.IsDistrict then
            if queueEntry and queueEntry.DistrictType then
                local pDistrictDef = GameInfo.Districts[queueEntry.DistrictType]
                if pDistrictDef and pDistrictDef.DistrictType then
                    local basicType = GetDistrictBaseType(pDistrictDef)
                    if basicType == item.BasicType then
                        return true
                    end
                end
            end
        end
        --
        if item.IsBuilding or item.IsWonder then
            if queueEntry and queueEntry.BuildingType then
                local pBuildingDef = GameInfo.Buildings[queueEntry.BuildingType]
                if pBuildingDef and pBuildingDef.BuildingType then
                    if pBuildingDef.BuildingType == item.Type then
                        return true
                    end
                end
            end
        end
        --
        if item.IsProject then
            if queueEntry and queueEntry.ProjectType then
                local pProjectDef = GameInfo.Projects[queueEntry.ProjectType]
                if pProjectDef and pProjectDef.ProjectType then
                    if pProjectDef.ProjectType == item.Type then
                        return true
                    end
                end
            end
        end
        --
    end

    return false
end

-- ---------------------------------------------------------------------------
function CanPurchaseItem(item) return item.GoldUnlock or item.FaithUnlock end

-- ---------------------------------------------------------------------------
function GetPurchaseItemsByYield(data, yield)
    local items = {}

    for _, item in ipairs(data) do
        if yield == Y_GOLD and item.GoldUnlock then
            table.insert(items, item)
        end
        if yield == Y_FAITH and item.FaithUnlock then
            table.insert(items, item)
        end

        if item.IsDistrict then
            local buildings = item.Buildings
            if not isNil(buildings) then
                for _, b in ipairs(buildings) do
                    if yield == Y_GOLD and b.GoldUnlock then
                        table.insert(items, b)
                    end
                    if yield == Y_FAITH and b.FaithUnlock then
                        table.insert(items, b)
                    end
                end
            end
        elseif item.IsUnit then
            local c = item.Corps
            if not isNil(c) then
                if yield == Y_GOLD and c.GoldUnlock then
                    table.insert(items, c)
                end
                if yield == Y_FAITH and c.FaithUnlock then
                    table.insert(items, c)
                end
            end
            --
            local a = item.Army
            if not isNil(a) then
                if yield == Y_GOLD and a.GoldUnlock then
                    table.insert(items, a)
                end
                if yield == Y_FAITH and a.FaithUnlock then
                    table.insert(items, a)
                end
            end
        end
    end

    return items
end

------------------------------------------------------------------------------
