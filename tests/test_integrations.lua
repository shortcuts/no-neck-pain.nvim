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
    })
end

T["integrations"] = MiniTest.new_set()

T["integrations"]["NvimTree throws with wrong values"] = function()
    Helpers.expect.error(function()
        child.lua([[ require('no-neck-pain').setup({
                    integrations = {
                        NvimTree = {
                            position = "nope",
                        },
                    },
                })
            ]])
    end)
end

T["integrations"]["NeoTree throws with wrong values"] = function()
    Helpers.expect.error(function()
        child.lua([[ require('no-neck-pain').setup({
                    integrations = {
                        NeoTree = {
                            position = "nope",
                        },
                    },
                })
            ]])
    end)
end

T["nvimdapui"] = MiniTest.new_set()

T["nvimdapui"]["keeps sides open"] = function()
    if child.fn.has("nvim-0.8") == 0 then
        MiniTest.skip("NvimDAPUI doesn't support version below 8")

        return
    end

    child.restart({ "-u", "scripts/init_with_nvimdapui.lua" })

    Helpers.toggle(child)
    child.wait()

    Helpers.expect.equality(Helpers.winsInTab(child), { 1001, 1000, 1002 })
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })

    child.lua([[require('dapui').open()]])
    child.wait()

    Helpers.expect.equality(
        Helpers.winsInTab(child),
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

    Helpers.toggle(child)

    Helpers.expect.equality(Helpers.winsInTab(child), { 1001, 1000, 1002 })
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
        width = 74,
    })
end

T["outline"] = MiniTest.new_set()

T["outline"]["keeps sides open"] = function()
    child.restart({ "-u", "scripts/init_with_outline.lua", "lua/no-neck-pain/main.lua" })

    Helpers.toggle(child)

    Helpers.expect.equality(Helpers.winsInTab(child), { 1001, 1000, 1002 })
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
        width = 40,
    })
end

T["NvimTree"] = MiniTest.new_set()

T["NvimTree"]["keeps sides open"] = function()
    if child.fn.has("nvim-0.9") == 0 then
        MiniTest.skip("NvimTree doesn't support version below 8")

        return
    end

    child.restart({ "-u", "scripts/init_with_nvimtree.lua", "foo" })

    Helpers.toggle(child)

    Helpers.expect.equality(Helpers.winsInTab(child), { 1001, 1000, 1002 })

    Helpers.expect.state(child, "enabled", true)
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })

    child.cmd([[NvimTreeOpen]])

    Helpers.expect.equality(Helpers.winsInTab(child), { 1004, 1001, 1000, 1002 })

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
        width = 38,
    })
end

T["neo-tree"] = MiniTest.new_set()

T["neo-tree"]["keeps sides open"] = function()
    child.restart({ "-u", "scripts/init_with_neotree.lua", "foo" })

    Helpers.toggle(child)

    Helpers.expect.equality(Helpers.winsInTab(child), { 1001, 1000, 1002 })

    Helpers.expect.state(child, "enabled", true)
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })

    child.cmd([[Neotree reveal]])
    child.wait()

    Helpers.expect.equality(Helpers.winsInTab(child), { 1001, 1004, 1000, 1002 })

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
        width = 60,
    })
end

T["TSPlayground"] = MiniTest.new_set()

T["TSPlayground"]["keeps sides open"] = function()
    if child.fn.has("nvim-0.9") == 0 then
        MiniTest.skip("tsplayground doesn't support version below 8")

        return
    end

    child.restart({ "-u", "scripts/init_with_tsplayground.lua" })

    Helpers.toggle(child)

    Helpers.expect.equality(Helpers.winsInTab(child), { 1001, 1000, 1002 })

    Helpers.expect.state(child, "enabled", true)
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })

    child.cmd("TSPlaygroundToggle")
    child.wait()

    Helpers.expect.state(child, "tabs[1].wins.columns", 4)

    Helpers.expect.equality(child.lua_get("vim.api.nvim_win_get_width(1004)"), 19)
    Helpers.expect.state(child, "tabs[1].wins.integrations.TSPlayground", {
        close = "TSPlaygroundToggle",
        fileTypePattern = "tsplayground",
        id = 1004,
        open = "TSPlaygroundToggle",
        width = 38,
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
        MiniTest.skip("tsplayground doesn't support version below 8")

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
    Helpers.toggle(child)
    child.wait()

    Helpers.expect.equality(Helpers.winsInTab(child), { 1001, 1000 })

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

    Helpers.expect.equality(child.lua_get("vim.api.nvim_win_get_width(1003)"), 26)
    Helpers.expect.buf_width(child, "tabs[1].wins.main.left", 26)
    Helpers.expect.state(child, "tabs[1].wins.integrations.TSPlayground", {
        close = "TSPlaygroundToggle",
        fileTypePattern = "tsplayground",
        id = 1003,
        open = "TSPlaygroundToggle",
        width = 52,
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
    Helpers.expect.buf_width(child, "tabs[1].wins.main.left", 40)
end

T["aerial"] = MiniTest.new_set()

T["aerial"]["keeps sides open"] = function()
    if child.fn.has("nvim-0.9") == 0 then
        MiniTest.skip("aerial doesn't support version below 8")

        return
    end

    child.restart({ "-u", "scripts/init_with_aerial.lua" })

    Helpers.toggle(child)

    Helpers.expect.equality(Helpers.winsInTab(child), { 1001, 1000, 1002 })

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
