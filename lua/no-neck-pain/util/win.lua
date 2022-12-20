local C = require("no-neck-pain.util.color")
local D = require("no-neck-pain.util.debug")
local M = require("no-neck-pain.util.map")
local W = {}

-- Creates a buffer for the given "padding" (width), at the given `moveTo` direction.
--
--@param name string: the name of the buffer, `no-neck-pain-` will be prepended.
--@param cmd string: the command to execute when creating the buffer
--@param padding number: the "padding" (width) of the buffer
--@param moveTo string: the command to execute to place the buffer at the correct spot.
function W.createBuf(name, cmd, padding, moveTo)
    if vim.api.nvim_list_uis()[1].width < _G.NoNeckPain.config.width then
        return D.log("W.createBuf", "not enough space to create side buffer %s", name)
    end

    vim.cmd(cmd)

    local id = vim.api.nvim_get_current_win()

    vim.api.nvim_win_set_width(0, padding)

    if _G.NoNeckPain.config.buffers.setNames then
        vim.api.nvim_buf_set_name(0, "no-neck-pain-" .. name)
    end

    for opt, val in pairs(_G.NoNeckPain.config.buffers[name].bo) do
        vim.api.nvim_buf_set_option(0, opt, val)
    end

    for opt, val in pairs(_G.NoNeckPain.config.buffers[name].wo) do
        vim.api.nvim_win_set_option(id, opt, val)
    end

    vim.cmd(moveTo)

    C.init(id, name, _G.NoNeckPain.config.buffers[name].backgroundColor)

    return id
end

-- returns the buffers without the NNP ones, and their number.
function W.bufferListWithoutNNP(list)
    local buffers = vim.api.nvim_list_wins()
    local validBuffers = {}
    local size = 0

    for _, buffer in pairs(buffers) do
        if not M.contains(list, buffer) and not W.isRelativeWindow(buffer) then
            table.insert(validBuffers, buffer)
            size = size + 1
        end
    end

    return validBuffers, size
end

-- returns true if the index 0 window or the current window is relative.
function W.isRelativeWindow(win)
    win = win or vim.api.nvim_get_current_win()

    if
        vim.api.nvim_win_get_config(0).relative ~= ""
        or vim.api.nvim_win_get_config(win).relative ~= ""
    then
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
        D.log(scope, "trying to kill the last available buffer %s, we can safely quit Neovim", win)

        vim.cmd([[quit!]])

        return true
    end

    D.log(scope, "killing window %s", win)

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

    D.log(scope, "resizing window %s with padding %s", win, padding)

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

-- Determine the "padding" (width) of the buffer based on the `_G.NoNeckPain.config.width` and the width of the screen.
--
-- @param paddingToSubstract number: a value to be substracted to the `width` of the screen.
function W.getPadding(side, paddingToSubstract)
    local wins = vim.api.nvim_list_uis()

    if wins[1] == nil then
        return D.log("W.getPadding", "attempted to get the padding of a non-existing window.")
    end

    local width = wins[1].width

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
