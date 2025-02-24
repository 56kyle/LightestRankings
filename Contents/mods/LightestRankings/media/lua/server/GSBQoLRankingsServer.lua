-- ============================================================
--  GSBQoLRankingsServer.lua (Main Entry)
--  Loads all partial modules, sets up final events.
-- ============================================================
if isClient() then return end

-- Create our global references if missing
GSBQoL = GSBQoL or {}
GSBQoL.Rankings = GSBQoL.Rankings or {}
GSBQoL.Rankings.Server = GSBQoL.Rankings.Server or {}
GSBQoL.Rankings.Server.Logger = GSBQoL.Rankings.Server.Logger or {}
GSBQoL.Rankings.Server.Commands = GSBQoL.Rankings.Server.Commands or {}

-- 1) Require each partial module in the order we need them.
require "GSBQoLRankingsServer_Config"
require "GSBQoLRankingsServer_Logger"
require "GSBQoLRankingsServer_TopList"
require "GSBQoLRankingsServer_Archiving"
require "GSBQoLRankingsServer_Broadcast"
require "GSBQoLRankingsServer_Commands"
require "GSBQoLRankingsServer_Factions"
require "GSBQoLRankingsServer_Ignore"

-- 2) Initialize global mod data event
Events.OnInitGlobalModData.Add(GSBQoL.Rankings.Server.OnInitGlobalModData)

-- 3) Client Command
function GSBQoL.Rankings.Server.OnClientCommand(module, command, player, args)
    if module == GSBQoL.Rankings.Shared.MODULE_NAME then
        local userName = ""
        if args and args[1] then
            userName = args[1]
        end

        -- Either admin or the actual player
        if (string.lower(player:getAccessLevel()) == "admin") or (userName == player:getUsername()) then
            local cmdFunc = GSBQoL.Rankings.Server.Commands[command]
            if cmdFunc then
                cmdFunc(player, args)
            else
                GSBQoL.Rankings.Server.Logger.error(command, { "Unknown command", "userName: " .. userName })
            end
        else
            GSBQoL.Rankings.Server.Logger.error(command,
                    { "userName mismatch or no permission", player:getUsername(), "username: " .. userName }
            )
        end
    end
end
Events.OnClientCommand.Add(GSBQoL.Rankings.Server.OnClientCommand)

-- 4) Auto-save every hour (same as original)
function GSBQoL.Rankings.Server.EveryHoursUpdate()
    GSBQoL.Rankings.Server.SaveModData()
end
Events.EveryHours.Add(GSBQoL.Rankings.Server.EveryHoursUpdate)

-- 5) 10-minute update to broadcast scoreboard & faction
function GSBQoL.Rankings.Server.EveryTenMinutesUpdate()
    GSBQoL.Rankings.Server.BroadcastBase()
    GSBQoL.Rankings.Server.BroadcastFaction()
end
Events.EveryTenMinutes.Add(GSBQoL.Rankings.Server.EveryTenMinutesUpdate)

-- 6) Done! The partial modules define everything else we need.

-- This is the old "IgnorePlayers" command
function GSBQoL.Rankings.Server.Commands.IgnorePlayers(player, args)
    if string.lower(player:getAccessLevel()) == "admin" then
        local data = getRankingData()
        data.ignoredPlayersList = args or {}
        if not args then
            GSBQoL.Rankings.Server.Logger.info("IgnorePlayers", { "ADMIN", player:getUsername(), "Empty list" })
        else
            for k, _ in pairs(args) do
                GSBQoL.Rankings.Server.Logger.info("IgnorePlayers", { "ADMIN", player:getUsername(), "Player ignored", k })
            end
        end
        saveModData()
        GSBQoL.Rankings.Server.BroadcastBase()
        GSBQoL.Rankings.Server.BroadcastAdmin(player)
    else
        GSBQoL.Rankings.Server.Logger.error("IgnorePlayers", { "NO PERMISSION", player:getUsername() })
    end
end

-- Admin broadcast of entire data for the admin window
function GSBQoL.Rankings.Server.BroadcastAdmin(player)
    local data = getRankingData()
    sendServerCommand(player, GSBQoL.Rankings.Shared.MODULE_NAME, "DataToAdmin", data)
    GSBQoL.Rankings.Server.Logger.info("BroadcastAdmin", { player:getUsername() })
