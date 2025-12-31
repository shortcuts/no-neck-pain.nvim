local Co = require("no-neck-pain.util.constants")
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

T["tabs"] = MiniTest.new_set()

T["tabs"]["keeps the active tab in state"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()

    Helpers.expect.state(child, "active_tab", 1)

    child.cmd("tabnew")
    child.wait()

    Helpers.expect.state(child, "active_tab", 2)
end

T["tabs"]["new tab doesn't have side buffers"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })
    Helpers.expect.state(child, "active_tab", 1)

    child.cmd("tabnew")
    child.wait()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1003 })
end

T["tabs"]["side buffers coexist on many tabs"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()

    -- tab 1
    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })
    Helpers.expect.state(child, "active_tab", 1)

    Helpers.expect.buf_width_in_range(child, "_G.NoNeckPain.state.tabs[1].wins.main.left", 13, 15)
    Helpers.expect.buf_width_in_range(child, "_G.NoNeckPain.state.tabs[1].wins.main.right", 13, 15)

    -- tab 2
    child.cmd("tabnew")
    child.nnp()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1004, 1003, 1005 })
    Helpers.expect.state(child, "active_tab", 2)

    child.cmd("tabclose")

    -- tab 3
    child.cmd("tabnew")
    child.nnp()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1007, 1006, 1008 })
    Helpers.expect.state(child, "active_tab", 3)

    -- width is preserved as on tab 1
    Helpers.expect.buf_width_in_range(child, "_G.NoNeckPain.state.tabs[1].wins.main.left", 13, 15)
    Helpers.expect.buf_width_in_range(child, "_G.NoNeckPain.state.tabs[1].wins.main.right", 13, 15)

    Helpers.expect.equality(child.get_wins_in_tab(1), { 1001, 1000, 1002 })
    Helpers.expect.equality(child.get_wins_in_tab(3), { 1007, 1006, 1008 })
end

T["tabs"]["previous tab kept side buffers if enabled"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()

    -- tab 1
    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })
    Helpers.expect.state(child, "active_tab", 1)

    -- tab 2
    child.cmd("tabnew")
    child.wait()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1003 })

    -- tab 1
    child.cmd("tabprevious")
    child.wait()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })
    Helpers.expect.state(child, "active_tab", 1)
end

T["tabs"]["does not throw when resizing and tab isn't registered"] = function()
    child.restart({
        "-u",
        "scripts/minimal_init.lua",
        "-p",
        "lua/no-neck-pain/main.lua",
        "lua/no-neck-pain/config.lua",
    })

    child.lua([[ require('no-neck-pain').setup({width=30}) ]])
    child.nnp()

    -- tab 1
    Helpers.expect.equality(child.get_wins_in_tab(), { 1002, 1000, 1003 })
    Helpers.expect.state(child, "active_tab", 1)

    -- tab 2
    child.cmd("tabnext")
    child.wait()

    Helpers.expect.state(child, "active_tab", 2)

    Helpers.expect.equality(child.get_size(), { 24, 80 })
    child.cmd("set columns=30")
    child.wait()

    Helpers.expect.equality(child.get_size(), { 24, 30 })

    child.cmd("tabnext")
    child.wait()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1002, 1000, 1003 })
    Helpers.expect.state(child, "active_tab", 1)
end

T["TabEnter"] = MiniTest.new_set()

T["TabEnter"]["starts the plugin on new tab"] = function()
    child.restart({ "-u", "scripts/init_auto_open.lua" })
    child.wait()

    Helpers.expect.state(child, "enabled", true)

    -- tab 1
    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })

    Helpers.expect.state(child, "active_tab", 1)

    -- tab 2
    child.cmd("tabnew")
    child.wait()

    Helpers.expect.state(child, "active_tab", 2)

    Helpers.expect.equality(child.get_wins_in_tab(), { 1004, 1003, 1005 })
end

