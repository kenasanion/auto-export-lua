--[[----------------------------------------------------------------------------
    ExportNow.lua

    Menu item script to manually trigger an export of matching photos.
    Available via File > Plug-in Extras > Export Now (Manual Trigger)
------------------------------------------------------------------------------]]

local LrTasks = import 'LrTasks'
local LrDialogs = import 'LrDialogs'
local LrApplication = import 'LrApplication'
local LrProgressScope = import 'LrProgressScope'

local PhotoFinder = require 'PhotoFinder'
local AutoExporter = require 'AutoExporter'
local Logger = require 'Logger'
local Config = require 'AutoExportConfig'

LrTasks.startAsyncTask(function()
    -- Check if destination is configured
    local destination = AutoExporter.getDestination()

    if not destination then
        local result = LrDialogs.confirm(
            "No Export Destination",
            "No export destination has been configured.\n\nWould you like to select a destination folder now?",
            "Select Folder",
            "Cancel"
        )

        if result == "ok" then
            if not AutoExporter.promptForDestination() then
                Logger.warn("Manual export cancelled - no destination selected")
                return
            end
            destination = AutoExporter.getDestination()
        else
            return
        end
    end

    -- Find photos to export
    Logger.info("Manual export triggered - searching for photos...")

    local photosToExport = PhotoFinder.findPhotosToExport()

    if #photosToExport == 0 then
        -- Check if there are any matching photos at all
        local allMatching = PhotoFinder.findMatchingPhotos()

        if #allMatching == 0 then
            LrDialogs.message(
                "Auto Export",
                "No photos match the current search criteria.\n\nCheck your configuration in AutoExportConfig.lua to verify the search criteria.",
                "info"
            )
        else
            LrDialogs.message(
                "Auto Export",
                string.format(
                    "All %d matching photos have already been exported.\n\nNo new photos to export at this time.",
                    #allMatching
                ),
                "info"
            )
        end
        return
    end

    -- Confirm export
    local confirmResult = LrDialogs.confirm(
        "Export Now",
        string.format(
            "Found %d photos ready to export.\n\nDestination: %s\n\nProceed with export?",
            #photosToExport,
            destination
        ),
        "Export",
        "Cancel"
    )

    if confirmResult ~= "ok" then
        Logger.info("Manual export cancelled by user")
        return
    end

    -- Perform the export
    Logger.info("Starting manual export of %d photos", #photosToExport)

    local results = AutoExporter.exportPhotos(photosToExport, destination)

    -- Show results
    if results.error then
        LrDialogs.message(
            "Export Failed",
            "Export failed: " .. results.error,
            "critical"
        )
    elseif results.failed > 0 then
        LrDialogs.message(
            "Export Completed with Errors",
            string.format(
                "Export completed:\n\n%d photos exported successfully\n%d photos failed\n\nCheck the log for details.",
                results.exported,
                results.failed
            ),
            "warning"
        )
    else
        LrDialogs.message(
            "Export Successful",
            string.format(
                "Successfully exported %d photos to:\n%s",
                results.exported,
                destination
            ),
            "info"
        )
    end

    Logger.info("Manual export complete: %d exported, %d failed",
        results.exported, results.failed)
end)
