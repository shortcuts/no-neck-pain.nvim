local A = require("no-neck-pain.util.api")
local T = require("no-neck-pain.trees")
local W = require("no-neck-pain.wins")

local E = {}

---skips the event if:
--- - the plugin is not enabled
--- - we have splits open (when `skipSplit` is `true`)
--- - we are focusing a floating window
--- - we are focusing one of the side buffer
---
---@param tab table?: the table where the tab information are stored.
---@private
function E.skip(tab)
    if _G.NoNeckPain.state == nil or not _G.NoNeckPain.state.enabled then
        return true
    end

    if W.isRelativeWindow() then
        return true
    end

    if tab ~= nil then
        if vim.api.nvim_get_current_tabpage() ~= tab.id then
            return true
        end

        if A.isCurrentWin(tab.wins.main.left) or A.isCurrentWin(tab.wins.main.right) then
            return true
        end
    end

    return false
end

--- determines if we should skip the enabling of the plugin:
---  1. if a tab definition already exists in the state
---  2. if we are focusing a relative window
---  3. if we are focusing a side tree or a dashboard
--- - the plugin is not enabled
--- - we have splits open (when `skipSplit` is `true`)
--- - we are focusing a floating window
--- - we are focusing one of the side buffer
---
---@param tab table?: the table where the tab information are stored.
---@private
function E.skipEnable(tab)
    if tab ~= nil then
        return true
    end

    if W.isRelativeWindow() then
        return true
    end

    local fileType = vim.bo.filetype

    local isSideTree, _ = T.isSideTree(tab, fileType)
    if isSideTree or fileType == "dashboard" then
        return true
    end

    return false
end

return E
