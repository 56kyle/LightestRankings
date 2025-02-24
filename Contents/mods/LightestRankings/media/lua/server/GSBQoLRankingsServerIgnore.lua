-- ============================================================
--  GSBQoLRankingsServerIgnore.lua
--  Logic to filter ignored players (if needed)
-- ============================================================

local Server = GSBQoL.Rankings.Server

-- The original mod used filterPlayers() to remove them from broadcast.
-- With our top-lists approach, you can remove them from top lists or skip them.
-- We'll just replicate the old approach so it's available if needed:

function Server.filterPlayers()
    local data = Server.data
    local allPlayers = data.players
    local ignored = data.ignoredPlayersList
    if not ignored then
        return allPlayers
    end

    local filtered = {}
    for pName, stats in pairs(allPlayers) do
        if not ignored[pName] then
            filtered[pName] = stats
        end
    end
    return filtered
end
