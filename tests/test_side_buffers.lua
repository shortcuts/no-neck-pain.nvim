local helpers = dofile("tests/helpers.lua")

local child = helpers.new_child_neovim()
local eq = helpers.expect.equality
local eq, eq_state = eq, helpers.expect.state_equality
local eq_type_global, eq_type_state =
    helpers.expect.global_type_equality, helpers.expect.state_type_equality

local new_set = MiniTest.new_set

local T = new_set({
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

T["side buffers"] = new_set()

T["side buffers"]["have the same width"] = function()
    child.lua([[require('no-neck-pain').enable()]])

    eq(
        child.lua_get("vim.api.nvim_win_get_width(_G.NoNeckPain.state.win.right)"),
        child.lua_get("vim.api.nvim_win_get_width(_G.NoNeckPain.state.win.left)")
    )
end

T["curr buffer"] = new_set()

T["curr buffer"]["have the default width from the config"] = function()
    child.lua([[
        require('no-neck-pain').setup({width=50})
        require('no-neck-pain').enable()
    ]])

    eq(child.lua_get("vim.api.nvim_win_get_width(_G.NoNeckPain.state.win.curr)"), 48)
end

T["auto command"] = new_set()

T["auto command"]["hides side buffers after split"] = function()
    child.lua([[require('no-neck-pain').enable()]])

    -- At start 1 win automatically sorrounded with side buffers
    eq(child.lua_get("vim.api.nvim_list_wins()"), { 1001, 1000, 1002 })
    eq_state(child, "win.left", 1001)
    eq_state(child, "win.right", 1002)

    -- Opening split hides side buffers
    child.cmd("split")
    eq(child.lua_get("vim.api.nvim_list_wins()"), { 1003, 1000 })
    eq_state(child, "win.left", vim.NIL)
    eq_state(child, "win.right", vim.NIL)

    -- Closing split and returning to last window opens side buffers again
    child.cmd("close")
    eq(child.lua_get("vim.api.nvim_list_wins()"), { 1004, 1000, 1005 })
    eq_state(child, "win.left", 1004)
    eq_state(child, "win.right", 1005)
end

T["auto command"]["hides side buffers after vsplit"] = function()
    child.lua([[require('no-neck-pain').enable()]])

    -- At start 1 win automatically sorrounded with side buffers
    eq(child.lua_get("vim.api.nvim_list_wins()"), { 1001, 1000, 1002 })
    eq_state(child, "win.left", 1001)
    eq_state(child, "win.right", 1002)

    -- Opening vsplit hides side buffers
    child.cmd("vsplit")
    eq(child.lua_get("vim.api.nvim_list_wins()"), { 1003, 1000 })
    eq_state(child, "win.left", vim.NIL)
    eq_state(child, "win.right", vim.NIL)

    -- Closing vsplit and returning to last window opens side buffers again
    child.cmd("close")
    eq(child.lua_get("vim.api.nvim_list_wins()"), { 1004, 1000, 1005 })
    eq_state(child, "win.left", 1004)
    eq_state(child, "win.right", 1005)
end

return T
