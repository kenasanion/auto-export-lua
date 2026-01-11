--[[----------------------------------------------------------------------------
    PluginInfoProvider.lua

    Provides custom information for the Plugin Manager display.
------------------------------------------------------------------------------]]

local LrView = import 'LrView'
local LrBinding = import 'LrBinding'
local LrFunctionContext = import 'LrFunctionContext'

local MonitoringService = require 'MonitoringService'
local AutoExporter = require 'AutoExporter'

--------------------------------------------------------------------------------
-- Section for Plugin Manager
--------------------------------------------------------------------------------

return {
    sectionsForTopOfDialog = function(f, propertyTable)
        return {
            {
                title = "Auto Export Status",

                f:row {
                    f:static_text {
                        title = "Monitor Status:",
                        width = LrView.share("label_width"),
                    },
                    f:static_text {
                        title = MonitoringService.isRunning() and "Running" or "Stopped",
                    },
                },

                f:row {
                    f:static_text {
                        title = "Export Destination:",
                        width = LrView.share("label_width"),
                    },
                    f:static_text {
                        title = AutoExporter.getDestination() or "Not set",
                        fill_horizontal = 1,
                        truncation = "middle",
                    },
                },

                f:spacer { height = 10 },

                f:static_text {
                    title = "Use File > Plug-in Extras to start/stop monitoring",
                    font = "<system/small>",
                },

                f:static_text {
                    title = "Use Library > Auto Export Settings to configure",
                    font = "<system/small>",
                },
            },
        }
    end,
}
