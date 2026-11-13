local config <const> = require 'config'
local state <const> = require 'client.state'

require 'client.nui'

---@type ChatMode[]
local MODE_ORDER <const> = { 'active', 'shown', 'inactive' }
local MODE_KVP <const> = 'mode'
local SUGGESTION_REFRESH_MS <const> = 500

---@type table<ChatMode, string>
local MODE_COPY <const> = {
    active = 'Chat shows new messages for a few seconds.',
    shown = 'Chat stays on screen.',
    inactive = 'Chat shows only when you open it.',
}

local savedMode <const> = GetResourceKvpString(MODE_KVP)

if MODE_COPY[savedMode] then
    state.mode = savedMode --[[@as ChatMode]]
end

---@class ChatSuggestion
---@field name string
---@field help string
---@field params? { name: string, help: string }[]

---@class ChatMessage
---@field id string
---@field author string
---@field channel string
---@field scope ChatScope
---@field style ChatStyle
---@field label string
---@field content string
---@field timestamp integer

---@class LegacyChatMessage
---@field args? any[]
---@field color? integer[]
---@field multiline? boolean
---@field template? string

---@param description string
local function notify(description)
    exports.cobalt_core:Notify({ title = 'Chat mode', description = description, type = 'inform' })
end

---@param mode ChatMode
local function setMode(mode)
    state.mode = mode
    SetResourceKvp(MODE_KVP, mode)
    SendNUIMessage({ action = 'mode', mode = mode })
    notify(MODE_COPY[mode])
end

---@return ChatMode
local function nextMode()
    for i, mode in ipairs(MODE_ORDER) do
        if mode == state.mode then
            return MODE_ORDER[i % #MODE_ORDER + 1]
        end
    end

    return MODE_ORDER[1]
end

RegisterCommand('chatmode', function(_, args)
    local mode <const> = args[1] and args[1]:lower()

    if not MODE_COPY[mode] then
        notify(('Chat mode is %s. Use /chatmode active, shown or inactive.'):format(state.mode))
        return
    end

    setMode(mode)
end, false)

RegisterCommand('+cobalt_chat_mode', function()
    if state.open then return end

    setMode(nextMode())
end, false)

RegisterCommand('-cobalt_chat_mode', function() end, false)

RegisterKeyMapping('+cobalt_chat_mode', 'Cycle chat mode', 'keyboard', config.ModeKey)

RegisterCommand('cobalt_chat_open', function()
    if state.open then return end

    state.open = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'focusInput' })
end, false)

RegisterKeyMapping('cobalt_chat_open', 'Open chat', 'keyboard', config.OpenKey)

---@param message ChatMessage
local function render(message)
    SendNUIMessage({ action = 'renderMessage', message = message })
end

RegisterNetEvent('cobalt_chat:render', function(message)
    if not message then return end

    render(message)
end)

local legacyCount = 0

---@param text any
---@return string
local function stripColourCodes(text)
    return (tostring(text):gsub('%^[0-9*_~]', ''))
end

---@param data string|LegacyChatMessage
---@return any[]
local function legacyArgs(data)
    if type(data) == 'string' then return { data } end

    return type(data) == 'table' and type(data.args) == 'table' and data.args or {}
end

