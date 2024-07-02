local A = require("no-neck-pain.util.api")
local Co = require("no-neck-pain.util.constants")
local D = require("no-neck-pain.util.debug")

local State = { enabled = false, activeTab = A.getCurrentTab(), tabs = nil }

---Sets the state to its original value.
---
---@private
function State:init()
    self.enabled = false
    self.activeTab = A.getCurrentTab()
    self.tabs = nil
end

---Saves the state in the global _G.NoNeckPain.state object.
---
---@private
function State:save()
    _G.NoNeckPain.state = self
end

---Initializes the vsplits to an empty table.
---
---@private
function State:initVSplits()
    self.tabs[self.activeTab].wins.vsplits = {}
end

---Gets the tab vsplits counter.
---
---@return table: the vsplits window IDs.
---@return number: the number of vsplits.
---@private
function State:getVSplits()
    return self.tabs[self.activeTab].wins.vsplits, A.length(self.tabs[self.activeTab].wins.vsplits)
end

---Whether the side is enabled in the config or not.
---
---@param side "left"|"right": the side of the window.
---@return boolean
---@private
function State:isSideEnabled(side)
    return _G.NoNeckPain.config.buffers[side].enabled
end

---Gets all integrations.
---
---@return table: the integration infos.
---@private
function State:getIntegrations()
    return self.tabs[self.activeTab].wins.integrations
end

---Iterates over the tabs in the state to remove invalid tabs.
---
---@param id number?: the `id` of the tab to remove from the state, defaults to the current tabpage.
---@return number: the total `tabs` in the state.
---@private
function State:refreshTabs(id)
    id = id or A.getCurrentTab()

    local refreshedTabs = {}

    for _, tab in pairs(self.tabs) do
        if tab.id ~= id and vim.api.nvim_tabpage_is_valid(tab.id) then
            refreshedTabs[tab.id] = tab
        end
    end

    if #refreshedTabs == 0 then
        self.tabs = nil

        return 0
    end

    self.tabs = refreshedTabs

    return #self.tabs
end

---Refresh the integrations of the active state tab.
---
---@param scope string: the caller of the method.
---@private
function State:refreshIntegrations(scope)
    self.tabs[self.activeTab].wins.integrations = self.scanIntegrations(self, scope)
end

