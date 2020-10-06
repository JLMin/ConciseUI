----------------------------------------------------------------
-- Map Pin List Panel
----------------------------------------------------------------
include("cui_settings") -- CUI

local m_playerMapPins = {}
local m_MapPinListButtonToPinEntry = {} -- map pin entries keyed to their MapPinListButton object string names.  This is currently just used for sorting, please becareful if you use it for anything else as it is cleared after use.

local PlayerMapPinListTTStr = Locale.Lookup("LOC_MAP_PIN_LIST_REMOTE_PIN_TOOLTIP")
local RemoteMapPinListTTStr = Locale.Lookup("LOC_MAP_PIN_LIST_REMOTE_PIN_TOOLTIP")

-------------------------------------------------
-- Map Pin List Scripting
-------------------------------------------------
function GetMapPinConfig(iPlayerID, mapPinID)
    local playerCfg = PlayerConfigurations[iPlayerID]
    if (playerCfg ~= nil) then
        local playerMapPins = playerCfg:GetMapPins()
        if (playerMapPins ~= nil) then
            return playerMapPins[mapPinID]
        end
    end
    return nil
end

-------------------------------------------------
-------------------------------------------------
function SetMapPinIcon(imageControl, mapPinIconName)
    if (imageControl ~= nil and mapPinIconName ~= nil) then
        local iconName = mapPinIconName
        if (not imageControl:SetIcon(iconName)) then
            imageControl:SetIcon("ICON_MAP_PIN_SQUARE")
        end
    end
end

-------------------------------------------------
-------------------------------------------------
function SortMapPinEntryStack(a, b)
    local controlStringA = tostring(a)
    local controlStringB = tostring(b)
    local pinEntryA = m_MapPinListButtonToPinEntry[controlStringA]
    local pinEntryB = m_MapPinListButtonToPinEntry[controlStringB]
    if (pinEntryA ~= nil and pinEntryB ~= nil) then
        -- CUI: sorting
        if pinEntryA.orderID ~= pinEntryB.orderID then
            return (pinEntryA.orderID or -1) < (pinEntryB.orderID or -1)
        end
        local pinNameA = Locale.ToLower(pinEntryA.MapPinName:GetText())
        local pinNameB = Locale.ToLower(pinEntryB.MapPinName:GetText())

        return pinNameA < pinNameB
    else
        -- This is obviously bad, why are they not in the list? Use the control strings to test against something.
        return controlStringA < controlStringB
    end
end

-------------------------------------------------
-------------------------------------------------
function UpdateMapPinListEntry(iPlayerID, mapPinID)
    local mapPinEntry = GetMapPinListEntry(iPlayerID, mapPinID)
    local mapPinCfg = GetMapPinConfig(iPlayerID, mapPinID)
    if (mapPinCfg ~= nil and mapPinEntry ~= nil) then
        -- Determine map pin display name.
        local pinName = mapPinCfg:GetName()
        if (pinName == nil) then
            -- CUI: for sorting
            local id = mapPinCfg:GetID()
            pinName = Locale.Lookup("LOC_MAP_PIN_DEFAULT_NAME", id + 1)
            mapPinEntry.orderID = id
        --
        end
        mapPinEntry.MapPinName:SetText(pinName)

        -- Set pin colors based on owner's player colors.
        -- local primaryColor, secondaryColor  = UI.GetPlayerColors(iPlayerID);
        -- mapPinEntry.PrimaryColorBox:SetColor(primaryColor);
        -- mapPinEntry.SecondaryColorBox:SetColor(secondaryColor);
        -- Set pin icon
        SetMapPinIcon(mapPinEntry.IconImage, mapPinCfg:GetIconName())

        -- Is this map pin visible on this list?
        local localPlayerID = Game.GetLocalPlayer()
        local showMapPin = mapPinCfg:IsVisible(localPlayerID)
        mapPinEntry.Root:SetHide(not showMapPin)
    end
end

