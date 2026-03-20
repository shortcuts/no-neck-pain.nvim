local api = require("no-neck-pain.util.api")
local constants = require("no-neck-pain.util.constants")
local log = require("no-neck-pain.util.log")
local event = require("no-neck-pain.util.event")
local state = require("no-neck-pain.state")
local ui = require("no-neck-pain.ui")
local helpers = require("no-neck-pain.util.helpers")

local main = {}

-- Toggle the plugin by calling the `enable`/`disable` methods respectively.
--
---@param scope string: internal identifier for logging purposes.
---@private
function main.toggle(scope)
    if state:has_tabs() and state:is_active_tab_registered() then
        return main.disable(scope)
    end

    main.enable(scope)
end

--- Toggles the scratch_pad feature of the plugin.
---@private
function main.toggle_scratch_pad()
    if not state:is_active_tab_registered() then
        return
    end

    local current_state = state.tabs[state.active_tab].scratchpad_enabled

    -- save new state of the scratch_pad and update tabs
    state:set_scratch_pad(not current_state)

    -- map over both sides and let the init method either setup or cleanup the side buffers
    for _, side in pairs(constants.SIDES) do
        local id = state:get_side_id(side)
        if id ~= nil and vim.api.nvim_win_is_valid(id) then
            vim.api.nvim_set_current_win(id)
            ui.init_scratch_pad(side, id, current_state)
        end
    end

    -- restore focus
    local prev_win = state:get_previously_focused_win()
    if prev_win ~= nil and vim.api.nvim_win_is_valid(prev_win) then
        vim.api.nvim_set_current_win(prev_win)
    end

    state:save()
end

--- Toggles the config `${side}.enabled` and re-inits the plugin.
---
---@param scope string: internal identifier for logging purposes.
---@param side "left" | "right": the side to toggle.
---@private
function main.toggle_side(scope, side)
    if not state:is_active_tab_registered() then
        log.debug(scope, "skipped because the current tab is not registered")

        return state:save()
    end

    helpers.set_config(vim.tbl_deep_extend("keep", {
        buffers = {
            [side] = {
                enabled = not helpers.get_config_field("buffers")[side].enabled,
            },
        },
    }, helpers.get_config()))

    if not helpers.get_config_field("buffers")[side].enabled then
        ui.close_win(scope, state:get_side_id(side), side)
        state:set_side_id(nil, side)
    end

    if
        not (state:is_side_enabled_and_valid("left") or state:is_side_enabled_and_valid("right"))
    then
        helpers.set_config(
            vim.tbl_deep_extend(
                "keep",
                { buffers = { left = { enabled = true }, right = { enabled = true } } },
                helpers.get_config()
            )
        )

        return main.disable(scope)
    end

    state:scan_layout(scope)

    main.init(scope)
end

--- Creates side buffers and set the tab state, focuses the `curr` window if required.
---@param scope string: internal identifier for logging purposes.
---@private
function main.init(scope)
    if not state:is_active_tab_registered() then
        error("called the internal `init` method on a `nil` tab.")
    end

    log.debug(
        scope,
        "init called on tab %d for current window %d",
        state.active_tab,
        state:get_side_id("curr")
    )

    if state:consume_redraw() then
        ui.move_sides(string.format("%s:consume_redraw", scope))
    end

    ui.create_side_buffers()

    if
        (state:is_side_the_active_win("left") or state:is_side_the_active_win("right"))
        and state:get_previously_focused_win() ~= vim.api.nvim_get_current_win()
    then
        log.debug(
            scope,
            "rerouting focus of %d to %s",
            vim.api.nvim_get_current_win(),
            state:get_previously_focused_win()
        )

        if vim.api.nvim_win_is_valid(state:get_side_id("curr")) then
            vim.api.nvim_set_current_win(state:get_side_id("curr"))
        end

        if
            vim.api.nvim_win_is_valid(state:get_previously_focused_win())
            and state.active_tab
                == vim.api.nvim_win_get_tabpage(state:get_previously_focused_win())
        then
            vim.api.nvim_set_current_win(state:get_previously_focused_win())
        end
    end

    state:save()
end

