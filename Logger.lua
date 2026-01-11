--[[----------------------------------------------------------------------------
    Logger.lua

    Logging utility for the Auto Export plugin.
------------------------------------------------------------------------------]]

local LrLogger = import 'LrLogger'
local LrDate = import 'LrDate'
local LrFileUtils = import 'LrFileUtils'
local LrPathUtils = import 'LrPathUtils'

local Config = require 'AutoExportConfig'

local Logger = {}

-- Create the logger instance
local myLogger = LrLogger('AutoExport')

-- Configure logger output
if Config.ENABLE_LOGGING then
    myLogger:enable('logfile')  -- Write to log file
    -- myLogger:enable('print')  -- Uncomment to also print to console
else
    myLogger:disable()
end

--------------------------------------------------------------------------------
-- Internal helper to format timestamp
--------------------------------------------------------------------------------
local function getTimestamp()
    local now = LrDate.currentTime()
    return LrDate.timeToUserFormat(now, "%Y-%m-%d %H:%M:%S")
end

--------------------------------------------------------------------------------
-- Log levels
--------------------------------------------------------------------------------

function Logger.trace(message, ...)
    if Config.ENABLE_LOGGING then
        local formatted = string.format("[%s] [TRACE] %s", getTimestamp(),
            string.format(message, ...))
        myLogger:trace(formatted)
    end
end

function Logger.debug(message, ...)
    if Config.ENABLE_LOGGING then
        local formatted = string.format("[%s] [DEBUG] %s", getTimestamp(),
            string.format(message, ...))
        myLogger:debug(formatted)
    end
end

function Logger.info(message, ...)
    if Config.ENABLE_LOGGING then
        local formatted = string.format("[%s] [INFO] %s", getTimestamp(),
            string.format(message, ...))
        myLogger:info(formatted)
    end
end

function Logger.warn(message, ...)
    if Config.ENABLE_LOGGING then
        local formatted = string.format("[%s] [WARN] %s", getTimestamp(),
            string.format(message, ...))
        myLogger:warn(formatted)
    end
end

function Logger.error(message, ...)
    if Config.ENABLE_LOGGING then
        local formatted = string.format("[%s] [ERROR] %s", getTimestamp(),
            string.format(message, ...))
        myLogger:error(formatted)
    end
end

--------------------------------------------------------------------------------
-- Convenience method for logging export results
--------------------------------------------------------------------------------

function Logger.logExport(photo, success, destination, errorMessage)
    local photoPath = photo:getRawMetadata('path') or 'Unknown'
    local photoName = LrPathUtils.leafName(photoPath)

    if success then
        Logger.info("Exported: %s -> %s", photoName, destination)
    else
        Logger.error("Export failed: %s - %s", photoName, errorMessage or 'Unknown error')
    end
end

--------------------------------------------------------------------------------
-- Log plugin lifecycle events
--------------------------------------------------------------------------------

function Logger.logStartup()
    Logger.info("========================================")
    Logger.info("Auto Export Plugin Started")
    Logger.info("Poll interval: %d seconds", Config.POLL_INTERVAL)
    Logger.info("========================================")
end

function Logger.logShutdown()
    Logger.info("========================================")
    Logger.info("Auto Export Plugin Stopped")
    Logger.info("========================================")
end

function Logger.logMonitoringStarted()
    Logger.info("Monitoring started - checking every %d seconds", Config.POLL_INTERVAL)
end

function Logger.logMonitoringStopped()
    Logger.info("Monitoring stopped")
end

function Logger.logPollCycle(photosFound, photosExported)
    Logger.debug("Poll cycle complete: %d photos found, %d exported",
        photosFound or 0, photosExported or 0)
end

return Logger