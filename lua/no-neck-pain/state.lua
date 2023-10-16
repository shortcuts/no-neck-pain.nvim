local A = require("no-neck-pain.util.api")
local D = require("no-neck-pain.util.debug")

local State = {enabled = false, activeTab = 1, tabs = nil}

local trees = {
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

---Sets the state to its original value.
---
---@private
function State:init()
    self.enabled = false
    self.activeTab = 1
    self.tabs = nil
end

---Sets the state trees to its original value.
---
---@private
function State:initTrees()
    self.tabs[self.activeTab].wins.trees = vim.deepcopy(trees)
end

---Sets the state splits to its original value.
---
---@private
function State:initSplits()
    self.tabs[self.activeTab].wins.splits = nil
end

---Iterates over the tabs in the state to remove invalid tabs.
---
---@param id number?: the `id` of the tab to remove from the state, defaults to the current tabpage.
---@return number: the total `tabs` in the state.
---@private
function State:refreshTabs(id)
    id = id or vim.api.nvim_get_current_tabpage()

    local refreshedTabs = {}

    for _, tab in pairs(self.tabs) do
        if tab.id ~= id and vim.api.nvim_tabpage_is_valid(tab.id) then
            table.insert(refreshedTabs, tab)
        end
    end

    self.tabs = refreshedTabs

    return #self.tabs
end


---Refresh the trees of the active state tab.
---
---@private
function State:refreshTrees()
    self.tabs[self.activeTab].wins.trees = self.scanTrees(self)
end

---Gets all wins that are not already registered in the given `tab`.
---
---@param withTrees boolean: whether we should consider external windows or not.
---@return table: the wins that are not in `tab`.
---@private
function State:getUnregisteredWins(withTrees)
    local wins = vim.api.nvim_tabpage_list_wins(self.activeTab)
    local stateWins = self.getRegisteredWins(self, true, true, withTrees)

    local validWins = {}

    for _, win in pairs(wins) do
        if not vim.tbl_contains(stateWins, win) and not A.isRelativeWindow(win) then
            table.insert(validWins, win)
        end
    end

    return validWins
end

---Gets all wins IDs that are registered in the state for the active tab.
---
---@param withMain boolean: whether we should consider main windows or not.
---@param withSplits boolean: whether we should consider splits windows or not.
---@param withTrees boolean: whether we should consider trees windows or not.
---@return table: the wins that are not in `tab`.
---@private
function State:getRegisteredWins(withMain, withSplits, withTrees)
    local wins = {}

    if withMain ~= nil and self.tabs[self.activeTab].wins.main ~= nil then
        for _, side in pairs(self.tabs[self.activeTab].wins.main) do
            table.insert(wins, side)
        end
    end

    if withSplits ~= nil and self.tabs[self.activeTab].wins.splits ~= nil then
        for _, split in pairs(self.tabs[self.activeTab].wins.splits) do
            table.insert(wins, split.id)
        end
    end

    if withTrees ~= nil and self.tabs[self.activeTab].wins.trees ~= nil then
        for _, tree in pairs(self.tabs[self.activeTab].wins.trees) do
            table.insert(wins, tree.id)
        end
    end

    return wins
end

---Whether the given `fileType` matches a supported side tree or not.
---
---@param scope string: caller of the method.
---@param win integer?: the id of the win
---@return boolean
---@return table|nil
---@private
function State:isSideTree(scope, win)
    win = win or 0
    local tab = self.getTabSafe(self)
    local buffer = vim.api.nvim_win_get_buf(win)
    local fileType = vim.api.nvim_buf_get_option(buffer, "filetype")

    if fileType == "" then
        fileType = vim.api.nvim_buf_get_name(buffer)
    end

    if fileType == "" and tab ~= nil then
        D.log(scope, "no name or filetype matching a tree, searching in wins...")

        local wins = self.getUnregisteredWins(self, false)

        if #wins ~= 1 or wins[1] == win then
            D.log(scope, "too many windows to determine")

            return false, nil
        end

        return self.isSideTree(self, scope, wins[1])
    end

    local registeredTrees = tab ~= nil and tab.wins.trees or trees

    for treeFileType, tree in pairs(registeredTrees) do
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
function State:scanTrees()
    local wins = vim.api.nvim_tabpage_list_wins(self.activeTab)
    local unregisteredTrees = vim.deepcopy(trees)

    for _, win in pairs(wins) do
        local isSideTree, external = self.isSideTree(self, "S.scanTrees", win)
        if isSideTree and external ~= nil then
            external.width = vim.api.nvim_win_get_width(win) * 2
            external.id = win

            unregisteredTrees[external.configName] = external
        end
    end

    return unregisteredTrees
end

-------------------------- checks

---Whether the `activeTab` is valid or not.
---
---@return boolean
---@private
function State:isActiveTabValid()
    return vim.api.nvim_tabpage_is_valid(self.activeTab)
end

---Whether the `activeTab` is registered in the state or not.
---
---@return boolean
---@private
function State:isActiveTabRegistered()
    return self.tabs[self.activeTab] ~= nil
end

---Whether the side window is registered and enabled in the config or not.
---
---@param side "left"|"right"|"curr": the side of the window.
---@return boolean
---@private
function State:isSideRegistered(side)
    if self.getSideID(self, side) == nil then
        return false
    end

    return _G.NoNeckPain.config.buffers[side].enabled
end

---Whether the side window is registered and a valid window.
---
---@param side "left"|"right"|"curr": the side of the window.
---@return boolean
---@private
function State:isSideWinValid(side)
    local id = self.tabs[self.activeTab].wins.main[side]

    return id ~= nil and vim.api.nvim_win_is_valid(id)
end

---Whether the side window is the currently active one or not.
---
---@param side "left"|"right"|"curr": the side of the window.
---@return boolean
---@private
function State:isSideTheActiveWin(side)
    return vim.api.nvim_get_current_win() == self.getSideID(self, side)
end

---Whether there is tabs registered or not.
---
---@return boolean
---@private
function State:hasTabs()
    return self.tabs ~= nil
end

---Whether there is splits registered in the active tab or not.
---
---@return boolean
---@private
function State:hasSplits()
    if not self.hasTabs(self) then
        return false
    end

    return self.tabs[self.activeTab].wins.splits ~= nil
end

-------------------------- setters and getters

---Returns the ID of the given `side`.
---
---@param side "left"|"right"|"curr": the side of the window.
---@return number
---@private
function State:getSideID(side)
    return self.tabs[self.activeTab].wins[side]
end

---Sets the ID of the given `side`.
---
---@param id number?: the id of the window.
---@param side "left"|"right"|"curr": the side of the window.
---@private
function State:setSideID(id, side)
    self.tabs[self.activeTab].wins[side] = id
end

---Sets the global state as enabled.
---
---@private
function State:setEnabled()
    self.enabled = true
end

---Sets the active tab.
---@param id number: the id of the active tab.
---
---@private
function State:setActiveTab(id)
    self.activeTab = id
end

---Set a split in the state at the given id.
---
---@param split table: the id of the split.
---
---@private
function State:setSplit(split)
    if self.tabs[self.activeTab].wins.splits == nil then
        self.tabs[self.activeTab].wins.splits = {}
    end

    self.tabs[self.activeTab].wins.splits[split.id] = split
end

---Gets the tab with the given `id` from the state.
---
---@param id number?: the id of the tab to get, fallbacks to the currently active one when `nil`.
---@return table: the `tab` information.
---@private
function State:getTab(id)
    id = id or self.activeTab or vim.api.nvim_get_current_tabpage()

    return self.tabs[id]
end


---Gets the tab with the given `id` from the state, safely returns nil if we are not sure it exists.
---
---@param id number?: the id of the tab to get, fallbacks to the currently active one when `nil`.
---@return table?: the `tab` information, or `nil` if it's not found.
---@private
function State:getTabSafe(id)
    if not self.hasTabs(self) then
        return nil
    end


    id = id or self.activeTab or vim.api.nvim_get_current_tabpage()

    return self.tabs[id]
end

---Sets the given `bool` value to the active tab scratchpad.
---
---@param bool boolean: the value of the scratchpad.
---@private
function State:setScratchpad(bool)
    self.tabs[self.activeTab].scratchPadEnabled = bool
end

---Gets the scratchpad value for the active tab.
---
---@private
function State:getScratchpad()
    return self.tabs[self.activeTab].scratchPadEnabled
end

---Register a new `tab` with the given `id` in the state.
---
---@param id number: the id of the tab.
---@private
function State:setTab(id)
    if self.tabs == nil then
        self.tabs = {}
    end


    self.tabs[id] = {
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
        },
    }

    self.tabs[id].wins.trees = self.initTrees(self)
