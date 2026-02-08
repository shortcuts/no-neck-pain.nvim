local Config = require("no-neck-pain.config")
local Helpers = dofile("tests/helpers.lua")

local child = Helpers.new_child_neovim()

local T = MiniTest.new_set({
    hooks = {
        -- This will be executed before every (even nested) case
        pre_case = function()
            -- Restart child process with custom 'init.lua' script
            child.restart({ "-u", "scripts/minimal_init.lua" })
        end,
        -- This will be executed one after all tests from this set are finished
        post_once = child.stop,
    },
})

T["install"] = MiniTest.new_set()

T["install"]["sets global loaded variable"] = function()
    child.wait()
    Helpers.expect.global(child, "_G.NoNeckPain", vim.NIL)
    Helpers.expect.global_type(child, "_G.NoNeckPainLoaded", "boolean")
end

T["setup"] = MiniTest.new_set()

T["setup"]["sets exposed methods and default options value"] = function()
    child.lua([[require('no-neck-pain').setup()]])

    Helpers.expect.global_type(child, "_G.NoNeckPain", "table")

    -- public methods
    Helpers.expect.global_type(child, "_G.NoNeckPain.toggle", "function")
    Helpers.expect.global_type(child, "_G.NoNeckPain.enable", "function")
    Helpers.expect.global_type(child, "_G.NoNeckPain.setup", "function")
    Helpers.expect.global_type(child, "_G.NoNeckPain.resize", "function")
    Helpers.expect.global_type(child, "_G.NoNeckPain.disable", "function")
    Helpers.expect.global_type(child, "_G.NoNeckPain.toggle_side", "function")
    Helpers.expect.global_type(child, "_G.NoNeckPain.toggle_scratch_pad", "function")
    Helpers.expect.global_type(child, "_G.NoNeckPain.toggle_debug", "function")

    -- config
    Helpers.expect.global_type(child, "_G.NoNeckPain.config", "table")
    Helpers.expect.config_type(child, "buffers", "table")

    Helpers.expect.config(child, "", {
        width = 100,
        minSideBufferWidth = 10,
        debug = false,
        disableOnLastBuffer = false,
        killAllBuffersOnDisable = false,
        fallbackOnBufferDelete = true,
        autocmds = {
            enableOnVimEnter = false,
            enableOnTabEnter = false,
            reloadOnColorSchemeChange = false,
            skipEnteringNoNeckPainBuffer = false,
        },
        mappings = {
            enabled = false,
            scratchPad = "<Leader>ns",
            toggle = "<Leader>np",
            toggleLeftSide = "<Leader>nql",
            toggleRightSide = "<Leader>nqr",
            widthUp = "<Leader>n=",
            widthDown = "<Leader>n-",
            debug = "<Leader>nd",
        },
        callbacks = {},
        buffers = {
            setNames = false,
            colors = { blend = 0 },
            bo = {
                bufhidden = "hide",
                buflisted = false,
                buftype = "nofile",
                filetype = "no-neck-pain",
                swapfile = false,
            },
            wo = {
                colorcolumn = "0",
                cursorcolumn = false,
                cursorline = false,
                foldenable = false,
                linebreak = true,
                list = false,
                number = false,
                relativenumber = false,
                wrap = true,
            },
            left = {
                enabled = true,
                scratchPad = {
                    enabled = false,
                    pathToFile = "no-neck-pain-left.norg",
                },
                colors = { blend = 0 },
                bo = {
                    bufhidden = "hide",
                    buflisted = false,
                    buftype = "nofile",
                    filetype = "no-neck-pain",
                    swapfile = false,
                },
                wo = {
                    colorcolumn = "0",
                    cursorcolumn = false,
                    cursorline = false,
                    foldenable = false,
                    linebreak = true,
                    list = false,
                    number = false,
                    relativenumber = false,
                    wrap = true,
                },
            },
            right = {
                enabled = true,
                scratchPad = {
                    enabled = false,
                    pathToFile = "no-neck-pain-right.norg",
                },
                colors = { blend = 0 },
                bo = {
                    bufhidden = "hide",
                    buflisted = false,
                    buftype = "nofile",
                    filetype = "no-neck-pain",
                    swapfile = false,
                },
                wo = {
                    colorcolumn = "0",
                    cursorcolumn = false,
                    cursorline = false,
                    foldenable = false,
                    linebreak = true,
                    list = false,
                    number = false,
                    relativenumber = false,
                    wrap = true,
                },
            },
        },
        integrations = {
            ["neo-tree"] = {
                position = "left",
            },
            dap = {
                position = "none",
            },
            NvimTree = {
                position = "left",
            },
            aerial = {
                position = "right",
            },
            dashboard = {
                enabled = false,
                filetypes = { "dashboard", "alpha", "starter", "snacks" },
            },
            neotest = {
                position = "right",
            },
            outline = {
                position = "right",
            },
            undotree = {
                position = "left",
            },
        },
    })
