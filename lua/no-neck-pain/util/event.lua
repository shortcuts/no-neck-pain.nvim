local api = require("no-neck-pain.util.api")
local constants = require("no-neck-pain.util.constants")
local state = require("no-neck-pain.state")

local E = {}

--- skips the event if:
--- - the plugin is not enabled
--- - the current window is a relative window
--- - the event is triggered in a different tab
---
---@private
function E.skip()
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
function E.skip_enable(scope)
    if state.is_active_tab_registered(state) then
        return true
    end

    if api.is_relative_window() then
        return true
    end

    if state.disabled_tabs[state.active_tab] then
        if scope == "enable_on_tab_enter" then
            return true
        end

        state.disabled_tabs[state.active_tab] = nil

        return false
    end

    -- dashboards delays the plugin enable step until next buffer entered
    if vim.tbl_contains(constants.DASHBOARDS, vim.bo.filetype) then
        return true
    end

    return state.is_supported_integration(state, "E.skip_enable", nil)
end

return E
