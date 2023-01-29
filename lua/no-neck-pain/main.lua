local Co = require("no-neck-pain.util.constants")
local D = require("no-neck-pain.util.debug")
local E = require("no-neck-pain.util.event")
local Sp = require("no-neck-pain.splits")
local T = require("no-neck-pain.trees")
local Ta = require("no-neck-pain.tabs")
local W = require("no-neck-pain.wins")

local N = {}
local S = Ta.initState()

-- Toggle the plugin by calling the `enable`/`disable` methods respectively.
function N.toggle(scope)
    local tab = Ta.get(S.tabs)

    if tab ~= nil then
        return N.disable(scope)
    end

    return N.enable(scope)
end

-- Creates side buffers and set the tab state, focuses the `curr` window if required.
local function init(scope, tab, goToCurr)
    D.log(scope, "init called on tab %d for current window %d", tab.id, tab.wins.main.curr)

    -- if we do not have side buffers, we must ensure we only trigger a focus if we re-create them
    local hadSideBuffers = true
    if
        (tab.wins.main.left == nil and _G.NoNeckPain.config.buffers.left.enabled)
        or (tab.wins.main.right == nil and _G.NoNeckPain.config.buffers.right.enabled)
    then
        hadSideBuffers = false
    end

    tab = W.createSideBuffers(tab)

    if
        goToCurr
        or (not hadSideBuffers and (tab.wins.main.left ~= nil or tab.wins.main.right ~= nil))
    then
        vim.fn.win_gotoid(tab.wins.main.curr)
    end
end

-- Initializes the plugin, sets event listeners and internal state.
function N.enable(scope)
    local tab = Ta.get(S.tabs)

    -- skip if we already have a state for the current tab.
    if S.enabled and tab ~= nil then
        return S
    end

    D.log(scope, "calling enable for tab %d", S.activeTab)

    -- register the new tab.
    S.tabs, tab = Ta.insert(S.tabs, S.activeTab)

    local augroupName = string.format("NoNeckPain-%d", S.activeTab)
    tab.augroup = vim.api.nvim_create_augroup(augroupName, { clear = true })

    tab.wins.main.curr = vim.api.nvim_get_current_win()
    tab.wins.splits = Sp.get(tab)

    init(scope, tab, true)

    vim.api.nvim_create_autocmd({ "VimResized" }, {
        callback = function(p)
            vim.schedule(function()
                if E.skip(tab, false) then
                    return
                end

                init(p.event, tab)
            end)
        end,
        group = augroupName,
        desc = "Resizes side windows after terminal has been resized, closes them if not enough space left.",
    })

    vim.api.nvim_create_autocmd({ "TabLeave" }, {
        callback = function()
            vim.schedule(function()
                S.activeTab = Ta.refresh(S.activeTab)
            end)
        end,
        group = augroupName,
        desc = "Refreshes the active tab state",
    })

    vim.api.nvim_create_autocmd({ "WinEnter" }, {
        callback = function(p)
            vim.schedule(function()
                if E.skip(tab, false) then
                    return
                end

                local focusedWin = vim.api.nvim_get_current_win()
                local wins, total = W.winsExceptState(tab, false)

                if total == 0 or not vim.tbl_contains(wins, focusedWin) then
                    return
                end

                -- we skip side trees etc. as they are not part of the split manager.
                local fileType = vim.api.nvim_buf_get_option(0, "filetype")
                if T.isSideTree(fileType) then
                    return D.log(p.event, "encountered an external window")
                end

                -- note: due to floor, side widths might be off by 1 on each side buffer so we add it
                local width = vim.api.nvim_win_get_width(focusedWin)
                for _, side in pairs(Co.SIDES) do
                    if tab.wins.main[side] and _G.NoNeckPain.config.buffers[side].enabled then
                        width = width + 1
                    end
                end

                local vsplit = width < _G.NoNeckPain.config.width

                D.log(
                    p.event,
                    "new split window found [%d / %d] = %s",
                    width,
                    _G.NoNeckPain.config.width,
                    vsplit
                )

                tab.wins.splits = Sp.insert(tab.wins.splits, focusedWin, vsplit)

                if vsplit then
                    init(p.event, tab)
                end
            end)
        end,
        group = augroupName,
        desc = "WinEnter covers the split/vsplit management",
    })

    vim.api.nvim_create_autocmd({ "QuitPre", "BufDelete" }, {
        callback = function(p)
            vim.schedule(function()
                if E.skip(nil, false) then
                    return
                end

                -- if we are not in split view, we check if we killed one of the main buffers (curr, left, right) to disable NNP
                if tab.wins.splits == nil and not W.stateWinsActive(tab, false) then
                    D.log(p.event, "one of the NNP main buffers have been closed, disabling...")

                    return N.disable(p.event)
                end

                if _G.NoNeckPain.config.disableOnLastBuffer then
                    local _, remaining = W.winsExceptState(tab, true)

                    if
                        remaining == 0
                        and vim.api.nvim_buf_get_option(0, "buftype") == ""
                        and vim.api.nvim_buf_get_option(0, "filetype") == ""
                        and vim.api.nvim_buf_get_option(0, "bufhidden") == "wipe"
                    then
                        D.log(p.event, "found last `wipe` buffer in list, disabling...")

                        return N.disable(p.event)
                    end
                end
            end)
        end,
        group = augroupName,
        desc = "Handles the closure of main NNP windows",
    })

    vim.api.nvim_create_autocmd({ "WinClosed", "BufDelete" }, {
        callback = function(p)
            vim.schedule(function()
                if E.skip(nil, false) or tab.wins.splits == nil or W.stateWinsActive(tab, true) then
                    return
                end

                tab.wins.splits = Sp.refresh(tab.wins.splits)

                -- if curr is not valid anymore, we focus the first valid split and remove it from the state
                if not vim.api.nvim_win_is_valid(tab.wins.main.curr) then
                    -- if neither curr and splits are remaining valids, we just disable
                    if tab.wins.splits == nil then
                        return N.disable(p.event)
                    end

                    tab.wins.main.curr = tab.wins.splits[1].id
                    tab.wins.splits = Sp.remove(tab.wins.splits, tab.wins.splits[1].id)
                end

                -- we only restore focus on curr if there's no split left
                init(p.event, tab, tab.wins.splits == nil)
            end)
        end,
        group = augroupName,
        desc = "Aims at restoring NNP enable state after closing a split/vsplit buffer or a main buffer",
    })

    vim.api.nvim_create_autocmd({ "WinEnter", "WinClosed" }, {
        callback = function(p)
            vim.schedule(function()
                if E.skip(tab, true) then
                    return
                end

                local focusedWin = vim.api.nvim_get_current_win()
                local wins, total = W.winsExceptState(tab, false)

                if total == 0 or not vim.tbl_contains(wins, focusedWin) then
                    return
                end

                local trees = T.refresh(tab)

                -- we cycle over supported integrations to see which got closed or opened
                for name, tree in pairs(tab.wins.external.trees) do
                    -- if there was a tree[name] but not anymore, we resize
                    if tree ~= nil and tree.id ~= nil and not vim.tbl_contains(wins, tree.id) then
                        D.log(p.event, "%s have been closed, resizing", name)

                        return init(p.event, tab)
                    end

                    -- we have a new tree registered, we can resize
                    if trees[name].id ~= tab.wins.external.trees[name].id then
                        D.log(p.event, "%s have been opened, resizing", name)

                        return init(p.event, tab)
                    end
                end
                tab.wins.external.trees = trees
            end)
        end,
        group = augroupName,
        desc = "Resize to apply on WinEnter/Closed of external windows",
    })

    S.enabled = true

    return S
