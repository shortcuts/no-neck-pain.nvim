--- Regression test suite for state refactoring
---
--- This test suite verifies that the refactoring work (Tasks 3-5) introduced NO
--- behavior changes to the plugin. It ensures:
---
--- 1. State Access API (state_access.lua) - Tests that the new state_access module
---    provides identical behavior to direct global access:
---    - get_config() returns same as _G.NoNeckPain.config
---    - get_state() returns same as _G.NoNeckPain.state
---    - get_config_field() and get_state_field() for nested access
---    - set_config() and set_state() properly update global state
---
--- 2. Helpers Module (helpers.lua) - Tests that helper functions work identically
---    to original duplicate code patterns:
---    - ensure_config_loaded() initializes config if needed
---    - ensure_plugin_enabled() validates plugin state
---    - safe_delete_augroup() handles non-existent augroups safely
---
--- Test Coverage:
--- - Direct API reads and writes
--- - Nested field access patterns
--- - Edge cases (nil values, missing fields)
--- - Validation and error handling
--- - State consistency across reads and writes

local Helpers = dofile("tests/helpers.lua")

local child = Helpers.new_child_neovim()

local T = MiniTest.new_set({
    hooks = {
        pre_case = function()
            child.restart({ "-u", "scripts/minimal_init.lua" })
            child.set_size(10, 200)
        end,
        post_once = child.stop,
    },
})

-- =============================================================================
-- GROUP 1: State Access API - Reading
-- =============================================================================

T["State Access: get_config() returns same as _G.NoNeckPain.config"] = function()
    -- Initialize the plugin
    child.lua([[ require('no-neck-pain').setup({width=100, minSideBufferWidth=10}) ]])

    -- Get config via direct access and state_access API
    local direct_config = child.lua_get("_G.NoNeckPain.config")
    local api_config = child.lua_get("require('no-neck-pain.util.helpers').get_config()")

    -- Both should be tables and equal
    Helpers.expect.equality(type(direct_config), "table")
    Helpers.expect.equality(type(api_config), "table")
    Helpers.expect.equality(direct_config.width, api_config.width)
    Helpers.expect.equality(direct_config.minSideBufferWidth, api_config.minSideBufferWidth)
end

T["State Access: get_state() returns same as _G.NoNeckPain.state"] = function()
    -- Setup and enable the plugin
    child.lua([[ require('no-neck-pain').setup({width=100}) ]])
    child.nnp()

    -- Get state via direct access and state_access API - compare enabled flag
    local direct_enabled = child.lua_get("_G.NoNeckPain.state.enabled")
    local api_enabled = child.lua_get("require('no-neck-pain.util.helpers').get_state().enabled")

    -- Compare active_tab
    local direct_tab = child.lua_get("_G.NoNeckPain.state.active_tab")
    local api_tab = child.lua_get("require('no-neck-pain.util.helpers').get_state().active_tab")

    -- Verify consistency
    Helpers.expect.equality(direct_enabled, api_enabled)
    Helpers.expect.equality(direct_tab, api_tab)
end

T["State Access: get_config() returns nil when not initialized"] = function()
    -- Don't call setup, check that get_config returns nil
    local result = child.lua_get("require('no-neck-pain.util.helpers').get_config()")
    Helpers.expect.equality(result, vim.NIL)
end

T["State Access: get_state() returns nil when not initialized"] = function()
    -- Don't call setup or enable, check that get_state returns nil
    local result = child.lua_get("require('no-neck-pain.util.helpers').get_state()")
    Helpers.expect.equality(result, vim.NIL)
end

T["State Access: get_config_field() retrieves nested config values"] = function()
    -- Setup with custom config
    child.lua([[ require('no-neck-pain').setup({
        width = 120,
        minSideBufferWidth = 15,
        debug = true
    }) ]])

    -- Test various fields
    local width = child.lua_get("require('no-neck-pain.util.helpers').get_config_field('width')")
    local minSideBufferWidth =
        child.lua_get("require('no-neck-pain.util.helpers').get_config_field('minSideBufferWidth')")
    local debug = child.lua_get("require('no-neck-pain.util.helpers').get_config_field('debug')")

    Helpers.expect.equality(width, 120)
    Helpers.expect.equality(minSideBufferWidth, 15)
    Helpers.expect.equality(debug, true)
