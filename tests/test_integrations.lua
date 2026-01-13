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

T["setup"] = MiniTest.new_set()

T["setup"]["sets default values"] = function()
    child.nnp()

    Helpers.expect.state(child, "tabs[1].wins.integrations", {
        ["neo-tree"] = {
            position = "left",
        },
        dap = {
            position = "none",
        },
        nvimtree = {
            position = "left",
        },
        aerial = {
            position = "right",
        },
        dashboard = {
            enabled = false,
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
    })
end

T["setup"]["overrides default values and add new entries"] = function()
    child.lua([[require('no-neck-pain').setup({
         integrations = {
             NvimTree = {
                 position = "right",
             },
             ["neo-tree"] = {
                 position = "right",
             },
             dap = {
                 position = "right",
             },
             undotree = {
                 position = "right",
             },
             neotest = {
             },
             outline = {
                 position = "left",
             },
             aerial = {
                 position = "left",
             },
             dashboard = {
                 enabled = true
             },
             FOOBAR = { 
                 position = "left"
            }
         }
      })]])
    child.cmd("NoNeckPain")
    child.wait()

    Helpers.expect.state(child, "tabs[1].wins.integrations", {
        ["neo-tree"] = {
            position = "right",
        },
        dap = {
            position = "right",
        },
        nvimtree = {
            position = "right",
        },
        neotest = {
            position = "right",
        },
        undotree = {
            position = "right",
        },
        outline = {
            position = "left",
        },
        aerial = {
            position = "left",
        },
        dashboard = {
            enabled = true,
        },
        foobar = {
            position = "left",
        },
    })
end

T["checkhealth"] = MiniTest.new_set()

T["checkhealth"]["state is in sync"] = function()
    child.lua([[ require('no-neck-pain').setup({width=20}) ]])
    child.nnp()
    child.wait()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })

    child.cmd("checkhealth")
    child.wait()

    if child.fn.has("nvim-0.10") == 0 then
        Helpers.expect.equality(child.get_wins_in_tab(), { 1004 })

        child.nnp()
        child.wait()

        Helpers.expect.equality(child.get_wins_in_tab(), { 1005, 1004, 1006 })
        Helpers.expect.state(child, "tabs[2].wins.main", {
            curr = 1004,
            left = 1005,
            right = 1006,
        })
    else
        Helpers.expect.equality(child.get_wins_in_tab(), { 1003 })

        child.nnp()
        child.wait()

        Helpers.expect.equality(child.get_wins_in_tab(), { 1004, 1003, 1005 })
        Helpers.expect.state(child, "tabs[2].wins.main", {
            curr = 1003,
            left = 1004,
            right = 1005,
        })
    end

    child.cmd("q")
    child.wait()

    Helpers.expect.state(child, "tabs[2]", vim.NIL)

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })
end

T["checkhealth"]["auto opens side buffers"] = function()
    child.restart({ "-u", "scripts/init_auto_open.lua" })
    child.wait()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })

    child.cmd("checkhealth")
    child.wait()

    if child.fn.has("nvim-0.10") == 0 then
        Helpers.expect.equality(child.get_wins_in_tab(), { 1005, 1004, 1006 })
        Helpers.expect.state(child, "tabs[2].wins.main", {
            curr = 1004,
            left = 1005,
            right = 1006,
        })
    else
        Helpers.expect.equality(child.get_wins_in_tab(), { 1004, 1003, 1005 })
        Helpers.expect.state(child, "tabs[2].wins.main", {
            curr = 1003,
            left = 1004,
            right = 1005,
        })
    end

    child.cmd("q")
    child.wait()

    Helpers.expect.state(child, "tabs[2]", vim.NIL)

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })
end

T["nvimdapui"] = MiniTest.new_set()

T["nvimdapui"]["keeps sides open"] = function()
    child.restart({ "-u", "scripts/init_with_nvimdapui.lua" })

    child.nnp()
    child.wait()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })

    child.lua([[require('dapui').open()]])
    child.wait()

    Helpers.expect.equality(
        child.get_wins_in_tab(),
        { 1001, 1010, 1009, 1008, 1007, 1000, 1006, 1003, 1002 }
    )

    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })

    Helpers.expect.state(child, "tabs[1].wins.columns", 5)
end

T["neotest"] = MiniTest.new_set()

T["neotest"]["keeps sides open"] = function()
    child.restart({ "-u", "scripts/init_with_neotest.lua", "lua/no-neck-pain/main.lua" })

    child.nnp()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })

    child.lua([[require('neotest').summary.open()]])

    Helpers.expect.state(child, "tabs[1].wins.columns", 4)

    Helpers.expect.state(child, "tabs[1].wins.integrations.neotest", {
        id = 1003,
        position = "right",
    })
end

T["outline"] = MiniTest.new_set()

