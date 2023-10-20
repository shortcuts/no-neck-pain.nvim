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
            undotree = {
                position = "right",
            },
            neotest = {
                reopen = false,
            },
        }
    })]])

    eq_config(child, "integrations", {
        NeoTree = {
            position = "right",
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
    child.restart({ "-u", "scripts/init_with_neotest.lua" })
    child.set_size(5, 300)

    child.lua([[require('no-neck-pain').enable()]])

    eq(helpers.winsInTab(child), { 1001, 1000, 1002 })
    eq_state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })

    child.lua([[require('neotest').summary.open()]])

    eq(helpers.winsInTab(child), { 1001, 1000, 1002, 1003 })
    eq_state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })

    eq_state(child, "tabs[1].wins.splits", vim.NIL)

    eq_state(child, "tabs[1].wins.integrations", {
        ["neo-tree"] = {
            close = "Neotree close",
            configName = "NeoTree",
            open = "Neotree reveal",
        },
        neotest = {
            close = "lua require('neotest').summary.close()",
            configName = "neotest",
            id = 1003,
            open = "lua require('neotest').summary.open()",
            width = 100,
        },
        nvimtree = {
            close = "NvimTreeClose",
            configName = "NvimTree",
            open = "NvimTreeOpen",
        },
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

    -- eq(helpers.winsInTab(child), { 1004, 1001, 1000, 1002 })
    --
    eq_state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })

    eq_state(child, "tabs[1].wins.splits", vim.NIL)

    eq_state(child, "tabs[1].wins.integrations", {
        NvimTree = {
            close = "NvimTreeClose",
            configName = "NvimTree",
            id = 1004,
            open = "NvimTreeOpen",
            width = 60,
        },
        ["neo-tree"] = {
            close = "Neotree close",
            configName = "NeoTree",
            open = "Neotree reveal",
        },
        neotest = {
            close = "lua require('neotest').summary.close()",
            configName = "neotest",
            open = "lua require('neotest').summary.open()",
        },
        nvimtree = {
            close = "NvimTreeClose",
            configName = "NvimTree",
            open = "NvimTreeOpen",
        },
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

    eq(helpers.winsInTab(child), { 1004, 1001, 1000, 1002 })

    eq_state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })

    eq_state(child, "tabs[1].wins.splits", vim.NIL)

    eq_state(child, "tabs[1].wins.integrations", {
        NeoTree = {
            close = "Neotree close",
            configName = "NeoTree",
            id = 1004,
            open = "Neotree reveal",
            width = 2,
        },
        ["neo-tree"] = {
            close = "Neotree close",
            configName = "NeoTree",
            open = "Neotree reveal",
        },
        neotest = {
            close = "lua require('neotest').summary.close()",
            configName = "neotest",
            open = "lua require('neotest').summary.open()",
        },
        nvimtree = {
            close = "NvimTreeClose",
            configName = "NvimTree",
            open = "NvimTreeOpen",
        },
    })
end

return T