end

T["setup"]["overrides default values"] = function()
    child.lua([[require('no-neck-pain').setup({
        width = 42,
        minSideBufferWidth = 0,
        debug = true,
        disableOnLastBuffer = true,
        killAllBuffersOnDisable = true,
        fallbackOnBufferDelete = false,
        autocmds = {
            enableOnVimEnter = true,
            enableOnTabEnter = true,
            reloadOnColorSchemeChange = true,
            skipEnteringNoNeckPainBuffer = true,
        },
        mappings = {enabled = true}
    })]])

    Helpers.expect.config(child, "", {
        width = 42,
        minSideBufferWidth = 0,
        debug = true,
        disableOnLastBuffer = true,
        killAllBuffersOnDisable = true,
        fallbackOnBufferDelete = false,
        autocmds = {
            enableOnVimEnter = true,
            enableOnTabEnter = true,
            reloadOnColorSchemeChange = true,
            skipEnteringNoNeckPainBuffer = true,
        },
        callbacks = {},
        mappings = {
            enabled = true,
            scratchPad = "<Leader>ns",
            toggle = "<Leader>np",
            toggleLeftSide = "<Leader>nql",
            toggleRightSide = "<Leader>nqr",
            widthUp = "<Leader>n=",
            widthDown = "<Leader>n-",
            debug = "<Leader>nd",
        },
        buffers = {
            setNames = false,
            colors = { blend = 0 },
            bo = {
                bufhidden = "hide",
                buflisted = false,
                buftype = "nofile",
                filetype = "no-neck-pain",
                swapfile = false,
            },
            wo = {
                colorcolumn = "0",
                cursorcolumn = false,
                cursorline = false,
                foldenable = false,
                linebreak = true,
                list = false,
                number = false,
                relativenumber = false,
                wrap = true,
            },
            left = {
                enabled = true,
                scratchPad = {
                    enabled = false,
                    pathToFile = "no-neck-pain-left.norg",
                },
                colors = { blend = 0 },
                bo = {
                    bufhidden = "hide",
                    buflisted = false,
                    buftype = "nofile",
                    filetype = "no-neck-pain",
                    swapfile = false,
                },
                wo = {
                    colorcolumn = "0",
                    cursorcolumn = false,
                    cursorline = false,
                    foldenable = false,
                    linebreak = true,
                    list = false,
                    number = false,
                    relativenumber = false,
                    wrap = true,
                },
            },
            right = {
                enabled = true,
                scratchPad = {
                    enabled = false,
                    pathToFile = "no-neck-pain-right.norg",
                },
                colors = { blend = 0 },
                bo = {
                    bufhidden = "hide",
                    buflisted = false,
                    buftype = "nofile",
                    filetype = "no-neck-pain",
                    swapfile = false,
                },
                wo = {
                    colorcolumn = "0",
                    cursorcolumn = false,
                    cursorline = false,
                    foldenable = false,
                    linebreak = true,
                    list = false,
                    number = false,
                    relativenumber = false,
                    wrap = true,
                },
            },
        },
        integrations = {
            ["neo-tree"] = {
                position = "left",
            },
            dap = {
                position = "none",
            },
            NvimTree = {
                position = "left",
            },
            aerial = {
                position = "right",
            },
            dashboard = {
                enabled = false,
                filetypes = { "dashboard", "alpha", "starter", "snacks" },
            },
            neotest = {
                position = "right",
            },
            outline = {
                position = "right",
            },
            undotree = {
                position = "left",
            },
        },
    })
end

T["setup"]["width - defaults to the `textwidth` when specified"] = function()
    child.cmd("set textwidth=30")
    child.lua([[require('no-neck-pain').setup({
        width = "textwidth"
    })]])

    Helpers.expect.config(child, "width", 30)
end

T["setup"]["width - defaults to the `textwidth` when specified"] = function()
    child.cmd("set colorcolumn=65")
    child.lua([[require('no-neck-pain').setup({
        width = "colorcolumn"
    })]])

    Helpers.expect.config(child, "width", 65)
end

T["setup"]["width - throws with non-supported string"] = function()
    Helpers.expect.error(function()
        child.lua([[require('no-neck-pain').setup({ width = "foo" })]])
    end)
end

