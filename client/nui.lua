local config <const> = require 'config'
local state <const> = require 'client.state'

---@param command string
---@return boolean
local function isServerRouted(command)
    return config.Channels[command] ~= nil or config.Delegations[command] ~= nil
end

---@param content string
local function dispatch(content)
    if content:sub(1, 1) ~= '/' then
        TriggerServerEvent('cobalt_chat:send', { content = content })
        return
    end

    local raw <const> = content:sub(2)
    local command <const> = raw:match('^(%S+)')

    if command and isServerRouted(command:lower()) then
        TriggerServerEvent('cobalt_chat:slash', raw)
        return
    end

    ExecuteCommand(raw)
end

RegisterNUICallback('send', function(data, cb)
    cb('ok')

    if type(data?.content) ~= 'string' then return end

    state.releaseFocus()
    SendNUIMessage({ action = 'blurInput' })
    dispatch(data.content)
end)

RegisterNUICallback('blur', function(_, cb)
    state.releaseFocus()
    cb('ok')
end)
