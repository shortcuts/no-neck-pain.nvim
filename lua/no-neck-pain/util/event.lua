local log = require("no-neck-pain.util.log")
local api = require("no-neck-pain.util.api")
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
        log.debug(scope, "skip: is_active_tab_registered")

        return true
    end

    if api.is_relative_window() then
        log.debug(scope, "skip: is_relative_window")

        return true
    end

    if state:is_active_tab_disabled() then
        if scope == "public_api_enable:TabEnter" then
            log.debug(scope, "skip: is_active_tab_disabled,public_api_enable:TabEnter")

            return true
        end

        log.debug(scope, "skip: is_active_tab_disabled,remove_active_tab_from_disabled")

        state:remove_active_tab_from_disabled()

        return false
    end

    local filetype = string.lower(vim.bo.filetype)

    if _G.NoNeckPain.config.integrations ~= nil then
        for key, config in pairs(_G.NoNeckPain.config.integrations) do
            if key ~= "dashboard" then
                log.debug(scope, "skip: find integration")

                if string.find(filetype, string.lower(key)) then
                    log.debug(scope, "%s is an integration", key)

                    return true
                end
            else
                if config.filetypes ~= nil then
                    log.debug(scope, "skip: find dashboard")

                    for _, ft in pairs(_G.NoNeckPain.config.integrations.dashboard.filetypes) do
                        if string.find(filetype, string.lower(ft)) then
                            log.debug(scope, "%s is a dashboard", ft)

                            return true
                        end
                    end
                end
            end
        end
    end

    return false
end

return event
