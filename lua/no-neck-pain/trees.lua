local T = {}

---Whether the given `fileType` matches a supported side tree or not.
---
---@param fileType string: the fileType of the buffer.
---@return boolean
---@private
function T.isSideTree(fileType)
    return fileType == "NvimTree" or fileType == "undotree"
end

---Scans the current tab wins to update registered side trees.
---
---@param tab table: the table where the tab information are stored.
---@return table: the update state trees table.
---@private
function T.refresh(tab)
    local wins = vim.api.nvim_tabpage_list_wins(tab.id)
    local trees = {
        NvimTree = {
            id = nil,
            width = 0,
        },
        undotree = {
            id = nil,
            width = 0,
        },
    }

    for _, win in pairs(wins) do
        local fileType = vim.api.nvim_buf_get_option(vim.api.nvim_win_get_buf(win), "filetype")
        if T.isSideTree(fileType) then
            trees[fileType] = {
                id = win,
                width = vim.api.nvim_win_get_width(win) * 2,
            }
        end
    end

    return trees
end

return T