end

-- Disables the plugin for the given tab, clear highlight groups and autocmds, closes side buffers and resets the internal state.
function N.disable(scope)
    local tab = Ta.get(S.tabs)

    if not S.enabled or tab == nil then
        return S
    end

    vim.api.nvim_del_augroup_by_id(tab.augroup)

    -- shutdowns gracefully by focusing the stored `curr` buffer
    if
        tab.wins.main.curr ~= nil
        and vim.api.nvim_win_is_valid(tab.wins.main.curr)
        and tab.wins.main.curr ~= vim.api.nvim_get_current_win()
    then
        vim.fn.win_gotoid(tab.wins.main.curr)

        if _G.NoNeckPain.config.killAllBuffersOnDisable then
            vim.cmd("only")
        end
    end

    -- determine if we should quit vim or just close the window
    for _, side in pairs(Co.SIDES) do
        vim.cmd(
            string.format(
                "highlight! clear NoNeckPain_background_tab_%s_side_%s NONE",
                tab.id,
                side
            )
        )
        vim.cmd(string.format("highlight! clear NoNeckPain_text_tab_%s_side_%s NONE", tab.id, side))

        if tab.wins.main[side] ~= nil then
            local activeWins = vim.api.nvim_tabpage_list_wins(tab.id)
            local haveOtherWins = false

            -- if we have other wins active and usable, we won't quit vim
            for _, activeWin in pairs(activeWins) do
                if tab.wins.main[side] ~= activeWin and not W.isRelativeWindow(activeWin) then
                    haveOtherWins = true
                end
            end

            -- we don't have any window left if we close this one
            if not haveOtherWins then
                -- either triggered by a :wq or quit event, we can just quit
                if scope == "QuitPre" then
                    return vim.cmd("quit!")
                end

                -- mostly triggered by :bd or similar
                -- we will create a new window and close the other
                vim.cmd("new")
            end

            -- when we have more than 1 window left, we can just close it
            W.close(scope, tab.wins.main[side], side)
        end
    end

    S.tabs = Ta.remove(S.tabs, tab.id)

    if S.tabs == nil then
        S = Ta.initState()
    end

    return S
end

return N
