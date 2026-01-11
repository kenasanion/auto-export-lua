--[[----------------------------------------------------------------------------
    ShowSettings.lua

    Menu item script to show and configure plugin settings.
    Available via Library > Auto Export Settings...
------------------------------------------------------------------------------]]

local LrTasks = import 'LrTasks'
local LrDialogs = import 'LrDialogs'
local LrView = import 'LrView'
local LrBinding = import 'LrBinding'
local LrFunctionContext = import 'LrFunctionContext'

local Config = require 'AutoExportConfig'
local AutoExporter = require 'AutoExporter'
local MonitoringService = require 'MonitoringService'
local Logger = require 'Logger'

LrFunctionContext.callWithContext("ShowSettings", function(context)
    local props = LrBinding.makePropertyTable(context)

    -- Initialize property values from current configuration
    props.destination = AutoExporter.getDestination() or "Not set"
    props.pollInterval = Config.POLL_INTERVAL
    props.autoStart = Config.AUTO_START_MONITORING
    props.exportFormat = Config.EXPORT_FORMAT
    props.jpegQuality = Config.JPEG_QUALITY
    props.searchCriteria = ""

    -- Build search criteria description
    if #Config.SEARCH_CRITERIA > 0 then
        local criteriaDesc = {}
        for _, criterion in ipairs(Config.SEARCH_CRITERIA) do
            if criterion.criteria == "rating" then
                table.insert(criteriaDesc,
                    string.format("Rating %s %d stars", criterion.operation, criterion.value))
            elseif criterion.criteria == "pick" then
                local pickDesc = criterion.value == 1 and "Flagged" or
                                 criterion.value == -1 and "Rejected" or "Unflagged"
                table.insert(criteriaDesc, pickDesc)
            elseif criterion.criteria == "keyword" then
                table.insert(criteriaDesc,
                    string.format("Keyword: %s", criterion.value))
            end
        end
        props.searchCriteria = table.concat(criteriaDesc, " AND ")
    end

    -- Get monitoring status
    local stats = MonitoringService.getStats()
    props.monitoringStatus = stats.isRunning and "Running" or "Stopped"
    props.totalExported = stats.totalExported or 0
    props.pollCount = stats.pollCount or 0

    local f = LrView.osFactory()

    local contents = f:column {
        spacing = f:control_spacing(),
        fill_horizontal = 1,

        -- Header
        f:static_text {
            title = "Auto Export Plugin Settings",
            font = "<system/bold>",
        },

        f:separator { fill_horizontal = 1 },

        -- Monitoring Status
        f:group_box {
            title = "Monitoring Status",
            fill_horizontal = 1,

            f:column {
                spacing = f:label_spacing(),

                f:row {
                    f:static_text {
                        title = "Status:",
                        width = LrView.share("label_width"),
                    },
                    f:static_text {
                        title = LrView.bind("monitoringStatus"),
                        font = "<system/bold>",
                    },
                },

                f:row {
                    f:static_text {
                        title = "Poll Count:",
                        width = LrView.share("label_width"),
                    },
                    f:static_text {
                        title = LrView.bind("pollCount"),
                    },
                },

                f:row {
                    f:static_text {
                        title = "Total Exported:",
                        width = LrView.share("label_width"),
                    },
                    f:static_text {
                        title = LrView.bind("totalExported"),
                    },
                },
            },
        },

        -- Export Destination
        f:group_box {
            title = "Export Destination",
            fill_horizontal = 1,

            f:column {
                spacing = f:label_spacing(),

                f:row {
                    f:static_text {
                        title = "Current:",
                        width = LrView.share("label_width"),
                    },
                    f:static_text {
                        title = LrView.bind("destination"),
                        fill_horizontal = 1,
                        truncation = "middle",
                    },
                },

                f:row {
                    f:push_button {
                        title = "Change Destination...",
                        action = function()
                            if AutoExporter.promptForDestination() then
                                props.destination = AutoExporter.getDestination()
                            end
                        end,
                    },
                },
            },
        },

        -- Source Folder Filter
        f:group_box {
            title = "Source Folder",
            fill_horizontal = 1,

            f:column {
                spacing = f:label_spacing(),

                f:row {
                    f:static_text {
                        title = "Monitor:",
                        width = LrView.share("label_width"),
                    },
                    f:static_text {
                        title = Config.SOURCE_FOLDER_PATH or "All folders (no filter)",
                        fill_horizontal = 1,
                        truncation = "middle",
                    },
                },

                f:static_text {
                    title = "Edit SOURCE_FOLDER_PATH in AutoExportConfig.lua to change",
                    font = "<system/small>",
                },
            },
        },

        -- Search Criteria
        f:group_box {
            title = "Search Criteria",
            fill_horizontal = 1,

            f:column {
                spacing = f:label_spacing(),

                f:row {
                    f:static_text {
                        title = "Current:",
                        width = LrView.share("label_width"),
                    },
                    f:static_text {
                        title = LrView.bind("searchCriteria"),
                        fill_horizontal = 1,
                    },
                },

                f:static_text {
                    title = "Edit AutoExportConfig.lua to change search criteria",
                    font = "<system/small>",
                },
            },
        },

        -- Export Settings
        f:group_box {
            title = "Export Settings",
            fill_horizontal = 1,

            f:column {
                spacing = f:label_spacing(),

                f:row {
                    f:static_text {
                        title = "Format:",
                        width = LrView.share("label_width"),
                    },
                    f:static_text {
                        title = LrView.bind("exportFormat"),
                    },
                },

                f:row {
                    f:static_text {
                        title = "JPEG Quality:",
                        width = LrView.share("label_width"),
                    },
                    f:static_text {
                        title = LrView.bind("jpegQuality"),
                    },
                },

                f:row {
                    f:static_text {
                        title = "Poll Interval:",
                        width = LrView.share("label_width"),
                    },
                    f:static_text {
                        title = string.format("%d seconds", props.pollInterval),
                    },
                },

                f:static_text {
                    title = "Edit AutoExportConfig.lua to change export settings",
                    font = "<system/small>",
                },
            },
        },

        f:separator { fill_horizontal = 1 },

        -- Help text
        f:static_text {
            title = "To start auto-exporting:",
            font = "<system/bold>",
        },

        f:static_text {
            title = "1. Set an export destination above",
        },

        f:static_text {
            title = "2. Use File > Plug-in Extras > Start Auto Export Monitoring",
        },

        f:static_text {
            title = "3. The plugin will check for matching photos every " .. props.pollInterval .. " seconds",
        },
    }

    LrDialogs.presentModalDialog {
        title = "Auto Export Settings",
        contents = contents,
    }
end)
