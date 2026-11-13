---@alias ChatMode 'active' | 'shown' | 'inactive'

---@class ChatState
---@field open boolean
---@field mode ChatMode
local state <const> = {
    open = false,
    mode = 'active',
}

local FOCUS_RELEASE_MS <const> = 300

function state.releaseFocus()
    state.open = false
    SetNuiFocus(false, false)

    local untilTime <const> = GetGameTimer() + FOCUS_RELEASE_MS

    CreateThread(function()
        while GetGameTimer() < untilTime do
            DisableControlAction(0, 199, true)
            DisableControlAction(0, 200, true)
            Wait(0)
        end
    end)
end

return state