T["TabEnter"]["does not re-enable if the user disables it"] = function()
    child.restart({ "-u", "scripts/init_auto_open.lua" })
    child.wait()

    Helpers.expect.state(child, "enabled", true)

    -- tab 1
    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })

    Helpers.expect.state(child, "active_tab", 1)

    -- tab 2
    child.cmd("tabnew")
    child.wait()
    Helpers.expect.state(child, "active_tab", 2)

    Helpers.expect.equality(child.get_wins_in_tab(), { 1004, 1003, 1005 })

    child.nnp()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1003 })
    Helpers.expect.state(child, "active_tab", 2)

    -- tab 1
    child.cmd("tabprevious")
    child.wait()
    Helpers.expect.state(child, "active_tab", 1)

    -- tab 2
    child.cmd("tabnext")
    child.wait()
    Helpers.expect.state(child, "active_tab", 2)

    Helpers.expect.equality(child.get_wins_in_tab(), { 1003 })
end

T["TabEnter"]["allows re-enabling a tab manually disabled"] = function()
    child.restart({ "-u", "scripts/init_auto_open.lua" })
    child.wait()

    Helpers.expect.state(child, "enabled", true)

    -- tab 1
    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })

    Helpers.expect.state(child, "active_tab", 1)

    -- tab 2
    child.cmd("tabnew")
    child.wait()
    Helpers.expect.state(child, "active_tab", 2)

    Helpers.expect.equality(child.get_wins_in_tab(), { 1004, 1003, 1005 })

    child.nnp()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1003 })
    Helpers.expect.state(child, "active_tab", 2)
    Helpers.expect.state(child, "disabled_tabs[2]", true)

    -- tab 1
    child.cmd("tabprevious")
    child.wait()
    Helpers.expect.state(child, "active_tab", 1)

    -- tab 2
    child.cmd("tabnext")
    child.wait()
    Helpers.expect.state(child, "active_tab", 2)

    Helpers.expect.equality(child.get_wins_in_tab(), { 1003 })

    child.nnp()

    Helpers.expect.state(child, "disabled_tabs[2]", vim.NIL)

    Helpers.expect.equality(child.get_wins_in_tab(), { 1006, 1003, 1007 })
end

T["tabnew/tabclose"] = MiniTest.new_set()

T["tabnew/tabclose"]["opening and closing tabs does not throw any error"] = function()
    child.restart({ "-u", "scripts/init_auto_open.lua" })
    child.wait()

    Helpers.expect.state(child, "enabled", true)
    Helpers.expect.state(child, "active_tab", 1)

    child.cmd("tabnew")
    child.wait()
    Helpers.expect.state(child, "active_tab", 2)

    child.cmd("tabclose")
    child.wait()
    Helpers.expect.state(child, "active_tab", 1)

    child.cmd("tabnew")
    child.wait()
    child.cmd("tabnew")
    child.wait()
    Helpers.expect.state(child, "active_tab", 4)

    child.cmd("tabclose")
    child.wait()
    Helpers.expect.state(child, "active_tab", 3)

    child.cmd("tabclose")
    child.wait()
    Helpers.expect.state(child, "active_tab", 1)
end

T["tabnew/tabclose"]["doesn't keep closed tabs in state"] = function()
    child.restart({ "-u", "scripts/init_auto_open.lua" })
    child.wait()

    Helpers.expect.state(child, "enabled", true)
    Helpers.expect.state(child, "active_tab", 1)
    Helpers.expect.state(child, "tabs", {
        {
            id = 1,
            redraw = false,
            scratchpad_enabled = false,
            wins = {
                integrations = Co.INTEGRATIONS,
                main = {
                    curr = 1000,
                    left = 1001,
                    right = 1002,
                },
                columns = 3,
            },
        },
    })

    child.cmd("tabnew")
    child.wait()
    Helpers.expect.state(child, "tabs", {
        {
            id = 1,
            redraw = false,
            scratchpad_enabled = false,
            wins = {
                integrations = Co.INTEGRATIONS,
                main = {
                    curr = 1000,
                    left = 1001,
                    right = 1002,
                },
                columns = 3,
            },
        },
        {
            id = 2,
            redraw = false,
            scratchpad_enabled = false,
            wins = {
                integrations = Co.INTEGRATIONS,
                main = {
                    curr = 1003,
                    left = 1004,
                    right = 1005,
                },
                columns = 3,
            },
        },
    })

    child.cmd("tabclose")
    child.wait()
    Helpers.expect.state(child, "tabs", {
        {
            id = 1,
            redraw = false,
            scratchpad_enabled = false,
            wins = {
                integrations = Co.INTEGRATIONS,
                main = {
                    curr = 1000,
                    left = 1001,
                    right = 1002,
                },
                columns = 3,
            },
        },
    })
