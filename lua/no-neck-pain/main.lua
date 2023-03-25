local A = require("no-neck-pain.util.api")
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
---@private
function N.toggle(scope)
    local tab = Ta.get(S.tabs)

    if tab ~= nil then
        return N.disable(scope)
    end

    return N.enable(scope)
end

--- Toggles the scratchPad feature of the plugin.
---@private
function N.toggleScratchPad()
    local tab = Ta.get(S.tabs)

    if tab == nil then
        return
    end

    -- store the current win to later restore focus
    local currWin = vim.api.nvim_get_current_win()

    -- map over both sides and let the init method either setup or cleanup the side buffers
    for _, side in pairs(Co.SIDES) do
        vim.fn.win_gotoid(tab.wins.main[side])
        W.initScratchPad(side, tab.scratchPadEnabled)
    end

    -- restore focus
    vim.fn.win_gotoid(currWin)

    -- save new state of the scratchpad and update tabs
    tab.scratchPadEnabled = not tab.scratchPadEnabled
    S.tabs = Ta.update(S.tabs, tab.id, tab)

    return S
end

--- Creates side buffers and set the tab state, focuses the `curr` window if required.
---@private
function N.init(scope, tab, goToCurr, skipTrees)
    if tab == nil then
        tab = Ta.get(S.tabs)

        if tab == nil then
            error("called the internal `init` method on a `nil` tab.")
        end
    end

    D.log(scope, "init called on tab %d for current window %d", tab.id, tab.wins.main.curr)

    -- if we do not have side buffers, we must ensure we only trigger a focus if we re-create them
    local hadSideBuffers = true
    if not A.hasSide(tab, "left") or not A.hasSide(tab, "right") then
        hadSideBuffers = false
    end

    tab = W.createSideBuffers(tab, skipTrees)

    if
        goToCurr
        or (not hadSideBuffers and (not A.sideNil(tab, "left") or not A.sideNil(tab, "right")))
        or (A.isCurrentWin(tab.wins.main.left) or A.isCurrentWin(tab.wins.main.right))
    then
        vim.fn.win_gotoid(tab.wins.main.curr)
    end

    S.tabs = Ta.update(S.tabs, tab.id, tab)

    return S
end

