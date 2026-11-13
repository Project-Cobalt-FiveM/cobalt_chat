local config <const> = require 'config'
local core <const> = exports.cobalt_core
local Cobalt <const> = core:GetCoreObject()

---@class ChatMessage
---@field id string
---@field author string
---@field authorSrc integer
---@field channel string
---@field scope ChatScope
---@field style ChatStyle
---@field label string
---@field content string
---@field timestamp integer

---@class RateBucket
---@field count integer
---@field windowStart integer

---@type table<integer, RateBucket>
local rateBuckets <const> = {}

---@type table<string, true>
local muted <const> = {}

local messageCount = 0

---@return string
local function nextMessageId()
    messageCount += 1

    return ('msg-%d'):format(messageCount)
end

---@param word string
---@return string
local function caseInsensitivePattern(word)
    return (word:gsub('%W', '%%%0'):gsub('%a', function(letter)
        return ('[%s%s]'):format(letter:lower(), letter:upper())
    end))
end

---@type { pattern: string, stars: string }[]
local filters <const> = {}

for _, word in ipairs(config.WordFilter) do
    filters[#filters + 1] = { pattern = caseInsensitivePattern(word), stars = ('*'):rep(#word) }
end

---@param source integer
---@return string
local function getDisplayName(source)
    return core:GetName(source) or GetPlayerName(source) or ('Player ' .. source)
end

---@param source integer
---@return string?
local function getCitizenId(source)
    return core:GetPlayer(source)?.PlayerData.citizenid
end

---@param source integer
---@return boolean
local function isStaff(source)
    return core:HasPermission(source, config.AdminRank)
end

---@param text string
---@return string
local function applyWordFilter(text)
    for _, filter in ipairs(filters) do
        text = text:gsub(filter.pattern, filter.stars)
    end

    return text
end

---@param source integer
---@return boolean
local function withinRateLimit(source)
    local limit <const> = config.RateLimit

    if limit.messages <= 0 then return true end

    local now <const> = GetGameTimer()
    local bucket <const> = rateBuckets[source]

    if not bucket or now - bucket.windowStart > limit.windowMs then
        rateBuckets[source] = { count = 1, windowStart = now }
        return true
    end

    if bucket.count >= limit.messages then return false end

    bucket.count += 1

    return true
end

---@param source integer
---@param channel string
---@param content string
---@param style? ChatStyle
---@return ChatMessage
local function buildMessage(source, channel, content, style)
    local definition <const> = config.Channels[channel] or config.Channels.say
    local isSystem <const> = style == 'system'

    return {
        id = nextMessageId(),
        author = isSystem and 'System' or getDisplayName(source),
        authorSrc = source,
        channel = channel,
        scope = definition.scope,
        style = style or definition.style or 'speech',
        label = isSystem and 'Server' or definition.label,
        content = content,
        timestamp = os.time() * 1000,
    }
end

---@param target integer
---@param message ChatMessage
local function deliver(target, message)
    TriggerClientEvent('cobalt_chat:render', target, message)
end

---@param source integer
---@param text string
local function tellSystem(source, text)
    deliver(source, buildMessage(source, 'ac', text, 'system'))
end

---@param sender integer
---@param message ChatMessage
local function deliverProximity(sender, message)
    local senderPed <const> = GetPlayerPed(sender)

    if not senderPed or senderPed == 0 then return end

    local origin <const> = GetEntityCoords(senderPed)

    for _, id in ipairs(GetPlayers()) do
        local target <const> = tonumber(id) --[[@as integer]]
        local ped <const> = GetPlayerPed(target)

        if ped ~= 0 and #(GetEntityCoords(ped) - origin) <= config.ProximityRadius then
            deliver(target, message)
        end
    end
end

---@param message ChatMessage
local function deliverStaff(message)
    for _, id in ipairs(GetPlayers()) do
        local target <const> = tonumber(id) --[[@as integer]]

        if isStaff(target) then
            deliver(target, message)
        end
    end
end

---@param message ChatMessage
local function deliverGlobal(message)
    deliver(-1, message)
end

---@type table<ChatScope, fun(sender: integer, message: ChatMessage)>
local deliverByScope <const> = {
    proximity = deliverProximity,
    global = function(_, message) deliverGlobal(message) end,
    admin = function(_, message) deliverStaff(message) end,
}

---@param source integer
---@return boolean
local function maySpeak(source)
    local citizenid <const> = getCitizenId(source)

    if citizenid and muted[citizenid] then
        tellSystem(source, '[muted] You are currently muted.')
        return false
    end

    if not withinRateLimit(source) then
        tellSystem(source, '[rate-limit] Slow down.')
        return false
    end

    return true
end

---@param source integer
---@param channel string
---@param body string
local function routeMessage(source, channel, body)
    if not body:find('%S') then return end

    if not maySpeak(source) then return end

    if channel == 'ac' and not isStaff(source) then
        tellSystem(source, 'You do not have permission for /ac')
        return
    end

    local content <const> = applyWordFilter(body:sub(1, config.MaxMessageLength))
    local message <const> = buildMessage(source, channel, content)

    lib.print.debug(('route %s -> %s from %d'):format(channel, message.scope, source))

    deliverByScope[message.scope](source, message)
end

RegisterNetEvent('cobalt_chat:send', function(payload)
    local source <const> = source

    if type(payload?.content) ~= 'string' then return end

    routeMessage(source, 'say', payload.content)
end)

RegisterNetEvent('cobalt_chat:slash', function(rawCommand)
    local source <const> = source

    if type(rawCommand) ~= 'string' then return end

    local command <const> = rawCommand:match('^(%S+)')

    if not command then return end

    local name <const> = command:lower()
    local rest <const> = rawCommand:match('^%S+%s+(.*)$') or ''

    if config.Channels[name] then
        routeMessage(source, name, rest)
        return
    end

    local delegation <const> = config.Delegations[name]

    if not delegation then return end

    if not rest:find('%S') then
        tellSystem(source, ('Usage: /%s <message>'):format(name))
        return
    end

    if not maySpeak(source) then return end

    if GetResourceState(delegation.resource) ~= 'started' then
        tellSystem(source, 'Nobody is answering that line right now.')
        return
    end

    TriggerEvent(delegation.event, source, rest:sub(1, config.MaxMessageLength))
end)

---@type CommandArgument[]
local targetArgument <const> = { { name = 'id', help = 'Player server id', type = 'playerId' } }

Cobalt.Commands.Add('mute', 'Mute a player in chat', targetArgument, true, function(source, args)
    local target <const> = args[1] --[[@as integer]]
    local citizenid <const> = getCitizenId(target)

    if not citizenid then return end

    local name <const> = getDisplayName(target)

    muted[citizenid] = true
    tellSystem(source, ('Muted %s'):format(name))
    tellSystem(target, 'You have been muted by an admin.')
    core:LogPlayer(source, 'chat.mute', ('Muted %s in chat'):format(name), { citizenid = citizenid }, 'info', target)
end, config.AdminRank)

Cobalt.Commands.Add('unmute', 'Unmute a player in chat', targetArgument, true, function(source, args)
    local target <const> = args[1] --[[@as integer]]
    local citizenid <const> = getCitizenId(target)

    if not citizenid then return end

    local name <const> = getDisplayName(target)

    muted[citizenid] = nil
    tellSystem(source, ('Unmuted %s'):format(name))
    core:LogPlayer(source, 'chat.unmute', ('Unmuted %s in chat'):format(name), { citizenid = citizenid }, 'info', target)
end, config.AdminRank)

Cobalt.Commands.Add('clearchat', 'Clear chat for every player', {}, false, function(source)
    TriggerClientEvent('chat:clear', -1)
    core:LogPlayer(source, 'chat.clear', 'Cleared chat for every player')
end, config.AdminRank)

---@param source integer
---@param permission string
---@return string
local function aceState(source, permission)
    return tostring(IsPlayerAceAllowed(tostring(source), permission))
end

Cobalt.Commands.Add('permcheck', 'Show your rank and command permissions', {
    { name = 'command', help = 'Command name to check' },
}, false, function(source, args)
    if source == 0 then return end

    local command <const> = args[1] and tostring(args[1]):lower()
    local lines <const> = {
        ('---- PERMCHECK src=%d ----'):format(source),
        ('  owner          : %s'):format(aceState(source, 'owner')),
        ('  admin          : %s'):format(aceState(source, 'admin')),
        ('  staff          : %s'):format(aceState(source, 'staff')),
        ('  command (any)  : %s'):format(aceState(source, 'command')),
        command and ('  command.%s   : %s'):format(command, aceState(source, 'command.' .. command))
            or '  (pass a command name as arg, e.g. /permcheck time)',
    }

    for _, line in ipairs(lines) do
        tellSystem(source, line)
    end
end)

AddEventHandler('playerDropped', function()
    rateBuckets[source] = nil
end)

---@param text string
---@param channel? string
local function broadcastSystem(text, channel)
    local name <const> = channel or 'ooc'
    local definition <const> = config.Channels[name] or config.Channels.ooc

    ---@type ChatMessage
    local message <const> = {
        id = nextMessageId(),
        author = 'System',
        authorSrc = 0,
        channel = name,
        scope = definition.scope,
        style = 'system',
        label = 'Server',
        content = text,
        timestamp = os.time() * 1000,
    }

    if definition.scope == 'admin' then
        deliverStaff(message)
        return
    end

    deliverGlobal(message)
end

AddEventHandler('cobalt_chat:system', broadcastSystem)

exports('System', broadcastSystem)

exports('addMessage', function(target, message)
    TriggerClientEvent('chat:addMessage', target, message)
end)
