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
-- GROUP 1: skip() Basic Functionality
-- =============================================================================

T["skip(): returns true when plugin is not enabled"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])

    Helpers.expect.global_type(child, "_G.NoNeckPain.state", "nil")

    local result = child.lua_get("require('no-neck-pain.util.event').skip()")

    Helpers.expect.equality(result, true)
end

T["skip(): returns false when plugin is enabled and window is normal"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()
    child.wait()

    Helpers.expect.state(child, "enabled", true)

    child.fn.win_gotoid(1000)
    child.wait()

    local result = child.lua_get("require('no-neck-pain.util.event').skip()")

    Helpers.expect.equality(result, false)
end

T["skip(): returns true when current window is relative (floating)"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()
    child.wait()

    Helpers.expect.state(child, "enabled", true)

    child.api.nvim_open_win(
        0,
        true,
        { width = 50, height = 10, relative = "cursor", row = 0, col = 0 }
    )
    child.wait()

    local result = child.lua_get("require('no-neck-pain.util.event').skip()")

    Helpers.expect.equality(result, true)
end

T["skip(): returns true when current tab is not active tab"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()
    child.wait()

    Helpers.expect.state(child, "enabled", true)
    Helpers.expect.state(child, "active_tab", 1)

    child.cmd("tabnew")
    child.wait()

    local current_tab = child.lua_get("vim.api.nvim_get_current_tabpage()")
    Helpers.expect.equality(current_tab, 2)

    child.lua([[
        local state = require('no-neck-pain.state')
        state.active_tab = 1
    ]])

    local result = child.lua_get("require('no-neck-pain.util.event').skip()")

    Helpers.expect.equality(result, true)
end

T["skip(): handles multiple rapid consecutive calls"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()
    child.wait()

    Helpers.expect.state(child, "enabled", true)

    child.fn.win_gotoid(1000)
    child.wait()

    for _ = 1, 20 do
        local result = child.lua_get("require('no-neck-pain.util.event').skip()")
        Helpers.expect.equality(result, false)
    end

    Helpers.expect.state(child, "enabled", true)
end

-- =============================================================================
-- GROUP 2: skip_enable() Dashboard and Integration Detection
-- =============================================================================

T["skip_enable(): returns true when tab is already registered"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()
    child.wait()

    Helpers.expect.state(child, "enabled", true)

    local result = child.lua_get("require('no-neck-pain.util.event').skip_enable('test_scope')")

    Helpers.expect.equality(result, true)
end

T["skip_enable(): returns true when current window is relative"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])

    child.api.nvim_open_win(
        0,
        true,
        { width = 50, height = 10, relative = "cursor", row = 0, col = 0 }
    )
    child.wait()

    child.lua([[
        _G.NoNeckPain.state = { 
            enabled = false, 
            active_tab = 1, 
            tabs = {}, 
            disabled_tabs = {} 
        }
        local state = require('no-neck-pain.state')
        function state:is_active_tab_registered() return false end
    ]])

    local result = child.lua_get("require('no-neck-pain.util.event').skip_enable('test_scope')")

    Helpers.expect.equality(result, true)
end

T["skip_enable(): returns false for normal buffer with no integrations"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])

    child.cmd("edit test.txt")
    child.wait()

    child.lua([[
        _G.NoNeckPain.state = { 
            enabled = false, 
            active_tab = 1, 
            tabs = {}, 
            disabled_tabs = {} 
        }
        local state = require('no-neck-pain.state')
        function state:is_active_tab_registered() return false end
        function state:is_active_tab_disabled() return false end
    ]])

    local result = child.lua_get("require('no-neck-pain.util.event').skip_enable('test_scope')")

    Helpers.expect.equality(result, false)
end

T["skip_enable(): detects alpha-nvim dashboard"] = function()
    child.lua([[ require('no-neck-pain').setup({
        width = 50,
        integrations = {
            dashboard = {
                filetypes = { "alpha" }
            }
        }
    }) ]])

    child.cmd("edit dashboard.txt")
    child.bo.filetype = "alpha"
    child.wait()

    child.lua([[
        _G.NoNeckPain.state = { 
            enabled = false, 
            active_tab = 1, 
            tabs = {}, 
            disabled_tabs = {} 
        }
        local state = require('no-neck-pain.state')
        function state:is_active_tab_registered() return false end
        function state:is_active_tab_disabled() return false end
    ]])

    local result = child.lua_get("require('no-neck-pain.util.event').skip_enable('test_scope')")

    Helpers.expect.equality(result, true)
end

T["skip_enable(): detects dashboard-nvim dashboard"] = function()
    child.lua([[ require('no-neck-pain').setup({
        width = 50,
        integrations = {
            dashboard = {
                filetypes = { "dashboard" }
            }
        }
    }) ]])

    child.cmd("edit dashboard.txt")
    child.bo.filetype = "dashboard"
    child.wait()

    child.lua([[
        _G.NoNeckPain.state = { 
            enabled = false, 
            active_tab = 1, 
            tabs = {}, 
            disabled_tabs = {} 
        }
        local state = require('no-neck-pain.state')
        function state:is_active_tab_registered() return false end
        function state:is_active_tab_disabled() return false end
    ]])

    local result = child.lua_get("require('no-neck-pain.util.event').skip_enable('test_scope')")

    Helpers.expect.equality(result, true)
end

T["skip_enable(): detects snacks-nvim dashboard"] = function()
    child.lua([[ require('no-neck-pain').setup({
        width = 50,
        integrations = {
            dashboard = {
                filetypes = { "snacks_dashboard" }
            }
        }
    }) ]])

    child.cmd("edit dashboard.txt")
    child.bo.filetype = "snacks_dashboard"
    child.wait()

    child.lua([[
        _G.NoNeckPain.state = { 
            enabled = false, 
            active_tab = 1, 
            tabs = {}, 
            disabled_tabs = {} 
        }
        local state = require('no-neck-pain.state')
        function state:is_active_tab_registered() return false end
        function state:is_active_tab_disabled() return false end
    ]])

    local result = child.lua_get("require('no-neck-pain.util.event').skip_enable('test_scope')")

    Helpers.expect.equality(result, true)
end

T["skip_enable(): detects NvimTree integration"] = function()
    child.lua([[ require('no-neck-pain').setup({
        width = 50,
        integrations = {
            NvimTree = { position = "left" }
        }
    }) ]])

    child.cmd("edit tree.txt")
    child.bo.filetype = "NvimTree"
    child.wait()

    child.lua([[
        _G.NoNeckPain.state = { 
            enabled = false, 
            active_tab = 1, 
            tabs = {}, 
            disabled_tabs = {} 
        }
        local state = require('no-neck-pain.state')
        function state:is_active_tab_registered() return false end
        function state:is_active_tab_disabled() return false end
    ]])

    local result = child.lua_get("require('no-neck-pain.util.event').skip_enable('test_scope')")

    Helpers.expect.equality(result, true)
end

T["skip_enable(): detects neo-tree integration"] = function()
    child.lua([[ require('no-neck-pain').setup({
        width = 50,
        integrations = {
            ["neo-tree"] = { position = "left" }
        }
    }) ]])

    child.cmd("edit tree.txt")
    child.bo.filetype = "neotree"
    child.wait()

    child.lua([[
        _G.NoNeckPain.state = { 
            enabled = false, 
            active_tab = 1, 
            tabs = {}, 
            disabled_tabs = {} 
        }
        local state = require('no-neck-pain.state')
        function state:is_active_tab_registered() return false end
        function state:is_active_tab_disabled() return false end
    ]])

    local result = child.lua_get("require('no-neck-pain.util.event').skip_enable('test_scope')")

    Helpers.expect.equality(result, true)
end

T["skip_enable(): is case insensitive for filetype matching"] = function()
    child.lua([[ require('no-neck-pain').setup({
        width = 50,
        integrations = {
            NvimTree = { position = "left" }
        }
    }) ]])

    child.cmd("edit tree.txt")
    child.bo.filetype = "nvimtree"
    child.wait()

    child.lua([[
        _G.NoNeckPain.state = { 
            enabled = false, 
            active_tab = 1, 
            tabs = {}, 
            disabled_tabs = {} 
        }
        local state = require('no-neck-pain.state')
        function state:is_active_tab_registered() return false end
        function state:is_active_tab_disabled() return false end
    ]])

    local result = child.lua_get("require('no-neck-pain.util.event').skip_enable('test_scope')")

    Helpers.expect.equality(result, true)
end

T["skip_enable(): handles disabled tab state correctly (TabEnter scope)"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()
    child.wait()

    child.nnp()
    child.wait()

    Helpers.expect.state(child, "enabled", false)

    local result = child.lua_get(
        "require('no-neck-pain.util.event').skip_enable('public_api_enable:TabEnter')"
    )

    Helpers.expect.equality(result, true)
end

T["skip_enable(): handles disabled tab state correctly (non-TabEnter scope)"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()
    child.wait()

    child.nnp()
    child.wait()

    Helpers.expect.state(child, "enabled", false)

    local result =
        child.lua_get("require('no-neck-pain.util.event').skip_enable('some_other_scope')")

    Helpers.expect.equality(result, false)
end

-- =============================================================================
-- GROUP 3: Edge Cases and Stress Tests
-- =============================================================================

T["Edge Cases: skip() with deleted window does not error"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()
    child.wait()

    Helpers.expect.state(child, "enabled", true)

    child.cmd("vsplit")
    local new_win = child.api.nvim_get_current_win()
    child.cmd("q")
    child.wait()

    child.lua("vim.api.nvim_set_current_win(1000)")

    local result = child.lua_get("require('no-neck-pain.util.event').skip()")

    Helpers.expect.equality(result, false)
end

T["Edge Cases: skip_enable() with nil filetype"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])

    child.cmd("enew")
    child.bo.filetype = ""
    child.wait()

    child.lua([[
        _G.NoNeckPain.state = { 
            enabled = false, 
            active_tab = 1, 
            tabs = {}, 
            disabled_tabs = {} 
        }
        local state = require('no-neck-pain.state')
        function state:is_active_tab_registered() return false end
        function state:is_active_tab_disabled() return false end
    ]])

    local result = child.lua_get("require('no-neck-pain.util.event').skip_enable('test_scope')")

    Helpers.expect.equality(result, false)
end

T["Edge Cases: skip_enable() with unknown filetype"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])

    child.cmd("edit test.xyz")
    child.bo.filetype = "unknowntype123"
    child.wait()

    child.lua([[
        _G.NoNeckPain.state = { 
            enabled = false, 
            active_tab = 1, 
            tabs = {}, 
            disabled_tabs = {} 
        }
        local state = require('no-neck-pain.state')
        function state:is_active_tab_registered() return false end
        function state:is_active_tab_disabled() return false end
    ]])

    local result = child.lua_get("require('no-neck-pain.util.event').skip_enable('test_scope')")

    Helpers.expect.equality(result, false)
end

T["Edge Cases: rapid skip() calls with window switching"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()
    child.wait()

    Helpers.expect.state(child, "enabled", true)

    for i = 1, 10 do
        child.fn.win_gotoid(1000)
        local result1 = child.lua_get("require('no-neck-pain.util.event').skip()")
        Helpers.expect.equality(result1, false)

        child.fn.win_gotoid(1001)
        local result2 = child.lua_get("require('no-neck-pain.util.event').skip()")
        Helpers.expect.equality(result2, false)
    end

    Helpers.expect.state(child, "enabled", true)
end

T["Edge Cases: skip_enable() with multiple integrations configured"] = function()
    child.lua([[ require('no-neck-pain').setup({
        width = 50,
        integrations = {
            NvimTree = { position = "left" },
            ["neo-tree"] = { position = "left" },
            undotree = { position = "left" },
            dashboard = {
                filetypes = { "alpha", "dashboard", "snacks_dashboard" }
            }
        }
    }) ]])

    child.cmd("edit tree.txt")
    child.bo.filetype = "nvimtree"
    child.wait()

    child.lua([[
        _G.NoNeckPain.state = { 
            enabled = false, 
            active_tab = 1, 
            tabs = {}, 
            disabled_tabs = {} 
        }
        local state = require('no-neck-pain.state')
        function state:is_active_tab_registered() return false end
        function state:is_active_tab_disabled() return false end
    ]])

    local result = child.lua_get("require('no-neck-pain.util.event').skip_enable('test_scope')")

    Helpers.expect.equality(result, true)
end

T["Edge Cases: skip_enable() respects custom dashboard filetypes"] = function()
    child.lua([[ require('no-neck-pain').setup({
        width = 50,
        integrations = {
            dashboard = {
                filetypes = { "custom_dashboard", "my_start_screen" }
            }
        }
    }) ]])

    child.cmd("edit dashboard.txt")
    child.bo.filetype = "custom_dashboard"
    child.wait()

    child.lua([[
        _G.NoNeckPain.state = { 
            enabled = false, 
            active_tab = 1, 
            tabs = {}, 
            disabled_tabs = {} 
        }
        local state = require('no-neck-pain.state')
        function state:is_active_tab_registered() return false end
        function state:is_active_tab_disabled() return false end
    ]])

    local result = child.lua_get("require('no-neck-pain.util.event').skip_enable('test_scope')")

    Helpers.expect.equality(result, true)
end

T["Edge Cases: skip_enable() with no integrations configured"] = function()
    child.lua([[ require('no-neck-pain').setup({
        width = 50,
        integrations = nil
    }) ]])

    child.cmd("edit test.txt")
    child.bo.filetype = "lua"
    child.wait()

    child.lua([[
        _G.NoNeckPain.state = { 
            enabled = false, 
            active_tab = 1, 
            tabs = {}, 
            disabled_tabs = {} 
        }
        local state = require('no-neck-pain.state')
        function state:is_active_tab_registered() return false end
        function state:is_active_tab_disabled() return false end
    ]])

    local result = child.lua_get("require('no-neck-pain.util.event').skip_enable('test_scope')")

    Helpers.expect.equality(result, false)
end

T["Edge Cases: skip() remains correct after multiple enable/disable cycles"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])

    for i = 1, 5 do
        child.nnp()
        child.wait()
        Helpers.expect.state(child, "enabled", true)

        local result_enabled = child.lua_get("require('no-neck-pain.util.event').skip()")
        Helpers.expect.equality(result_enabled, false)

        child.nnp()
        child.wait()
        Helpers.expect.state(child, "enabled", false)

        local result_disabled = child.lua_get("require('no-neck-pain.util.event').skip()")
        Helpers.expect.equality(result_disabled, true)
    end
end

T["Edge Cases: skip_enable() partial filetype match works correctly"] = function()
    child.lua([[ require('no-neck-pain').setup({
        width = 50,
        integrations = {
            ["neo-tree"] = { position = "left" }
        }
    }) ]])

    child.cmd("edit tree.txt")
    child.bo.filetype = "neotree-popup"
    child.wait()

    child.lua([[
        _G.NoNeckPain.state = { 
            enabled = false, 
            active_tab = 1, 
            tabs = {}, 
            disabled_tabs = {} 
        }
        local state = require('no-neck-pain.state')
        function state:is_active_tab_registered() return false end
        function state:is_active_tab_disabled() return false end
    ]])

    local result = child.lua_get("require('no-neck-pain.util.event').skip_enable('test_scope')")

    Helpers.expect.equality(result, true)
end

T["Edge Cases: multiple events in sequence (WinEnter -> WinClosed -> TabEnter)"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()
    child.wait()

    Helpers.expect.state(child, "enabled", true)
    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })

    child.fn.win_gotoid(1000)
    child.wait()

    local skip_result_1 = child.lua_get("require('no-neck-pain.util.event').skip()")
    Helpers.expect.equality(skip_result_1, false)

    child.cmd("vsplit")
    child.wait()
    child.cmd("q")
    child.wait()

    local skip_result_2 = child.lua_get("require('no-neck-pain.util.event').skip()")
    Helpers.expect.equality(skip_result_2, false)

    child.cmd("tabnew")
    child.wait()

    child.lua([[
        local state = require('no-neck-pain.state')
        state.active_tab = 1
    ]])

    local skip_result_3 = child.lua_get("require('no-neck-pain.util.event').skip()")
    Helpers.expect.equality(skip_result_3, true)

    Helpers.expect.state(child, "enabled", true)
end

return T
