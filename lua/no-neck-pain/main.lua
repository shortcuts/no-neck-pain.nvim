local api = require("no-neck-pain.util.api")
local constants = require("no-neck-pain.util.constants")
local log = require("no-neck-pain.util.log")
local event = require("no-neck-pain.util.event")
local state = require("no-neck-pain.state")
local ui = require("no-neck-pain.ui")
local helpers = require("no-neck-pain.util.helpers")

local main = {}

local session_restore_in_progress = false
local skip_entering_in_progress = false

function main.signal_session_restore_start()
    session_restore_in_progress = true
end

function main.signal_session_restore_complete()
    session_restore_in_progress = false
end

-- Toggle the plugin by calling the `enable`/`disable` methods respectively.
--
---@param scope string: debug/trace identifier for logging (not execution scope) - used in debug output only
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
---@param scope string: debug/trace identifier for logging (not execution scope) - used in debug output only
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

    if not (state:is_side_valid("left") or state:is_side_valid("right")) then
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
---@param scope string: debug/trace identifier for logging (not execution scope) - used in debug output only
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
    -- scope is a debug identifier (e.g., "VimEnter", "WinEnter:1001") passed through for tracing, not execution control

    if state:consume_redraw() then
        ui.move_sides(string.format("%s:consume_redraw", scope))
    end

    local left_before = state:get_side_id("left")
    local right_before = state:get_side_id("right")

    ui.create_side_buffers()

    local left_after = state:get_side_id("left")
    local right_after = state:get_side_id("right")

    local new_left = left_before == nil and left_after ~= nil
    local new_right = right_before == nil and right_after ~= nil

    if (new_left or new_right) and not (new_left and new_right) then
        -- Count expected NNP-managed windows vs actual windows in tab
        -- If there are more windows, splits exist and the new side buffer
        -- needs repositioning to span full tab height
        local expected = 1 -- curr
            + (left_after ~= nil and 1 or 0)
            + (right_after ~= nil and 1 or 0)
        local actual = #vim.api.nvim_tabpage_list_wins(state.active_tab)

        if actual > expected then
            ui.move_sides(string.format("%s:reposition_new_sides", scope))
        end
    end

    if
        (state:is_side_focused("left") or state:is_side_focused("right"))
        and state:get_previously_focused_win() ~= vim.api.nvim_get_current_win()
    then
        log.debug(
            scope,
            "rerouting focus of %d to %s",
            vim.api.nvim_get_current_win(),
            state:get_previously_focused_win()
        )

        local curr_id = state:get_side_id("curr")
        if curr_id and vim.api.nvim_win_is_valid(curr_id) then
            vim.api.nvim_set_current_win(curr_id)
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
---@param scope string: debug/trace identifier for logging (not execution scope) - used in debug output only
---@private
function main.enable(scope)
    state:set_active_tab(api.get_current_tab())

    if event.skip_enable(scope) then
        return
    end

    local callbacks = helpers.get_config_field("callbacks")
    if callbacks.preEnable ~= nil then
        callbacks.preEnable(state)
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
    state:set_previously_focused_win(vim.api.nvim_get_current_win())
    state:scan_layout(scope)

    vim.api.nvim_create_autocmd({ "VimEnter", "WinEnter" }, {
        callback = function(p)
            if skip_entering_in_progress then
                return
            end

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
                elseif wins[i] and api.is_side_id(state:get_previously_focused_win(), wins[i]) then
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
                return log.debug(p.event, "aborting reroute, %d is not a valid window", new_focus)
            end

            skip_entering_in_progress = true
            vim.api.nvim_set_current_win(new_focus)
            skip_entering_in_progress = false

            state:set_previously_focused_win(new_focus)

            return log.debug(p.event, "rerouted focus of %d to %d", current_side, new_focus)
        end,
        group = augroup_name,
        desc = "Keeps track of the last focused win, and re-route if necessary",
    })

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

    -- Helper: Validates side window IDs after layout change
    -- Returns flags indicating which side windows are still valid
    local function validate_side_windows(scope, valid_win_set)
        -- Check if main window is still valid
        local curr_id = state:get_side_id("curr")
        if curr_id and not valid_win_set[curr_id] then
            log.debug(scope, "clearing invalid main window %d", curr_id)
            -- Try to find a replacement window
            local unregistered = state:get_unregistered_wins(scope)
            if #unregistered > 0 then
                state:set_side_id(unregistered[1], "curr")
                log.debug(scope, "reassigned main window to %d", unregistered[1])
            elseif
                state:get_previously_focused_win()
                and vim.api.nvim_win_is_valid(state:get_previously_focused_win())
            then
                state:set_side_id(state:get_previously_focused_win(), "curr")
                log.debug(
                    scope,
                    "reassigned main window to previously focused %d",
                    state:get_previously_focused_win()
                )
            end
        end

        -- Check if left window is still valid
        local left_id = state:get_side_id("left")
        local left_was_cleared = false
        if left_id and not valid_win_set[left_id] then
            log.debug(scope, "left side window %d is no longer valid", left_id)
            left_was_cleared = true
            state:set_side_id(nil, "left")
        end

        -- Check if right window is still valid
        local right_id = state:get_side_id("right")
        local right_was_cleared = false
        if right_id and not valid_win_set[right_id] then
            log.debug(scope, "right side window %d is no longer valid", right_id)
            right_was_cleared = true
            state:set_side_id(nil, "right")
        end

        return left_was_cleared, right_was_cleared
    end

    -- Helper: Determines if layout reinitialization is needed
    -- Returns the action to take: "disable", "init", or nil
    local function should_reinit(
        event_name,
        init,
        pre_count,
        post_count,
        left_cleared,
        right_cleared,
        left_id_before,
        right_id_before
    )
        local side_window_was_cleared = left_cleared or right_cleared

        -- When a side window is detected as cleared on WinClosed, check if it was already
        -- nil before the event (squeezed out by create_side_buffers due to space).
        -- If both IDs were already nil, this is a stale WinClosed event and we should
        -- allow reinitialization to potentially recreate the sides if space is available.
        if side_window_was_cleared and event_name == "WinClosed" then
            -- If both sides were already nil, the clearing detected is from stale window checks
            -- Allow reinit to potentially recreate sides
            if left_id_before == nil and right_id_before == nil then
                log.debug(
                    "should_reinit",
                    "side was cleared but both IDs were already nil, allowing init"
                )
                -- Continue to check other conditions instead of returning "disable"
            else
                -- At least one side was actually valid and just got cleared
                return "disable"
            end
        elseif init then
            return "init"
        elseif
            event_name == "WinClosed"
            and not init
            and pre_count ~= post_count
            and not side_window_was_cleared
        then
            return "init"
        elseif event_name == "WinEnter" and not init and pre_count ~= post_count then
            -- On WinEnter, if window count changed, reinit to recreate side windows
            -- even if they were cleared (e.g., by a split operation)
            return "init"
        end

        return nil
    end

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

                local old_integration_ids = {}
                for name, opts in pairs(state:get_integrations()) do
                    if opts.id ~= nil then
                        old_integration_ids[name] = opts.id
                    end
                end

                local init = state:scan_layout(s)

                local new_integration_found = false
                for name, opts in pairs(state:get_integrations()) do
                    log.debug(
                        s,
                        "post-scan integration '%s': id=%s, old_id=%s",
                        name,
                        tostring(opts.id),
                        tostring(old_integration_ids[name])
                    )
                    if opts.id ~= nil and not old_integration_ids[name] then
                        new_integration_found = true
                        break
                    end
                end

                -- Capture side IDs before validation to detect if they were already nil
                local left_id_before = state:get_side_id("left")
                local right_id_before = state:get_side_id("right")

                -- Validate that stored window IDs are still valid after layout change
                local valid_wins = vim.api.nvim_tabpage_list_wins(state.active_tab)
                local post_win_count = #valid_wins
                local valid_win_set = {}
                for _, win_id in ipairs(valid_wins) do
                    valid_win_set[win_id] = true
                end

                local left_cleared, right_cleared = validate_side_windows(s, valid_win_set)

                -- Early exit if no changes and active window is a side buffer
                if
                    not state.tabs[state.active_tab].redraw
                    and (state:is_side_focused("left") or state:is_side_focused("right") or state:is_side_focused(
                        "curr"
                    ))
                    and not init
                    and pre_win_count == post_win_count
                then
                    return
                end

                -- Determine action based on layout state
                local action = should_reinit(
                    p.event,
                    init,
                    pre_win_count,
                    post_win_count,
                    left_cleared,
                    right_cleared,
                    left_id_before,
                    right_id_before
                )

                log.debug(
                    s,
                    "action=%s, new_integration_found=%s, init=%s, pre=%d, post=%d",
                    tostring(action),
                    tostring(new_integration_found),
                    tostring(init),
                    pre_win_count,
                    post_win_count
                )

                if action == "disable" then
                    log.debug(s, "a side window was closed, disabling plugin")
                    api.debounce(s, function()
                        main.disable(s)
                    end)
                elseif action == "init" then
                    local current_win = vim.api.nvim_get_current_win()
                    if
                        not api.is_relative_window(current_win)
                        and not state:is_side_focused("left")
                        and not state:is_side_focused("right")
                    then
                        state:set_previously_focused_win(current_win)
                    end
                    api.debounce(s, main.init)
                elseif new_integration_found and p.event == "WinEnter" then
                    state.tabs[state.active_tab].redraw = false
                    api.debounce(s, ui.create_side_buffers)
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

                local curr_id = state:get_side_id("curr")

                if p.event == "BufDelete" and curr_id and vim.api.nvim_win_is_valid(curr_id) then
                    return
                end

                local refresh = state:scan_layout(s)

                curr_id = state:get_side_id("curr")
                if not curr_id or not vim.api.nvim_win_is_valid(curr_id) then
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

                        -- if we are currently on a side window, splitting here would leak
                        -- side window options to the newly opened window, which would override
                        -- the user's default window options, so we reset them to their initial value
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
                                vim.api.nvim_set_option_value(
                                    opt,
                                    val,
                                    { win = new_win, scope = "local" }
                                )
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

                    local wins = state:get_unregistered_wins(s)
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
                    and (not state:is_side_valid("left") or not state:is_side_valid("right"))
                then
                    log.debug(s, "closed a vsplit when no side buffers were present")

                    return main.init(s)
                end

                if
                    (state:is_side_enabled("left") and not state:is_side_valid("left"))
                    or (state:is_side_enabled("right") and not state:is_side_valid("right"))
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

    local callbacks = helpers.get_config_field("callbacks")
    if callbacks.postEnable ~= nil then
        callbacks.postEnable(state)
    end
end

--- Disables the plugin for the given tab, clear highlight groups and autocmds, closes side buffers and resets the internal state.
---@param scope string: debug/trace identifier for logging (not execution scope) - used in debug output only
---@private
function main.disable(scope)
    local callbacks = helpers.get_config_field("callbacks")
    if callbacks.preDisable ~= nil then
        callbacks.preDisable(state)
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

        if not session_restore_in_progress then
            state:init()
        end
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

    local callbacks = helpers.get_config_field("callbacks")
    if callbacks.postDisable ~= nil then
        callbacks.postDisable(state)
    end
end

return main
