local helpers = dofile("tests/helpers.lua")

local child = helpers.new_child_neovim()
local _, eq = helpers.expect, helpers.expect.equality
local new_set, _ = MiniTest.new_set, MiniTest.finally

local T = new_set({
    hooks = {
        -- This will be executed before every (even nested) case
        pre_case = function()
            -- Restart child process with custom 'init.lua' script
            child.restart({ "-u", "scripts/minimal_init.lua" })
            -- Load tested plugin
            child.lua([[M = require('no-neck-pain')]])
        end,
        -- This will be executed one after all tests from this set are finished
        post_once = child.stop,
    },
})

T["side buffers"] = new_set()

T["side buffers"]["have the same width"] = function()
    child.lua([[
        M = require('no-neck-pain').enable()
    ]])

    eq(
        child.lua_get("vim.api.nvim_win_get_width(_G.NoNeckPain.state.win.right)"),
        child.lua_get("vim.api.nvim_win_get_width(_G.NoNeckPain.state.win.left)")
    )
end

T["curr buffer"] = new_set()

T["curr buffer"]["have the default width from the config"] = function()
    child.lua([[
        M = require('no-neck-pain').setup({width=50})
        M = require('no-neck-pain').enable()
    ]])

    eq(child.lua_get("vim.api.nvim_win_get_width(_G.NoNeckPain.state.win.curr)"), 48)
end

T["auto command"] = new_set()

T["auto command"]["hides side buffers after split"] = function()
    child.lua([[
        M = require('no-neck-pain').enable()
    ]])

    local expect_state = function(field, value)
        eq(child.lua_get("_G.NoNeckPain.state." .. field), value)
    end

    -- At start 1 win automatically sorrounded with side buffers
    eq(child.lua_get("vim.api.nvim_list_wins()"), { 1001, 1000, 1002 })
    expect_state("win.left", 1001)
    expect_state("win.right", 1002)

    -- Opening split hides side buffers
    child.cmd("split")
    eq(child.lua_get("vim.api.nvim_list_wins()"), { 1003, 1000 })
    expect_state("win.left", vim.NIL)
    expect_state("win.right", vim.NIL)

    -- Closing split and returning to last window opens side buffers again
    child.cmd("close")
    eq(child.lua_get("vim.api.nvim_list_wins()"), { 1004, 1000, 1005 })
    expect_state("win.left", 1004)
    expect_state("win.right", 1005)
end

T["auto command"]["hides side buffers after vsplit"] = function()
    child.lua([[
        M = require('no-neck-pain').enable()
    ]])

    local expect_state = function(field, value)
        eq(child.lua_get("_G.NoNeckPain.state." .. field), value)
    end

    -- At start 1 win automatically sorrounded with side buffers
    eq(child.lua_get("vim.api.nvim_list_wins()"), { 1001, 1000, 1002 })
    expect_state("win.left", 1001)
    expect_state("win.right", 1002)

    -- Opening vsplit hides side buffers
    child.cmd("vsplit")
    eq(child.lua_get("vim.api.nvim_list_wins()"), { 1003, 1000 })
    expect_state("win.left", vim.NIL)
    expect_state("win.right", vim.NIL)

    -- Closing vsplit and returning to last window opens side buffers again
    child.cmd("close")
    eq(child.lua_get("vim.api.nvim_list_wins()"), { 1004, 1000, 1005 })
    expect_state("win.left", 1004)
    expect_state("win.right", 1005)
end

return T