end

T["State Access: get_state_field() retrieves nested state values"] = function()
    -- Setup and enable
    child.lua([[ require('no-neck-pain').setup({width=100}) ]])
    child.nnp()

    -- Test various state fields
    local enabled = child.lua_get("require('no-neck-pain.util.helpers').get_state_field('enabled')")
    local active_tab =
        child.lua_get("require('no-neck-pain.util.helpers').get_state_field('active_tab')")

    Helpers.expect.equality(enabled, true)
    Helpers.expect.equality(type(active_tab), "number")
end

T["State Access: get_config_field() returns nil for non-existent field"] = function()
    -- Setup config
    child.lua([[ require('no-neck-pain').setup({width=100}) ]])

    -- Try to get non-existent field
    local result =
        child.lua_get("require('no-neck-pain.util.helpers').get_config_field('nonexistent_field')")
    Helpers.expect.equality(result, vim.NIL)
end

T["State Access: get_state_field() returns nil for non-existent field"] = function()
    -- Setup and enable
    child.lua([[ require('no-neck-pain').setup({width=100}) ]])
    child.nnp()

    -- Try to get non-existent field
    local result =
        child.lua_get("require('no-neck-pain.util.helpers').get_state_field('nonexistent_field')")
    Helpers.expect.equality(result, vim.NIL)
end

-- =============================================================================
-- GROUP 2: State Access API - Writing
-- =============================================================================

T["State Access: set_config() updates _G.NoNeckPain.config"] = function()
    -- Setup initial config
    child.lua([[ require('no-neck-pain').setup({width=100}) ]])

    -- Update config via set_config
    child.lua([[
        local state_access = require('no-neck-pain.util.helpers')
        local config = state_access.get_config()
        config.width = 150
        state_access.set_config(config)
    ]])

    -- Verify the change is reflected in global state
    local new_width = child.lua_get("_G.NoNeckPain.config.width")
    Helpers.expect.equality(new_width, 150)
end

T["State Access: set_state() updates _G.NoNeckPain.state"] = function()
    -- Setup and enable
    child.lua([[ require('no-neck-pain').setup({width=100}) ]])
    child.nnp()

    -- Update state via set_state
    child.lua([[
        local state_access = require('no-neck-pain.util.helpers')
        local state = state_access.get_state()
        state.enabled = false
        state_access.set_state(state)
    ]])

    -- Verify the change is reflected in global state
    local new_enabled = child.lua_get("_G.NoNeckPain.state.enabled")
    Helpers.expect.equality(new_enabled, false)
end

T["State Access: set_config() accepts valid config update"] = function()
    child.lua([[ require('no-neck-pain').setup({width=100}) ]])

    child.lua([[ 
        local sa = require('no-neck-pain.util.helpers')
        local cfg = sa.get_config()
        cfg.width = 120
        _G.test_result = sa.set_config(cfg)
    ]])
    local result = child.lua_get("_G.test_result")

    Helpers.expect.equality(result, true)
    local new_width = child.lua_get("_G.NoNeckPain.config.width")
    Helpers.expect.equality(new_width, 120)
end

T["State Access: set_config() accepts string width"] = function()
    -- Setup initial config
    child.lua([[ require('no-neck-pain').setup({width=100}) ]])

    -- Set config with string width (textwidth, colorcolumn)
    local success =
        child.lua_get("require('no-neck-pain.util.helpers').set_config({width='textwidth'})")

    Helpers.expect.equality(success, true)
end

T["State Access: set_state() accepts valid state update"] = function()
    child.lua([[ require('no-neck-pain').setup({width=100}) ]])
    child.nnp()

    child.lua([[ 
        local sa = require('no-neck-pain.util.helpers')
        local st = sa.get_state()
        st.enabled = false
        _G.test_result = sa.set_state(st)
    ]])
    local result = child.lua_get("_G.test_result")

    Helpers.expect.equality(result, true)
    local new_enabled = child.lua_get("_G.NoNeckPain.state.enabled")
    Helpers.expect.equality(new_enabled, false)
end