T["outline"]["keeps sides open"] = function()
    child.restart({ "-u", "scripts/init_with_outline.lua", "lua/no-neck-pain/main.lua" })

    child.nnp()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })

    child.cmd("Outline")
    child.wait()

    Helpers.expect.state(child, "tabs[1].wins.columns", 4)

    Helpers.expect.state(child, "tabs[1].wins.integrations.outline", {
        id = 1004,
        position = "right",
    })
end

T["NvimTree"] = MiniTest.new_set()

T["NvimTree"]["keeps sides open"] = function()
    child.restart({ "-u", "scripts/init_with_nvimtree.lua", "foo" })

    child.nnp()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })

    Helpers.expect.state(child, "enabled", true)
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })

    child.cmd([[NvimTreeOpen]])

    Helpers.expect.equality(child.get_wins_in_tab(), { 1004, 1001, 1000, 1002 })

    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })

    Helpers.expect.state(child, "tabs[1].wins.columns", 4)

    Helpers.expect.state(child, "tabs[1].wins.integrations.nvimtree", {
        id = 1004,
        position = "left",
    })
end

T["neo-tree"] = MiniTest.new_set()

T["neo-tree"]["keeps sides open"] = function()
    child.restart({ "-u", "scripts/init_with_neotree.lua", "foo" })

    child.nnp()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })

    Helpers.expect.state(child, "enabled", true)
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })

    child.cmd([[Neotree reveal]])
    child.wait()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1004, 1000, 1002 })

    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })

    Helpers.expect.state(child, "tabs[1].wins.columns", 4)

    Helpers.expect.state(child, "tabs[1].wins.integrations", {
        aerial = {
            position = "right",
        },
        dap = {
            position = "none",
        },
        dashboard = {
            enabled = false,
        },
        ["neo-tree"] = {
            id = 1004,
            position = "left",
        },
        neotest = {
            position = "right",
        },
        nvimtree = {
            position = "left",
        },
        outline = {
            position = "right",
        },
        undotree = {
            position = "left",
        },
    })

    child.nnp()
    child.nnp()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1005, 1004, 1000, 1006 })

    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1005,
        right = 1006,
    })

    Helpers.expect.state(child, "tabs[1].wins.columns", 4)

    Helpers.expect.state(child, "tabs[1].wins.integrations", {
        aerial = {
            position = "right",
        },
        dap = {
            position = "none",
        },
        dashboard = {
            enabled = false,
        },
        ["neo-tree"] = {
            id = 1004,
            position = "left",
        },
        neotest = {
            position = "right",
        },
        nvimtree = {
            position = "left",
        },
        outline = {
            position = "right",
        },
        undotree = {
            position = "left",
        },
    })
end

T["neo-tree"]["properly enables nnp with tree already opened"] = function()
    child.restart({ "-u", "scripts/init_with_neotree.lua", "." })

    Helpers.expect.equality(child.get_wins_in_tab(1), { 1002, 1000 })

    child.cmd("e Makefile")

    child.nnp()

    if child.fn.has("nvim-0.10") == 0 then
        Helpers.expect.equality(child.get_wins_in_tab(), { 1003, 1002, 1000, 1004 })
    else
        Helpers.expect.equality(child.get_wins_in_tab(), { 1004, 1002, 1000, 1005 })
    end

    Helpers.expect.state(child, "enabled", true)

    Helpers.expect.state(child, "tabs[1].wins.integrations", {
        aerial = {
            position = "right",
        },
        dap = {
            position = "none",
        },
        dashboard = {
            enabled = false,
        },
        ["neo-tree"] = {
            id = 1002,
            position = "left",
        },
        neotest = {
            position = "right",
        },
        nvimtree = {
            position = "left",
        },
        outline = {
            position = "right",
        },
        undotree = {
            position = "left",
        },
    })

    if child.fn.has("nvim-0.10") == 0 then
        Helpers.expect.state(child, "tabs[1].wins.main", {
            curr = 1000,
            left = 1003,
            right = 1004,
        })
    else
        Helpers.expect.state(child, "tabs[1].wins.main", {
            curr = 1000,
            left = 1004,
            right = 1005,
        })
    end
end

T["aerial"] = MiniTest.new_set()

T["aerial"]["keeps sides open"] = function()
    if child.fn.has("nvim-0.11") == 0 then
        MiniTest.skip("aerial doesn't support version below 11")

        return
    end

    child.restart({ "-u", "scripts/init_with_aerial.lua" })

    child.nnp()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })

    Helpers.expect.state(child, "enabled", true)
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })

    child.cmd("AerialToggle")
    child.wait()

    Helpers.expect.state(child, "tabs[1].wins.columns", 4)

    Helpers.expect.equality(child.lua_get("vim.api.nvim_win_get_width(1004)"), 14)
    Helpers.expect.state(child, "tabs[1].wins.integrations.aerial.id", 1004)

    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })

    child.cmd("AerialToggle")
    child.wait()

    Helpers.expect.state(child, "tabs[1].wins.integrations.aerial", {
        position = "right",
    })
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })
end

return T
