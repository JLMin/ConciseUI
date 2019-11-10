-- ===========================================================================
-- Diplomacy Trade View Manager
-- ===========================================================================
include("InstanceManager")
include("Civ6Common") -- AutoSizeGridButton
include("Colors")
include("SupportFunctions")
include("PopupDialog")
include("ToolTipHelper_PlayerYields")
include("CivilizationIcon")
include("GreatWorksSupport")
include("cui_helper") -- CUI

-- ===========================================================================
--	VARIABLES
-- ===========================================================================
local ms_PlayerPanelIM = InstanceManager:new("PlayerAvailablePanel", "Root")
local ms_IconOnlyIM = InstanceManager:new("IconOnly", "SelectButton",
                                          Controls.IconOnlyContainer)
local ms_IconAndTextIM = InstanceManager:new("IconAndText", "SelectButton",
                                             Controls.IconAndTextContainer)
local ms_LeftRightListIM = InstanceManager:new("LeftRightList", "List",
                                               Controls.LeftRightListContainer)
local ms_TopDownListIM = InstanceManager:new("TopDownList", "List",
                                             Controls.TopDownListContainer)
local ms_AgreementOptionIM = InstanceManager:new("AgreementOptionInstance",
                                                 "AgreementOptionButton",
                                                 Controls.ValueEditStack)

-- CUI: instances
local CuiGroupListIM = InstanceManager:new("CuiGroupList", "List",
                                           Controls.LeftRightListContainer)
local CuiEditGroupIM = InstanceManager:new("CuiEditGroup", "Top",
                                           Controls.IconOnlyContainer)
local CuiDefaultColor = UI.GetColorValueFromHexLiteral(0xFFFFFFFF)
local CuiRedColor = UI.GetColorValueFromHexLiteral(0xFF0000FF)
local CuiGreenColor = UI.GetColorValueFromHexLiteral(0xFF00FF00)

local ms_ValueEditDealItemID = -1 -- The ID of the deal item that is being value edited.
local ms_ValueEditDealItemControlTable = nil -- The control table of the deal item that is being edited.

local OTHER_PLAYER = 0
local LOCAL_PLAYER = 1

local ms_LocalPlayerPanel = {}
local ms_OtherPlayerPanel = {}

local ms_LocalPlayer = nil
local ms_OtherPlayer = nil
local ms_OtherPlayerID = -1
local ms_OtherPlayerIsHuman = false

local ms_InitiatedByPlayerID = -1

ms_bIsDemand = false
local ms_bExiting = false

local ms_LastIncomingDealProposalAction = DealProposalAction.PENDING

local m_kPopupDialog -- Will use custom "popup" since in leader mode the Popup stack is disabled.

local AvailableDealItemGroupTypes = {}
AvailableDealItemGroupTypes.GOLD = 1
AvailableDealItemGroupTypes.LUXURY_RESOURCES = 2
AvailableDealItemGroupTypes.STRATEGIC_RESOURCES = 3
AvailableDealItemGroupTypes.AGREEMENTS = 4
AvailableDealItemGroupTypes.CITIES = 5
AvailableDealItemGroupTypes.OTHER_PLAYERS = 6
AvailableDealItemGroupTypes.GREAT_WORKS = 7
AvailableDealItemGroupTypes.CAPTIVES = 8

AvailableDealItemGroupTypes.COUNT = 8

local ms_AvailableGroups = {}

-----------------------
local DealItemGroupTypes = {}
DealItemGroupTypes.GOLD = 1
DealItemGroupTypes.RESOURCES = 2
DealItemGroupTypes.AGREEMENTS = 3
DealItemGroupTypes.CITIES = 4
DealItemGroupTypes.GREAT_WORKS = 5
DealItemGroupTypes.CAPTIVES = 6

DealItemGroupTypes.COUNT = 6

local ms_DealGroups = {}

local ms_DealAgreementsGroup = {}

local ms_DefaultOneTimeGoldAmount = 100

local ms_DefaultMultiTurnGoldAmount = 10
local ms_DefaultMultiTurnGoldDuration = 30

local ms_bForceUpdateOnCommit = false

local ms_bDontUpdateOnBack = false

local MAX_DEAL_ITEM_EDIT_HEIGHT = 300

-- ===========================================================================
function SetIconToSize(iconControl, iconName, iconSize)
    if iconSize == nil then iconSize = 50 end
    local x, y, szIconName, iconSize = IconManager:FindIconAtlasNearestSize(
                                           iconName, iconSize, true)
    iconControl:SetTexture(x, y, szIconName)
    iconControl:SetSizeVal(iconSize, iconSize)
end

-- ===========================================================================
function InitializeDealGroups()

    for i = 1, AvailableDealItemGroupTypes.COUNT, 1 do
        ms_AvailableGroups[i] = {}
    end

    for i = 1, DealItemGroupTypes.COUNT, 1 do ms_DealGroups[i] = {} end

end
InitializeDealGroups()

-- ===========================================================================
function GetPlayerType(player)
    if (player:GetID() == ms_LocalPlayer:GetID()) then return LOCAL_PLAYER end

    return OTHER_PLAYER
end

-- ===========================================================================
function GetPlayerOfType(playerType)
    if (playerType == LOCAL_PLAYER) then return ms_LocalPlayer end

    return ms_OtherPlayer
end

-- ===========================================================================
function GetOtherPlayer(player)
    if (player ~= nil and player:GetID() == ms_OtherPlayer:GetID()) then
        return ms_LocalPlayer
    end

    return ms_OtherPlayer
end

-- ===========================================================================
function SetDefaultLeaderDialogText()
    if (ms_bIsDemand == true and ms_InitiatedByPlayerID == ms_OtherPlayerID) then
        SetLeaderDialog("LOC_DIPLO_DEMAND_INTRO", "")
    else
        SetLeaderDialog("LOC_DIPLO_DEAL_INTRO", "")
    end
end

-- ===========================================================================
function ProposeWorkingDeal(bIsAutoPropose)
    if (bIsAutoPropose == nil) then bIsAutoPropose = false end

    if (not DealManager.HasPendingDeal(ms_LocalPlayer:GetID(),
                                       ms_OtherPlayer:GetID())) then
        if (ms_bIsDemand) then
            DealManager.SendWorkingDeal(DealProposalAction.DEMANDED,
                                        ms_LocalPlayer:GetID(),
                                        ms_OtherPlayer:GetID())
        else
            if (bIsAutoPropose) then
                DealManager.SendWorkingDeal(DealProposalAction.INSPECT,
                                            ms_LocalPlayer:GetID(),
                                            ms_OtherPlayer:GetID())
            else
                DealManager.SendWorkingDeal(DealProposalAction.PROPOSED,
                                            ms_LocalPlayer:GetID(),
                                            ms_OtherPlayer:GetID())
            end
        end
    end
end

-- ===========================================================================
function RequestEqualizeWorkingDeal()
    if (not DealManager.HasPendingDeal(ms_LocalPlayer:GetID(),
                                       ms_OtherPlayer:GetID())) then
        DealManager.SendWorkingDeal(DealProposalAction.EQUALIZE,
                                    ms_LocalPlayer:GetID(),
                                    ms_OtherPlayer:GetID())
    end
end

-- ===========================================================================
function DealIsEmpty()
    local pDeal = DealManager.GetWorkingDeal(DealDirection.OUTGOING,
                                             ms_LocalPlayer:GetID(),
                                             ms_OtherPlayer:GetID())
    if (pDeal == nil or pDeal:GetItemCount() == 0) then return true end

    return false
end

-- ===========================================================================
-- Update the proposed working deal.  This is called as items are changed in the deal.
-- It is primarily used to 'auto-propose' the deal when working with an AI.
function UpdateProposedWorkingDeal()
    if (ms_LastIncomingDealProposalAction ~= DealProposalAction.PENDING or
        IsAutoPropose()) then

        local pDeal = DealManager.GetWorkingDeal(DealDirection.OUTGOING,
                                                 ms_LocalPlayer:GetID(),
                                                 ms_OtherPlayer:GetID())
        if (pDeal == nil or pDeal:GetItemCount() == 0 or ms_bIsDemand) then
            -- Is a demand or no items, restart
            ms_LastIncomingDealProposalAction = DealProposalAction.PENDING
            UpdateDealStatus()
        else
            if (IsAutoPropose()) then ProposeWorkingDeal(true) end
        end
    end
end

-- ===========================================================================
function UpdateOtherPlayerText(otherPlayerSays)
    local bHide = true
    if (ms_OtherPlayer ~= nil and otherPlayerSays ~= nil) then
        local playerConfig = PlayerConfigurations[ms_OtherPlayer:GetID()]
        if (playerConfig ~= nil) then
            -- leader icon
            local otherPlayerController =
                CivilizationIcon:AttachInstance(Controls.OtherPlayerBubbleIcon)
            otherPlayerController:UpdateIconFromPlayerID(ms_OtherPlayer:GetID())

            -- Set the leader name
            local leaderDesc = playerConfig:GetLeaderName()
            Controls.OtherPlayerBubbleName:SetText(
                Locale.ToUpper(Locale.Lookup(
                                   "LOC_DIPLOMACY_DEAL_OTHER_PLAYER_SAYS",
                                   leaderDesc)))
        end
    end
    -- When we get dialog for what the leaders say during a trade, we can add it here!
end

-- ===========================================================================
function OnToggleCollapseGroup(iconList)
    if (iconList.ListStack:IsHidden()) then
        iconList.ListStack:SetHide(false)
    else
        iconList.ListStack:SetHide(true)
    end

    iconList.List:CalculateSize()
    iconList.List:ReprocessAnchoring()
end
-- ===========================================================================
function CreateHorizontalGroup(rootStack, title)
    local iconList = ms_LeftRightListIM:GetInstance(rootStack)
    if (title == nil or title == "") then
        iconList.Title:SetHide(true) -- No title
    else
        iconList.TitleText:LocalizeAndSetText(title)
    end
    iconList.List:CalculateSize()
    iconList.List:ReprocessAnchoring()

    return iconList
end

-- ===========================================================================
function CreateVerticalGroup(rootStack, title)
    local iconList = ms_TopDownListIM:GetInstance(rootStack)
    if (title == nil or title == "") then
        iconList.Title:SetHide(true) -- No title
    else
        iconList.TitleText:LocalizeAndSetText(title)
    end
    iconList.List:CalculateSize()
    iconList.List:ReprocessAnchoring()

    return iconList
end

-- CUI =======================================================================
function CuiCreateEditGroup(rootStack)
    local iconList = CuiGroupListIM:GetInstance(rootStack)
    iconList.List:CalculateSize()
    iconList.List:ReprocessAnchoring()
    return iconList
end

-- ===========================================================================
function CreatePlayerAvailablePanel(playerType, rootControl)

    -- local playerPanel = ms_PlayerPanelIM:GetInstance(rootControl);
    -- CUI: custom gold group
    ms_AvailableGroups[AvailableDealItemGroupTypes.GOLD][playerType] =
        CuiCreateEditGroup(rootControl)
    -- ms_AvailableGroups[AvailableDealItemGroupTypes.GOLD][playerType] = CreateHorizontalGroup(rootControl);
    --
    ms_AvailableGroups[AvailableDealItemGroupTypes.LUXURY_RESOURCES][playerType] =
        CreateHorizontalGroup(rootControl, "LOC_DIPLOMACY_DEAL_LUXURY_RESOURCES")
    ms_AvailableGroups[AvailableDealItemGroupTypes.STRATEGIC_RESOURCES][playerType] =
        CreateHorizontalGroup(rootControl,
                              "LOC_DIPLOMACY_DEAL_STRATEGIC_RESOURCES")
    ms_AvailableGroups[AvailableDealItemGroupTypes.AGREEMENTS][playerType] =
        CreateVerticalGroup(rootControl, "LOC_DIPLOMACY_DEAL_AGREEMENTS")
    ms_AvailableGroups[AvailableDealItemGroupTypes.CITIES][playerType] =
        CreateVerticalGroup(rootControl, "LOC_DIPLOMACY_DEAL_CITIES")
    ms_AvailableGroups[AvailableDealItemGroupTypes.OTHER_PLAYERS][playerType] =
        CreateVerticalGroup(rootControl, "LOC_DIPLOMACY_DEAL_OTHER_PLAYERS")
    ms_AvailableGroups[AvailableDealItemGroupTypes.GREAT_WORKS][playerType] =
        CreateVerticalGroup(rootControl, "LOC_DIPLOMACY_DEAL_GREAT_WORKS")
    ms_AvailableGroups[AvailableDealItemGroupTypes.CAPTIVES][playerType] =
        CreateVerticalGroup(rootControl, "LOC_DIPLOMACY_DEAL_CAPTIVES")

    rootControl:CalculateSize()
    rootControl:ReprocessAnchoring()

    return playerPanel
end

-- ===========================================================================
function CreatePlayerDealPanel(playerType, rootControl)
    -- This creates the containers for the offer area...
    -- ms_DealGroups[DealItemGroupTypes.RESOURCES][playerType]	= CreateHorizontalGroup(rootControl);
    -- ms_DealGroups[DealItemGroupTypes.AGREEMENTS][playerType]	= CreateVerticalGroup(rootControl);
    -- **********************************************************************
    -- Currently putting them all in the same control.
    ms_DealGroups[DealItemGroupTypes.RESOURCES][playerType] = rootControl
    ms_DealGroups[DealItemGroupTypes.AGREEMENTS][playerType] = rootControl
    ms_DealGroups[DealItemGroupTypes.CITIES][playerType] = rootControl
    ms_DealGroups[DealItemGroupTypes.GREAT_WORKS][playerType] = rootControl
    ms_DealGroups[DealItemGroupTypes.CAPTIVES][playerType] = rootControl

end

-- ===========================================================================
function OnValuePulldownCommit(forType)

    local pDeal = DealManager.GetWorkingDeal(DealDirection.OUTGOING,
                                             ms_LocalPlayer:GetID(),
                                             ms_OtherPlayer:GetID())
    if (pDeal ~= nil) then

        local pDealItem = pDeal:FindItemByID(ms_ValueEditDealItemID)
        if (pDealItem ~= nil) then
            pDealItem:SetValueType(forType)

            local valueName = pDealItem:GetValueTypeNameID()
            if (ms_ValueEditDealItemControlTable ~= nil) then
                -- Keep the text on the icon, that is currently hidden, up to date too.
                ms_ValueEditDealItemControlTable.ValueText:LocalizeAndSetText(
                    pDealItem:GetValueTypeNameID(valueName))
            end

            UpdateDealStatus()
            UpdateProposedWorkingDeal()
        end
    end

    Controls.ValueEditPopupBackground:SetHide(true)

end

-- ===========================================================================
function SetValueText(icon, pDealItem)

    if (icon.ValueText ~= nil) then
        local valueName = pDealItem:GetValueTypeNameID()
        if (valueName == nil) then
            if (pDealItem:HasPossibleValues()) then
                valueName = "LOC_DIPLOMACY_DEAL_CLICK_TO_CHANGE_DEAL_PARAMETER"
            end
        end
        if (valueName ~= nil) then
            icon.ValueText:LocalizeAndSetText(valueName)
            icon.ValueText:SetHide(false)
        else
            icon.ValueText:SetHide(true)
        end
    end
end

