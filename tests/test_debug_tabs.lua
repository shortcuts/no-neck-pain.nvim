local MiniTest = require("mini.test")
local Helpers = require("tests.helpers")

local child = Helpers.new_child_neovim()

local T = MiniTest.new_set({
    hooks = {
        post_once = child.stop,
    },
})

T["check if auto-enable works"] = function()
    child.restart({ "-u", "scripts/init_auto_open.lua" })
    child.wait(500)

    local has_state = child.lua_get("_G.NoNeckPain ~= nil and _G.NoNeckPain.state ~= nil")
    MiniTest.expect.equality(has_state, true)
    
    local is_enabled = child.lua_get("_G.NoNeckPain.state.enabled")
    MiniTest.expect.equality(is_enabled, true)
end

return T
