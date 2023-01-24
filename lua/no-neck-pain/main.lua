local D = require("no-neck-pain.util.debug")
local E = require("no-neck-pain.util.event")
local M = require("no-neck-pain.util.map")
local W = require("no-neck-pain.util.win")
local T = require("no-neck-pain.util.trees")
local Sp = require("no-neck-pain.util.split")
local St = require("no-neck-pain.util.state")

local N = {}

-- state
local S = St.init()

-- Toggle the plugin by calling the `enable`/`disable` methods respectively.
function N.toggle()
    if S.enabled then
        return N.disable("N.toggle")
    end

    return N.enable()
end

-- Creates side buffers and set the internal state considering potential external trees.
local function init(scope, goToCurr)
    D.log(scope, "init called, %d is the current window", S.wins.main.curr)

    -- if we do not have side buffers, we must ensure we only trigger a focus if we re-create them
    local hadSideBuffers = true
    if
        (S.wins.main.left == nil and _G.NoNeckPain.config.buffers.left.enabled)
        or (S.wins.main.right == nil and _G.NoNeckPain.config.buffers.right.enabled)
    then
        hadSideBuffers = false
    end

    -- before creating side buffers, we determine if we should consider externals
    S.wins.external.trees = T.refresh()
    S.wins.main.left, S.wins.main.right = W.createSideBuffers(S.wins)
    -- we might have closed trees during the buffer creation process, we re-fetch the latest IDs to prevent inconsistencies
    S.wins.external.trees = T.refresh()

    if
        goToCurr or (not hadSideBuffers and (S.wins.main.left ~= nil or S.wins.main.right ~= nil))
    then
        vim.fn.win_gotoid(S.wins.main.curr)
    end
end