-- ===========================================================================
function CreatePanels()

    -- Create the Other Player Panels
    CreatePlayerAvailablePanel(OTHER_PLAYER, Controls.TheirInventoryStack)

    -- Create the Local Player Panels
    CreatePlayerAvailablePanel(LOCAL_PLAYER, Controls.MyInventoryStack)

    CreatePlayerDealPanel(OTHER_PLAYER, Controls.TheirOfferStack)
    CreatePlayerDealPanel(LOCAL_PLAYER, Controls.MyOfferStack)

    Controls.EqualizeDeal:RegisterCallback(Mouse.eLClick, OnEqualizeDeal)
    Controls.EqualizeDeal:RegisterCallback(Mouse.eMouseEnter, function()
        UI.PlaySound("Main_Menu_Mouse_Over")
    end)
    Controls.AcceptDeal:RegisterCallback(Mouse.eLClick, OnProposeOrAcceptDeal)
    Controls.AcceptDeal:RegisterCallback(Mouse.eMouseEnter, function()
        UI.PlaySound("Main_Menu_Mouse_Over")
    end)
    Controls.DemandDeal:RegisterCallback(Mouse.eLClick, OnProposeOrAcceptDeal)
    Controls.DemandDeal:RegisterCallback(Mouse.eMouseEnter, function()
        UI.PlaySound("Main_Menu_Mouse_Over")
    end)
    Controls.RefuseDeal:RegisterCallback(Mouse.eLClick, OnRefuseDeal)
    Controls.RefuseDeal:RegisterCallback(Mouse.eMouseEnter, function()
        UI.PlaySound("Main_Menu_Mouse_Over")
    end)
    Controls.ResumeGame:RegisterCallback(Mouse.eLClick, OnResumeGame)
    Controls.ResumeGame:RegisterCallback(Mouse.eMouseEnter, function()
        UI.PlaySound("Main_Menu_Mouse_Over")
    end)

end

-- ===========================================================================
-- Find the 'instance' table from the control
function FindIconInstanceFromControl(rootControl)

    if (rootControl ~= nil) then
        local controlTable = ms_IconOnlyIM:FindInstanceByControl(rootControl)
        if (controlTable == nil) then
            controlTable = ms_IconAndTextIM:FindInstanceByControl(rootControl)
        end

        return controlTable
    end

    return nil
end

-- ===========================================================================
-- Show or hide the "amount text" or the "Value Text" sub-control of the supplied control instance
function SetHideValueText(controlTable, bHide)

    if (controlTable ~= nil) then
        if (controlTable.AmountText ~= nil) then
            controlTable.AmountText:SetHide(bHide)
        end
        if (controlTable.ValueText ~= nil) then
            controlTable.ValueText:SetHide(bHide)
        end
    end
end

-- ===========================================================================
-- Detach the value edit overlay from anything it is attached to.
function ClearValueEdit()

    SetHideValueText(ms_ValueEditDealItemControlTable, false)

    ms_ValueEditDealItemControlTable = nil
    ms_ValueEditDealItemID = -1

end

-- ===========================================================================
-- Is the deal a gift to the other player?
function IsGiftToOtherPlayer()
    local pDeal = DealManager.GetWorkingDeal(DealDirection.OUTGOING,
                                             ms_LocalPlayer:GetID(),
                                             ms_OtherPlayer:GetID())
    if (pDeal ~= nil and not ms_bIsDemand and pDeal:IsValid()) then
        local iItemsFromLocal = pDeal:GetItemCount(ms_LocalPlayer:GetID(),
                                                   ms_OtherPlayer:GetID())
        local iItemsFromOther = pDeal:GetItemCount(ms_OtherPlayer:GetID(),
                                                   ms_LocalPlayer:GetID())

        if (iItemsFromLocal > 0 and iItemsFromOther == 0) then
            return true

        end
    end

    return false
end

-- ===========================================================================
function UpdateDealStatus()
    local bDealValid = false
    ClearValueEdit()
    local pDeal = DealManager.GetWorkingDeal(DealDirection.OUTGOING,
                                             ms_LocalPlayer:GetID(),
                                             ms_OtherPlayer:GetID())
    if (pDeal ~= nil) then
        if (pDeal:GetItemCount() > 0) then bDealValid = true end
    end

    if (bDealValid) then
        if pDeal:Validate() ~= DealValidationResult.VALID then
            bDealValid = false
        end
    end

    Controls.EqualizeDeal:SetHide(ms_bIsDemand)

    -- Have we sent out a deal?
    local bHasPendingDeal = DealManager.HasPendingDeal(ms_LocalPlayer:GetID(),
                                                       ms_OtherPlayer:GetID())

    if (not bHasPendingDeal and ms_LastIncomingDealProposalAction ==
        DealProposalAction.PENDING) then
        -- We have yet to send out a deal.
        Controls.AcceptDeal:SetHide(true)
        local showDemand = bDealValid and ms_bIsDemand
        Controls.DemandDeal:SetHide(not showDemand)
    else
        local cantAccept = (ms_LastIncomingDealProposalAction ~=
                               DealProposalAction.ACCEPTED and
                               ms_LastIncomingDealProposalAction ~=
                               DealProposalAction.PROPOSED and
                               ms_LastIncomingDealProposalAction ~=
                               DealProposalAction.ADJUSTED) or not bDealValid or
                               bHasPendingDeal
        Controls.AcceptDeal:SetHide(cantAccept)
        if (ms_bIsDemand) then
            if (ms_LocalPlayer:GetID() == ms_InitiatedByPlayerID) then
                -- Local human is making a demand
                if (ms_LastIncomingDealProposalAction ==
                    DealProposalAction.ACCEPTED) then
                    Controls.DemandDeal:SetHide(cantAccept)
                    -- The other player has accepted the demand, but we must enact it.
                    -- We won't have the human need to press the accept button, just do it and exit.
                    OnProposeOrAcceptDeal()
                    return
                else
                    Controls.AcceptDeal:SetHide(true)
                    Controls.DemandDeal:SetHide(false)
                end
            else
                Controls.DemandDeal:SetHide(true)
            end
        else
            Controls.DemandDeal:SetHide(true)
        end
    end

    UpdateProposalButtons(bDealValid)

    ResizeDealAndButtons()
end

-- ===========================================================================
function ResizeDealAndButtons()

    -- Find the widest deal button text and size others to match
    local refuseX, refuseY = AutoSizeGridButton(Controls.RefuseDeal, 200, 41,
                                                10, "1") -- CUI
    local equalizeX, equalizeY = AutoSizeGridButton(Controls.EqualizeDeal, 200,
                                                    32, 10, "1")
    local acceptX, acceptY = AutoSizeGridButton(Controls.AcceptDeal, 200, 41,
                                                10, "1")

    local minX = refuseX
    if not Controls.EqualizeDeal:IsHidden() and minX < equalizeX then
        minX = equalizeX
    end
    if not Controls.AcceptDeal:IsHidden() and minX < acceptX then
        minX = acceptX
    end

    if Controls.RefuseDeal:GetSizeX() < minX then
        Controls.RefuseDeal:SetSizeX(minX)
    end
    if Controls.EqualizeDeal:GetSizeX() < minX then
        Controls.EqualizeDeal:SetSizeX(minX)
    end
    if Controls.AcceptDeal:GetSizeX() < minX then
        Controls.AcceptDeal:SetSizeX(minX)
    end

    Controls.DealOptionsStack:CalculateSize()
    Controls.DealOptionsStack:ReprocessAnchoring()

    Controls.TheirOfferStack:CalculateSize()
    Controls.TheirOfferBracket:DoAutoSize()
    Controls.TheirOfferScroll:CalculateSize()

    Controls.MyOfferStack:CalculateSize()
    Controls.MyOfferBracket:DoAutoSize()
    Controls.MyOfferScroll:CalculateSize()
end

-- ===========================================================================
-- The Human has ask to have the deal equalized.  Well, what the AI is
-- willing to take.
function OnEqualizeDeal()
    ClearValueEdit()
    RequestEqualizeWorkingDeal()
end

-- ===========================================================================
-- Propose the deal, if this is the first time, or accept it, if the other player has
-- accepted it.
function OnProposeOrAcceptDeal()

    ClearValueEdit()

    if (ms_LastIncomingDealProposalAction == DealProposalAction.PENDING or
        ms_LastIncomingDealProposalAction == DealProposalAction.REJECTED or
        ms_LastIncomingDealProposalAction == DealProposalAction.EQUALIZE_FAILED) then
        ProposeWorkingDeal()
        UpdateDealStatus()
        UI.PlaySound("Confirm_Bed_Positive")
    else
        if (ms_LastIncomingDealProposalAction == DealProposalAction.ACCEPTED or
            ms_LastIncomingDealProposalAction == DealProposalAction.PROPOSED or
            ms_LastIncomingDealProposalAction == DealProposalAction.ADJUSTED) then
            -- Any adjustments?
            if (DealManager.AreWorkingDealsEqual(ms_LocalPlayer:GetID(),
                                                 ms_OtherPlayer:GetID())) then
                -- Yes, we can accept
                -- if deal will trigger war, prompt user before confirming deal
                local sendDealAndContinue =
                    function()
                        -- Send the deal.  This will also send out a POSITIVE response statement
                        DealManager.SendWorkingDeal(DealProposalAction.ACCEPTED,
                                                    ms_LocalPlayer:GetID(),
                                                    ms_OtherPlayer:GetID())
                        OnContinue()
                        UI.PlaySound("Confirm_Bed_Positive")
                    end

                local pDeal = DealManager.GetWorkingDeal(DealDirection.OUTGOING,
                                                         ms_LocalPlayer:GetID(),
                                                         ms_OtherPlayer:GetID())
                local pJointWarItem = pDeal:FindItemByType(
                                          DealItemTypes.AGREEMENTS,
                                          DealAgreementTypes.JOINT_WAR)
                if DealAgreementTypes.JOINT_WAR and pJointWarItem then
                    local iWarType = pJointWarItem:GetParameterValue("WarType")

                    if (iWarType == nil) then
                        iWarType = WarTypes.FORMAL_WAR
                    end

                    local targetPlayerID = pJointWarItem:GetValueType()
                    if (targetPlayerID >= 0) then
                        LuaEvents.DiplomacyActionView_ConfirmWarDialog(
                            ms_LocalPlayer:GetID(), targetPlayerID, iWarType,
                            sendDealAndContinue)
                    else
                        UI.DataError(
                            "Invalid Player ID to declare Joint War to: " ..
                                targetPlayerID)
                    end
                else
                    local pThirdPartyWarItem =
                        pDeal:FindItemByType(DealItemTypes.AGREEMENTS,
                                             DealAgreementTypes.THIRD_PARTY_WAR)
                    if (DealAgreementTypes.THIRD_PARTY_WAR and
                        pThirdPartyWarItem) then
                        local iWarType =
                            pThirdPartyWarItem:GetParameterValue("WarType")

                        if (iWarType == nil) then
                            iWarType = WarTypes.FORMAL_WAR
                        end

                        local targetPlayerID = pThirdPartyWarItem:GetValueType()
                        if (targetPlayerID >= 0) then
                            LuaEvents.DiplomacyActionView_ConfirmWarDialog(
                                ms_LocalPlayer:GetID(), targetPlayerID,
                                iWarType, sendDealAndContinue)
                        else
                            UI.DataError(
                                "Invalid Player ID to declare Third Party War to: " ..
                                    targetPlayerID)
                        end
                    else
                        sendDealAndContinue()
                    end
                end
            else
                -- No, send an adjustment and stay in the deal view.
                DealManager.SendWorkingDeal(DealProposalAction.ADJUSTED,
                                            ms_LocalPlayer:GetID(),
                                            ms_OtherPlayer:GetID())
                UpdateDealStatus()
            end
        end
    end
end

-- ===========================================================================
function OnRefuseDeal(bForceClose)

    if (bForceClose == nil) then bForceClose = false end

    local bHasPendingDeal = DealManager.HasPendingDeal(ms_LocalPlayer:GetID(),
                                                       ms_OtherPlayer:GetID())

    local sessionID = DiplomacyManager.FindOpenSessionID(Game.GetLocalPlayer(),
                                                         ms_OtherPlayer:GetID())
    if (sessionID ~= nil) then
        if (not ms_OtherPlayerIsHuman and not bHasPendingDeal) then
            -- Refusing an AI's deal
            ClearValueEdit()

            if (ms_InitiatedByPlayerID == ms_OtherPlayerID) then
                -- AI started this, so tell them that we don't want the deal
                if (bForceClose == true) then
                    -- Forcing the close, usually because the turn timer expired
                    DealManager.SendWorkingDeal(DealProposalAction.REJECTED,
                                                ms_LocalPlayer:GetID(),
                                                ms_OtherPlayer:GetID())
                    DiplomacyManager.CloseSession(sessionID)
                    StartExitAnimation()
                else
                    DiplomacyManager.AddResponse(sessionID,
                                                 Game.GetLocalPlayer(),
                                                 "NEGATIVE")
                end
            else
                -- Else close the session
                DiplomacyManager.CloseSession(sessionID)
                StartExitAnimation()
            end
        else
            if (ms_OtherPlayerIsHuman) then
                if (bHasPendingDeal) then
                    -- Canceling the deal with the other player.
                    DealManager.SendWorkingDeal(DealProposalAction.CLOSED,
                                                ms_LocalPlayer:GetID(),
                                                ms_OtherPlayer:GetID())
                else
                    if (ms_InitiatedByPlayerID ~= Game.GetLocalPlayer()) then
                        -- Refusing the deal with the other player.
                        DealManager.SendWorkingDeal(DealProposalAction.REJECTED,
                                                    ms_LocalPlayer:GetID(),
                                                    ms_OtherPlayer:GetID())
                    end
                end

                DiplomacyManager.CloseSession(sessionID)
                StartExitAnimation()
            end
        end
    else
        -- We have lost our session!
        if (not ContextPtr:IsHidden()) then
            if (not ms_bExiting) then OnResumeGame() end
        end
    end

end

-- ===========================================================================
function OnResumeGame()

    -- Exiting back to wait for a response
    ClearValueEdit()

    local sessionID = DiplomacyManager.FindOpenSessionID(Game.GetLocalPlayer(),
                                                         ms_OtherPlayer:GetID())
    if (sessionID ~= nil) then DiplomacyManager.CloseSession(sessionID) end

    -- Start the exit animation, it will call OnContinue when complete
    StartExitAnimation()
end

-- ===========================================================================
function OnExitFadeComplete()
    if (Controls.TradePanelFade:IsReversing()) then
        Controls.TradePanelFade:SetSpeed(2)
        Controls.TradePanelSlide:SetSpeed(2)

        OnContinue()
    end
end
Controls.TradePanelFade:RegisterEndCallback(OnExitFadeComplete)
-- ===========================================================================
-- Change the value number edit by a delta
function OnValueAmountEditDelta(dealItemID, delta)

    local pDeal = DealManager.GetWorkingDeal(DealDirection.OUTGOING,
                                             ms_LocalPlayer:GetID(),
                                             ms_OtherPlayer:GetID())
    if (pDeal ~= nil) then

        local pDealItem = pDeal:FindItemByID(dealItemID)
        if (pDealItem ~= nil) then
            local iNewAmount = tonumber(Controls.ValueAmountEditBox:GetText() or
                                            0) + delta
            iNewAmount = clip(iNewAmount, 1, pDealItem:GetMaxAmount())
            Controls.ValueAmountEditBox:SetText(tostring(iNewAmount))
        end
    end
end

-- ===========================================================================
-- Detach the value edit if it is attached to the control
function DetachValueEdit(itemID)

    if (itemID == ms_ValueEditDealItemID) then ClearValueEdit() end

end

