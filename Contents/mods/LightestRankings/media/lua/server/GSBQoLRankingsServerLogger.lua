-- ============================================================
--  GSBQoLRankingsServerLogger.lua
--  Logic responsible for handling logging
-- ============================================================

local Logger = GSBQoL.Rankings.Server.Logger

function Logger.convertToBrackets(list)
    local function concat(text, newText)
        local nt = "[" .. newText .. "]"
        if text == "" then
            return nt
        else
            return text .. " " .. nt
        end
    end

    local result = ""
    for _, txt in ipairs(list) do
        result = concat(result, txt)
    end
    return result
end

function Logger.write(logType, module, messages)
    local logEntries = {}
    table.insert(logEntries, logType)
    table.insert(logEntries, module)
    if messages then
        for _, m in ipairs(messages) do
            table.insert(logEntries, m)
        end
    end

    writeLog(GSBQoL.Rankings.Shared.MODULE_NAME, Logger.convertToBrackets(logEntries))
end

function Logger.info(module, messages)
    Logger.write("INFO", module, messages)
end

function Logger.error(module, messages)
    Logger.write("ERROR", module, messages)
end