-------------------------------------------------
-------------------------------------------------
function GetMapPinListEntry(iPlayerID, mapPinID)
    local playerMapPins = m_playerMapPins[iPlayerID]
    if (playerMapPins == nil) then
        playerMapPins = {}
        m_playerMapPins[iPlayerID] = playerMapPins
    end

    local mapPinEntry = playerMapPins[mapPinID]
    if (mapPinEntry == nil) then
        mapPinEntry = {}
        ContextPtr:BuildInstanceForControl("MapPinListEntry", mapPinEntry, Controls.MapPinEntryStack)

        playerMapPins[mapPinID] = mapPinEntry
        m_MapPinListButtonToPinEntry[tostring(mapPinEntry.Root)] = mapPinEntry

        mapPinEntry.MapPinListButton:SetVoids(iPlayerID, mapPinID)
        if (iPlayerID == Game.GetLocalPlayer()) then
            mapPinEntry.EditMapPin:SetHide(false)
            mapPinEntry.EditMapPin:SetVoids(iPlayerID, mapPinID)
            mapPinEntry.EditMapPin:RegisterCallback(Mouse.eLClick, OnMapPinEntryEdit)
        else
            mapPinEntry.EditMapPin:SetHide(true)
        end

        mapPinEntry.MapPinListButton:RegisterCallback(Mouse.eLClick, OnMapPinEntryLeftClick)

        if (iPlayerID == Game.GetLocalPlayer()) then
            mapPinEntry.MapPinListButton:SetToolTipString(PlayerMapPinListTTStr)
        else
            mapPinEntry.MapPinListButton:SetToolTipString(RemoteMapPinListTTStr)
        end

        UpdateMapPinListEntry(iPlayerID, mapPinID)

        Controls.MapPinEntryStack:CalculateSize()
        Controls.MapPinEntryStack:ReprocessAnchoring()

    -- Controls.MapPinLogPanel:CalculateInternalSize();
    -- Controls.MapPinLogPanel:ReprocessAnchoring();
    end
    return mapPinEntry
end

-------------------------------------------------
-------------------------------------------------
function BuildMapPinList()
    -- CUI
    Controls.ShowDistricts:SetCheck(CuiSettings:GetBoolean(CuiSettings.SHOW_DISTRICTS))
    Controls.ShowWonders:SetCheck(CuiSettings:GetBoolean(CuiSettings.SHOW_WONDERS))
    Controls.AutoNaming:SetCheck(CuiSettings:GetBoolean(CuiSettings.AUTO_NAMING))
    m_playerMapPins = {}
    m_MapPinListButtonToPinEntry = {}
    Controls.MapPinEntryStack:DestroyAllChildren()

    -- Call GetMapPinListEntry on every map pin to initially create the entries.
    for iPlayer = 0, GameDefines.MAX_MAJOR_CIVS - 1 do
        local pPlayerConfig = PlayerConfigurations[iPlayer]
        if (pPlayerConfig ~= nil) then
            local pPlayerPins = pPlayerConfig:GetMapPins()
            for ii, mapPinCfg in pairs(pPlayerPins) do
                local pinID = mapPinCfg:GetID()
                GetMapPinListEntry(iPlayer, pinID)
            end
        end
    end
    -- Sort by names when we're done.
    Controls.MapPinEntryStack:SortChildren(SortMapPinEntryStack)

    -- Don't need this anymore, get rid of the references so they can be properly released!
    m_MapPinListButtonToPinEntry = {}

    -- Recalc after sorting so the anchoring can account for hidden elements.
    Controls.MapPinEntryStack:CalculateSize()
    Controls.MapPinEntryStack:ReprocessAnchoring()
    -- CUI: dynamically resize scroll panel
    local maxY = 8 * 25 - 1 -- show up to 15 pins without a scrollbar
    local stackY = Controls.MapPinEntryStack:GetSizeY()
    local deltaX = stackY > maxY and 16 or 0 -- make room for scrollbar
    local panelX = math.max(Controls.ICONContoral:GetSizeX(), 280)
    local panelY = math.min(maxY, stackY)
    Controls.MapPinScrollPanel:SetSizeVal(panelX - deltaX, panelY)
    Controls.MapPinScrollPanel:ReprocessAnchoring()
    Controls.MapPinPanel:SetSizeX(panelX + 40)
    Controls.AddPinButton:SetSizeX(panelX)
    Controls.MapPinStack:ReprocessAnchoring()
    Controls.MapPinPanel:ReprocessAnchoring()
end

-------------------------------------------------
-- Button Event Handlers
-------------------------------------------------
function OnMapPinEntryLeftClick(iPlayerID, mapPinID)
    local mapPinCfg = GetMapPinConfig(iPlayerID, mapPinID)
    if (mapPinCfg ~= nil) then
        local hexX = mapPinCfg:GetHexX()
        local hexY = mapPinCfg:GetHexY()
        UI.LookAtPlot(hexX, hexY)
    -- Would love to find a fun effect to play on the map pin when you look at it so that you don't lose it.
    -- UI.OnNaturalWonderRevealed(hexX, hexY);
    end
end

function OnMapPinEntryEdit(iPlayerID, mapPinID)
    if (iPlayerID == Game.GetLocalPlayer()) then
        -- You're only allowed to edit your own pins.
        local mapPinCfg = GetMapPinConfig(iPlayerID, mapPinID)
        if (mapPinCfg ~= nil) then
            local hexX = mapPinCfg:GetHexX()
            local hexY = mapPinCfg:GetHexY()
            UI.LookAtPlot(hexX, hexY)
            LuaEvents.MapPinPopup_RequestMapPin(hexX, hexY)
        end
    end
end

