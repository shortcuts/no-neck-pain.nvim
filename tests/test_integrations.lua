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
    child.set_size(20, 100)

    Helpers.toggle(child)

    Helpers.expect.equality(Helpers.winsInTab(child), { 1001, 1000, 1002 })
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })

    child.lua([[require('dapui').open()]])
    vim.loop.sleep(50)

    Helpers.expect.equality(
        Helpers.winsInTab(child),
        { 1010, 1009, 1008, 1007, 1001, 1000, 1002, 1006, 1003 }
    )

    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })

    Helpers.expect.state(child, "tabs[1].wins.vsplits", 5)

    Helpers.expect.state(child, "tabs[1].wins.integrations.NvimDAPUI", {
        close = "lua require('dapui').close()",
        fileTypePattern = "dap",
        id = 1003,
        open = "lua require('dapui').open()",
        width = 58,
    })
end

T["neotest"] = MiniTest.new_set()

T["neotest"]["keeps sides open"] = function()
    child.restart({ "-u", "scripts/init_with_neotest.lua", "lua/no-neck-pain/main.lua" })
    child.set_size(20, 100)

    Helpers.toggle(child)

    Helpers.expect.equality(Helpers.winsInTab(child), { 1001, 1000, 1002 })
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })

    child.lua([[require('neotest').summary.open()]])
    vim.loop.sleep(50)

    Helpers.expect.state(child, "tabs[1].wins.vsplits", 3)

    Helpers.expect.state(child, "tabs[1].wins.integrations.neotest", {
        close = "lua require('neotest').summary.close()",
        fileTypePattern = "neotest",
        id = 1003,
        open = "lua require('neotest').summary.open()",
        width = 100,
    })
end

T["outline"] = MiniTest.new_set()

T["outline"]["keeps sides open"] = function()
    child.restart({ "-u", "scripts/init_with_outline.lua", "lua/no-neck-pain/main.lua" })
    child.set_size(20, 100)

    Helpers.toggle(child)

    Helpers.expect.equality(Helpers.winsInTab(child), { 1001, 1000, 1002 })
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })

    child.cmd("Outline")
    vim.loop.sleep(50)

    Helpers.expect.state(child, "tabs[1].wins.vsplits", 4)

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
    child.loop.sleep(50)

    Helpers.expect.equality(Helpers.winsInTab(child), { 1004, 1001, 1000, 1002 })

    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })

    Helpers.expect.state(child, "tabs[1].wins.vsplits", 4)

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
    child.set_size(5, 300)

    Helpers.toggle(child)

    Helpers.expect.equality(Helpers.winsInTab(child), { 1001, 1000, 1002 })

    Helpers.expect.state(child, "enabled", true)
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })

    child.cmd([[Neotree reveal]])
    child.loop.sleep(50)

    Helpers.expect.equality(Helpers.winsInTab(child), { 1004, 1001, 1000, 1002 })

    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })

    Helpers.expect.state(child, "tabs[1].wins.vsplits", 4)

    Helpers.expect.state(child, "tabs[1].wins.integrations.NeoTree", {
        close = "Neotree close",
        fileTypePattern = "neo-tree",
        id = 1004,
        open = "Neotree reveal",
        width = 2,
    })
end

T["TSPlayground"] = MiniTest.new_set()

T["TSPlayground"]["keeps sides open"] = function()
    child.restart({ "-u", "scripts/init_with_tsplayground.lua" })
    child.set_size(5, 300)

    Helpers.toggle(child)

    Helpers.expect.equality(Helpers.winsInTab(child), { 1001, 1000, 1002 })

    Helpers.expect.state(child, "enabled", true)
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })

    child.cmd("TSPlaygroundToggle")
    vim.loop.sleep(50)

    Helpers.expect.state(child, "tabs[1].wins.vsplits", 3)

    Helpers.expect.equality(child.lua_get("vim.api.nvim_win_get_width(1004)"), 159)
    Helpers.expect.state(child, "tabs[1].wins.integrations.TSPlayground", {
        close = "TSPlaygroundToggle",
        fileTypePattern = "tsplayground",
        id = 1004,
        open = "TSPlaygroundToggle",
        width = 318,
    })

    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
    })

    child.cmd("TSPlaygroundToggle")
    vim.loop.sleep(50)

    Helpers.expect.state(child, "tabs[1].wins.integrations.TSPlayground", {
        close = "TSPlaygroundToggle",
        fileTypePattern = "tsplayground",
        open = "TSPlaygroundToggle",
    })
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1005,
    })
end

T["TSPlayground"]["reduces `left` side if only active when integration is on `right`"] = function()
    child.restart({ "-u", "scripts/init_with_tsplayground.lua" })
    child.set_size(5, 300)

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

    Helpers.expect.equality(Helpers.winsInTab(child), { 1001, 1000 })

    Helpers.expect.state(child, "enabled", true)
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = nil,
    })
    Helpers.expect.buf_width(child, "tabs[1].wins.main.left", 30)

    child.cmd("TSPlaygroundToggle")
    vim.loop.sleep(50)

    Helpers.expect.state(child, "tabs[1].wins.vsplits", 3)

    Helpers.expect.equality(child.lua_get("vim.api.nvim_win_get_width(1003)"), 144)
    Helpers.expect.buf_width(child, "tabs[1].wins.main.left", 20)
    Helpers.expect.state(child, "tabs[1].wins.integrations.TSPlayground", {
        close = "TSPlaygroundToggle",
        fileTypePattern = "tsplayground",
        id = 1003,
        open = "TSPlaygroundToggle",
        width = 288,
    })
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = nil,
    })

    child.cmd("TSPlaygroundToggle")
    vim.loop.sleep(50)

    Helpers.expect.state(child, "tabs[1].wins.vsplits", 2)

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
    if child.fn.has("nvim-0.8") == 0 then
        MiniTest.skip("aerial doesn't support version below 8")

        return
    end

    child.restart({ "-u", "scripts/init_with_aerial.lua" })
    child.set_size(5, 500)

    Helpers.toggle(child)

    Helpers.expect.equality(Helpers.winsInTab(child), { 1001, 1000, 1002 })

    Helpers.expect.state(child, "enabled", true)
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })

    child.cmd("AerialToggle")

    Helpers.expect.state(child, "tabs[1].wins.vsplits", 4)

    Helpers.expect.equality(child.lua_get("vim.api.nvim_win_get_width(1004)"), 25)
    Helpers.expect.state(child, "tabs[1].wins.integrations.aerial.id", 1004)

    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })

    child.cmd("AerialToggle")
    vim.loop.sleep(50)

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
