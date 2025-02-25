-- ===================================================================
--  GSBQoLRankingsServerArchive.lua
--  Archives inactive players not on top lists.
-- ===================================================================
if isClient() then return end

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

local archiveInterval = SandboxVars.GSBQoLRanking.PruneInterval or 24
local daysSinceLastArchive = 0

local function onEveryHourCheckArchive()
    daysSinceLastArchive = daysSinceLastArchive + 1
    if daysSinceLastArchive >= archiveInterval then
        daysSinceLastArchive = 0
        pruneInactivePlayers()
    end
end

Events.EveryHours.Add(onEveryHourCheckArchive)
