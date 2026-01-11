--[[----------------------------------------------------------------------------
    AutoExporter.lua

    Handles the actual export of photos using LrExportSession.
------------------------------------------------------------------------------]]

local LrApplication = import 'LrApplication'
local LrExportSession = import 'LrExportSession'
local LrPathUtils = import 'LrPathUtils'
local LrFileUtils = import 'LrFileUtils'
local LrDate = import 'LrDate'
local LrTasks = import 'LrTasks'
local LrDialogs = import 'LrDialogs'
local LrProgressScope = import 'LrProgressScope'

local Config = require 'AutoExportConfig'
local Logger = require 'Logger'
local ExportTracker = require 'ExportTracker'

local AutoExporter = {}

-- Current export destination (can be set via settings)
local exportDestination = nil

--------------------------------------------------------------------------------
-- Set the export destination folder
--------------------------------------------------------------------------------

function AutoExporter.setDestination(path)
    if path and LrFileUtils.exists(path) then
        exportDestination = path
        Logger.info("Export destination set to: %s", path)
        return true
    else
        Logger.error("Invalid export destination: %s", path or "nil")
        return false
    end
end

--------------------------------------------------------------------------------
-- Get current export destination
--------------------------------------------------------------------------------

function AutoExporter.getDestination()
    return exportDestination or Config.DEFAULT_EXPORT_PATH
end

--------------------------------------------------------------------------------
-- Prompt user to select destination folder
--------------------------------------------------------------------------------

function AutoExporter.promptForDestination()
    local result = LrDialogs.runOpenPanel {
        title = "Select Auto Export Destination Folder",
        canChooseFiles = false,
        canChooseDirectories = true,
        canCreateDirectories = true,
        allowsMultipleSelection = false,
    }

    if result and #result > 0 then
        return AutoExporter.setDestination(result[1])
    end

    return false
end

--------------------------------------------------------------------------------
-- Build export settings table
--------------------------------------------------------------------------------

local function buildExportSettings(destinationPath)
    local settings = {
        -- Destination
        LR_export_destinationType = "specificFolder",
        LR_export_destinationPathPrefix = destinationPath,
        LR_export_useSubfolder = false,

        -- File naming
        LR_renamingTokensOn = false,  -- Use original filename
        LR_tokens = Config.FILENAME_TEMPLATE,
        LR_collisionHandling = Config.COLLISION_HANDLING,

        -- File format
        LR_format = Config.EXPORT_FORMAT,

        -- Color space
        LR_export_colorSpace = Config.COLOR_SPACE,

        -- Metadata
        LR_metadata_keywordOptions = Config.INCLUDE_METADATA and "lightroomHierarchical" or "flat",
        LR_removeLocationMetadata = Config.REMOVE_LOCATION_INFO,
        LR_includeFaceTagsAsKeywords = true,
        LR_includeVideoFiles = true,

        -- Don't add to catalog
        LR_reimportExportedPhoto = false,
    }

    -- Format-specific settings
    if Config.EXPORT_FORMAT == "JPEG" then
        settings.LR_jpeg_quality = Config.JPEG_QUALITY / 100
        settings.LR_jpeg_useLimitSize = false
    elseif Config.EXPORT_FORMAT == "TIFF" then
        settings.LR_tiff_compressionMethod = "compressionMethod_None"
        settings.LR_tiff_bitDepth = 16
    elseif Config.EXPORT_FORMAT == "PSD" then
        settings.LR_psd_bitDepth = 16
    end

    -- Image sizing
    if Config.SIZE_MAX_WIDTH or Config.SIZE_MAX_HEIGHT then
        settings.LR_size_doConstrain = true
        settings.LR_size_doNotEnlarge = Config.SIZE_DO_NOT_ENLARGE
        settings.LR_size_resizeType = Config.SIZE_RESIZE_TO_FIT
        settings.LR_size_maxWidth = Config.SIZE_MAX_WIDTH or 9999
        settings.LR_size_maxHeight = Config.SIZE_MAX_HEIGHT or 9999
        settings.LR_size_resolution = Config.SIZE_RESOLUTION
        settings.LR_size_resolutionUnits = "inch"
    else
        settings.LR_size_doConstrain = false
    end

    -- Output sharpening
    if Config.SHARPEN_FOR then
        settings.LR_outputSharpeningOn = true
        settings.LR_outputSharpeningMedia = Config.SHARPEN_FOR
        settings.LR_outputSharpeningLevel =
            Config.SHARPEN_AMOUNT == "low" and 1 or
            Config.SHARPEN_AMOUNT == "high" and 3 or 2
    else
        settings.LR_outputSharpeningOn = false
    end

    return settings
end

