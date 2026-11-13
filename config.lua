---@alias ChatScope 'proximity' | 'global' | 'admin'
---@alias ChatStyle 'speech' | 'action' | 'narrative' | 'system'

---@class ChatChannelConfig
---@field scope ChatScope
---@field label string
---@field order integer
---@field style? ChatStyle

---@class ChatDelegation
---@field resource string
---@field event string

---@class ChatConfig
---@field OpenKey string
---@field ModeKey string
---@field IdleFadeMs integer
---@field MaxMessages integer
---@field MaxMessageLength integer
---@field ProximityRadius number
---@field Channels table<string, ChatChannelConfig>
---@field AdminRank string
---@field Delegations table<string, ChatDelegation>
---@field RateLimit { messages: integer, windowMs: integer }
---@field WordFilter string[]

---@type ChatConfig
return {
    -- Chat box
    OpenKey = 'T', -- default key that opens chat; players can rebind it in GTA settings
    ModeKey = 'PAGEDOWN', -- default key that cycles the chat between active, shown and inactive; players can rebind it in GTA settings
    IdleFadeMs = 3000, -- milliseconds before the closed chat fades out
    MaxMessages = 1000, -- messages kept in the history before the oldest are dropped
    MaxMessageLength = 240, -- characters; longer messages are cut
    ProximityRadius = 30.0, -- meters a proximity channel carries

    -- Channels, by the command that sends to them (/say, /ooc, ...)
    -- scope: 'proximity' (players within ProximityRadius), 'global' (everyone) or 'admin' (AdminRank and up)
    -- label: tab name; order: tab position; style: 'speech' (default), 'action', 'narrative' or 'system'
    Channels = {
        say = { scope = 'proximity', label = 'Local', order = 1 },
        ooc = { scope = 'global', label = 'OOC', order = 2 },
        me = { scope = 'proximity', label = 'Me', order = 3, style = 'action' },
        ['do'] = { scope = 'proximity', label = 'Do', order = 4, style = 'narrative' },
        ac = { scope = 'admin', label = 'Staff', order = 5 },
    },

    -- Rank that sees and uses the admin channel: 'staff', 'admin' or 'owner'
    AdminRank = 'staff',

    -- Commands handed to another resource's server event with (source, message) instead of a channel
    Delegations = {
        ['911'] = { resource = 'cobalt_police', event = 'cobalt_police:emergencyCall' }, -- police dispatch
        ['311'] = { resource = 'cobalt_police', event = 'cobalt_police:medicalCall' }, -- EMS dispatch
    },

    -- Anti-spam: at most this many messages per player in each window
    RateLimit = {
        messages = 4, -- messages allowed per window
        windowMs = 5000, -- milliseconds
    },

    -- Words replaced by asterisks, matched without regard to case
    WordFilter = {},
}
