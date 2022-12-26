local D = require("no-neck-pain.util.debug")
local E = require("no-neck-pain.util.event")
local M = require("no-neck-pain.util.map")
local W = require("no-neck-pain.util.win")

-- internal methods
local NoNeckPain = {}

-- state
local S = {
    enabled = false,
    augroup = nil,
    win = {
        main = {
            curr = nil,
            left = nil,
            right = nil,
            split = nil,
        },
        external = {
            tree = {
                id = nil,
                width = 0,
            },
        },
    },
    vsplit = false,
}

--- Toggle the plugin by calling the `enable`/`disable` methods respectively.
function NoNeckPain.toggle()
    if S.enabled then
        NoNeckPain.disable()

        return false
    end

    NoNeckPain.enable()

    return true
end

-- Resizes both of the NNP buffers.
local function resize(scope)
    W.resize(scope, S.win.main.left, W.getPadding("left", S.win.external.tree.width))
    W.resize(scope, S.win.main.right, W.getPadding("right", S.win.external.tree.width))
end

-- Close both of the NNP buffers and set their state to `nil`.
local function close(scope)
    S.win.main.left = W.close(scope, S.win.main.left)
    S.win.main.right = W.close(scope, S.win.main.right)
end

-- Creates NNP buffers.
local function init()
    local splitbelow, splitright = vim.o.splitbelow, vim.o.splitright
    vim.o.splitbelow, vim.o.splitright = true, true

    S.win.main.curr = vim.api.nvim_get_current_win()

    if vim.api.nvim_list_uis()[1].width < _G.NoNeckPain.config.width then
        return D.log("init", "not enough space to create side buffers")
    end

    -- before creating side buffers, we determine if we should consider externals
    S.win.external.tree = W.getSideTree()

    if _G.NoNeckPain.config.buffers.left.enabled and S.win.main.left == nil then
        S.win.main.left = W.createBuf(
            "left",
            "leftabove vnew",
            W.getPadding("left", S.win.external.tree.width),
            "wincmd l"
        )
    end

    if _G.NoNeckPain.config.buffers.right.enabled and S.win.main.right == nil then
        S.win.main.right = W.createBuf(
            "right",
            "vnew",
            W.getPadding("right", S.win.external.tree.width),
            "wincmd h"
        )
    end

    vim.o.splitbelow, vim.o.splitright = splitbelow, splitright
    vim.fn.win_gotoid(S.win.main.curr)
end