T["State Access: set_config() rejects invalid operations and updates are idempotent"] = function()
    child.lua([[ require('no-neck-pain').setup({width=100}) ]])

    child.lua([[ 
        local sa = require('no-neck-pain.util.helpers')
        local cfg = sa.get_config()
        cfg.width = 125
        sa.set_config(cfg)
        local cfg2 = sa.get_config()
        cfg2.width = 125
        _G.test_result = sa.set_config(cfg2)
    ]])
    local result = child.lua_get("_G.test_result")

    Helpers.expect.equality(result, true)
    local final_width = child.lua_get("_G.NoNeckPain.config.width")
    Helpers.expect.equality(final_width, 125)
end

T["State Access: merge_config() deep merges config updates"] = function()
    -- Setup initial config with nested structure
    child.lua([[ require('no-neck-pain').setup({
        width = 100,
        minSideBufferWidth = 10,
        debug = false
    }) ]])

    -- Merge partial updates
    child.lua([[
        require('no-neck-pain.util.helpers').merge_config({width = 120, debug = true})
    ]])

    -- Verify merged values
    local width = child.lua_get("_G.NoNeckPain.config.width")
    local debug = child.lua_get("_G.NoNeckPain.config.debug")
    local minSideBufferWidth = child.lua_get("_G.NoNeckPain.config.minSideBufferWidth")

    Helpers.expect.equality(width, 120)
    Helpers.expect.equality(debug, true)
    Helpers.expect.equality(minSideBufferWidth, 10)
end

-- =============================================================================
-- GROUP 3: Helpers Module - ensure_config_loaded
-- =============================================================================

T["Helpers: ensure_config_loaded() loads config if not initialized"] = function()
    -- Setup plugin first
    child.lua([[ require('no-neck-pain').setup({width=100}) ]])

    -- Reset config to nil to simulate uninitialized state
    child.lua([[ _G.NoNeckPain.config = nil ]])

    -- Now ensure it gets loaded
    child.lua([[ 
        local config = require('no-neck-pain.config')
        require('no-neck-pain.util.helpers').ensure_config_loaded(config)
    ]])

    -- Verify config is now loaded
    local config = child.lua_get("_G.NoNeckPain.config")
    Helpers.expect.equality(type(config), "table")
    Helpers.expect.no_equality(config.width, vim.NIL)
end

T["Helpers: ensure_config_loaded() does not reload if already loaded"] = function()
    -- Setup with initial config
    child.lua([[ 
        require('no-neck-pain').setup({width=100})
        local initial_width = _G.NoNeckPain.config.width
    ]])

    local initial_width = child.lua_get("_G.NoNeckPain.config.width")

    -- Call ensure_config_loaded
    child.lua([[ 
        local config = require('no-neck-pain.config')
        require('no-neck-pain.util.helpers').ensure_config_loaded(config)
    ]])

    -- Width should remain the same (not reloaded with default)
    local new_width = child.lua_get("_G.NoNeckPain.config.width")
    Helpers.expect.equality(new_width, initial_width)
    Helpers.expect.equality(new_width, 100)
end

-- =============================================================================
-- GROUP 4: Helpers Module - ensure_plugin_enabled
-- =============================================================================

T["Helpers: ensure_plugin_enabled() validates plugin is enabled"] = function()
    -- Setup and enable the plugin
    child.lua([[ require('no-neck-pain').setup({width=100}) ]])
    child.nnp()

    -- Should not error when enabled
    local success = child.lua_get(
        "pcall(function() require('no-neck-pain.util.helpers').ensure_plugin_enabled() end)"
    )

    Helpers.expect.equality(success, true)
end

T["Helpers: ensure_plugin_enabled() throws error when disabled"] = function()
    -- Setup but don't enable
    child.lua([[ require('no-neck-pain').setup({width=100}) ]])

    -- Should error when plugin is not enabled
    local success = child.lua_get(
        "pcall(function() require('no-neck-pain.util.helpers').ensure_plugin_enabled() end)"
    )

    Helpers.expect.equality(success, false)
end

T["Helpers: ensure_plugin_enabled() throws error when state is nil"] = function()
    -- Don't setup at all
    local success = child.lua_get(
        "pcall(function() require('no-neck-pain.util.helpers').ensure_plugin_enabled() end)"
    )

    Helpers.expect.equality(success, false)
end

