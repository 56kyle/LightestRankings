if isClient() then
    return
end

GSBQoL = GSBQoL or {}
GSBQoL.Rankings = GSBQoL.Rankings or {}
GSBQoL.Rankings.Server = GSBQoL.Rankings.Server or {}
GSBQoL.Rankings.Server.Logger = GSBQoL.Rankings.Server.Logger or {}
GSBQoL.Rankings.Server.Commands = GSBQoL.Rankings.Server.Commands or {}

function GSBQoL.Rankings.Server.Logger.convertToBrackets(list)
    function concat(text, newText)
        local nt = "[" .. newText .. "]"
        if text == "" then
            return nt;
        else
            return text .. " " .. nt;
        end
    end

    local result = "";
    for i, text in ipairs(list) do
        result = concat(result, text);
    end
    return result
end

function GSBQoL.Rankings.Server.Logger.write(logType, module, messages)
    local logEntries = {}
    table.insert(logEntries, logType);
    table.insert(logEntries, module);
    if messages then
        for i, m in ipairs(messages) do
            table.insert(logEntries, m);
        end
    end

    writeLog(GSBQoL.Rankings.Shared.MODULE_NAME, GSBQoL.Rankings.Server.Logger.convertToBrackets(logEntries));
end

function GSBQoL.Rankings.Server.Logger.info(module, messages)
    GSBQoL.Rankings.Server.Logger.write("INFO", module, messages);
end

function GSBQoL.Rankings.Server.Logger.error(module, messages)
    GSBQoL.Rankings.Server.Logger.write("ERROR", module, messages);
end

function GSBQoL.Rankings.Server.Commands.BroadcastAdmin(player, args)
    if string.lower(player:getAccessLevel()) == "admin" then
        GSBQoL.Rankings.Server.BroadcastAdmin(player);
    end
end

function GSBQoL.Rankings.Server.registerKillsInFaction(player, zombieKills, data, dataPlayer)
    local killsInSession = zombieKills - (dataPlayer["killsRegisteredInFaction"] or 0);

    if killsInSession > 0 then
        local userName = player:getUsername();

        local factions = data["factions"];
        if factions == nil then
            factions = {}
        end

        local playerFaction = Faction.getPlayerFaction(player);
        if playerFaction ~= nil then
            local name = playerFaction:getName();
            local factionData = factions[name]

            if factionData == nil then
                factionData = {}
                factionData["name"] = name;
                factionData["kills"] = 0;
                factionData["killsDetailed"] = {}
            end
            local colorInfo = playerFaction:getTagColor();
            factionData["tag"] = playerFaction:getTag();
            factionData["color"] = { r = colorInfo:getR(), g = colorInfo:getG(), b = colorInfo:getB() };
            factionData["kills"] = factionData["kills"] + killsInSession;

            local killsDetailed = factionData["killsDetailed"];
            killsDetailed[userName] = (killsDetailed[userName] or 0) + killsInSession;
            table.sort(killsDetailed, function(a, b)
                return a > b;
            end)
            factionData["killsDetailed"] = killsDetailed;
            factions[name] = factionData;

        end

        dataPlayer["killsRegisteredInFaction"] = zombieKills;
        data["factions"] = factions;
    end
end

function GSBQoL.Rankings.Server.Commands.BaseInfo(player, args)
    local userName = args[1];
    local zombieKills = args[2];
    local lifetime = args[3];

    local data = GSBQoL.Rankings.Server.data;
    local dataPlayer = data.players[userName];

    if dataPlayer == nil then
        dataPlayer = {};
        dataPlayer["overallKills"] = 0;
        dataPlayer["deaths"] = 0;
        dataPlayer["longestLifetime"] = 0;
        dataPlayer["killsRegisteredInFaction"] = 0;
    end
    dataPlayer["kills"] = zombieKills;
    dataPlayer["lifetime"] = lifetime;

    GSBQoL.Rankings.Server.registerKillsInFaction(player, zombieKills, data, dataPlayer);

    data.players[userName] = dataPlayer;
    GSBQoL.Rankings.Server.data = data;
end

function GSBQoL.Rankings.Server.Commands.DeathKillsCount(player, args)
    local userName = args[1];
    local zombieKills = args[2];
    local lifetime = args[3];

    local data = GSBQoL.Rankings.Server.data;
    local dataPlayer = data.players[userName];
    dataPlayer["kills"] = 0;
    dataPlayer["deaths"] = (dataPlayer["deaths"] or 0) + 1;
    dataPlayer["overallKills"] = (dataPlayer["overallKills"] or 0) + zombieKills;
    dataPlayer["longestLifetime"] = math.max(dataPlayer["longestLifetime"] or 0, lifetime);

    GSBQoL.Rankings.Server.registerKillsInFaction(player, zombieKills, data, dataPlayer);
    dataPlayer["killsRegisteredInFaction"] = 0;

    data.players[userName] = dataPlayer;
    GSBQoL.Rankings.Server.data = data;

    GSBQoL.Rankings.Server.BroadcastBase();