-- ===========================================================================
-- Reattach the value edit overlay to the control set it is editing.
function ReAttachValueEdit()

    if (ms_ValueEditDealItemControlTable ~= nil) then

        SetHideValueText(ms_ValueEditDealItemControlTable, true)

        -- Display the number in the value edit field
        local pDeal = DealManager.GetWorkingDeal(DealDirection.OUTGOING,
                                                 ms_LocalPlayer:GetID(),
                                                 ms_OtherPlayer:GetID())
        if (pDeal ~= nil) then

            local pDealItem = pDeal:FindItemByID(ms_ValueEditDealItemID)
            if (pDealItem ~= nil) then

                local itemID = pDealItem:GetID()
                local itemType = pDealItem:GetType()
                if (itemType == DealItemTypes.GOLD or itemType ==
                    DealItemTypes.RESOURCES) then
                    -- Hide/show everything for GOLD and RESOURCE options
                    ms_AgreementOptionIM:ResetInstances()
                    Controls.ValueEditIconGrid:SetHide(false)
                    Controls.ValueAmountEditBoxContainer:SetHide(false)

                    local iDuration = pDealItem:GetDuration()

                    Controls.ValueEditHeaderLabel:SetText(
                        Locale.Lookup("LOC_DIPLOMACY_DEAL_HOW_MANY"))

                    if (iDuration == 0) then
                        ---- One time
                        Controls.ValueEditValueText:SetHide(true)
                    else
                        ---- Multi-turn
                        Controls.ValueEditValueText:LocalizeAndSetText(
                            "LOC_DIPLOMACY_DEAL_FOR_TURNS", iDuration)
                        Controls.ValueEditValueText:SetHide(false)
                    end

                    if (itemType == DealItemTypes.GOLD) then
                        SetIconToSize(Controls.ValueEditIcon,
                                      "ICON_YIELD_GOLD_5")
                    elseif (itemType == DealItemTypes.RESOURCES) then
                        local resourceType = pDealItem:GetValueType()
                        local resourceDesc = GameInfo.Resources[resourceType]
                        SetIconToSize(Controls.ValueEditIcon,
                                      "ICON_" .. resourceDesc.ResourceType)
                    end

                    Controls.ValueEditAmountText:SetText(
                        tostring(pDealItem:GetAmount()))
                    Controls.ValueEditAmountText:SetHide(false)

                    Controls.ValueAmountEditBox:SetText(
                        tostring(pDealItem:GetAmount()))
                    Controls.ValueEditButton:RegisterCallback(Mouse.eLClick,
                                                              function()
                        OnValueEditButton(itemID)
                    end)
                    Controls.ValueAmountEditLeftButton:RegisterCallback(
                        Mouse.eLClick,
                        function()
                            OnValueAmountEditDelta(itemID, -1)
                        end)
                    Controls.ValueAmountEditRightButton:RegisterCallback(
                        Mouse.eLClick,
                        function()
                            OnValueAmountEditDelta(itemID, 1)
                        end)
                elseif (itemType == DealItemTypes.AGREEMENTS) then
                    local subType = pDealItem:GetSubType()
                    local iDuration = pDealItem:GetDuration()

                    ShowAgreementOptionPopup(subType, iDuration,
                                             pDealItem:GetFromPlayerID())
                else
                    -- The value of the item cannot be adjusted so don't show a popup
                    return
                end
            end
        end

        Controls.ValueEditIconGrid:DoAutoSize()

        ResizeValueEditScrollPanel()

        Controls.ValueEditPopup:DoAutoSize()
        Controls.ValueEditPopupBackground:SetHide(false)
    end

end

-- ===========================================================================
-- Attach the value edit overlay to a control set.
function AttachValueEdit(rootControl, dealItemID)

    ClearValueEdit()

    local pDeal = DealManager.GetWorkingDeal(DealDirection.OUTGOING,
                                             ms_LocalPlayer:GetID(),
                                             ms_OtherPlayer:GetID())
    if (pDeal ~= nil) then

        local pDealItem = pDeal:FindItemByID(dealItemID)
        if (pDealItem ~= nil) then
            -- Do we have something to edit?
            if (pDealItem:HasPossibleValues() or pDealItem:HasPossibleAmounts()) then
                -- Yes
                ms_ValueEditDealItemControlTable =
                    FindIconInstanceFromControl(rootControl)
                ms_ValueEditDealItemID = dealItemID

                ReAttachValueEdit()
            end
        end
    end

end

-- ===========================================================================
-- Update the deal panel for a player
function UpdateDealPanel(player)

    -- If we modify the deal without sending it to the AI then reset the status to PENDING
    ms_LastIncomingDealProposalAction = DealProposalAction.PENDING

    UpdateDealStatus()

    PopulatePlayerDealPanel(Controls.TheirOfferStack, ms_OtherPlayer)
    PopulatePlayerDealPanel(Controls.MyOfferStack, ms_LocalPlayer)

    ResizeDealAndButtons()

end

-- ===========================================================================
function OnClickAvailableOneTimeGold(player, iAddAmount)

    if (ms_bIsDemand == true and ms_InitiatedByPlayerID == ms_OtherPlayerID) then
        -- Can't modifiy demand that is not ours
        return
    end

    local pDeal = DealManager.GetWorkingDeal(DealDirection.OUTGOING,
                                             ms_LocalPlayer:GetID(),
                                             ms_OtherPlayer:GetID())
    if (pDeal ~= nil) then

        local pPlayerTreasury = player:GetTreasury()
        local bFound = false

        -- Already there?
        local dealItems = pDeal:FindItemsByType(DealItemTypes.GOLD,
                                                DealItemSubTypes.NONE,
                                                player:GetID())
        local pDealItem
        if (dealItems ~= nil) then
            for i, pDealItem in ipairs(dealItems) do
                if (pDealItem:GetDuration() == 0) then
                    -- Already have a one time gold.  Up the amount
                    iAddAmount = pDealItem:GetAmount() + iAddAmount
                    iAddAmount = clip(iAddAmount, nil, pDealItem:GetMaxAmount())
                    if (iAddAmount ~= pDealItem:GetAmount()) then
                        pDealItem:SetAmount(iAddAmount)
                        bFound = true
                        break
                    else
                        return -- No change, just exit
                    end
                end
            end
        end

        -- Doesn't exist yet, add it.
        if (not bFound) then

            -- Going to add anything?
            pDealItem = pDeal:AddItemOfType(DealItemTypes.GOLD, player:GetID())
            if (pDealItem ~= nil) then

                -- Set the duration, so the max amount calculation knows what we are doing
                pDealItem:SetDuration(0)

                -- Adjust the gold to our max
                iAddAmount = clip(iAddAmount, nil, pDealItem:GetMaxAmount())
                if (iAddAmount > 0) then
                    pDealItem:SetAmount(iAddAmount)
                    bFound = true
                else
                    -- It is empty, remove it.
                    local itemID = pDealItem:GetID()
                    pDeal:RemoveItemByID(itemID)
                end
            end
        end

        if (bFound) then
            UpdateProposedWorkingDeal()
            UpdateDealPanel(player)
        end
    end
end

-- ===========================================================================
function OnClickAvailableMultiTurnGold(player, iAddAmount, iDuration)

    if (ms_bIsDemand == true and ms_InitiatedByPlayerID == ms_OtherPlayerID) then
        -- Can't modifiy demand that is not ours
        return
    end

    local pDeal = DealManager.GetWorkingDeal(DealDirection.OUTGOING,
                                             ms_LocalPlayer:GetID(),
                                             ms_OtherPlayer:GetID())
    if (pDeal ~= nil) then

        local pPlayerTreasury = player:GetTreasury()

        local bFound = false
        UI.PlaySound("UI_GreatWorks_Put_Down")

        -- Already there?
        local dealItems = pDeal:FindItemsByType(DealItemTypes.GOLD,
                                                DealItemSubTypes.NONE,
                                                player:GetID())
        local pDealItem
        if (dealItems ~= nil) then
            for i, pDealItem in ipairs(dealItems) do
                if (pDealItem:GetDuration() ~= 0) then
                    -- Already have a multi-turn gold.  Up the amount
                    iAddAmount = pDealItem:GetAmount() + iAddAmount
                    iAddAmount = clip(iAddAmount, nil, pDealItem:GetMaxAmount())
                    if (iAddAmount ~= pDealItem:GetAmount()) then
                        pDealItem:SetAmount(iAddAmount)
                        bFound = true
                        break
                    else
                        return -- No change, just exit
                    end
                end
            end
        end

        -- Doesn't exist yet, add it.
        if (not bFound) then
            -- Going to add anything?
            pDealItem = pDeal:AddItemOfType(DealItemTypes.GOLD, player:GetID())
            if (pDealItem ~= nil) then

                -- Set the duration, so the max amount calculation knows what we are doing
                pDealItem:SetDuration(iDuration)

                -- Adjust the gold to our max
                iAddAmount = clip(iAddAmount, nil, pDealItem:GetMaxAmount())

                if (iAddAmount > 0) then
                    pDealItem:SetAmount(iAddAmount)
                    bFound = true
                else
                    -- It is empty, remove it.
                    local itemID = pDealItem:GetID()
                    pDeal:RemoveItemByID(itemID)
                end
            end
        end

        if (bFound) then
            UpdateProposedWorkingDeal()
            UpdateDealPanel(player)
        end
    end
end

-- ===========================================================================
-- Clip val to be within the range of min and max
function clip(val, min, max)
    if min == nil then min = 1 end -- CUI
    if min and val < min then
        val = min
    elseif max and val > max then
        val = max
    end
    return val
end

-- ===========================================================================
-- Check to see if the deal should be auto-proposed.
function IsAutoPropose()
    if (not ms_OtherPlayerIsHuman) then
        local pDeal = DealManager.GetWorkingDeal(DealDirection.OUTGOING,
                                                 ms_LocalPlayer:GetID(),
                                                 ms_OtherPlayer:GetID())
        pDeal:Validate()
        if (pDeal ~= nil and not ms_bIsDemand and pDeal:IsValid() and
            not DealManager.HasPendingDeal(ms_LocalPlayer:GetID(),
                                           ms_OtherPlayer:GetID())) then
            local iItemsFromLocal = pDeal:GetItemCount(ms_LocalPlayer:GetID(),
                                                       ms_OtherPlayer:GetID())
            local iItemsFromOther = pDeal:GetItemCount(ms_OtherPlayer:GetID(),
                                                       ms_LocalPlayer:GetID())

            if (iItemsFromLocal > 0 or iItemsFromOther > 0) then
                return true
            end
        end
    end
    return false
end

