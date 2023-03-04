local helpers = dofile("tests/helpers.lua")
local Co = require("no-neck-pain.util.constants")

local child = helpers.new_child_neovim()
local eq_config = helpers.expect.config_equality

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

T["setup"]["overrides default values"] = function()
    child.cmd([[
        highlight Normal guibg=black guifg=white
        set background=dark
    ]])
    child.lua([[require('no-neck-pain').setup({
        buffers = {
            colors = {
                background = "catppuccin-frappe",
                blend = 0.4,
                text = "#7480c2",
            },
            left = {
                colors = {
                    background = "catppuccin-frappe",
                    blend = 0.2,
            	    text = "#7480c2",
                },
            },
            right = {
                colors = {
                    background = "catppuccin-frappe",
                    blend = 0.2,
            	    text = "#7480c2",
                },
            },
        },
    })]])

    eq_config(child, "buffers.colors.background", "#828590")
    eq_config(child, "buffers.colors.blend", 0.4)
    eq_config(child, "buffers.colors.text", "#7480c2")

    for _, scope in pairs(Co.SIDES) do
        eq_config(child, "buffers." .. scope .. ".colors.background", "#595c6b")
        eq_config(child, "buffers." .. scope .. ".colors.blend", 0.2)
        eq_config(child, "buffers." .. scope .. ".colors.text", "#7480c2")
    end
end

T["setup"]["`left` or `right` buffer options overrides `common` ones"] = function()
    child.cmd([[
        highlight Normal guibg=black guifg=white
        set background=dark
    ]])
    child.lua([[require('no-neck-pain').setup({
        buffers = {
            colors = {
                background = "catppuccin-frappe",
                blend = 0.1,
                text = "#7480c2",
            },
            left = {
                colors = {
                    background = "catppuccin-frappe-dark",
                    blend = -0.8,
                    text = "#123123",
                },
            },
            right = {
                colors = {
                    background = "catppuccin-latte",
                    blend = 1,
                    text = "#456456",
                },
            },
        },
    })]])

    eq_config(child, "buffers.colors.background", "#444858")
    eq_config(child, "buffers.colors.blend", 0.1)
    eq_config(child, "buffers.colors.text", "#7480c2")

    eq_config(child, "buffers.left.colors.background", "#08080b")
    eq_config(child, "buffers.right.colors.background", "#ffffff")

    eq_config(child, "buffers.left.colors.blend", -0.8)
    eq_config(child, "buffers.right.colors.blend", 1)

    eq_config(child, "buffers.left.colors.text", "#123123")
    eq_config(child, "buffers.right.colors.text", "#456456")
end

T["setup"]["`common` options spreads it to `left` and `right` buffers"] = function()
    child.cmd([[
        highlight Normal guibg=black guifg=white
        set background=dark
    ]])
    child.lua([[require('no-neck-pain').setup({
        buffers = {
            colors = {
                background = "catppuccin-frappe",
                blend = 1,
                text = "#000000",
            },
        },
    })]])

    eq_config(child, "buffers.colors.background", "#ffffff")
    eq_config(child, "buffers.colors.text", "#000000")

    eq_config(child, "buffers.left.colors.background", "#ffffff")
    eq_config(child, "buffers.right.colors.background", "#ffffff")

    eq_config(child, "buffers.left.colors.blend", 1)
    eq_config(child, "buffers.right.colors.blend", 1)

    eq_config(child, "buffers.left.colors.text", "#000000")
    eq_config(child, "buffers.right.colors.text", "#000000")
end

T["setup"]["supports transparent bgs"] = function()
    child.lua([[require('no-neck-pain').setup()]])

    eq_config(child, "buffers.colors.background", "NONE")
    eq_config(child, "buffers.colors.text", "#ffffff")

    for _, scope in pairs(Co.SIDES) do
        eq_config(child, "buffers." .. scope .. ".colors.background", "NONE")
        eq_config(child, "buffers." .. scope .. ".colors.text", "#ffffff")
    end
end

T["setup"]["colors.background overrides a nil background when defined"] = function()
    child.lua([[require('no-neck-pain').setup({buffers={colors={background="#abcabc"}}})]])

    eq_config(child, "buffers.colors.background", "#abcabc")
    eq_config(child, "buffers.colors.text", vim.NIL)

    for _, scope in pairs(Co.SIDES) do
        eq_config(child, "buffers." .. scope .. ".colors.background", "#abcabc")
        eq_config(child, "buffers." .. scope .. ".colors.text", "#d5e4dd")
    end
end

T["color"] = MiniTest.new_set()

T["color"]["map integration name to a value"] = function()
    for integration, value in pairs(Co.INTEGRATIONS) do
        child.lua(string.format(
            [[ require('no-neck-pain').setup({
                buffers = {
                    colors = { background = "%s" },
                    left = { colors = { background = "%s" } },
                    right = { colors = { background = "%s" } },
                },
            })]],
            integration,
            integration,
            integration
        ))
        for _, scope in pairs(Co.SIDES) do
            eq_config(child, "buffers." .. scope .. ".colors.background", value)
        end
    end
end
--
T["color"]["buffers: throws with wrong values"] = function()
    local keyValueSetupErrors = {
        { "background", "no-neck-pain" },
        { "blend", 30 },
    }

    for _, keyValueSetupError in pairs(keyValueSetupErrors) do
        helpers.expect.error(function()
            child.lua(string.format(
                [[require('no-neck-pain').setup({
                    buffers = {
                        colors = {
                            %s = "%s",
                        },
                    },
                })]],
                keyValueSetupError[1],
                keyValueSetupError[2]
            ))
        end)
    end
end

return T