end

function GSBQoL.Rankings.Server.ResetPlayersFactionCount()
    local data = GSBQoL.Rankings.Server.data;
    for key, dataPlayer in pairs(data.players) do
        dataPlayer["killsRegisteredInFaction"] = dataPlayer["kills"] or 0;
    end
end

function GSBQoL.Rankings.Server.Commands.FactionSeasonReset(player, args)
    if string.lower(player:getAccessLevel()) == "admin" then
        GSBQoL.Rankings.Server.data = ModData.get(GSBQoL.Rankings.Shared.MODDATA);
        GSBQoL.Rankings.Server.data["factions"] = nil

        GSBQoL.Rankings.Server.ResetPlayersFactionCount()

        GSBQoL.Rankings.Server.Save();
        GSBQoL.Rankings.Server.BroadcastFaction();
        GSBQoL.Rankings.Server.BroadcastAdmin(player);

        GSBQoL.Rankings.Server.Logger.info("FactionSeasonReset", { player:getUsername() });
    else
        GSBQoL.Rankings.Server.Logger.error("FactionSeasonReset", { "NO PERMISSION", player:getUsername() });
    end
end

function GSBQoL.Rankings.Server.Commands.FactionSeasonNew(player, args)
    if string.lower(player:getAccessLevel()) == "admin" then
        GSBQoL.Rankings.Server.data = ModData.get(GSBQoL.Rankings.Shared.MODDATA);
        local factionSeasons = GSBQoL.Rankings.Server.data["factionSeasons"] or {};

        local season = {};
        season["number"] = #factionSeasons + 1;
        season["endAt"] = getTimestamp();
        season["endBy"] = player:getUsername();
        season["factions"] = GSBQoL.Rankings.Server.data["factions"];

        table.insert(factionSeasons, season);
        GSBQoL.Rankings.Server.data["factionSeasons"] = factionSeasons;
        GSBQoL.Rankings.Server.data["factions"] = {}

        GSBQoL.Rankings.Server.ResetPlayersFactionCount()

        GSBQoL.Rankings.Server.Save();
        GSBQoL.Rankings.Server.BroadcastFaction();
        GSBQoL.Rankings.Server.BroadcastAdmin(player);

        GSBQoL.Rankings.Server.Logger.info("FactionSeasonNew", { player:getUsername(), "Faction season end", "number", tostring(season.number) });
        for i, faction in ipairs(season["factions"]) do
            local tag = faction.tag;
            if not tag then
                tag = "TAGLESS"
            end
            GSBQoL.Rankings.Server.Logger.info("FactionSeasonNew", { tag, faction.name, tostring(faction.kills) });
            for k, kills in pairs(faction["killsDetailed"]) do
                GSBQoL.Rankings.Server.Logger.info("FactionSeasonNew", { "Faction kills detailed", faction.name, k, tostring(kills) });
            end
        end

        dataPlayer["killsRegisteredInFaction"] = zombieKills;
    else
        GSBQoL.Rankings.Server.Logger.error("FactionSeasonNew", { "NO PERMISSION", player:getUsername() });
    end
end

function GSBQoL.Rankings.Server.Commands.IgnorePlayers(player, args)
    if string.lower(player:getAccessLevel()) == "admin" then
        GSBQoL.Rankings.Server.data["ignoredPlayersList"] = args;
        if args == nil then
            GSBQoL.Rankings.Server.Logger.info("IgnorePlayers", { "ADMIN", player:getUsername(), "Empty list" });
        else
            for k, v in pairs(args) do
                GSBQoL.Rankings.Server.Logger.info("IgnorePlayers", { "ADMIN", player:getUsername(), "Player ignored", k });
            end
        end

        GSBQoL.Rankings.Server.Save();
        GSBQoL.Rankings.Server.BroadcastBase();
        GSBQoL.Rankings.Server.BroadcastAdmin(player);
    else
        GSBQoL.Rankings.Server.Logger.error("IgnorePlayers", { "NO PERMISSION", player:getUsername() });
    end
end