-- ===========================================================================
-- Check the state of the deal and show/hide the special proposal buttons
function UpdateProposalButtons(bDealValid)

    local bDealIsPending = DealManager.HasPendingDeal(ms_LocalPlayer:GetID(),
                                                      ms_OtherPlayer:GetID())

    if (bDealValid and (not bDealIsPending or not ms_OtherPlayerIsHuman)) then
        Controls.ResumeGame:SetHide(true)
        local pDeal = DealManager.GetWorkingDeal(DealDirection.OUTGOING,
                                                 ms_LocalPlayer:GetID(),
                                                 ms_OtherPlayer:GetID())
        Controls.EqualizeDeal:SetHide(ms_bIsDemand)
        if (pDeal ~= nil) then

            local iItemsFromLocal = pDeal:GetItemCount(ms_LocalPlayer:GetID(),
                                                       ms_OtherPlayer:GetID())
            local iItemsFromOther = pDeal:GetItemCount(ms_OtherPlayer:GetID(),
                                                       ms_LocalPlayer:GetID())

            -- Hide/show directions if either side has no items
            Controls.MyDirections:SetHide(iItemsFromLocal > 0)
            Controls.TheirDirections:SetHide(iItemsFromOther > 0)

            if (not ms_bIsDemand) then
                if (not ms_OtherPlayerIsHuman) then
                    -- Dealing with an AI
                    if (pDeal:HasUnacceptableItems()) then
                        Controls.EqualizeDeal:SetHide(true)
                        Controls.AcceptDeal:SetHide(true)
                        SetLeaderDialog("LOC_DIPLO_DEAL_UNACCEPTABLE_DEAL", "")
                    elseif (iItemsFromLocal > 0 and iItemsFromOther == 0) then
                        -- One way gift?
                        if ms_LastIncomingDealProposalAction ==
                            DealProposalAction.EQUALIZE_FAILED then
                            -- Equalize failed, hide the button, and we can't accept now!
                            -- Except... not.
                            -- The AI will yield EQUALIZE_FAILED if it would have accepted the gift without modifications.
                            -- The AI does not distinguish between 'this gift is fine as is' and 'i would not give you anything for that'.
                            Controls.AcceptDeal:SetShow(false)
                            Controls.EqualizeDeal:SetShow(false)
                            SetLeaderDialog(
                                "LOC_DIPLO_DEAL_LEADER_GIFT_EQUALIZE_FAILED", "")
                        elseif ms_LastIncomingDealProposalAction ==
                            DealProposalAction.REJECTED then
                            -- Most likely autoproposed, there's a chance for an equalize. No accept, again.
                            Controls.AcceptDeal:SetShow(false)
                            Controls.EqualizeDeal:SetShow(true)
                            Controls.EqualizeDeal:LocalizeAndSetText(
                                "LOC_DIPLOMACY_DEAL_WHAT_WOULD_IT_TAKE")
                            Controls.EqualizeDeal:LocalizeAndSetToolTip(
                                "LOC_DIPLOMACY_DEAL_WHAT_IT_WILL_TAKE_TOOLTIP")
                            SetLeaderDialog(
                                "LOC_DIPLO_MAKE_DEAL_AI_REFUSE_DEAL_ANY_ANY", "")
                        else
                            -- No immediate complaints, I guess we can show both equalize and accept.
                            Controls.AcceptDeal:SetShow(true)
                            Controls.AcceptDeal:LocalizeAndSetText(
                                "LOC_DIPLOMACY_DEAL_GIFT_DEAL")
                            Controls.EqualizeDeal:SetShow(true)
                            Controls.EqualizeDeal:LocalizeAndSetText(
                                "LOC_DIPLOMACY_DEAL_WHAT_WOULD_YOU_GIVE_ME")
                            Controls.EqualizeDeal:LocalizeAndSetToolTip(
                                "LOC_DIPLO_DEAL_WHAT_WOULD_YOU_GIVE_ME_TOOLTIP")
                            SetLeaderDialog("LOC_DIPLO_DEAL_LEADER_GIFT",
                                            "LOC_DIPLO_DEAL_LEADER_GIFT_EFFECT")
                        end
                    else
                        if (iItemsFromLocal == 0 and iItemsFromOther > 0) then
                            -- AI was unable to equalize for the requested items so hide the equalize button
                            if ms_LastIncomingDealProposalAction ==
                                DealProposalAction.EQUALIZE_FAILED then
                                Controls.EqualizeDeal:SetHide(true)
                                SetLeaderDialog(
                                    "LOC_DIPLO_DEAL_LEADER_EQUALIZE_FAILED", "")
                            else
                                Controls.EqualizeDeal:SetHide(false)
                                SetLeaderDialog("LOC_DIPLO_DEAL_UNFAIR", "")
                            end

                            Controls.EqualizeDeal:LocalizeAndSetText(
                                "LOC_DIPLOMACY_DEAL_WHAT_WOULD_IT_TAKE")
                            Controls.EqualizeDeal:LocalizeAndSetToolTip(
                                "LOC_DIPLOMACY_DEAL_WHAT_IT_WILL_TAKE_TOOLTIP")
                            Controls.AcceptDeal:SetHide(true) -- If either of the above buttons are showing, disable the main accept button

                        else -- Something is being offered on both sides
                            -- Show equalize button if the accept button is hidden and the AI already hasn't attempted to equalize the deal
                            if Controls.AcceptDeal:IsHidden() and
                                ms_LastIncomingDealProposalAction ~=
                                DealProposalAction.EQUALIZE_FAILED then
                                Controls.EqualizeDeal:SetHide(false)
                                Controls.EqualizeDeal:LocalizeAndSetText(
                                    "LOC_DIPLOMACY_MAKE_DEAL_EQUITABLE")
                                Controls.EqualizeDeal:LocalizeAndSetToolTip(
                                    "LOC_DIPLOMACY_MAKE_DEAL_EQUITABLE_TOOLTIP")
                            else
                                Controls.EqualizeDeal:SetHide(true)
                                if ms_LastIncomingDealProposalAction ==
                                    DealProposalAction.PROPOSED then
                                    SetLeaderDialog("LOC_DIPLO_DEAL_INTRO_AI",
                                                    "")
                                elseif ms_LastIncomingDealProposalAction ==
                                    DealProposalAction.ACCEPTED then
                                    SetLeaderDialog(
                                        "LOC_DIPLO_MAKE_DEAL_AI_ACCEPT_DEAL_ANY_ANY",
                                        "")
                                elseif ms_LastIncomingDealProposalAction ==
                                    DealProposalAction.ADJUSTED then
                                    SetLeaderDialog(
                                        "LOC_DIPLO_DEAL_LEADER_EQUALIZE_SUCCEEDED",
                                        "")
                                else
                                    SetLeaderDialog(
                                        "LOC_DIPLO_DEAL_LEADER_EQUALIZE_FAILED",
                                        "")
                                end
                            end

                            Controls.AcceptDeal:LocalizeAndSetText(
                                "LOC_DIPLOMACY_DEAL_ACCEPT_DEAL")
                        end
                    end
                else
                    -- Dealing with another human
                    Controls.EqualizeDeal:SetHide(true)
                    Controls.AcceptDeal:SetHide(false)

                    if (ms_LastIncomingDealProposalAction ==
                        DealProposalAction.PENDING) then
                        -- Just starting the deal
                        if (iItemsFromLocal > 0 and iItemsFromOther == 0) then
                            -- Is this one way to them?
                            Controls.MyDirections:SetHide(true)
                            Controls.TheirDirections:SetHide(false)
                            Controls.AcceptDeal:LocalizeAndSetText(
                                "LOC_DIPLOMACY_DEAL_GIFT_DEAL")
                        else
                            -- Everything else is a proposal to another human
                            Controls.MyDirections:SetHide(true)
                            Controls.TheirDirections:SetHide(true)
                            Controls.AcceptDeal:LocalizeAndSetText(
                                "LOC_DIPLOMACY_DEAL_PROPOSE_DEAL")
                        end
                        -- Make sure the leader text is set to something appropriate.
                        SetDefaultLeaderDialogText()
                    else
                        Controls.MyDirections:SetHide(true)
                        Controls.TheirDirections:SetHide(true)
                        -- Are the incoming and outgoing deals the same?
                        if (DealManager.AreWorkingDealsEqual(
                            ms_LocalPlayer:GetID(), ms_OtherPlayer:GetID())) then
                            Controls.AcceptDeal:LocalizeAndSetText(
                                "LOC_DIPLOMACY_DEAL_ACCEPT_DEAL")
                        else
                            Controls.AcceptDeal:LocalizeAndSetText(
                                "LOC_DIPLOMACY_DEAL_PROPOSE_DEAL")
                        end
                    end
                end
            else
                -- Is a Demand
                if (ms_InitiatedByPlayerID == ms_OtherPlayerID) then
                    Controls.MyDirections:SetHide(true)
                    Controls.TheirDirections:SetHide(true)
                    SetDefaultLeaderDialogText()
                else
                    if (iItemsFromOther == 0) then
                        Controls.TheirDirections:SetHide(false)
                    else
                        Controls.TheirDirections:SetHide(true)
                    end
                    -- Demand against another player
                    SetLeaderDialog("LOC_DIPLO_DEAL_LEADER_DEMAND",
                                    "LOC_DIPLO_DEAL_LEADER_DEMAND_EFFECT")
                end
            end
        else
            -- Make sure the leader text is set to something appropriate.
            SetDefaultLeaderDialogText()
        end
    else
        -- There isn't a valid deal, or we are just viewing a pending deal.
        local bIsViewing = (bDealIsPending and ms_OtherPlayerIsHuman)

        local iItemsFromLocal = 0
        local iItemsFromOther = 0

        local pDeal = DealManager.GetWorkingDeal(DealDirection.OUTGOING,
                                                 ms_LocalPlayer:GetID(),
                                                 ms_OtherPlayer:GetID())
        if (pDeal ~= nil) then
            iItemsFromLocal = pDeal:GetItemCount(ms_LocalPlayer:GetID(),
                                                 ms_OtherPlayer:GetID())
            iItemsFromOther = pDeal:GetItemCount(ms_OtherPlayer:GetID(),
                                                 ms_LocalPlayer:GetID())
        end

        Controls.MyDirections:SetHide(bIsViewing or iItemsFromLocal > 0)
        Controls.TheirDirections:SetHide(bIsViewing or iItemsFromOther > 0)
        Controls.EqualizeDeal:SetHide(true)
        Controls.AcceptDeal:SetHide(true)
        Controls.DemandDeal:SetHide(true)

        if (not DealIsEmpty() and not bDealValid) then
            -- Set have the other leader tell them that the deal has invalid items.
            SetLeaderDialog("LOC_DIPLOMACY_DEAL_INVALID", "")
        else
            SetDefaultLeaderDialogText()
        end

        Controls.ResumeGame:SetHide(not bIsViewing)
    end

    if (bDealIsPending and ms_OtherPlayerIsHuman) then
        if (ms_bIsDemand) then
            Controls.RefuseDeal:LocalizeAndSetText(
                "LOC_DIPLOMACY_DEAL_CANCEL_DEMAND")
        else
            Controls.RefuseDeal:LocalizeAndSetText(
                "LOC_DIPLOMACY_DEAL_CANCEL_DEAL")
        end
    else
        -- Did the other player start this or the local player?
        if (ms_InitiatedByPlayerID == ms_OtherPlayerID) then
            if (not bDealValid) then
                -- Our changes have made the deal invalid, say cancel instead
                Controls.RefuseDeal:LocalizeAndSetText(
                    "LOC_DIPLOMACY_DEAL_CANCEL_DEAL")
            else
                if (ms_bIsDemand) then
                    Controls.AcceptDeal:LocalizeAndSetText(
                        "LOC_DIPLOMACY_DEAL_ACCEPT_DEMAND")
                    Controls.RefuseDeal:LocalizeAndSetText(
                        "LOC_DIPLOMACY_DEAL_REFUSE_DEMAND")
                else
                    Controls.RefuseDeal:LocalizeAndSetText(
                        "LOC_DIPLOMACY_DEAL_REFUSE_DEAL")
                end
            end
        else
            Controls.RefuseDeal:LocalizeAndSetText(
                "LOC_DIPLOMACY_DEAL_EXIT_DEAL")
        end
    end
    Controls.DealOptionsStack:CalculateSize()
    Controls.DealOptionsStack:ReprocessAnchoring()

    if (ms_bIsDemand) then
        if (ms_InitiatedByPlayerID == ms_OtherPlayerID) then
            -- Demand from the other player and we are responding
            Controls.MyOfferBracket:SetHide(false)
            Controls.MyOfferLabel:SetHide(false)
            Controls.TheirOfferLabel:SetHide(true)
            Controls.TheirOfferBracket:SetHide(true)
        else
            -- Demand from us, to the other player
            Controls.MyOfferBracket:SetHide(true)
            Controls.MyOfferLabel:SetHide(true)
            Controls.TheirOfferLabel:SetHide(false)
            Controls.TheirOfferBracket:SetHide(false)
        end
    else
        Controls.MyOfferLabel:SetHide(false)
        Controls.MyOfferBracket:SetHide(false)
        Controls.TheirOfferLabel:SetHide(false)
        Controls.TheirOfferBracket:SetHide(false)
    end
end

-- ===========================================================================
function PopulateAvailableGold(player, iconList)

    local iAvailableItemCount = 0

    local eFromPlayerID = player:GetID()
    local eToPlayerID = GetOtherPlayer(player):GetID()

    local pForDeal = DealManager.GetWorkingDeal(DealDirection.OUTGOING,
                                                ms_LocalPlayer:GetID(),
                                                ms_OtherPlayer:GetID())
    local possibleResources = DealManager.GetPossibleDealItems(eFromPlayerID,
                                                               eToPlayerID,
                                                               DealItemTypes.GOLD,
                                                               pForDeal)
    if (possibleResources ~= nil) then
        for i, entry in ipairs(possibleResources) do
            if (entry.Duration == 0) then
                -- CUI: one time gold, custom edit group
                if not ms_bIsDemand then
                    local editGroup = CuiGetEditGroup(iconList)
                    SetIconToSize(editGroup.Icon, "ICON_YIELD_GOLD_5")
                    editGroup.AmountText:SetText(entry.MaxAmount)
                    editGroup.Turns:SetHide(true)
                    CuiEditGroupSetup(player, editGroup, "ONE_TIME")

                    iAvailableItemCount = iAvailableItemCount + 1
                end
            else
                -- CUI: multi-turn gold, custom edit group
                local editGroup = CuiGetEditGroup(iconList)
                SetIconToSize(editGroup.Icon, "ICON_YIELD_GOLD_5")
                editGroup.AmountText:SetText(entry.MaxAmount)
                editGroup.Turns:SetHide(false)
                CuiEditGroupSetup(player, editGroup, "MULTI_TURN")

                iAvailableItemCount = iAvailableItemCount + 1
            end
            iconList.ListStack:CalculateSize()
            iconList.List:ReprocessAnchoring()
        end
    end

    return iAvailableItemCount
end

-- ===========================================================================
function OnClickAvailableBasic(itemType, player, valueType)

    if (ms_bIsDemand == true and ms_InitiatedByPlayerID == ms_OtherPlayerID) then
        -- Can't modifiy demand that is not ours
        return
    end

    local pDeal = DealManager.GetWorkingDeal(DealDirection.OUTGOING,
                                             ms_LocalPlayer:GetID(),
                                             ms_OtherPlayer:GetID())
    if (pDeal ~= nil) then

        -- Already there?
        local pDealItem = pDeal:FindItemByValueType(itemType,
                                                    DealItemSubTypes.NONE,
                                                    valueType, player:GetID())
        if (pDealItem == nil) then
            -- No
            pDealItem = pDeal:AddItemOfType(itemType, player:GetID())
            if (pDealItem ~= nil) then
                pDealItem:SetValueType(valueType)
                UpdateDealPanel(player)
                UpdateProposedWorkingDeal()
            end
        end
    end
end

-- ===========================================================================
function OnClickAvailableResource(player, resourceType)

    if (ms_bIsDemand == true and ms_InitiatedByPlayerID == ms_OtherPlayerID) then
        -- Can't modifiy demand that is not ours
        return
    end

    local pDeal = DealManager.GetWorkingDeal(DealDirection.OUTGOING,
                                             ms_LocalPlayer:GetID(),
                                             ms_OtherPlayer:GetID())
    if (pDeal ~= nil) then

        -- Already there?
        local dealItems = pDeal:FindItemsByType(DealItemTypes.RESOURCES,
                                                DealItemSubTypes.NONE,
                                                player:GetID())
        local pDealItem
        if (dealItems ~= nil) then
            for i, pDealItem in ipairs(dealItems) do
                if pDealItem:GetValueType() == resourceType then
                    -- Check for non-zero duration.  There may already be a one-time transfer of the resource if a city is in the deal.
                    if (pDealItem:GetDuration() ~= 0) then
                        return -- Already in there.
                    end
                end
            end
        end

        local pPlayerResources = player:GetResources()
        -- Get the total amount of the resource we have. This does not take into account anything already in the deal.
        local iAmount = pPlayerResources:GetResourceAmount(resourceType)
        if (iAmount > 0) then

            pDealItem = pDeal:AddItemOfType(DealItemTypes.RESOURCES,
                                            player:GetID())
            if (pDealItem ~= nil) then
                -- Add one
                pDealItem:SetValueType(resourceType)
                pDealItem:SetAmount(1)
                pDealItem:SetDuration(30) -- Default to this many turns

                -- After we add the item, test to see if the item is valid, it is possible that we have exceeded the amount of resources we can trade.
                if not pDealItem:IsValid() then
                    pDeal:RemoveItemByID(pDealItem:GetID())
                    pDealItem = nil
                else
                    UI.PlaySound("UI_GreatWorks_Put_Down")
                end

                UpdateDealPanel(player)
                UpdateProposedWorkingDeal()
            end
        end
    end
end

-- ===========================================================================
function OnClickAvailableAgreement(player, agreementType, agreementTurns)

    if (ms_bIsDemand == true and ms_InitiatedByPlayerID == ms_OtherPlayerID) then
        -- Can't modifiy demand that is not ours
        return
    end

    local pDeal = DealManager.GetWorkingDeal(DealDirection.OUTGOING,
                                             ms_LocalPlayer:GetID(),
                                             ms_OtherPlayer:GetID())
    if (pDeal ~= nil) then

        -- Already there?
        local pDealItem = pDeal:FindItemByType(DealItemTypes.AGREEMENTS,
                                               agreementType, player:GetID())
        if (pDealItem == nil) then
            if (agreementType == DealAgreementTypes.JOINT_WAR or agreementType ==
                DealAgreementTypes.THIRD_PARTY_WAR or agreementType ==
                DealAgreementTypes.RESEARCH_AGREEMENT) then
                ShowAgreementOptionPopup(agreementType, agreementTurns,
                                         player:GetID())
            else
                -- No
                pDealItem = pDeal:AddItemOfType(DealItemTypes.AGREEMENTS,
                                                player:GetID())
                if (pDealItem ~= nil) then
                    pDealItem:SetSubType(agreementType)
                    pDealItem:SetDuration(agreementTurns)

                    UpdateDealPanel(player)
                    UpdateProposedWorkingDeal()
                    UI.PlaySound("UI_GreatWorks_Put_Down")
                end
            end
        end
    end
end

-- ===========================================================================
function OnSelectAgreementOption(agreementType, agreementTurns, agreementValue,
                                 agreementParameters, fromPlayerId)
    local pDeal = DealManager.GetWorkingDeal(DealDirection.OUTGOING,
                                             ms_LocalPlayer:GetID(),
                                             ms_OtherPlayer:GetID())
    if (pDeal ~= nil) then

        -- Already there?
        local pDealItem = pDeal:FindItemByType(DealItemTypes.AGREEMENTS,
                                               agreementType, fromPlayerId)
        if (pDealItem ~= nil) then
            -- deal manager doesn't update properly unless we delete the deal item
            -- and add a new one.
            if (not pDealItem:IsLocked()) then
                local itemID = pDealItem:GetID()
                DetachValueEdit(itemID)
                pDeal:RemoveItemByID(itemID)
                pDealItem = pDeal:AddItemOfType(DealItemTypes.AGREEMENTS,
                                                fromPlayerId)
            end
        else
            pDealItem = pDeal:AddItemOfType(DealItemTypes.AGREEMENTS,
                                            fromPlayerId)
        end

        if (pDealItem ~= nil) then
            pDealItem:SetSubType(agreementType)
            pDealItem:SetDuration(agreementTurns)
            pDealItem:SetValueType(agreementValue)

            if (agreementType == DealAgreementTypes.JOINT_WAR or agreementType ==
                DealAgreementTypes.THIRD_PARTY_WAR) then
                pDealItem:SetParameterValue("WarType",
                                            agreementParameters.WarType)
            end

            UpdateDealPanel(ms_LocalPlayer)
            UpdateProposedWorkingDeal()
            UI.PlaySound("UI_GreatWorks_Put_Down")
        end

        Controls.ValueEditPopupBackground:SetHide(true)
    end
end

