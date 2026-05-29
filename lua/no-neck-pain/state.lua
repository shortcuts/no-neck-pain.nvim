--- Global state management for the plugin
---
--- Tracks tabs, windows, integrations, and layout state across editor sessions.
---
---@module "no-neck-pain.state"

local api = require("no-neck-pain.util.api")
local log = require("no-neck-pain.util.log")
local helpers = require("no-neck-pain.util.helpers")

----- default values and toggles =======================================================
---@private

local state = {
    enabled = false,
    active_tab = api.get_current_tab(),
    tabs = {},
    disabled_tabs = {},
    initial_window_opts = {},
    previously_focused_win = vim.api.nvim_get_current_win(),
}

--- Captures initial window options from the current normal window.
--- Only captures if initial_window_opts is empty (first time).
--- Should be called before side buffers are created to capture user's configured options.
---
---@private
function state:capture_initial_window_opts()
    if self.initial_window_opts ~= nil and next(self.initial_window_opts) ~= nil then
        return
    end

    local current_win = vim.api.nvim_get_current_win()

    if api.is_relative_window(current_win) then
        return
    end

    self.initial_window_opts = {}

    -- keep this list in sync with config.NoNeckPain.bufferOptionsWo
    for _, opt in ipairs({
        "colorcolumn",
        "cursorcolumn",
        "cursorline",
        "foldenable",
        "linebreak",
        "list",
        "number",
        "relativenumber",
        "wrap",
    }) do
        self.initial_window_opts[opt] = vim.api.nvim_get_option_value(opt, { win = current_win })
    end
end

--- Sets the state to its original value.
---
---@private
function state:init()
    self.enabled = false
    self.active_tab = api.get_current_tab()
    self.tabs = {}
end

--- Sets the integrations state of the current tab to its original value.
---
---@private
function state:init_integrations()
    if not (self:has_tabs() and self.tabs[self.active_tab]) then
        return
    end
    self.tabs[self.active_tab].wins.integrations = {}

    -- normalize to lowercase
    for name, opts in pairs(vim.deepcopy(helpers.get_config_field("integrations"))) do
        local lower_name = string.lower(name)
        self.tabs[self.active_tab].wins.integrations[lower_name] = opts
    end
end

--- Sets the columns state of the current tab to its original value.
---
---@private
function state:init_columns()
    if not (self:has_tabs() and self.tabs[self.active_tab]) then
        return
    end
    self.tabs[self.active_tab].wins.columns = 0
    self.tabs[self.active_tab].wins.none_columns = 0
end

--- Saves the state in the global _G.NoNeckPain.state object.
---
---@private
function state:save()
    helpers.set_state(self)
end

--- Sets the global state as enabled.
---
---@private
function state:set_enabled()
    self.enabled = true
end

----- tab tracker =======================================================
---@private

--- Whether the `active_tab` is registered in the state and valid.
---
---@return boolean
---@private
function state:is_active_tab_registered()
    return self:has_tabs()
        and self.tabs[self.active_tab] ~= nil
        and vim.api.nvim_tabpage_is_valid(self.active_tab)
end

--- Whether there is tabs registered or not.
---
---@return boolean
---@private
function state:has_tabs()
    return self.tabs ~= nil
end

--- Sets the active tab.
---@param id number: the id of the active tab.
---
---@private
function state:set_active_tab(id)
    self.active_tab = id
end

--- Gets the tab with the given `id` from the state, safely returns nil if we are not sure it exists.
---
---@return table?: the `tab` information, or `nil` if it's not found.
---@private
function state:get_tab()
    if not self:has_tabs() then
        return nil
    end

    local id = self.active_tab or api.get_current_tab()

    return self.tabs[id]
end

--- Iterates over the tabs in the state to remove invalid tabs.
---
---@param scope string: caller of the method.
---@param skip_id number?: the ID to skip from potentially valid tabs.
---@return number: the total `tabs` in the state.
---@private
function state:refresh_tabs(scope, skip_id)
    log.debug(scope, "refreshing tabs...")

    for _, tab in pairs(self.tabs) do
        if tab.id == skip_id or not vim.api.nvim_tabpage_is_valid(tab.id) then
            if self.tabs[tab.id] then
                self.tabs[tab.id] = nil
            end
        end
    end

    local len = vim.tbl_count(self.tabs)

    if len == 0 then
        self:init()
    end

    return len
end

