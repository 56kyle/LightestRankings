-- ============================================================
--  GSBQoLRankingsServerFaction.lua
--  Logic responsible for ranking out of a Faction
-- ============================================================

local Server = GSBQoL.Rankings.Server

function Server.registerKillsInFaction(player, zombieKills, data, dataPlayer)
    if not zombieKills then return end

    local killsInSession = zombieKills - (dataPlayer["killsRegisteredInFaction"] or 0)
    if killsInSession <= 0 then return end

    local userName = player:getUsername()
    local factions = data["factions"]
    if not factions then
        factions = {}
        data["factions"] = factions
    end

    local playerFaction = Faction.getPlayerFaction(player)
    if playerFaction then
        local name = playerFaction:getName()
        local factionData = factions[name]
        if not factionData then
            factionData = {
                name = name,
                kills = 0,
                killsDetailed = {}
            }
        end

        factionData["kills"] = factionData["kills"] + killsInSession
        local colorInfo = playerFaction:getTagColor()
        factionData["tag"] = playerFaction:getTag()
        factionData["color"] = {
            r = colorInfo:getR(),
            g = colorInfo:getG(),
            b = colorInfo:getB()
        }

        local kd = factionData["killsDetailed"]
        kd[userName] = (kd[userName] or 0) + killsInSession
        factionData["killsDetailed"] = kd
        factions[name] = factionData
    end

    dataPlayer["killsRegisteredInFaction"] = zombieKills
end