-- ===========================================================================
function ShowAgreementOptionPopup(agreementType, agreementTurns, fromPlayerId)

    -- Hide/show everything for AGREEMENTS options
    ms_AgreementOptionIM:ResetInstances()
    Controls.ValueEditIconGrid:SetHide(true)
    Controls.ValueAmountEditBoxContainer:SetHide(true)

    -- don't update when backing out
    ms_bDontUpdateOnBack = true

    if agreementType == DealAgreementTypes.RESEARCH_AGREEMENT then
        Controls.ValueEditHeaderLabel:SetText(
            Locale.Lookup("LOC_DIPLOMACY_DEAL_SELECT_TECH"))
    elseif agreementType == DealAgreementTypes.ALLIANCE then
        Controls.ValueEditHeaderLabel:SetText(
            Locale.Lookup("LOC_DIPLOMACY_DEAL_SELECT_ALLIANCE"))
    else
        Controls.ValueEditHeaderLabel:SetText(
            Locale.Lookup("LOC_DIPLOMACY_DEAL_SELECT_TARGET"))
    end

    local toPlayerId = ms_LocalPlayer:GetID()
    if (toPlayerId == fromPlayerId) then toPlayerId = ms_OtherPlayer:GetID() end
    local pForDeal = DealManager.GetWorkingDeal(DealDirection.OUTGOING,
                                                ms_LocalPlayer:GetID(),
                                                ms_OtherPlayer:GetID())
    local possibleValues = DealManager.GetPossibleDealItems(fromPlayerId,
                                                            toPlayerId,
                                                            DealItemTypes.AGREEMENTS,
                                                            agreementType,
                                                            pForDeal)
    if (possibleValues ~= nil) then
        for i, entry in ipairs(possibleValues) do
            local instance = ms_AgreementOptionIM:GetInstance()

            local szDisplayName = ""
            local szItemName = Locale.Lookup(entry.ForTypeDisplayName)
            if (entry.SubType == DealAgreementTypes.RESEARCH_AGREEMENT) then
                local eTech = GameInfo.Technologies[entry.ForType].Index
                local iTurns = ms_LocalPlayer:GetDiplomacy()
                                   :ComputeResearchAgreementTurns(
                                       ms_OtherPlayer, eTech)
                szDisplayName = Locale.Lookup(
                                    "LOC_DIPLOMACY_DEAL_PARAMETER_WITH_TURNS",
                                    szItemName, iTurns)
                instance.AgreementOptionIcon:SetIcon(
                    "ICON_" .. entry.ForTypeName)
                instance.AgreementOptionIcon:SetHide(false)
            else
                if (entry.SubType == DealAgreementTypes.JOINT_WAR or
                    entry.SubType == DealAgreementTypes.THIRD_PARTY_WAR) then
                    szDisplayName = szItemName

                    -- Have a type of war that describes the joint war?
                    if entry.Parameters ~= nil then
                        if entry.Parameters.WarType ~= nil then
                            local warDef =
                                GameInfo.Wars[entry.Parameters.WarType]
                            if warDef ~= nil then
                                szDisplayName =
                                    szDisplayName .. "[newline]" ..
                                        Locale.Lookup(warDef.Name)
                            end
                        end
                    end

                    instance.AgreementOptionIcon:SetHide(true)
                else
                    szDisplayName = szItemName
                    instance.AgreementOptionIcon:SetHide(true)
                end
            end

            instance.AgreementOptionLabel:SetText(szDisplayName)

            if agreementType == DealAgreementTypes.ALLIANCE then
                local allianceLevel = ms_LocalPlayer:GetDiplomacy()
                                          :GetAllianceLevel(ms_OtherPlayer)
                local allianceData = GameInfo.Alliances[entry.ForTypeName]
                local tooltip =
                    Game.GetGameDiplomacy():GetAllianceBenefitsString(
                        allianceData.Index, allianceLevel, true)
                instance.AgreementOptionButton:SetToolTipString(tooltip)
            else
                instance.AgreementOptionButton:SetToolTipString("")
            end

            local agreementValueType = entry.ForType
            local agreementParameters = entry.Parameters
            instance.AgreementOptionButton:RegisterCallback(Mouse.eLClick,
                                                            function()
                OnSelectAgreementOption(agreementType, agreementTurns,
                                        agreementValueType, agreementParameters,
                                        fromPlayerId)
            end)

            Controls.ValueEditButton:RegisterCallback(Mouse.eLClick,
                                                      OnAgreementBackButton)
        end
    end

    Controls.ValueEditIconGrid:DoAutoSize()

    ResizeValueEditScrollPanel()

    Controls.ValueEditPopup:DoAutoSize()
    Controls.ValueEditPopupBackground:SetHide(false)
end

-- ===========================================================================
function ResizeValueEditScrollPanel()
    -- Resize scroll panel to a maximum height of five agreement options
    Controls.ValueEditStack:CalculateSize()
    if Controls.ValueEditStack:GetSizeY() > MAX_DEAL_ITEM_EDIT_HEIGHT then
        Controls.ValueEditScrollPanel:SetSizeY(MAX_DEAL_ITEM_EDIT_HEIGHT)
    else
        Controls.ValueEditScrollPanel:SetSizeY(
            Controls.ValueEditStack:GetSizeY())
    end
    Controls.ValueEditScrollPanel:CalculateSize()
end

-- ===========================================================================
function OnAgreementBackButton()
    if not ms_bDontUpdateOnBack then
        UpdateDealPanel(ms_LocalPlayer)
        UpdateProposedWorkingDeal()
    end
    ms_bDontUpdateOnBack = false
    Controls.ValueEditPopupBackground:SetHide(true)
end

-- ===========================================================================
function OnClickAvailableGreatWork(player, type)

    OnClickAvailableBasic(DealItemTypes.GREATWORK, player, type)
    UI.PlaySound("UI_GreatWorks_Put_Down")

end

-- ===========================================================================
function OnClickAvailableCaptive(player, type)

    OnClickAvailableBasic(DealItemTypes.CAPTIVE, player, type)
    UI.PlaySound("UI_GreatWorks_Put_Down")

end

-- ===========================================================================
function OnClickAvailableCity(player, valueType, subType)

    if (ms_bIsDemand == true and ms_InitiatedByPlayerID == ms_OtherPlayerID) then
        -- Can't modifiy demand that is not ours
        return
    end

    local pDeal = DealManager.GetWorkingDeal(DealDirection.OUTGOING,
                                             ms_LocalPlayer:GetID(),
                                             ms_OtherPlayer:GetID())
    if (pDeal ~= nil) then

        -- Already there?
        local pDealItem = pDeal:FindItemByValueType(DealItemTypes.CITIES,
                                                    subType, valueType,
                                                    player:GetID())
        if (pDealItem == nil) then
            -- No
            local otherPlayerID = ms_OtherPlayer:GetID()
            if (otherPlayerID == player:GetID()) then
                otherPlayerID = ms_LocalPlayer:GetID()
            end

            pDealItem = pDeal:AddItemOfType(DealItemTypes.CITIES,
                                            player:GetID(), otherPlayerID,
                                            subType, valueType)
            if (pDealItem ~= nil) then
                pDealItem:SetSubType(subType)
                pDealItem:SetValueType(valueType)
                if (not pDealItem:IsValid(pDeal)) then
                    pDeal:RemoveItemByID(pDealItem:GetID())
                end
                UpdateDealPanel(player)
                UpdateProposedWorkingDeal()
            end
        end
    end

    UI.PlaySound("UI_GreatWorks_Put_Down")

end

-- ===========================================================================
function OnRemoveDealItem(player, itemID)

    if (ms_bIsDemand == true and ms_InitiatedByPlayerID == ms_OtherPlayerID) then
        -- Can't remove it
        return
    end

    DetachValueEdit(itemID)

    local pDeal = DealManager.GetWorkingDeal(DealDirection.OUTGOING,
                                             ms_LocalPlayer:GetID(),
                                             ms_OtherPlayer:GetID())
    if (pDeal ~= nil) then

        local pDealItem = pDeal:FindItemByID(itemID)
        if (pDealItem ~= nil) then
            if (not pDealItem:IsLocked()) then
                if (pDeal:RemoveItemByID(itemID)) then
                    UpdateDealPanel(player)
                    UpdateProposedWorkingDeal()
                    UI.PlaySound("UI_GreatWorks_Pick_Up")
                end
            end
        end
    end
end

-- ===========================================================================
function OnSelectValueDealItem(player, itemID, controlInstance)

    if (ms_bIsDemand == true and ms_InitiatedByPlayerID == ms_OtherPlayerID) then
        -- Can't edit it
        return
    end

    if (controlInstance ~= nil) then AttachValueEdit(controlInstance, itemID) end
end

-- ===========================================================================
function OnValueEditButton(itemID)
    local pDeal = DealManager.GetWorkingDeal(DealDirection.OUTGOING,
                                             ms_LocalPlayer:GetID(),
                                             ms_OtherPlayer:GetID())
    if pDeal then
        local pDealItem = pDeal:FindItemByID(itemID)
        if pDealItem then
            local newAmount = tonumber(Controls.ValueAmountEditBox:GetText())
            newAmount = clip(newAmount, 1, pDealItem:GetMaxAmount())

            if (newAmount ~= pDealItem:GetAmount()) then
                local subtype = pDealItem:GetSubType()
                local duration = pDealItem:GetDuration()
                local valueType = pDealItem:GetValueType()
                local fromPlayerId = pDealItem:GetFromPlayerID()
                local type = pDealItem:GetType()
                if (not pDealItem:IsLocked()) then
                    DetachValueEdit(itemID)
                    pDeal:RemoveItemByID(itemID)
                    pDealItem = pDeal:AddItemOfType(type, fromPlayerId)
                    pDealItem:SetSubType(subtype)
                    pDealItem:SetDuration(duration)
                    pDealItem:SetValueType(valueType)
                end

                pDealItem:SetAmount(newAmount)
                ms_bForceUpdateOnCommit = true
                UpdateProposedWorkingDeal()
            end

            if g_ValueEditDealItemControlTable then
                g_ValueEditDealItemControlTable.AmountText:SetText(newAmount)
                g_ValueEditDealItemControlTable.AmountText:SetHide(false)
            end
            UpdateDealStatus()
        end
    end

    Controls.ValueEditPopupBackground:SetHide(true)
end

-- ===========================================================================
function PopulateAvailableResources(player, iconList, className)

    local iAvailableItemCount = 0
    local pForDeal = DealManager.GetWorkingDeal(DealDirection.OUTGOING,
                                                ms_LocalPlayer:GetID(),
                                                ms_OtherPlayer:GetID())
    local possibleResources = DealManager.GetPossibleDealItems(player:GetID(),
                                                               GetOtherPlayer(
                                                                   player):GetID(),
                                                               DealItemTypes.RESOURCES,
                                                               pForDeal)
    if (possibleResources ~= nil) then
        for i, entry in ipairs(possibleResources) do

            local resourceDesc = GameInfo.Resources[entry.ForType]
            if (resourceDesc ~= nil) then
                -- Do we have some and is it a luxury item?
                if (entry.MaxAmount > 0 and resourceDesc.ResourceClassType ==
                    className) then
                    local icon = ms_IconOnlyIM:GetInstance(iconList.ListStack)
                    SetIconToSize(icon.Icon,
                                  "ICON_" .. resourceDesc.ResourceType, 36) -- CUI: smaller icon
                    icon.AmountText:SetText(tostring(entry.MaxAmount))
                    icon.AmountText:SetHide(false)

                    icon.SelectButton:SetDisabled(not entry.IsValid)
                    local resourceType = entry.ForType

                    -- CUI: resources check
                    icon.Turns:SetHide(true)
                    local resource = GameInfo.Resources[resourceType]
                    local localResources =
                        Players[ms_LocalPlayer:GetID()]:GetResources()
                    local otherResources =
                        Players[ms_OtherPlayer:GetID()]:GetResources()
                    local needMask = false
                    local addTooltip = ""

                    if (resource ~= nil and
                        (resource.ResourceClassType == "RESOURCECLASS_LUXURY" or
                            resource.ResourceClassType ==
                            "RESOURCECLASS_STRATEGIC")) then
                        -- their inventory
                        if player == ms_OtherPlayer then
                            -- we already have
                            if localResources:HasResource(resource.Index) then
                                needMask = true
                                addTooltip =
                                    "[NEWLINE][COLOR_Red]" ..
                                        Locale.Lookup(
                                            "LOC_CUI_DP_WE_HAVE_ITEM_TOOLTIP") ..
                                        "[ENDCOLOR]"
                            end
                            -- blocked deal, for AI only
                            if entry.MaxAmount == 1 and
                                not Players[ms_OtherPlayer:GetID()]:IsHuman() then
                                needMask = true
                                addTooltip =
                                    addTooltip .. "[NEWLINE][COLOR_Red]" ..
                                        Locale.Lookup(
                                            "LOC_DIPLO_DEAL_UNACCEPTABLE_ITEM_TOOLTIP") ..
                                        "[ENDCOLOR]"
                            end
                        end

                        -- our inventory
                        if player == ms_LocalPlayer then
                            -- thay already have
                            needMask =
                                otherResources:HasResource(resource.Index)
                            addTooltip =
                                "[NEWLINE][COLOR_Red]" ..
                                    Locale.Lookup(
                                        "LOC_CUI_DP_THEY_HAVE_ITEM_TOOLTIP") ..
                                    "[ENDCOLOR]"
                        end
                    end

                    if needMask then
                        icon.SelectButton:SetColor(CuiRedColor)
                        icon.SelectButton:SetToolTipString(
                            Locale.Lookup(resourceDesc.Name) .. addTooltip)
                    else
                        icon.SelectButton:SetColor(CuiGreenColor)
                        icon.SelectButton:SetToolTipString(
                            Locale.Lookup(resourceDesc.Name))
                    end
                    icon.UnacceptableIcon:SetHide(true)

                    -- What to do when double clicked/tapped.
                    icon.SelectButton:RegisterCallback(Mouse.eLClick, function()
                        OnClickAvailableResource(player, resourceType)
                    end)
                    -- Set a tool tip
                    -- CUI icon.SelectButton:LocalizeAndSetToolTip(resourceDesc.Name);
                    icon.SelectButton:ReprocessAnchoring()

                    iAvailableItemCount = iAvailableItemCount + 1
                end
            end
        end

        iconList.ListStack:CalculateSize()
        iconList.List:ReprocessAnchoring()
    end

    -- Hide if empty
    iconList.GetTopControl():SetHide(iconList.ListStack:GetSizeX() == 0)

    return iAvailableItemCount
end

-- ===========================================================================
function PopulateAvailableLuxuryResources(player, iconList)

    local iAvailableItemCount = 0
    iAvailableItemCount = iAvailableItemCount +
                              PopulateAvailableResources(player, iconList,
                                                         "RESOURCECLASS_LUXURY")
    return iAvailableItemCount
end

-- ===========================================================================
function PopulateAvailableStrategicResources(player, iconList)

    local iAvailableItemCount = 0
    iAvailableItemCount = iAvailableItemCount +
                              PopulateAvailableResources(player, iconList,
                                                         "RESOURCECLASS_STRATEGIC")
    return iAvailableItemCount
end

