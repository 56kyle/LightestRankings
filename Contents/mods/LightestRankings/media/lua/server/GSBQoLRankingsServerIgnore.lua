-- ===================================================================
--  GSBQoLRankingsServerIgnore.lua
--  Manages logic for ignoring specific players.
-- ===================================================================
if isClient() then return end

local Server = GSBQoL.Rankings.Server

-- This replicates old "filterPlayers" logic,
-- ignoring all players in data.ignoredPlayersList if needed.
function Server.filterPlayers()
    local data = Server.data
    if not data.ignoredPlayersList then
        return data.players
    end

    local results = {}
    for pName, stats in pairs(data.players) do
        if not data.ignoredPlayersList[pName] then
            results[pName] = stats
        end
    end
    return results
end