--- Register a new `tab` with the given `id` in the state.
---
---@param id number: the id of the tab.
---@private
function state:set_tab(id)
    log.debug("set_tab", "registered new tab %d", id)

    self.tabs[id] = {
        id = id,
        scratchpad_enabled = false,
        redraw = false,
        wins = {
            columns = 0,
            none_columns = 0,
            main = {
                curr = nil,
                left = nil,
                right = nil,
            },
            integrations = {},
        },
    }
    self.active_tab = id
end

----- disabled tabs ====================================================
---@private

--- Registers the given `id` as manually disabled tabs.
---
---@param id number: the id of the tab.
---@private
function state:set_tab_disabled(id)
    self.disabled_tabs[id] = true
end

--- Removes the currently active tab from the disabled ones.
---
---@private
function state:remove_active_tab_from_disabled()
    self.disabled_tabs[self.active_tab] = nil
end

--- Whether the currently active tab has been manually disabled or not.
---
---@return boolean
---@private
function state:is_active_tab_disabled()
    return self.disabled_tabs[self.active_tab]
end

----- integrations tracker ====================================================
---@private

--- Gets all integrations.
---
---@return table: the integration infos.
---@private
function state:get_integrations()
    if not (self:has_tabs() and self.tabs[self.active_tab] ~= nil) then
        return {}
    end
    return self.tabs[self.active_tab].wins.integrations
end

--- Gets the integration with the given `win` if it's already registered.
---
---@param id integer: the integration to search for.
---@return string?: the integration name.
---@return table?: the integration infos.
---@private
function state:get_integration(id)
    if
        not self.enabled
        or self:get_tab() == nil
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

--- Whether the given `filetype` matches a supported integration or not.
---
---@param scope string: caller of the method.
---@param win integer: the id of the win
---@return boolean: whether the current win is a integration or not.
---@return string?: the supported integration name.
---@return table?: the supported integration infos.
---@private
function state:is_supported_integration(scope, win)
    if win == nil or not vim.api.nvim_win_is_valid(win) then
        return false
    end

    local buffer = vim.api.nvim_win_get_buf(win)
    local filetype = vim.api.nvim_get_option_value("filetype", { buf = buffer })

    local integration_name, integration_info = self:get_integration(win)
    if integration_name and integration_info then
        log.debug(scope, "integration already registered, skipping computing...")

        return true, integration_name, integration_info
    end

    local lowercase_filetype = string.lower(filetype)

    for name, integration in pairs(self:get_integrations()) do
        if name == lowercase_filetype or string.find(lowercase_filetype, name) then
            log.debug(scope, "win '%d' is an integration '%s'", win, filetype)

            return true, name, integration
        end
    end

    return false, nil
end

----- side buffers =======================================================
---@private

--- Side window state queries:
--- - is_side_enabled: checks if enabled in config
--- - is_side_valid: checks if window is created and valid
--- - is_side_focused: checks if window is currently focused

--- Whether the side is enabled in the config or not.
---
---@param side "left"|"right"|"curr": the side of the window.
---@return boolean
---@private
function state:is_side_enabled(side)
    local buffers = helpers.get_config_field("buffers")
    if buffers == nil or buffers[side] == nil then
        return false
    end
    return buffers[side].enabled
end

--- Whether the side window is registered and a valid window.
---
---@param side "left"|"right"|"curr": the side of the window.
---@return boolean
---@private
function state:is_side_valid(side)
    if side ~= "curr" and not self:is_side_enabled(side) then
        return false
    end

    local id = self:get_side_id(side)

    return id ~= nil and vim.api.nvim_win_is_valid(id)
end

--- Whether the side window is the currently focused one or not.
---
---@param side "left"|"right"|"curr": the side of the window.
---@return boolean
---@private
function state:is_side_focused(side)
    return vim.api.nvim_get_current_win() == self:get_side_id(side)
end

--- Returns the ID of the given `side`.
---
---@param side "left"|"right"|"curr": the side of the window.
---@return number?
---@private
function state:get_side_id(side)
    if not (self:has_tabs() and self.tabs[self.active_tab] ~= nil) then
        return nil
    end
    return self.tabs[self.active_tab].wins.main[side]
end

--- Sets the ID of the given `side`.
---
---@param id number?: the id of the window.
---@param side "left"|"right"|"curr": the side of the window.
---@private
function state:set_side_id(id, side)
    if not (self:has_tabs() and self.tabs[self.active_tab] ~= nil) then
        return
    end
    self.tabs[self.active_tab].wins.main[side] = id
