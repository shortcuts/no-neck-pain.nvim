local A = require("no-neck-pain.util.api")
local Co = require("no-neck-pain.util.constants")
local D = require("no-neck-pain.util.debug")

local State = { enabled = false, active_tab = A.get_current_tab(), tabs = {} }

---Sets the state to its original value.
---
---@private
function State:init()
    self.enabled = false
    self.active_tab = A.get_current_tab()
    self.tabs = {}
end

---Sets the integrations state of the current tab to its original value.
---
---@private
function State:init_integrations()
    self.tabs[self.active_tab].wins.integrations = vim.deepcopy(Co.INTEGRATIONS)
end

---Sets the columns state of the current tab to its original value.
---
---@private
function State:init_columns()
    self.tabs[self.active_tab].wins.columns = 0
end

---Saves the state in the global _G.NoNeckPain.state object.
---
---@private
function State:save()
    _G.NoNeckPain.state = self
end

---Gets the columns count in the current layout.
---
---@return table: the columns window IDs.
---@private
function State:get_columns()
    return self.tabs[self.active_tab].wins.columns
end

---Consumes the redraw value in the state, in order to know if we should redraw sides or not.
---
---@return boolean
---@private
function State:consume_redraw()
    local redraw = self.tabs[self.active_tab].redraw

    self.tabs[self.active_tab].redraw = false

    return redraw
end

---Whether the side is enabled in the config or not.
---
---@param side "left"|"right"|"curr": the side of the window.
---@return boolean
---@private
function State:is_side_enabled(side)
    return _G.NoNeckPain.config.buffers[side].enabled
end

---Gets all integrations.
---
---@return table: the integration infos.
---@private
function State:get_integrations()
    return self.tabs[self.active_tab].wins.integrations
end

---Iterates over the tabs in the state to remove invalid tabs.
---
---@param scope string: caller of the method.
---@param skip_id number?: the ID to skip from potentially valid tabs.
---@return number: the total `tabs` in the state.
---@private
function State:refresh_tabs(scope, skip_id)
    D.log(scope, "refreshing tabs...")

    for _, tab in pairs(self.tabs) do
        if tab.id == skip_id or not vim.api.nvim_tabpage_is_valid(tab.id) then
            self.tabs[tab.id] = nil
        end
    end

    local len = vim.tbl_count(self.tabs)

    if len == 0 then
        self.init(self)
    end

    return len
end

