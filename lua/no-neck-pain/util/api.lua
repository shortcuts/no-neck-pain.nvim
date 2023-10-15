local A = {}

---Returns the name of the augroup for the given tab ID.
---
---@return string: the initialied state
---@private
function A.getAugroupName()
    return string.format("NoNeckPain-%d", State.activeTab)
end

---returns the width and height of a given window
---
---@param win number?: the win number, defaults to 0 if nil
---@return number: the width of the window
---@return number: the height of the window
---@private
function A.getWidthAndHeight(win)
    win = win or 0

    if win ~= 0 and not vim.api.nvim_win_is_valid(win) then
        win = 0
    end

    return vim.api.nvim_win_get_width(win), vim.api.nvim_win_get_height(win)
end

---computes whether the "side" is defined and exists.
---
---@param tab table: the table where the tab information are stored.
---@param side "left"|"right": the side of the window being resized.
---@return boolean: whether the side exists or not.
---@private
function A.sideExist(tab, side)
    if tab == nil then
        return false
    end

    return _G.NoNeckPain.config.buffers[side].enabled and tab.wins.main[side] ~= nil
end

---Determines if the given `win` or the current window is relative.
---
---@param win number?: the id of the window.
---@return boolean: true if the window is relative.
---@private
function A.isRelativeWindow(win)
    win = win or vim.api.nvim_get_current_win()

    if
        vim.api.nvim_win_get_config(0).relative ~= ""
        or vim.api.nvim_win_get_config(win).relative ~= ""
    then
        return true
    end

    return false
end

return A
