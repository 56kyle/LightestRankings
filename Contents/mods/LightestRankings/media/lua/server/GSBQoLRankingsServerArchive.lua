-- ===================================================================
--  GSBQoLRankingsServerArchive.lua
--  Archives inactive players not on top lists.
-- ===================================================================
local Server = GSBQoL.Rankings.Server
local Config = Server.Config

local function pruneInactivePlayers()
    local nowHours = Server.getWorldHours()
    local cutoff = Config.daysBeforeArchive * 24

    local removed = {}
    for playerName, record in pairs(Server.data.players) do
        if not Server.isOnAnyTopList(playerName) then
            local lastSeen = record.lastSeen or 0
            if (nowHours - lastSeen) >= cutoff then
                Server.data.archivedPlayers[playerName] = record
                table.insert(removed, playerName)
            end
        end
    end

    for _, delName in ipairs(removed) do
        Server.data.players[delName] = nil
    end

    if #removed > 0 then
        Server.Logger.info("pruneInactivePlayers", {"Archived players:", #removed})
        Server.saveData()
    end
end

local dayCheck = 0
local function onEveryHourCheckArchive()
    dayCheck = dayCheck + 1
    if dayCheck >= 24 then
        dayCheck = 0
        pruneInactivePlayers()
    end
end

Events.EveryHours.Add(onEveryHourCheckArchive)
