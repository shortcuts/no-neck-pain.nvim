local D = require("no-neck-pain.util.debug")
local E = require("no-neck-pain.util.event")
local M = require("no-neck-pain.util.map")
local W = require("no-neck-pain.util.win")
local T = require("no-neck-pain.util.trees")
local ST = require("no-neck-pain.util.state")

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
local function init()
    S.win.main.curr = vim.api.nvim_get_current_win()

    -- before creating side buffers, we determine if we should consider externals
    S.win.external.trees = T.getSideTrees()
    S.win.main.left, S.win.main.right = W.createSideBuffers(S.win)
    -- we might have closed trees during the buffer creation process, we re-fetch the latest IDs to prevent inconsistencies
    S.win.external.trees = T.getSideTrees()

    vim.fn.win_gotoid(S.win.main.curr)
end

-- Initializes the plugin, sets event listeners and internal state.
function N.enable()
    if S.enabled then
        return S
    end

    S.augroup = vim.api.nvim_create_augroup("NoNeckPain", {
        clear = true,
    })

    init()

    vim.api.nvim_create_autocmd({ "VimResized" }, {
        callback = function(p)
            vim.schedule(function()
                if E.skip(S.enabled, S.win.main, nil) then
                    return
                end

                local width = vim.api.nvim_list_uis()[1].width

                -- we create everything if side buffers are missing
                if
                    width > _G.NoNeckPain.config.width
                    and S.win.main.left == nil
                    and S.win.main.right == nil
                then
                    return init()
                end

                S.win.main.left, S.win.main.right = W.resizeOrCloseSideBuffers(p.event, S.win)
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
                local wins, total = W.listWinsExcept(ST.mergeStateWins(S.win.main, S.win.splits))

                if total == 0 or not M.contains(wins, focusedWin) then
                    return
                end

                -- we skip side trees etc. as they are not part of the split manager.
                local fileType = vim.api.nvim_buf_get_option(0, "filetype")
                if T.isSideTree(fileType) then
                    return D.log(p.event, "encountered an external window")
                end

                local screenWidth = vim.api.nvim_list_uis()[1].width
                local width = vim.api.nvim_win_get_width(focusedWin)

                -- since the side buffer is still there when detecting a split
                -- we need to add the side buffers to the width to properly compare with
                -- the screen width.
                -- note: due to floor, side widths might be off by 1, so we add it
                if S.win.main.left ~= nil and vim.api.nvim_win_is_valid(S.win.main.left) then
                    width = width + vim.api.nvim_win_get_width(S.win.main.left) + 1
                else
                    S.win.main.left = nil
                end

                if S.win.main.right ~= nil and vim.api.nvim_win_is_valid(S.win.main.right) then
                    width = width + vim.api.nvim_win_get_width(S.win.main.right) + 1
                else
                    S.win.main.right = nil
                end

                D.log(p.event, "new split window found [%s/%s]", width, screenWidth)

                local vsplit = width < screenWidth

                S.win.splits = ST.insertInSplits(S.win.splits, focusedWin, vsplit)

                if vsplit then
                    S.win.main.left, S.win.main.right = W.resizeOrCloseSideBuffers(p.event, S.win)
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
                -- TODO: make killed side buffer decision configurable, we can re-create it
                if S.win.splits == nil and not ST.stateWinsPresent(S.win, false) then
                    D.log(p.event, "one of the NNP main buffers have been closed, disabling...")

                    return N.disable(p.event)
                end

                if _G.NoNeckPain.config.disableOnLastBuffer then
                    local _, remaining = W.listWinsExcept(
                        ST.mergeStateWins(S.win.main, S.win.splits, S.win.external.trees)
                    )

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

                if ST.stateWinsPresent(S.win, true) then
                    return D.log(p.event, "state wins are still active, no need to kill splits.")
                end

                S.win.splits = ST.refreshSplits(S.win.splits)

                -- if curr is not valid anymore, we focus the first valid split and remove it from the state
                if not vim.api.nvim_win_is_valid(S.win.main.curr) then
                    -- if neither curr and splits are remaining valids, we just disable
                    if S.win.splits == nil then
                        return N.disable(p.event)
                    end

                    vim.fn.win_gotoid(S.win.splits[1].id)
                    S.win.splits = ST.removeSplit(S.win.splits, S.win.splits[1].id)
                end

                init()
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
                local wins, total = W.listWinsExcept(ST.mergeStateWins(S.win.main, S.win.splits))

                if total == 0 or not M.contains(wins, focusedWin) then
                    return
                end

                local trees = T.getSideTrees()

                -- we cycle over supported integrations to see which got closed or opened
                for name, tree in pairs(S.win.external.trees) do
                    -- if there was a tree[name] but not anymore, we resize
                    if tree ~= nil and tree.id ~= nil and not M.contains(wins, tree.id) then
                        D.log(p.event, "%s have been closed, resizing", name)

                        S.win.external.trees[name] = {
                            id = nil,
                            width = 0,
                        }

                        return init()
                    end

                    -- we have a new tree registered, we can resize
                    if trees[name].id ~= S.win.external.trees[name].id then
                        D.log(p.event, "%s have been opened, resizing", name)

                        S.win.external.trees = trees
                        S.win.main.left, S.win.main.right =
                            W.resizeOrCloseSideBuffers(p.event, S.win)

                        return
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