--- Initializes the plugin, sets event listeners and internal state.
---
---@param scope string: internal identifier for logging purposes.
---@private
function main.enable(scope)
    state:set_active_tab(api.get_current_tab())

    if event.skip_enable(scope) then
        return
    end

    if helpers.get_config_field("callbacks").preEnable ~= nil then
        helpers.get_config_field("callbacks").preEnable(state)
    end

    log.debug(scope, "calling enable for tab %d", state.active_tab)

    state:set_enabled()
    state:set_tab(state.active_tab)

    -- Capture initial window options from the current normal window
    -- This must be done before creating side buffers to capture user's configured options
    state:capture_initial_window_opts()

    local augroup_name = api.get_augroup_name(state.active_tab)
    vim.api.nvim_create_augroup(augroup_name, { clear = true })

    state:set_side_id(vim.api.nvim_get_current_win(), "curr")
    state:scan_layout(scope)
    main.init(scope)
    state:scan_layout(scope)

    vim.api.nvim_create_autocmd({ "VimResized" }, {
        callback = function(p)
            vim.schedule(function()
                if
                    helpers.get_state() == nil
                    or not helpers.get_state_field("enabled")
                    or not state:is_active_tab_registered()
                then
                    return
                end

                main.init(p.event)
            end)
        end,
        group = augroup_name,
        desc = "Resizes side windows after terminal has been resized, closes them if not enough space left.",
    })

    vim.api.nvim_create_autocmd({ "TabEnter" }, {
        callback = function(p)
            api.debounce(p.event, function()
                state:set_active_tab(api.get_current_tab())

                log.debug(p.event, "tab %d entered", state.active_tab)

                state:refresh_tabs(p.event)
            end)
        end,
        group = augroup_name,
        desc = "Keeps track of the currently active tab and the tab state",
    })

    vim.api.nvim_create_autocmd({ "WinEnter", "WinClosed" }, {
        callback = function(p)
            local s = string.format("%s:%d", p.event, vim.api.nvim_get_current_win())
            vim.schedule(function()
                -- Update active tab first (TabEnter debounce might not have run yet)
                state:set_active_tab(api.get_current_tab())

                if not state:is_active_tab_registered() or event.skip() then
                    return
                end

                local pre_win_count = #vim.api.nvim_tabpage_list_wins(state.active_tab)
                local init = state:scan_layout(s)

                -- Validate that stored window IDs are still valid after layout change
                local valid_wins = vim.api.nvim_tabpage_list_wins(state.active_tab)
                local post_win_count = #valid_wins
                local valid_win_set = {}
                for _, win_id in ipairs(valid_wins) do
                    valid_win_set[win_id] = true
                end

                -- Check if main window is still valid
                local curr_id = state:get_side_id("curr")
                if curr_id and not valid_win_set[curr_id] then
                    log.debug(s, "clearing invalid main window %d", curr_id)
                    -- Try to find a replacement window
                    local unregistered = state:get_unregistered_wins(s)
                    if #unregistered > 0 then
                        state:set_side_id(unregistered[1], "curr")
                        log.debug(s, "reassigned main window to %d", unregistered[1])
                    elseif
                        state:get_previously_focused_win()
                        and vim.api.nvim_win_is_valid(state:get_previously_focused_win())
                    then
                        state:set_side_id(state:get_previously_focused_win(), "curr")
                        log.debug(
                            s,
                            "reassigned main window to previously focused %d",
                            state:get_previously_focused_win()
                        )
                    end
                end

                -- Check if left window is still valid
                local left_id = state:get_side_id("left")
                local left_was_cleared = false
                if left_id and not valid_win_set[left_id] then
                    log.debug(s, "left side window %d is no longer valid", left_id)
                    left_was_cleared = true
                end

                -- Check if right window is still valid
                local right_id = state:get_side_id("right")
                local right_was_cleared = false
                if right_id and not valid_win_set[right_id] then
                    log.debug(s, "right side window %d is no longer valid", right_id)
                    right_was_cleared = true
                end

                local side_window_was_cleared = left_was_cleared or right_was_cleared

                if
                    not state.tabs[state.active_tab].redraw
                    and (state:is_side_the_active_win("left") or state:is_side_the_active_win(
                        "right"
                    ) or state:is_side_the_active_win("curr"))
                    and not init
                    and pre_win_count == post_win_count
                then
                    return
                end

                if side_window_was_cleared and p.event == "WinClosed" then
                    log.debug(s, "a side window was closed, disabling plugin")
                    api.debounce(s, function()
                        main.disable()
                    end)
                elseif init then
                    api.debounce(s, main.init)
                elseif
                    p.event == "WinClosed"
                    and not init
                    and pre_win_count ~= post_win_count
                    and not side_window_was_cleared
                then
                    api.debounce(s, main.init)
                end
            end)
        end,
        group = augroup_name,
        desc = "Keeps track of the state after entering new windows",
    })

    vim.api.nvim_create_autocmd({ "QuitPre", "BufDelete" }, {
        callback = function(p)
            vim.schedule(function()
                local s = string.format("%s:%d", p.event, vim.api.nvim_get_current_win())
                if not state:is_active_tab_registered() or api.is_relative_window() then
                    return
                end

                if
                    p.event == "BufDelete"
                    and vim.api.nvim_win_is_valid(state:get_side_id("curr"))
                then
                    return
                end

                local refresh = state:scan_layout(s)

                if not vim.api.nvim_win_is_valid(state:get_side_id("curr")) then
                    if
                        p.event == "BufDelete"
                        and helpers.get_config_field("fallbackOnBufferDelete")
                    then
                        local win = vim.api.nvim_get_current_win()

                        log.debug(
                            s,
                            "`curr` has been deleted, resetting state, now focusing %d",
                            win
                        )

                        local opened_buffers = api.get_opened_buffers()

                        -- if we are currently on a side window,
                        -- side window options to the newly opened window
                        -- which will override the user's default window options
                        -- we then need to reset it to the initial value we stored at startup
                        if
                            api.is_side_id(state:get_side_id("left"), win)
                            or api.is_side_id(state:get_side_id("right"), win)
                            or api.is_relative_window(win)
                        then
                            vim.cmd("rightbelow vertical split")

                            local new_win = vim.api.nvim_get_current_win()

                            if not vim.api.nvim_win_is_valid(new_win) then
                                return log.debug(s, "split failed to create a new window, aborting")
                            end

                            log.debug(
                                s,
                                "currently on a side %d, new win is %d, resetting window options",
                                win,
                                new_win
                            )

                            for opt, val in pairs(state.initial_window_opts) do
                                api.set_window_option(new_win, opt, val)
                            end
                        end

                        if vim.tbl_count(opened_buffers) > 0 then
                            local bufname, _ = next(opened_buffers)
                            if bufname and vim.startswith(bufname, "NoNamePain") then
                                bufname = string.sub(bufname, 11)
                            end

                            vim.cmd("buffer " .. bufname)
                            log.debug(s, "fallback to %s", bufname)
                        end

                        main.disable(string.format("%s:reset", s))
                        main.enable(string.format("%s:reset", s))

                        return
                    end

                    local wins = state:get_unregistered_wins(scope)
                    if #wins == 0 then
                        log.debug(s, "no active windows found")

                        return main.disable(s)
                    end

                    state:set_side_id(wins[1], "curr")

                    log.debug(s, "re-routing to %d", wins[1])

                    return main.init(s)
                end

                if
                    p.event == "QuitPre"
                    and not state:is_side_enabled_and_valid("left")
                    and not state:is_side_enabled_and_valid("right")
                then
                    log.debug(s, "closed a vsplit when no side buffers were present")

                    return main.init(s)
                end

                if
                    (state:is_side_enabled("left") and not state:is_side_enabled_and_valid("left"))
                    or (
                        state:is_side_enabled("right")
                        and not state:is_side_enabled_and_valid("right")
                    )
                then
                    log.debug(s, "one of the NNP side has been closed")

                    return main.disable(s)
                end

                if refresh then
                    return main.init(s)
                end
            end)
        end,
        group = augroup_name,
        desc = "keeps track of the state after closing windows and deleting buffers",
    })

    vim.api.nvim_create_autocmd({ "VimEnter", "WinEnter" }, {
        callback = function(p)
            vim.schedule(function()
                p.event = string.format("%s:skip_entering", p.event)
                if not state:is_active_tab_registered() then
                    return log.debug(p.event, "skip")
                end

                if not helpers.get_config_field("autocmds").skipEnteringNoNeckPainBuffer then
                    state:set_previously_focused_win(vim.api.nvim_get_current_win())
                    return
                end

                if state:get_scratch_pad() then
                    return log.debug(p.event, "skip because scratchpad is enabled")
                end

                local current_side = vim.api.nvim_get_current_win()
                local other_side
                local left_id = state:get_side_id("left")
                local right_id = state:get_side_id("right")

                if current_side == left_id then
                    other_side = right_id
                elseif current_side == right_id then
                    other_side = left_id
                else
                    state:set_previously_focused_win(vim.api.nvim_get_current_win())
                    return
                end

                -- we need to know if the user navigates from ltr or rtl
                -- so we keep track of the encounter of prev,curr to determine
                -- the next valid window to focus

                local wins = vim.api.nvim_list_wins()
                local idx

                for i = 1, #wins do
                    if wins[i] and api.is_side_id(current_side, wins[i]) then
                        idx = api.find_next_side_idx(
                            i - 1,
                            -1,
                            wins,
                            current_side,
                            other_side,
                            state:get_previously_focused_win()
                        )
                        break
                    elseif
                        wins[i] and api.is_side_id(state:get_previously_focused_win(), wins[i])
                    then
                        idx = api.find_next_side_idx(
                            i + 1,
                            1,
                            wins,
                            current_side,
                            other_side,
                            state:get_previously_focused_win()
                        )
                        break
                    end
                end

                local new_focus = wins[idx] or state:get_previously_focused_win()

                if not vim.api.nvim_win_is_valid(new_focus) then
                    return log.debug(
                        p.event,
                        "aborting reroute, %d is not a valid window",
                        new_focus
                    )
                end

                vim.schedule(function()
                    vim.api.nvim_set_current_win(new_focus)
                end)

                return log.debug(p.event, "rerouted focus of %d to %d", current_side, new_focus)
            end)
        end,
        group = augroup_name,
        desc = "Keeps track of the last focused win, and re-route if necessary",
    })

    vim.api.nvim_create_autocmd({ "SessionLoadPost" }, {
        callback = function()
            vim.schedule(function()
                local state_ref = helpers.get_state()
                -- If plugin was enabled before session, reinit side buffers with new layout
                if state_ref and state_ref.enabled and state_ref:is_active_tab_registered() then
                    -- Preserve old side window IDs in state for auto-restore after session
                    state_ref:scan_layout("SessionLoadPost")
                    main.init("SessionLoadPost")
                end
            end)
        end,
        group = augroup_name,
        desc = "Re-initialize side buffers after session restore",
    })

    state:save()

    if helpers.get_config_field("callbacks").postEnable ~= nil then
        helpers.get_config_field("callbacks").postEnable(state)
    end
