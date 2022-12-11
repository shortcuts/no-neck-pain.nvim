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

return T
