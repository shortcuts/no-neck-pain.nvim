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
function A.sideExist(tab, side)
    if tab == nil then
        return false
    end

    return _G.NoNeckPain.config.buffers[side].enabled and tab.wins.main[side] ~= nil
end

---whether the currently focused window is the provided one.
---
---@return boolean
---@param win number?: the win number, defaults to 0 if nil
---@private
function A.isCurrentWin(win)
    return vim.api.nvim_get_current_win() == win
end

function A.mergeState(main, splits, trees)
    local wins = {}

    if main ~= nil then
        for _, side in pairs(main) do
            table.insert(wins, side)
        end
    end

    if splits ~= nil then
        for _, split in pairs(splits) do
            table.insert(wins, split.id)
        end
    end

    if trees ~= nil then
        for _, tree in pairs(trees) do
            table.insert(wins, tree.id)
        end
    end

    return wins
end

---Gets all wins that are not already registered in the given `tab`, we consider side trees if provided.
---
---@param tab table: the table where the tab information are stored.
---@param withTrees boolean: whether we should consider external windows or not.
---@return table: the wins that are not in `tab`.
---@private
function A.winsExceptState(tab, withTrees)
    local wins = vim.api.nvim_tabpage_list_wins(tab.id)
    local mergedWins =
        A.mergeState(tab.wins.main, tab.wins.splits, withTrees and tab.wins.external.trees or nil)

    local validWins = {}

    for _, win in pairs(wins) do
        if not vim.tbl_contains(mergedWins, win) and not A.isRelativeWindow(win) then
            table.insert(validWins, win)
        end
    end

    return validWins
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