---Closes side integrations if opened.
---
---@return boolean: whether we closed something or not.
---@private
function State:close_integration()
    local wins = vim.api.nvim_list_wins()
    local has_closed_integration = false

    for name, opts in pairs(self.tabs[self.active_tab].wins.integrations) do
        if opts.id ~= nil and opts.close ~= nil then
            local scope = string.format("close_integration:%s", name)
            -- if this integration doesn't belong to any side we don't have to
            -- close it to redraw side buffers
            local side = _G.NoNeckPain.config.integrations[name].position
            if side ~= "left" and side ~= "right" then
                D.log(scope, "skipped because not a side integration")

                goto continue
            end

            -- first element in the current wins list means it's the far left one,
            -- if the integration is already at this spot then we don't have to close anything
            if side == "left" and wins[1] == self.tabs[self.active_tab].wins.main[side] then
                D.log(scope, "skipped because already at the far left side")

                goto continue
            end

            -- last element in the current wins list means it's the far right one,
            -- if the integration is already at this spot then we don't have to close anything
            if side == "right" and wins[#wins] == self.tabs[self.active_tab].wins.main[side] then
                D.log(scope, "skipped because already at the far right side")

                goto continue
            end

            D.log(string.format("close_integration:%s", name), "integration was opened")

            vim.cmd(opts.close)
            has_closed_integration = true
        end
        ::continue::
    end

    return has_closed_integration
end

---Reopens the integrations if they were previously closed.
---
---@private
function State:reopen_integration()
    for name, opts in pairs(self.tabs[self.active_tab].wins.integrations) do
        if
            opts.id ~= nil
            and opts.open ~= nil
            and _G.NoNeckPain.config.integrations[name].reopen == true
        then
            D.log(string.format("reopen_integration:%s", name), "integration was closed previously")

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
function State:get_integration(id)
    if
        not self.enabled
        or not self.has_tabs(self)
        or self.get_tab(self) == nil
        or self.tabs[self.active_tab].wins.integrations == nil
    then
        return nil, nil
    end

    for name, opts in pairs(self.tabs[self.active_tab].wins.integrations) do
        if opts.id ~= nil and opts.id == id then
            return name, opts
        end
    end

    return nil, nil
end

---Gets wins that are not relative or main wins.
---
---@return table: the list of windows IDs.
---@private
function State:get_unregistered_wins()
    return vim.tbl_filter(function(win)
        return not A.is_relative_window(win)
            and win ~= self.get_side_id(self, "curr")
            and win ~= self.get_side_id(self, "left")
            and win ~= self.get_side_id(self, "right")
            and not self.is_supported_integration(self, "_", win)
    end, vim.api.nvim_tabpage_list_wins(self.active_tab))
end

---Whether the given `filetype` matches a supported integration or not.
---
---@param scope string: caller of the method.
---@param win integer?: the id of the win
---@return boolean: whether the current win is a integration or not.
---@return string?: the supported integration name.
---@return table?: the supported integration infos.
---@private
function State:is_supported_integration(scope, win)
    win = win or 0
    local tab = self.get_tab_safe(self)
    local buffer = vim.api.nvim_win_get_buf(win)
    local filetype = vim.api.nvim_buf_get_option(buffer, "filetype")

    local integration_name, integration_info = self.get_integration(self, win)
    if integration_name and integration_info then
        D.log(scope, "integration already registered, skipping computing...")

        return true, integration_name, integration_info
    end

    local registered_integrations = tab ~= nil and tab.wins.integrations or Co.INTEGRATIONS

    for name, integration in pairs(registered_integrations) do
        if vim.startswith(string.lower(filetype), integration.fileTypePattern) then
            D.log(scope, "win '%d' is an integration '%s'", win, filetype)

            if tab ~= nil then
                return true, name, integration
            end

            return true, nil
        end
    end

    return false, nil
end

---Whether the `active_tab` is registered in the state and valid.
---
---@return boolean
---@private
function State:is_active_tab_registered()
    return self.has_tabs(self)
        and self.tabs[self.active_tab] ~= nil
        and vim.api.nvim_tabpage_is_valid(self.active_tab)
end

---Returns true if the win isn't registered, or if it is and valid, false otherwise.
---
---@param side "left"|"right": the side of the window.
---@return boolean
---@private
function State:is_side_win_valid(side)
    if not self.is_side_enabled(self, side) then
        return true
    end

    local id = self.get_side_id(self, side)

    return id ~= nil and vim.api.nvim_win_is_valid(id)
end

---Whether the side window is registered and a valid window.
---
---@param side "left"|"right"|"curr": the side of the window.
---@return boolean
---@private
function State:is_side_win_valid(side)
    if side ~= "curr" and not self.is_side_enabled(self, side) then
        return false
    end

    local id = self.get_side_id(self, side)

    return id ~= nil and vim.api.nvim_win_is_valid(id)
end

---Whether the sides window are registered and enabled in the config or not.
---
---@param condition "or"|"and"
---@param expected boolean
---@return boolean
---@private
function State:check_sides(condition, expected)
    if condition == "or" then
        return self.is_side_win_valid(self, "left") == expected
            or self.is_side_win_valid(self, "right") == expected
    end

    return self.is_side_win_valid(self, "left") == expected
        and self.is_side_win_valid(self, "right") == expected
end

---Whether the side window is the currently active one or not.
---
---@param side "left"|"right"|"curr": the side of the window.
---@return boolean
---@private
function State:is_side_the_active_win(side)
    return vim.api.nvim_get_current_win() == self.get_side_id(self, side)
end

---Whether there is tabs registered or not.
---
---@return boolean
---@private
function State:has_tabs()
    return self.tabs ~= nil
end

---Whether there is integrations registered in the active tab or not.
---
---@return boolean
---@private
function State:has_integrations()
    if not self.has_tabs(self) then
        return false
    end

    for _, integration in pairs(self.tabs[self.active_tab].wins.integrations) do
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
function State:wants_sides()
    return _G.NoNeckPain.config.buffers.left.enabled and _G.NoNeckPain.config.buffers.right.enabled
end

---Returns the ID of the given `side`.
---
---@param side "left"|"right"|"curr": the side of the window.
---@return number
---@private
function State:get_side_id(side)
    return self.tabs[self.active_tab].wins.main[side]
end

---Sets the ID of the given `side`.
---
---@param id number?: the id of the window.
---@param side "left"|"right"|"curr": the side of the window.
---@private
function State:set_side_id(id, side)
    self.tabs[self.active_tab].wins.main[side] = id
end

---Sets the global state as enabled.
---
---@private
function State:set_enabled()
    self.enabled = true
end

---Creates a namespace for the given `side` and stores it in the state.
---
---@param side "left"|"right": the side.
---@return number: the created namespace id.
---@return string: the name of the created namespace.
---@private
function State:set_namespace(side)
    if self.namespaces == nil then
        self.namespaces = {}
    end

    local name = string.format("NoNeckPain_tab_%s_side_%s", self.active_tab, side)
    local id = vim.api.nvim_create_namespace(name)

    self.namespaces[side] = id

    return id, name
end

---Clears the given `side` namespace and resets its state value.
---
---@param bufnr number: the buffer number.
---@param side "left"|"right": the side.
---@private
function State:remove_namespace(bufnr, side)
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
function State:set_active_tab(id)
    self.active_tab = id
end

---Gets the tab with the given `id` from the state.
---
---@return table: the `tab` information.
---@private
function State:get_tab()
    local id = self.active_tab or A.get_current_tab()

    return self.tabs[id]
end

---Gets the tab with the given `id` from the state, safely returns nil if we are not sure it exists.
---
---@return table?: the `tab` information, or `nil` if it's not found.
---@private
function State:get_tab_safe()
    if not self.has_tabs(self) then
        return nil
    end

    return self.get_tab(self)
end

---Sets the given `bool` value to the active tab scratchPad.
---
---@param bool boolean: the value of the scratchPad.
---@private
function State:set_scratchPad(bool)
    self.tabs[self.active_tab].scratchpad_enabled = bool
end

---Gets the scratchPad value for the active tab.
---
---@return boolean: the value of the scratchPad.
---@private
function State:get_scratchPad()
    return self.tabs[self.active_tab].scratchpad_enabled
end

---Register a new `tab` with the given `id` in the state.
---
---@param id number: the id of the tab.
---@private
function State:set_tab(id)
    D.log("set_tab", "registered new tab %d", id)

    self.tabs[id] = {
        id = id,
        scratchpad_enabled = false,
        wins = {
            columns = 0,
            main = {
                curr = nil,
                left = nil,
                right = nil,
            },
            integrations = vim.deepcopy(Co.INTEGRATIONS),
        },
    }
    self.active_tab = id
end

---Increases the columns if the encountered window of the given table is not an integration, otherwise sets the integration.
---When a column in encountered, it counts for a column but we don't consider its child windows, it will be walked in at a later time.
---
---@param scope string: the caller of the method.
---@param wins table: the layout windows.
---@private
function State:set_layout_windows(scope, wins)
    for _, win in ipairs(wins) do
        local id = win[2]
        if win[1] == "leaf" and not A.is_relative_window(id) then
            local supported, name, integration = self.is_supported_integration(self, scope, id)
            if supported and name and integration then
                integration.width = vim.api.nvim_win_get_width(id) * 2
                integration.id = id

                self.tabs[self.active_tab].redraw = true
                self.tabs[self.active_tab].wins.integrations[name] = integration
            end
            self.tabs[self.active_tab].wins.columns = self.tabs[self.active_tab].wins.columns + 1
        elseif win[1] == "col" then
            self.tabs[self.active_tab].wins.columns = self.tabs[self.active_tab].wins.columns + 1
        end
    end
end

---Recursively walks in the `winlayout` until it has computed every column present.
---
---When a leaf is 'col', we walk in the next element (its windows), and keep track of the previous 'col' origin in order to deduce it from the potential 'row'.
---When a leaf is 'row', if we had a column previously, we remove 1 element from the next element (its windows), because at least 1 window is also part of this column. If there was no column, we consider every leafs in the row.
---When a leaf is a table that contains a 'col' or 'row', we directly walk in it.
---
---@param scope string: the caller of the method.
---@param tree table: the tree to walk in.
---@param has_col_parent boolean: whether or not the previous walked tree was a column.
---@private
function State:walk_layout(scope, tree, has_col_parent)
    -- col -- represents a vertical association of window, e.g. { { "leaf", int }, { "col", { ... } }, { "row", { ...} } }
    -- row -- represents an horizontal association of window, e.g  { { "leaf", int }, { "col", { ... } }, { "row", { ...} } }
    -- leaf -- represents a window, e.g. { "leaf", int }

    if tree == nil then
        return
    end

    -- D.log(scope, "new layer entered%s: %s", has_col_parent and " from col" or "", vim.inspect(tree))
    for idx, leaf in ipairs(tree) do
        if leaf == "row" then
            local leafs = tree[idx + 1]
            -- if on a row we were on a col, then it means one iteam of the row must be of the same width as a col one
            if has_col_parent and vim.tbl_count(leafs) > 1 then
                table.remove(leafs, 1)
            end
            self.set_layout_windows(self, scope, leafs)
            self.walk_layout(self, scope, tree[idx + 1], false)
        elseif leaf == "col" then
            self.walk_layout(self, scope, tree[idx + 1], true)
        elseif type(leaf) == "table" and type(leaf[1]) == "string" then
            self.walk_layout(self, scope, leaf, has_col_parent)
        end
    end
end

---Scans the winlayout in order to identify window position and type.
---
---@param scope string: the caller of the method.
---@return boolean: whether the number of columns changed or not.
---@private
function State:scan_layout(scope)
    local columns = self.get_columns(self)

    self.init_columns(self)
    self.init_integrations(self)

    local layout = vim.fn.winlayout(self.active_tab)

    -- basically when opening vim with nnp autocmds, nothing else than a curr window
    if layout[1] == "leaf" then
        self.set_layout_windows(self, scope, { layout })
    -- when a helper or vsplit takes most of the width
    elseif layout[1] == "col" and vim.tbl_count(layout) == 2 then
        self.walk_layout(self, scope, layout[2], false)
    else
        self.walk_layout(self, scope, layout, false)
    end
    self.save(self)

    D.log(
        scope,
        "[tab %d] computed columns: %d - %d",
        self.active_tab,
        columns,
        self.get_columns(self)
    )

    return columns ~= self.get_columns(self)
end

return State
