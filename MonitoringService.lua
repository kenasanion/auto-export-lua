--[[----------------------------------------------------------------------------
    MonitoringService.lua

    Background service that polls for new photos and triggers exports.
------------------------------------------------------------------------------]]

local LrApplication = import 'LrApplication'
local LrTasks = import 'LrTasks'
local LrFunctionContext = import 'LrFunctionContext'
local LrDialogs = import 'LrDialogs'
local LrDate = import 'LrDate'

local Config = require 'AutoExportConfig'
local Logger = require 'Logger'
local PhotoFinder = require 'PhotoFinder'
local AutoExporter = require 'AutoExporter'
local ExportTracker = require 'ExportTracker'

local MonitoringService = {}

-- Service state
local isRunning = false
local shouldStop = false
local lastPollTime = nil
local totalExported = 0
local pollCount = 0

--------------------------------------------------------------------------------
-- Check if monitoring is currently active
--------------------------------------------------------------------------------

function MonitoringService.isRunning()
    return isRunning
end

--------------------------------------------------------------------------------
-- Get monitoring statistics
--------------------------------------------------------------------------------

function MonitoringService.getStats()
    return {
        isRunning = isRunning,
        lastPollTime = lastPollTime,
        totalExported = totalExported,
        pollCount = pollCount,
        pollInterval = Config.POLL_INTERVAL,
    }
end

--------------------------------------------------------------------------------
-- The main polling loop
--------------------------------------------------------------------------------

local function pollLoop()
    Logger.logMonitoringStarted()

    while not shouldStop do
        pollCount = pollCount + 1
        lastPollTime = LrDate.currentTime()

        Logger.debug("Poll cycle #%d starting...", pollCount)

        -- Find photos that need to be exported
        local photosToExport = PhotoFinder.findPhotosToExport()

        if #photosToExport > 0 then
            Logger.info("Found %d photos to export", #photosToExport)

            -- Check if we have a valid destination
            local destination = AutoExporter.getDestination()
            if destination then
                -- Export the photos
                local results = AutoExporter.exportPhotos(photosToExport, destination)
                totalExported = totalExported + results.exported

                Logger.logPollCycle(#photosToExport, results.exported)
            else
                Logger.warn("No export destination configured - skipping export")
            end
        else
            Logger.debug("No new photos to export")
            Logger.logPollCycle(0, 0)
        end

        -- Wait for next poll interval
        if not shouldStop then
            Logger.debug("Sleeping for %d seconds...", Config.POLL_INTERVAL)
            LrTasks.sleep(Config.POLL_INTERVAL)
        end
    end

    Logger.logMonitoringStopped()
end

--------------------------------------------------------------------------------
-- Start the monitoring service
--------------------------------------------------------------------------------

function MonitoringService.start()
    if isRunning then
        Logger.warn("Monitoring service is already running")
        return false
    end

    -- Initialize tracker
    ExportTracker.init()

    -- Check for valid destination
    local destination = AutoExporter.getDestination()
    if not destination then
        Logger.warn("No export destination configured")

        -- Prompt user for destination
        local result = LrDialogs.confirm(
            "No Export Destination",
            "Would you like to select an export destination folder now?",
            "Select Folder",
            "Cancel"
        )

        if result == "ok" then
            if not AutoExporter.promptForDestination() then
                Logger.error("No destination selected - monitoring not started")
                return false
            end
        else
            Logger.error("Monitoring cancelled - no destination configured")
            return false
        end
    end

    -- Reset state
    shouldStop = false
    isRunning = true
    pollCount = 0
    totalExported = 0

    -- Start the background task
    LrTasks.startAsyncTask(function()
        LrFunctionContext.callWithContext("MonitoringService", function(context)
            -- Set up cleanup handler
            context:addCleanupHandler(function()
                isRunning = false
                shouldStop = true
                ExportTracker.flush()
                Logger.info("Monitoring service cleanup complete")
            end)

            -- Run the poll loop
            pollLoop()
        end)
    end)

    Logger.info("Monitoring service started successfully")
    return true
end

--------------------------------------------------------------------------------
-- Stop the monitoring service
--------------------------------------------------------------------------------

function MonitoringService.stop()
    if not isRunning then
        Logger.warn("Monitoring service is not running")
        return false
    end

    Logger.info("Stopping monitoring service...")
    shouldStop = true

    -- The loop will exit on its own after the current sleep
    -- We don't forcefully stop it to allow cleanup

    return true
end

--------------------------------------------------------------------------------
-- Force stop (for shutdown scenarios)
--------------------------------------------------------------------------------

function MonitoringService.forceStop()
    shouldStop = true
    isRunning = false
    ExportTracker.flush()
end

--------------------------------------------------------------------------------
-- Run a single poll cycle manually
--------------------------------------------------------------------------------

function MonitoringService.pollOnce()
    Logger.info("Running single poll cycle...")

    -- Initialize tracker if not already done
    ExportTracker.init()

    local photosToExport = PhotoFinder.findPhotosToExport()

    if #photosToExport > 0 then
        local destination = AutoExporter.getDestination()
        if destination then
            local results = AutoExporter.exportPhotos(photosToExport, destination)
            return results
        else
            Logger.warn("No export destination configured")
            return { exported = 0, failed = 0, error = "No destination" }
        end
    else
        Logger.info("No new photos to export")
        return { exported = 0, failed = 0 }
    end
end

--------------------------------------------------------------------------------
-- Toggle monitoring on/off
--------------------------------------------------------------------------------

function MonitoringService.toggle()
    if isRunning then
        return MonitoringService.stop()
    else
        return MonitoringService.start()
    end
end

return MonitoringService