-- plugin also test 'mini.test'.
local helpers = dofile("tests/helpers.lua")

local child = helpers.new_child_neovim()
local _, eq = helpers.expect, helpers.expect.equality
local new_set, _ = MiniTest.new_set, MiniTest.finally

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

T["setup()"]["sets global variable"] = function()
    eq(child.lua_get("type(_G.noNeckPainLoaded)"), "boolean")
end

T["setup()"]["check exposed fields"] = function()
    eq(child.lua_get("type(_G.NoNeckPain)"), "table")

    -- exposed fns
    eq(child.lua_get("type(_G.NoNeckPain.start)"), "function")
    eq(child.lua_get("type(_G.NoNeckPain.setup)"), "function")

    -- config
    eq(child.lua_get("type(_G.NoNeckPain.config)"), "table")

    local expect_config = function(field, value)
        eq(child.lua_get("_G.NoNeckPain.config." .. field), value)
    end

    expect_config("width", 100)
    expect_config("debug", false)
end

return T
