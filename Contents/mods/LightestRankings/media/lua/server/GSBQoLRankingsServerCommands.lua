-- ============================================================
--  GSBQoLRankingsServerCommands.lua
--  Command handlers for BaseInfo, DeathKillsCount, etc.
-- ============================================================

local Server = GSBQoL.Rankings.Server

-- Our commands table
-- The mod calls them by name: GSBQoL.Rankings.Server.Commands[commandName]
Server.Commands = Server.Commands or {}

function Server.Commands.BaseInfo(player, args)
    -- args: { userName, zombieKills, hoursSurvived }
    local userName = args[1]
    local kills = args[2]
    local lifetime = args[3]

    local data = Server.data
    local dataPlayer = data.players[userName] or {
        overallKills = 0,
        deaths = 0,
        longestLifetime = 0,
        killsRegisteredInFaction = 0
    }

    -- Current kills
    Server.UpdatePlayerStat(userName, "kills", kills)
    -- Current survival hours
    Server.UpdatePlayerStat(userName, "lifetime", lifetime)

    -- Also update faction
    Server.registerKillsInFaction(player, kills, data, dataPlayer)

    data.players[userName] = dataPlayer
    Server.SaveModData()
end

function Server.Commands.DeathKillsCount(player, args)
    -- args: { userName, zombieKills, lifetime }
    local userName = args[1]
    local zombieKills = args[2]
    local lifetime = args[3]

    local data = Server.data
    local dataPlayer = data.players[userName] or {
        overallKills = 0,
        deaths = 0,
        longestLifetime = 0
    }

    local newDeaths = (dataPlayer.deaths or 0) + 1
    Server.UpdatePlayerStat(userName, "deaths", newDeaths)

    local newOverall = (dataPlayer.overallKills or 0) + zombieKills
    Server.UpdatePlayerStat(userName, "overallKills", newOverall)

    -- kills reset to 0 on death
    Server.UpdatePlayerStat(userName, "kills", 0)

    -- track lifetime if it's the longest
    if (dataPlayer.longestLifetime or 0) < lifetime then
        dataPlayer.longestLifetime = lifetime
        Server.UpdatePlayerStat(userName, "lifetime", lifetime)
    end

    Server.registerKillsInFaction(player, zombieKills, data, dataPlayer)
    dataPlayer.killsRegisteredInFaction = 0

    data.players[userName] = dataPlayer
    Server.SaveModData()

    -- broadcast scoreboard changes
    Server.BroadcastBase()
end

function Server.Commands.IgnorePlayers(player, args)
    if string.lower(player:getAccessLevel()) == "admin" then
        local data = Server.data
        data.ignoredPlayersList = args or {}
        if not args then
            Server.Logger.info("IgnorePlayers", { "ADMIN", player:getUsername(), "Empty list" })
        else
            for k, _ in pairs(args) do
                Server.Logger.info("IgnorePlayers", { "ADMIN", player:getUsername(), "Player ignored", k })
            end
        end
        Server.SaveModData()
        Server.BroadcastBase()
        Server.BroadcastAdmin(player)
    else
        Server.Logger.error("IgnorePlayers", { "NO PERMISSION", player:getUsername() })
    end
end

function Server.Commands.BroadcastAdmin(player, _args)
    if string.lower(player:getAccessLevel()) == "admin" then
        Server.BroadcastAdmin(player)
    end
end

function Server.Commands.FactionSeasonReset(player, _args)
    if string.lower(player:getAccessLevel()) == "admin" then
        local data = Server.data
        data.factions = {}

        -- reset killsRegisteredInFaction
        for _, pData in pairs(data.players) do
            pData.killsRegisteredInFaction = pData.kills or 0
        end

        Server.SaveModData()
        Server.BroadcastFaction()
        Server.BroadcastAdmin(player)
        Server.Logger.info("FactionSeasonReset", { player:getUsername() })
    else
        Server.Logger.error("FactionSeasonReset", { "NO PERMISSION", player:getUsername() })
    end
end

function Server.Commands.FactionSeasonNew(player, _args)
    if string.lower(player:getAccessLevel()) == "admin" then
        local data = Server.data
        local factionSeasons = data.factionSeasons or {}

        local season = {}
        season["number"] = #factionSeasons + 1
        season["endAt"] = getTimestamp()
        season["endBy"] = player:getUsername()
        season["factions"] = data["factions"]

        table.insert(factionSeasons, season)
        data["factionSeasons"] = factionSeasons
        data["factions"] = {}

        for _, pData in pairs(data.players) do
            pData.killsRegisteredInFaction = pData.kills or 0
        end

        Server.SaveModData()
        Server.BroadcastFaction()
        Server.BroadcastAdmin(player)

        Server.Logger.info("FactionSeasonNew",
                { player:getUsername(), "Faction season end", "number", tostring(season.number) }
        )

        if season["factions"] then
            for fName, fData in pairs(season["factions"]) do
                local tag = fData.tag or "TAGLESS"
                Server.Logger.info("FactionSeasonNew", { tag, fName, tostring(fData.kills) })
                if fData["killsDetailed"] then
                    for pName, kills in pairs(fData["killsDetailed"]) do
                        Server.Logger.info("FactionSeasonNew",
                                { "Faction kills detailed", fName, pName, tostring(kills) }
                        )
                    end
                end
            end
        end
    else
        Server.Logger.error("FactionSeasonNew", { "NO PERMISSION", player:getUsername() })
    end
end