---Closes side integrations if opened.
---
---@return boolean: whether we closed something or not.
---@private
function State:closeIntegration()
    local wins = vim.api.nvim_list_wins()
    local hasClosedIntegration = false

    for name, opts in pairs(self.tabs[self.activeTab].wins.integrations) do
        if opts.id ~= nil and opts.close ~= nil then
            local scope = string.format("closeIntegration:%s", name)
            -- if this integration doesn't belong to any side we don't have to
            -- close it to redraw side buffers
            local side = _G.NoNeckPain.config.integrations[name].position
            if side ~= "left" and side ~= "right" then
                D.log(scope, "skipped because not a side integration")

                goto continue
            end

            -- first element in the current wins list means it's the far left one,
            -- if the integration is already at this spot then we don't have to close anything
            if side == "left" and wins[1] == self.tabs[self.activeTab].wins.main[side] then
                D.log(scope, "skipped because already at the far left side")

                goto continue
            end

            -- last element in the current wins list means it's the far right one,
            -- if the integration is already at this spot then we don't have to close anything
            if side == "right" and wins[#wins] == self.tabs[self.activeTab].wins.main[side] then
                D.log(scope, "skipped because already at the far right side")

                goto continue
            end

            D.log(string.format("closeIntegration:%s", name), "integration was opened")

            vim.cmd(opts.close)
            hasClosedIntegration = true
        end
        ::continue::
    end

    return hasClosedIntegration
end

---Reopens the integrations if they were previously closed.
---
---@private
function State:reopenIntegration()
    for name, opts in pairs(self.tabs[self.activeTab].wins.integrations) do
        if
            opts.id ~= nil
            and opts.open ~= nil
            and _G.NoNeckPain.config.integrations[name].reopen == true
        then
            D.log(string.format("reopenIntegration:%s", name), "integration was closed previously")

            vim.cmd(opts.open)
        end
    end
end

---Gets the integration with the given `win` if it's already registered.
---
---@param id integer: the integration to search for.
---@return string?: the integration name.
---@return table?: the integration infos.
---@private
function State:getIntegration(id)
    if
        not self.enabled
        or not self.hasTabs(self)
        or self.getTab(self) == nil
        or self.tabs[self.activeTab].wins.integrations == nil
    then
        return nil, nil
    end

    for name, opts in pairs(self.tabs[self.activeTab].wins.integrations) do
        if opts.id ~= nil and opts.id == id then
            return name, opts
        end
    end

    return nil, nil
end

---Gets all wins that are not already registered in the given `tab`.
---
---@param withCurr boolean?: whether we should filter curr or not
---@return table: the wins that are not in `tab`.
---@private
function State:getUnregisteredWins(withCurr)
    return vim.tbl_filter(function(win)
        if A.isRelativeWindow(win) then
            return false
        end

        if not withCurr and win == self.getSideID(self, "curr") then
            return false
        end

        if win == self.getSideID(self, "left") or win == self.getSideID(self, "right") then
            return false
        end

        return true
    end, vim.api.nvim_tabpage_list_wins(self.activeTab))
end

---Whether the given `fileType` matches a supported integration or not.
---
---@param scope string: caller of the method.
---@param win integer?: the id of the win
---@return boolean: whether the current win is a integration or not.
---@return string?: the supported integration name.
---@return table?: the supported integration infos.
---@private
function State:isSupportedIntegration(scope, win)
    win = win or 0
    local tab = self.getTabSafe(self)
    local buffer = vim.api.nvim_win_get_buf(win)
    local fileType = vim.api.nvim_buf_get_option(buffer, "filetype")

    local integrationName, integrationInfo = self.getIntegration(self, win)
    if integrationName and integrationInfo then
        D.log(scope, "integration already registered, skipping computing...")

        return true, integrationName, integrationInfo
    end

    if fileType == "" and tab ~= nil then
        local wins = self.getUnregisteredWins(self)

        D.log(scope, "computing recursively")
        if #wins ~= 1 or wins[1] == win then
            D.log(scope, "too many windows to determine")

            return false, nil, nil
        end

        return self.isSupportedIntegration(self, scope, wins[1])
    end

    local registeredIntegrations = tab ~= nil and tab.wins.integrations or Co.INTEGRATIONS

    for name, integration in pairs(registeredIntegrations) do
        if vim.startswith(string.lower(fileType), integration.fileTypePattern) then
            D.log(scope, "win '%d' is an integration '%s'", win, fileType)

            if tab ~= nil then
                return true, name, integration
            end

            return true, nil
        end
    end

    return false, nil
end

---Scans the current tab wins to update registered side integrations.
---
---@param scope string: the caller of the method.
---@return table: the update state integrations table.
---@private
function State:scanIntegrations(scope)
    local wins = self.getUnregisteredWins(self)
    local unregisteredIntegrations = vim.deepcopy(Co.INTEGRATIONS)

    for _, win in pairs(wins) do
        local supported, name, integration = self.isSupportedIntegration(self, scope, win)
        if supported and name and integration then
            integration.width = vim.api.nvim_win_get_width(win) * 2
            integration.id = win

            unregisteredIntegrations[name] = integration
        end
    end

    return unregisteredIntegrations
end

---Whether the `activeTab` is registered in the state and valid.
---
---@return boolean
---@private
function State:isActiveTabRegistered()
    return self.hasTabs(self)
        and self.tabs[self.activeTab] ~= nil
        and vim.api.nvim_tabpage_is_valid(self.activeTab)
end

---Whether the side window is registered and enabled in the config or not.
---
---@param side "left"|"right"|"curr": the side of the window.
---@return boolean
---@private
function State:isSideRegistered(side)
    if not self.isActiveTabRegistered(self) then
        return false
    end

    if self.getSideID(self, side) == nil then
        return false
    end

    return _G.NoNeckPain.config.buffers[side].enabled
end

---Whether the sides window are registered and enabled in the config or not.
---
---@param condition "or"|"and"
---@param expected boolean
---@return boolean
---@private
function State:checkSides(condition, expected)
    if condition == "or" then
        return self.isSideRegistered(self, "left") == expected
            or self.isSideRegistered(self, "right") == expected
    end

    return self.isSideRegistered(self, "left") == expected
        and self.isSideRegistered(self, "right") == expected
end

---Whether the side window is registered and a valid window.
---
---@param side "left"|"right"|"curr": the side of the window.
---@return boolean
---@private
function State:isSideWinValid(side)
    local id = self.getSideID(self, side)

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

---Whether there is integrations registered in the active tab or not.
---
---@return boolean
---@private
function State:hasIntegrations()
    if not self.hasTabs(self) then
        return false
    end

    for _, integration in pairs(self.tabs[self.activeTab].wins.integrations) do
        if integration.id ~= nil then
            return true
        end
    end

    return false
end

---Whether the user wants both sides to be opened or not.
---
---@return boolean
---@private
function State:wantsSides()
    return _G.NoNeckPain.config.buffers.left.enabled and _G.NoNeckPain.config.buffers.right.enabled
end

---Returns the ID of the given `side`.
---
---@param side "left"|"right"|"curr": the side of the window.
---@return number
---@private
function State:getSideID(side)
    return self.tabs[self.activeTab].wins.main[side]
end

---Sets the ID of the given `side`.
---
---@param id number?: the id of the window.
---@param side "left"|"right"|"curr": the side of the window.
---@private
function State:setSideID(id, side)
    self.tabs[self.activeTab].wins.main[side] = id
end

---Sets the global state as enabled.
---
---@private
function State:setEnabled()
    self.enabled = true
end

---Creates a namespace for the given `side` and stores it in the state.
---
---@param side "left"|"right": the side.
---@return number: the created namespace id.
---@return string: the name of the created namespace.
---@private
function State:setNamespace(side)
    if self.namespaces == nil then
        self.namespaces = {}
    end

    local name = string.format("NoNeckPain_tab_%s_side_%s", self.activeTab, side)
    local id = vim.api.nvim_create_namespace(name)

    self.namespaces[side] = id

    return id, name
end

---Clears the given `side` namespace and resets its state value.
---
---@param bufnr number: the buffer number.
---@param side "left"|"right": the side.
---@private
function State:removeNamespace(bufnr, side)
    if self.namespaces == nil or self.namespaces[side] == nil then
        return
    end

    if not vim.api.nvim_buf_is_valid(bufnr) then
        return
    end

    vim.api.nvim_buf_clear_namespace(bufnr, self.namespaces[side], 0, -1)
end

---Sets the active tab.
---@param id number: the id of the active tab.
---
---@private
function State:setActiveTab(id)
    self.activeTab = id
end

---Gets the tab with the given `id` from the state.
---
---@return table: the `tab` information.
---@private
function State:getTab()
    local id = self.activeTab or A.getCurrentTab()

    return self.tabs[id]
end

---Gets the tab with the given `id` from the state, safely returns nil if we are not sure it exists.
---
---@return table?: the `tab` information, or `nil` if it's not found.
---@private
function State:getTabSafe()
    if not self.hasTabs(self) then
        return nil
    end

    return self.getTab(self)
end

---Sets the given `bool` value to the active tab scratchPad.
---
---@param bool boolean: the value of the scratchPad.
---@private
function State:setScratchPad(bool)
    self.tabs[self.activeTab].scratchPadEnabled = bool
end

---Gets the scratchPad value for the active tab.
---
---@return boolean: the value of the scratchPad.
---@private
function State:getScratchPad()
    return self.tabs[self.activeTab].scratchPadEnabled
end

---Register a new `tab` with the given `id` in the state.
---
---@param id number: the id of the tab.
---@private
function State:setTab(id)
    self.tabs = self.tabs or {}

    D.log("setTab", "registered new tab %d", id)

    self.tabs[id] = {
        id = id,
        scratchPadEnabled = false,
        wins = {
            vsplits = {},
            main = {
                curr = nil,
                left = nil,
                right = nil,
            },
            integrations = vim.deepcopy(Co.INTEGRATIONS),
        },
    }
    self.activeTab = id
end

---Insert the given ids window ids in the state.
---
---@param vsplits table: the vsplits leafs to add to the state.
---@private
function State:insertVSplits(vsplits)
    for _, vsplit in ipairs(vsplits) do
        -- only add the leaf because we can receive something like { "col" {...}}, which will then be walked in and inserted later
        if vsplit[1] == "leaf" then
            self.tabs[self.activeTab].wins.vsplits[vsplit[2]] = true
        end
    end
end

---Recursively walks in the `winlayout` until it has computed every column present in the UI.
---
---When we find a `row`, we set `vsplit` to true, the next element will always be a `table` so once on it -we can increase the `vsplits` counter.
---
---In order to also compute nested vsplits, we need to keep track how deep we are in the layout, we remove
---that depth from the number of elements in the current `row` in order to avoid counting all parents many times.
---
---@private
function State:walkLayout(parent, curr)
    for _, group in ipairs(curr) do
        if type(group) == "table" then
            -- a row indicates a `vsplit` window container
            if parent == "row" then
                -- we remove the depth from the len in order to avoid counting parents multiple times.
                self.insertVSplits(self, group)
                parent = nil
            end
            self.walkLayout(self, parent, group)
        -- depth 0 on a leaf is only possible after enabling nnp as there's nothing in the layout other than the main window
        elseif group == "leaf" and parent == nil then
            self.insertVSplits(self, { curr })
        elseif type(group) == "string" then
            parent = group
        end
    end
end

---Refresh vsplits state based on the `winlayout`.
---
---@param scope string: the caller of the method.
---@return boolean: whether the number of vsplits changed or not.
---@private
function State:refreshVSplits(scope)
    local _, nbVSplits = self.getVSplits(self)

    self.initVSplits(self)

    self.walkLayout(self, nil, vim.fn.winlayout(self.activeTab))

    D.log(scope, "computed %d vsplits", nbVSplits)

    self.save(self)

    local _, nbNBVsplits = self.getVSplits(self)

    -- TODO: real table diff
    return nbVSplits ~= nbNBVsplits
end

return State
