-- ===================================================================
--  GSBQoLRankingsServer.lua (Main Entry)
--  Loads modules in order, sets up events, and glues everything.
-- ===================================================================
if isClient() then return end

GSBQoL = GSBQoL or {}
GSBQoL.Rankings = GSBQoL.Rankings or {}
GSBQoL.Rankings.Server = GSBQoL.Rankings.Server or {}
GSBQoL.Rankings.Server.Logger = GSBQoL.Rankings.Server.Logger or {}
GSBQoL.Rankings.Server.Commands = GSBQoL.Rankings.Server.Commands or {}

require "GSBQoLRankingsServerConfig"
require "GSBQoLRankingsServerLogger"
require "GSBQoLRankingsServerTopList"
require "GSBQoLRankingsServerArchive"
require "GSBQoLRankingsServerBroadcast"
require "GSBQoLRankingsServerCommands"
require "GSBQoLRankingsServerFaction"
require "GSBQoLRankingsServerIgnore"

-- Called by PZ for all server commands from clients
function GSBQoL.Rankings.Server.OnClientCommand(module, command, player, args)
    if module == GSBQoL.Rankings.Shared.MODULE_NAME then
        local userName = ""
        if args and args[1] then
            userName = args[1]
        end

        local isAdmin = (string.lower(player:getAccessLevel()) == "admin")
        local isSelf = (userName == player:getUsername())
        if isAdmin or isSelf then
            local cmdFunction = GSBQoL.Rankings.Server.Commands[command]
            if cmdFunction then
                cmdFunction(player, args)
            else
                GSBQoL.Rankings.Server.Logger.error(command, {"Command not found", "userName=" .. userName})
            end
        else
            GSBQoL.Rankings.Server.Logger.error(command, {"userName mismatch or permission denied", player:getUsername(), "arg userName=" .. userName})
        end
    end
end

Events.OnClientCommand.Add(GSBQoL.Rankings.Server.OnClientCommand)

-- Save data every hour
local function onEveryHour()
    GSBQoL.Rankings.Server.saveData()
end
Events.EveryHours.Add(onEveryHour)

-- Broadcast scoreboard/faction every 10 minutes
local function onEveryTenMinutes()
    GSBQoL.Rankings.Server.broadcastScoreboard()
    GSBQoL.Rankings.Server.broadcastFaction()
end
Events.EveryTenMinutes.Add(onEveryTenMinutes)
