-- ===========================================================================
-- Cui Spy Info
-- eudaimonia, 3/11/2019
-- ===========================================================================
include("EspionageSupport")

-- ===========================================================================
local isAttached = false

-- ===========================================================================
function GetSpyTooltip(localPlayer)
  local playerUnits = localPlayer:GetUnits()
  local numberOfSpies = 0
  local tooltip = ""

  local spies = {}
  GetNormalSpies(spies, playerUnits)
  GetCapturedSpies(spies)
  GetTravellingSpies(spies, localPlayer)

  numberOfSpies = #spies
  if numberOfSpies > 0 then
    for _, spy in ipairs(spies) do
      local tmpInfo = "[NEWLINE][NEWLINE]"
      tmpInfo = tmpInfo .. spy.Name .. spy.Rank .. spy.City .. "[NEWLINE]"
      tmpInfo = tmpInfo .. spy.Action .. spy.Turns
      tooltip = tooltip .. tmpInfo
    end
  end

  return numberOfSpies, tooltip
end

-- ===========================================================================
function GetNormalSpies(spies, playerUnits)
  for i, unit in playerUnits:Members() do
    local unitInfo = GameInfo.Units[unit:GetUnitType()]
    if unitInfo.Spy then
      local spyEntry = {Name = "", Rank = "", City = "", Action = "", Turns = ""}

      spyEntry.Name = Locale.ToUpper(unit:GetName())
      spyEntry.Rank = " (" .. Locale.Lookup(GetSpyRankNameByLevel(unit:GetExperience():GetLevel())) .. ")"

      local spyPlot = Map.GetPlot(unit:GetX(), unit:GetY())
      local plotCity = Cities.GetPlotPurchaseCity(spyPlot)
      if plotCity then spyEntry.City = " - " .. Locale.ToUpper(plotCity:GetName()) end

      local operationType = unit:GetSpyOperation()
      if operationType == -1 then
        spyEntry.Action = Locale.Lookup("LOC_ESPIONAGEOVERVIEW_AWAITING_ASSIGNMENT")
      else
        local operationInfo = GameInfo.UnitOperations[operationType]
        local turnsRemaining = unit:GetSpyOperationEndTurn() - Game.GetCurrentGameTurn()
        if turnsRemaining <= 0 then turnsRemaining = 0 end
        if operationInfo then
          spyEntry.Action = Locale.Lookup(operationInfo.Description)
          spyEntry.Turns = " [" .. Locale.Lookup("LOC_ESPIONAGEOVERVIEW_MORE_TURNS", turnsRemaining) .. "]"
        end
      end

      table.insert(spies, spyEntry)
    end
  end
end

-- ===========================================================================
function GetCapturedSpies(spies)
  local players = Game.GetPlayers()
  for i, player in ipairs(players) do
    local playerDiplomacy = player:GetDiplomacy()
    local numCapturedSpies = playerDiplomacy:GetNumSpiesCaptured()
    for i = 0, numCapturedSpies - 1, 1 do
      local spy = playerDiplomacy:GetNthCapturedSpy(player:GetID(), i)
      if spy and spy.OwningPlayer == Game.GetLocalPlayer() then
        local spyEntry = {Name = "", Rank = "", City = "", Action = "", Turns = ""}

        local capturingPlayerConfig = PlayerConfigurations[player:GetID()]
        local capureingPlayerName = Locale.Lookup(capturingPlayerConfig:GetPlayerName())
        if capureingPlayerName then
          spyEntry.Name = Locale.ToUpper(spy.Name)
          spyEntry.Rank = " (" .. Locale.Lookup(GetSpyRankNameByLevel(spy.Level)) .. ")"
          spyEntry.Action = Locale.Lookup("LOC_ESPIONAGEOVERVIEW_CAPTURED") .. " '" .. capureingPlayerName .. "'"

          table.insert(spies, spyEntry)
        end
      end
    end
  end
end

