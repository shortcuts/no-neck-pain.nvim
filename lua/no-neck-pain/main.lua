local A = require("no-neck-pain.util.api")
local Co = require("no-neck-pain.util.constants")
local D = require("no-neck-pain.util.debug")
local E = require("no-neck-pain.util.event")
local S = require("no-neck-pain.state")
local W = require("no-neck-pain.wins")

local N = {}

-- Toggle the plugin by calling the `enable`/`disable` methods respectively.
--
--- @param scope string: internal identifier for logging purposes.
---@private
function N.toggle(scope)
    if S.has_tabs(S) and S.is_active_tab_registered(S) then
        return N.disable(scope)
    end

    N.enable(scope)
end

--- Toggles the scratchpad feature of the plugin.
---@private
function N.toggle_scratchpad()
    if not S.is_active_tab_registered(S) then
        return
    end

    -- store the current win to later restore focus
    local curr_win = vim.api.nvim_get_current_win()
    local current_state = S.tabs[S.active_tab].scratchpad_enabled

    -- save new state of the scratchpad and update tabs
    S.set_scratchpad(S, not current_state)

    -- map over both sides and let the init method either setup or cleanup the side buffers
    for _, side in pairs(Co.SIDES) do
        local id = S.get_side_id(S, side)
        if id ~= nil then
            vim.api.nvim_set_current_win(id)
            W.init_scratchpad(side, id, current_state)
        end
    end

    -- restore focus
    vim.api.nvim_set_current_win(curr_win)

    S.save(S)
end

--- Toggles the config `${side}.enabled` and re-inits the plugin.
---
--- @param scope string: internal identifier for logging purposes.
--- @param side "left" | "right": the side to toggle.
---@private
function N.toggle_side(scope, side)
    if not S.is_active_tab_registered(S) then
        D.log(scope, "skipped because the current tab is not registered")

        return S.save(S)
    end

    _G.NoNeckPain.config = vim.tbl_deep_extend(
        "keep",
        { buffers = { [side] = { enabled = not _G.NoNeckPain.config.buffers[side].enabled } } },
        _G.NoNeckPain.config
    )

    if not _G.NoNeckPain.config.buffers[side].enabled then
        W.close(scope, S.get_side_id(S, side), side)
        S.set_side_id(S, nil, side)
    end

    if not S.check_sides(S, "or", true) then
        _G.NoNeckPain.config = vim.tbl_deep_extend(
            "keep",
            { buffers = { left = { enabled = true }, right = { enabled = true } } },
            _G.NoNeckPain.config
        )

        return N.disable(scope)
    end

    S.scan_layout(S, scope)

    N.init(scope)
end

--- Creates side buffers and set the tab state, focuses the `curr` window if required.
--- @param scope string: internal identifier for logging purposes.
--- @param go_to_curr boolean?: whether we should re-focus the `curr` window.
---@private
function N.init(scope, go_to_curr)
    if not S.is_active_tab_registered(S) then
        error("called the internal `init` method on a `nil` tab.")
    end

    D.log(
        scope,
        "init called on tab %d for current window %d",
        S.active_tab,
        S.get_side_id(S, "curr")
    )

    -- if we do not have side buffers, we must ensure we only trigger a focus if we re-create them
    local had_side_buffers = true
    if not S.is_side_win_valid(S, "left") or not S.is_side_win_valid(S, "right") then
        had_side_buffers = false
    end

    W.create_side_buffers()

    if S.consume_redraw(S) then
        W.reposition(string.format("%s:consume_redraw", scope))
    end

    if
        go_to_curr
        or (not had_side_buffers and S.check_sides(S, "or", true))
        or (S.is_side_the_active_win(S, "left") or S.is_side_the_active_win(S, "right"))
    then
        D.log(scope, "re-routing focus to curr")

        vim.api.nvim_set_current_win(S.get_side_id(S, "curr"))
    end

    -- if we still have side buffers open at this point, and we have vsplit opened,
    -- there might be width issues so we the resize opened vsplits.
    if S.check_sides(S, "or", true) and S.get_columns(S) > 1 then
        D.log("wins_resize", "have %d columns", S.get_columns(S))

        for _, win in pairs(S.get_unregistered_wins(S)) do
            W.resize(win, _G.NoNeckPain.config.width, string.format("win:%d", win))
        end

        if not had_side_buffers then
            W.resize(
                S.get_side_id(S, "curr"),
                _G.NoNeckPain.config.width,
                string.format("win:%d", S.get_side_id(S, "curr"))
            )
        end
    end

    S.save(S)
