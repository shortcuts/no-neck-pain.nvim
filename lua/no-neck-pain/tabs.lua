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

---Returns the name of the augroup for the given tab ID.
---
---@param id number: the tab ID.
---@return string: the initialied state
---@private
function Ta.getAugroupName(id)
    return string.format("NoNeckPain-%d", id)
end

---Iterates over the current state to refresh the `tabs` table, removes any `tab` that are not valid anymore.
---
---@param tabs table: the `tabs` state list.
---@param id number?: the `id` of the tab to remove from the state, defaults to the current tabpage.
---@return table?: the refreshed tabs list.
---@private
function Ta.refresh(tabs, id)
    id = id or vim.api.nvim_get_current_tabpage()
    local refreshedTabs = {}

    for _, tab in pairs(tabs) do
        if tab.id ~= id and vim.api.nvim_tabpage_is_valid(tab.id) then
            table.insert(refreshedTabs, tab)
        end
    end

    if #refreshedTabs == 0 then
        return nil
    end

    return refreshedTabs
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
        scratchPadEnabled = false,
        layers = {
            vsplit = 1,
            split = 1,
        },
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