---@param data string|LegacyChatMessage
---@return ChatMessage?
local function fromLegacy(data)
    local args <const> = legacyArgs(data)
    local author = 'System'
    local first = 1

    if #args >= 2 then
        author = stripColourCodes(args[1])
        first = 2
    end

    local parts <const> = {}

    for i = first, #args do
        parts[#parts + 1] = tostring(args[i])
    end

    local content <const> = table.concat(parts, ' ')

    if content == '' then return end

    legacyCount += 1

    return {
        id = ('legacy-%d'):format(legacyCount),
        author = author ~= '' and author or 'System',
        channel = 'server',
        scope = 'global',
        style = 'system',
        label = 'Server',
        content = content,
        timestamp = GetCloudTimeAsInt() * 1000,
    }
end

RegisterNetEvent('chat:addMessage', function(data)
    local message <const> = fromLegacy(data)

    if message then
        render(message)
    end
end)

RegisterNetEvent('chat:clear', function()
    SendNUIMessage({ action = 'clear' })
end)

---@type table<string, ChatSuggestion>
local registered <const> = {}

---@return ChatSuggestion[]
local function buildSuggestions()
    local list <const> = {}
    local seen <const> = {}

    ---@param suggestion ChatSuggestion
    local function add(suggestion)
        if seen[suggestion.name] then return end

        seen[suggestion.name] = true
        list[#list + 1] = suggestion
    end

    for _, suggestion in pairs(registered) do
        add(suggestion)
    end

    for command, channel in pairs(config.Channels) do
        add({ name = '/' .. command, help = ('%s channel'):format(channel.label) })
    end

    add({
        name = '/chatmode',
        help = 'Choose when chat shows',
        params = { { name = 'active|shown|inactive', help = '' } },
    })

    for command in pairs(config.Delegations) do
        add({ name = '/' .. command, help = 'Delegated to another resource' })
    end

    for _, command in ipairs(GetRegisteredCommands()) do
        local name <const> = command.name

        if name and not name:find('^[+-]') and IsAceAllowed('command.' .. name) then
            add({ name = '/' .. name, help = '' })
        end
    end

    return list
end

---@return { command: string, label: string, order: integer }[]
local function buildChannels()
    local list <const> = {}

    for command, channel in pairs(config.Channels) do
        list[#list + 1] = { command = command, label = channel.label, order = channel.order }
    end

    table.sort(list, function(a, b) return a.order < b.order end)

    return list
end

---@return string?
local function getMentionName()
    return exports.cobalt_core:GetPlayerData()?.charinfo?.firstname
end

local function pushBoot()
    SendNUIMessage({
        action = 'boot',
        config = {
            idleFadeMs = config.IdleFadeMs,
            maxMessages = config.MaxMessages,
            maxMessageLen = config.MaxMessageLength,
            channels = buildChannels(),
            mentionName = getMentionName(),
        },
        suggestions = buildSuggestions(),
        mode = state.mode,
    })
end

local function refreshSuggestions()
    SetTimeout(SUGGESTION_REFRESH_MS, function()
        SendNUIMessage({ action = 'addSuggestions', suggestions = buildSuggestions() })
    end)
end

RegisterNUICallback('ready', function(_, cb)
    pushBoot()
    cb('ok')
end)

RegisterNetEvent('cobalt_core:Client:OnPlayerLoaded', function()
    SendNUIMessage({ action = 'identity', name = getMentionName() })
end)

---@param resource string
local function onOtherResourceChanged(resource)
    if resource == cache.resource then return end

    refreshSuggestions()
end

AddEventHandler('onClientResourceStart', onOtherResourceChanged)
AddEventHandler('onClientResourceStop', onOtherResourceChanged)

---@param suggestions ChatSuggestion[]
local function register(suggestions)
    local added <const> = {}

    for _, suggestion in ipairs(suggestions) do
        if type(suggestion) == 'table' and type(suggestion.name) == 'string' and suggestion.name ~= '' then
            registered[suggestion.name] = suggestion
            added[#added + 1] = suggestion
        end
    end

    SendNUIMessage({ action = 'addSuggestions', suggestions = added })
end

RegisterNetEvent('chat:addSuggestion', function(name, help, params)
    register({ { name = name, help = help, params = params } })
end)

RegisterNetEvent('chat:addSuggestions', function(list)
    if type(list) ~= 'table' then return end

    if list.name then
        register({ list })
        return
    end

    local suggestions <const> = {}

    for _, suggestion in pairs(list) do
        suggestions[#suggestions + 1] = suggestion
    end

    register(suggestions)
end)

RegisterNetEvent('chat:removeSuggestion', function(name)
    if type(name) ~= 'string' then return end

    registered[name] = nil
    SendNUIMessage({ action = 'removeSuggestion', name = name })
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == cache.resource then SetNuiFocus(false, false) end
end)
