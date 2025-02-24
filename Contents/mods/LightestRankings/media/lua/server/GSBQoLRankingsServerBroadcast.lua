-- ============================================================
--  GSBQoLRankingsServerBroadcast.lua
--  Logic responsible for broadcasting scoreboard & faction data
-- ============================================================

local Server = GSBQoL.Rankings.Server

function Server.BroadcastBase()
    local data = Server.data
    local toSend = {}

    -- Convert top lists back to the old dictionary style that the client expects
    local function insertEntry(cat, entry)
        local stats = toSend[entry.name] or { kills = 0, deaths = 0, overallKills = 0, lifetime = 0 }
        stats[cat] = entry.value
        toSend[entry.name] = stats
    end

    for _, entry in ipairs(data.topLists.kills) do
        insertEntry("kills", entry)
    end
    for _, entry in ipairs(data.topLists.deaths) do
        insertEntry("deaths", entry)
    end
    for _, entry in ipairs(data.topLists.overallKills) do
        insertEntry("overallKills", entry)
    end
    for _, entry in ipairs(data.topLists.lifetime) do
        insertEntry("lifetime", entry)
    end

    -- Now send to all
    sendServerCommand(GSBQoL.Rankings.Shared.MODULE_NAME, "DataFromServer", toSend)
end

function Server.BroadcastFaction()
    local data = Server.data
    sendServerCommand(GSBQoL.Rankings.Shared.MODULE_NAME, "DataFactionFromServer", data.factions)
end

-- Admin broadcast of entire data for the admin window
function Server.BroadcastAdmin(player)
    local data = Server.data
    sendServerCommand(player, GSBQoL.Rankings.Shared.MODULE_NAME, "DataToAdmin", data)
    Server.Logger.info("BroadcastAdmin", { player:getUsername() })
end