end

--- Initializes the plugin, sets event listeners and internal state.
---
--- @param scope string: internal identifier for logging purposes.
---@private
function N.enable(scope)
    if E.skip_enable() then
        return
    end

    D.log(scope, "calling enable for tab %d", A.get_current_tab())

    S.set_enabled(S)
    S.set_tab(S, A.get_current_tab())

    local augroup_name = A.get_augroup_name(S.active_tab)
    vim.api.nvim_create_augroup(augroup_name, { clear = true })

    S.set_side_id(S, vim.api.nvim_get_current_win(), "curr")
    S.scan_layout(S, scope)
    N.init(scope, true)
    S.scan_layout(S, scope)

    vim.api.nvim_create_autocmd({ "VimResized" }, {
        callback = function(p)
            vim.schedule(function()
                if _G.NoNeckPain.state == nil or not _G.NoNeckPain.state.enabled then
                    return
                end

                local tab = S.get_tab(S)

                if tab ~= nil then
                    if A.get_current_tab() ~= tab.id then
                        return
                    end
                end

                N.init(p.event)
            end)
        end,
        group = augroup_name,
        desc = "Resizes side windows after terminal has been resized, closes them if not enough space left.",
    })

    vim.api.nvim_create_autocmd({ "TabEnter" }, {
        callback = function(p)
            A.debounce(p.event, function()
                D.log(p.event, "tab %d entered", S.active_tab)

                S.refresh_tabs(S, p.event)

                S.set_active_tab(S, A.get_current_tab())
            end)
        end,
        group = augroup_name,
        desc = "Keeps track of the currently active tab and the tab state",
    })

    vim.api.nvim_create_autocmd({ "WinEnter", "WinClosed" }, {
        callback = function(p)
            local s = string.format("%s:%d", p.event, vim.api.nvim_get_current_win())
            vim.schedule(function()
                if not S.is_active_tab_registered(S) or E.skip() then
                    return
                end

                local init = S.scan_layout(S, s)

                if
                    not S.tabs[S.active_tab].redraw
                    and (
                        S.is_side_the_active_win(S, "left")
                        or S.is_side_the_active_win(S, "right")
                        or S.is_side_the_active_win(S, "curr")
                    )
                then
                    return
                end

                if init then
                    A.debounce(s, function()
                        return N.init(s)
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
                if not S.is_active_tab_registered(S) or E.skip() then
                    return
                end

                if
                    p.event == "BufDelete" and vim.api.nvim_win_is_valid(S.get_side_id(S, "curr"))
                then
                    return
                end

                local refresh = S.scan_layout(S, s)

                if not vim.api.nvim_win_is_valid(S.get_side_id(S, "curr")) then
                    if p.event == "Buf_delete" and _G.NoNeckPain.config.fallbackOnBufferDelete then
                        D.log(s, "`curr` has been deleted, resetting state")

                        vim.cmd("new")

                        N.disable(string.format("%s:reset", s))
                        N.enable(string.format("%s:reset", s))

                        return
                    end

                    local wins = S.get_unregistered_wins(S)
                    if #wins == 0 then
                        D.log(s, "no active windows found")

                        return N.disable(s)
                    end

                    S.set_side_id(S, wins[1], "curr")

                    D.log(s, "re-routing to %d", wins[1])

                    return N.init(s, true)
                end

                if
                    p.event == "QuitPre"
                    and not S.is_side_win_valid(S, "left")
                    and not S.is_side_win_valid(S, "right")
                then
                    D.log(s, "closed a vsplit when no side buffers were present")

                    return N.init(s)
                end

                if
                    (S.is_side_enabled(S, "left") and not S.is_side_win_valid(S, "left"))
                    or (S.is_side_enabled(S, "right") and not S.is_side_win_valid(S, "right"))
                then
                    D.log(s, "one of the NNP side has been closed")

                    return N.disable(s)
                end

                if refresh then
                    return N.init(s)
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
                    p.event = string.format("%s:skip_entering_NoNeckPain_buffer", p.event)
                    if not S.is_active_tab_registered(S) or E.skip() or S.get_scratchpad(S) then
                        return D.log(p.event, "skip")
                    end

                    local current_win = vim.api.nvim_get_current_win()
                    local left_id = S.get_side_id(S, "left")
                    local right_id = S.get_side_id(S, "right")

                    if current_win ~= left_id and current_win ~= right_id then
                        return
                    end

                    local wins = vim.api.nvim_list_wins()

                    for i = 1, #wins do
                        local id = i == #wins and 1 or i + 1
                        if
                            wins[id] ~= current_win
                            and wins[id] ~= left_id
                            and wins[id] ~= right_id
                        then
                            vim.api.nvim_set_current_win(wins[id])

                            return D.log(
                                p.event,
                                "rerouted focus of %d to %d",
                                current_win,
                                wins[id]
                            )
                        end
                    end
                end)
            end,
            group = augroup_name,
            desc = "Entering a no-neck-pain side buffer skips to the next available buffer",
        })
    end

    S.save(S)
end

--- Disables the plugin for the given tab, clear highlight groups and autocmds, closes side buffers and resets the internal state.
---@private
function N.disable(scope)
    local active_tab = S.active_tab

    D.log(scope, "calling disable for tab %d", active_tab)

    local wins = vim.tbl_filter(function(win)
        return win ~= S.get_side_id(S, "left")
            and win ~= S.get_side_id(S, "right")
            and not A.is_relative_window(win)
    end, vim.api.nvim_tabpage_list_wins(active_tab))

    if #vim.api.nvim_list_tabpages() == 1 and #wins == 0 then
        for name, modified in pairs(A.get_opened_buffers()) do
            if modified then
                local bufname = name
                if vim.startswith(name, "NoNeckPain") then
                    bufname = string.sub(name, 11)
                end

                vim.schedule(function()
                    vim.notify(
                        "[no-neck-pain.nvim] unable to quit nvim because one or more buffer has modified files, please save or discard changes",
                        vim.log.levels.ERROR
                    )
                    vim.cmd("rightbelow vertical split")
                    vim.cmd("buffer " .. bufname)
                    N.init(scope)
                end)
                return
            end
        end

        pcall(vim.api.nvim_del_augroup_by_name, A.get_augroup_name(active_tab))
        pcall(vim.api.nvim_del_augroup_by_name, "NoNeckPainVimEnterAutocmd")

        return vim.cmd("quitall!")
    end

    pcall(vim.api.nvim_del_augroup_by_name, A.get_augroup_name(active_tab))

    local sides = { left = S.get_side_id(S, "left"), right = S.get_side_id(S, "right") }
    local curr_id = S.get_side_id(S, "curr")

    if S.refresh_tabs(S, scope, active_tab) == 0 then
        pcall(vim.api.nvim_del_augroup_by_name, "NoNeckPainVimEnterAutocmd")

        D.log(scope, "no more active tabs left, reinitializing state")

        S.init(S)
    end

    for side, id in pairs(sides) do
        if vim.api.nvim_win_is_valid(id) then
            S.remove_namespace(S, vim.api.nvim_win_get_buf(id), side)
            W.close(scope, id, side)
        end
    end

    -- shutdowns gracefully by focusing the stored `curr` buffer
    if curr_id ~= nil and vim.api.nvim_win_is_valid(curr_id) then
        vim.api.nvim_set_current_win(curr_id)

        if _G.NoNeckPain.config.killAllBuffersOnDisable then
            vim.cmd("only")
        end
    end

    S.save(S)
end

return N
