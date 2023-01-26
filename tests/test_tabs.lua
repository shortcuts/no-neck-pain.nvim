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

T["tabs"]["keeps track of the current tab page"] = function()
    child.lua([[
        require('no-neck-pain').setup({width=50})
        require('no-neck-pain').enable()
    ]])

    eq_state(child, "tabs", 1)

    child.cmd("tabnew")

    eq_state(child, "tabs", 2)
end

T["tabs"]["tabnew closes side buffers"] = function()
    child.lua([[
        require('no-neck-pain').setup({width=50})
        require('no-neck-pain').enable()
    ]])

    eq(
        child.lua_get("vim.api.nvim_tabpage_list_wins(_G.NoNeckPain.state.tabs)"),
        { 1001, 1000, 1002 }
    )
    eq_state(child, "tabs", 1)

    child.cmd("tabnew")

    eq(child.lua_get("vim.api.nvim_tabpage_list_wins(_G.NoNeckPain.state.tabs)"), { 1003 })
    eq_state(child, "tabs", 2)
end

T["tabs"]["previous tab kept side buffers if enabled"] = function()
    child.lua([[
        require('no-neck-pain').setup({width=50})
        require('no-neck-pain').enable()
    ]])

    eq(
        child.lua_get("vim.api.nvim_tabpage_list_wins(_G.NoNeckPain.state.tabs)"),
        { 1001, 1000, 1002 }
    )
    eq_state(child, "tabs", 1)

    child.cmd("tabnew")

    eq(child.lua_get("vim.api.nvim_tabpage_list_wins(_G.NoNeckPain.state.tabs)"), { 1003 })
    eq_state(child, "tabs", 2)

    child.cmd("tabprevious")

    eq(
        child.lua_get("vim.api.nvim_tabpage_list_wins(_G.NoNeckPain.state.tabs)"),
        { 1001, 1000, 1002 }
    )
    eq_state(child, "tabs", 1)
end

return T
