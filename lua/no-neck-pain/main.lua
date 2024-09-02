local api = require("no-neck-pain.util.api")
local constants = require("no-neck-pain.util.constants")
local log = require("no-neck-pain.util.debug")
local event = require("no-neck-pain.util.event")
local state = require("no-neck-pain.state")
local ui = require("no-neck-pain.ui")

local main = {}

-- Toggle the plugin by calling the `enable`/`disable` methods respectively.
--
---@param scope string: internal identifier for logging purposes.
---@private
function main.toggle(scope)
    if state.has_tabs(state) and state.is_active_tab_registered(state) then
        return main.disable(scope)
    end

    main.enable(scope)
end

--- Toggles the scratchPad feature of the plugin.
---@private
function main.toggle_scratchPad()
    if not state.is_active_tab_registered(state) then
        return
    end

    -- store the current win to later restore focus
    local curr_win = vim.api.nvim_get_current_win()
    local current_state = state.tabs[state.active_tab].scratchpad_enabled

    -- save new state of the scratchPad and update tabs
    state.set_scratchPad(state, not current_state)

    -- map over both sides and let the init method either setup or cleanup the side buffers
    for _, side in pairs(constants.SIDES) do
        local id = state.get_side_id(state, side)
        if id ~= nil then
            vim.api.nvim_set_current_win(id)
            ui.init_scratchPad(side, id, current_state)
        end
    end

    -- restore focus
    vim.api.nvim_set_current_win(curr_win)

    state.save(state)
end

--- Toggles the config `${side}.enabled` and re-inits the plugin.
---
---@param scope string: internal identifier for logging purposes.
---@param side "left" | "right": the side to toggle.
---@private
function main.toggle_side(scope, side)
    if not state.is_active_tab_registered(state) then
        log.debug(scope, "skipped because the current tab is not registered")

        return state.save(state)
    end

    _G.NoNeckPain.config = vim.tbl_deep_extend(
        "keep",
        { buffers = { [side] = { enabled = not _G.NoNeckPain.config.buffers[side].enabled } } },
        _G.NoNeckPain.config
    )

    if not _G.NoNeckPain.config.buffers[side].enabled then
        ui.close_win(scope, state.get_side_id(state, side), side)
        state.set_side_id(state, nil, side)
    end

    if not state.check_sides(state, "or", true) then
        _G.NoNeckPain.config = vim.tbl_deep_extend(
            "keep",
            { buffers = { left = { enabled = true }, right = { enabled = true } } },
            _G.NoNeckPain.config
        )

        return main.disable(scope)
    end

    state.scan_layout(state, scope)

    main.init(scope)
end

--- Creates side buffers and set the tab state, focuses the `curr` window if required.
---@param scope string: internal identifier for logging purposes.
---@param go_to_curr boolean?: whether we should re-focus the `curr` window.
---@private
function main.init(scope, go_to_curr)
    if not state.is_active_tab_registered(state) then
        error("called the internal `init` method on a `nil` tab.")
    end

    log.debug(
        scope,
        "init called on tab %d for current window %d",
        state.active_tab,
        state.get_side_id(state, "curr")
    )

    -- if we do not have side buffers, we must ensure we only trigger a focus if we re-create them
    local had_side_buffers = true
    if
        not state.is_side_enabled_or_valid(state, "left")
        or not state.is_side_enabled_or_valid(state, "right")
    then
        had_side_buffers = false
    end

    ui.create_side_buffers()

    if state.consume_redraw(state) then
        ui.move_sides(string.format("%s:consume_redraw", scope))
    end

    if
        go_to_curr
        or (not had_side_buffers and state.check_sides(state, "or", true))
        or (
            state.is_side_the_active_win(state, "left")
            or state.is_side_the_active_win(state, "right")
        )
    then
        log.debug(scope, "re-routing focus to curr")

        vim.api.nvim_set_current_win(state.get_side_id(state, "curr"))
    end

    -- if we still have side buffers open at this point, and we have vsplit opened,
    -- there might be width issues so we the resize_win opened vsplits.
    if state.check_sides(state, "or", true) and state.get_columns(state) > 1 then
        log.debug("resize_win", "have %d columns", state.get_columns(state))

        for _, win in pairs(state.get_unregistered_wins(state)) do
            ui.resize_win(win, _G.NoNeckPain.config.width, string.format("win:%d", win))
        end

        if not had_side_buffers then
            ui.resize_win(
                state.get_side_id(state, "curr"),
                _G.NoNeckPain.config.width,
                string.format("win:%d", state.get_side_id(state, "curr"))
            )
        end
    end

    state.save(state)
