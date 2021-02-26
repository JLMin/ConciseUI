-- ===========================================================================
--	Production Panel / Purchase Panel
--	Override for Babylon DLC Heroes Mode
-- ===========================================================================
include("ProductionPanel");
include("ToolTipHelper")
include("ToolTipHelper_Babylon_Heroes");

local RightClickProductionItem_BASE = RightClickProductionItem;

-- ===========================================================================
-- Override: when clicking a Hero Devotion project, view the Hero info rather than
-- the project info
function RightClickProductionItem(sItemType:string)
	
	local pProjectInfo = GameInfo.Projects[sItemType];
	if (pProjectInfo ~= nil) then
		for row in GameInfo.HeroClasses() do
			if (row.CreationProjectType == sItemType) then
				-- View the Hero UnitType instead
				if (row.UnitType ~= "") then
					return RightClickProductionItem_BASE(row.UnitType);
				end
			end
		end
	end

	-- Default
	return RightClickProductionItem_BASE(sItemType);
end