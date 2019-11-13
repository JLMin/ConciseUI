--[[
-- Created by Andrew Garrett
-- Copyright (c) Firaxis Games 2018
--]] -- ===========================================================================
-- INCLUDES
-- ===========================================================================
include("DiplomacyDealView.lua")

-- ===========================================================================
--	VARIABLES
-- ===========================================================================
local ms_DefaultOneTimeFavorAmount = 1

-- CUI
local CuiDefaultColor = UI.GetColorValueFromHexLiteral(0xFFFFFFFF)
local cuiSPC = 5 -- Strategic Per Click

-- ===========================================================================
-- CACHE BASE FUNCTIONS
-- ===========================================================================
BASE_GetItemTypeIcon = GetItemTypeIcon
BASE_CreateGroupTypes = CreateGroupTypes
BASE_IsItemValueEditable = IsItemValueEditable
BASE_PopulateDealResources = PopulateDealResources
BASE_CreatePlayerAvailablePanel = CreatePlayerAvailablePanel
BASE_PopulatePlayerAvailablePanel = PopulatePlayerAvailablePanel

-- ===========================================================================
-- OVERRIDE BASE FUNCTIONS
-- ===========================================================================
function OnClickAvailableResource(player, resourceType)

  if ((ms_bIsDemand == true or ms_bIsGift == true) and ms_InitiatedByPlayerID == ms_OtherPlayerID) then
    -- Can't modifiy demand that is not ours
    return
  end

  local pBaseResourceDef = GameInfo.Resources[resourceType]
  local pResourceDef = GameInfo.Resource_Consumption[pBaseResourceDef.ResourceType]

  local pDeal = DealManager.GetWorkingDeal(DealDirection.OUTGOING, Game.GetLocalPlayer(), GetOtherPlayer():GetID())
  if (pDeal ~= nil) then

    -- Already there?
    local dealItems = pDeal:FindItemsByType(DealItemTypes.RESOURCES, DealItemSubTypes.NONE, player:GetID())
    local pDealItem
    if (dealItems ~= nil) then
      for i, pDealItem in ipairs(dealItems) do
        if pDealItem:GetValueType() == resourceType then
          -- Check for non-zero duration.  There may already be a one-time transfer of the resource if a city is in the deal.
          if (pDealItem:GetDuration() ~= 0) then
            return -- Already in there.
          end
          if (pResourceDef ~= nil and pResourceDef.Accumulate) then
            -- already have this, up the amount
            -- CUI: rewrite strategic logic
            local oldValue = pDealItem:GetAmount()
            local newValue = clip(oldValue + cuiSPC, nil, pDealItem:GetMaxAmount())

            if (newValue ~= pDealItem:GetAmount()) then
              pDealItem:SetAmount(newValue)

              if not pDealItem:IsValid() then
                pDealItem:SetAmount(oldValue)
                return
              else
                UI.PlaySound("UI_GreatWorks_Put_Down")
                UpdateDealPanel(player)
                UpdateProposedWorkingDeal()
                return
              end
            else
              return
            end
            --
          end
        end
      end
    end

    -- we don't need to check how many the player has, the deal manager will reject if we try to add too many
    local pPlayerResources = player:GetResources()
    pDealItem = pDeal:AddItemOfType(DealItemTypes.RESOURCES, player:GetID())
    if (pDealItem ~= nil) then
      pDealItem:SetValueType(resourceType)

      -- CUI: rewrite strategic logic
      if (pResourceDef ~= nil and pResourceDef.Accumulate) then
        local iAddAmount = math.min(cuiSPC, pDealItem:GetMaxAmount())
        pDealItem:SetAmount(iAddAmount)
        pDealItem:SetDuration(0)
      else
        pDealItem:SetAmount(1)
        pDealItem:SetDuration(30) -- Default to this many turns
      end
      --
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

-- ===========================================================================
-- Check the state of the deal and show/hide the special proposal buttons for a possible gift (not actually possible until XP2)
function UpdateProposalButtonsForGift(iItemsFromLocal, iItemsFromOther)
  local pDeal = DealManager.GetWorkingDeal(DealDirection.OUTGOING, g_LocalPlayer:GetID(), g_OtherPlayer:GetID())
  if (iItemsFromLocal == 0 and iItemsFromOther > 0 and not pDeal:IsGift()) then return true end

  return false
end

-- ===========================================================================
function GetItemTypeIcon(pDealItem)
  if (pDealItem:GetType() == DealItemTypes.FAVOR) then return "ICON_YIELD_FAVOR" end
  return BASE_GetItemTypeIcon(pDealItem)
end

-- ===========================================================================
function CreateGroupTypes()
  BASE_CreateGroupTypes()
  AvailableDealItemGroupTypes.FAVOR = table.count(AvailableDealItemGroupTypes) + 1
  DealItemGroupTypes.FAVOR = table.count(DealItemGroupTypes) + 1
end

-- ===========================================================================
function IsItemValueEditable(itemType) return BASE_IsItemValueEditable(itemType) or itemType == DealItemTypes.FAVOR end