end

T["tabnew/tabclose"]["keeps state synchronized between tabs"] = function()
    child.restart({ "-u", "scripts/init_auto_open.lua" })
    child.wait()

    child.cmd("badd 1")
    Helpers.expect.state(child, "enabled", true)
    Helpers.expect.state(child, "active_tab", 1)
    Helpers.expect.state(child, "tabs", {
        {
            id = 1,
            redraw = false,
            scratchpad_enabled = false,
            wins = {
                integrations = Co.INTEGRATIONS,
                main = {
                    curr = 1000,
                    left = 1001,
                    right = 1002,
                },
                columns = 3,
            },
        },
    })

    child.cmd("tabnew")
    child.wait()
    child.cmd("badd 2")
    child.wait()
    Helpers.expect.state(child, "enabled", true)
    Helpers.expect.state(child, "active_tab", 2)
    Helpers.expect.state(child, "tabs", {
        {
            id = 1,
            redraw = false,
            scratchpad_enabled = false,
            wins = {
                integrations = Co.INTEGRATIONS,
                main = {
                    curr = 1000,
                    left = 1001,
                    right = 1002,
                },
                columns = 3,
            },
        },
        {
            id = 2,
            redraw = false,
            scratchpad_enabled = false,
            wins = {
                integrations = Co.INTEGRATIONS,
                main = {
                    curr = 1003,
                    left = 1004,
                    right = 1005,
                },
                columns = 3,
            },
        },
    })

    child.nnp()
    Helpers.expect.state(child, "tabs", {
        {
            id = 1,
            redraw = false,
            scratchpad_enabled = false,
            wins = {
                integrations = Co.INTEGRATIONS,
                main = {
                    curr = 1000,
                    left = 1001,
                    right = 1002,
                },
                columns = 3,
            },
        },
    })

    child.nnp()
    Helpers.expect.state(child, "tabs", {
        {
            id = 1,
            redraw = false,
            scratchpad_enabled = false,
            wins = {
                integrations = Co.INTEGRATIONS,
                main = {
                    curr = 1000,
                    left = 1001,
                    right = 1002,
                },
                columns = 3,
            },
        },
        {
            id = 2,
            redraw = false,
            scratchpad_enabled = false,
            wins = {
                integrations = Co.INTEGRATIONS,
                main = {
                    curr = 1003,
                    left = 1006,
                    right = 1007,
                },
                columns = 3,
            },
        },
    })

    child.cmd("tabprevious")
    child.wait()
    Helpers.expect.state(child, "active_tab", 1)
    Helpers.expect.state(child, "tabs", {
        {
            id = 1,
            redraw = false,
            scratchpad_enabled = false,
            wins = {
                integrations = Co.INTEGRATIONS,
                main = {
                    curr = 1000,
                    left = 1001,
                    right = 1002,
                },
                columns = 3,
            },
        },
        {
            id = 2,
            redraw = false,
            scratchpad_enabled = false,
            wins = {
                integrations = Co.INTEGRATIONS,
                main = {
                    curr = 1003,
                    left = 1006,
                    right = 1007,
                },
                columns = 3,
            },
        },
    })

    child.cmd("tabprevious")
    child.wait()
    Helpers.expect.state(child, "active_tab", 2)
end