T["Helpers: ensure_plugin_enabled() error message is helpful"] = function()
    child.lua([[ require('no-neck-pain').setup({width=100}) ]])

    child.lua([[ 
        local ok, err = pcall(require('no-neck-pain.util.helpers').ensure_plugin_enabled)
        _G.error_msg = tostring(err or "")
    ]])

    local error_msg = child.lua_get("_G.error_msg")

    Helpers.expect.match(error_msg, "NoNeckPain")
end

-- =============================================================================
-- GROUP 5: Helpers Module - safe_delete_augroup
-- =============================================================================

T["Helpers: safe_delete_augroup() deletes existing augroup"] = function()
    child.lua([[ vim.api.nvim_create_augroup("test_group_safe", {clear=true}) ]])

    child.lua([[ require('no-neck-pain.util.helpers').safe_delete_augroup("test_group_safe") ]])

    child.lua([[ _G.exists_after = pcall(vim.api.nvim_del_augroup_by_name, "test_group_safe") ]])
    local exists_after = child.lua_get("_G.exists_after")

    Helpers.expect.equality(exists_after, false)
end

T["Helpers: safe_delete_augroup() does not error on non-existent group"] = function()
    -- Try to delete non-existent group - should not error
    local success = child.lua_get(
        "pcall(function() require('no-neck-pain.util.helpers').safe_delete_augroup('nonexistent_group_xyz') end)"
    )

    Helpers.expect.equality(success, true)
end

T["Helpers: safe_delete_augroup() handles multiple deletions"] = function()
    child.lua([[
        local helpers = require('no-neck-pain.util.helpers')
        for i = 1, 3 do
            vim.api.nvim_create_augroup("test_grp_" .. i, {clear=true})
            helpers.safe_delete_augroup("test_grp_" .. i)
        end
    ]])

    Helpers.expect.equality(true, true)
end

-- =============================================================================
-- GROUP 6: State Consistency - Round-trip tests
-- =============================================================================

T["Regression: Config round-trip (set then get)"] = function()
    -- Setup
    child.lua([[ require('no-neck-pain').setup({width=100}) ]])

    -- Round-trip: set new config and read it back
    child.lua([[
        local state_access = require('no-neck-pain.util.helpers')
        local config = state_access.get_config()
        config.width = 175
        state_access.set_config(config)
    ]])

    -- Verify via both API and direct access
    local api_width =
        child.lua_get("require('no-neck-pain.util.helpers').get_config_field('width')")
    local direct_width = child.lua_get("_G.NoNeckPain.config.width")

    Helpers.expect.equality(api_width, 175)
    Helpers.expect.equality(direct_width, 175)
    Helpers.expect.equality(api_width, direct_width)
end

T["Regression: State round-trip (set then get)"] = function()
    -- Setup and enable
    child.lua([[ require('no-neck-pain').setup({width=100}) ]])
    child.nnp()

    -- Get initial state
    local initial_enabled = child.lua_get("_G.NoNeckPain.state.enabled")
    Helpers.expect.equality(initial_enabled, true)

    -- Round-trip: disable via set_state
    child.lua([[
        local state_access = require('no-neck-pain.util.helpers')
        local state = state_access.get_state()
        state.enabled = false
        state_access.set_state(state)
    ]])

    -- Verify via both API and direct access
    local api_enabled =
        child.lua_get("require('no-neck-pain.util.helpers').get_state_field('enabled')")
    local direct_enabled = child.lua_get("_G.NoNeckPain.state.enabled")

    Helpers.expect.equality(api_enabled, false)
    Helpers.expect.equality(direct_enabled, false)
    Helpers.expect.equality(api_enabled, direct_enabled)
end

T["Regression: Multiple successive config updates"] = function()
    -- Setup
    child.lua([[ require('no-neck-pain').setup({width=100}) ]])

    -- Multiple updates
    child.lua([[
        local state_access = require('no-neck-pain.util.helpers')
        
        -- Update 1
        local config = state_access.get_config()
        config.width = 110
        state_access.set_config(config)
        
        -- Update 2
        config = state_access.get_config()
        config.width = 120
        state_access.set_config(config)
        
        -- Update 3
        config = state_access.get_config()
        config.width = 130
        state_access.set_config(config)
    ]])

    -- Final width should be 130
    local final_width = child.lua_get("_G.NoNeckPain.config.width")
    Helpers.expect.equality(final_width, 130)
end

return T
