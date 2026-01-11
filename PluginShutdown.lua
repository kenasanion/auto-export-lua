--[[----------------------------------------------------------------------------
    PluginShutdown.lua

    Called when the plugin is shut down by Lightroom (on exit or disable).
------------------------------------------------------------------------------]]

-- Safe cleanup using pcall to avoid errors if Lightroom is already shutting down
pcall(function()
    local MonitoringService = require 'MonitoringService'
    local ExportTracker = require 'ExportTracker'

    MonitoringService.forceStop()
    ExportTracker.flush()
end)