-- ===========================================================================
function PopulateDealResources(player, iconList)

  BASE_PopulateDealResources(player, iconList)

  local pDeal = DealManager.GetWorkingDeal(DealDirection.OUTGOING, g_LocalPlayer:GetID(), g_OtherPlayer:GetID())
  local playerType = GetPlayerType(player)
  if (pDeal ~= nil) then
    for pDealItem in pDeal:Items() do
      if (pDealItem:GetFromPlayerID() == player:GetID()) then
        local type = pDealItem:GetType()
        local iDuration = pDealItem:GetDuration()
        local dealItemID = pDealItem:GetID()
        -- Gold?
        if (type == DealItemTypes.FAVOR) then
          local icon
          if (iDuration == 0) then
            -- One time
            icon = g_IconOnlyIM:GetInstance(iconList)
            SetIconToSize(icon.Icon, "ICON_YIELD_FAVOR")
            icon.AmountText:SetText(tostring(pDealItem:GetAmount()))
            icon.AmountText:SetHide(false)
            icon.Icon:SetColor(1, 1, 1)
            icon.SelectButton:SetColor(CuiDefaultColor) -- CUI: reset color
            icon.Turns:SetHide(true) -- CUI

            -- Show/hide unacceptable item notification
            icon.UnacceptableIcon:SetHide(not pDealItem:IsUnacceptable())

            icon.SelectButton:RegisterCallback(Mouse.eRClick, function(void1, void2, self)
              OnRemoveDealItem(player, dealItemID, self)
            end)
            icon.SelectButton:RegisterCallback(Mouse.eLClick,
                                               function(void1, void2, self) OnSelectValueDealItem(player, dealItemID, self) end)
            icon.SelectButton:SetToolTipString(nil) -- We recycle the entries, so make sure this is clear.
            icon.SelectButton:SetDisabled(false)
            if (dealItemID == g_ValueEditDealItemID) then g_ValueEditDealItemControlTable = icon end
          else
            -- Multi-turn
            UI.DataError(
                "Favor can only be traded in lump sums, but gamecore is indicating duration. This may be an issue @sbatista & @agarrett")
          end
        end -- end for each item in deal
      end -- end if deal
    end
  end

end

-- ===========================================================================
function CreatePlayerAvailablePanel(playerType, rootControl)
  -- CUI: custom gold & favor group
  g_AvailableGroups[AvailableDealItemGroupTypes.FAVOR][playerType] = CuiCreateEditGroup(rootControl)
  return BASE_CreatePlayerAvailablePanel(playerType, rootControl)
end

-- ===========================================================================
function PopulatePlayerAvailablePanel(rootControl, player)

  local playerType = GetPlayerType(player)
  local iAvailableItemCount = PopulateAvailableFavor(player, g_AvailableGroups[AvailableDealItemGroupTypes.FAVOR][playerType])
  iAvailableItemCount = iAvailableItemCount + BASE_PopulatePlayerAvailablePanel(rootControl, player)
  return iAvailableItemCount
end

function PopulateAvailableFavor(player, iconList)

  local iAvailableItemCount = 0

  local eFromPlayerID = player:GetID()
  local eToPlayerID = GetOtherPlayer(player):GetID()

  local pForDeal = DealManager.GetWorkingDeal(DealDirection.OUTGOING, g_LocalPlayer:GetID(), g_OtherPlayer:GetID())
  local possibleResources = DealManager.GetPossibleDealItems(eFromPlayerID, eToPlayerID, DealItemTypes.FAVOR, pForDeal)
  if ((possibleResources ~= nil) and (player:GetFavor() > 0)) then
    for i, entry in ipairs(possibleResources) do
      -- One time favor
      local favorBalance = player:GetFavor()

      if (not ms_bIsDemand) then

        -- CUI: use custom edit group
        local editGroup = CuiGetEditGroup(iconList)
        SetIconToSize(editGroup.Icon, "ICON_YIELD_FAVOR")
        editGroup.AmountText:SetText(favorBalance)
        editGroup.Turns:SetHide(true)
        CuiEditGroupSetup(player, editGroup, "FAVOR")
        editGroup.Icon:SetColor(1, 1, 1)
        --
        iAvailableItemCount = iAvailableItemCount + 1
      end
    end
  end

  return iAvailableItemCount
end

-- ===========================================================================
function OnClickAvailableOneTimeFavor(player, iAddAmount)

  if ((ms_bIsDemand == true or ms_bIsGift == true) and ms_InitiatedByPlayerID == ms_OtherPlayerID) then
    -- Can't modifiy demand that is not ours
    return
  end

  local pDeal = DealManager.GetWorkingDeal(DealDirection.OUTGOING, g_LocalPlayer:GetID(), g_OtherPlayer:GetID())
  if (pDeal ~= nil) then

    local bFound = false

    -- Already there?
    local dealItems = pDeal:FindItemsByType(DealItemTypes.FAVOR, DealItemSubTypes.NONE, player:GetID())
    local pDealItem
    if (dealItems ~= nil) then
      for i, pDealItem in ipairs(dealItems) do
        if (pDealItem:GetDuration() == 0) then
          -- Already have a one time favor.  Up the amount
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
      pDealItem = pDeal:AddItemOfType(DealItemTypes.FAVOR, player:GetID())
      if (pDealItem ~= nil) then

        -- Set the duration, so the max amount calculation knows what we are doing
        pDealItem:SetDuration(0)

        -- Adjust the favor to our max
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