end

--- Gets wins that are not relative or main wins.
---
---@param scope string: caller of the method.
---@return table: the list of windows IDs.
---@private
function state:get_unregistered_wins(scope)
    return vim.tbl_filter(function(win)
        return not api.is_relative_window(win)
            and win ~= self:get_side_id("left")
            and win ~= self:get_side_id("right")
            and not self:is_supported_integration(scope, win)
    end, vim.api.nvim_tabpage_list_wins(self.active_tab))
end

----- layout =======================================================
---@private

--- Resizes a window if it's valid.
---
---@param scope string: the caller of the method.
---@param side "left"|"right"|"curr": the side of the window.
---@param width number: the width to apply to the window.
---@private
function state:resize_win(scope, side, width)
    local id = self:get_side_id(side)

    log.debug(scope, "win %d with width %d", id, width)

    if id ~= nil and vim.api.nvim_win_is_valid(id) then
        vim.api.nvim_win_set_width(id, width)
    else
        log.debug(scope, "win is not valid")
    end
end

--- Gets the columns count in the current layout.
---
---@return table?: the columns window IDs.
---@private
function state:get_columns()
    if not (self:has_tabs() and self.tabs[self.active_tab] ~= nil) then
        return nil
    end
    return self.tabs[self.active_tab].wins.columns
end

---@return number: the number of columns occupied by position="none" integrations.
---@private
function state:get_none_columns()
    if not (self:has_tabs() and self.tabs[self.active_tab] ~= nil) then
        return 0
    end
    return self.tabs[self.active_tab].wins.none_columns or 0
end

--- Consumes the redraw value in the state, in order to know if we should redraw sides or not.
---
---@return boolean
---@private
function state:consume_redraw()
    if not (self:has_tabs() and self.tabs[self.active_tab] ~= nil) then
        return false
    end
    local redraw = self.tabs[self.active_tab].redraw

    self.tabs[self.active_tab].redraw = false

    return redraw
end

--- Increases the columns if the encountered window of the given table is not an integration, otherwise sets the integration.
--- When a column in encountered, it counts for a column but we don't consider its child windows, it will be walked in at a later time.
---
---@param scope string: the caller of the method.
---@param wins table: the layout windows.
---@private
function state:set_layout_windows(scope, wins)
    if not (self:has_tabs() and self.tabs[self.active_tab]) then
        return
    end
    for _, win in ipairs(wins) do
        local id = win[2]
        if win[1] == "leaf" and not api.is_relative_window(id) then
            self.tabs[self.active_tab].wins.columns = self.tabs[self.active_tab].wins.columns + 1
            if id ~= self:get_side_id("curr") then
                local supported, name, integration = self:is_supported_integration(scope, id)
                if supported and name and integration then
                    integration.id = id

                    self.tabs[self.active_tab].redraw = true
                    self.tabs[self.active_tab].wins.integrations[name] = integration
                end
                if supported and integration and integration.position == "none" then
                    self.tabs[self.active_tab].wins.none_columns = self.tabs[self.active_tab].wins.none_columns
                        + 1
                end
            end
        elseif win[1] == "col" then
            self.tabs[self.active_tab].wins.columns = self.tabs[self.active_tab].wins.columns + 1
            -- scan leaf children of the col for integrations (e.g. snacks explorer)
            self:_scan_col_children(scope, win[2])
        end
    end
end

