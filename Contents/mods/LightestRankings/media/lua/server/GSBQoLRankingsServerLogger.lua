-- ===================================================================
--  GSBQoLRankingsServerLogger.lua
--  Logging functionality (unchanged except for naming improvements).
-- ===================================================================
local Logger = GSBQoL.Rankings.Server.Logger

function Logger.convertMessagesToBracketText(messages)
    local function bracketify(base, text)
        return base == "" and ("[" .. text .. "]") or (base .. " [" .. text .. "]")
    end

    local result = ""
    for _, msg in ipairs(messages) do
        result = bracketify(result, msg)
    end
    return result
end

function Logger.write(level, moduleName, messageArray)
    local combined = {}
    table.insert(combined, level)
    table.insert(combined, moduleName)
    if messageArray then
        for _, m in ipairs(messageArray) do
            table.insert(combined, m)
        end
    end
    local text = Logger.convertMessagesToBracketText(combined)
    writeLog(GSBQoL.Rankings.Shared.MODULE_NAME, text)
end

function Logger.info(moduleName, messageArray)
    Logger.write("INFO", moduleName, messageArray)
end

function Logger.error(moduleName, messageArray)
    Logger.write("ERROR", moduleName, messageArray)
end
