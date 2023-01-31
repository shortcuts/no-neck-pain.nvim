local helpers = dofile("tests/helpers.lua")

local child = helpers.new_child_neovim()
local eq_global, eq_state, eq_buf_width =
    helpers.expect.global_equality, helpers.expect.state_equality, helpers.expect.buf_width_equality

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

T["commands"] = MiniTest.new_set()

T["commands"]["NoNeckPain toggles the plugin state"] = function()
    child.cmd("NoNeckPain")
    eq_state(child, "enabled", true)

    child.cmd("NoNeckPain")
    eq_state(child, "enabled", false)
end

T["commands"]["NoNeckPainResize sets the config width and resizes windows"] = function()
    child.cmd("NoNeckPain")

    eq_global(child, "_G.NoNeckPain.config.width", 100)

    -- need to know why the child isn't precise enough
    eq_buf_width(child, "tabs[1].wins.main.curr", 80)

    child.cmd("NoNeckPainResize 20")

    eq_global(child, "_G.NoNeckPain.config.width", 20)

    -- need to know why the child isn't precise enough
    eq_buf_width(child, "tabs[1].wins.main.curr", 20)
end

T["commands"]["NoNeckPainResize throws with the plugin disabled"] = function()
    helpers.expect.error(function()
        child.cmd("NoNeckPainResize 20")
    end)
end

T["commands"]["NoNeckPainResize does nothing with the same widht"] = function()
    child.cmd("NoNeckPain")

    eq_global(child, "_G.NoNeckPain.config.width", 100)

    -- need to know why the child isn't precise enough
    eq_buf_width(child, "tabs[1].wins.main.curr", 80)

    child.cmd("NoNeckPainResize 100")

    eq_global(child, "_G.NoNeckPain.config.width", 100)

    -- need to know why the child isn't precise enough
    eq_buf_width(child, "tabs[1].wins.main.curr", 80)
end

return T