--- Recursively walks in the `winlayout` until it has computed every column present.
---
--- When a leaf is 'col', we walk in the next element (its windows), and keep track of the previous 'col' origin in order to deduce it from the potential 'row'.
--- When a leaf is 'row', if we had a column previously, we remove 1 element from the next element (its windows), because at least 1 window is also part of this column. If there was no column, we consider every leafs in the row.
--- When a leaf is a table that contains a 'col' or 'row', we directly walk in it.
---
---@param scope string: the caller of the method.
---@param tree table: the tree to walk in.
---@param has_col_parent boolean: whether or not the previous walked tree was a column.
---@private
function state:walk_layout(scope, tree, has_col_parent)
    -- col -- represents a vertical association of window, e.g. { { "leaf", int }, { "col", { ... } }, { "row", { ...} } }
    -- row -- represents an horizontal association of window, e.g  { { "leaf", int }, { "col", { ... } }, { "row", { ...} } }
    -- leaf -- represents a window, e.g. { "leaf", int }

    if tree == nil then
        return
    end

    -- log.debug(scope, "new layer entered%s: %s", has_col_parent and " from col" or "", vim.inspect(tree))
    for idx, leaf in ipairs(tree) do
        if leaf == "row" then
            local leafs = tree[idx + 1]
            -- if on a row we were on a col, then it means one iteam of the row must be of the same width as a col one
            if has_col_parent and vim.tbl_count(leafs) > 1 then
                local leafs_copy = vim.list_extend({}, leafs)
                table.remove(leafs_copy, 1)
                self:set_layout_windows(scope, leafs_copy)
            else
                self:set_layout_windows(scope, leafs)
            end
            self:walk_layout(scope, tree[idx + 1], false)
        elseif leaf == "col" then
            self:walk_layout(scope, tree[idx + 1], true)
        elseif type(leaf) == "table" and type(leaf[1]) == "string" then
            self:walk_layout(scope, leaf, has_col_parent)
        end
    end
end

--- Scans the winlayout in order to identify window position and type.
---
---@param scope string: the caller of the method.
---@return boolean: whether the number of columns changed or not.
---@private
function state:scan_layout(scope)
    local initial_columns = self:get_columns()

    self:init_columns()
    self:init_integrations()

    local layout = vim.fn.winlayout()
    local layout_type = layout[1]

    if layout_type == "leaf" then
        -- Single window layout (e.g., vim startup with nnp autocmds)
        self:set_layout_windows(scope, { layout })
    elseif layout_type == "col" and vim.tbl_count(layout) == 2 then
        -- Column layout with potential leaf-only structure
        local is_leaf_only = true
        for _, sub in ipairs(layout[2]) do
            if sub[1] ~= "leaf" then
                is_leaf_only = false
                break
            end
        end

        if is_leaf_only then
            -- A col of leaves = one visual column (windows stacked vertically)
            self.tabs[self.active_tab].wins.columns = self.tabs[self.active_tab].wins.columns + 1
            self:_scan_col_children(scope, layout[2])
        else
            self:walk_layout(scope, layout[2], false)
        end
    else
        -- Complex layout structure
        self:walk_layout(scope, layout, false)
    end

    self:save()

    local final_columns = self:get_columns()
    log.debug(scope, "computed columns: %d - %d", initial_columns, final_columns)

    return initial_columns ~= final_columns
end

----- namespace =======================================================
---@private

--- Creates a namespace for the given `win` and stores it in the state.
---
---@param side number: the side window id.
---@return number: the created namespace id.
---@private
function state:set_namespace(side)
    if self.namespaces == nil then
        self.namespaces = {}
    end

    local name = string.format("NoNeckPain_tab_%s_side_%s", self.active_tab, side)
    local id = vim.api.nvim_create_namespace(name)

    self.namespaces[side] = id

    return id
end

--- Clears the given `side` namespace and resets its state value.
---
---@param bufnr number: the buffer number.
---@param side "left"|"right": the side.
---@private
function state:remove_namespace(bufnr, side)
    if self.namespaces == nil or self.namespaces[side] == nil then
        return
    end

    if not vim.api.nvim_buf_is_valid(bufnr) then
        return
    end

    vim.api.nvim_buf_clear_namespace(bufnr, self.namespaces[side], 0, -1)
end

----- scratchpad =======================================================
---@private

--- Sets the given `bool` value to the active tab scratch_pad.
---
---@param bool boolean: the value of the scratch_pad.
---@private
function state:set_scratch_pad(bool)
    if not (self:has_tabs() and self.tabs[self.active_tab] ~= nil) then
        return
    end
    self.tabs[self.active_tab].scratchpad_enabled = bool
end

--- Gets the scratch_pad value for the active tab.
---
---@return boolean: the value of the scratch_pad.
---@private
function state:get_scratch_pad()
    if not (self:has_tabs() and self.tabs[self.active_tab] ~= nil) then
        return false
    end
    return self.tabs[self.active_tab].scratchpad_enabled
end

----- layout decision helpers =======================================================
---@private

