local A = {}

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
function A.hasSide(tab, side)
    return _G.NoNeckPain.config.buffers[side].enabled and tab.wins.main[side] ~= nil
end

---whether the side is nil or not.
---
---@param tab table: the table where the tab information are stored.
---@param side "left"|"right": the side of the window being resized.
---@return boolean: whether the side nil or not.
---@private
function A.sideNil(tab, side)
    return tab.wins.main[side] == nil
end

---whether the currently focused window is the provided one.
---
---@return boolean
---@param win number?: the win number, defaults to 0 if nil
---@private
function A.isCurrentWin(win)
    return vim.api.nvim_get_current_win() == win
end

return A
