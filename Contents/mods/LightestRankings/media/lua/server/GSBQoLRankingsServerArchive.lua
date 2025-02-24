-- ============================================================
--  GSBQoLRankingsServerArchive.lua
--  Logic responsible for archiving players
-- ============================================================

local Server = GSBQoL.Rankings.Server
local Config = Server.Config

function Server.PruneInactivePlayers()
    local data = Server.data
    local nowH = Server.GetGameHours()
    local cutoff = Config.INACTIVE_DAYS * 24

    local toRemove = {}
    for playerName, pData in pairs(data.players) do
        if not Server.PlayerIsOnAnyTopList(playerName) then
            local lastSeen = pData.lastSeen or 0
            if (nowH - lastSeen) >= cutoff then
                data.archivedPlayers[playerName] = pData
                table.insert(toRemove, playerName)
            end
        end
    end

    for _, rmName in ipairs(toRemove) do
        data.players[rmName] = nil
    end

    if #toRemove > 0 then
        Server.Logger.info("PruneInactivePlayers", { "Archived", #toRemove, "players" })
        Server.SaveModData()
    end
end

-- We'll run this every 24 hours
local pruneDayCounter = 0
Events.EveryHours.Add(function()
    pruneDayCounter = pruneDayCounter + 1
    if pruneDayCounter >= 24 then
        pruneDayCounter = 0
        Server.PruneInactivePlayers()
    end
end)
