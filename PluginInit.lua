--[[----------------------------------------------------------------------------
    PluginInit.lua

    Called when the plugin is first loaded by Lightroom.
------------------------------------------------------------------------------]]

local LrTasks = import 'LrTasks'

local Config = require 'AutoExportConfig'
local Logger = require 'Logger'
local MonitoringService = require 'MonitoringService'
local ExportTracker = require 'ExportTracker'

-- Log startup
Logger.logStartup()

-- Initialize the export tracker
ExportTracker.init()

-- Auto-start monitoring if configured
if Config.AUTO_START_MONITORING then
    LrTasks.startAsyncTask(function()
        -- Small delay to let Lightroom finish starting up
        LrTasks.sleep(5)

        Logger.info("Auto-starting monitoring service...")
        MonitoringService.start()
    end)
end

Logger.info("Plugin initialization complete")