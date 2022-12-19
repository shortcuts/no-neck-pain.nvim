local D = require("no-neck-pain.util.debug")
local M = require("no-neck-pain.util.map")
local W = {}

-- returns the buffers without the NNP ones, and their number.
function W.bufferListWithoutNNP(scope, list)
    local buffers = vim.api.nvim_list_wins()
    local validBuffers = {}
    local size = 0

    for _, buffer in pairs(buffers) do
        if not M.contains(list, buffer) and not W.isRelativeWindow(scope, buffer) then
            table.insert(validBuffers, buffer)
            size = size + 1
        end
    end

    return validBuffers, size
end

-- returns true if the index 0 window or the current window is relative.
function W.isRelativeWindow(scope, win)
    win = win or vim.api.nvim_get_current_win()

    if
        vim.api.nvim_win_get_config(0).relative ~= ""
        or vim.api.nvim_win_get_config(win).relative ~= ""
    then
        D.print(scope, "float window detected")

        return true
    end
end

-- closes a given `win` (NNP buffer) if there's other buffers (not NNP buffers) open.
-- quits Neovim if we close an NNP buffer but there's no other valid buffer left.
function W.close(scope, win)
    if win == nil then
        return false
    end

    local buffers = vim.api.nvim_list_wins()

    if M.tsize(buffers) == 1 and buffers[1] == win then
        D.print(
            scope
                .. ": trying to kill the last available buffer "
                .. win
                .. ", we can safely quit Neovim"
        )

        vim.cmd([[quit!]])

        return true
    end

    D.print(scope .. ": killing window " .. win)

    if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, false)
    end

    return true
end

-- resizes a given `win` for the given `padding`
function W.resize(scope, win, padding)
    if win == nil then
        return
    end

    if vim.api.nvim_win_is_valid(win) then
        D.print(scope, "resizing", win, padding)

        vim.api.nvim_win_set_width(win, padding)
    end
end

return W
