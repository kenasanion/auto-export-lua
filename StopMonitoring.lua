--[[----------------------------------------------------------------------------
    StopMonitoring.lua

    Menu item script to stop the monitoring service.
    Available via File > Plug-in Extras > Stop Auto Export Monitoring
------------------------------------------------------------------------------]]

local LrDialogs = import 'LrDialogs'

local MonitoringService = require 'MonitoringService'
local Logger = require 'Logger'

if not MonitoringService.isRunning() then
    LrDialogs.message(
        "Auto Export",
        "Monitoring is not currently running."
    )
else
    local success = MonitoringService.stop()

    if success then
        LrDialogs.message(
            "Auto Export",
            "Monitoring has been stopped."
        )
    else
        LrDialogs.message(
            "Auto Export",
            "Failed to stop monitoring.",
            "warning"
        )
    end
end