--------------------------------------------------------------------------------
-- Export a single photo
--------------------------------------------------------------------------------

function AutoExporter.exportPhoto(photo, destinationPath)
    local catalog = LrApplication.activeCatalog()
    local photoInfo = {
        path = photo:getRawMetadata('path'),
        filename = photo:getFormattedMetadata('fileName'),
    }

    Logger.debug("Exporting photo: %s", photoInfo.filename)

    -- Build export settings
    local exportSettings = buildExportSettings(destinationPath)

    -- Create export session with single photo
    local exportSession = LrExportSession {
        photosToExport = { photo },
        exportSettings = exportSettings,
    }

    -- Perform the export
    local success = true
    local errorMessage = nil
    local exportedPath = nil

    exportSession:doExportOnCurrentTask()

    -- Check results
    for _, rendition in exportSession:renditions() do
        local ok, pathOrError = rendition:waitForRender()
        if ok then
            exportedPath = pathOrError
            Logger.logExport(photo, true, exportedPath)
        else
            success = false
            errorMessage = pathOrError
            Logger.logExport(photo, false, nil, errorMessage)
        end
    end

    -- Mark as exported if successful
    if success then
        catalog:withWriteAccessDo("Mark photo as exported", function()
            ExportTracker.markAsExported(photo, catalog)
        end)
    end

    return success, exportedPath, errorMessage
end

--------------------------------------------------------------------------------
-- Export multiple photos
--------------------------------------------------------------------------------

function AutoExporter.exportPhotos(photos, destinationPath, progressCallback)
    if not photos or #photos == 0 then
        Logger.info("No photos to export")
        return { exported = 0, failed = 0, results = {} }
    end

    local destination = destinationPath or AutoExporter.getDestination()

    if not destination then
        Logger.error("No export destination configured")
        return { exported = 0, failed = 0, error = "No destination configured" }
    end

    -- Ensure destination exists
    if not LrFileUtils.exists(destination) then
        local created = LrFileUtils.createDirectory(destination)
        if not created then
            Logger.error("Could not create destination folder: %s", destination)
            return { exported = 0, failed = 0, error = "Could not create destination" }
        end
    end

    local catalog = LrApplication.activeCatalog()
    local results = {
        exported = 0,
        failed = 0,
        results = {},
    }

    -- Build export settings
    local exportSettings = buildExportSettings(destination)

    -- Create export session with all photos
    local exportSession = LrExportSession {
        photosToExport = photos,
        exportSettings = exportSettings,
    }

    Logger.info("Starting export of %d photos to %s", #photos, destination)

    -- Create progress scope
    local progressScope = LrProgressScope {
        title = "Auto Export",
        caption = string.format("Exporting %d photos...", #photos),
    }

    -- Perform the export
    exportSession:doExportOnCurrentTask()

    -- Process results
    local photoIndex = 0
    for _, rendition in exportSession:renditions() do
        photoIndex = photoIndex + 1
        local photo = cyclePhotos and photos[photoIndex]

        -- Update progress
        progressScope:setPortionComplete(photoIndex, #photos)
        if progressCallback then
            progressCallback(photoIndex, #photos)
        end

        -- Check if cancelled
        if progressScope:isCanceled() then
            Logger.info("Export cancelled by user")
            break
        end

        -- Wait for render and check result
        local ok, pathOrError = rendition:waitForRender()
        local photoForRendition = rendition.photo

        if ok then
            results.exported = results.exported + 1
            table.insert(results.results, {
                photo = photoForRendition,
                success = true,
                path = pathOrError,
            })
            Logger.logExport(photoForRendition, true, pathOrError)

            -- Mark as exported
            catalog:withWriteAccessDo("Mark photo as exported", function()
                ExportTracker.markAsExported(photoForRendition, catalog)
            end)
        else
            results.failed = results.failed + 1
            table.insert(results.results, {
                photo = photoForRendition,
                success = false,
                error = pathOrError,
            })
            Logger.logExport(photoForRendition, false, nil, pathOrError)
        end
    end

    progressScope:done()

    -- Flush tracking data
    ExportTracker.flush()

    Logger.info("Export complete: %d exported, %d failed",
        results.exported, results.failed)

    return results
end

--------------------------------------------------------------------------------
-- Quick export with default settings
--------------------------------------------------------------------------------

function AutoExporter.quickExport(photos)
    local destination = AutoExporter.getDestination()

    if not destination then
        -- Prompt for destination
        if not AutoExporter.promptForDestination() then
            Logger.warn("Export cancelled - no destination selected")
            return nil
        end
        destination = AutoExporter.getDestination()
    end

    return AutoExporter.exportPhotos(photos, destination)
end

return AutoExporter