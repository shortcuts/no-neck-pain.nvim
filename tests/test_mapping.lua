local Co = require("no-neck-pain.util.constants")
local helpers = dofile("tests/helpers.lua")

local child = helpers.new_child_neovim()
local eq, eq_global, eq_config, eq_state =
    helpers.expect.equality,
    helpers.expect.global_equality,
    helpers.expect.config_equality,
    helpers.expect.state_equality
local eq_type_global, eq_type_config, eq_type_state =
    helpers.expect.global_type_equality,
    helpers.expect.config_type_equality,
    helpers.expect.state_type_equality

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
        toggleMapping = "<Leader>kz",
        widthUpMapping = "<Leader>k-",
        widthDownMapping = "<Leader>k=",
    })]])

    eq_config(child, "toggleMapping", "<Leader>kz")
    eq_config(child, "widthUpMapping", "<Leader>k-")
    eq_config(child, "widthDownMapping", "<Leader>k=")
end

T["setup"]["increase the width with mapping"] = function()
    child.lua([[
        require('no-neck-pain').setup({width=50,widthUpMapping="nn"})
        require('no-neck-pain').enable()
    ]])

    eq_global(child, "_G.NoNeckPain.config.width", 50)
    eq(
        child.lua_get("vim.api.nvim_tabpage_list_wins(_G.NoNeckPain.state.activeTab)"),
        { 1001, 1000, 1002 }
    )

    child.lua("vim.api.nvim_input('nn')")
    child.lua("vim.api.nvim_input('nn')")
    child.lua("vim.api.nvim_input('nn')")
    child.lua("vim.api.nvim_input('nn')")

    eq_global(child, "_G.NoNeckPain.config.width", 70)
end

T["setup"]["decrease the width with mapping"] = function()
    child.lua([[
        require('no-neck-pain').setup({width=50,widthDownMapping="nn"})
        require('no-neck-pain').enable()
    ]])

    eq_global(child, "_G.NoNeckPain.config.width", 50)
    eq(
        child.lua_get("vim.api.nvim_tabpage_list_wins(_G.NoNeckPain.state.activeTab)"),
        { 1001, 1000, 1002 }
    )

    child.lua("vim.api.nvim_input('nn')")
    child.lua("vim.api.nvim_input('nn')")
    child.lua("vim.api.nvim_input('nn')")
    child.lua("vim.api.nvim_input('nn')")

    eq_global(child, "_G.NoNeckPain.config.width", 30)
end

return T
