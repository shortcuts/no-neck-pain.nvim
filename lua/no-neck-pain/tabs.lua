local D = require("no-neck-pain.util.debug")

local Ta = {}

---Initializes the state for the first tab, called when enabling or disabling the plugin.
---
---@return table: the initialied state
---@private
function Ta.initState()
    return {
        enabled = false,
        activeTab = 1,
        tabs = nil,
    }
end

---Gets the current tab page ID.
---
---@return number: the current tab page ID.
---@private
function Ta.refresh(curr)
    local new = vim.api.nvim_win_get_tabpage(0)

    if curr == new then
        return curr
    end

    D.log("Ta.refresh", "new tab page registered: was %d, now %d", curr, new)

    return new
end

---Inserts a new tab to the `tabs` state, with the given `id`.
---
---@param tabs table?: the `tabs` state list.
---@return table: the updated tabs state.
---@return table: the newly initialized tab.
---@private
function Ta.insert(tabs, id)
    tabs = tabs or {}

    local newTab = {
        id = id,
        augroup = nil,
        wins = {
            main = {
                curr = nil,
                left = nil,
                right = nil,
            },
            splits = nil,
            external = {
                trees = {
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
                },
            },
        },
    }

    table.insert(tabs, newTab)

    return tabs, newTab
end

---Remove the tab with the given `id` from the tabs state.
---
---@param tabs table: the `tabs` state list.
---@param id number: the id of the tab to remove.
---@return table?: the updated tabs state list or nil if there's no remaining tabs active.
---@private
function Ta.remove(tabs, id)
    local newTabs = {}
    local total = 0

    for _, tab in pairs(tabs) do
        if tab.id ~= id then
            table.insert(newTabs, tab)
            total = total + 1
        end
    end

    if total == 0 then
        return nil
    end

    return newTabs
end

---Gets the tab with the given `id` for the state
---
---@param tabs table?: the `tabs` state list.
---@param id number?: the id of the tab to get, fallbacks to the current page when `nil`.
---@return table?: the `tab` information, or `nil` if it's not found.
---@private
function Ta.get(tabs, id)
    if tabs == nil then
        return nil
    end

    id = id or vim.api.nvim_get_current_tabpage()

    for _, tab in pairs(tabs) do
        if tab.id == id then
            return tab
        end
    end

    return nil
end

---Replaces the tab with the given `id` by the `updatedTab`
---
---@param tabs table: the `tabs` state list.
---@param id number: the id of the tab to update.
---@param updatedTab table: the table where the updated tab information are stored.
---@return table?: the `tab` information, or `nil` if it's not found.
---@private
function Ta.update(tabs, id, updatedTab)
    if tabs == nil then
        return nil
    end

    local updatedTabs = {}

    for _, tab in pairs(tabs) do
        if tab.id == id then
            table.insert(updatedTabs, updatedTab)
        elseif tab.id ~= id then
            table.insert(updatedTabs, tab)
        end
    end

    return updatedTabs
end

return Ta
