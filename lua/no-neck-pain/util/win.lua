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

    D.print(scope .. ": resizing window " .. win .. " with padding", padding)

    if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_set_width(win, padding)
    end
end

function W.getSideTree()
    local wins = vim.api.nvim_list_wins()

    for _, win in pairs(wins) do
        if vim.api.nvim_buf_get_option(vim.api.nvim_win_get_buf(win), "filetype") == "NvimTree" then
            return {
                id = win,
                width = vim.api.nvim_win_get_width(win) * 2,
            }
        end
    end

    return {
        id = nil,
        width = 0,
    }
end

-- Determine the "padding" (width) of the buffer based on the `_G.NoNeckPain.config.width`, the width of the screen, and it a side tree is currently open.
--
-- @param paddingToSubstract number: a value to be substracted to the `width` of the screen
function W.getPadding(side, paddingToSubstract)
    local width = vim.api.nvim_list_uis()[1].width

    if _G.NoNeckPain.config.width >= width then
        return 1
    end

    paddingToSubstract = paddingToSubstract or 0

    -- if the side we are resizing is not the same as the tree position, we set it to 0
    if side ~= _G.NoNeckPain.config.integrations.nvimTree.position then
        paddingToSubstract = 0
    end

    return math.floor((width - paddingToSubstract - _G.NoNeckPain.config.width) / 2)
end

return W
