local MiniTest = require("mini.test")
local Helpers = require("tests.helpers")

local child = Helpers.new_child_neovim()

local T = MiniTest.new_set({
    hooks = {
        pre_case = function()
            child.start({ "-u", "scripts/minimal_init.lua" })
        end,
        post_once = child.stop,
    },
})

T["Diagnostic test for state initialization"] = function()
    child.lua("require('no-neck-pain').setup({ debug = true, width = 50 })")
    child.wait(100)

    -- Check if state exists and is initialized
    child.lua(
        "local state = _G.NoNeckPain.state print('1. After setup, state = ' .. (state and 'table' or 'nil'))"
    )

    -- Now enable the plugin
    child.lua("require('no-neck-pain').enable('test_diagnostic')")
    child.wait(1000)

    -- Check state again
    child.lua(
        "local state = _G.NoNeckPain.state print('2. After enable, state.enabled = ' .. tostring(state and state.enabled or 'N/A'))"
    )
end

return T
