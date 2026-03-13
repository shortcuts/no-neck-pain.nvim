local MiniTest = require("mini.test")
local Helpers = require("tests.helpers")

local T = MiniTest.new_set()
local child = Helpers.new_child_neovim()

T["Debug"] = {}

T["Debug"]["check if auto-enable works"] = function()
    child.restart({ "-u", "scripts/init_auto_open.lua" })
    child.wait(500)

    -- Check if the BufRead autocmd is registered
    local autocmds =
        child.lua_get("vim.api.nvim_get_autocmds({ group = 'NoNeckPainVimEnterAutocmd' })")
    print("\n1. BufRead autocmds:", vim.inspect(autocmds))

    -- Now try to open a file
    print("\n2. Opening test.lua...")
    child.cmd("e test.lua")
    child.wait(100)

    -- Check state immediately after
    local state = child.lua_get("_G.NoNeckPain and _G.NoNeckPain.state")
    print("\n3. After e test.lua, state.enabled =", state and state.enabled)

    -- Wait longer
    child.wait(2000)

    -- Check again
    state = child.lua_get("_G.NoNeckPain and _G.NoNeckPain.state")
    print("\n4. After 2s wait, state.enabled =", state and state.enabled)

    -- Try the wait_for helper
    print("\n5. Calling wait_for_plugin_enabled...")
    local enabled = child.wait_for_plugin_enabled(3000)
    print("   Result:", enabled)

    state = child.lua_get("_G.NoNeckPain and _G.NoNeckPain.state")
    print("\n6. Final state.enabled =", state and state.enabled)
end

return T