end

--- Disables the plugin for the given tab, clear highlight groups and autocmds, closes side buffers and resets the internal state.
---@private
function main.disable(scope)
    if helpers.get_config_field("callbacks").preDisable ~= nil then
        helpers.get_config_field("callbacks").preDisable(state)
    end

    local active_tab = state.active_tab

    log.debug(scope, "calling disable for tab %d", active_tab)

    local wins = vim.tbl_filter(function(win)
        return win ~= state:get_side_id("left")
            and win ~= state:get_side_id("right")
            and not api.is_relative_window(win)
    end, vim.api.nvim_tabpage_list_wins(active_tab))

    if #vim.api.nvim_list_tabpages() == 1 and #wins == 0 then
        for name, modified in pairs(api.get_opened_buffers()) do
            if modified then
                if vim.startswith(name, "NoNamePain") then
                    name = string.sub(name, 11)
                end

                vim.schedule(function()
                    log.notify(
                        scope,
                        vim.log.levels.ERROR,
                        true,
                        "unable to quit nvim because one or more buffer has modified files, please save or discard changes"
                    )
                    vim.cmd("rightbelow vertical split")
                    vim.cmd("buffer " .. name)
                    main.init(scope)
                end)
                return
            end
        end

        helpers.safe_delete_augroup(api.get_augroup_name(active_tab))
        helpers.safe_delete_augroup("NoNeckPainVimEnterAutocmd")

        return vim.cmd("quitall!")
    end

    helpers.safe_delete_augroup(api.get_augroup_name(active_tab))

    local sides = { left = state:get_side_id("left"), right = state:get_side_id("right") }
    local curr_id = state:get_side_id("curr")

    if state:refresh_tabs(scope, active_tab) == 0 then
        helpers.safe_delete_augroup("NoNeckPainVimEnterAutocmd")

        log.debug(scope, "no more active tabs left, reinitializing state")

        -- SAFE: state:init() resets tabs but preserves namespaces, so they're still available
        -- for state:remove_namespace() calls below which need self.namespaces intact
        state:init()
    end

    for side, id in pairs(sides) do
        if vim.api.nvim_win_is_valid(id) then
            -- Safe to use self.namespaces here even after state:init() call above
            -- because init() only resets self.tabs and self.active_tab, not self.namespaces
            state:remove_namespace(vim.api.nvim_win_get_buf(id), side)
            ui.close_win(scope, id, side)
        end
    end

    -- shutdowns gracefully by focusing the stored `curr` buffer
    if curr_id ~= nil and vim.api.nvim_win_is_valid(curr_id) then
        vim.api.nvim_set_current_win(curr_id)

        if helpers.get_config_field("killAllBuffersOnDisable") then
            vim.cmd("only")
        end
    end

    state:set_tab_disabled(active_tab)

    state:save()

    if helpers.get_config_field("callbacks").postDisable ~= nil then
        helpers.get_config_field("callbacks").postDisable(state)
    end
end

return main
