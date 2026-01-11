--[[----------------------------------------------------------------------------
    PhotoFinder.lua

    Searches the catalog for photos matching the configured criteria.
------------------------------------------------------------------------------]]

local LrApplication = import 'LrApplication'
local LrTasks = import 'LrTasks'

local Config = require 'AutoExportConfig'
local Logger = require 'Logger'
local ExportTracker = require 'ExportTracker'

local PhotoFinder = {}

--------------------------------------------------------------------------------
-- Build search descriptor from config
--------------------------------------------------------------------------------

local function buildSearchDescriptor()
    local searchDesc = {}

    if #Config.SEARCH_CRITERIA == 1 then
        -- Single criterion - simple format
        searchDesc = Config.SEARCH_CRITERIA[1]
    elseif #Config.SEARCH_CRITERIA > 1 then
        -- Multiple criteria - combine them
        searchDesc = {
            combine = Config.SEARCH_COMBINE,
            criteria = Config.SEARCH_CRITERIA,
        }
    else
        -- No criteria configured - return empty
        Logger.warn("No search criteria configured!")
        return nil
    end

    return searchDesc
end

--------------------------------------------------------------------------------
-- Find all photos matching the configured criteria
--------------------------------------------------------------------------------

function PhotoFinder.findMatchingPhotos()
    local catalog = LrApplication.activeCatalog()
    local searchDesc = buildSearchDescriptor()

    local photos

    if not searchDesc then
        -- No criteria means export all photos in the catalog
        Logger.debug("No search criteria - returning all photos in catalog")
        photos = catalog:getAllPhotos()
    else
        Logger.debug("Searching for photos with criteria...")
        photos = catalog:findPhotos {
            searchDesc = searchDesc,
        }
    end

    -- Filter by source folder if configured
    if Config.SOURCE_FOLDER_PATH then
        Logger.debug("Filtering photos by folder: %s", Config.SOURCE_FOLDER_PATH)
        local filteredPhotos = {}

        for _, photo in ipairs(photos) do
            local photoPath = photo:getRawMetadata('path')
            if photoPath and string.find(photoPath, Config.SOURCE_FOLDER_PATH, 1, true) then
                table.insert(filteredPhotos, photo)
            end
        end

        Logger.info("Filtered %d photos from folder (out of %d total)",
            #filteredPhotos, #photos)
        photos = filteredPhotos
    end

    Logger.debug("Found %d photos matching criteria", #photos)

    return photos
end

--------------------------------------------------------------------------------
-- Find photos that need to be exported (matching criteria + not yet exported)
--------------------------------------------------------------------------------

function PhotoFinder.findPhotosToExport()
    local allMatchingPhotos = PhotoFinder.findMatchingPhotos()
    local photosToExport = {}

    for _, photo in ipairs(allMatchingPhotos) do
        if not ExportTracker.hasBeenExported(photo) then
            table.insert(photosToExport, photo)
        end
    end

    Logger.info("Found %d photos to export (out of %d matching)",
        #photosToExport, #allMatchingPhotos)

    return photosToExport
end

--------------------------------------------------------------------------------
-- Find photos by specific criteria (for manual filtering)
--------------------------------------------------------------------------------

function PhotoFinder.findByRating(minRating)
    local catalog = LrApplication.activeCatalog()

    return catalog:findPhotos {
        searchDesc = {
            criteria = "rating",
            operation = ">=",
            value = minRating,
        },
    }
end

function PhotoFinder.findByFlag(flagStatus)
    -- flagStatus: 1 = flagged, 0 = unflagged, -1 = rejected
    local catalog = LrApplication.activeCatalog()

    return catalog:findPhotos {
        searchDesc = {
            criteria = "pick",
            operation = "==",
            value = flagStatus,
        },
    }
end

function PhotoFinder.findByLabel(labelColor)
    -- labelColor: 1=red, 2=yellow, 3=green, 4=blue, 5=purple
    local catalog = LrApplication.activeCatalog()

    return catalog:findPhotos {
        searchDesc = {
            criteria = "labelColor",
            operation = "==",
            value = labelColor,
        },
    }
end

function PhotoFinder.findByKeyword(keyword)
    local catalog = LrApplication.activeCatalog()

    return catalog:findPhotos {
        searchDesc = {
            criteria = "keywords",
            operation = "any",
            value = keyword,
        },
    }
end

function PhotoFinder.findByCollection(collectionName)
    local catalog = LrApplication.activeCatalog()

    return catalog:findPhotos {
        searchDesc = {
            criteria = "collection",
            operation = "==",
            value = collectionName,
        },
    }
end

--------------------------------------------------------------------------------
-- Find photos modified since a given timestamp
--------------------------------------------------------------------------------

function PhotoFinder.findModifiedSince(timestamp)
    local catalog = LrApplication.activeCatalog()
    local allPhotos = catalog:getAllPhotos()
    local modifiedPhotos = {}

    for _, photo in ipairs(allPhotos) do
        local editTime = photo:getRawMetadata('lastEditTime')
        if editTime and editTime > timestamp then
            table.insert(modifiedPhotos, photo)
        end
    end

    return modifiedPhotos
end

--------------------------------------------------------------------------------
-- Get photo info for logging/display
--------------------------------------------------------------------------------

function PhotoFinder.getPhotoInfo(photo)
    return {
        id = photo.localIdentifier,
        path = photo:getRawMetadata('path'),
        filename = photo:getFormattedMetadata('fileName'),
        rating = photo:getRawMetadata('rating'),
        flag = photo:getRawMetadata('pickStatus'),
        label = photo:getRawMetadata('colorNameForLabel'),
        editTime = photo:getRawMetadata('lastEditTime'),
        captureTime = photo:getRawMetadata('dateTimeOriginal'),
    }
end

return PhotoFinder