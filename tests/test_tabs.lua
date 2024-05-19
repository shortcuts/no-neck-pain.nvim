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
    Helpers.toggle(child)

    Helpers.expect.state(child, "activeTab", 1)

    child.cmd("tabnew")

    Helpers.expect.state(child, "activeTab", 2)
end

T["tabs"]["new tab doesn't have side buffers"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    Helpers.toggle(child)

    Helpers.expect.equality(Helpers.winsInTab(child), { 1001, 1000, 1002 })
    Helpers.expect.state(child, "activeTab", 1)

    child.cmd("tabnew")

    Helpers.expect.equality(Helpers.winsInTab(child), { 1003 })
end

T["tabs"]["side buffers coexist on many tabs"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    Helpers.toggle(child)

    -- tab 1
    Helpers.expect.equality(Helpers.winsInTab(child), { 1001, 1000, 1002 })
    Helpers.expect.state(child, "activeTab", 1)

    -- tab 2
    child.cmd("tabnew")
    Helpers.toggle(child)

    Helpers.expect.equality(Helpers.winsInTab(child), { 1004, 1003, 1005 })
    Helpers.expect.state(child, "activeTab", 2)

    -- tab 3
    child.cmd("tabnew")
    Helpers.toggle(child)

    Helpers.expect.equality(Helpers.winsInTab(child), { 1007, 1006, 1008 })
    Helpers.expect.state(child, "activeTab", 3)

    Helpers.expect.equality(Helpers.winsInTab(child, 1), { 1001, 1000, 1002 })
    Helpers.expect.equality(Helpers.winsInTab(child, 2), { 1004, 1003, 1005 })
    Helpers.expect.equality(Helpers.winsInTab(child, 3), { 1007, 1006, 1008 })
end

T["tabs"]["previous tab kept side buffers if enabled"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    Helpers.toggle(child)

    -- tab 1
    Helpers.expect.equality(Helpers.winsInTab(child), { 1001, 1000, 1002 })
    Helpers.expect.state(child, "activeTab", 1)

    -- tab 2
    child.cmd("tabnew")

    Helpers.expect.equality(Helpers.winsInTab(child), { 1003 })

    -- tab 1
    child.cmd("tabprevious")

    Helpers.expect.equality(Helpers.winsInTab(child), { 1001, 1000, 1002 })
    Helpers.expect.state(child, "activeTab", 1)
end

T["TabNewEntered"] = MiniTest.new_set()

T["TabNewEntered"]["starts the plugin on new tab"] = function()
    child.restart({ "-u", "scripts/init_auto_open.lua" })
    Helpers.wait(child)

    Helpers.expect.state(child, "enabled", true)

    -- tab 1
    Helpers.expect.equality(Helpers.winsInTab(child), { 1001, 1000, 1002 })

    Helpers.expect.state(child, "activeTab", 1)

    -- tab 2
    child.cmd("tabnew")
    Helpers.wait(child)

    Helpers.expect.state(child, "activeTab", 2)

    Helpers.expect.equality(Helpers.winsInTab(child), { 1004, 1003, 1005 })

    child.stop()
end

T["TabNewEntered"]["does not re-enable if the user disables it"] = function()
    child.restart({ "-u", "scripts/init_auto_open.lua" })
    Helpers.wait(child)

    Helpers.expect.state(child, "enabled", true)

    -- tab 1
    Helpers.expect.equality(Helpers.winsInTab(child), { 1001, 1000, 1002 })

    Helpers.expect.state(child, "activeTab", 1)

    -- tab 2
    child.cmd("tabnew")
    Helpers.wait(child)
    Helpers.expect.state(child, "activeTab", 2)

    Helpers.expect.equality(Helpers.winsInTab(child), { 1004, 1003, 1005 })

    Helpers.toggle(child)

    Helpers.expect.equality(Helpers.winsInTab(child), { 1003 })
    Helpers.expect.state(child, "activeTab", 2)

    -- tab 1
    child.cmd("tabprevious")
    Helpers.expect.state(child, "activeTab", 1)

    -- tab 2
    child.cmd("tabnext")
    Helpers.expect.state(child, "activeTab", 2)

    Helpers.expect.equality(Helpers.winsInTab(child), { 1003 })

    child.stop()
end

T["tabnew/tabclose"] = MiniTest.new_set()

T["tabnew/tabclose"]["opening and closing tabs does not throw any error"] = function()
    child.restart({ "-u", "scripts/init_auto_open.lua" })
    Helpers.wait(child)

    Helpers.expect.state(child, "enabled", true)
    Helpers.expect.state(child, "activeTab", 1)

    child.cmd("tabnew")
    Helpers.wait(child)
    Helpers.expect.state(child, "activeTab", 2)

    child.cmd("tabclose")
    Helpers.expect.state(child, "activeTab", 1)

    child.cmd("tabnew")
    Helpers.wait(child)
    child.cmd("tabnew")
    Helpers.wait(child)
    Helpers.expect.state(child, "activeTab", 4)

    child.cmd("tabclose")
    Helpers.expect.state(child, "activeTab", 3)

    child.cmd("tabclose")
    Helpers.expect.state(child, "activeTab", 1)
end

T["tabnew/tabclose"]["doesn't keep closed tabs in state"] = function()
    child.restart({ "-u", "scripts/init_auto_open.lua" })
    Helpers.wait(child)

    Helpers.expect.state(child, "enabled", true)
    Helpers.expect.state(child, "activeTab", 1)
    Helpers.expect.state(child, "tabs", {
        {
            id = 1,
            layers = {
                split = 1,
                vsplit = 1,
            },
            scratchPadEnabled = false,
            wins = {
                integrations = Co.INTEGRATIONS,
                main = {
                    curr = 1000,
                    left = 1001,
                    right = 1002,
                },
            },
        },
    })

    child.cmd("tabnew")
    Helpers.wait(child)
    Helpers.expect.state(child, "tabs", {
        {
            id = 1,
            layers = {
                split = 1,
                vsplit = 1,
            },
            scratchPadEnabled = false,
            wins = {
                integrations = Co.INTEGRATIONS,
                main = {
                    curr = 1000,
                    left = 1001,
                    right = 1002,
                },
            },
        },
        {
            id = 2,
            layers = {
                split = 1,
                vsplit = 1,
            },
            scratchPadEnabled = false,
            wins = {
                integrations = Co.INTEGRATIONS,
                main = {
                    curr = 1003,
                    left = 1004,
                    right = 1005,
                },
            },
        },
    })

    child.cmd("tabclose")
    Helpers.expect.state(child, "tabs", {
        {
            id = 1,
            layers = {
                split = 1,
                vsplit = 1,
            },
            scratchPadEnabled = false,
            wins = {
                integrations = Co.INTEGRATIONS,
                main = {
                    curr = 1000,
                    left = 1001,
                    right = 1002,
                },
            },
        },
    })
end

T["tabnew/tabclose"]["keeps state synchronized between tabs"] = function()
    child.restart({ "-u", "scripts/init_auto_open.lua" })
    Helpers.wait(child)

    child.cmd("badd 1")
    Helpers.expect.state(child, "enabled", true)
    Helpers.expect.state(child, "activeTab", 1)
    Helpers.expect.state(child, "tabs", {
        {
            id = 1,
            layers = {
                split = 1,
                vsplit = 1,
            },
            scratchPadEnabled = false,
            wins = {
                integrations = Co.INTEGRATIONS,
                main = {
                    curr = 1000,
                    left = 1001,
                    right = 1002,
                },
            },
        },
    })

    child.cmd("tabnew")
    Helpers.wait(child)
    child.cmd("badd 2")
    Helpers.expect.state(child, "enabled", true)
    Helpers.expect.state(child, "activeTab", 2)
    Helpers.expect.state(child, "tabs", {
        {
            id = 1,
            layers = {
                split = 1,
                vsplit = 1,
            },
            scratchPadEnabled = false,
            wins = {
                integrations = Co.INTEGRATIONS,
                main = {
                    curr = 1000,
                    left = 1001,
                    right = 1002,
                },
            },
        },
        {
            id = 2,
            layers = {
                split = 1,
                vsplit = 1,
            },
            scratchPadEnabled = false,
            wins = {
                integrations = Co.INTEGRATIONS,
                main = {
                    curr = 1003,
                    left = 1004,
                    right = 1005,
                },
            },
        },
    })

    Helpers.toggle(child)
    Helpers.expect.state(child, "tabs", {
        {
            id = 1,
            layers = {
                split = 1,
                vsplit = 1,
            },
            scratchPadEnabled = false,
            wins = {
                integrations = Co.INTEGRATIONS,
                main = {
                    curr = 1000,
                    left = 1001,
                    right = 1002,
                },
            },
        },
    })

    Helpers.toggle(child)
    Helpers.expect.state(child, "tabs", {
        {
            id = 1,
            layers = {
                split = 1,
                vsplit = 1,
            },
            scratchPadEnabled = false,
            wins = {
                integrations = Co.INTEGRATIONS,
                main = {
                    curr = 1000,
                    left = 1001,
                    right = 1002,
                },
            },
        },
        {
            id = 2,
            layers = {
                split = 1,
                vsplit = 1,
            },
            scratchPadEnabled = false,
            wins = {
                integrations = Co.INTEGRATIONS,
                main = {
                    curr = 1003,
                    left = 1006,
                    right = 1007,
                },
            },
        },
    })

    child.cmd("tabprevious")
    Helpers.expect.state(child, "activeTab", 1)
    Helpers.expect.state(child, "tabs", {
        {
            id = 1,
            layers = {
                split = 1,
                vsplit = 1,
            },
            scratchPadEnabled = false,
            wins = {
                integrations = Co.INTEGRATIONS,
                main = {
                    curr = 1000,
                    left = 1001,
                    right = 1002,
                },
            },
        },
        {
            id = 2,
            layers = {
                split = 1,
                vsplit = 1,
            },
            scratchPadEnabled = false,
            wins = {
                integrations = Co.INTEGRATIONS,
                main = {
                    curr = 1003,
                    left = 1006,
                    right = 1007,
                },
            },
        },
    })

    child.cmd("tabprevious")
    Helpers.expect.state(child, "activeTab", 2)
end

T["tabnew/tabclose"]["does not pick tab 1 for the first active tab"] = function()
    child.lua([[require('no-neck-pain').setup({width=50})]])
    Helpers.expect.global_type(child, "_G.NoNeckPain.config", "table")
    Helpers.expect.global_type(child, "_G.NoNeckPain.state", "nil")

    Helpers.expect.equality(child.api.nvim_get_current_tabpage(), 1)
    child.cmd("badd 1")

    child.cmd("tabnew")
    Helpers.expect.equality(child.api.nvim_get_current_tabpage(), 2)
    child.cmd("badd 2")

    Helpers.expect.global_type(child, "_G.NoNeckPain.state", "nil")
    Helpers.toggle(child)
    Helpers.expect.equality(child.api.nvim_get_current_tabpage(), 2)
    Helpers.expect.global_type(child, "_G.NoNeckPain.state", "table")
    Helpers.expect.state(child, "enabled", true)
    Helpers.expect.state(child, "tabs[1]", vim.NIL)
    Helpers.expect.state(child, "activeTab", 2)
    Helpers.expect.state(child, "tabs[2]", {
        id = 2,
        layers = {
            split = 1,
            vsplit = 1,
        },
        scratchPadEnabled = false,
        wins = {
            integrations = Co.INTEGRATIONS,
            main = {
                curr = 1001,
                left = 1002,
                right = 1003,
            },
        },
    })

    child.cmd("tabprevious")
    Helpers.expect.equality(child.api.nvim_get_current_tabpage(), 1)
    Helpers.expect.global_type(child, "_G.NoNeckPain.state", "table")
    Helpers.expect.state(child, "enabled", true)
    Helpers.expect.state(child, "tabs[1]", vim.NIL)
    Helpers.expect.state(child, "activeTab", 1)

    Helpers.toggle(child)
    Helpers.expect.state(child, "tabs[1]", {
        id = 1,
        layers = {
            split = 1,
            vsplit = 1,
        },
        scratchPadEnabled = false,
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
                TSPlayground = {
                    close = "TSPlaygroundToggle",
                    fileTypePattern = "tsplayground",
                    open = "TSPlaygroundToggle",
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
        },
    })
    Helpers.expect.state(child, "tabs[2]", {
        id = 2,
        layers = {
            split = 1,
            vsplit = 1,
        },
        scratchPadEnabled = false,
        wins = {
            integrations = Co.INTEGRATIONS,
            main = {
                curr = 1001,
                left = 1002,
                right = 1003,
            },
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
    Helpers.expect.equality(child.api.nvim_get_current_tabpage(), 2)
    child.cmd("badd 2")

    Helpers.expect.global_type(child, "_G.NoNeckPain.state", "nil")
    Helpers.toggle(child)
    Helpers.expect.equality(child.api.nvim_get_current_tabpage(), 2)
    Helpers.expect.global_type(child, "_G.NoNeckPain.state", "table")
    Helpers.expect.state(child, "enabled", true)
    Helpers.expect.state(child, "tabs[1]", vim.NIL)
    Helpers.expect.state(child, "activeTab", 2)
    Helpers.expect.state(child, "tabs[2]", {
        id = 2,
        layers = {
            split = 1,
            vsplit = 1,
        },
        scratchPadEnabled = false,
        wins = {
            integrations = Co.INTEGRATIONS,
            main = {
                curr = 1001,
                left = 1002,
                right = 1003,
            },
        },
    })

    child.cmd("tabprevious")
    Helpers.expect.equality(child.api.nvim_get_current_tabpage(), 1)
    Helpers.expect.global_type(child, "_G.NoNeckPain.state", "table")
    Helpers.expect.state(child, "enabled", true)
    Helpers.expect.state(child, "tabs[1]", vim.NIL)
    Helpers.expect.state(child, "activeTab", 1)

    child.cmd("tabnext")
    Helpers.expect.global_type(child, "_G.NoNeckPain.state", "table")
    Helpers.expect.equality(child.api.nvim_get_current_tabpage(), 2)
    Helpers.expect.state(child, "activeTab", 2)
    Helpers.expect.state(child, "enabled", true)
    Helpers.expect.state(child, "tabs[1]", vim.NIL)
    Helpers.expect.state(child, "tabs[2]", {
        id = 2,
        layers = {
            split = 1,
            vsplit = 1,
        },
        scratchPadEnabled = false,
        wins = {
            integrations = Co.INTEGRATIONS,
            main = {
                curr = 1001,
                left = 1002,
                right = 1003,
            },
        },
    })

    Helpers.toggle(child)
    Helpers.expect.state(child, "tabs", vim.NIL)
end

return T
