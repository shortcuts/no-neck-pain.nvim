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

    return api.get_current_tab() ~= state.active_tab
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
    if state.is_active_tab_registered(state) then
        log.debug(string.format("skip_enable:%s", scope), "tab already registered")
        return true
    end

    if api.is_relative_window() then
        log.debug(string.format("skip_enable:%s", scope), "relative window")
        return true
    end

    if state.is_active_tab_disabled(state) then
        log.debug(string.format("skip_enable:%s", scope), "disabled")
        if scope == "enable_on_tab_enter" then
            return true
        end

        state.remove_active_tab_from_disabled(state)

        return false
    end

    -- dashboards delays the plugin enable step until next buffer entered
    if vim.tbl_contains(constants.DASHBOARDS, vim.bo.filetype) then
        log.debug(string.format("skip_enable:%s", scope), "dashboard")
        return true
    end
    log.debug(string.format("skip_enable:%s", scope), vim.bo.filetype)

    return state.is_supported_integration(state, "event.skip_enable", nil)
end

return event
