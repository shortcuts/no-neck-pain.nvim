local D = require("no-neck-pain.util.debug")
local E = require("no-neck-pain.util.event")
local M = require("no-neck-pain.util.map")
local W = require("no-neck-pain.util.win")
local T = require("no-neck-pain.util.trees")
local Sp = require("no-neck-pain.util.split")

local N = {}

-- state
local S = {
    enabled = false,
    augroup = nil,
    win = {
        main = {
            curr = nil,
            left = nil,
            right = nil,
        },
        splits = nil,
        external = {
            trees = {
                NvimTree = {
                    id = nil,
                    width = 0,
                },
                undotree = {
                    id = nil,
                    width = 0,
                },
            },
        },
    },
}

-- Toggle the plugin by calling the `enable`/`disable` methods respectively.
function N.toggle()
    if S.enabled then
        return N.disable("N.toggle")
    end

    return N.enable()
end

-- Creates side buffers and set the internal state considering potential external trees.
local function init(scope, goToCurr)
    D.log(scope, "init called, %d is the current window", S.win.main.curr)

    -- if we do not have side buffers, we must ensure we only trigger a focus if we re-create them
    local hadSideBuffers = true
    if
        (S.win.main.left == nil and _G.NoNeckPain.config.buffers.left.enabled)
        or (S.win.main.right == nil and _G.NoNeckPain.config.buffers.right.enabled)
    then
        hadSideBuffers = false
    end

    -- before creating side buffers, we determine if we should consider externals
    S.win.external.trees = T.getSideTrees()
    S.win.main.left, S.win.main.right = W.createSideBuffers(S.win)
    -- we might have closed trees during the buffer creation process, we re-fetch the latest IDs to prevent inconsistencies
    S.win.external.trees = T.getSideTrees()

    if goToCurr or (not hadSideBuffers and (S.win.main.left ~= nil or S.win.main.right ~= nil)) then
        vim.fn.win_gotoid(S.win.main.curr)
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

    S.win.main.curr = vim.api.nvim_get_current_win()
    S.win.splits = Sp.getSplits(S.win)

    init("enable", true)

    vim.api.nvim_create_autocmd({ "VimResized" }, {
        callback = function(p)
            vim.schedule(function()
                if E.skip(S.enabled, S.win.main, nil) then
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
                if E.skip(S.enabled, S.win.main, nil) then
                    return
                end

                local focusedWin = vim.api.nvim_get_current_win()
                local wins, total = W.winsExceptState(S.win, false)

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

                S.win.splits = Sp.insert(S.win.splits, focusedWin, vsplit)

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
                if E.skip(S.enabled, nil, nil) then
                    return
                end

                -- if we are not in split view, we check if we killed one of the main buffers (curr, left, right) to disable NNP
                if S.win.splits == nil and not W.stateWinsActive(S.win, false) then
                    D.log(p.event, "one of the NNP main buffers have been closed, disabling...")

                    return N.disable(p.event)
                end

                if _G.NoNeckPain.config.disableOnLastBuffer then
                    local _, remaining = W.winsExceptState(S.win, true)

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
                if E.skip(S.enabled, nil, nil) or S.win.splits == nil then
                    return
                end

                if W.stateWinsActive(S.win, true) then
                    return
                end

                S.win.splits = Sp.refresh(S.win.splits)

                -- if curr is not valid anymore, we focus the first valid split and remove it from the state
                if not vim.api.nvim_win_is_valid(S.win.main.curr) then
                    -- if neither curr and splits are remaining valids, we just disable
                    if S.win.splits == nil then
                        return N.disable(p.event)
                    end

                    S.win.main.curr = S.win.splits[1].id
                    S.win.splits = Sp.remove(S.win.splits, S.win.splits[1].id)
                end

                -- we only restore focus on curr if there's no split left
                init(p.event, S.win.splits == nil)
            end)
        end,
        group = "NoNeckPain",
        desc = "Aims at restoring NNP enable state after closing a split/vsplit buffer or a main buffer",
    })

    vim.api.nvim_create_autocmd({ "WinEnter", "WinClosed" }, {
        callback = function(p)
            vim.schedule(function()
                if E.skip(S.enabled, S.win.main, S.win.splits) then
                    return
                end

                local focusedWin = vim.api.nvim_get_current_win()
                local wins, total = W.winsExceptState(S.win, false)

                if total == 0 or not M.contains(wins, focusedWin) then
                    return
                end

                local trees = T.getSideTrees()

                -- we cycle over supported integrations to see which got closed or opened
                for name, tree in pairs(S.win.external.trees) do
                    -- if there was a tree[name] but not anymore, we resize
                    if tree ~= nil and tree.id ~= nil and not M.contains(wins, tree.id) then
                        D.log(p.event, "%s have been closed, resizing", name)

                        return init(p.event)
                    end

                    -- we have a new tree registered, we can resize
                    if trees[name].id ~= S.win.external.trees[name].id then
                        D.log(p.event, "%s have been opened, resizing", name)

                        return init(p.event)
                    end
                end
                S.win.external.trees = trees
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
        S.win.main.curr ~= nil
        and vim.api.nvim_win_is_valid(S.win.main.curr)
        and S.win.main.curr ~= vim.api.nvim_get_current_win()
    then
        vim.fn.win_gotoid(S.win.main.curr)

        if _G.NoNeckPain.config.killAllBuffersOnDisable then
            vim.cmd("only")
        end
    end

    W.closeSideBuffers(scope, S.win.main)

    S = {
        enabled = false,
        augroup = nil,
        win = {
            main = {
                curr = nil,
                left = nil,
                right = nil,
            },
            splits = nil,
            external = {
                trees = {
                    NvimTree = {
                        id = nil,
                        width = 0,
                    },
                    undotree = {
                        id = nil,
                        width = 0,
                    },
                },
            },
        },
    }

    return S
end

return N
