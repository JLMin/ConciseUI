-- Copyright 2017-2019, Firaxis Games
include("CityPanel")
BASE_ViewMain = ViewMain

-- ===========================================================================
function ViewMain(kData)
  BASE_ViewMain(kData)
  local pCity = UI.GetHeadSelectedCity()
  if pCity ~= nil then
    local pCulturalIdentity = pCity:GetCulturalIdentity()
    local currentLoyalty = pCulturalIdentity:GetLoyalty()

    -- CUI: loyalty
    Controls.BreakdownIcon:SetIcon("ICON_STAT_CULTURAL_FLAG")
    Controls.BreakdownLabel:SetText(Locale.ToUpper(Locale.Lookup("LOC_CULTURAL_IDENTITY_LOYALTY_SUBSECTION")))
    Controls.BreakdownNum:SetText(Round(currentLoyalty, 1))
    -- CUI: districts numbers
    Controls.ReligionIcon:SetIcon("ICON_BUILDINGS")
    Controls.ReligionLabel:SetText(Locale.ToUpper(Locale.Lookup("LOC_HUD_DISTRICTS")))
    Controls.ReligionNum:SetText(kData.DistrictsNum .. "/" .. kData.DistrictsPossibleNum)

  end
end

-- ===========================================================================
function OnCityLoyaltyChanged(ownerPlayerID, cityID)
  if UI.IsCityIDSelected(ownerPlayerID, cityID) then UI.DeselectCityID(ownerPlayerID, cityID) end
end

-- ===========================================================================
function LateInitialize() Events.CityLoyaltyChanged.Add(OnCityLoyaltyChanged) end
