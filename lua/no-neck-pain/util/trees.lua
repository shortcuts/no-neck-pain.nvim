local T = {}

function T.isSideTree(fileType)
    return fileType == "NvimTree" or fileType == "undotree"
end

function T.getSideTrees()
    local wins = vim.api.nvim_list_wins()
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
