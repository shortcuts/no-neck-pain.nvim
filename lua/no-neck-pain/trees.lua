local T = {}

function T.init()
    return {
        NvimTree = {
            configName = "NvimTree",
            close = "NvimTreeClose",
            open = "NvimTreeOpen",
        },
        ["neo-tree"] = {
            configName = "NeoTree",
            close = "Neotree close",
            open = "Neotree reveal",
        },
        Neotest = {
            configName = "neotest",
            close = "lua require('neotest').summary.toggle()",
            open = "lua require('neotest').summary.toggle()",
        },
    }
end

---Whether the given `fileType` matches a supported side tree or not.
---
---@param tab table?: the state tab.
---@param fileType string: the fileType of the buffer.
---@return boolean
---@return table|nil
function T.isSideTree(tab, fileType)
    if fileType == "" then
        return false, nil
    end

    local trees = tab ~= nil and tab.wins.external.trees or T.init()

    for treeFileType, tree in pairs(trees) do
        if vim.startswith(fileType, treeFileType) then
            return true, tab ~= nil and tree or nil
        end
    end

    return false, nil
end

---Scans the current tab wins to update registered side trees.
---
---@param tab table: the table where the tab information are stored.
---@return table: the update state trees table.
---@private
function T.refresh(tab)
    local wins = vim.api.nvim_tabpage_list_wins(tab.id)
    local trees = T.init()

    for _, win in pairs(wins) do
        local fileType = vim.api.nvim_buf_get_option(vim.api.nvim_win_get_buf(win), "filetype")
        local isSideTree, external = T.isSideTree(tab, fileType)
        if isSideTree and external ~= nil then
            external.width = vim.api.nvim_win_get_width(win) * 2
            external.id = win

            trees[external.configName] = external
        end
    end

    return trees
end

---Closes side trees if opened.
---
---@param tab table: the table where the tab information are stored.
---@return table: the integrations mapping with a boolean set to true, if we closed one of them.
---@private
function T.close(tab)
    for _, opts in pairs(tab.wins.external.trees) do
        if opts.id ~= nil and opts.close ~= nil then
            vim.cmd(opts.close)
        end
    end

    return tab.wins.external.trees
end

---Reopens the trees if they were previously closed.
---
---@param trees table: the integrations mappings with their associated boolean value, `true` if we closed it previously.
---@private
function T.reopen(trees)
    for tree, opts in pairs(trees) do
        if
            opts.id ~= nil
            and opts.open ~= nil
            and _G.NoNeckPain.config.integrations[tree].reopen == true
        then
            vim.cmd(opts.open)
        end
    end
end

return T
