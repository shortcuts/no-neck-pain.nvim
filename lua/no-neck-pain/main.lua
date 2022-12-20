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
    D.print(scope, "resizing NNP buffers")

    W.resize(scope, S.win.main.left, W.getPadding("left", S.win.external.tree.width))
    W.resize(scope, S.win.main.right, W.getPadding("right", S.win.external.tree.width))
end

-- Creates NNP buffers.
local function init(scope)
    D.print(scope, "intializing NNP")

    local splitbelow, splitright = vim.o.splitbelow, vim.o.splitright
    vim.o.splitbelow, vim.o.splitright = true, true

    S.win.main.curr = vim.api.nvim_get_current_win()

    -- before creating side buffers, we determine if a side tree is open
    S.win.external.tree = W.getSideTree()

    if _G.NoNeckPain.config.buffers.left.enabled then
        S.win.main.left = W.createBuf(
            "left",
            "leftabove vnew",
            W.getPadding("left", S.win.external.tree.width),
            "wincmd l"
        )
    end

    if _G.NoNeckPain.config.buffers.right.enabled then
        S.win.main.right = W.createBuf(
            "right",
            "vnew",
            W.getPadding("right", S.win.external.tree.width),
            "wincmd h"
        )
    end

    vim.o.splitbelow, vim.o.splitright = splitbelow, splitright
end

