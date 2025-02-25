-- ===================================================================
--  GSBQoLRankingsServerFaction.lua
--  Manages faction kill tracking for each player.
-- ===================================================================
if isClient() then return end

local Server = GSBQoL.Rankings.Server

function Server.registerFactionKills(player, killCount, data, record)
    if not killCount then return end

    local currentInFaction = killCount - (record.killsRegisteredInFaction or 0)
    if currentInFaction <= 0 then return end

    local userName = player:getUsername()
    local factionSet = data.factions
    if not factionSet then
        factionSet = {}
        data.factions = factionSet
    end

    local playerFaction = Faction.getPlayerFaction(player)
    if playerFaction then
        local factionName = playerFaction:getName()
        local info = factionSet[factionName]
        if not info then
            info = {
                name = factionName,
                kills = 0,
                killsDetailed = {}
            }
        end

        info.kills = info.kills + currentInFaction
        local colorInfo = playerFaction:getTagColor()
        info.tag = playerFaction:getTag()
        info.color = {
            r = colorInfo:getR(),
            g = colorInfo:getG(),
            b = colorInfo:getB()
        }

        local kd = info.killsDetailed
        kd[userName] = (kd[userName] or 0) + currentInFaction
        info.killsDetailed = kd

        factionSet[factionName] = info
    end

    record.killsRegisteredInFaction = killCount
end