-------------------------------------------------
-------------------------------------------------
function OnAddPinButton()
    -- Toggles map pin interface mode
    if (UI.GetInterfaceMode() == InterfaceModeTypes.PLACE_MAP_PIN) then
        UI.SetInterfaceMode(InterfaceModeTypes.SELECTION)
    else
        UI.SetInterfaceMode(InterfaceModeTypes.PLACE_MAP_PIN)
    end
end

-------------------------------------------------
-- External Event Handlers
-------------------------------------------------
function OnPlayerInfoChanged(playerID)
    BuildMapPinList()
end

-------------------------------------------------
-------------------------------------------------
function OnInterfaceModeChanged(eNewMode)
    if (UI.GetInterfaceMode() == InterfaceModeTypes.PLACE_MAP_PIN) then
        Controls.AddPinButton:SetText(Locale.Lookup("LOC_GREAT_WORKS_PLACING"))
        Controls.AddPinButton:SetSelected(true)
    else
        Controls.AddPinButton:SetText(Locale.Lookup("LOC_HUD_MAP_PLACE_MAP_PIN"))
        Controls.AddPinButton:SetSelected(false)
    end
end

function OnLocalPlayerChanged(eLocalPlayer, ePrevLocalPlayer)
    BuildMapPinList()
end

-------------------------------------------------
-- ShowHideHandler
-------------------------------------------------
function ShowHideHandler(bIsHide, bIsInit)
    if (not bIsHide) then
    end
end
ContextPtr:SetShowHideHandler(ShowHideHandler)

-- CUI -----------------------------------------------------------------------
function CuiOnShowDistrictsClick()
    local b = Controls.ShowDistricts:IsChecked()
    CuiSettings:SetBoolean(CuiSettings.SHOW_DISTRICTS, b)
    LuaEvents.CuiMapPinSettingChange()
end

-- CUI -----------------------------------------------------------------------
function CuiOnShowWondersClick()
    local b = Controls.ShowWonders:IsChecked()
    CuiSettings:SetBoolean(CuiSettings.SHOW_WONDERS, b)
    LuaEvents.CuiMapPinSettingChange()
end

-- CUI -----------------------------------------------------------------------
function CuiOnAutoNamingClick()
    local b = Controls.AutoNaming:IsChecked()
    CuiSettings:SetBoolean(CuiSettings.AUTO_NAMING, b)
end

-- CUI -----------------------------------------------------------------------
function CuiOnToggleMapPin()
    -- map pin panel and button
    local pinListPanel = ContextPtr:LookUpControl("/InGame/MinimapPanel/MapPinListPanel")
    pinListPanel:SetHide(false)
    local pinListButton = ContextPtr:LookUpControl("/InGame/MinimapPanel/MapPinListButton")
    pinListButton:SetSelected(true)

    -- map options panel and button
    local optionsPanel = ContextPtr:LookUpControl("/InGame/MinimapPanel/MapOptionsPanel")
    optionsPanel:SetHide(true)
    local optionsButton = ContextPtr:LookUpControl("/InGame/MinimapPanel/MapOptionsButton")
    optionsButton:SetSelected(false)

    -- lens panel and button
    local lensPanel = ContextPtr:LookUpControl("/InGame/MinimapPanel/LensPanel")
    lensPanel:SetHide(true)
    local lensButton = ContextPtr:LookUpControl("/InGame/MinimapPanel/LensButton")
    lensButton:SetSelected(false)

    OnAddPinButton()
end

-- CUI -----------------------------------------------------------------------
function CuiOnIngameAction(actionId)
    if (Game.GetLocalPlayer() == -1) then
        return
    end
    if actionId == Input.GetActionId("CuiActionPlaceMapPin") then
        CuiOnToggleMapPin()
        UI.PlaySound("Play_UI_Click")
    end
end

-- CUI -----------------------------------------------------------------------
function CuiInit()
    Events.InputActionTriggered.Add(CuiOnIngameAction)
    Controls.ShowDistricts:RegisterCallback(Mouse.eLClick, CuiOnShowDistrictsClick)
    Controls.ShowWonders:RegisterCallback(Mouse.eLClick, CuiOnShowWondersClick)
    Controls.AutoNaming:RegisterCallback(Mouse.eLClick, CuiOnAutoNamingClick)
end

-- ===========================================================================
function Initialize()
    CuiInit() -- CUI
    Controls.AddPinButton:RegisterCallback(Mouse.eLClick, OnAddPinButton)
    Controls.AddPinButton:RegisterCallback(
        Mouse.eMouseEnter,
        function()
            UI.PlaySound("Main_Menu_Mouse_Over")
        end
    )
    Events.PlayerInfoChanged.Add(OnPlayerInfoChanged)
    Events.InterfaceModeChanged.Add(OnInterfaceModeChanged)
    Events.LocalPlayerChanged.Add(OnLocalPlayerChanged)
    BuildMapPinList()
end
Initialize()