-- ===========================================================================
function PopulateAvailableAgreements(player, iconList)

    local iAvailableItemCount = 0
    local pForDeal = DealManager.GetWorkingDeal(DealDirection.OUTGOING,
                                                ms_LocalPlayer:GetID(),
                                                ms_OtherPlayer:GetID())
    local possibleAgreements = DealManager.GetPossibleDealItems(player:GetID(),
                                                                GetOtherPlayer(
                                                                    player):GetID(),
                                                                DealItemTypes.AGREEMENTS,
                                                                pForDeal)
    if (possibleAgreements ~= nil) then
        for i, entry in ipairs(possibleAgreements) do
            local agreementType = entry.SubType

            local agreementDuration = entry.Duration
            local icon = ms_IconAndTextIM:GetInstance(iconList.ListStack)

            local info = GameInfo.DiplomaticActions[agreementType]
            if (info ~= nil) then
                SetIconToSize(icon.Icon, "ICON_" .. info.DiplomaticActionType,
                              38)
            end
            icon.AmountText:SetHide(true)
            icon.IconText:LocalizeAndSetText(entry.SubTypeName)
            icon.SelectButton:SetDisabled(
                not entry.IsValid and entry.ValidationResult ~=
                    DealValidationResult.MISSING_DEPENDENCY) -- Hide if invalid, unless it is just missing a dependency, the user will update that when it is added to the deal.
            icon.ValueText:SetHide(true)

            -- What to do when double clicked/tapped.
            icon.SelectButton:RegisterCallback(Mouse.eLClick, function()
                OnClickAvailableAgreement(player, agreementType,
                                          agreementDuration)
            end)
            -- Set a tool tip if their is a duration
            if (entry.Duration > 0) then
                local szTooltip = Locale.Lookup(
                                      "LOC_DIPLOMACY_DEAL_PARAMETER_WITH_TURNS",
                                      entry.SubTypeName, entry.Duration)
                icon.SelectButton:SetToolTipString(szTooltip)
            else
                icon.SelectButton:SetToolTipString(nil)
            end

            -- icon.SelectButton:LocalizeAndSetToolTip( );
            icon.SelectButton:ReprocessAnchoring()

            iAvailableItemCount = iAvailableItemCount + 1
        end

        iconList.ListStack:CalculateSize()
        iconList.List:ReprocessAnchoring()
    end

    -- Hide if empty
    iconList.GetTopControl():SetHide(iconList.ListStack:GetSizeX() == 0)

    return iAvailableItemCount
end

