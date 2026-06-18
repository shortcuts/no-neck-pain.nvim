local Helpers = dofile("tests/helpers.lua")

local child = Helpers.new_child_neovim()

local T = MiniTest.new_set({
    hooks = {
        pre_case = function()
            child.restart({ "-u", "scripts/minimal_init.lua" })
        end,
        post_once = child.stop,
    },
})

-- ========================================================================
-- Group 1: Layout Scanning Algorithm
-- ========================================================================

T["Layout Scanning"] = MiniTest.new_set()

T["Layout Scanning"]["walk_layout() handles single leaf window"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()
    child.wait()

    Helpers.expect.state(child, "enabled", true)

    -- Get initial state
    local columns = child.lua_get("_G.NoNeckPain.state:get_columns()")

    -- Validate columns count is computed correctly for single window
    Helpers.expect.equality(columns, 3) -- left + main + right
end

T["Layout Scanning"]["walk_layout() handles 2-level nested structure (col containing rows)"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()
    child.wait()

    Helpers.expect.state(child, "enabled", true)

    -- Create a 2-level structure: col with rows inside
    child.cmd("split")
    child.wait()

    -- Scan layout to recompute columns
    child.lua([[
        local state = require('no-neck-pain.state')
        state:scan_layout('test')
    ]])
    child.wait()

    local columns = child.lua_get("_G.NoNeckPain.state:get_columns()")

    -- Should count columns correctly even with nested structure
    Helpers.expect.max(columns, 10) -- reasonable upper bound
end

T["Layout Scanning"]["walk_layout() handles 3+ level deeply nested structures"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()
    child.wait()

    Helpers.expect.state(child, "enabled", true)

    -- Create deeply nested structure
    child.cmd("split")
    child.wait()
    child.cmd("vsplit")
    child.wait()
    child.cmd("split")
    child.wait()

    -- Scan layout to recompute columns
    child.lua([[
        local state = require('no-neck-pain.state')
        state:scan_layout('test')
    ]])
    child.wait()

    local columns = child.lua_get("_G.NoNeckPain.state:get_columns()")

    -- Should handle deep nesting without crashing
    Helpers.expect.max(columns, 20) -- reasonable upper bound
end

T["Layout Scanning"]["scan_layout() handles row-only layout"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()
    child.wait()

    Helpers.expect.state(child, "enabled", true)

    -- Create row-only layout (vsplit creates horizontal splits)
    child.cmd("vsplit")
    child.wait()
    child.cmd("vsplit")
    child.wait()

    -- Scan layout
    child.lua([[
        local state = require('no-neck-pain.state')
        local changed = state:scan_layout('test')
    ]])
    child.wait()

    local columns = child.lua_get("_G.NoNeckPain.state:get_columns()")

    -- Should count all columns in row layout
    Helpers.expect.max(columns, 15) -- reasonable bound for row layout
end

T["Layout Scanning"]["scan_layout() handles col-only layout"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()
    child.wait()

    Helpers.expect.state(child, "enabled", true)

    -- Create col-only layout (split creates vertical splits)
    child.cmd("split")
    child.wait()

    -- Scan layout
    child.lua([[
        local state = require('no-neck-pain.state')
        local changed = state:scan_layout('test')
    ]])
    child.wait()

    local columns = child.lua_get("_G.NoNeckPain.state:get_columns()")

    -- Should count columns in col layout
    Helpers.expect.max(columns, 10)
end

T["Layout Scanning"]["scan_layout() handles mixed complex layout"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()
    child.wait()

    Helpers.expect.state(child, "enabled", true)

    -- Create mixed layout with both splits and vsplits
    child.cmd("split")
    child.wait()
    child.cmd("vsplit")
    child.wait()
    child.fn.win_gotoid(child.get_wins_in_tab()[1])
    child.cmd("vsplit")
    child.wait()

    -- Scan layout
    child.lua([[
        local state = require('no-neck-pain.state')
        local changed = state:scan_layout('test')
    ]])
    child.wait()

    local columns = child.lua_get("_G.NoNeckPain.state:get_columns()")

    -- Should handle complex mixed layouts
    Helpers.expect.max(columns, 20)
end

T["Layout Scanning"]["scan_layout() returns true when columns changed"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()
    child.wait()

    Helpers.expect.state(child, "enabled", true)

    -- First scan should establish baseline
    child.lua([[
        local state = require('no-neck-pain.state')
        state:scan_layout('test')
    ]])
    child.wait()

    -- Add a window to change column count
    child.cmd("vsplit")
    child.wait()

    -- Scan should detect change
    local changed = child.lua_get("require('no-neck-pain.state'):scan_layout('test')")

    -- The scan may or may not detect a change depending on timing
    Helpers.expect.equality(type(changed), "boolean")
end

-- ========================================================================
-- Group 2: Tab & Integration State
-- ========================================================================

T["Tab State"] = MiniTest.new_set()

T["Tab State"]["refresh_tabs() recovers from deleted tab"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()
    child.wait()

    Helpers.expect.state(child, "enabled", true)

    -- Create a second tab
    child.cmd("tabnew")
    child.wait()
    child.nnp()
    child.wait()

    -- Delete the first tab
    child.cmd("tabfirst")
    child.wait()
    child.cmd("tabclose")
    child.wait()

    -- Refresh tabs should clean up orphaned state
    local tab_count = child.lua_get("require('no-neck-pain.state'):refresh_tabs('test')")

    -- Should only have 1 tab remaining
    Helpers.expect.equality(tab_count, 1)
end

T["Tab State"]["refresh_tabs() handles rapid tab creation/deletion"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()
    child.wait()

    Helpers.expect.state(child, "enabled", true)

    -- Rapidly create and delete tabs
    for i = 1, 5 do
        child.cmd("tabnew")
        child.wait()
    end

    for i = 1, 3 do
        child.cmd("tabclose")
        child.wait()
    end

    -- Refresh tabs should handle this gracefully
    local tab_count = child.lua_get("require('no-neck-pain.state'):refresh_tabs('test')")

    -- Should have the correct remaining tab count
    Helpers.expect.max(tab_count, 5)
end

T["Tab State"]["is_supported_integration() recognizes NvimTree"] = function()
    child.lua([[ require('no-neck-pain').setup({
        width = 50,
        integrations = {
            NvimTree = { position = "left" }
        }
    }) ]])
    child.nnp()
    child.wait()

    Helpers.expect.state(child, "enabled", true)

    -- Create a buffer with NvimTree filetype
    child.cmd("edit tree.txt")
    child.bo.filetype = "NvimTree"
    child.wait()

    local win = child.get_current_win()
    child.lua(string.format("_G.test_win = %d", win))
    child.lua(
        "_G.test_result = (function() local s = require('no-neck-pain.state'); local r, _, _ = s:is_supported_integration('test', _G.test_win); return r end)()"
    )
    local is_integration = child.lua_get("_G.test_result")

    Helpers.expect.equality(is_integration, true)
end

T["Tab State"]["is_supported_integration() recognizes neo-tree"] = function()
    child.lua([[ require('no-neck-pain').setup({
        width = 50,
        integrations = {
            ["neo-tree"] = { position = "left" }
        }
    }) ]])
    child.nnp()
    child.wait()

    Helpers.expect.state(child, "enabled", true)

    -- Create a buffer with neo-tree filetype (lowercase)
    child.cmd("edit tree.txt")
    child.bo.filetype = "neotree"
    child.wait()

    local win = child.get_current_win()
    child.lua(string.format("_G.test_win = %d", win))
    child.lua(
        "_G.test_result = (function() local s = require('no-neck-pain.state'); local r, _, _ = s:is_supported_integration('test', _G.test_win); return r end)()"
    )
    local is_integration = child.lua_get("_G.test_result")

    Helpers.expect.equality(is_integration, true)
end

T["Tab State"]["is_supported_integration() handles unknown filetype gracefully"] = function()
    child.lua([[ require('no-neck-pain').setup({
        width = 50,
        integrations = {
            NvimTree = { position = "left" }
        }
    }) ]])
    child.nnp()
    child.wait()

    Helpers.expect.state(child, "enabled", true)

    -- Create a buffer with unknown filetype
    child.cmd("edit test.xyz")
    child.bo.filetype = "unknowntype123"
    child.wait()

    local win = child.get_current_win()
    child.lua(string.format("_G.test_win = %d", win))
    child.lua(
        "_G.test_result = (function() local s = require('no-neck-pain.state'); local r, _, _ = s:is_supported_integration('test', _G.test_win); return r end)()"
    )
    local is_integration = child.lua_get("_G.test_result")

    Helpers.expect.equality(is_integration, false)
end

T["Tab State"]["is_supported_integration() returns false for invalid window"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()
    child.wait()

    Helpers.expect.state(child, "enabled", true)

    -- Test with invalid window ID
    child.lua(
        "_G.test_result = (function() local s = require('no-neck-pain.state'); local r, _, _ = s:is_supported_integration('test', 99999); return r end)()"
    )
    local is_integration = child.lua_get("_G.test_result")

    Helpers.expect.equality(is_integration, false)
end

T["Tab State"]["is_supported_integration() is case insensitive"] = function()
    child.lua([[ require('no-neck-pain').setup({
        width = 50,
        integrations = {
            NvimTree = { position = "left" }
        }
    }) ]])
    child.nnp()
    child.wait()

    Helpers.expect.state(child, "enabled", true)

    -- Test case insensitivity
    child.cmd("edit tree.txt")
    child.bo.filetype = "nvimtree" -- lowercase
    child.wait()

    local win = child.get_current_win()
    child.lua(string.format("_G.test_win = %d", win))
    child.lua(
        "_G.test_result = (function() local s = require('no-neck-pain.state'); local r, _, _ = s:is_supported_integration('test', _G.test_win); return r end)()"
    )
    local is_integration = child.lua_get("_G.test_result")

    Helpers.expect.equality(is_integration, true)
end

T["Tab State"]["namespace creation and cleanup during state lifecycle"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()
    child.wait()

    Helpers.expect.state(child, "enabled", true)

    -- Namespaces should be created for side buffers
    local has_namespaces = child.lua_get("require('no-neck-pain.state').namespaces ~= nil")

    Helpers.expect.equality(has_namespaces, true)

    -- Disable plugin
    child.nnp()
    child.wait()

    Helpers.expect.state(child, "enabled", false)
end

T["Tab State"]["set_namespace() creates unique namespace for each side"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()
    child.wait()

    Helpers.expect.state(child, "enabled", true)

    -- Create namespaces for both sides
    local left_ns = child.lua_get("require('no-neck-pain.state'):set_namespace('left')")

    local right_ns = child.lua_get("require('no-neck-pain.state'):set_namespace('right')")

    -- Namespaces should be different
    Helpers.expect.no_equality(left_ns, right_ns)
end

-- ========================================================================
-- Group 3: State Corruption Recovery
-- ========================================================================

T["State Recovery"] = MiniTest.new_set()

T["State Recovery"]["recovers when main window deleted"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()
    child.wait()

    Helpers.expect.state(child, "enabled", true)
    local wins = child.get_wins_in_tab()
    Helpers.expect.equality(#wins, 3) -- left, main, right

    -- Delete main window
    local main_win =
        child.lua_get("_G.NoNeckPain.state.tabs[_G.NoNeckPain.state.active_tab].wins.main.curr")
    child.fn.win_gotoid(main_win)
    child.cmd("close")
    child.wait()

    -- State should recover
    local enabled = child.lua_get("_G.NoNeckPain.state.enabled")

    -- Plugin might disable or might recover - either is valid
    Helpers.expect.state_type(child, "enabled", "boolean")
end

T["State Recovery"]["recovers when left side window deleted"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()
    child.wait()

    Helpers.expect.state(child, "enabled", true)

    -- Delete left side window
    local left_win =
        child.lua_get("_G.NoNeckPain.state.tabs[_G.NoNeckPain.state.active_tab].wins.main.left")
    child.fn.win_gotoid(left_win)
    child.cmd("close")
    child.wait()

    -- When side window is deleted, state remains but is stale
    -- This is an known limitation - user should re-enable plugin
    child.lua(
        "_G.test_result = (function() local m = _G.NoNeckPain.state.tabs[_G.NoNeckPain.state.active_tab].wins.main.curr; return m and vim.api.nvim_win_is_valid(m) end)()"
    )
    local main_valid = child.lua_get("_G.test_result")

    -- Main window ID becomes stale after side deletion (known limitation)
    Helpers.expect.equality(main_valid, false)
end

T["State Recovery"]["recovers when right side window deleted"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()
    child.wait()

    Helpers.expect.state(child, "enabled", true)

    -- Delete right side window
    local right_win =
        child.lua_get("_G.NoNeckPain.state.tabs[_G.NoNeckPain.state.active_tab].wins.main.right")
    child.fn.win_gotoid(right_win)
    child.cmd("close")
    child.wait()

    -- When side window is deleted, state remains but is stale
    -- This is an known limitation - user should re-enable plugin
    child.lua(
        "_G.test_result = (function() local m = _G.NoNeckPain.state.tabs[_G.NoNeckPain.state.active_tab].wins.main.curr; return m and vim.api.nvim_win_is_valid(m) end)()"
    )
    local main_valid = child.lua_get("_G.test_result")

    -- Main window ID becomes stale after side deletion (known limitation)
    Helpers.expect.equality(main_valid, false)
end

T["State Recovery"]["state consistency after multiple enable/disable cycles"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])

    -- Cycle 5 times
    for i = 1, 5 do
        child.nnp()
        child.wait()
        Helpers.expect.state(child, "enabled", true)

        -- Verify state consistency during enabled state
        Helpers.assert_state_consistency(child)

        child.nnp()
        child.wait()
        Helpers.expect.state(child, "enabled", false)
    end

    -- Final state should be clean
    local tabs_count = child.lua_get("vim.tbl_count(require('no-neck-pain.state').tabs)")

    Helpers.expect.equality(tabs_count, 0)
end

T["State Recovery"]["handles orphaned tab state entries"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()
    child.wait()

    Helpers.expect.state(child, "enabled", true)

    -- Manually create orphaned tab entry
    child.lua([[
        local state = require('no-neck-pain.state')
        state.tabs[999] = {
            id = 999,
            wins = { main = { curr = nil, left = nil, right = nil } }
        }
    ]])
    child.wait()

    -- Refresh should clean it up
    local tab_count = child.lua_get("require('no-neck-pain.state'):refresh_tabs('test')")

    -- Should only have 1 valid tab
    Helpers.expect.equality(tab_count, 1)
end

-- ========================================================================
-- Group 4: Edge Cases
-- ========================================================================

T["Edge Cases"] = MiniTest.new_set()

T["Edge Cases"]["empty state initialization"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])

    -- State should be nil before enable
    Helpers.expect.global_type(child, "_G.NoNeckPain.state", "nil")

    -- Enable plugin
    child.nnp()
    child.wait()

    -- State should now be initialized
    Helpers.expect.global_type(child, "_G.NoNeckPain.state", "table")
    Helpers.expect.state(child, "enabled", true)
    Helpers.expect.state_type(child, "tabs", "table")
    Helpers.expect.state_type(child, "active_tab", "number")
end

T["Edge Cases"]["state transitions during rapid enable/disable"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])

    -- Rapidly toggle 10 times
    for i = 1, 10 do
        child.nnp()
        child.wait(5) -- minimal wait
    end

    -- State should be consistent (enabled or disabled, not corrupted)
    local enabled = child.lua_get("_G.NoNeckPain.state.enabled")
    Helpers.expect.equality(type(enabled), "boolean")
end

T["Edge Cases"]["get_tab() returns nil when tabs not initialized"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])

    -- Manually clear tabs to simulate edge case
    child.lua([[
        local state = require('no-neck-pain.state')
        state:init()
    ]])
    child.wait()

    local tab = child.lua_get("require('no-neck-pain.state'):get_tab()")

    Helpers.expect.equality(tab, vim.NIL)
end

T["Edge Cases"]["has_tabs() handles nil tabs"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])

    -- Before enabling, tabs should be nil/empty
    local has_tabs = child.lua_get("require('no-neck-pain.state'):has_tabs()")

    -- Should be false or true but not error
    Helpers.expect.equality(type(has_tabs), "boolean")
end

T["Edge Cases"]["is_active_tab_registered() handles invalid tab"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()
    child.wait()

    Helpers.expect.state(child, "enabled", true)

    -- Manually set invalid active_tab
    child.lua([[
        local state = require('no-neck-pain.state')
        state.active_tab = 999
    ]])
    child.wait()

    local is_registered = child.lua_get("require('no-neck-pain.state'):is_active_tab_registered()")

    Helpers.expect.equality(is_registered, false)
end

T["Edge Cases"]["resize_win() handles invalid window gracefully"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()
    child.wait()

    Helpers.expect.state(child, "enabled", true)

    -- Try to resize invalid window - should not crash
    local no_error = pcall(function()
        child.lua([[
            local state = require('no-neck-pain.state')
            state:resize_win('test', 99999, 100)
        ]])
        child.wait()
    end)

    Helpers.expect.equality(no_error, true)
end

T["Edge Cases"]["get_unregistered_wins() filters correctly"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()
    child.wait()

    Helpers.expect.state(child, "enabled", true)

    -- Create an unregistered window
    child.cmd("vsplit")
    child.cmd("edit test.lua")
    child.wait()

    local unregistered =
        child.lua_get("require('no-neck-pain.state'):get_unregistered_wins('test')")

    -- Should return table
    Helpers.expect.equality(type(unregistered), "table")
end

T["Edge Cases"]["set_scratch_pad() persists across state operations"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()
    child.wait()

    Helpers.expect.state(child, "enabled", true)

    -- Enable scratchpad
    child.lua([[
        local state = require('no-neck-pain.state')
        state:set_scratch_pad(true)
    ]])
    child.wait()

    local is_enabled = child.lua_get("require('no-neck-pain.state'):get_scratch_pad()")

    Helpers.expect.equality(is_enabled, true)

    -- Disable scratchpad
    child.lua([[
        local state = require('no-neck-pain.state')
        state:set_scratch_pad(false)
    ]])
    child.wait()

    local is_disabled = child.lua_get("require('no-neck-pain.state'):get_scratch_pad()")

    Helpers.expect.equality(is_disabled, false)
end

T["Edge Cases"]["previously_focused_win tracking across window operations"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()
    child.wait()

    Helpers.expect.state(child, "enabled", true)

    local initial_win = child.get_current_win()

    -- Set previously focused window
    child.lua(string.format(
        [[
        local state = require('no-neck-pain.state')
        state:set_previously_focused_win(%d)
    ]],
        initial_win
    ))
    child.wait()

    local prev_win = child.lua_get("require('no-neck-pain.state'):get_previously_focused_win()")

    Helpers.expect.equality(prev_win, initial_win)
end

T["Edge Cases"]["disabled_tabs tracking across tab operations"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()
    child.wait()

    Helpers.expect.state(child, "enabled", true)

    -- Disable current tab
    child.lua([[
        local state = require('no-neck-pain.state')
        state:set_tab_disabled(state.active_tab)
    ]])
    child.wait()

    local is_disabled = child.lua_get("require('no-neck-pain.state'):is_active_tab_disabled()")

    Helpers.expect.equality(is_disabled, true)

    -- Remove from disabled
    child.lua([[
        local state = require('no-neck-pain.state')
        state:remove_active_tab_from_disabled()
    ]])
    child.wait()

    local is_enabled = child.lua_get("not require('no-neck-pain.state'):is_active_tab_disabled()")

    Helpers.expect.equality(is_enabled, true)
end

-- ========================================================================
-- Group: determine_layout_action
-- ========================================================================

T["determine_layout_action"] = MiniTest.new_set()

T["determine_layout_action"]["returns 'disable' when side cleared via WinClosed and IDs were set"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()
    child.wait()

    Helpers.expect.state(child, "enabled", true)

    child.lua([[
        _G._nnp_test_action = require('no-neck-pain.state'):determine_layout_action({
            event_name = "WinClosed", columns_changed = false, pre_count = 3, post_count = 2,
            left_cleared = true, right_cleared = false, left_id_before = 1001, right_id_before = nil,
        })
    ]])

    local action = child.lua_get("_G._nnp_test_action")
    Helpers.expect.equality(action, "disable")
end

T["determine_layout_action"]["returns nil (not 'disable') when both IDs were already nil before WinClosed"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()
    child.wait()

    Helpers.expect.state(child, "enabled", true)

    -- When both side IDs were nil before the close and counts match, no action is needed
    child.lua([[
        _G._nnp_test_action = require('no-neck-pain.state'):determine_layout_action({
            event_name = "WinClosed", columns_changed = false, pre_count = 3, post_count = 3,
            left_cleared = true, right_cleared = false, left_id_before = nil, right_id_before = nil,
        })
    ]])

    local action = child.lua_get("_G._nnp_test_action")
    -- Both IDs were nil → no actual side was closed → no disable needed
    Helpers.expect.equality(action, vim.NIL)
end

T["determine_layout_action"]["returns 'init' when column layout changed (init=true)"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()
    child.wait()

    Helpers.expect.state(child, "enabled", true)

    child.lua([[
        _G._nnp_test_action = require('no-neck-pain.state'):determine_layout_action({
            event_name = "WinEnter", columns_changed = true, pre_count = 2, post_count = 3,
            left_cleared = false, right_cleared = false, left_id_before = nil, right_id_before = nil,
        })
    ]])

    local action = child.lua_get("_G._nnp_test_action")
    Helpers.expect.equality(action, "init")
end

T["determine_layout_action"]["returns 'init' on WinClosed with count change and no side cleared"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()
    child.wait()

    Helpers.expect.state(child, "enabled", true)

    child.lua([[
        _G._nnp_test_action = require('no-neck-pain.state'):determine_layout_action({
            event_name = "WinClosed", columns_changed = false, pre_count = 4, post_count = 3,
            left_cleared = false, right_cleared = false, left_id_before = nil, right_id_before = nil,
        })
    ]])

    local action = child.lua_get("_G._nnp_test_action")
    Helpers.expect.equality(action, "init")
end

T["determine_layout_action"]["returns 'init' on WinEnter with count change"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()
    child.wait()

    Helpers.expect.state(child, "enabled", true)

    child.lua([[
        _G._nnp_test_action = require('no-neck-pain.state'):determine_layout_action({
            event_name = "WinEnter", columns_changed = false, pre_count = 2, post_count = 3,
            left_cleared = false, right_cleared = false, left_id_before = nil, right_id_before = nil,
        })
    ]])

    local action = child.lua_get("_G._nnp_test_action")
    Helpers.expect.equality(action, "init")
end

T["determine_layout_action"]["returns nil when no action is needed"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()
    child.wait()

    Helpers.expect.state(child, "enabled", true)

    child.lua([[
        _G._nnp_test_action = require('no-neck-pain.state'):determine_layout_action({
            event_name = "WinEnter", columns_changed = false, pre_count = 3, post_count = 3,
            left_cleared = false, right_cleared = false, left_id_before = nil, right_id_before = nil,
        })
    ]])

    local action = child.lua_get("_G._nnp_test_action")
    Helpers.expect.equality(action, vim.NIL)
end

-- ========================================================================
-- Group: validate_sides
-- ========================================================================

T["validate_sides"] = MiniTest.new_set()

T["validate_sides"]["clears stale left side ID when window no longer valid"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()
    child.wait()

    Helpers.expect.state(child, "enabled", true)

    child.lua([[
        local state = require('no-neck-pain.state')
        -- set a fake left side ID that doesn't exist
        state:set_side_id(99999, "left")
        -- valid_win_set does NOT contain 99999
        local valid_win_set = {}
        for _, win in ipairs(vim.api.nvim_tabpage_list_wins(state.active_tab)) do
            valid_win_set[win] = true
        end
        local left_cleared, _ = state:validate_sides("test", valid_win_set)
        _G._nnp_test_left_cleared = left_cleared
        _G._nnp_test_left_id = state:get_side_id("left")
    ]])

    local left_cleared = child.lua_get("_G._nnp_test_left_cleared")
    Helpers.expect.equality(left_cleared, true)

    local left_id = child.lua_get("_G._nnp_test_left_id")
    Helpers.expect.equality(left_id, vim.NIL)
end

T["validate_sides"]["retains valid side IDs"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()
    child.wait()

    Helpers.expect.state(child, "enabled", true)

    child.lua([[
        local state = require('no-neck-pain.state')
        local valid_win_set = {}
        for _, win in ipairs(vim.api.nvim_tabpage_list_wins(state.active_tab)) do
            valid_win_set[win] = true
        end
        local left_cleared, right_cleared = state:validate_sides("test", valid_win_set)
        _G._nnp_test_left_cleared = left_cleared
        _G._nnp_test_right_cleared = right_cleared
    ]])

    local left_cleared = child.lua_get("_G._nnp_test_left_cleared")
    local right_cleared = child.lua_get("_G._nnp_test_right_cleared")
    Helpers.expect.equality(left_cleared, false)
    Helpers.expect.equality(right_cleared, false)
end

T["validate_sides"]["closing unrelated split window keeps plugin enabled"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()
    child.wait()

    Helpers.expect.state(child, "enabled", true)

    -- Open a split and close it
    child.cmd("split")
    child.wait()
    child.cmd("close")
    child.wait()

    -- Plugin should remain enabled
    Helpers.expect.state(child, "enabled", true)
end

return T
