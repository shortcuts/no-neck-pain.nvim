-- plugin also test 'mini.test'.
local helpers = dofile("tests/helpers.lua")

local child = helpers.new_child_neovim()
local expect, eq = helpers.expect, helpers.expect.equality
local new_set, finally = MiniTest.new_set, MiniTest.finally

-- Define main test set of this file
local T = new_set({
    -- Register hooks
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

-- Test set fields define nested structure
T["setup()"] = new_set()

T["setup()"]["sets global vars and functions"] = function()
    -- Global variable
    eq(child.lua_get("type(vim.g.noNeckPain)"), "boolean")

    -- Functions
    expect.match(child.cmd_capture("NoNeckPain"), "string")
end

-- Return test set which will be collected and execute inside `MiniTest.run()`
return T