-- Initializes the plugin, sets event listeners and internal state.
function N.enable()
    if S.enabled then
        return S
    end

    S.augroup = vim.api.nvim_create_augroup("NoNeckPain", {
        clear = true,
    })

    S.wins.main.curr = vim.api.nvim_get_current_win()
    S.wins.splits = Sp.get(S.wins)

    init("enable", true)

    vim.api.nvim_create_autocmd({ "VimResized" }, {
        callback = function(p)
            vim.schedule(function()
                if E.skip(S, false) then
                    return
                end

                init(p.event)
            end)
        end,
        group = "NoNeckPain",
        desc = "Resizes side windows after terminal has been resized, closes them if not enough space left.",
    })

    vim.api.nvim_create_autocmd({ "WinEnter" }, {
        callback = function(p)
            vim.schedule(function()
                if E.skip(S, false) then
                    return
                end

                local focusedWin = vim.api.nvim_get_current_win()
                local wins, total = W.winsExceptState(S.wins, false)

                if total == 0 or not M.contains(wins, focusedWin) then
                    return
                end

                -- we skip side trees etc. as they are not part of the split manager.
                local fileType = vim.api.nvim_buf_get_option(0, "filetype")
                if T.isSideTree(fileType) then
                    return D.log(p.event, "encountered an external window")
                end

                -- -- note: due to floor, side widths might be off by 1, so we add it
                local width = vim.api.nvim_win_get_width(focusedWin) + 1
                local vsplit = width < _G.NoNeckPain.config.width

                D.log(
                    p.event,
                    "new split window found [%d / %d] = %s",
                    width,
                    _G.NoNeckPain.config.width,
                    vsplit
                )

                S.wins.splits = Sp.insert(S.wins.splits, focusedWin, vsplit)

                if vsplit then
                    init(p.event)
                end
            end)
        end,
        group = "NoNeckPain",
        desc = "WinEnter covers the split/vsplit management",
    })

    vim.api.nvim_create_autocmd({ "QuitPre", "BufDelete" }, {
        callback = function(p)
            vim.schedule(function()
                if E.skip(nil, false) then
                    return
                end

                -- if we are not in split view, we check if we killed one of the main buffers (curr, left, right) to disable NNP
                if S.wins.splits == nil and not W.stateWinsActive(S.wins, false) then
                    D.log(p.event, "one of the NNP main buffers have been closed, disabling...")

                    return N.disable(p.event)
                end

                if _G.NoNeckPain.config.disableOnLastBuffer then
                    local _, remaining = W.winsExceptState(S.wins, true)

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
        group = "NoNeckPain",
        desc = "Handles the closure of main NNP windows and restoring the state correctly",
    })

    vim.api.nvim_create_autocmd({ "WinClosed", "BufDelete" }, {
        callback = function(p)
            vim.schedule(function()
                if E.skip(nil, false) or S.wins.splits == nil then
                    return
                end

                if W.stateWinsActive(S.wins, true) then
                    return
                end

                S.wins.splits = Sp.refresh(S.wins.splits)

                -- if curr is not valid anymore, we focus the first valid split and remove it from the state
                if not vim.api.nvim_win_is_valid(S.wins.main.curr) then
                    -- if neither curr and splits are remaining valids, we just disable
                    if S.wins.splits == nil then
                        return N.disable(p.event)
                    end

                    S.wins.main.curr = S.wins.splits[1].id
                    S.wins.splits = Sp.remove(S.wins.splits, S.wins.splits[1].id)
                end

                -- we only restore focus on curr if there's no split left
                init(p.event, S.wins.splits == nil)
            end)
        end,
        group = "NoNeckPain",
        desc = "Aims at restoring NNP enable state after closing a split/vsplit buffer or a main buffer",
    })

    vim.api.nvim_create_autocmd({ "WinEnter", "WinClosed" }, {
        callback = function(p)
            vim.schedule(function()
                if E.skip(S, true) then
                    return
                end

                local focusedWin = vim.api.nvim_get_current_win()
                local wins, total = W.winsExceptState(S.wins, false)

                if total == 0 or not M.contains(wins, focusedWin) then
                    return
                end

                local trees = T.refresh()

                -- we cycle over supported integrations to see which got closed or opened
                for name, tree in pairs(S.wins.external.trees) do
                    -- if there was a tree[name] but not anymore, we resize
                    if tree ~= nil and tree.id ~= nil and not M.contains(wins, tree.id) then
                        D.log(p.event, "%s have been closed, resizing", name)

                        return init(p.event)
                    end

                    -- we have a new tree registered, we can resize
                    if trees[name].id ~= S.wins.external.trees[name].id then
                        D.log(p.event, "%s have been opened, resizing", name)

                        return init(p.event)
                    end
                end
                S.wins.external.trees = trees
            end)
        end,
        group = "NoNeckPain",
        desc = "Resize to apply on WinEnter/Closed of external windows",
    })

    S.enabled = true

    return S
end

-- Disables the plugin, clear highlight groups and autocmds, closes side buffers and resets the internal state.
function N.disable(scope)
    if not S.enabled then
        return S
    end

    S.enabled = false
    vim.cmd("highlight! clear NNPBuffers_Background_left NONE")
    vim.cmd("highlight! clear NNPBuffers_Text_left NONE")
    vim.cmd("highlight! clear NNPBuffers_Background_Right NONE")
    vim.cmd("highlight! clear NNPBuffers_Text_Right NONE")
    vim.api.nvim_del_augroup_by_id(S.augroup)

    -- shutdowns gracefully by focusing the stored `curr` buffer
    if
        S.wins.main.curr ~= nil
        and vim.api.nvim_win_is_valid(S.wins.main.curr)
        and S.wins.main.curr ~= vim.api.nvim_get_current_win()
    then
        vim.fn.win_gotoid(S.wins.main.curr)

        if _G.NoNeckPain.config.killAllBuffersOnDisable then
            vim.cmd("only")
        end
    end

    W.closeSideBuffers(scope, S.wins.main)

    S = St.init()

    return S
end

return N