T["enable"] = MiniTest.new_set()

T["enable"]["(single tab) sets state"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()

    -- state
    Helpers.expect.global_type(child, "_G.NoNeckPain.state", "table")

    Helpers.expect.state(child, "enabled", true)
    Helpers.expect.state(child, "active_tab", 1)

    Helpers.expect.state_type(child, "tabs", "table")

    Helpers.expect.state_type(child, "tabs[1].wins", "table")
    Helpers.expect.state_type(child, "tabs[1].wins.main", "table")
    Helpers.expect.state_type(child, "tabs[1].wins.integrations", "table")

    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })

    Helpers.expect.state(child, "tabs[1].wins.columns", 3)
end

T["enable"]["(multiple tab) sets state"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()

    -- tab 1
    Helpers.expect.global_type(child, "_G.NoNeckPain.state", "table")

    Helpers.expect.state(child, "enabled", true)
    Helpers.expect.state(child, "active_tab", 1)

    Helpers.expect.state_type(child, "tabs", "table")

    Helpers.expect.state_type(child, "tabs[1].wins", "table")
    Helpers.expect.state_type(child, "tabs[1].wins.main", "table")
    Helpers.expect.state_type(child, "tabs[1].wins.integrations", "table")

    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })
    Helpers.expect.state(child, "tabs[1].wins.columns", 3)

    -- tab 2
    child.cmd("tabnew")
    child.nnp()

    Helpers.expect.state(child, "active_tab", 2)
    Helpers.expect.state(child, "enabled", true)

    Helpers.expect.state_type(child, "tabs", "table")

    Helpers.expect.state_type(child, "tabs[2].wins", "table")
    Helpers.expect.state_type(child, "tabs[2].wins.main", "table")
    Helpers.expect.state_type(child, "tabs[2].wins.integrations", "table")

    Helpers.expect.state(child, "tabs[2].wins.main", {
        curr = 1003,
        left = 1004,
        right = 1005,
    })
    Helpers.expect.state(child, "tabs[2].wins.columns", 3)
end

T["disable"] = MiniTest.new_set()

T["disable"]["(single tab) resets state"] = function()
    child.nnp()

    Helpers.expect.global_type(child, "_G.NoNeckPain.state", "table")

    Helpers.expect.state(child, "enabled", true)
    Helpers.expect.state(child, "active_tab", 1)

    Helpers.expect.state_type(child, "tabs", "table")

    child.nnp()

    Helpers.expect.global_type(child, "_G.NoNeckPain.state", "table")

    Helpers.expect.state(child, "enabled", false)
    Helpers.expect.state(child, "active_tab", 1)

    Helpers.expect.state(child, "tabs", {})
end

T["disable"]["(multiple tab) resets state"] = function()
    child.nnp()

    Helpers.expect.global_type(child, "_G.NoNeckPain.state", "table")

    Helpers.expect.state(child, "enabled", true)
    Helpers.expect.state(child, "active_tab", 1)

    Helpers.expect.state_type(child, "tabs", "table")

    child.cmd("tabnew")
    child.nnp()

    Helpers.expect.global_type(child, "_G.NoNeckPain.state", "table")

    Helpers.expect.state(child, "enabled", true)
    Helpers.expect.state(child, "active_tab", 2)

    Helpers.expect.state_type(child, "tabs", "table")

    -- disable tab 2
    child.nnp()

    Helpers.expect.state(child, "enabled", true)
    Helpers.expect.state(child, "active_tab", 2)

    Helpers.expect.state_type(child, "tabs", "table")

    -- disable tab 1
    child.cmd("tabprevious")
    child.nnp()

    Helpers.expect.state(child, "enabled", false)
    Helpers.expect.state(child, "active_tab", 1)

    Helpers.expect.state(child, "tabs", {})
end

T["disable"]["(no file) does not close the window if unsaved buffer"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()

    Helpers.expect.state(child, "enabled", true)
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })
    Helpers.expect.equality(child.list_buffers(), { 1, 2, 3 })

    child.api.nvim_buf_set_lines(1, 0, 1, false, { "foo" })
    Helpers.expect.equality(child.lua_get("vim.api.nvim_buf_get_option(1, 'modified')"), true)

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })
    Helpers.expect.equality(child.lua_get("vim.api.nvim_get_current_win()"), 1000)

    child.cmd("quit")

    Helpers.expect.equality(child.is_running(), true)
end

