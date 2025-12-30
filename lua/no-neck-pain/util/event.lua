local log = require("no-neck-pain.util.log")
local api = require("no-neck-pain.util.api")
local constants = require("no-neck-pain.util.constants")
local state = require("no-neck-pain.state")

local event = {}

--- skips the event if:
--- - the plugin is not enabled
--- - the current window is a relative window
--- - the event is triggered in a different tab
---
---@private
function event.skip()
    if _G.NoNeckPain.state == nil or not _G.NoNeckPain.state.enabled then
        return true
    end

    if api.is_relative_window() then
        return true
    end

    if api.get_current_tab() ~= state.active_tab then
        log.debug(
            "event.skip",
            "current tab: %d, active tab: %d",
            api.get_current_tab(),
            state.active_tab
        )

        return true
    end

    return false
end

--- determines if we should skip the enabling of the plugin:
---  1. if a tab definition already exists in the state
---  2. if we are focusing a relative window
---  3. if we are focusing a side tree or a dashboard
--- - the plugin is not enabled
--- - we have splits open (when `skip_split` is `true`)
--- - we are focusing a floating window
--- - we are focusing one of the side buffer
---
---@param scope string: internal identifier for logging purposes.
---@private
function event.skip_enable(scope)
    if state:is_active_tab_registered() then
        return true
    end

    if api.is_relative_window() then
        return true
    end

    if state:is_active_tab_disabled() then
        if scope == "enable_on_tab_enter" then
            return true
        end

        state:remove_active_tab_from_disabled()

        return false
    end

    -- dashboards delays the plugin enable step until next buffer entered
    if vim.tbl_contains(constants.DASHBOARDS, vim.bo.filetype) then
        return true
    end

    return state:is_supported_integration("event.skip_enable", 0)
end

return event
