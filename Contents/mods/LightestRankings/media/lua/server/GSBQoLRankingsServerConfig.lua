-- ============================================================
--  GSBQoLRankingsServerConfig.lua
--  Basic configuration & data references
-- ============================================================

GSBQoL.Rankings.Server.Config = {
    TOP_SCOREBOARD_SIZE = 50,  -- max scoreboard size per category
    INACTIVE_DAYS = 30         -- days offline before archiving
}

-- We'll store the mod data in GSBQoL.Rankings.Server.data

function GSBQoL.Rankings.Server.SaveModData()
    if not GSBQoL.Rankings.Server.data then return end
    ModData.add(GSBQoL.Rankings.Shared.MODDATA, GSBQoL.Rankings.Server.data)
end

-- Helper to get PZ "world age in hours" for measuring time
function GSBQoL.Rankings.Server.GetGameHours()
    return getGameTime():getWorldAgeHours()
end

-- OnInitGlobalModData
function GSBQoL.Rankings.Server.OnInitGlobalModData(isNewGame)
    if not ModData.exists(GSBQoL.Rankings.Shared.MODDATA) then
        ModData.create(GSBQoL.Rankings.Shared.MODDATA)
    end

    local data = ModData.get(GSBQoL.Rankings.Shared.MODDATA)
    data.players = data.players or {}
    data.factions = data.factions or {}
    data.archivedPlayers = data.archivedPlayers or {}
    data.ignoredPlayersList = data.ignoredPlayersList or {}
    data.factionSeasons = data.factionSeasons or {}

    -- We'll store top-lists in data.topLists
    data.topLists = data.topLists or {
        kills = {},
        deaths = {},
        overallKills = {},
        lifetime = {}
    }

    -- Fix older data that might not have lastSeen
    for playerName, pData in pairs(data.players) do
        if not pData.lastSeen then
            pData.lastSeen = GSBQoL.Rankings.Server.GetGameHours()
        end
    end

    GSBQoL.Rankings.Server.data = data

    -- Rebuild scoreboard once
    GSBQoL.Rankings.Server.RebuildAllScoreboards()

    GSBQoL.Rankings.Server.Logger.info("OnInitGlobalModData", { "GSBQoL Rankings data loaded/created." })
end



