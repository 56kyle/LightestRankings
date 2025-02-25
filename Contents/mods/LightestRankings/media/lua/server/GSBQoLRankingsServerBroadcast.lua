-- ===================================================================
--  GSBQoLRankingsServerBroadcast.lua
--  Broadcasting scoreboard & faction data to clients.
-- ===================================================================
if isClient() then return end

local Server = GSBQoL.Rankings.Server

function Server.broadcastScoreboard()
    local data = Server.data
    local scoreboardDict = {}

    local function addEntry(category, entry)
        local stats = scoreboardDict[entry.name] or {
            kills = 0,
            deaths = 0,
            overallKills = 0,
            lifetime = 0
        }
        stats[category] = entry.value
        scoreboardDict[entry.name] = stats
    end

    for _, entry in ipairs(data.topLists.kills) do
        addEntry("kills", entry)
    end
    for _, entry in ipairs(data.topLists.deaths) do
        addEntry("deaths", entry)
    end
    for _, entry in ipairs(data.topLists.overallKills) do
        addEntry("overallKills", entry)
    end
    for _, entry in ipairs(data.topLists.lifetime) do
        addEntry("lifetime", entry)
    end

    sendServerCommand(GSBQoL.Rankings.Shared.MODULE_NAME, "DataFromServer", scoreboardDict)
end

function Server.broadcastFaction()
    sendServerCommand(GSBQoL.Rankings.Shared.MODULE_NAME, "DataFactionFromServer", Server.data.factions)
end

function Server.broadcastAdminData(player)
    sendServerCommand(player, GSBQoL.Rankings.Shared.MODULE_NAME, "DataToAdmin", Server.data)
    Server.Logger.info("broadcastAdminData", {player:getUsername()})
end