--- Scans leaf children of a col node, registering any integrations found and
--- incrementing none_columns if a position="none" integration is present.
---
---@param scope string: the caller of the method.
---@param children table: array of layout nodes that are children of a col node.
---@private
function state:_scan_col_children(scope, children)
    if not (self:has_tabs() and self.tabs[self.active_tab]) then
        return
    end
    local has_none = false
    for _, sub in ipairs(children) do
        if sub[1] == "leaf" and not api.is_relative_window(sub[2]) then
            local id = sub[2]
            if id ~= self:get_side_id("curr") then
                local supported, name, integration = self:is_supported_integration(scope, id)
                if supported and name and integration then
                    integration.id = id
                    self.tabs[self.active_tab].redraw = true
                    self.tabs[self.active_tab].wins.integrations[name] = integration
                    if integration.position == "none" then
                        has_none = true
                    end
                end
            end
        end
    end
    if has_none then
        self.tabs[self.active_tab].wins.none_columns = self.tabs[self.active_tab].wins.none_columns
            + 1
    end
end

--- Validates the stored side window IDs against the set of currently valid windows.
--- Clears any side ID that no longer refers to a valid window and optionally reassigns
--- the `curr` window to the best available replacement.
---
---@param scope string: the caller of the method.
---@param valid_win_set table: map of window ID → true for all currently valid windows.
---@return boolean: whether the left side was cleared.
---@return boolean: whether the right side was cleared.
---@private
function state:validate_sides(scope, valid_win_set)
    local curr_id = self:get_side_id("curr")
    if curr_id and not valid_win_set[curr_id] then
        log.debug(scope, "clearing invalid main window %d", curr_id)
        local unregistered = self:get_unregistered_wins(scope)
        local candidate
        for _, win in ipairs(unregistered) do
            if vim.api.nvim_win_is_valid(win) then
                local ft = vim.bo[vim.api.nvim_win_get_buf(win)].filetype
                if not helpers.is_filetype_integration(ft) then
                    candidate = win
                    break
                end
            end
        end
        if candidate then
            self:set_side_id(candidate, "curr")
            log.debug(scope, "reassigned main window to %d", candidate)
        elseif
            self:get_previously_focused_win()
            and vim.api.nvim_win_is_valid(self:get_previously_focused_win())
        then
            self:set_side_id(self:get_previously_focused_win(), "curr")
            log.debug(
                scope,
                "reassigned main window to previously focused %d",
                self:get_previously_focused_win()
            )
        end
    end

    local left_id = self:get_side_id("left")
    local left_cleared = false
    if left_id and not valid_win_set[left_id] then
        log.debug(scope, "left side window %d is no longer valid", left_id)
        left_cleared = true
        self:set_side_id(nil, "left")
    end

    local right_id = self:get_side_id("right")
    local right_cleared = false
    if right_id and not valid_win_set[right_id] then
        log.debug(scope, "right side window %d is no longer valid", right_id)
        right_cleared = true
        self:set_side_id(nil, "right")
    end

    return left_cleared, right_cleared
end

--- Determines what layout action to take after a window event.
---
---@param event_name string: the triggering autocmd event name ("WinClosed" or "WinEnter").
---@param init boolean: whether scan_layout detected a column count change.
---@param pre_count number: window count before the event.
---@param post_count number: window count after the event.
---@param left_cleared boolean: whether the left side ID was just cleared.
---@param right_cleared boolean: whether the right side ID was just cleared.
---@param left_id_before number?: the left side ID before validation.
---@param right_id_before number?: the right side ID before validation.
---@return "disable"|"init"|nil
---@private
function state:determine_layout_action(
    event_name,
    init,
    pre_count,
    post_count,
    left_cleared,
    right_cleared,
    left_id_before,
    right_id_before
)
    local side_window_was_cleared = left_cleared or right_cleared

    if side_window_was_cleared and event_name == "WinClosed" then
        if left_id_before == nil and right_id_before == nil then
            log.debug(
                "determine_layout_action",
                "side was cleared but both IDs were already nil, allowing init"
            )
            -- fall through to check remaining conditions
        else
            return "disable"
        end
    elseif init then
        return "init"
    elseif
        event_name == "WinClosed"
        and not init
        and pre_count ~= post_count
        and not side_window_was_cleared
    then
        return "init"
    elseif event_name == "WinEnter" and not init and pre_count ~= post_count then
        return "init"
    end

    return nil
end

----- focused win tracker =======================================================
---@private

--- Sets the given `id` as the previously focused window.
---
---@param id number
---@private
function state:set_previously_focused_win(id)
    self.previously_focused_win = id
end

--- Gets the previously focused win id.
---
---@return number
---@private
function state:get_previously_focused_win()
    return self.previously_focused_win
end

return state
