--[[----------------------------------------------------------------------------
    Auto Export Plugin for Lightroom Classic

    This plugin monitors the catalog for photos matching specific criteria
    and automatically exports them to a designated folder.
------------------------------------------------------------------------------]]

return {
    LrSdkVersion = 6.0,
    LrSdkMinimumVersion = 4.0,

    LrToolkitIdentifier = 'com.theretrogradepress.autoexport',
    LrPluginName = "Auto Export",

    LrPluginInfoUrl = "https://theretrogradepress.com/autoexport",

    -- Plugin lifecycle scripts
    LrInitPlugin = 'PluginInit.lua',
    LrShutdownPlugin = 'PluginShutdown.lua',

    -- Plugin Manager customization
    LrPluginInfoProvider = 'PluginInfoProvider.lua',

    -- Add menu items to File > Plug-in Extras
    LrExportMenuItems = {
        {
            title = "Start Auto Export Monitoring",
            file = "StartMonitoring.lua",
        },
        {
            title = "Stop Auto Export Monitoring",
            file = "StopMonitoring.lua",
        },
        {
            title = "Export Now (Manual Trigger)",
            file = "ExportNow.lua",
        },
        {
            title = "Show Export Log",
            file = "ShowLog.lua",
        },
    },

    -- Library menu items (available in Library module)
    LrLibraryMenuItems = {
        {
            title = "Auto Export Settings...",
            file = "ShowSettings.lua",
        },
    },

    VERSION = { major = 1, minor = 0, revision = 0, build = 1 },
}