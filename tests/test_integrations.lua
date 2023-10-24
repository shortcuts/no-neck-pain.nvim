local helpers = dofile("tests/helpers.lua")

local child = helpers.new_child_neovim()
local eq, eq_config, eq_state =
    helpers.expect.equality, helpers.expect.config_equality, helpers.expect.state_equality

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
        }
    })]])

    eq_config(child, "integrations", {
        NeoTree = {
            position = "right",
            reopen = false,
        },
        NvimDAPUI = {
            position = "none",
            reopen = false
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
    })
end

T["integrations"] = MiniTest.new_set()

T["integrations"]["NvimTree throws with wrong values"] = function()
    helpers.expect.error(function()
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
    helpers.expect.error(function()
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

T["neotest"] = MiniTest.new_set()

T["neotest"]["keeps sides open"] = function()
    child.restart({ "-u", "scripts/init_with_neotest.lua", "lua/no-neck-pain/main.lua" })
    child.set_size(20, 100)

    child.lua([[require('no-neck-pain').enable()]])

    eq(helpers.winsInTab(child), { 1001, 1000, 1002 })
    eq_state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })

    child.lua([[require('neotest').summary.open()]])
    vim.loop.sleep(50)

    eq_state(child, "tabs[1].wins.splits", vim.NIL)

    eq_state(child, "tabs[1].wins.integrations.neotest", {
        close = "lua require('neotest').summary.close()",
        fileTypePattern = "neotest",
        id = 1003,
        open = "lua require('neotest').summary.open()",
        width = 100,
    })
end

T["NvimTree"] = MiniTest.new_set()

T["NvimTree"]["keeps sides open"] = function()
    if child.fn.has("nvim-0.8") == 0 then
        MiniTest.skip("NvimTree doesn't support version below 8")

        return
    end

    child.restart({ "-u", "scripts/init_with_nvimtree.lua", "foo" })
    child.set_size(5, 300)

    child.cmd([[NoNeckPain]])

    eq(helpers.winsInTab(child), { 1001, 1000, 1002 })

    eq_state(child, "enabled", true)
    eq_state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })

    child.cmd([[NvimTreeOpen]])
    child.loop.sleep(50)

    eq(helpers.winsInTab(child), { 1004, 1001, 1000, 1002 })

    eq_state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })

    eq_state(child, "tabs[1].wins.splits", vim.NIL)

    eq_state(child, "tabs[1].wins.integrations.NvimTree", {
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

    child.cmd([[NoNeckPain]])

    eq(helpers.winsInTab(child), { 1001, 1000, 1002 })

    eq_state(child, "enabled", true)
    eq_state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })

    child.cmd([[Neotree reveal]])
    child.loop.sleep(50)

    eq(helpers.winsInTab(child), { 1004, 1001, 1000, 1002 })

    eq_state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })

    eq_state(child, "tabs[1].wins.splits", vim.NIL)

    eq_state(child, "tabs[1].wins.integrations.NeoTree", {
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

    child.cmd([[NoNeckPain]])

    eq(helpers.winsInTab(child), { 1001, 1000, 1002 })

    eq_state(child, "enabled", true)
    eq_state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })

    child.cmd("TSPlaygroundToggle")
    vim.loop.sleep(50)

    eq_state(child, "tabs[1].wins.splits", vim.NIL)

    eq_state(child, "tabs[1].wins.integrations.TSPlayground", {
        close = "TSPlaygroundToggle",
        fileTypePattern = "tsplayground",
        id = 1004,
        open = "TSPlaygroundToggle",
        width = 248,
    })
end

return T
