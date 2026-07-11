local Helpers = dofile("tests/helpers.lua")

local child = Helpers.new_child_neovim()

local T = MiniTest.new_set({
    hooks = {
        pre_case = function()
            child.restart({ "-u", "scripts/minimal_init.lua" })
        end,
        post_once = child.stop,
    },
})

-- =============================================================================
-- GROUP 1: Command Tests
-- =============================================================================

T["Commands: NoNeckPain toggles the plugin state"] = function()
    child.nnp()
    Helpers.expect.state(child, "enabled", true)

    child.nnp()
    Helpers.expect.state(child, "enabled", false)
end

T["Commands: NoNeckPainResize sets the config width and resizes windows"] = function()
    child.nnp()

    Helpers.expect.global(child, "_G.NoNeckPain.config.width", 100)

    Helpers.expect.buf_width(child, "tabs[1].wins.main.curr", 80)

    child.cmd("NoNeckPainResize 20")
    child.wait()

    Helpers.expect.global(child, "_G.NoNeckPain.config.width", 20)

    Helpers.expect.buf_width(child, "tabs[1].wins.main.curr", 18)
end

T["Commands: NoNeckPainResize throws with the plugin disabled"] = function()
    Helpers.expect.error(function()
        child.cmd("NoNeckPainResize 20")
    end)
end

T["Commands: NoNeckPainResize does nothing with the same width"] = function()
    child.nnp()

    Helpers.expect.global(child, "_G.NoNeckPain.config.width", 100)

    Helpers.expect.buf_width(child, "tabs[1].wins.main.curr", 80)

    child.cmd("NoNeckPainResize 100")

    Helpers.expect.global(child, "_G.NoNeckPain.config.width", 100)

    Helpers.expect.buf_width(child, "tabs[1].wins.main.curr", 80)
end

T["Commands: NoNeckPainWidthUp increases the width by 5"] = function()
    child.nnp()

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

T["Commands: NoNeckPainWidthUp increases the width by N when mappings.widthUp is configured"] = function()
    child.lua([[require('no-neck-pain').setup({
        mappings = {
            widthUp = {mapping = "<Leader>k-", value = 12},
        }
    })]])

    child.nnp()

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

T["Commands: NoNeckPainWidthDown decreases the width by 5"] = function()
    child.nnp()

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

T["Commands: NoNeckPainWidthDown decreases the width by N when mappings.widthDown is configured"] = function()
    child.lua([[require('no-neck-pain').setup({
        mappings = {
            widthDown = {mapping = "<Leader>k-", value = 8},
        }
    })]])

    child.nnp()

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
