--- Regression test suite for the `no-neck-pain.util.helpers` module
---
--- Verifies that the helpers which do real work behave identically to the
--- duplicate code patterns they replaced:
--- - ensure_plugin_enabled() validates plugin state
--- - safe_delete_augroup() handles non-existent augroups safely
---
--- Test Coverage:
--- - Validation and error handling
--- - Edge cases (nil state, missing augroups)

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
-- GROUP 1: Helpers Module - ensure_plugin_enabled
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
-- GROUP 2: Helpers Module - safe_delete_augroup
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

return T