function GSBQoL.Rankings.Server.OnClientCommand(module, command, player, args)
    if module == GSBQoL.Rankings.Shared.MODULE_NAME then
        local userName = "";
        if args and args[1] then
            userName = args[1]
        end
        if string.lower(player:getAccessLevel()) == "admin" or userName == player:getUsername() then
            GSBQoL.Rankings.Server.Commands[command](player, args);
        else
            GSBQoL.Rankings.Server.Logger.error(command, { "userName not match", player:getUsername(), "username: " .. userName });
        end
    end
end

-- TODO change to send info do ALL logged admins
function GSBQoL.Rankings.Server.BroadcastAdmin(player)
    sendServerCommand(player, GSBQoL.Rankings.Shared.MODULE_NAME, "DataToAdmin", GSBQoL.Rankings.Server.data);
    GSBQoL.Rankings.Server.Logger.info("BroadcastAdmin", { player:getUsername() });
end

function GSBQoL.Rankings.Server.BroadcastBase()
    sendServerCommand(GSBQoL.Rankings.Shared.MODULE_NAME, "DataFromServer", GSBQoL.Rankings.filterPlayers());
end

function GSBQoL.Rankings.Server.BroadcastFaction()
    sendServerCommand(GSBQoL.Rankings.Shared.MODULE_NAME, "DataFactionFromServer", GSBQoL.Rankings.Server.data["factions"]);
end

function GSBQoL.Rankings.filterPlayers()
    local allPlayers = GSBQoL.Rankings.Server.data["players"];
    if GSBQoL.Rankings.Server.data["ignoredPlayersList"] == nil then
        return allPlayers;
    else
        local filteredList = {};
        local ignoredList = GSBQoL.Rankings.Server.data["ignoredPlayersList"];
        for v, k in pairs(allPlayers) do
            local ignored = false;
            for iv, ik in pairs(ignoredList) do
                if tostring(iv) == tostring(v) then
                    ignored = true;
                    break
                end
            end
            if not ignored then
                filteredList[v] = k;
            end
        end
        return filteredList;
    end
end

function GSBQoL.Rankings.Server.EveryHoursUpdate()
    GSBQoL.Rankings.Server.Save();
end

function GSBQoL.Rankings.Server.Save()
    ModData.add(GSBQoL.Rankings.Shared.MODDATA, GSBQoL.Rankings.Server.data)
end

function GSBQoL.Rankings.Server.EveryTenMinutesUpdate()
    GSBQoL.Rankings.Server.BroadcastBase();
    GSBQoL.Rankings.Server.BroadcastFaction();
end

function GSBQoL.Rankings.Server.OnInitGlobalModData(isNewGame)
    if not ModData.exists(GSBQoL.Rankings.Shared.MODDATA) then
        ModData.create(GSBQoL.Rankings.Shared.MODDATA)
    end

    local data = ModData.get(GSBQoL.Rankings.Shared.MODDATA)
    data["converted"] = data.converted or false;
    if not data.converted then
        local players = {}
        if getGameTime():getModData().gsbQoLRankingDataKillsLiveCount then
            for k, kills in pairs(getGameTime():getModData().gsbQoLRankingDataKillsLiveCount) do
                local player = players[k] or {}
                player["kills"] = kills;
                player["overallKills"] = 0;
                player["deaths"] = 0;
                player["lifetime"] = 0;
                player["longestLifetime"] = 0;
                player["killsRegisteredInFaction"] = kills;
                players[k] = player;
            end
        end
        if getGameTime():getModData().gsbQoLRankingDataDeathsCount then
            for k, deaths in pairs(getGameTime():getModData().gsbQoLRankingDataDeathsCount) do
                local player = players[k] or {}
                player["deaths"] = deaths;
                players[k] = player;
            end
        end
        if getGameTime():getModData().gsbQoLRankingDataOverallKillsCountBase then
            for k, overallKills in pairs(getGameTime():getModData().gsbQoLRankingDataOverallKillsCountBase) do
                local player = players[k] or {}
                player["overallKills"] = overallKills;
                players[k] = player;
            end
        end
        data["converted"] = true;
        data["players"] = players;
    end
    GSBQoL.Rankings.Server.data = data;
end

Events.OnInitGlobalModData.Add(GSBQoL.Rankings.Server.OnInitGlobalModData)

Events.OnClientCommand.Add(GSBQoL.Rankings.Server.OnClientCommand);
Events.EveryTenMinutes.Add(GSBQoL.Rankings.Server.EveryTenMinutesUpdate);
Events.EveryHours.Add(GSBQoL.Rankings.Server.EveryHoursUpdate);
