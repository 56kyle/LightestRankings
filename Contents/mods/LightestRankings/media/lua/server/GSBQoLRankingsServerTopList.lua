-- ============================================================
--  GSBQoLRankingsServerTopList.lua
--  Logic responsible for managing the list of highest ranking players among each stat
-- ============================================================

local Server = GSBQoL.Rankings.Server
local Config = Server.Config

-- Insert or update a player in a single top list, e.g. "kills".
-- We do an insertion sort approach to avoid re-sorting big tables.
local function updateTopList(category, playerName, value)
    local data = Server.data
    local topList = data.topLists[category]
    if not topList then return end

    -- Remove existing if present
    local existingIndex = nil
    for i, entry in ipairs(topList) do
        if entry.name == playerName then
            existingIndex = i
            break
        end
    end
    if existingIndex then
        table.remove(topList, existingIndex)
    end

    -- Insert in descending order
    local inserted = false
    for i, entry in ipairs(topList) do
        if value > entry.value then
            table.insert(topList, i, { name = playerName, value = value })
            inserted = true
            break
        end
    end
    if not inserted then
        table.insert(topList, { name = playerName, value = value })
    end

    -- Enforce max scoreboard size
    if #topList > Config.TOP_SCOREBOARD_SIZE then
        table.remove(topList)
    end
end

-- Check if a player is in ANY top list
function Server.PlayerIsOnAnyTopList(playerName)
    for _, topList in pairs(Server.data.topLists) do
        for _, entry in ipairs(topList) do
            if entry.name == playerName then
                return true
            end
        end
    end
    return false
end

-- Rebuild all top lists from data.players dictionary
function Server.RebuildAllScoreboards()
    local data = Server.data
    data.topLists = {
        kills = {},
        deaths = {},
        overallKills = {},
        lifetime = {}
    }

    for playerName, pinfo in pairs(data.players) do
        local killsVal = pinfo.kills or 0
        local deathsVal = pinfo.deaths or 0
        local overallVal = pinfo.overallKills or 0
        local lifeVal = pinfo.lifetime or 0

        if killsVal > 0 then
            updateTopList("kills", playerName, killsVal)
        end
        if deathsVal > 0 then
            updateTopList("deaths", playerName, deathsVal)
        end
        if overallVal > 0 then
            updateTopList("overallKills", playerName, overallVal)
        end
        if lifeVal > 0 then
            updateTopList("lifetime", playerName, lifeVal)
        end
    end

    Server.SaveModData()
end

-- Update a single stat for a player and the relevant top list
function Server.UpdatePlayerStat(userName, statName, newValue)
    local data = Server.data
    local p = data.players[userName] or {
        overallKills = 0,
        deaths = 0,
        longestLifetime = 0,
        killsRegisteredInFaction = 0
    }
    p[statName] = newValue
    p.lastSeen = Server.GetGameHours()  -- refresh lastSeen
    data.players[userName] = p

    if newValue > 0 then
        updateTopList(statName, userName, newValue)
    else
        -- if zero, forcibly remove from top list
        updateTopList(statName, userName, 0)
    end
end
