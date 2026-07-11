local Helpers = dofile("tests/helpers.lua")

local child = Helpers.new_child_neovim()

local T = MiniTest.new_set({
    hooks = {
        pre_case = function()
            child.restart({ "-u", "scripts/minimal_init.lua" })
            child.set_size(10, 200)
        end,
        post_once = child.stop,
    },
})

-- =============================================================================
-- GROUP 1: Callback Tests
-- =============================================================================

T["Setup: execute preEnable"] = function()
    child.restart({ "-u", "scripts/init_callbacks.lua" })
    child.nnp()

    Helpers.expect.global_type(child, "_G.NoNeckPainPreEnable", "boolean")
    Helpers.expect.global(child, "_G.NoNeckPainPreEnable", false)

    Helpers.expect.global_type(child, "_G.NoNeckPainPostEnable", "boolean")
    Helpers.expect.global(child, "_G.NoNeckPainPostEnable", true)

    Helpers.expect.global_type(child, "_G.NoNeckPainPreDisable", "nil")
    Helpers.expect.global_type(child, "_G.NoNeckPainPostDisable", "nil")

    child.nnp()

    Helpers.expect.global_type(child, "_G.NoNeckPainPreEnable", "nil")
    Helpers.expect.global_type(child, "_G.NoNeckPainPostEnable", "nil")

    Helpers.expect.global_type(child, "_G.NoNeckPainPreDisable", "boolean")
    Helpers.expect.global(child, "_G.NoNeckPainPreDisable", true)

    Helpers.expect.global_type(child, "_G.NoNeckPainPostDisable", "boolean")
    Helpers.expect.global(child, "_G.NoNeckPainPostDisable", false)
end

return T
