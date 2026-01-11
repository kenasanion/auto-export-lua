--[[----------------------------------------------------------------------------
    ShowLog.lua

    Menu item script to show the export log.
    Available via File > Plug-in Extras > Show Export Log
------------------------------------------------------------------------------]]

local LrTasks = import 'LrTasks'
local LrDialogs = import 'LrDialogs'
local LrFileUtils = import 'LrFileUtils'
local LrPathUtils = import 'LrPathUtils'
local LrShell = import 'LrShell'

local Config = require 'AutoExportConfig'
local Logger = require 'Logger'

LrTasks.startAsyncTask(function()
    -- Get the log file path
    local logPath = Config.LOG_FILE_PATH

    if not logPath then
        -- Use default Lightroom log location
        local documentsPath = LrPathUtils.getStandardFilePath('documents')
        logPath = LrPathUtils.child(documentsPath, 'AutoExport.log')
    end

    -- Check if log file exists
    if not LrFileUtils.exists(logPath) then
        LrDialogs.message(
            "Auto Export Log",
            "No log file found.\n\nLogging may be disabled in the configuration, or no events have been logged yet.\n\nExpected location:\n" .. logPath,
            "info"
        )
        return
    end

    -- Get file info
    local fileSize = LrFileUtils.fileAttributes(logPath).fileSize or 0
    local fileSizeKB = math.floor(fileSize / 1024)

    -- Ask user what they want to do
    local action = LrDialogs.presentModalDialog({
        title = "Auto Export Log",
        message = string.format(
            "Log file found:\n%s\n\nSize: %d KB",
            logPath,
            fileSizeKB
        ),
        actionVerb = "Open in Editor",
        cancelVerb = "Show in Finder",
        otherVerb = "Cancel",
    })

    if action == "ok" then
        -- Open in default text editor
        LrShell.openFilesInApp({ logPath }, LrShell.defaultApp)

    elseif action == "cancel" then
        -- Show in Finder/Explorer
        LrShell.revealInShell(logPath)

    elseif action == "other" then
        -- User cancelled
        return
    end
end)
