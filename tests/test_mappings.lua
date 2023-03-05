local helpers = dofile("tests/helpers.lua")

local child = helpers.new_child_neovim()
local eq, eq_global, eq_config =
    helpers.expect.equality, helpers.expect.global_equality, helpers.expect.config_equality

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
        mappings = {
            enabled = true,
            toggle = "<Leader>kz",
            widthUp = "<Leader>k-",
            widthDown = "<Leader>k=",
        }
    })]])

    eq_config(child, "mappings.enabled", true)
    eq_config(child, "mappings.toggle", "<Leader>kz")
    eq_config(child, "mappings.widthUp", "<Leader>k-")
    eq_config(child, "mappings.widthDown", "<Leader>k=")
end

T["setup"]["increase the width with mapping"] = function()
    child.lua([[
        require('no-neck-pain').setup({width=50,mappings={enabled=true,widthUp="nn"}})
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
        require('no-neck-pain').setup({width=50,mappings={enabled=true,widthDown="nn"}})
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