-- ===========================================================================
function MakeCityToolTip(player, cityID)
    local pCity = player:GetCities():FindID(cityID)
    if (pCity ~= nil) then
        local szToolTip = Locale.Lookup("LOC_DEAL_CITY_POPULATION_TOOLTIP",
                                        pCity:GetPopulation())
        local districtNames = {}
        local pCityDistricts = pCity:GetDistricts()
        if (pCityDistricts ~= nil) then

            for i, pDistrict in pCityDistricts:Members() do
                local pDistrictDef = GameInfo.Districts[pDistrict:GetType()]
                if (pDistrictDef ~= nil) then
                    local districtType = pDistrictDef.DistrictType
                    -- Skip the city center and any wonder districts
                    if (districtType ~= "DISTRICT_CITY_CENTER" and districtType ~=
                        "DISTRICT_WONDER") then
                        table.insert(districtNames, pDistrictDef.Name)
                    end
                end
            end
        end

        if (#districtNames > 0) then
            szToolTip = szToolTip .. "[NEWLINE]" ..
                            Locale.Lookup("LOC_DEAL_CITY_DISTRICTS_TOOLTIP")
            for i, name in ipairs(districtNames) do
                szToolTip = szToolTip .. "[NEWLINE]" .. Locale.Lookup(name)
            end
        end

        -- Add Resources
        local extractedResources = player:GetResources()
                                       :GetResourcesExtractedByCity(cityID,
                                                                    ResultFormat.SUMMARY)
        if extractedResources ~= nil and #extractedResources > 0 then
            szToolTip = szToolTip .. "[NEWLINE]" ..
                            Locale.Lookup("LOC_DEAL_CITY_RESOURCES_TOOLTIP")
            for i, entry in ipairs(extractedResources) do
                local resourceDesc = GameInfo.Resources[entry.ResourceType]
                if resourceDesc ~= nil then
                    szToolTip = szToolTip .. "[NEWLINE]" ..
                                    Locale.Lookup(resourceDesc.Name) .. " : " ..
                                    tostring(entry.Amount)
                end
            end
        end

        -- Add Great Works
        local cityGreatWorks = player:GetCulture():GetGreatWorksInCity(cityID)
        if cityGreatWorks ~= nil and #cityGreatWorks > 0 then
            szToolTip = szToolTip .. "[NEWLINE]" ..
                            Locale.Lookup("LOC_DEAL_CITY_GREAT_WORKS_TOOLTIP")
            for i, entry in ipairs(cityGreatWorks) do
                local greatWorksDesc = GameInfo.GreatWorks[entry.GreatWorksType]
                if greatWorksDesc ~= nil then
                    szToolTip = szToolTip .. "[NEWLINE]" ..
                                    Locale.Lookup(greatWorksDesc.Name)
                end
            end
        end

        return szToolTip
    end

    return ""
end

-- ===========================================================================
function PopulateAvailableCities(player, iconList)

    local iAvailableItemCount = 0
    local pForDeal = DealManager.GetWorkingDeal(DealDirection.OUTGOING,
                                                ms_LocalPlayer:GetID(),
                                                ms_OtherPlayer:GetID())
    local possibleItems = DealManager.GetPossibleDealItems(player:GetID(),
                                                           GetOtherPlayer(player):GetID(),
                                                           DealItemTypes.CITIES,
                                                           pForDeal)
    if (possibleItems ~= nil) then
        for i, entry in ipairs(possibleItems) do

            local type = entry.ForType
            local subType = entry.SubType
            local icon = ms_IconAndTextIM:GetInstance(iconList.ListStack)
            SetIconToSize(icon.Icon, "ICON_BUILDINGS", 45)
            icon.AmountText:SetHide(true)
            icon.IconText:LocalizeAndSetText(entry.ForTypeName)
            icon.SelectButton:SetDisabled(
                not entry.IsValid and entry.ValidationResult ~=
                    DealValidationResult.MISSING_DEPENDENCY) -- Hide if invalid, unless it is just missing a dependency, the user will update that when it is added to the deal.
            icon.ValueText:SetHide(true)

            -- What to do when double clicked/tapped.
            icon.SelectButton:RegisterCallback(Mouse.eLClick, function()
                OnClickAvailableCity(player, type, subType)
            end)

            -- Since we're ceding this city make sure to look for this city in the current owners city list
            if entry.SubType == 1 then -- CitySubTypes:CEDE_OCCUPIED
                icon.SelectButton:SetToolTipString(
                    MakeCityToolTip(GetOtherPlayer(player), type))
            else
                icon.SelectButton:SetToolTipString(MakeCityToolTip(player, type))
            end

            iAvailableItemCount = iAvailableItemCount + 1
        end

        iconList.ListStack:CalculateSize()
    end

    -- Hide if empty
    iconList.GetTopControl():SetHide(iconList.ListStack:GetSizeX() == 0)

    return iAvailableItemCount
end

-- ===========================================================================
function PopulateAvailableOtherPlayers(player, iconList)

    local iAvailableItemCount = 0
    -- Hide if empty
    iconList.GetTopControl():SetHide(iconList.ListStack:GetSizeX() == 0)

    return iAvailableItemCount
end

-- ===========================================================================
function PopulateAvailableGreatWorks(player, iconList)

    local iAvailableItemCount = 0
    local pForDeal = DealManager.GetWorkingDeal(DealDirection.OUTGOING,
                                                ms_LocalPlayer:GetID(),
                                                ms_OtherPlayer:GetID())
    local possibleItems = DealManager.GetPossibleDealItems(player:GetID(),
                                                           GetOtherPlayer(player):GetID(),
                                                           DealItemTypes.GREATWORK,
                                                           pForDeal)
    if (possibleItems ~= nil) then
        for i, entry in ipairs(possibleItems) do
            local greatWorkDesc =
                GameInfo.GreatWorks[entry.ForTypeDescriptionID]
            if (greatWorkDesc ~= nil) then
                local type = entry.ForType
                local icon = ms_IconAndTextIM:GetInstance(iconList.ListStack)
                SetIconToSize(icon.Icon, "ICON_" .. greatWorkDesc.GreatWorkType,
                              45)
                icon.AmountText:SetHide(true)
                icon.IconText:LocalizeAndSetText(entry.ForTypeName)
                icon.SelectButton:SetDisabled(
                    not entry.IsValid and entry.ValidationResult ~=
                        DealValidationResult.MISSING_DEPENDENCY) -- Hide if invalid, unless it is just missing a dependency, the user will update that when it is added to the deal.
                icon.ValueText:SetHide(true)

                -- What to do when double clicked/tapped.
                icon.SelectButton:RegisterCallback(Mouse.eLClick, function()
                    OnClickAvailableGreatWork(player, type)
                end)
                -- Set a tool tip
                local strGreatWorkTooltip =
                    GreatWorksSupport_GetBasicTooltip(entry.ForType, false)
                icon.SelectButton:SetToolTipString(strGreatWorkTooltip)
                icon.SelectButton:ReprocessAnchoring()

                iAvailableItemCount = iAvailableItemCount + 1
            end
        end

        iconList.ListStack:CalculateSize()
        iconList.List:ReprocessAnchoring()
    end

    -- Hide if empty
    iconList.GetTopControl():SetHide(iconList.ListStack:GetSizeX() == 0)

    return iAvailableItemCount

end

-- ===========================================================================
function PopulateAvailableCaptives(player, iconList)

    local iAvailableItemCount = 0

    local pForDeal = DealManager.GetWorkingDeal(DealDirection.OUTGOING,
                                                ms_LocalPlayer:GetID(),
                                                ms_OtherPlayer:GetID())
    local possibleItems = DealManager.GetPossibleDealItems(player:GetID(),
                                                           GetOtherPlayer(player):GetID(),
                                                           DealItemTypes.CAPTIVE,
                                                           pForDeal)
    if (possibleItems ~= nil) then
        for i, entry in ipairs(possibleItems) do

            local type = entry.ForType
            local icon = ms_IconAndTextIM:GetInstance(iconList.ListStack)
            SetIconToSize(icon.Icon, "ICON_UNIT_SPY")
            icon.AmountText:SetHide(true)
            if (entry.ForTypeName ~= nil) then
                icon.IconText:LocalizeAndSetText(entry.ForTypeName)
            end
            icon.SelectButton:SetDisabled(
                not entry.IsValid and entry.ValidationResult ~=
                    DealValidationResult.MISSING_DEPENDENCY) -- Hide if invalid, unless it is just missing a dependency, the user will update that when it is added to the deal.
            icon.ValueText:SetHide(true)

            -- What to do when double clicked/tapped.
            icon.SelectButton:RegisterCallback(Mouse.eLClick, function()
                OnClickAvailableCaptive(player, type)
            end)
            icon.SelectButton:SetToolTipString(nil) -- We recycle the entries, so make sure this is clear.
            icon.SelectButton:ReprocessAnchoring()

            iAvailableItemCount = iAvailableItemCount + 1
        end

        iconList.ListStack:CalculateSize()
        iconList.List:ReprocessAnchoring()
    end

    -- Hide if empty
    iconList.GetTopControl():SetHide(iconList.ListStack:GetSizeX() == 0)

    return iAvailableItemCount
end

-- ===========================================================================
function PopulatePlayerAvailablePanel(rootControl, player)

    local iAvailableItemCount = 0

    if (player ~= nil) then

        local playerType = GetPlayerType(player)
        if (ms_bIsDemand and player:GetID() == ms_InitiatedByPlayerID) then
            -- This is a demand, so hide all the demanding player's items
            for i = 1, AvailableDealItemGroupTypes.COUNT, 1 do
                ms_AvailableGroups[i][playerType].GetTopControl():SetHide(true)
            end
        else
            ms_AvailableGroups[AvailableDealItemGroupTypes.GOLD][playerType]
                .GetTopControl():SetHide(false)

            iAvailableItemCount = iAvailableItemCount +
                                      PopulateAvailableGold(player,
                                                            ms_AvailableGroups[AvailableDealItemGroupTypes.GOLD][playerType])
            iAvailableItemCount = iAvailableItemCount +
                                      PopulateAvailableLuxuryResources(player,
                                                                       ms_AvailableGroups[AvailableDealItemGroupTypes.LUXURY_RESOURCES][playerType])
            iAvailableItemCount = iAvailableItemCount +
                                      PopulateAvailableStrategicResources(
                                          player,
                                          ms_AvailableGroups[AvailableDealItemGroupTypes.STRATEGIC_RESOURCES][playerType])

            if (not ms_bIsDemand) then
                iAvailableItemCount = iAvailableItemCount +
                                          PopulateAvailableAgreements(player,
                                                                      ms_AvailableGroups[AvailableDealItemGroupTypes.AGREEMENTS][playerType])
            else
                ms_AvailableGroups[AvailableDealItemGroupTypes.AGREEMENTS][playerType]
                    .GetTopControl():SetHide(true)
            end

            iAvailableItemCount = iAvailableItemCount +
                                      PopulateAvailableCities(player,
                                                              ms_AvailableGroups[AvailableDealItemGroupTypes.CITIES][playerType])

            if (not ms_bIsDemand) then
                iAvailableItemCount = iAvailableItemCount +
                                          PopulateAvailableOtherPlayers(player,
                                                                        ms_AvailableGroups[AvailableDealItemGroupTypes.OTHER_PLAYERS][playerType])
            else
                ms_AvailableGroups[AvailableDealItemGroupTypes.OTHER_PLAYERS][playerType]
                    .GetTopControl():SetHide(false)
            end

            iAvailableItemCount = iAvailableItemCount +
                                      PopulateAvailableGreatWorks(player,
                                                                  ms_AvailableGroups[AvailableDealItemGroupTypes.GREAT_WORKS][playerType])
            iAvailableItemCount = iAvailableItemCount +
                                      PopulateAvailableCaptives(player,
                                                                ms_AvailableGroups[AvailableDealItemGroupTypes.CAPTIVES][playerType])

        end

        rootControl:CalculateSize()
        rootControl:ReprocessAnchoring()

    end

    return iAvailableItemCount
end

-- ===========================================================================
function PopulateDealBasic(player, iconList, populateType, iconName)

    local pDeal = DealManager.GetWorkingDeal(DealDirection.OUTGOING,
                                             ms_LocalPlayer:GetID(),
                                             ms_OtherPlayer:GetID())
    local playerType = GetPlayerType(player)
    if (pDeal ~= nil) then

        local pDealItem
        for pDealItem in pDeal:Items() do
            local type = pDealItem:GetType()
            if (pDealItem:GetFromPlayerID() == player:GetID()) then
                local iDuration = pDealItem:GetDuration()
                local dealItemID = pDealItem:GetID()

                if (type == populateType) then
                    local icon = ms_IconAndTextIM:GetInstance(iconList)
                    SetIconToSize(icon.Icon, iconName)
                    icon.AmountText:SetHide(true)
                    local typeName = pDealItem:GetValueTypeNameID()
                    if (typeName ~= nil) then
                        icon.IconText:LocalizeAndSetText(typeName)
                    end

                    -- Show/hide unacceptable item notification
                    icon.UnacceptableIcon:SetHide(not pDealItem:IsUnacceptable())

                    icon.SelectButton:RegisterCallback(Mouse.eRClick,
                                                       function(void1, void2,
                                                                self)
                        OnRemoveDealItem(player, dealItemID, self)
                    end)
                    icon.SelectButton:RegisterCallback(Mouse.eLClick,
                                                       function(void1, void2,
                                                                self)
                        OnSelectValueDealItem(player, dealItemID, self)
                    end)

                    icon.SelectButton:SetToolTipString(nil) -- We recycle the entries, so make sure this is clear.
                end
            end
        end

        iconList:CalculateSize()
        iconList:ReprocessAnchoring()

    end

end

-- ===========================================================================
function GetParentItemTransferToolTip(parentDealItem)
    local szToolTip = ""

    -- If it is from a city, put the city name in the tool tip.
    if (parentDealItem:GetType() == DealItemTypes.CITIES) then

        local cityTypeName = parentDealItem:GetValueTypeNameID()
        if (cityTypeName ~= nil) then
            local cityName = Locale.Lookup(cityTypeName)
            local szTransfer = Locale.Lookup(
                                   "LOC_DEAL_ITEM_TRANSFERRED_WITH_CITY_TOOLTIP",
                                   cityName)

            szToolTip = "[NEWLINE]" .. szTransfer
        end
    end

    return szToolTip
end
-- ===========================================================================
function PopulateDealResources(player, iconList)
    local pDeal = DealManager.GetWorkingDeal(DealDirection.OUTGOING,
                                             ms_LocalPlayer:GetID(),
                                             ms_OtherPlayer:GetID())
    local playerType = GetPlayerType(player)
    if (pDeal ~= nil) then
        ms_IconOnlyIM:ReleaseInstanceByParent(iconList)
        ms_IconAndTextIM:ReleaseInstanceByParent(iconList)

        local pDealItem
        for pDealItem in pDeal:Items() do

            local type = pDealItem:GetType()
            if (pDealItem:GetFromPlayerID() == player:GetID()) then
                local iDuration = pDealItem:GetDuration()
                local dealItemID = pDealItem:GetID()
                -- Gold?
                if (type == DealItemTypes.GOLD) then
                    local icon
                    if (iDuration == 0) then
                        -- One time
                        icon = ms_IconOnlyIM:GetInstance(iconList)
                        icon.SelectButton:SetColor(CuiDefaultColor) -- CUI: reset color
                        icon.Turns:SetHide(true)
                    else
                        -- Multi-turn
                        icon = ms_IconOnlyIM:GetInstance(iconList)
                        icon.SelectButton:SetColor(CuiDefaultColor) -- CUI: reset color
                        icon.Turns:SetHide(false)
                    end
                    SetIconToSize(icon.Icon, "ICON_YIELD_GOLD_5")
                    icon.AmountText:SetText(tostring(pDealItem:GetAmount()))
                    icon.AmountText:SetHide(false)

                    -- Show/hide unacceptable item notification
                    icon.UnacceptableIcon:SetHide(not pDealItem:IsUnacceptable())

                    icon.SelectButton:RegisterCallback(Mouse.eRClick,
                                                       function(void1, void2,
                                                                self)
                        OnRemoveDealItem(player, dealItemID, self)
                    end)
                    icon.SelectButton:RegisterCallback(Mouse.eLClick,
                                                       function(void1, void2,
                                                                self)
                        OnSelectValueDealItem(player, dealItemID, self)
                    end)
                    icon.SelectButton:SetToolTipString(nil) -- We recycle the entries, so make sure this is clear.
                    if (dealItemID == ms_ValueEditDealItemID) then
                        ms_ValueEditDealItemControlTable = icon
                    end
                else
                    if (type == DealItemTypes.RESOURCES) then

                        local resourceType = pDealItem:GetValueType()
                        local icon
                        if (iDuration == 0) then
                            -- One time
                            icon = ms_IconOnlyIM:GetInstance(iconList)
                            icon.SelectButton:SetColor(CuiDefaultColor) -- CUI: reset color
                            icon.Turns:SetHide(true)
                        else
                            -- Multi-turn
                            icon = ms_IconOnlyIM:GetInstance(iconList)
                            icon.SelectButton:SetColor(CuiDefaultColor) -- CUI: reset color
                            icon.Turns:SetHide(false)
                        end
                        local resourceDesc = GameInfo.Resources[resourceType]
                        SetIconToSize(icon.Icon,
                                      "ICON_" .. resourceDesc.ResourceType)
                        icon.AmountText:SetText(tostring(pDealItem:GetAmount()))
                        icon.AmountText:SetHide(false)

                        -- Show/hide unacceptable item notification
                        icon.UnacceptableIcon:SetHide(
                            not pDealItem:IsUnacceptable())

                        local szToolTip = Locale.Lookup(resourceDesc.Name)

                        local parentDealItem = pDeal:GetItemParent(pDealItem)

                        if parentDealItem == nil then
                            -- No parent, the user can click on the item to change it.
                            icon.SelectButton:RegisterCallback(Mouse.eRClick,
                                                               function(void1,
                                                                        void2,
                                                                        self)
                                OnRemoveDealItem(player, dealItemID, self)
                            end)
                            icon.SelectButton:RegisterCallback(Mouse.eLClick,
                                                               function(void1,
                                                                        void2,
                                                                        self)
                                OnSelectValueDealItem(player, dealItemID, self)
                            end)
                        else
                            icon.SelectButton:ClearCallback(Mouse.eRClick) -- Clear, we are re-using control instances
                            icon.SelectButton:ClearCallback(Mouse.eLClick)

                            szToolTip = szToolTip ..
                                            GetParentItemTransferToolTip(
                                                parentDealItem)
                        end

                        -- Set a tool tip
                        icon.SelectButton:SetToolTipString(szToolTip)

                        -- KWG: Make a way for the icon manager to have categories, so the API is like this
                        -- icon.Icon:SetTexture(IconManager:FindIconAtlasForType(IconTypes.RESOURCE, resourceType));
                        if (dealItemID == ms_ValueEditDealItemID) then
                            ms_ValueEditDealItemControlTable = icon
                        end
                    end -- end else if the item isn't gold
                end -- end for each item in dael
            end -- end if deal
        end

        iconList:CalculateSize()
        iconList:ReprocessAnchoring()

    end

end

-- ===========================================================================
function PopulateDealAgreements(player, iconList)

    local pDeal = DealManager.GetWorkingDeal(DealDirection.OUTGOING,
                                             ms_LocalPlayer:GetID(),
                                             ms_OtherPlayer:GetID())
    local playerType = GetPlayerType(player)
    if (pDeal ~= nil) then

        local pDealItem
        for pDealItem in pDeal:Items() do

            local type = pDealItem:GetType()
            if (pDealItem:GetFromPlayerID() == player:GetID()) then
                local dealItemID = pDealItem:GetID()
                -- Agreement?
                if (type == DealItemTypes.AGREEMENTS) then
                    local icon = ms_IconAndTextIM:GetInstance(iconList)
                    local info =
                        GameInfo.DiplomaticActions[pDealItem:GetSubType()]
                    if (info ~= nil) then
                        SetIconToSize(icon.Icon,
                                      "ICON_" .. info.DiplomaticActionType, 38)
                    end

                    icon.AmountText:SetHide(true)

                    local pWarItem = pDeal:FindItemByType(
                                         DealItemTypes.AGREEMENTS,
                                         DealAgreementTypes.JOINT_WAR)

                    if pWarItem == nil then
                        pWarItem = pDeal:FindItemByType(
                                       DealItemTypes.AGREEMENTS,
                                       DealAgreementTypes.THIRD_PARTY_WAR)
                    end

                    local iWarType = nil
                    if pWarItem ~= nil then
                        iWarType = pDealItem:GetParameterValue("WarType")
                    end

                    if iWarType ~= nil then
                        local warDef = GameInfo.Wars[iWarType]
                        icon.IconText:LocalizeAndSetText(warDef.Name)
                    else
                        local subTypeDisplayName = pDealItem:GetSubTypeNameID()
                        if (subTypeDisplayName ~= nil) then
                            icon.IconText:LocalizeAndSetText(subTypeDisplayName)
                        end
                    end
                    icon.SelectButton:SetToolTipString(nil) -- We recycle the entries, so make sure this is clear.

                    -- Show/hide unacceptable item notification
                    icon.UnacceptableIcon:SetHide(not pDealItem:IsUnacceptable())

                    -- Populate the value pulldown
                    SetValueText(icon, pDealItem)

                    icon.SelectButton:RegisterCallback(Mouse.eRClick,
                                                       function(void1, void2,
                                                                self)
                        OnRemoveDealItem(player, dealItemID, self)
                    end)

                    if (info.DiplomaticActionType == "DIPLOACTION_JOINT_WAR" and
                        pDealItem:GetFromPlayerID() == ms_OtherPlayer:GetID()) then
                        icon.SelectButton:SetDisabled(true)
                        icon.SelectButton:SetToolTipString(
                            Locale.Lookup(
                                "LOC_JOINT_WAR_CANNOT_EDIT_THEIRS_TOOLTIP"))
                    else
                        icon.SelectButton:SetDisabled(false)
                        icon.SelectButton:RegisterCallback(Mouse.eLClick,
                                                           function(void1,
                                                                    void2, self)
                            OnSelectValueDealItem(player, dealItemID, self)
                        end)
                    end
                end
            end
        end

        iconList:CalculateSize()
        iconList:ReprocessAnchoring()

    end

end

-- ===========================================================================
function PopulateDealGreatWorks(player, iconList)

    local pDeal = DealManager.GetWorkingDeal(DealDirection.OUTGOING,
                                             ms_LocalPlayer:GetID(),
                                             ms_OtherPlayer:GetID())
    local playerType = GetPlayerType(player)
    if (pDeal ~= nil) then

        local pDealItem
        for pDealItem in pDeal:Items() do

            local type = pDealItem:GetType()
            if (pDealItem:GetFromPlayerID() == player:GetID()) then
                local iDuration = pDealItem:GetDuration()
                local dealItemID = pDealItem:GetID()

                if (type == DealItemTypes.GREATWORK) then
                    local icon = ms_IconAndTextIM:GetInstance(iconList)

                    local typeID = pDealItem:GetValueTypeID()
                    SetIconToSize(icon.Icon, "ICON_" .. typeID, 45)
                    icon.AmountText:SetHide(true)

                    local typeName = pDealItem:GetValueTypeNameID()

                    local strTooltip = ""

                    if (typeName ~= nil) then
                        icon.IconText:LocalizeAndSetText(typeName)
                        strTooltip = Locale.Lookup(
                                         GreatWorksSupport_GetBasicTooltip(
                                             pDealItem:GetValueType(), false))
                    else
                        icon.IconText:SetText(nil)
                    end

                    icon.ValueText:SetHide(true)

                    -- Show/hide unacceptable item notification
                    icon.UnacceptableIcon:SetHide(not pDealItem:IsUnacceptable())

                    local parentDealItem = pDeal:GetItemParent(pDealItem)

                    if parentDealItem == nil then
                        -- No parent, we can remove independently
                        icon.SelectButton:RegisterCallback(Mouse.eRClick,
                                                           function(void1,
                                                                    void2, self)
                            OnRemoveDealItem(player, dealItemID, self)
                        end)
                        icon.SelectButton:RegisterCallback(Mouse.eLClick,
                                                           function(void1,
                                                                    void2, self)
                            OnSelectValueDealItem(player, dealItemID, self)
                        end)
                    else
                        icon.SelectButton:ClearCallback(Mouse.eRClick)
                        icon.SelectButton:ClearCallback(Mouse.eLClick)
                        -- Add on to the tool tip to show why it is there.
                        strTooltip = strTooltip ..
                                         GetParentItemTransferToolTip(
                                             parentDealItem)
                    end

                    icon.SelectButton:SetToolTipString(strTooltip)
                end
            end
        end

        iconList:CalculateSize()
        iconList:ReprocessAnchoring()

    end

end

-- ===========================================================================
function PopulateDealCaptives(player, iconList)

    PopulateDealBasic(player, iconList, DealItemTypes.CAPTIVE, "ICON_UNIT_SPY")

end

-- ===========================================================================
function PopulateDealCities(player, iconList)

    local pDeal = DealManager.GetWorkingDeal(DealDirection.OUTGOING,
                                             ms_LocalPlayer:GetID(),
                                             ms_OtherPlayer:GetID())
    local playerType = GetPlayerType(player)
    if (pDeal ~= nil) then

        local pDealItem
        for pDealItem in pDeal:Items() do

            local type = pDealItem:GetType()
            if (pDealItem:GetFromPlayerID() == player:GetID()) then
                local dealItemID = pDealItem:GetID()

                if (type == DealItemTypes.CITIES) then
                    local icon = ms_IconAndTextIM:GetInstance(iconList)
                    SetIconToSize(icon.Icon, "ICON_BUILDINGS")
                    icon.AmountText:SetHide(true)
                    local typeName = pDealItem:GetValueTypeNameID()
                    if (typeName ~= nil) then
                        icon.IconText:LocalizeAndSetText(typeName)
                    end

                    -- Show/hide unacceptable item notification
                    icon.UnacceptableIcon:SetHide(not pDealItem:IsUnacceptable())

                    icon.SelectButton:RegisterCallback(Mouse.eRClick,
                                                       function(void1, void2,
                                                                self)
                        OnRemoveDealItem(player, dealItemID, self)
                    end)
                    icon.SelectButton:RegisterCallback(Mouse.eLClick,
                                                       function(void1, void2,
                                                                self)
                        OnSelectValueDealItem(player, dealItemID, self)
                    end)

                    icon.SelectButton:SetToolTipString(
                        MakeCityToolTip(player, pDealItem:GetValueType()))
                end
            end
        end

        iconList:CalculateSize()
        iconList:ReprocessAnchoring()

    end

end

-- ===========================================================================
function PopulatePlayerDealPanel(rootControl, player)

    if (player ~= nil) then

        local playerType = GetPlayerType(player)
        PopulateDealResources(player,
                              ms_DealGroups[DealItemGroupTypes.RESOURCES][playerType])
        PopulateDealAgreements(player,
                               ms_DealGroups[DealItemGroupTypes.AGREEMENTS][playerType])
        PopulateDealCaptives(player,
                             ms_DealGroups[DealItemGroupTypes.CAPTIVES][playerType])
        PopulateDealGreatWorks(player,
                               ms_DealGroups[DealItemGroupTypes.GREAT_WORKS][playerType])
        PopulateDealCities(player,
                           ms_DealGroups[DealItemGroupTypes.CITIES][playerType])

        rootControl:CalculateSize()
        rootControl:ReprocessAnchoring()
    end
end

-- ===========================================================================
function HandleESC()
    -- Were we just viewing the deal?
    if (m_kPopupDialog:IsOpen()) then
        m_kPopupDialog:Close()
    elseif (not Controls.ResumeGame:IsHidden()) then
        OnResumeGame()
    else
        OnRefuseDeal()
    end
end

-- ===========================================================================
--	INPUT Handlings
--	If this context is visible, it will get a crack at the input.
-- ===========================================================================
function KeyHandler(key)
    if (key == Keys.VK_ESCAPE) then
        HandleESC()
        return true
    end

    return false
end

-- ===========================================================================
function InputHandler(pInputStruct)
    local uiMsg = pInputStruct:GetMessageType()
    if uiMsg == KeyEvents.KeyUp then return KeyHandler(pInputStruct:GetKey()) end
    if (uiMsg == MouseEvents.LButtonUp or uiMsg == MouseEvents.RButtonUp or
        uiMsg == MouseEvents.MButtonUp or uiMsg == MouseEvents.PointerUp) then
        ClearValueEdit()
    end

    return false
end

-- ===========================================================================
--	Handle a request to be shown, this should only be called by
--  the diplomacy statement handler.
-- ===========================================================================
function OnShowMakeDeal(otherPlayerID)
    ms_OtherPlayerID = otherPlayerID
    ms_bIsDemand = false
    ContextPtr:SetHide(false)
end
LuaEvents.DiploPopup_ShowMakeDeal.Add(OnShowMakeDeal)

-- ===========================================================================
--	Handle a request to be shown, this should only be called by
--  the diplomacy statement handler.
-- ===========================================================================
function OnShowMakeDemand(otherPlayerID)
    ms_OtherPlayerID = otherPlayerID
    ms_bIsDemand = true
    ContextPtr:SetHide(false)
end
LuaEvents.DiploPopup_ShowMakeDemand.Add(OnShowMakeDemand)

-- ===========================================================================
--	Handle a request to be hidden, this should only be called by
--  the diplomacy statement handler.
-- ===========================================================================
function OnHideDeal(otherPlayerID) OnContinue() end
LuaEvents.DiploPopup_HideDeal.Add(OnHideDeal)

-- ===========================================================================
-- The other player has updated the deal
function OnDiplomacyIncomingDeal(eFromPlayer, eToPlayer, eAction)

    if (eFromPlayer == ms_OtherPlayerID) then
        local pDeal = DealManager.GetWorkingDeal(DealDirection.INCOMING,
                                                 ms_LocalPlayer:GetID(),
                                                 ms_OtherPlayer:GetID())
        if (pDeal ~= nil) then
            -- Copy the deal to our OUTGOING deal back to the other player, in case we want to make modifications
            DealManager.CopyIncomingToOutgoingWorkingDeal(
                ms_LocalPlayer:GetID(), ms_OtherPlayer:GetID())
            ms_LastIncomingDealProposalAction = eAction

            PopulatePlayerDealPanel(Controls.TheirOfferStack, ms_OtherPlayer)
            PopulatePlayerDealPanel(Controls.MyOfferStack, ms_LocalPlayer)
            UpdateDealStatus()

        end
    end

end
Events.DiplomacyIncomingDeal.Add(OnDiplomacyIncomingDeal)

-- ===========================================================================
--	Handle a deal changing, usually from an incoming statement.
-- ===========================================================================
function OnDealUpdated(otherPlayerID, eAction, szText)
    if (not ContextPtr:IsHidden()) then
        -- Display some updated text.
        if (szText ~= nil and szText ~= "") then
            SetLeaderDialog(szText, "")
        end
        -- Update deal and possible override text from szText
        OnDiplomacyIncomingDeal(otherPlayerID, Game.GetLocalPlayer(), eAction)
    end
end
LuaEvents.DiploPopup_DealUpdated.Add(OnDealUpdated)

-- ===========================================================================
function SetLeaderDialog(leaderDialog, leaderEffect)
    -- Update dialog
    Controls.LeaderDialog:LocalizeAndSetText(leaderDialog)

    -- Add parentheses to the effect text unless the text is ""
    if leaderEffect ~= "" then
        leaderEffect = "(" .. Locale.Lookup(leaderEffect) .. ")"
    end
    Controls.LeaderEffect:SetText(leaderEffect)

    -- Recenter text
    Controls.LeaderDialogStack:CalculateSize()
    Controls.LeaderDialogStack:ReprocessAnchoring()
end

-- ===========================================================================
function StartExitAnimation()
    -- Start the exit animation, it will call OnContinue when complete
    ms_bExiting = true
    Controls.YieldSlide:Reverse()
    Controls.YieldAlpha:Reverse()
    Controls.TradePanelFade:Reverse()
    Controls.TradePanelSlide:Reverse()
    Controls.TradePanelFade:SetSpeed(5)
    Controls.TradePanelSlide:SetSpeed(5)
    UI.PlaySound("UI_Diplomacy_Menu_Change")
end

-- ===========================================================================
function OnContinue() ContextPtr:SetHide(true) end

-- ===========================================================================
--	Functions for setting the data in the yield area
-- ===========================================================================
function FormatValuePerTurn(value)
    return Locale.ToNumber(value, "+#,###.#;-#,###.#")
end

function RefreshYields()

    local ePlayer = Game.GetLocalPlayer()
    local localPlayer = nil
    if ePlayer ~= -1 then
        localPlayer = Players[ePlayer]
        if localPlayer == nil then return end
    else
        return
    end

    ---- SCIENCE ----
    local playerTechnology = localPlayer:GetTechs()
    local currentScienceYield = playerTechnology:GetScienceYield()
    Controls.SciencePerTurn:SetText(FormatValuePerTurn(currentScienceYield))
    Controls.ScienceBacking:SetToolTipString(GetScienceTooltip())
    Controls.ScienceStack:CalculateSize()

    ---- CULTURE----
    local playerCulture = localPlayer:GetCulture()
    local currentCultureYield = playerCulture:GetCultureYield()
    Controls.CulturePerTurn:SetText(FormatValuePerTurn(currentCultureYield))
    Controls.CultureBacking:SetToolTipString(GetCultureTooltip())
    Controls.CultureStack:CalculateSize()

    ---- GOLD ----
    local playerTreasury = localPlayer:GetTreasury()
    local goldYield = playerTreasury:GetGoldYield() -
                          playerTreasury:GetTotalMaintenance()
    local goldBalance = math.floor(playerTreasury:GetGoldBalance())
    Controls.GoldBalance:SetText(Locale.ToNumber(goldBalance, "#,###.#"))
    Controls.GoldPerTurn:SetText(FormatValuePerTurn(goldYield))
    Controls.GoldBacking:SetToolTipString(GetGoldTooltip())
    Controls.GoldStack:CalculateSize()

    ---- FAITH ----
    local playerReligion = localPlayer:GetReligion()
    local faithYield = playerReligion:GetFaithYield()
    local faithBalance = playerReligion:GetFaithBalance()
    Controls.FaithBalance:SetText(Locale.ToNumber(faithBalance, "#,###.#"))
    Controls.FaithPerTurn:SetText(FormatValuePerTurn(faithYield))
    Controls.FaithBacking:SetToolTipString(GetFaithTooltip())
    Controls.FaithStack:CalculateSize()
    if (faithYield == 0) then
        Controls.FaithBacking:SetHide(true)
    else
        Controls.FaithBacking:SetHide(false)
    end

    Controls.YieldStack:CalculateSize()
    Controls.YieldStack:ReprocessAnchoring()
end
-- ===========================================================================
-- ===========================================================================
function OnShow()
    RefreshYields()
    Controls.YieldAlpha:SetToBeginning()
    Controls.YieldAlpha:Play()
    Controls.YieldSlide:SetToBeginning()
    Controls.YieldSlide:Play()
    Controls.TradePanelFade:SetToBeginning()
    Controls.TradePanelFade:Play()
    Controls.TradePanelSlide:SetToBeginning()
    Controls.TradePanelSlide:Play()
    Controls.LeaderDialogFade:SetToBeginning()
    Controls.LeaderDialogFade:Play()
    Controls.LeaderDialogSlide:SetToBeginning()
    Controls.LeaderDialogSlide:Play()
    Controls.ValueEditPopupBackground:SetHide(true)

    CuiResetEditGroup() -- CUI

    ms_IconOnlyIM:ResetInstances()
    ms_IconAndTextIM:ResetInstances()

    ms_bExiting = false

    if (Game.GetLocalPlayer() == -1) then return end

    -- For hotload testing, force the other player to be valid
    if (ms_OtherPlayerID == -1) then
        local playerID = 0
        for playerID = 0, GameDefines.MAX_PLAYERS - 1, 1 do
            if (playerID ~= Game.GetLocalPlayer() and
                Players[playerID]:IsAlive()) then
                ms_OtherPlayerID = playerID
                break
            end
        end
    end

    -- Set up some globals for easy access
    ms_LocalPlayer = Players[Game.GetLocalPlayer()]
    ms_OtherPlayer = Players[ms_OtherPlayerID]
    ms_OtherPlayerIsHuman = ms_OtherPlayer:IsHuman()

    local sessionID = DiplomacyManager.FindOpenSessionID(Game.GetLocalPlayer(),
                                                         ms_OtherPlayer:GetID())
    if (sessionID ~= nil) then
        local sessionInfo = DiplomacyManager.GetSessionInfo(sessionID)
        ms_InitiatedByPlayerID = sessionInfo.FromPlayer
    end

    -- Did the AI start this or the human?
    if (ms_InitiatedByPlayerID == ms_OtherPlayerID) then
        ms_LastIncomingDealProposalAction = DealProposalAction.PROPOSED
        DealManager.CopyIncomingToOutgoingWorkingDeal(ms_LocalPlayer:GetID(),
                                                      ms_OtherPlayer:GetID())
    else
        ms_LastIncomingDealProposalAction = DealProposalAction.PENDING
        -- We are NOT clearing the current outgoing deal. This allows other screens to pre-populate the deal.
    end

    UpdateOtherPlayerText(1)
    SetDefaultLeaderDialogText()

    local iAvailableItemCount = 0
    -- Available content to trade.  Shouldn't change during the session, but it might, especially in multiplayer.
    iAvailableItemCount = iAvailableItemCount +
                              PopulatePlayerAvailablePanel(
                                  Controls.MyInventoryStack, ms_LocalPlayer)
    iAvailableItemCount = iAvailableItemCount +
                              PopulatePlayerAvailablePanel(
                                  Controls.TheirInventoryStack, ms_OtherPlayer)

    Controls.MyInventoryScroll:CalculateSize()
    Controls.TheirInventoryScroll:CalculateSize()

    m_kPopupDialog:Close() -- Close and reset the popup in case it's open

    if (iAvailableItemCount == 0) then
        if (ms_bIsDemand) then
            m_kPopupDialog:AddText(Locale.Lookup(
                                       "LOC_DIPLO_DEMAND_NO_AVAILABLE_ITEMS"))
            m_kPopupDialog:AddTitle(Locale.ToUpper(
                                        Locale.Lookup(
                                            "LOC_DIPLO_CHOICE_MAKE_DEMAND")))
            m_kPopupDialog:AddButton(Locale.Lookup("LOC_OK_BUTTON"),
                                     OnRefuseDeal)
        else
            m_kPopupDialog:AddText(Locale.Lookup(
                                       "LOC_DIPLO_DEAL_NO_AVAILABLE_ITEMS"))
            m_kPopupDialog:AddTitle(Locale.ToUpper(
                                        Locale.Lookup(
                                            "LOC_DIPLO_CHOICE_MAKE_DEAL")))
            m_kPopupDialog:AddButton(Locale.Lookup("LOC_OK_BUTTON"),
                                     OnRefuseDeal)
        end
        m_kPopupDialog:Open()
    end

    PopulatePlayerDealPanel(Controls.TheirOfferStack, ms_OtherPlayer)
    PopulatePlayerDealPanel(Controls.MyOfferStack, ms_LocalPlayer)
    UpdateDealStatus()

    -- We may be coming into this screen with a deal already set, which needs to be sent to the AI for inspection. Check that.
    -- Don't send AI proposals for inspection or they will think the player was the creator of the deal
    if (IsAutoPropose() and
        (ms_InitiatedByPlayerID ~= ms_OtherPlayerID or ms_OtherPlayerIsHuman)) then
        ProposeWorkingDeal(true)
    end

    Controls.MyOfferScroll:CalculateSize()
    Controls.TheirOfferScroll:CalculateSize()

    LuaEvents.DiploBasePopup_HideUI(true)
    TTManager:ClearCurrent() -- Clear any tool tips raised;

    Controls.DealOptionsStack:CalculateSize()
    Controls.DealOptionsStack:ReprocessAnchoring()
end

----------------------------------------------------------------
function OnHide() LuaEvents.DiploBasePopup_HideUI(false) end

-- ===========================================================================
--	Context CTOR
-- ===========================================================================
function OnInit(isHotload)
    CreatePanels()

    if (isHotload and not ContextPtr:IsHidden()) then OnShow() end
end

-- ===========================================================================
--	Context DESTRUCTOR
--	Not called when screen is dismissed, only if the whole context is removed!
-- ===========================================================================
function OnShutdown() end

-- ===========================================================================
function OnLocalPlayerTurnEnd()
    if (not ContextPtr:IsHidden()) then
        -- Were we just viewing the deal?
        if (not Controls.ResumeGame:IsHidden()) then
            OnResumeGame()
        else
            OnRefuseDeal(true)
        end
        OnContinue()
    end
end

-- ===========================================================================
function OnPlayerDefeat(player, defeat, eventID)
    local localPlayer = Game.GetLocalPlayer()
    if (localPlayer and localPlayer >= 0) then -- Check to see if there is any local player
        -- Was it the local player?
        if (localPlayer == player) then OnLocalPlayerTurnEnd() end
    end
end

-- ===========================================================================
function OnTeamVictory(team, victory, eventID)

    local localPlayer = Game.GetLocalPlayer()
    if (localPlayer and localPlayer >= 0) then -- Check to see if there is any local player
        OnLocalPlayerTurnEnd()
    end
end

-- ===========================================================================
--	Engine Event
-- ===========================================================================
function OnUserRequestClose()
    -- Is this showing; if so then it needs to raise dialog to handle close
    if (not ContextPtr:IsHidden()) then
        m_kPopupDialog:Reset()
        m_kPopupDialog:AddText(Locale.Lookup("LOC_CONFIRM_EXIT_TXT"))
        m_kPopupDialog:AddButton(Locale.Lookup("LOC_NO"), nil)
        m_kPopupDialog:AddButton(Locale.Lookup("LOC_YES"), OnQuitYes, nil, nil,
                                 "PopupButtonInstanceRed")
        m_kPopupDialog:Open()
    end
end
function OnQuitYes() Events.UserConfirmedClose() end

-- CUI =======================================================================
function CuiResetEditGroup() CuiEditGroupIM:ResetInstances() end

-- CUI =======================================================================
function CuiGetEditGroup(iconList)
    return CuiEditGroupIM:GetInstance(iconList.ListStack)
end

-- CUI =======================================================================
function CuiEditGroupSetup(player, editGroup, groupType)
    if groupType == "ONE_TIME" then
        CuiRegCallback(editGroup.Edit100,
                       function()
            OnClickAvailableOneTimeGold(player, 100)
        end, function() OnClickAvailableOneTimeGold(player, -100) end)
        CuiRegCallback(editGroup.Edit10,
                       function() OnClickAvailableOneTimeGold(player, 10) end,
                       function()
            OnClickAvailableOneTimeGold(player, -10)
        end)
        CuiRegCallback(editGroup.Edit1,
                       function() OnClickAvailableOneTimeGold(player, 1) end,
                       function() OnClickAvailableOneTimeGold(player, -1) end)
    elseif groupType == "MULTI_TURN" then
        CuiRegCallback(editGroup.Edit100, function()
            OnClickAvailableMultiTurnGold(player, 100,
                                          ms_DefaultMultiTurnGoldDuration)
        end, function()
            OnClickAvailableMultiTurnGold(player, -100,
                                          ms_DefaultMultiTurnGoldDuration)
        end)
        CuiRegCallback(editGroup.Edit10, function()
            OnClickAvailableMultiTurnGold(player, 10,
                                          ms_DefaultMultiTurnGoldDuration)
        end, function()
            OnClickAvailableMultiTurnGold(player, -10,
                                          ms_DefaultMultiTurnGoldDuration)
        end)
        CuiRegCallback(editGroup.Edit1, function()
            OnClickAvailableMultiTurnGold(player, 1,
                                          ms_DefaultMultiTurnGoldDuration)
        end, function()
            OnClickAvailableMultiTurnGold(player, -1,
                                          ms_DefaultMultiTurnGoldDuration)
        end)
    end
end

-- ===========================================================================
function Initialize()

    ContextPtr:SetInitHandler(OnInit)
    ContextPtr:SetInputHandler(InputHandler, true)
    ContextPtr:SetShutdown(OnShutdown)
    ContextPtr:SetShowHandler(OnShow)
    ContextPtr:SetHideHandler(OnHide)

    Events.LocalPlayerTurnEnd.Add(OnLocalPlayerTurnEnd)
    Events.PlayerDefeat.Add(OnPlayerDefeat)
    Events.TeamVictory.Add(OnTeamVictory)

    Events.UserRequestClose.Add(OnUserRequestClose)

    m_kPopupDialog = PopupDialog:new("DiplomacyDealView")
end

Initialize()
