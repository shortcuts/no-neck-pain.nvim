local D = require("no-neck-pain.util.debug")

local Ta = {}

function Ta.initState()
    return {
        enabled = false,
        activeTab = 1,
        tabs = nil,
    }
end

-- returns the current tabpage.
function Ta.refresh(curr)
    local new = vim.api.nvim_win_get_tabpage(0)

    if curr == new then
        return curr
    end

    D.log("Ta.refresh", "new tab page registered: was %d, now %d", curr, new)

    return new
end

-- inserts a tab in the given `tabs` list with the given `id`.
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

-- removes the tab with the given `id` and returns the new `tabs` list, and the total of elements in it.
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
        return nil, total
    end

    return newTabs, total
end

-- returns the tab with the given `id`.
function Ta.get(tabs, id)
    if tabs == nil then
        return nil
    end

    for _, tab in pairs(tabs) do
        if tab.id == id then
            return tab
        end
    end

    return nil
end

-- returns the tab's state if the currently focused tab is registered
function Ta.exists(tabs)
    if tabs == nil then
        return nil
    end

    local tabPage = vim.api.nvim_get_current_tabpage()
    local tab = Ta.get(tabs, tabPage)

    if tab == nil then
        return nil
    end

    return tab
end

-- replace the tab of the given `id` in the `tabs` list with the `updatedTab`.
function Ta.update(tabs, id, updatedTab)
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
