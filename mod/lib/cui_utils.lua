-- ===========================================================================
-- cui_utils.lua
-- ===========================================================================

isExpansion1 = Modding.IsModActive("1B28771A-C749-434B-9053-D1380C553DE9")
isExpansion2 = Modding.IsModActive("4873eb62-8ccc-4574-b784-dda455e74e68")

-- CUI -----------------------------------------------------------------------
function printc(t, i)
    local n = i or ""
    if isNil(t) then
        print("Cui Print:", n, "nil")
    end

    if type(t) == "table" then
        local s = "-- Cui Print Table: " .. n .. " ================"
        print(s)
        for k, v in pairs(t) do
            print("-", k, v)
        end
        print("--")
    else
        print("Cui Print:", n, t)
    end
end

-- CUI -----------------------------------------------------------------------
function isNil(v)
    if type(v) == "table" then
        return v == nil or next(v) == nil
    elseif type(v) == "string" then
        return v == nil or v == ""
    else
        return v == nil
    end
end

-- CUI -----------------------------------------------------------------------
function SortedTable(t, f)
    local a = {}

    for n in pairs(t) do
        table.insert(a, n)
    end

    if f then
        table.sort(
            a,
            function(k1, k2)
                return f(t, k1, k2)
            end
        )
    else
        table.sort(a)
    end

    local i = 0
    local iter = function()
        i = i + 1
        if a[i] == nil then
            return nil
        else
            return a[i], t[a[i]]
        end
    end
    return iter
end

-- CUI -----------------------------------------------------------------------
function CuiRegCallback(control, callbackLClick, callbackRClick, sound)
    if callbackLClick then
        control:RegisterCallback(Mouse.eLClick, callbackLClick)
    end
    if callbackRClick then
        if sound then
            control:RegisterCallback(
                Mouse.eRClick,
                function()
                    callbackRClick()
                    UI.PlaySound(sound)
                end
            )
        else
            control:RegisterCallback(
                Mouse.eRClick,
                function()
                    callbackRClick()
                    UI.PlaySound("Play_UI_Click")
                end
            )
        end
    end
    control:RegisterCallback(
        Mouse.eMouseEnter,
        function()
            UI.PlaySound("Main_Menu_Mouse_Over")
        end
    )
end

-- CUI -----------------------------------------------------------------------
function CuiLeaderTexture(icon, size, shouldShow)
    local x, y, sheet
    x, y, sheet = IconManager:FindIconAtlas(icon, size)
    if (sheet == nil or sheet == "" or (not shouldShow)) then
        x, y, sheet = IconManager:FindIconAtlas("ICON_LEADER_DEFAULT", size)
    end
    return x, y, sheet
end

-- CUI -----------------------------------------------------------------------
function CuiSetIconToSize(iconControl, iconName, iconSize)
    if iconSize == nil then
        iconSize = 36
    end
    local x, y, szIconName, iconSize = IconManager:FindIconAtlasNearestSize(iconName, iconSize, true)
    iconControl:SetTexture(x, y, szIconName)
    iconControl:SetSizeVal(iconSize, iconSize)
end

-- CUI -----------------------------------------------------------------------
function CuiGetPlayerBasicData()
    local localPlayerID = Game.GetLocalPlayer()
    local localPlayer = Players[localPlayerID]
    local localDiplomacy = localPlayer:GetDiplomacy()

    local aliveMajors = PlayerManager.GetAliveMajors()
    table.sort(
        aliveMajors,
        function(a, b)
            return localDiplomacy:GetMetTurn(a:GetID()) < localDiplomacy:GetMetTurn(b:GetID())
        end
    )

    local playerData = {}
    local metPlayers, uniqueLeaders = GetMetPlayersAndUniqueLeaders()

    for _, pPlayer in ipairs(aliveMajors) do
        local playerID = pPlayer:GetID()
        local pPlayerConfig = PlayerConfigurations[playerID]
        playerData[playerID] = {
            playerID = playerID,
            isLocalPlayer = playerID == Game.GetLocalPlayer(),
            isHuman = GameConfiguration.IsAnyMultiplayer() and pPlayerConfig:IsHuman(),
            isMet = metPlayers[playerID],
            leaderName = pPlayerConfig:GetLeaderTypeName(),
            leaderIcon = "ICON_" .. pPlayerConfig:GetLeaderTypeName()
        }
    end

    return playerData
end
