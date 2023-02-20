local T = {}

local INTEGRATIONS = {
    NvimTree = {
        enabled = false,
        close = "NvimTreeClose",
        open = "NvimTreeOpen",
    },
    NeoTree = {
        enabled = false,
        close = "NeoTreeClose",
        open = "NeoTreeReveal",
    },
}

---Whether the given `fileType` matches a supported side tree or not.
---
---@param fileType string: the fileType of the buffer.
---@return boolean
---@private
function T.isSideTree(fileType)
    return fileType == "NvimTree" or fileType == "undotree" or fileType == "neo-tree"
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
        NeoTree = {
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

---Closes side trees if opened.
---
---@param tab table: the table where the tab information are stored.
---@return table: the integrations mapping with a boolean set to true, if we closed one of them.
---@private
function T.close(tab)
    for tree, opts in pairs(INTEGRATIONS) do
        if tab.wins.external.trees[tree].id ~= nil then
            INTEGRATIONS[tree].enabled = true
            vim.cmd(opts.close)
        end
    end

    return INTEGRATIONS
end

---Reopens the tree if it was previously closed.
---
---@param integrations table: the integrations mappings with their associated boolean value, `true` if we closed it previously.
---@private
function T.reopen(integrations)
    for tree, opts in pairs(integrations) do
        if opts.enabled and _G.NoNeckPain.config.integrations[tree].reopen == true then
            vim.cmd(opts.open)
        end
    end
end

return T
