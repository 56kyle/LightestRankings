-- ===================================================================
--  GSBQoLRankingsServerTopList.lua
--  Manages top lists (kills, deaths, overallKills, lifetime)
-- ===================================================================
if isClient() then return end

local Server = GSBQoL.Rankings.Server
local Config = Server.Config

local function insertOrUpdateRank(category, playerName, value)
    local topList = Server.data.topLists[category]
    if not topList then return end

    local oldIndex
    for i, entry in ipairs(topList) do
        if entry.name == playerName then
            oldIndex = i
            break
        end
    end
    if oldIndex then
        table.remove(topList, oldIndex)
    end

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

    if #topList > Config.maxTopListSize then
        table.remove(topList) -- remove last
    end
end

function Server.isOnAnyTopList(playerName)
    for _, topList in pairs(Server.data.topLists) do
        for _, entry in ipairs(topList) do
            if entry.name == playerName then
                return true
            end
        end
    end
    return false
end

function Server.rebuildAllScoreboards()
    local data = Server.data
    data.topLists = {
        kills = {},
        deaths = {},
        overallKills = {},
        lifetime = {}
    }

    for playerName, record in pairs(data.players) do
        local kills = record.kills or 0
        local deaths = record.deaths or 0
        local overallKills = record.overallKills or 0
        local lifetime = record.lifetime or 0

        if kills > 0 then
            insertOrUpdateRank("kills", playerName, kills)
        end
        if deaths > 0 then
            insertOrUpdateRank("deaths", playerName, deaths)
        end
        if overallKills > 0 then
            insertOrUpdateRank("overallKills", playerName, overallKills)
        end
        if lifetime > 0 then
            insertOrUpdateRank("lifetime", playerName, lifetime)
        end
    end

    Server.saveData()
end

function Server.updatePlayerStat(playerName, stat, newValue)
    local data = Server.data
    local record = data.players[playerName] or {
        overallKills = 0,
        deaths = 0,
        longestLifetime = 0,
        killsRegisteredInFaction = 0
    }

    record[stat] = newValue
    record.lastSeen = Server.getWorldHours()
    data.players[playerName] = record

    insertOrUpdateRank(stat, playerName, math.max(newValue, 0))
end