--- Initializes NNP and sets event listeners.
function NoNeckPain.enable()
    if S.enabled then
        return
    end

    S.augroup = vim.api.nvim_create_augroup("NoNeckPain", {
        clear = true,
    })

    init()

    vim.api.nvim_create_autocmd({ "VimResized" }, {
        callback = function(p)
            vim.schedule(function()
                if E.skip(p.event, S.enabled, nil) then
                    return
                end

                local width = vim.api.nvim_list_uis()[1].width

                if width > _G.NoNeckPain.config.width then
                    D.log(
                        p.event,
                        "window's width %s is above the given `width` option %s",
                        width,
                        _G.NoNeckPain.config.width
                    )

                    -- we create everything if side buffers are missing
                    if S.win.main.left == nil and S.win.main.right == nil then
                        return init()
                    end

                    return resize(p.event)
                end

                -- window width below `options.width`
                close(p.event)
            end)
        end,
        group = "NoNeckPain",
        desc = "Resizes side windows after shell has been resized",
    })

    vim.api.nvim_create_autocmd({ "WinEnter" }, {
        callback = function(p)
            vim.schedule(function()
                if E.skip(p.event, S.enabled, nil) then
                    return
                end

                local focusedWin = vim.api.nvim_get_current_win()
                local buffers, total = W.listWinsExcept(S.win.main)

                if total == 0 or not M.contains(buffers, focusedWin) then
                    return D.log(p.event, "no valid buffers to handle, no split to handle")
                end

                local fileType = vim.api.nvim_buf_get_option(0, "filetype")
                if fileType == "NvimTree" then
                    S.win.external.tree = W.getSideTree()

                    return D.log(p.event, "encoutered an external window")
                end

                -- start by saving the split, because steps below will trigger `WinClosed`
                S.win.main.split = focusedWin

                local screenWidth = vim.api.nvim_list_uis()[1].width
                local width = vim.api.nvim_win_get_width(focusedWin)

                -- since the side buffer is still there when detecting a split
                -- we need to add the side buffers to the width to properly compare with
                -- the screen width.
                -- note: due to floor/ceil, side widths might be off by 1, so we add it
                if S.win.main.left ~= nil then
                    width = width + vim.api.nvim_win_get_width(S.win.main.left) + 1
                end

                if S.win.main.right ~= nil then
                    width = width + vim.api.nvim_win_get_width(S.win.main.right) + 1
                end

                D.log(p.event, "split found [%s/%s]", width, screenWidth)

                if width < screenWidth then
                    S.vsplit = true
                    return close(p.event)
                end
            end)
        end,
        group = "NoNeckPain",
        desc = "WinEnter covers the split/vsplit management",
    })

    vim.api.nvim_create_autocmd({ "QuitPre", "BufDelete" }, {
        callback = function(p)
            vim.schedule(function()
                if E.skip(p.event, S.enabled, nil) then
                    return
                end

                local wins = vim.api.nvim_list_wins()

                -- if we are not in split view, we check if we killed one of the main buffers (curr, left, right) to disable NNP
                -- TODO: make killed side buffer decision configurable, we can re-create it
                if S.win.main.split == nil and not M.every(wins, S.win.main) then
                    D.log(p.event, "one of the NNP main buffers have been closed, disabling...")

                    return NoNeckPain.disable(p.event)
                end

                if _G.NoNeckPain.config.disableOnLastBuffer then
                    local _, remaining = W.listWinsExcept({
                        S.win.main.curr,
                        S.win.main.left,
                        S.win.main.right,
                        S.win.main.split,
                        S.win.external.tree.id,
                    })

                    if
                        remaining == 0
                        and vim.api.nvim_buf_get_option(0, "buftype") == ""
                        and vim.api.nvim_buf_get_option(0, "filetype") == ""
                        and vim.api.nvim_buf_get_option(0, "bufhidden") == "wipe"
                    then
                        D.log(p.event, "found last `wipe` buffer in list, disabling...")

                        return NoNeckPain.disable()
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
                if E.skip(p.event, S.enabled, nil) or S.win.main.split == nil then
                    return
                end

                local wins = vim.api.nvim_list_wins()
                local total = M.tsize(wins)

                -- `total` needs to be compared with the number of active wins,
                -- in the NNP context. This threshold holds the count.
                -- 1 = split && curr && !left && !right
                --  - vsplit   we have either `curr` or `split` left, basic vsplit case
                --  - split    we don't have side buffers (e.g. small window, disabled in config)
                -- 2 = !vsplit && split && curr && (!left || !right)
                --  - user disabled one of the side buffer
                -- 3 = !vsplit && split && curr && left && right
                --  - a default config case
                local threshold = 1

                if not S.vsplit then
                    if S.win.main.left ~= nil and S.win.main.right ~= nil then
                        threshold = 2
                    elseif S.win.main.left ~= nil or S.win.main.right ~= nil then
                        threshold = 3
                    end
                end

                if total > threshold then
                    return
                end

                D.log(p.event, "%s < %s, killing split", total, threshold)

                if vim.api.nvim_win_is_valid(S.win.main.split) then
                    S.win.main.curr = S.win.main.split
                end

                S.win.main.split = nil
                S.vsplit = false

                init()
            end)
        end,
        group = "NoNeckPain",
        desc = "Aims at restoring NNP enable state after closing a split/vsplit buffer or a main buffer",
    })

    vim.api.nvim_create_autocmd({ "WinEnter", "WinClosed" }, {
        callback = function(p)
            vim.schedule(function()
                local focusedWin = vim.api.nvim_get_current_win()

                if
                    E.skip(p.event, S.enabled, S.win.split) or M.contains(S.win.main, focusedWin)
                then
                    return
                end

                if
                    S.win.external.tree.id ~= nil
                    and not M.contains(vim.api.nvim_list_wins(), S.win.external.tree.id)
                then
                    S.win.external.tree = {
                        id = nil,
                        width = 0,
                    }

                    return resize(p.event)
                end

                S.win.external.tree = W.getSideTree()
                if S.win.external.tree.id ~= nil then
                    D.log(p.event, "side tree found, resizing")

                    return resize(p.event)
                end
            end)
        end,
        group = "NoNeckPain",
        desc = "Resize to apply on WinEnter/Closed",
    })

    S.enabled = true
end

--- Disable NNP and reset windows, leaving the `curr` focused window as focused.
function NoNeckPain.disable(scope)
    if not S.enabled then
        return
    end

    S.enabled = false
    vim.cmd("highlight! clear NNPBuffers_left NONE")
    vim.cmd("highlight! clear NNPBuffers_right NONE")
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

    close(scope)

    S.augroup = nil
    S.vsplit = false
    S.win = {
        main = {
            curr = nil,
            left = nil,
            right = nil,
            split = nil,
        },
        external = {
            tree = {
                id = nil,
                width = 0,
            },
        },
    }
end

return { NoNeckPain, S }