--- Initializes the plugin, sets event listeners and internal state.
---@private
function N.enable(scope)
    local tab = Ta.get(S.tabs)

    if E.skipEnable(tab) then
        return nil
    end

    D.log(scope, "calling enable for tab %d", S.activeTab)

    -- register the new tab.
    S.tabs, tab = Ta.insert(S.tabs, S.activeTab)

    local augroupName = string.format("NoNeckPain-%d", S.activeTab)
    tab.augroup = vim.api.nvim_create_augroup(augroupName, { clear = true })

    tab.wins.main.curr = vim.api.nvim_get_current_win()
    tab, _ = Sp.compute(tab, tab.wins.main.curr)

    S = N.init(scope, tab, true)

    S.enabled = true

    vim.api.nvim_create_autocmd({ "VimResized" }, {
        callback = function(p)
            vim.schedule(function()
                if E.skip(tab) then
                    return
                end

                S = N.init(p.event, tab)
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
                if E.skip(tab) then
                    return
                end

                -- there's nothing to manage when there's no side buffer, fallback to vim's default behavior
                if A.sideNil(tab, "right") and A.sideNil(tab, "left") then
                    return D.log(p.event, "skip split logic: no side buffer")
                end

                -- a side tree isn't considered as a split
                if T.isSideTree(vim.api.nvim_buf_get_option(0, "filetype")) then
                    return D.log(p.event, "skip split logic: side tree")
                end

                local focusedWin = vim.api.nvim_get_current_win()
                local wins, total = W.winsExceptState(tab, false)

                if total == 0 or not vim.tbl_contains(wins, focusedWin) then
                    return D.log(p.event, "skip split logic: no new window")
                end

                local isVSplit = true

                tab, isVSplit = Sp.compute(tab, focusedWin)
                tab.wins.splits = tab.wins.splits or {}
                table.insert(tab.wins.splits, { id = focusedWin, vertical = isVSplit })

                if isVSplit then
                    S = N.init(p.event, tab)
                end
            end)
        end,
        group = augroupName,
        desc = "WinEnter covers the split/vsplit management",
    })

    vim.api.nvim_create_autocmd({ "QuitPre", "BufDelete" }, {
        callback = function(p)
            vim.schedule(function()
                if E.skip(nil) then
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
                if E.skip(nil) or tab.wins.splits == nil or W.stateWinsActive(tab, true) then
                    return
                end

                tab.wins.splits = vim.tbl_filter(function(split)
                    if vim.api.nvim_win_is_valid(split.id) then
                        return true
                    end

                    tab.layers = Sp.decreaseLayers(tab.layers, split.vertical)

                    return false
                end, tab.wins.splits)

                if #tab.wins.splits == 0 then
                    tab.wins.splits = nil
                end

                -- we keep track if curr have been closed because if it's the case,
                -- the focus will be on a side buffer which is wrong
                local haveCloseCurr = false

                -- if curr is not valid anymore, we focus the first valid split and remove it from the state
                if not vim.api.nvim_win_is_valid(tab.wins.main.curr) then
                    -- if neither curr and splits are remaining valids, we just disable
                    if tab.wins.splits == nil then
                        return N.disable(p.event)
                    end

                    haveCloseCurr = true

                    tab.layers = Sp.decreaseLayers(tab.layers, tab.wins.splits[1].vertical)

                    tab.wins.main.curr = tab.wins.splits[1].id
                    tab.wins.splits = Sp.remove(tab.wins.splits, tab.wins.splits[1].id)
                end

                -- we only restore focus on curr if there's no split left
                S = N.init(p.event, tab, haveCloseCurr or tab.wins.splits == nil)
            end)
        end,
        group = augroupName,
        desc = "Aims at restoring NNP enable state after closing a split/vsplit buffer or a main buffer",
    })

    vim.api.nvim_create_autocmd({ "WinEnter", "WinClosed" }, {
        callback = function(p)
            vim.schedule(function()
                if E.skip(tab) then
                    return
                end

                local fileType = vim.api.nvim_buf_get_option(0, "filetype")

                -- We can skip enter hooks that are not on a side tree
                if p.event == "WinEnter" and not T.isSideTree(fileType) then
                    return
                end

                -- if a buffer have been closed but we don't have trees in the state
                if
                    p.event == "WinClosed"
                    and vim.tbl_count(W.mergeState(nil, nil, tab.wins.external.trees)) == 0
                then
                    return
                end

                local trees = T.refresh(tab)
                local treesIDs = W.mergeState(nil, nil, trees)

                -- we cycle over supported integrations to see which got closed or opened
                for name, tree in pairs(tab.wins.external.trees) do
                    if
                        -- if we have an id in the state but it's not active anymore
                        (tree.id ~= nil and not vim.tbl_contains(treesIDs, tree.id))
                        -- we have a new tree registered, we can resize
                        or (trees[name].id ~= nil and trees[name].id ~= tree.id)
                    then
                        D.log(p.event, "%s have changed, resizing", name)

                        S = N.init(p.event, tab, false, true)

                        return
                    end
                end
                tab.wins.external.trees = trees
            end)
        end,
        group = augroupName,
        desc = "Resize to apply on WinEnter/Closed of external windows",
    })

    return S
end

--- Disables the plugin for the given tab, clear highlight groups and autocmds, closes side buffers and resets the internal state.
---@private
function N.disable(scope)
    local tab = Ta.get(S.tabs)

    if tab == nil then
        return S
    end

    D.log(scope, "calling disable for tab %d", S.activeTab)

    -- we first remove the tab and reset the state if necessary, so there's no side effects of later actions.
    S.tabs = Ta.remove(S.tabs, tab.id)

    if S.tabs == nil then
        S = Ta.initState()
    end

    vim.api.nvim_del_augroup_by_id(tab.augroup)

    -- shutdowns gracefully by focusing the stored `curr` buffer
    if
        tab.wins.main.curr ~= nil
        and vim.api.nvim_win_is_valid(tab.wins.main.curr)
        and not A.isCurrentWin(tab.wins.main.curr)
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

        if not A.sideNil(tab, side) then
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

    return S
end

return N
