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

return A
