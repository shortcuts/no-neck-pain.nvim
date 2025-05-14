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
    child.lua([[require('no-neck-pain').setup()]])

    Helpers.expect.config(child, "integrations", {
        NeoTree = {
            position = "left",
            reopen = true,
        },
        NvimDAPUI = {
            position = "none",
            reopen = true,
        },
        NvimTree = {
            position = "left",
            reopen = true,
        },
        TSPlayground = {
            position = "right",
            reopen = true,
        },
        aerial = {
            position = "right",
            reopen = true,
        },
        dashboard = {
            enabled = false,
        },
        neotest = {
            position = "right",
            reopen = true,
        },
        outline = {
            position = "right",
            reopen = true,
        },
        undotree = {
            position = "left",
        },
    })
end

T["setup"]["overrides default values"] = function()
    child.lua([[require('no-neck-pain').setup({
        integrations = {
            NvimTree = {
                position = "right",
                reopen = false,
            },
            NeoTree = {
                position = "right",
                reopen = false,
            },
            NvimDAPUI = {
                reopen = false,
            },
            undotree = {
                position = "right",
            },
            neotest = {
                reopen = false,
            },
            TSPlayground = {
                reopen = false,
                position = "left",
            },
            outline = {
                reopen = false,
                position = "left",
            },
            aerial = {
                position = "left",
                reopen = false,
            },
            dashboard = {
                enabled = true
            },
        }
    })]])

    Helpers.expect.config(child, "integrations", {
        NeoTree = {
            position = "right",
            reopen = false,
        },
        NvimDAPUI = {
            position = "none",
            reopen = false,
        },
        NvimTree = {
            position = "right",
            reopen = false,
        },
        neotest = {
            position = "right",
            reopen = false,
        },
        undotree = {
            position = "right",
        },
        TSPlayground = {
            position = "left",
            reopen = false,
        },
        outline = {
            position = "left",
            reopen = false,
        },
        aerial = {
            position = "left",
            reopen = false,
        },
        dashboard = {
            enabled = true,
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
        close = "lua require('neotest').summary.close()",
        fileTypePattern = "neotest",
        id = 1003,
        open = "lua require('neotest').summary.open()",
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
        close = "Outline",
        fileTypePattern = "outline",
        id = 1004,
        open = "Outline",
    })
end

T["NvimTree"] = MiniTest.new_set()

T["NvimTree"]["keeps sides open"] = function()
    if child.fn.has("nvim-0.9") == 0 then
        MiniTest.skip("NvimTree doesn't support version below 9")

        return
    end

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

    Helpers.expect.state(child, "tabs[1].wins.integrations.NvimTree", {
        close = "NvimTreeClose",
        fileTypePattern = "nvimtree",
        id = 1004,
        open = "NvimTreeOpen",
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

    Helpers.expect.state(child, "tabs[1].wins.integrations.NeoTree", {
        close = "Neotree close",
        fileTypePattern = "neo-tree",
        id = 1004,
        open = "Neotree reveal",
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

    Helpers.expect.state(child, "tabs[1].wins.integrations.NeoTree", {
        close = "Neotree close",
        fileTypePattern = "neo-tree",
        id = 1004,
        open = "Neotree reveal",
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

    Helpers.expect.state(child, "tabs[1].wins.integrations.NeoTree", {
        close = "Neotree close",
        fileTypePattern = "neo-tree",
        id = 1002,
        open = "Neotree reveal",
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

T["TSPlayground"] = MiniTest.new_set()

T["TSPlayground"]["keeps sides open"] = function()
    if child.fn.has("nvim-0.9") == 0 then
        MiniTest.skip("tsplayground doesn't support version below 9")

        return
    end

    child.restart({ "-u", "scripts/init_with_tsplayground.lua" })

    child.nnp()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })

    Helpers.expect.state(child, "enabled", true)
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })

    child.cmd("TSPlaygroundToggle")
    child.wait()

    Helpers.expect.state(child, "tabs[1].wins.columns", 4)

    Helpers.expect.min(child.lua_get("vim.api.nvim_win_get_width(1004)"), 18)
    Helpers.expect.max(child.lua_get("vim.api.nvim_win_get_width(1004)"), 19)
    Helpers.expect.state(child, "tabs[1].wins.integrations.TSPlayground", {
        close = "TSPlaygroundToggle",
        fileTypePattern = "tsplayground",
        id = 1004,
        open = "TSPlaygroundToggle",
    })

    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })

    child.cmd("TSPlaygroundToggle")

    Helpers.expect.state(child, "tabs[1].wins.integrations.TSPlayground", {
        close = "TSPlaygroundToggle",
        fileTypePattern = "tsplayground",
        open = "TSPlaygroundToggle",
    })
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })
end

T["TSPlayground"]["reduces `left` side if only active when integration is on `right`"] = function()
    if child.fn.has("nvim-0.9") == 0 then
        MiniTest.skip("tsplayground doesn't support version below 9")

        return
    end

    child.restart({ "-u", "scripts/init_with_tsplayground.lua" })

    child.lua([[
        require('no-neck-pain').setup({
            width = 20,
            buffers = {
                right = {
                    enabled = false,
                },
            },
        })
    ]])
    child.nnp()
    child.wait()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000 })

    Helpers.expect.state(child, "enabled", true)
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = nil,
    })
    Helpers.expect.buf_width(child, "tabs[1].wins.main.left", 30)
    Helpers.expect.state(child, "tabs[1].wins.columns", 2)

    child.cmd("TSPlaygroundToggle")
    child.wait()

    Helpers.expect.state(child, "tabs[1].wins.columns", 3)

    Helpers.expect.equality(child.lua_get("vim.api.nvim_win_get_width(1003)"), 28)
    Helpers.expect.buf_width(child, "tabs[1].wins.main.left", 30)
    Helpers.expect.state(child, "tabs[1].wins.integrations.TSPlayground", {
        close = "TSPlaygroundToggle",
        fileTypePattern = "tsplayground",
        id = 1003,
        open = "TSPlaygroundToggle",
    })
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = nil,
    })

    child.cmd("TSPlaygroundToggle")
    child.wait()

    Helpers.expect.state(child, "tabs[1].wins.columns", 2)

    Helpers.expect.state(child, "tabs[1].wins.integrations.TSPlayground", {
        close = "TSPlaygroundToggle",
        fileTypePattern = "tsplayground",
        open = "TSPlaygroundToggle",
    })
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = nil,
    })
    Helpers.expect.buf_width(child, "tabs[1].wins.main.left", 30)
end

T["aerial"] = MiniTest.new_set()

T["aerial"]["keeps sides open"] = function()
    if child.fn.has("nvim-0.9") == 0 then
        MiniTest.skip("aerial doesn't support version below 8")

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
        close = "AerialToggle",
        fileTypePattern = "aerial",
        open = "AerialToggle",
    })
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })
end

return T