T["tabnew/tabclose"]["does not pick tab 1 for the first active tab"] = function()
    child.lua([[require('no-neck-pain').setup({width=50})]])
    Helpers.expect.global_type(child, "_G.NoNeckPain.config", "table")
    Helpers.expect.global_type(child, "_G.NoNeckPain.state", "nil")

    Helpers.expect.equality(child.api.nvim_get_current_tabpage(), 1)
    child.cmd("badd 1")

    child.cmd("tabnew")
    child.wait()
    Helpers.expect.equality(child.api.nvim_get_current_tabpage(), 2)
    child.cmd("badd 2")

    Helpers.expect.global_type(child, "_G.NoNeckPain.state", "nil")
    child.nnp()
    Helpers.expect.equality(child.api.nvim_get_current_tabpage(), 2)
    Helpers.expect.global_type(child, "_G.NoNeckPain.state", "table")
    Helpers.expect.state(child, "enabled", true)
    Helpers.expect.state(child, "tabs[1]", vim.NIL)
    Helpers.expect.state(child, "active_tab", 2)
    Helpers.expect.state(child, "tabs[2]", {
        id = 2,
        redraw = false,
        scratchpad_enabled = false,
        wins = {
            integrations = Co.INTEGRATIONS,
            main = {
                curr = 1001,
                left = 1002,
                right = 1003,
            },
            columns = 3,
        },
    })

    child.cmd("tabprevious")
    child.wait()
    Helpers.expect.equality(child.api.nvim_get_current_tabpage(), 1)
    Helpers.expect.global_type(child, "_G.NoNeckPain.state", "table")
    Helpers.expect.state(child, "enabled", true)
    Helpers.expect.state(child, "tabs[1]", vim.NIL)
    Helpers.expect.state(child, "active_tab", 1)

    child.nnp()
    Helpers.expect.state(child, "tabs[1]", {
        id = 1,
        redraw = false,
        scratchpad_enabled = false,
        wins = {
            integrations = {
                NeoTree = {
                    close = "Neotree close",
                    fileTypePattern = "neo-tree",
                    open = "Neotree reveal",
                },
                NvimDAPUI = {
                    close = "lua require('dapui').close()",
                    fileTypePattern = "dap",
                    open = "lua require('dapui').open()",
                },
                NvimTree = {
                    close = "NvimTreeClose",
                    fileTypePattern = "nvimtree",
                    open = "NvimTreeOpen",
                },
                neotest = {
                    close = "lua require('neotest').summary.close()",
                    fileTypePattern = "neotest",
                    open = "lua require('neotest').summary.open()",
                },
                undotree = {
                    close = "UndotreeToggle",
                    fileTypePattern = "undotree",
                    open = "UndotreeToggle",
                },
                outline = {
                    close = "Outline",
                    fileTypePattern = "outline",
                    open = "Outline",
                },
                aerial = {
                    close = "AerialToggle",
                    fileTypePattern = "aerial",
                    open = "AerialToggle",
                },
            },
            main = {
                curr = 1000,
                left = 1004,
                right = 1005,
            },
            columns = 3,
        },
    })
    Helpers.expect.state(child, "tabs[2]", {
        id = 2,
        redraw = false,
        scratchpad_enabled = false,
        wins = {
            integrations = Co.INTEGRATIONS,
            main = {
                curr = 1001,
                left = 1002,
                right = 1003,
            },
            columns = 3,
        },
    })
end

T["tabnew/tabclose"]["keep state synchronized on second tab"] = function()
    child.lua([[require('no-neck-pain').setup({width=50})]])
    Helpers.expect.global_type(child, "_G.NoNeckPain.config", "table")
    Helpers.expect.global_type(child, "_G.NoNeckPain.state", "nil")

    Helpers.expect.equality(child.api.nvim_get_current_tabpage(), 1)
    child.cmd("badd 1")

    child.cmd("tabnew")
    child.wait()
    Helpers.expect.equality(child.api.nvim_get_current_tabpage(), 2)
    child.cmd("badd 2")

    Helpers.expect.global_type(child, "_G.NoNeckPain.state", "nil")
    child.nnp()
    Helpers.expect.equality(child.api.nvim_get_current_tabpage(), 2)
    Helpers.expect.global_type(child, "_G.NoNeckPain.state", "table")
    Helpers.expect.state(child, "enabled", true)
    Helpers.expect.state(child, "tabs[1]", vim.NIL)
    Helpers.expect.state(child, "active_tab", 2)
    Helpers.expect.state(child, "tabs[2]", {
        id = 2,
        redraw = false,
        scratchpad_enabled = false,
        wins = {
            integrations = Co.INTEGRATIONS,
            main = {
                curr = 1001,
                left = 1002,
                right = 1003,
            },
            columns = 3,
        },
    })

    child.cmd("tabprevious")
    child.wait()
    Helpers.expect.equality(child.api.nvim_get_current_tabpage(), 1)
    Helpers.expect.global_type(child, "_G.NoNeckPain.state", "table")
    Helpers.expect.state(child, "enabled", true)
    Helpers.expect.state(child, "tabs[1]", vim.NIL)
    Helpers.expect.state(child, "active_tab", 1)

    child.cmd("tabnext")
    child.wait()
    Helpers.expect.global_type(child, "_G.NoNeckPain.state", "table")
    Helpers.expect.equality(child.api.nvim_get_current_tabpage(), 2)
    Helpers.expect.state(child, "active_tab", 2)
    Helpers.expect.state(child, "enabled", true)
    Helpers.expect.state(child, "tabs[1]", vim.NIL)
    Helpers.expect.state(child, "tabs[2]", {
        id = 2,
        redraw = false,
        scratchpad_enabled = false,
        wins = {
            integrations = Co.INTEGRATIONS,
            main = {
                curr = 1001,
                left = 1002,
                right = 1003,
            },
            columns = 3,
        },
    })

    child.nnp()
    Helpers.expect.state(child, "tabs", {})
