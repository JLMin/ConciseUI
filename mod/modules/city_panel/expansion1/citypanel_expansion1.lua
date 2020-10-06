-- Copyright 2017-2019, Firaxis Games

include("CityPanel");
BASE_ViewMain = ViewMain;

-- ===========================================================================
function ViewMain( kData:table )
	BASE_ViewMain( kData );
	local pCity :table = UI.GetHeadSelectedCity();
	if pCity ~= nil then
		local pCulturalIdentity :table = pCity:GetCulturalIdentity();
		local currentLoyalty	:number= pCulturalIdentity:GetLoyalty();

        -- CUI >> loyalty
		Controls.BreakdownIcon:SetIcon("ICON_STAT_CULTURAL_FLAG");
		Controls.BreakdownLabel:SetText(Locale.ToUpper(Locale.Lookup("LOC_CULTURAL_IDENTITY_LOYALTY_SUBSECTION")));
		Controls.BreakdownNum:SetText(Round(currentLoyalty, 1));
		-- Controls.BreakdownNum:SetOffsetX(19);
        -- << CUI

        -- CUI >> districts numbers
        Controls.ReligionIcon:SetIcon("ICON_BUILDINGS");
        Controls.ReligionLabel:SetText(Locale.ToUpper(Locale.Lookup("LOC_HUD_DISTRICTS")));
        Controls.ReligionNum:SetText(kData.DistrictsNum .. "/" .. kData.DistrictsPossibleNum);
        -- << CUI
	end
end

-- ===========================================================================
function OnCityLoyaltyChanged( ownerPlayerID:number, cityID:number )
	if UI.IsCityIDSelected(ownerPlayerID, cityID) then
		UI.DeselectCityID(ownerPlayerID, cityID);
	end
end

-- ===========================================================================
function LateInitialize()
	Events.CityLoyaltyChanged.Add(OnCityLoyaltyChanged);
end
