-- ===========================================================================
-- Cui Production Panel Support Functions
-- ---------------------------------------------------------------------------

include( "cui_helper" );

-- ===========================================================================
-- Help Functions
-- ---------------------------------------------------------------------------
function GetDistrictBaseType(district)
  local dType = district.DistrictType;
  if not isNil(GameInfo.DistrictReplaces[dType]) then
    dType = GameInfo.DistrictReplaces[dType].ReplacesDistrictType;
  end
  return dType;
end

-- ---------------------------------------------------------------------------
function CuiCanProduceDistrict(city, queue, district)
  local canProduce, results = queue:CanProduce(district.Hash, false, true);

  if not canProduce then
    local notSuitable = CuiDistrictReasonCheck(results);
    --
    if notSuitable then
      local plots = GetCityRelatedPlotIndexesDistrictsAlternative(city, district.Hash);
      if not isNil(plots) then canProduce = true; end
    end
  end

  return canProduce, results;
end

-- ---------------------------------------------------------------------------
function CuiDistrictReasonCheck(results)
  local suitableTxt = "LOC_DISTRICT_ZONE_NO_SUITABLE_LOCATION";
  -- local floodedTxt  = Locale.Lookup("LOC_DISTRICT_REPAIR_LOCATION_FLOODED");
  local notSuitable = false;
  -- local isFlooded   = false;

  if not isNil(results) then
    local fReasons = results[CityCommandResults.FAILURE_REASONS];
    if not isNil(fReasons) then
      for i, v in ipairs(fReasons) do
        if v == suitableTxt then notSuitable = true; end
        -- if v == floodedTxt  then isFlooded   = true; end
      end
    end
  end

  return notSuitable;
end

-- ---------------------------------------------------------------------------
function CuiIsItemInProgress(queue, item)
  if item.Progress > 0 then return true; end
  return item.RequiresPlacement and queue:HasBeenPlaced(item.Hash);
end

-- ---------------------------------------------------------------------------
function GetFailureToolTip(canProduce, results)
  if (not canProduce) and results then
    local failureReasons = results[CityCommandResults.FAILURE_REASONS];
    if not isNil(failureReasons) then
      local allReasons = "";
      for i, v in ipairs(failureReasons) do
        if not isNil(allReasons) then allReasons = allReasons .. "[NEWLINE]"; end
        allReasons = allReasons .. "[COLOR:Red]" .. Locale.Lookup(v) .. "[ENDCOLOR]";
      end
      return allReasons;
    end
  end

  return "";
end

-- ---------------------------------------------------------------------------
function GetPurchaseCostToolTip(cost, yield)
  local tooltip = "";
  if cost ~= 0 then
    local concatString = "";
    if yield == "YIELD_GOLD" then
      concatString = " [ICON_GOLD] " .. Locale.Lookup("LOC_YIELD_GOLD_NAME");
    elseif yield == "YIELD_FAITH" then
      concatString = " [ICON_FAITH] " .. Locale.Lookup("LOC_YIELD_FAITH_NAME");
    end
    tooltip = Locale.Lookup("LOC_HUD_PURCHASE") .. ": " .. cost .. concatString;
  end
  return tooltip;
end

-- ---------------------------------------------------------------------------
function GetProduceCostToolTip(cost, progress)
  local tooltip = "";
  if cost ~= 0 then
    local concatString = " [ICON_Production] " .. Locale.Lookup("LOC_HUD_PRODUCTION");
    local costString = tostring(cost);
    if progress > 0 then
      costString = tostring(progress) .. "/" .. tostring(cost);
    end
    tooltip = Locale.Lookup("LOC_HUD_PRODUCTION_COST") .. ": " .. costString .. concatString;
  end
  return tooltip;
end

-- ---------------------------------------------------------------------------
function TurnString(t)
  local n = (t == -1) and "999+" or t;
  return t .. "[ICON_TURN]";
end

-- ---------------------------------------------------------------------------
function ComposeTT( ... )
  local args = { ... };
  if isNil(args) then return ""; end

  local t = "";
  local r = "[NEWLINE][NEWLINE]";
  for _, v in ipairs(args) do
    if not isNil(v) then
      if isNil(t) then t = v;
                  else t = t .. r .. v;
      end
    end
  end
  return t;
end

-- ===========================================================================
-- Test & Debug
-- ---------------------------------------------------------------------------
function PPD(data)
 --
end

function isItem(item, name)
  local locName = Locale.Lookup(item.Name);
  return locName == name;
end

function pItem(item, extraInfo)
  print(Locale.Lookup(item.Name), extraInfo);
end