end

T["tabnew/tabclose"]["does not close nvim when quitting tab if some are left"] = function()
    child.lua([[require('no-neck-pain').setup({width=50})]])

    Helpers.expect.equality(child.api.nvim_get_current_tabpage(), 1)
    child.nnp()
    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })

    child.cmd("tabnew")
    child.wait()
    Helpers.expect.equality(child.api.nvim_get_current_tabpage(), 2)
    child.nnp()
    Helpers.expect.equality(child.get_wins_in_tab(), { 1004, 1003, 1005 })

    Helpers.expect.state(child, "enabled", true)
    Helpers.expect.state(child, "tabs[1]", {
        id = 1,
        redraw = false,
        scratchpad_enabled = false,
        wins = {
            integrations = Co.INTEGRATIONS,
            main = {
                curr = 1000,
                left = 1001,
                right = 1002,
            },
            columns = 3,
        },
    })
    Helpers.expect.state(child, "active_tab", 2)
    Helpers.expect.state(child, "tabs[2]", {
        id = 2,
        redraw = false,
        scratchpad_enabled = false,
        wins = {
            integrations = Co.INTEGRATIONS,
            main = {
                curr = 1003,
                left = 1004,
                right = 1005,
            },
            columns = 3,
        },
    })

    child.cmd("q")
    child.wait()
    Helpers.expect.equality(child.api.nvim_get_current_tabpage(), 1)
    Helpers.expect.state(child, "active_tab", 1)
    Helpers.expect.state(child, "tabs[1]", {
        id = 1,
        redraw = false,
        scratchpad_enabled = false,
        wins = {
            integrations = Co.INTEGRATIONS,
            main = {
                curr = 1000,
                left = 1001,
                right = 1002,
            },
            columns = 3,
        },
    })
    Helpers.expect.state(child, "tabs[2]", vim.NIL)
end

T["tabnew/tabclose"]["closes terminal tab without affecting no-neck-pain on other tabs"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()

    Helpers.expect.state(child, "active_tab", 1)
    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })
    Helpers.expect.state(child, "tabs[1]", {
        id = 1,
        redraw = false,
        scratchpad_enabled = false,
        wins = {
            integrations = Co.INTEGRATIONS,
            main = {
                curr = 1000,
                left = 1001,
                right = 1002,
            },
            columns = 3,
        },
    })

    Helpers.expect.equality(child.lua_get("vim.api.nvim_list_tabpages()"), { 1 })

    child.cmd("tabe term://")
    child.wait()

    Helpers.expect.equality(child.lua_get("vim.api.nvim_list_tabpages()"), { 1, 2 })

    -- Enter insert mode in terminal and run the command
    child.cmd("startinsert")
    child.wait()
    child.api.nvim_input("<CR>")
    child.wait()

    Helpers.expect.equality(child.lua_get("vim.api.nvim_list_tabpages()"), { 1 })

    -- Back to tab1 with no-neck-pain intact
    Helpers.expect.state(child, "tabs[1]", {
        id = 1,
        redraw = false,
        scratchpad_enabled = false,
        wins = {
            integrations = Co.INTEGRATIONS,
            main = {
                curr = 1000,
                left = 1001,
                right = 1002,
            },
            columns = 3,
        },
    })

    Helpers.expect.state(child, "tabs[2]", vim.NIL)
    Helpers.expect.equality(child.lua_get("vim.api.nvim_list_tabpages()"), { 1 })
end

return T
