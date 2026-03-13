local MiniTest = require("mini.test")
local Helpers = require("tests.helpers")

local T = MiniTest.new_set()

T["Diagnostic test for state initialization"] = function()
    local child = Helpers.new_child_neovim()

    child.lua("require('no-neck-pain').setup({ debug = true, width = 50 })")
    child.wait(100)

    -- Check if state exists and is initialized
    local state = child.lua_get("_G.NoNeckPain.state")
    print("\n1. After setup, state.enabled = ", state and state.enabled)

    -- Now enable the plugin
    child.lua("require('no-neck-pain').enable('test_diagnostic')")
    child.wait(1000)

    -- Check state again
    state = child.lua_get("_G.NoNeckPain.state")
    print("\n2. After enable, state.enabled = ", state and state.enabled)

    child.stop()
end

return T
