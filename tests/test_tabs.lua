local Co = require("no-neck-pain.util.constants")
local helpers = dofile("tests/helpers.lua")

local child = helpers.new_child_neovim()
local eq, eq_state = helpers.expect.equality, helpers.expect.state_equality

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
    child.lua([[
        require('no-neck-pain').setup({width=50})
        require('no-neck-pain').enable()
    ]])

    eq_state(child, "activeTab", 1)

    child.cmd("tabnew")

    eq_state(child, "activeTab", 2)
end

T["tabs"]["new tab doesn't have side buffers"] = function()
    child.lua([[
        require('no-neck-pain').setup({width=50})
        require('no-neck-pain').enable()
    ]])

    eq(helpers.winsInTab(child), { 1001, 1000, 1002 })
    eq_state(child, "activeTab", 1)

    child.cmd("tabnew")

    eq(helpers.winsInTab(child), { 1003 })
end

T["tabs"]["side buffers coexist on many tabs"] = function()
    child.lua([[
        require('no-neck-pain').setup({width=50})
        require('no-neck-pain').enable()
    ]])

    -- tab 1
    eq(helpers.winsInTab(child), { 1001, 1000, 1002 })
    eq_state(child, "activeTab", 1)

    -- tab 2
    child.cmd("tabnew")
    child.lua([[ require('no-neck-pain').enable() ]])

    eq(helpers.winsInTab(child), { 1004, 1003, 1005 })
    eq_state(child, "activeTab", 2)

    -- tab 3
    child.cmd("tabnew")
    child.lua([[ require('no-neck-pain').enable() ]])

    eq(helpers.winsInTab(child), { 1007, 1006, 1008 })
    eq_state(child, "activeTab", 3)

    eq(helpers.winsInTab(child, 1), { 1001, 1000, 1002 })
    eq(helpers.winsInTab(child, 2), { 1004, 1003, 1005 })
    eq(helpers.winsInTab(child, 3), { 1007, 1006, 1008 })
end

T["tabs"]["previous tab kept side buffers if enabled"] = function()
    child.lua([[
        require('no-neck-pain').setup({width=50})
        require('no-neck-pain').enable()
    ]])

    -- tab 1
    eq(helpers.winsInTab(child), { 1001, 1000, 1002 })
    eq_state(child, "activeTab", 1)

    -- tab 2
    child.cmd("tabnew")

    eq(helpers.winsInTab(child), { 1003 })

    -- tab 1
    child.cmd("tabprevious")

    eq(helpers.winsInTab(child), { 1001, 1000, 1002 })
    eq_state(child, "activeTab", 1)
end

T["TabNewEntered"] = MiniTest.new_set()

T["TabNewEntered"]["starts the plugin on new tab"] = function()
    child.restart({ "-u", "scripts/init_auto_open.lua" })

    eq_state(child, "enabled", true)

    -- tab 1
    eq(helpers.winsInTab(child), { 1001, 1000, 1002 })

    eq_state(child, "activeTab", 1)

    -- tab 2
    child.cmd("tabnew")
    eq_state(child, "activeTab", 2)

    eq(helpers.winsInTab(child), { 1004, 1003, 1005 })

    child.stop()
end

T["TabNewEntered"]["does not re-enable if the user disables it"] = function()
    child.restart({ "-u", "scripts/init_auto_open.lua" })

    eq_state(child, "enabled", true)

    -- tab 1
    eq(helpers.winsInTab(child), { 1001, 1000, 1002 })

    eq_state(child, "activeTab", 1)

    -- tab 2
    child.cmd("tabnew")
    eq_state(child, "activeTab", 2)

    eq(helpers.winsInTab(child), { 1004, 1003, 1005 })

    child.cmd("NoNeckPain")

    eq(helpers.winsInTab(child), { 1003 })
    eq_state(child, "activeTab", 2)

    -- tab 1
    child.cmd("tabprevious")
    eq_state(child, "activeTab", 1)

    -- tab 2
    child.cmd("tabnext")
    eq_state(child, "activeTab", 2)

    eq(helpers.winsInTab(child), { 1003 })

    child.stop()
end

T["tabnew/tabclose"] = MiniTest.new_set()

T["tabnew/tabclose"]["opening and closing tabs does not throw any error"] = function()
    child.restart({ "-u", "scripts/init_auto_open.lua" })

    eq_state(child, "enabled", true)
    eq_state(child, "activeTab", 1)

    child.cmd("tabnew")
    eq_state(child, "activeTab", 2)

    child.cmd("tabclose")
    eq_state(child, "activeTab", 1)

    child.cmd("tabnew")
    child.cmd("tabnew")
    eq_state(child, "activeTab", 4)

    child.cmd("tabclose")
    eq_state(child, "activeTab", 3)

    child.cmd("tabclose")
    eq_state(child, "activeTab", 1)
end

T["tabnew/tabclose"]["doesn't keep closed tabs in state"] = function()
    child.restart({ "-u", "scripts/init_auto_open.lua" })

    eq_state(child, "enabled", true)
    eq_state(child, "activeTab", 1)
    eq_state(child, "tabs", {
        {
            id = 1,
            layers = {
                split = 1,
                vsplit = 1,
            },
            scratchPadEnabled = false,
            wins = {
                integrations = Co.integrations,
                main = {
                    curr = 1000,
                    left = 1001,
                    right = 1002,
                },
            },
        },
    })

    child.cmd("tabnew")
    eq_state(child, "tabs", {
        {
            id = 1,
            layers = {
                split = 1,
                vsplit = 1,
            },
            scratchPadEnabled = false,
            wins = {
                integrations = Co.integrations,
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
                integrations = Co.integrations,
                main = {
                    curr = 1003,
                    left = 1004,
                    right = 1005,
                },
            },
        },
    })

    child.cmd("tabclose")
    eq_state(child, "tabs", {
        {
            id = 1,
            layers = {
                split = 1,
                vsplit = 1,
            },
            scratchPadEnabled = false,
            wins = {
                integrations = Co.integrations,
                main = {
                    curr = 1000,
                    left = 1001,
                    right = 1002,
                },
            },
        },
    })
end

return T