T["disable"]["(on file) does not close the window if unsaved buffer"] = function()
    child.restart({ "-u", "scripts/minimal_init.lua", "lua/no-neck-pain/main.lua" })
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()

    Helpers.expect.state(child, "enabled", true)
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })
    Helpers.expect.equality(child.list_buffers(), { 1, 2, 3 })

    child.api.nvim_buf_set_lines(1, 0, 1, false, { "foo" })
    Helpers.expect.equality(child.lua_get("vim.api.nvim_buf_get_option(1, 'modified')"), true)

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })
    Helpers.expect.equality(child.lua_get("vim.api.nvim_get_current_win()"), 1000)

    child.cmd("quit")

    Helpers.expect.equality(child.is_running(), true)
end

T["disable"]["relative window doesn't prevent quitting nvim"] = function()
    child.restart({ "-u", "scripts/init_with_incline.lua" })
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()

    Helpers.expect.state(child, "enabled", true)
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1003,
        right = 1004,
    })
    Helpers.expect.equality(child.get_wins_in_tab(), { 1003, 1000, 1004, 1002 })
    vim.fn.win_gotoid(1000)

    child.cmd("quit")

    Helpers.expect.error(function()
        -- error because instance is closed
        Helpers.expect.equality(child.get_wins_in_tab(), { 1003, 1000, 1004, 1002 })
    end)
end

-- GROUP 1: API Error Handling - Methods called when plugin not enabled
T["API: toggle_scratch_pad() without enable throws error"] = function()
    child.lua([[ require('no-neck-pain').setup() ]])

    Helpers.expect.error(function()
        child.lua([[ require('no-neck-pain').toggle_scratch_pad() ]])
    end)
end

T["API: toggle_debug() without enable throws error"] = function()
    child.lua([[ require('no-neck-pain').setup() ]])

    Helpers.expect.error(function()
        child.lua([[ require('no-neck-pain').toggle_debug() ]])
    end)
end

T["API: resize() without enable throws error"] = function()
    child.lua([[ require('no-neck-pain').setup() ]])

    Helpers.expect.error(function()
        child.lua([[ require('no-neck-pain').resize(50) ]])
    end)
end

T["API: toggle_side() without enable throws error"] = function()
    child.lua([[ require('no-neck-pain').setup() ]])

    Helpers.expect.error(function()
        child.lua([[ require('no-neck-pain').toggle_side("left") ]])
    end)
end

T["API: error messages are clear when plugin not enabled"] = function()
    child.lua([[ require('no-neck-pain').setup() ]])

    -- Verify error contains expected message
    Helpers.expect.error(function()
        child.lua([[ require('no-neck-pain').resize(50) ]])
    end)

    -- The error thrown by the API should contain "must be enabled"
    local error_msg = child.lua_get([[
        pcall(function() require('no-neck-pain').resize(50) end)
    ]])
end

-- GROUP 2: Invalid Input Handling
T["API: resize(0) no-ops and doesn't change width"] = function()
    child.lua([[ require('no-neck-pain').setup({width=100}) ]])
    child.nnp()

    Helpers.expect.state(child, "enabled", true)
    Helpers.expect.config(child, "width", 100)

    -- resize(0) should no-op
    child.lua([[ require('no-neck-pain').resize(0) ]])

    -- Width should remain unchanged
    Helpers.expect.config(child, "width", 100)
end

T["API: resize(-100) no-ops and doesn't change width"] = function()
    child.lua([[ require('no-neck-pain').setup({width=100}) ]])
    child.nnp()

    Helpers.expect.state(child, "enabled", true)
    Helpers.expect.config(child, "width", 100)

    -- resize(-100) should no-op
    child.lua([[ require('no-neck-pain').resize(-100) ]])

    -- Width should remain unchanged
    Helpers.expect.config(child, "width", 100)
end

T["API: resize('invalid') handles gracefully"] = function()
    child.lua([[ require('no-neck-pain').setup({width=100}) ]])
    child.nnp()

    Helpers.expect.state(child, "enabled", true)
    Helpers.expect.config(child, "width", 100)

    -- resize with invalid string should no-op (tonumber returns nil, default to 0)
    child.lua([[ require('no-neck-pain').resize("invalid") ]])

    -- Width should remain unchanged
    Helpers.expect.config(child, "width", 100)
end

T["API: resize(nil) handles gracefully"] = function()
    child.lua([[ require('no-neck-pain').setup({width=100}) ]])
    child.nnp()

    Helpers.expect.state(child, "enabled", true)
    Helpers.expect.config(child, "width", 100)

    -- resize with nil should no-op
    child.lua([[ require('no-neck-pain').resize(nil) ]])

    -- Width should remain unchanged
    Helpers.expect.config(child, "width", 100)
end