--- Initializes NNP and sets event listeners.
function NoNeckPain.enable()
    if S.enabled then
        return D.print("Enable: tried to enable already enabled NNP")
    end

    D.print("enabling NNP")

    S.augroup = vim.api.nvim_create_augroup("NoNeckPain", {
        clear = true,
    })

    init("NoNeckPain.enable")

    vim.api.nvim_create_autocmd({ "VimResized" }, {
        callback = function()
            vim.schedule(function()
                if E.skip("VimResized", S.enabled, S.win.split) then
                    return
                end

                local width = vim.api.nvim_list_uis()[1].width

                if width > _G.NoNeckPain.config.width then
                    D.print("VimResized: window's width is above the `width` option")

                    if S.win.main.left == nil and S.win.main.right == nil then
                        D.print("VimResized: no side buffer found, creating...")

                        return init("VimEnter")
                    end

                    D.print("VimResized: buffers are here, resizing...")

                    return resize("VimResized")
                end

                D.print(
                    "VimResized: window's width is below the `width` option, closing opened buffers..."
                )

                local ok = W.close("VimResized", S.win.main.left)
                if ok then
                    S.win.main.left = nil
                end

                ok = W.close("VimResized", S.win.main.right)
                if ok then
                    S.win.main.right = nil
                end
            end)
        end,
        group = "NoNeckPain",
        desc = "Resizes side windows after shell has been resized",
    })

    vim.api.nvim_create_autocmd({ "WinEnter" }, {
        callback = function()
            vim.schedule(function()
                if E.skip("WinEnter", S.enabled, S.win.split) then
                    return
                end

                local buffers, total = W.bufferListWithoutNNP("WinEnter", S.win.main)
                local focusedWin = vim.api.nvim_get_current_win()

                if total == 0 or not M.contains(buffers, focusedWin) then
                    return D.print("WinEnter: no valid buffers to handle, no split to handle")
                end

                D.print("WinEnter: found ", total, " remaining valid buffers")

                -- below we will check for plugins that opens windows as splits (e.g. tree)
                -- and early return while storing its NoNeckPain.
                if vim.api.nvim_buf_get_option(0, "filetype") == "NvimTree" then
                    S.win.external.tree = W.getSideTree()

                    return D.print("WinEnter: encoutered an NvimTree split")
                end

                -- start by saving the split, because steps below will trigger `WinClosed`
                S.win.main.split = focusedWin

                if W.close("WinEnter", S.win.main.left) then
                    S.win.main.left = nil
                end

                if W.close("WinEnter", S.win.main.right) then
                    S.win.main.right = nil
                end
            end)
        end,
        group = "NoNeckPain",
        desc = "WinEnter covers the split/vsplit management",
    })

    vim.api.nvim_create_autocmd({ "WinClosed", "BufDelete" }, {
        callback = function()
            vim.schedule(function()
                if E.skip("WinClose, BufDelete", S.enabled, nil) then
                    return
                end

                local buffers = vim.api.nvim_list_wins()

                -- if we are not in split view, we check if we killed one of the main buffers (curr, left, right) to disable NNP
                -- TODO: make killed side buffer decision configurable, we can re-create it
                if S.win.main.split == nil and not M.every(buffers, S.win.main) then
                    D.print(
                        "WinClosed, BufDelete: one of the NNP main buffers have been closed, disabling..."
                    )

                    return NoNeckPain.disable()
                end

                local _, total = W.bufferListWithoutNNP("WinClosed, BufDelete", {
                    S.win.main.curr,
                    S.win.main.left,
                    S.win.main.right,
                    S.win.external.tree.id,
                })

                if
                    _G.NoNeckPain.config.disableOnLastBuffer
                    and total == 0
                    and vim.api.nvim_buf_get_option(0, "buftype") == ""
                    and vim.api.nvim_buf_get_option(0, "filetype") == ""
                    and vim.api.nvim_buf_get_option(0, "bufhidden") == "wipe"
                then
                    D.print("WinClosed, BufDelete: found last `wipe` buffer in list, disabling...")

                    return NoNeckPain.disable()
                elseif M.tsize(buffers) > 1 then
                    return D.print(
                        "WinClosed, BufDelete: more than one buffer left, no killed split to handle"
                    )
                end

                S.win.main.curr = buffers[0]
                S.win.main.split = nil

                -- focus curr
                vim.fn.win_gotoid(S.win.main.curr)

                -- recreate everything
                init("WinClosed, BufDelete")
            end)
        end,
        group = "NoNeckPain",
        desc = "Aims at restoring NNP enable state after closing a split/vsplit buffer or a main buffer",
    })

    vim.api.nvim_create_autocmd({ "WinEnter", "WinClosed" }, {
        callback = function()
            vim.schedule(function()
                if E.skip("WinEnter, WinClosed", S.enabled, nil) then
                    return
                end

                local focusedWin = vim.api.nvim_get_current_win()

                -- skip if the newly focused window is a side buffer
                if focusedWin == S.win.main.left or focusedWin == S.win.main.right then
                    return D.print("WinEnter, WinClosed: focus on side buffer, skipped resize")
                end

                -- when opening a new buffer as current, store its padding and resize everything (e.g. side tree)
                if focusedWin ~= S.win.main.curr then
                    S.win.external.tree = W.getSideTree()

                    D.print(
                        "WinEnter, WinClosed: new current buffer with width:",
                        S.win.external.tree.width
                    )
                end

                if not M.contains(vim.api.nvim_list_wins(), S.win.external.tree.id) then
                    S.win.external.tree = {
                        id = nil,
                        width = 0,
                    }
                end

                resize("WinEnter, WinClosed")
            end)
        end,
        group = "NoNeckPain",
        desc = "Resize to apply on WinEnter/Closed",
    })

    S.enabled = true
end

--- Disable NNP and reset windows, leaving the `curr` focused window as focused.
function NoNeckPain.disable()
    if not S.enabled then
        return D.print("Disable: tried to disable non-enabled NNP")
    end

    D.print("disabling NNP")

    S.enabled = false
    vim.api.nvim_del_augroup_by_id(S.augroup)

    W.close("Disable left", S.win.main.left)
    W.close("Disable right", S.win.main.right)

    -- shutdowns gracefully by focusing the stored `curr` buffer, if possible
    if
        S.win.main.curr ~= nil
        and vim.api.nvim_win_is_valid(S.win.main.curr)
        and S.win.main.curr ~= vim.api.nvim_get_current_win()
    then
        vim.fn.win_gotoid(S.win.main.curr)
    end

    if _G.NoNeckPain.config.killAllBuffersOnDisable then
        vim.cmd("only")
    end

    S.augroup = nil
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
