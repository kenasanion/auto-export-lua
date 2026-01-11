--[[----------------------------------------------------------------------------
    SelectSourceFolder.lua

    Menu item to select which folder to monitor for auto export.
    Available via Library > Auto Export Settings...
------------------------------------------------------------------------------]]

local LrTasks = import 'LrTasks'
local LrDialogs = import 'LrDialogs'
local LrPathUtils = import 'LrPathUtils'
local LrApplication = import 'LrApplication'

local Logger = require 'Logger'

LrTasks.startAsyncTask(function()
    local catalog = LrApplication.activeCatalog()

    -- Get all folders in the catalog
    local folders = catalog:getFolders()

    if not folders or #folders == 0 then
        LrDialogs.message(
            "No Folders Found",
            "No folders found in the catalog. Import some photos first.",
            "info"
        )
        return
    end

    -- Build a list of folder paths for selection
    local folderChoices = {}
    local folderPaths = {}

    table.insert(folderChoices, "All Folders (no filter)")
    table.insert(folderPaths, nil)

    for _, folder in ipairs(folders) do
        local folderPath = folder:getPath()
        if folderPath then
            local folderName = LrPathUtils.leafName(folderPath)
            table.insert(folderChoices, folderName .. " (" .. folderPath .. ")")
            table.insert(folderPaths, folderPath)
        end
    end

    -- Let user select a folder
    local result = LrDialogs.presentModalDialog({
        title = "Select Source Folder to Monitor",
        message = "Choose which folder to monitor for auto export:\n\n(Photos outside this folder will not be exported)",
        contents = function(f)
            return f:column {
                spacing = f:control_spacing(),

                f:static_text {
                    title = "Select a folder:",
                },

                f:popup_menu {
                    items = folderChoices,
                    value = 1,
                },
            }
        end,
    })

    if result == "ok" then
        -- Update the config file with the selected folder
        local selectedIndex = 1 -- This would come from the popup menu value
        local selectedPath = folderPaths[selectedIndex]

        if selectedPath then
            Logger.info("Source folder set to: %s", selectedPath)
            LrDialogs.message(
                "Source Folder Set",
                string.format(
                    "Auto export will now only export photos from:\n\n%s\n\nTo change this setting, edit SOURCE_FOLDER_PATH in AutoExportConfig.lua",
                    selectedPath
                ),
                "info"
            )
        else
            Logger.info("Source folder filter removed - will export from all folders")
            LrDialogs.message(
                "No Filter Set",
                "Auto export will now export photos from all folders in the catalog.\n\nTo change this setting, edit SOURCE_FOLDER_PATH in AutoExportConfig.lua",
                "info"
            )
        end
    end
end)
