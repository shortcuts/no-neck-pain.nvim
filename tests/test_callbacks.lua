local Helpers = dofile("tests/helpers.lua")

local child = Helpers.new_child_neovim()

local T = MiniTest.new_set({
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

T["setup"] = MiniTest.new_set()

T["setup"]["execute preEnable"] = function()
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
