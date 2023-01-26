local T = {}

-- whether the given `fileType` matches a supported side tree or not.
function T.isSideTree(fileType)
    return fileType == "NvimTree" or fileType == "undotree"
end

-- returns all of the side trees wins and their width.
function T.refresh(state)
    local wins = vim.api.nvim_tabpage_list_wins(state.tabs)
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
