-- ===================================================================
--  GSBQoLRankingsServerCommands.lua
--  Handles BaseInfo, DeathKillsCount, ignoring players, etc.
-- ===================================================================
if isClient() then return end

local Server = GSBQoL.Rankings.Server

Server.Commands = Server.Commands or {}

function Server.Commands.BaseInfo(player, args)
    -- args: { name, killCount, hoursSurvived }
    local userName = args[1]
    local kills = args[2]
    local survivalHours = args[3]

    local record = Server.data.players[userName] or {
        overallKills = 0,
        deaths = 0,
        longestLifetime = 0,
        killsRegisteredInFaction = 0
    }
    record.lastSeen = Server.getWorldHours()

    Server.updatePlayerStat(userName, "kills", kills)
    Server.updatePlayerStat(userName, "lifetime", survivalHours)

    Server.registerFactionKills(player, kills, Server.data, record)
    Server.data.players[userName] = record
    Server.saveData()
end

function Server.Commands.DeathKillsCount(player, args)
    -- args: { name, killCount, hoursSurvived }
    local userName = args[1]
    local kills = args[2]
    local survivalHours = args[3]

    local record = Server.data.players[userName] or {
        overallKills = 0,
        deaths = 0,
        longestLifetime = 0
    }

    record.deaths = (record.deaths or 0) + 1
    Server.updatePlayerStat(userName, "deaths", record.deaths)

    record.overallKills = (record.overallKills or 0) + kills
    Server.updatePlayerStat(userName, "overallKills", record.overallKills)

    Server.updatePlayerStat(userName, "kills", 0)

    if (record.longestLifetime or 0) < survivalHours then
        record.longestLifetime = survivalHours
        Server.updatePlayerStat(userName, "lifetime", survivalHours)
    end

    Server.registerFactionKills(player, kills, Server.data, record)
    record.killsRegisteredInFaction = 0

    Server.data.players[userName] = record
    Server.saveData()

    Server.broadcastScoreboard()
end

function Server.Commands.IgnorePlayers(player, args)
    if string.lower(player:getAccessLevel()) == "admin" then
        Server.data.ignoredPlayersList = args or {}
        if not args then
            Server.Logger.info("IgnorePlayers", {"ADMIN", player:getUsername(), "Empty ignore list"})
        else
            for k, _ in pairs(args) do
                Server.Logger.info("IgnorePlayers", {"ADMIN", player:getUsername(), "Ignored", k})
            end
        end
        Server.saveData()
        Server.broadcastScoreboard()
        Server.broadcastAdminData(player)
    else
        Server.Logger.error("IgnorePlayers", {"No permission", player:getUsername()})
    end
end

function Server.Commands.BroadcastAdmin(player, _args)
    if string.lower(player:getAccessLevel()) == "admin" then
        Server.broadcastAdminData(player)
    end
end

function Server.Commands.FactionSeasonReset(player, _args)
    if string.lower(player:getAccessLevel()) == "admin" then
        Server.data.factions = {}
        for _, record in pairs(Server.data.players) do
            record.killsRegisteredInFaction = record.kills or 0
        end
        Server.saveData()
        Server.broadcastFaction()
        Server.broadcastAdminData(player)
        Server.Logger.info("FactionSeasonReset", {player:getUsername()})
    else
        Server.Logger.error("FactionSeasonReset", {"No permission", player:getUsername()})
    end
end

function Server.Commands.FactionSeasonNew(player, _args)
    if string.lower(player:getAccessLevel()) == "admin" then
        local data = Server.data
        local oldFactions = data.factions or {}
        local seasons = data.factionSeasons or {}

        local newSeason = {
            number = #seasons + 1,
            endAt = getTimestamp(),
            endBy = player:getUsername(),
            factions = oldFactions
        }
        table.insert(seasons, newSeason)

        data.factionSeasons = seasons
        data.factions = {}

        for _, record in pairs(data.players) do
            record.killsRegisteredInFaction = record.kills or 0
        end

        Server.saveData()
        Server.broadcastFaction()
        Server.broadcastAdminData(player)

        Server.Logger.info("FactionSeasonNew", {player:getUsername(), "Ended season #", tostring(newSeason.number)})

        for fName, fData in pairs(oldFactions) do
            local tag = fData.tag or "TAGLESS"
            Server.Logger.info("FactionSeasonNew", {tag, fName, "Kills=" .. tostring(fData.kills or 0)})
            if fData.killsDetailed then
                for pName, killCount in pairs(fData.killsDetailed) do
                    Server.Logger.info("FactionSeasonNew", {fName, pName, "Kills=" .. killCount})
                end
            end
        end
    else
        Server.Logger.error("FactionSeasonNew", {"No permission", player:getUsername()})
    end
end
