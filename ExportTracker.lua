--[[----------------------------------------------------------------------------
    ExportTracker.lua

    Tracks which photos have been exported to avoid duplicates.
    Supports tracking via custom metadata or external file.
------------------------------------------------------------------------------]]

local LrApplication = import 'LrApplication'
local LrDate = import 'LrDate'
local LrFileUtils = import 'LrFileUtils'
local LrPathUtils = import 'LrPathUtils'
local LrTasks = import 'LrTasks'

local Config = require 'AutoExportConfig'
local Logger = require 'Logger'

local ExportTracker = {}

-- In-memory cache of exported photo IDs (for faster lookups)
local exportedCache = {}

-- Path to external tracking file
local trackingFilePath = nil

--------------------------------------------------------------------------------
-- Initialize the tracker
--------------------------------------------------------------------------------

function ExportTracker.init()
    Logger.debug("Initializing ExportTracker")

    -- Set up tracking file path if needed
    if Config.TRACKING_METHOD == "file" or Config.TRACKING_METHOD == "both" then
        local catalog = LrApplication.activeCatalog()
        local catalogPath = catalog:getPath()
        local catalogDir = LrPathUtils.parent(catalogPath)
        trackingFilePath = LrPathUtils.child(catalogDir, "AutoExport_tracking.json")

        -- Load existing tracking data
        ExportTracker.loadTrackingFile()
    end

    Logger.debug("ExportTracker initialized with method: %s", Config.TRACKING_METHOD)
end

--------------------------------------------------------------------------------
-- Load tracking data from external file
--------------------------------------------------------------------------------

function ExportTracker.loadTrackingFile()
    if not trackingFilePath then return end

    if LrFileUtils.exists(trackingFilePath) then
        local file = io.open(trackingFilePath, "r")
        if file then
            local content = file:read("*all")
            file:close()

            -- Simple JSON parsing for our format
            -- Format: {"photoId1": timestamp1, "photoId2": timestamp2, ...}
            for id, timestamp in string.gmatch(content, '"([^"]+)"%s*:%s*(%d+)') do
                exportedCache[id] = tonumber(timestamp)
            end

            Logger.debug("Loaded %d entries from tracking file", ExportTracker.getCacheCount())
        end
    end
end

--------------------------------------------------------------------------------
-- Save tracking data to external file
--------------------------------------------------------------------------------

function ExportTracker.saveTrackingFile()
    if not trackingFilePath then return end

    local file = io.open(trackingFilePath, "w")
    if file then
        file:write("{\n")

        local first = true
        for id, timestamp in pairs(exportedCache) do
            if not first then
                file:write(",\n")
            end
            file:write(string.format('  "%s": %d', id, timestamp))
            first = false
        end

        file:write("\n}\n")
        file:close()

        Logger.debug("Saved tracking file with %d entries", ExportTracker.getCacheCount())
    else
        Logger.error("Failed to save tracking file: %s", trackingFilePath)
    end
end

--------------------------------------------------------------------------------
-- Get count of cached entries
--------------------------------------------------------------------------------

function ExportTracker.getCacheCount()
    local count = 0
    for _ in pairs(exportedCache) do
        count = count + 1
    end
    return count
end

--------------------------------------------------------------------------------
-- Check if a photo has been exported
--------------------------------------------------------------------------------

function ExportTracker.hasBeenExported(photo)
    local photoId = tostring(photo.localIdentifier)

    -- Check metadata-based tracking
    if Config.TRACKING_METHOD == "metadata" or Config.TRACKING_METHOD == "both" then
        local exportTimestamp = photo:getPropertyForPlugin(
            _PLUGIN,
            Config.TRACKING_FIELD
        )

        if exportTimestamp and exportTimestamp ~= "" then
            -- Check if photo was modified after export
            local editTime = photo:getRawMetadata('lastEditTime')
            if editTime and tonumber(exportTimestamp) >= editTime then
                return true  -- Already exported and not modified since
            else
                return false  -- Modified since last export, needs re-export
            end
        end
    end

    -- Check file-based tracking
    if Config.TRACKING_METHOD == "file" or Config.TRACKING_METHOD == "both" then
        local cachedTimestamp = exportedCache[photoId]
        if cachedTimestamp then
            local editTime = photo:getRawMetadata('lastEditTime')
            if editTime and cachedTimestamp >= editTime then
                return true
            end
        end
    end

    return false
end

--------------------------------------------------------------------------------
-- Mark a photo as exported
--------------------------------------------------------------------------------

function ExportTracker.markAsExported(photo, catalog)
    local photoId = tostring(photo.localIdentifier)
    local timestamp = LrDate.currentTime()

    -- Update metadata-based tracking
    if Config.TRACKING_METHOD == "metadata" or Config.TRACKING_METHOD == "both" then
        -- This must be called within catalog:withWriteAccessDo()
        photo:setPropertyForPlugin(
            _PLUGIN,
            Config.TRACKING_FIELD,
            tostring(math.floor(timestamp))
        )
    end

    -- Update file-based tracking
    if Config.TRACKING_METHOD == "file" or Config.TRACKING_METHOD == "both" then
        exportedCache[photoId] = math.floor(timestamp)
        -- Save periodically (not on every photo to avoid I/O overhead)
    end

    Logger.debug("Marked photo %s as exported at %d", photoId, timestamp)
end

--------------------------------------------------------------------------------
-- Clear export status for a photo (allows re-export)
--------------------------------------------------------------------------------

function ExportTracker.clearExportStatus(photo, catalog)
    local photoId = tostring(photo.localIdentifier)

    if Config.TRACKING_METHOD == "metadata" or Config.TRACKING_METHOD == "both" then
        photo:setPropertyForPlugin(
            _PLUGIN,
            Config.TRACKING_FIELD,
            nil
        )
    end

    if Config.TRACKING_METHOD == "file" or Config.TRACKING_METHOD == "both" then
        exportedCache[photoId] = nil
    end

    Logger.debug("Cleared export status for photo %s", photoId)
end

--------------------------------------------------------------------------------
-- Save all pending changes (call periodically or on shutdown)
--------------------------------------------------------------------------------

function ExportTracker.flush()
    if Config.TRACKING_METHOD == "file" or Config.TRACKING_METHOD == "both" then
        ExportTracker.saveTrackingFile()
    end
end

--------------------------------------------------------------------------------
-- Get statistics
--------------------------------------------------------------------------------

function ExportTracker.getStats()
    return {
        cachedCount = ExportTracker.getCacheCount(),
        trackingMethod = Config.TRACKING_METHOD,
        trackingFilePath = trackingFilePath,
    }
end

return ExportTracker