end

---Sets the `layers` of the currently active tab.
---
---@param vsplit number?: the number of opened vsplits.
---@param split number?: the number of opened splits.
---@private
function State:setLayers(vsplit, split)
    if vsplit ~= nil then
        self.tabs[self.activeTab].layers.vsplit = vsplit
    end

    if vsplit ~= nil then
        self.tabs[self.activeTab].layers.split = split
    end
end

---Removes the split with the given `id` from the state.
---
---@param id number: the id of the split to remove.
---@private
function State:removeSplit(id)
    self.tabs[self.activeTab].wins.splits[id] = nil
end

---Decreases the layers of splits state values.
---
---@param isVSplit boolean: whether the window is a vsplit or not.
---@private
function State:decreaseLayers(isVSplit)
    local scope = isVSplit and 'vsplit' or 'split'

        self.tabs[self.activeTab].layers[scope] = self.tabs[self.activeTab].layers[scope] - 1

        if self.tabs[self.activeTab].layers[scope] < 1 then
            self.tabs[self.activeTab].layers[scope] = 1
        end
end

---Determines current state of the split/vsplit windows by comparing widths and heights.
---
---@param focusedWin number: the id of the current window.
---@return boolean: whether the current window is a vsplit or not.
---@private
function State:computeSplits(focusedWin)
    local side = self.getSideID(self, 'left') or self.getSideID(self, 'right')
    local sWidth, sHeight = 0, 0

    -- when side buffer exists we rely on them, otherwise we fallback to the UI
    if side ~= nil then
        local nbSide = 1

        if self.isSideRegistered(self, 'left') and self.isSideRegistered(self, 'right') then
            nbSide = 2
        end

        sWidth, sHeight = A.getWidthAndHeight(side)
        sWidth = vim.api.nvim_list_uis()[1].width - sWidth * nbSide
    else
        sWidth = vim.api.nvim_list_uis()[1].width
        sHeight = vim.api.nvim_list_uis()[1].height
    end

    local fWidth, fHeight = A.getWidthAndHeight(focusedWin)
    local isVSplit = true

    local splitInF = math.floor(sHeight / fHeight)
    if splitInF < 1 then
        splitInF = 1
    end

    if splitInF > self.tabs[self.activeTab].layers.split then
        isVSplit = false
    end

    local vsplitInF = math.floor(sWidth / fWidth)
    if vsplitInF < 1 then
        vsplitInF = 1
    end

    if vsplitInF > self.tabs[self.activeTab].layers.vsplit then
        isVSplit = true
    end

    -- update anyway because we want state consistency
    self.setLayers(self, vsplitInF, splitInF)

    D.log(
        "Sp.compute",
        "[split %d | vsplit %d] new split, vertical: %s",
        self.tabs[self.activeTab].layers.split,
        self.tabs[self.activeTab].layers.vsplit,
        isVSplit
    )

    return isVSplit
end

return State