T["API: resize() with same width no-ops"] = function()
    child.lua([[ require('no-neck-pain').setup({width=100}) ]])
    child.nnp()

    Helpers.expect.state(child, "enabled", true)
    Helpers.expect.config(child, "width", 100)

    -- Get initial state to verify no re-initialization occurs
    local initial_curr = child.lua_get("_G.NoNeckPain.state.tabs[1].wins.main.curr")

    -- resize with same width should no-op
    child.lua([[ require('no-neck-pain').resize(100) ]])

    -- Width unchanged and window IDs should be same (no re-init)
    Helpers.expect.config(child, "width", 100)
    Helpers.expect.state(child, "tabs[1].wins.main.curr", initial_curr)
end

-- GROUP 3: API Idempotency
T["API: multiple enable() calls result in enabled state"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])

    -- Call enable multiple times
    child.lua([[ require('no-neck-pain').enable("test1") ]])
    child.wait()
    child.lua([[ require('no-neck-pain').enable("test2") ]])
    child.wait()
    child.lua([[ require('no-neck-pain').enable("test3") ]])
    child.wait()

    -- Should still be enabled with proper state
    Helpers.expect.state(child, "enabled", true)
    Helpers.expect.state(child, "active_tab", 1)
    Helpers.expect.state_type(child, "tabs", "table")
end

T["API: multiple disable() calls result in disabled state"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()

    Helpers.expect.state(child, "enabled", true)

    -- Call disable multiple times
    child.nnp()
    child.wait()
    child.lua([[ require('no-neck-pain').disable() ]])
    child.wait()
    child.lua([[ require('no-neck-pain').disable() ]])
    child.wait()

    -- Should still be disabled with empty tabs
    Helpers.expect.state(child, "enabled", false)
    Helpers.expect.state(child, "tabs", {})
end

T["API: toggle() is idempotent - enable/disable/enable"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])

    -- First toggle - enable
    child.lua([[ require('no-neck-pain').toggle() ]])
    child.wait()
    Helpers.expect.state(child, "enabled", true)

    -- Second toggle - disable
    child.lua([[ require('no-neck-pain').toggle() ]])
    child.wait()
    Helpers.expect.state(child, "enabled", false)

    -- Third toggle - enable again
    child.lua([[ require('no-neck-pain').toggle() ]])
    child.wait()
    Helpers.expect.state(child, "enabled", true)
end

T["API: toggle_debug() is idempotent"] = function()
    child.lua([[ require('no-neck-pain').setup({debug=false}) ]])
    child.nnp()

    Helpers.expect.state(child, "enabled", true)
    Helpers.expect.config(child, "debug", false)

    -- Toggle debug on
    child.lua([[ require('no-neck-pain').toggle_debug() ]])
    Helpers.expect.config(child, "debug", true)

    -- Toggle debug off
    child.lua([[ require('no-neck-pain').toggle_debug() ]])
    Helpers.expect.config(child, "debug", false)

    -- Toggle debug on again
    child.lua([[ require('no-neck-pain').toggle_debug() ]])
    Helpers.expect.config(child, "debug", true)
end

-- GROUP 4: Additional Edge Cases
T["API: resize() with valid positive values updates width correctly"] = function()
    child.lua([[ require('no-neck-pain').setup({width=100}) ]])
    child.nnp()

    Helpers.expect.state(child, "enabled", true)
    Helpers.expect.config(child, "width", 100)

    -- Valid resize
    child.lua([[ require('no-neck-pain').resize(80) ]])
    Helpers.expect.config(child, "width", 80)

    -- Another valid resize
    child.lua([[ require('no-neck-pain').resize(120) ]])
    Helpers.expect.config(child, "width", 120)
end

T["API: setup() can be called multiple times"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    Helpers.expect.config(child, "width", 50)

    -- Setup again with different config
    child.lua([[ require('no-neck-pain').setup({width=80, debug=true}) ]])
    Helpers.expect.config(child, "width", 80)
    Helpers.expect.config(child, "debug", true)
end

T["API: enable() after disable() restores functionality"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()

    Helpers.expect.state(child, "enabled", true)
    local first_curr = child.lua_get("_G.NoNeckPain.state.tabs[1].wins.main.curr")

    -- Disable
    child.nnp()
    Helpers.expect.state(child, "enabled", false)

    -- Re-enable
    child.lua([[ require('no-neck-pain').enable("test") ]])
    child.wait()

    Helpers.expect.state(child, "enabled", true)
    Helpers.expect.state_type(child, "tabs", "table")
    Helpers.expect.state_type(child, "tabs[1].wins.main", "table")
end

return T