end

--- Initializes the plugin, sets event listeners and internal state.
---
---@param scope string: internal identifier for logging purposes.
---@private
function main.enable(scope)
    if event.skip_enable(scope) then
        return
    end

    log.debug(scope, "calling enable for tab %d", api.get_current_tab())

    state.set_enabled(state)
    state.set_tab(state, api.get_current_tab())

    local augroup_name = api.get_augroup_name(state.active_tab)
    vim.api.nvim_create_augroup(augroup_name, { clear = true })

    state.set_side_id(state, vim.api.nvim_get_current_win(), "curr")
    state.scan_layout(state, scope)
    main.init(scope, true)
    state.scan_layout(state, scope)

    vim.api.nvim_create_autocmd({ "VimResized" }, {
        callback = function(p)
            vim.schedule(function()
                if _G.NoNeckPain.state == nil or not _G.NoNeckPain.state.enabled then
                    return
                end

                local tab = state.get_tab(state)

                if tab ~= nil then
                    if api.get_current_tab() ~= tab.id then
                        return
                    end
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
                log.debug(p.event, "tab %d entered", state.active_tab)

                state.refresh_tabs(state, p.event)

                state.set_active_tab(state, api.get_current_tab())
            end)
        end,
        group = augroup_name,
        desc = "Keeps track of the currently active tab and the tab state",
    })

    vim.api.nvim_create_autocmd({ "WinEnter", "WinClosed" }, {
        callback = function(p)
            local s = string.format("%s:%d", p.event, vim.api.nvim_get_current_win())
            vim.schedule(function()
                if not state.is_active_tab_registered(state) or event.skip() then
                    return
                end

                local init = state.scan_layout(state, s)

                if
                    not state.tabs[state.active_tab].redraw
                    and (
                        state.is_side_the_active_win(state, "left")
                        or state.is_side_the_active_win(state, "right")
                        or state.is_side_the_active_win(state, "curr")
                    )
                then
                    return
                end

                if init then
                    api.debounce(s, function()
                        return main.init(s)
                    end)
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
                if not state.is_active_tab_registered(state) or event.skip() then
                    return
                end

                if
                    p.event == "BufDelete"
                    and vim.api.nvim_win_is_valid(state.get_side_id(state, "curr"))
                then
                    return
                end

                local refresh = state.scan_layout(state, s)

                if not vim.api.nvim_win_is_valid(state.get_side_id(state, "curr")) then
                    if p.event == "BufDelete" and _G.NoNeckPain.config.fallbackOnBufferDelete then
                        log.debug(s, "`curr` has been deleted, resetting state")

                        local opened_buffers = api.get_opened_buffers()

                        vim.cmd("rightbelow vertical split")

                        if vim.tbl_count(opened_buffers) > 0 then
                            local bufname, _ = next(opened_buffers)

                            vim.cmd("buffer " .. bufname)
                            log.debug(s, "fallback to %s", bufname)
                        end

                        main.disable(string.format("%s:reset", s))
                        main.enable(string.format("%s:reset", s))

                        return
                    end

                    local wins = state.get_unregistered_wins(state)
                    if #wins == 0 then
                        log.debug(s, "no active windows found")

                        return main.disable(s)
                    end

                    state.set_side_id(state, wins[1], "curr")

                    log.debug(s, "re-routing to %d", wins[1])

                    return main.init(s, true)
                end

                if
                    p.event == "QuitPre"
                    and not state.is_side_enabled_and_valid(state, "left")
                    and not state.is_side_enabled_and_valid(state, "right")
                then
                    log.debug(s, "closed a vsplit when no side buffers were present")

                    return main.init(s)
                end

                if
                    (
                        state.is_side_enabled(state, "left")
                        and not state.is_side_enabled_and_valid(state, "left")
                    )
                    or (
                        state.is_side_enabled(state, "right")
                        and not state.is_side_enabled_and_valid(state, "right")
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

    if _G.NoNeckPain.config.autocmds.skipEnteringNoNeckPainBuffer then
        vim.api.nvim_create_autocmd({ "WinLeave" }, {
            callback = function(p)
                vim.schedule(function()
                    p.event = string.format("%s:skip_entering", p.event)
                    if
                        not state.is_active_tab_registered(state)
                        or event.skip()
                        or state.get_scratchPad(state)
                    then
                        return log.debug(p.event, "skip")
                    end

                    local current_side = vim.api.nvim_get_current_win()
                    local other_side = state.get_side_id(state, "right")
                    local left_id = state.get_side_id(state, "left")
                    local right_id = state.get_side_id(state, "right")

                    if current_side == left_id then
                        other_side = right_id
                    elseif current_side == right_id then
                        other_side = left_id
                    else
                        state.set_previously_focused_win(state, vim.api.nvim_get_current_win())
                        return
                    end

                    -- we need to know if the user navigates from ltr or rtl
                    -- so we keep track of the encounter of prev,curr to determine
                    -- the next valid window to focus

                    local wins = vim.api.nvim_list_wins()
                    local idx

                    for i = 1, #wins do
                        if api.is_side_id(current_side, wins[i]) then
                            local j = i - 1 < 1 and #wins or i - 1
                            while true do
                                if
                                    not api.is_side_id(current_side, wins[j])
                                    and not api.is_side_id(other_side, wins[j])
                                then
                                    idx = j
                                    break
                                end
                                j = j == 1 and #wins or j - 1
                            end
                            break
                        elseif api.is_side_id(state.get_previously_focused_win(state), wins[i]) then
                            local j = i + 1 > #wins and 1 or i + 1
                            while true do
                                if
                                    not api.is_side_id(current_side, wins[j])
                                    and not api.is_side_id(other_side, wins[j])
                                then
                                    idx = j
                                    break
                                end
                                j = j == #wins and 1 or j + 1
                            end
                            break
                        end
                    end

                    if idx then
                        vim.api.nvim_set_current_win(wins[idx])

                        return log.debug(
                            p.event,
                            "rerouted focus of %d to %d",
                            current_side,
                            wins[idx]
                        )
                    end
                end)
            end,
            group = augroup_name,
            desc = "Entering a no-neck-pain side buffer skips to the next available buffer",
        })
    end

    state.save(state)
end

--- Disables the plugin for the given tab, clear highlight groups and autocmds, closes side buffers and resets the internal state.
---@private
function main.disable(scope)
    local active_tab = state.active_tab

    log.debug(scope, "calling disable for tab %d", active_tab)

    local wins = vim.tbl_filter(function(win)
        return win ~= state.get_side_id(state, "left")
            and win ~= state.get_side_id(state, "right")
            and not api.is_relative_window(win)
    end, vim.api.nvim_tabpage_list_wins(active_tab))

    if #vim.api.nvim_list_tabpages() == 1 and #wins == 0 then
        for name, modified in pairs(api.get_opened_buffers()) do
            if modified then
                local bufname = name
                if vim.startswith(name, "NoNamePain") then
                    bufname = string.sub(name, 11)
                end

                vim.schedule(function()
                    vim.notify(
                        "[no-neck-pain.nvim] unable to quit nvim because one or more buffer has modified files, please save or discard changes",
                        vim.log.levels.ERROR
                    )
                    vim.cmd("rightbelow vertical split")
                    vim.cmd("buffer " .. bufname)
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

    local sides =
        { left = state.get_side_id(state, "left"), right = state.get_side_id(state, "right") }
    local curr_id = state.get_side_id(state, "curr")

    if state.refresh_tabs(state, scope, active_tab) == 0 then
        pcall(vim.api.nvim_del_augroup_by_name, "NoNeckPainVimEnterAutocmd")

        log.debug(scope, "no more active tabs left, reinitializing state")

        state.init(state)
    end

    for side, id in pairs(sides) do
        if vim.api.nvim_win_is_valid(id) then
            state.remove_namespace(state, vim.api.nvim_win_get_buf(id), side)
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

    state.set_tab_disabled(state, active_tab)

    state.save(state)
end

return main
