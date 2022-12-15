local D = require("no-neck-pain.util.debug")
local M = require("no-neck-pain.util.map")
local W = {}

-- returns the buffers without the NNP ones, and their number.
function W.bufferListWithoutNNP(scope, nnpBuffers)
    local buffers = vim.api.nvim_list_wins()
    local validBuffers = {}
    local size = 0

    for _, buffer in pairs(buffers) do
        if
            buffer ~= nnpBuffers.curr
            and buffer ~= nnpBuffers.left
            and buffer ~= nnpBuffers.right
            and not W.isRelativeWindow(scope, buffer)
        then
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

-- closes a window if it exists and is valid.
function W.close(scope, win)
    if win == nil then
        return false
    end

    local buffers = vim.api.nvim_list_wins()

    if M.tsize(buffers) == 1 then
        D.print(scope .. ": last window is " .. win .. " can't kill it")

        return false
    end

    D.print(scope .. ": killing window " .. win)

    if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, false)

        return true
    end

    return false
end

return W
