-- ===================================================================
--  GSBQoLRankingsServerConfig.lua
--  Configuration, initial mod data setup, base references.
-- ===================================================================
if isClient() then return end

local Server = GSBQoL.Rankings.Server

Server.Config = {
    scoreboardSize = SandboxVars.GSBQoLRanking.ScoreboardSize or 50,
    daysBeforeArchive = SandboxVars.GSBQoLRanking.DaysBeforeArchive or 30
}

function Server.saveData()
    if Server.data then
        ModData.add(GSBQoL.Rankings.Shared.MODDATA, Server.data)
    end
end

function Server.getWorldHours()
    return getGameTime():getWorldAgeHours()
end

function Server.OnInitGlobalModData(isNewGame)
    if not ModData.exists(GSBQoL.Rankings.Shared.MODDATA) then
        ModData.create(GSBQoL.Rankings.Shared.MODDATA)
    end

    local data = ModData.get(GSBQoL.Rankings.Shared.MODDATA)

    data.players = data.players or {}
    data.archivedPlayers = data.archivedPlayers or {}
    data.factions = data.factions or {}
    data.ignoredPlayersList = data.ignoredPlayersList or {}
    data.factionSeasons = data.factionSeasons or {}

    data.topLists = data.topLists or {
        kills = {},
        deaths = {},
        overallKills = {},
        lifetime = {}
    }

    for name, record in pairs(data.players) do
        if not record.lastSeen then
            record.lastSeen = Server.getWorldHours()
        end
    end

    Server.data = data

    Server.rebuildAllScoreboards()

    Server.Logger.info("OnInitGlobalModData", {"Loaded or created GSBQoLRankings data."})
end

Events.OnInitGlobalModData.Add(Server.OnInitGlobalModData)
