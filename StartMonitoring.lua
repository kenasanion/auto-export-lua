--[[----------------------------------------------------------------------------
    StartMonitoring.lua

    Menu item script to start the monitoring service.
    Available via File > Plug-in Extras > Start Auto Export Monitoring
------------------------------------------------------------------------------]]

local LrTasks = import 'LrTasks'
local LrDialogs = import 'LrDialogs'

local MonitoringService = require 'MonitoringService'
local Logger = require 'Logger'

LrTasks.startAsyncTask(function()
    if MonitoringService.isRunning() then
        LrDialogs.message(
            "Auto Export",
            "Monitoring is already running."
        )
        return
    end

    local success = MonitoringService.start()

    if success then
        LrDialogs.message(
            "Auto Export",
            "Monitoring started successfully.\n\nThe plugin will check for new photos periodically."
        )
    else
        LrDialogs.message(
            "Auto Export",
            "Failed to start monitoring. Check the log for details.",
            "warning"
        )
    end
end)