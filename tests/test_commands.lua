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

T["commands"] = MiniTest.new_set()

T["commands"]["NoNeckPain toggles the plugin state"] = function()
    Helpers.toggle(child)
    Helpers.expect.state(child, "enabled", true)

    Helpers.toggle(child)
    Helpers.expect.state(child, "enabled", false)
end

T["commands"]["NoNeckPainResize sets the config width and resizes windows"] = function()
    Helpers.toggle(child)

    Helpers.expect.global(child, "_G.NoNeckPain.config.width", 100)

    -- need to know why the child isn't precise enough
    Helpers.expect.buf_width(child, "tabs[1].wins.main.curr", 80)

    child.cmd("NoNeckPainResize 20")
    Helpers.wait(child)

    Helpers.expect.global(child, "_G.NoNeckPain.config.width", 20)

    Helpers.expect.buf_width(child, "tabs[1].wins.main.curr", 18)
end

T["commands"]["NoNeckPainResize throws with the plugin disabled"] = function()
    Helpers.expect.error(function()
        child.cmd("NoNeckPainResize 20")
    end)
end

T["commands"]["NoNeckPainResize does nothing with the same width"] = function()
    Helpers.toggle(child)

    Helpers.expect.global(child, "_G.NoNeckPain.config.width", 100)

    -- need to know why the child isn't precise enough
    Helpers.expect.buf_width(child, "tabs[1].wins.main.curr", 80)

    child.cmd("NoNeckPainResize 100")

    Helpers.expect.global(child, "_G.NoNeckPain.config.width", 100)

    -- need to know why the child isn't precise enough
    Helpers.expect.buf_width(child, "tabs[1].wins.main.curr", 80)
end

T["commands"]["NoNeckPainWidthUp increases the width by 5"] = function()
    Helpers.toggle(child)

    Helpers.expect.global(child, "_G.NoNeckPain.config.width", 100)

    child.cmd("NoNeckPainWidthUp")
    child.cmd("NoNeckPainWidthUp")
    child.cmd("NoNeckPainWidthUp")
    child.cmd("NoNeckPainWidthUp")
    child.cmd("NoNeckPainWidthUp")
    child.cmd("NoNeckPainWidthUp")
    child.cmd("NoNeckPainWidthUp")
    child.cmd("NoNeckPainWidthUp")
    child.cmd("NoNeckPainWidthUp")
    child.cmd("NoNeckPainWidthUp")

    Helpers.expect.global(child, "_G.NoNeckPain.config.width", 150)
end

T["commands"]["NoNeckPainWidthUp increases the width by N when mappings.widthUp is configured"] = function()
    child.lua([[require('no-neck-pain').setup({
        mappings = {
            widthUp = {mapping = "<Leader>k-", value = 12},
        }
    })]])

    Helpers.toggle(child)

    Helpers.expect.global(child, "_G.NoNeckPain.config.width", 100)

    child.cmd("NoNeckPainWidthUp")
    child.cmd("NoNeckPainWidthUp")
    child.cmd("NoNeckPainWidthUp")
    child.cmd("NoNeckPainWidthUp")
    child.cmd("NoNeckPainWidthUp")
    child.cmd("NoNeckPainWidthUp")
    child.cmd("NoNeckPainWidthUp")
    child.cmd("NoNeckPainWidthUp")
    child.cmd("NoNeckPainWidthUp")
    child.cmd("NoNeckPainWidthUp")

    Helpers.expect.global(child, "_G.NoNeckPain.config.width", 220)
end

T["commands"]["NoNeckPainWidthUp decreases the width by 5"] = function()
    Helpers.toggle(child)

    Helpers.expect.global(child, "_G.NoNeckPain.config.width", 100)

    child.cmd("NoNeckPainWidthDown")
    child.cmd("NoNeckPainWidthDown")
    child.cmd("NoNeckPainWidthDown")
    child.cmd("NoNeckPainWidthDown")
    child.cmd("NoNeckPainWidthDown")
    child.cmd("NoNeckPainWidthDown")
    child.cmd("NoNeckPainWidthDown")
    child.cmd("NoNeckPainWidthDown")
    child.cmd("NoNeckPainWidthDown")
    child.cmd("NoNeckPainWidthDown")

    Helpers.expect.global(child, "_G.NoNeckPain.config.width", 50)
end

T["commands"]["NoNeckPainWidthUp decreases the width by N when mappings.widthDown is configured"] = function()
    child.lua([[require('no-neck-pain').setup({
        mappings = {
            widthDown = {mapping = "<Leader>k-", value = 8},
        }
    })]])

    Helpers.toggle(child)

    Helpers.expect.global(child, "_G.NoNeckPain.config.width", 100)

    child.cmd("NoNeckPainWidthDown")
    child.cmd("NoNeckPainWidthDown")
    child.cmd("NoNeckPainWidthDown")
    child.cmd("NoNeckPainWidthDown")
    child.cmd("NoNeckPainWidthDown")
    child.cmd("NoNeckPainWidthDown")
    child.cmd("NoNeckPainWidthDown")
    child.cmd("NoNeckPainWidthDown")
    child.cmd("NoNeckPainWidthDown")
    child.cmd("NoNeckPainWidthDown")

    Helpers.expect.global(child, "_G.NoNeckPain.config.width", 20)
end

return T
