local D = require("no-neck-pain.util.debug")

local T = {}

function T.init()
    return {
        nvimtree = {
            configName = "NvimTree",
            close = "NvimTreeClose",
            open = "NvimTreeOpen",
        },
        ["neo-tree"] = {
            configName = "NeoTree",
            close = "Neotree close",
            open = "Neotree reveal",
        },
        neotest = {
            configName = "neotest",
            close = "lua require('neotest').summary.close()",
            open = "lua require('neotest').summary.open()",
        },
    }
end

---Whether the given `fileType` matches a supported side tree or not.
---
---@param scope string: caller of the method.
---@param win integer?: the id of the win
---@return boolean
---@return table|nil
---@private
function T.isSideTree(scope, win)
    win = win or 0
    local tab = State.getTabSafe(State)
    local buffer = vim.api.nvim_win_get_buf(win)
    local fileType = vim.api.nvim_buf_get_option(buffer, "filetype")

    if fileType == "" then
        fileType = vim.api.nvim_buf_get_name(buffer)
    end

    if fileType == "" and tab ~= nil then
        D.log(scope, "no name or filetype matching a tree, searching in wins...")

        local wins = State.getUnregisteredWins(State, false)

        if #wins ~= 1 or wins[1] == win then
            D.log(scope, "too many windows to determine")

            return false, nil
        end

        return T.isSideTree(scope, wins[1])
    end

    local trees = tab ~= nil and tab.wins.trees or T.init()

    for treeFileType, tree in pairs(trees) do
        if vim.startswith(string.lower(fileType), treeFileType) then
            D.log(scope, "win '%d' is a side tree '%s'", win, fileType)

            return true, tab ~= nil and tree or nil
        end
    end

    return false, nil
end

---Scans the current tab wins to update registered side trees.
---
---@return table: the update state trees table.
---@private
function T.refresh()
    local wins = vim.api.nvim_tabpage_list_wins(State.activeTab)
    local trees = T.init()

    for _, win in pairs(wins) do
        local isSideTree, external = T.isSideTree("T.refresh", win)
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
---@return table: the integrations mapping with a boolean set to true, if we closed one of them.
---@private
function T.close()
    local tab = State.getTab(State)

    for _, opts in pairs(tab.wins.trees) do
        if opts.id ~= nil and opts.close ~= nil then
            vim.cmd(opts.close)
        end
    end

    return tab.wins.trees
end

---Reopens the trees if they were previously closed.
---
---@param trees table: the integrations mappings with their associated boolean value, `true` if we closed it previously.
---@private
function T.reopen(trees)
    for _, opts in pairs(trees) do
        if
            opts.id ~= nil
            and opts.open ~= nil
            and _G.NoNeckPain.config.integrations[opts.configName].reopen == true
        then
            vim.cmd(opts.open)
        end
    end
end

return T
