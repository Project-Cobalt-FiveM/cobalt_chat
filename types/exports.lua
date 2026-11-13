---@meta

---@class ChatLegacyMessage
---@field args? any[] `{ author, text }`, or `{ text }` for a message from System
---@field color? integer[]
---@field multiline? boolean
---@field template? string

---@class CobaltChatExports
local CobaltChatExports = {}

---**Server.** Broadcasts a System message on a channel from `config.Channels`. `ac` reaches staff only; the rest reach everyone.
---@param text string
---@param channel? string defaults to `ooc`
function CobaltChatExports:System(text, channel) end

---**Server.** Sends a stock-chat message, the same as `TriggerClientEvent('chat:addMessage', target, message)`.
---@param target integer server id, or -1 for everyone
---@param message string|ChatLegacyMessage
function CobaltChatExports:addMessage(target, message) end

exports.cobalt_chat = CobaltChatExports