end

function GSBQoL.Rankings.Server.Commands.BroadcastAdmin(player, _args)
    if string.lower(player:getAccessLevel()) == "admin" then
        GSBQoL.Rankings.Server.BroadcastAdmin(player)
    end
end

-- FactionSeasonReset command
function GSBQoL.Rankings.Server.Commands.FactionSeasonReset(player, _args)
    if string.lower(player:getAccessLevel()) == "admin" then
        local data = getRankingData()
        data.factions = nil
        data.factions = {}

        -- Reset killsRegisteredInFaction for all players
        for _, pData in pairs(data.players) do
            pData.killsRegisteredInFaction = pData.kills or 0
        end

        saveModData()
        GSBQoL.Rankings.Server.BroadcastFaction()
        GSBQoL.Rankings.Server.BroadcastAdmin(player)
        GSBQoL.Rankings.Server.Logger.info("FactionSeasonReset", { player:getUsername() })
    else
        GSBQoL.Rankings.Server.Logger.error("FactionSeasonReset", { "NO PERMISSION", player:getUsername() })
    end
end

-- FactionSeasonNew command
function GSBQoL.Rankings.Server.Commands.FactionSeasonNew(player, _args)
    if string.lower(player:getAccessLevel()) == "admin" then
        local data = getRankingData()
        local factionSeasons = data["factionSeasons"] or {}

        local season = {}
        season["number"] = #factionSeasons + 1
        season["endAt"] = getTimestamp()
        season["endBy"] = player:getUsername()
        season["factions"] = data["factions"]

        table.insert(factionSeasons, season)
        data["factionSeasons"] = factionSeasons
        data["factions"] = {}

        -- reset killsRegisteredInFaction for all players
        for _, pData in pairs(data.players) do
            pData.killsRegisteredInFaction = pData.kills or 0
        end

        saveModData()
        GSBQoL.Rankings.Server.BroadcastFaction()
        GSBQoL.Rankings.Server.BroadcastAdmin(player)

        GSBQoL.Rankings.Server.Logger.info("FactionSeasonNew",
                { player:getUsername(), "Faction season end", "number", tostring(season.number) }
        )

        if season["factions"] then
            for factionName, fData in pairs(season["factions"]) do
                local tag = fData.tag or "TAGLESS"
                GSBQoL.Rankings.Server.Logger.info("FactionSeasonNew", { tag, factionName, tostring(fData.kills) })
                if fData["killsDetailed"] then
                    for pName, kills in pairs(fData["killsDetailed"]) do
                        GSBQoL.Rankings.Server.Logger.info("FactionSeasonNew",
                                { "Faction kills detailed", factionName, pName, tostring(kills) }
                        )
                    end
                end
            end
        end
    else
        GSBQoL.Rankings.Server.Logger.error("FactionSeasonNew", { "NO PERMISSION", player:getUsername() })
    end
end

-- ==========================
-- SERVER COMMAND HANDLING
-- ==========================
function GSBQoL.Rankings.Server.OnClientCommand(module, command, player, args)
    if module == GSBQoL.Rankings.Shared.MODULE_NAME then
        local userName = ""
        if args and args[1] then
            userName = args[1]
        end

        if (string.lower(player:getAccessLevel()) == "admin") or (userName == player:getUsername()) then
            local cmdFunc = GSBQoL.Rankings.Server.Commands[command]
            if cmdFunc then
                cmdFunc(player, args)
            else
                GSBQoL.Rankings.Server.Logger.error(command, { "Unknown command", "userName: " .. userName })
            end
        else
            GSBQoL.Rankings.Server.Logger.error(command,
                    { "userName mismatch or no permission", player:getUsername(), "username: " .. userName }
            )
        end
    end
end

Events.OnClientCommand.Add(GSBQoL.Rankings.Server.OnClientCommand)

-- ==========================
-- PERIODIC SAVE
-- (unchanged: we can still save every hour)
-- ==========================

function GSBQoL.Rankings.Server.EveryHoursUpdate()
    saveModData()
end

Events.EveryHours.Add(GSBQoL.Rankings.Server.EveryHoursUpdate)

-- ============================================================
-- END OF GSBQoLRankingsServer.lua (Forked Version)
-- ============================================================
