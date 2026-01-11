--[[----------------------------------------------------------------------------
    AutoExportConfig.lua

    Central configuration for the Auto Export plugin.
    Modify these values to customize behavior.
------------------------------------------------------------------------------]]

local LrPathUtils = import 'LrPathUtils'

local Config = {}

--------------------------------------------------------------------------------
-- POLLING SETTINGS
--------------------------------------------------------------------------------

-- How often to check for new photos (in seconds)
-- Minimum recommended: 30 seconds to avoid performance issues
Config.POLL_INTERVAL = 5

-- Whether monitoring starts automatically when Lightroom launches
Config.AUTO_START_MONITORING = false

--------------------------------------------------------------------------------
-- EXPORT SETTINGS
--------------------------------------------------------------------------------

-- Default export destination folder
-- Use nil to prompt user or set via plugin settings
Config.DEFAULT_EXPORT_PATH = nil

-- Export format: "JPEG", "TIFF", "PSD", "DNG", "ORIGINAL"
Config.EXPORT_FORMAT = "JPEG"

-- JPEG quality (1-100)
Config.JPEG_QUALITY = 85

-- Image sizing
Config.SIZE_RESOLUTION = 300          -- DPI
Config.SIZE_MAX_WIDTH = 4096          -- pixels (nil for no limit)
Config.SIZE_MAX_HEIGHT = 4096         -- pixels (nil for no limit)
Config.SIZE_RESIZE_TO_FIT = "longEdge" -- "longEdge", "shortEdge", "width", "height", "megapixels", "dimensions"
Config.SIZE_DO_NOT_ENLARGE = true

-- Color space: "sRGB", "AdobeRGB", "ProPhotoRGB"
Config.COLOR_SPACE = "sRGB"

-- Metadata options
Config.INCLUDE_METADATA = true
Config.REMOVE_LOCATION_INFO = false

-- Sharpening
Config.SHARPEN_FOR = "screen"          -- "screen", "matte", "glossy"
Config.SHARPEN_AMOUNT = "standard"     -- "low", "standard", "high"

--------------------------------------------------------------------------------
-- SEARCH CRITERIA (which photos to auto-export)
--------------------------------------------------------------------------------

-- Available criteria types:
-- "rating"      - Star rating (1-5)
-- "pick"        - Flag status (1=flagged, 0=unflagged, -1=rejected)
-- "labelColor"  - Color label (1=red, 2=yellow, 3=green, 4=blue, 5=purple)
-- "labelText"   - Label text string
-- "keyword"     - Keyword text
-- "collection"  - Collection name
-- "folder"      - Folder path
-- "fileFormat"  - "DNG", "RAW", "JPG", "TIFF", "PSD"

-- Limit export to a specific folder (set to nil to export from all folders)
-- Example: "/Users/yourname/Pictures/Lightroom/2024" or "C:\\Pictures\\Lightroom\\2024"
Config.SOURCE_FOLDER_PATH = nil

-- Default search: Export ALL photos (no criteria)
-- Set to empty to export all photos, or add specific criteria to filter
Config.SEARCH_CRITERIA = {
    -- No criteria = export all photos after applying development settings
    -- Uncomment below to add filters:
    -- {
    --     criteria = "rating",
    --     operation = ">=",
    --     value = 3,  -- 3+ stars
    -- },
    -- {
    --     criteria = "pick",
    --     operation = "==",
    --     value = 1,  -- flagged
    -- },
    -- {
    --     criteria = "keyword",
    --     operation = "any",
    --     value = "export",
    -- },
}

-- Combine multiple criteria with "intersect" (AND) or "union" (OR)
Config.SEARCH_COMBINE = "intersect"

--------------------------------------------------------------------------------
-- FILE NAMING
--------------------------------------------------------------------------------

-- Naming template tokens:
-- {{filename}}     - Original filename without extension
-- {{date}}         - Export date (YYYYMMDD)
-- {{time}}         - Export time (HHMMSS)
-- {{sequence}}     - Sequence number
-- {{rating}}       - Star rating
-- {{extension}}    - File extension

Config.FILENAME_TEMPLATE = "{{filename}}"

-- What to do if file exists: "rename", "overwrite", "skip"
Config.COLLISION_HANDLING = "rename"

--------------------------------------------------------------------------------
-- TRACKING (to avoid re-exporting)
--------------------------------------------------------------------------------

-- Custom metadata field ID used to track export status
Config.TRACKING_FIELD = "autoExportTimestamp"

-- Track exports by:
-- "metadata"   - Use custom metadata field on each photo (requires field registration)
-- "file"       - Use external JSON file (recommended)
-- "both"       - Use both methods
Config.TRACKING_METHOD = "file"

--------------------------------------------------------------------------------
-- LOGGING
--------------------------------------------------------------------------------

-- Enable detailed logging
Config.ENABLE_LOGGING = true

-- Log file location (nil = default Documents folder)
Config.LOG_FILE_PATH = nil

-- Maximum log file size in MB before rotation
Config.MAX_LOG_SIZE_MB = 10

return Config