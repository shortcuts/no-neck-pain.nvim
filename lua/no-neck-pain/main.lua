local api = require("no-neck-pain.util.api")
local constants = require("no-neck-pain.util.constants")
local log = require("no-neck-pain.util.log")
local event = require("no-neck-pain.util.event")
local state = require("no-neck-pain.state")
local ui = require("no-neck-pain.ui")

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
        if id ~= nil then
            vim.api.nvim_set_current_win(id)
            ui.init_scratch_pad(side, id, current_state)
        end
    end

    -- restore focus
    vim.api.nvim_set_current_win(state:get_previously_focused_win())

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

    _G.NoNeckPain.config = vim.tbl_deep_extend(
        "keep",
        { buffers = { [side] = { enabled = not _G.NoNeckPain.config.buffers[side].enabled } } },
        _G.NoNeckPain.config
    )

    if not _G.NoNeckPain.config.buffers[side].enabled then
        ui.close_win(scope, state:get_side_id(side), side)
        state:set_side_id(nil, side)
    end

    if
        not (state:is_side_enabled_and_valid("left") or state:is_side_enabled_and_valid("right"))
    then
        _G.NoNeckPain.config = vim.tbl_deep_extend(
            "keep",
            { buffers = { left = { enabled = true }, right = { enabled = true } } },
            _G.NoNeckPain.config
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
    if event.skip_enable(scope) then
        return
    end

    if _G.NoNeckPain.config.callbacks.preEnable ~= nil then
        _G.NoNeckPain.config.callbacks.preEnable(state)
    end

    state:set_active_tab(api.get_current_tab())

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
                    _G.NoNeckPain.state == nil
                    or not _G.NoNeckPain.state.enabled
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
                if not state:is_active_tab_registered() or event.skip() then
                    return
                end

                local init = state:scan_layout(s)

                if
                    not state.tabs[state.active_tab].redraw
                    and (state:is_side_the_active_win("left") or state:is_side_the_active_win(
                        "right"
                    ) or state:is_side_the_active_win("curr"))
                    and not init
                then
                    return
                end

                if init then
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
                    if p.event == "BufDelete" and _G.NoNeckPain.config.fallbackOnBufferDelete then
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

    vim.api.nvim_create_autocmd({ "WinEnter" }, {
        callback = function(p)
            vim.schedule(function()
                p.event = string.format("%s:skip_entering", p.event)
                if not state:is_active_tab_registered() then
                    return log.debug(p.event, "skip")
                end

                if not _G.NoNeckPain.config.autocmds.skipEnteringNoNeckPainBuffer then
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

                vim.api.nvim_set_current_win(new_focus)

                return log.debug(p.event, "rerouted focus of %d to %d", current_side, new_focus)
            end)
        end,
        group = augroup_name,
        desc = "Keeps track of the last focused win, and re-route if necessary",
    })

    state:save()

    if _G.NoNeckPain.config.callbacks.postEnable ~= nil then
        _G.NoNeckPain.config.callbacks.postEnable(state)
    end
end

--- Disables the plugin for the given tab, clear highlight groups and autocmds, closes side buffers and resets the internal state.
---@private
function main.disable(scope)
    if _G.NoNeckPain.config.callbacks.preDisable ~= nil then
        _G.NoNeckPain.config.callbacks.preDisable(state)
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

        pcall(vim.api.nvim_del_augroup_by_name, api.get_augroup_name(active_tab))
        pcall(vim.api.nvim_del_augroup_by_name, "NoNeckPainVimEnterAutocmd")

        return vim.cmd("quitall!")
    end

    pcall(vim.api.nvim_del_augroup_by_name, api.get_augroup_name(active_tab))

    local sides = { left = state:get_side_id("left"), right = state:get_side_id("right") }
    local curr_id = state:get_side_id("curr")

    if state:refresh_tabs(scope, active_tab) == 0 then
        pcall(vim.api.nvim_del_augroup_by_name, "NoNeckPainVimEnterAutocmd")

        log.debug(scope, "no more active tabs left, reinitializing state")

        state:init()
    end

    for side, id in pairs(sides) do
        if vim.api.nvim_win_is_valid(id) then
            state:remove_namespace(vim.api.nvim_win_get_buf(id), side)
            ui.close_win(scope, id, side)
        end
    end

    -- shutdowns gracefully by focusing the stored `curr` buffer
    if curr_id ~= nil and vim.api.nvim_win_is_valid(curr_id) then
        vim.api.nvim_set_current_win(curr_id)

        if _G.NoNeckPain.config.killAllBuffersOnDisable then
            vim.cmd("only")
        end
    end

    state:set_tab_disabled(active_tab)

    state:save()

    if _G.NoNeckPain.config.callbacks.postDisable ~= nil then
        _G.NoNeckPain.config.callbacks.postDisable(state)
    end
end

return main