-- ===========================================================================
function GetTravellingSpies(spies, localPlayer)
  local playerDiplomacy = localPlayer:GetDiplomacy()
  if playerDiplomacy then
    local numSpiesOffMap = playerDiplomacy:GetNumSpiesOffMap()
    for i = 0, numSpiesOffMap - 1, 1 do
      local spy = playerDiplomacy:GetNthOffMapSpy(localPlayer, i)
      if spy and spy.ReturnTurn ~= -1 then
        local spyEntry = {Name = "", Rank = "", City = "", Action = "", Turns = ""}

        local spyPlot = Map.GetPlot(spy.XLocation, spy.YLocation)
        local targetCity = Cities.GetPlotPurchaseCity(spyPlot)
        local travelTurnsRemaining = spy.ReturnTurn - Game.GetCurrentGameTurn()
        if targetCity and travelTurnsRemaining then
          spyEntry.Name = Locale.ToUpper(spy.Name)
          spyEntry.Rank = " (" .. Locale.Lookup(GetSpyRankNameByLevel(spy.Level)) .. ")"
          spyEntry.Action = Locale.Lookup("LOC_ESPIONAGEOVERVIEW_TRANSIT_TO", targetCity:GetName())
          spyEntry.Turns = "[" .. Locale.Lookup("LOC_ESPIONAGEOVERVIEW_MORE_TURNS", travelTurnsRemaining) .. "]"

          table.insert(spies, spyEntry)
        end
      end
    end
  end
end

-- ===========================================================================
function RefreshSpyInfo()
  local localPlayer = Players[Game.GetLocalPlayer()]
  if (localPlayer == nil) then return end

  local playerDiplo = localPlayer:GetDiplomacy()
  local spyCapacity = playerDiplo:GetSpyCapacity()

  if spyCapacity > 0 then
    local sSpyActive = 0
    local sTooltip = ""
    spyAvailable, sTooltip = GetSpyTooltip(localPlayer)
    local coloredAvailable = spyAvailable
    if spyAvailable > spyCapacity then
      coloredAvailable = "[COLOR_RED]" .. spyAvailable .. "[ENDCOLOR]"
    elseif spyAvailable < spyCapacity then
      coloredAvailable = "[COLOR_GREEN]" .. spyAvailable .. "[ENDCOLOR]"
    end
    Controls.SpyAvailable:SetText(coloredAvailable)
    Controls.SpyCapacity:SetText(spyCapacity)

    local sSummary = ""
    sSummary = sSummary .. Locale.Lookup("LOC_CUI_SI_SPY_AVAILABLE", spyAvailable) .. "[NEWLINE]"
    sSummary = sSummary .. Locale.Lookup("LOC_CUI_SI_SPY_CAPACITY", spyCapacity)
    Controls.CuiSpyInfo:SetToolTipString(sSummary .. sTooltip)

    Controls.CuiSpyInfo:SetHide(false)
  else
    Controls.CuiSpyInfo:SetHide(true)
  end

  Controls.SpyStack:CalculateSize()
  Controls.SpyStack:ReprocessAnchoring()
end

-- ===========================================================================
function AttachToTopPanel()
  if not isAttached then
    local infoStack = ContextPtr:LookUpControl("/InGame/TopPanel/InfoStack/StaticInfoStack")
    Controls.CuiSpyInfo:ChangeParent(infoStack)
    infoStack:AddChildAtIndex(Controls.CuiSpyInfo, 1)
    infoStack:CalculateSize()
    infoStack:ReprocessAnchoring()
    isAttached = true
  end
end

-- ===========================================================================
function Initialize()
  ContextPtr:SetHide(true)
  Events.LoadGameViewStateDone.Add(AttachToTopPanel)
  Events.TurnBegin.Add(RefreshSpyInfo)
  Events.LocalPlayerChanged.Add(RefreshSpyInfo)
  Events.LoadGameViewStateDone.Add(RefreshSpyInfo)
end
Initialize()
