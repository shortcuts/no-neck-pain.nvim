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
    child.lua([[require('no-neck-pain').setup({
        buffers = {
            backgroundColor = "catppuccin-frappe",
            blend = 0.4,
            textColor = "#7480c2",
            left = {
                backgroundColor = "catppuccin-frappe",
                blend = 0.2,
            	textColor = "#7480c2",
            },
            right = {
                backgroundColor = "catppuccin-frappe",
                blend = 0.2,
            	textColor = "#7480c2",
            },
        },
    })]])

    eq_config(child, "buffers.backgroundColor", "#828590")
    eq_config(child, "buffers.blend", 0.4)
    eq_config(child, "buffers.textColor", "#7480c2")

    for _, scope in pairs(Co.SIDES) do
        eq_config(child, "buffers." .. scope .. ".backgroundColor", "#595c6b")
        eq_config(child, "buffers." .. scope .. ".blend", 0.2)
        eq_config(child, "buffers." .. scope .. ".textColor", "#7480c2")
    end
end

T["setup"]["`left` or `right` buffer options overrides `common` ones"] = function()
    child.lua([[require('no-neck-pain').setup({
        buffers = {
            backgroundColor = "catppuccin-frappe",
            blend = 0.1,
            textColor = "#7480c2",
            left = {
                backgroundColor = "catppuccin-frappe-dark",
                blend = -0.8,
                textColor = "#123123",
            },
            right = {
                backgroundColor = "catppuccin-latte",
                blend = 1,
                textColor = "#456456",
            },
        },
    })]])

    eq_config(child, "buffers.backgroundColor", "#444858")
    eq_config(child, "buffers.blend", 0.1)
    eq_config(child, "buffers.textColor", "#7480c2")

    eq_config(child, "buffers.left.backgroundColor", "#08080b")
    eq_config(child, "buffers.right.backgroundColor", "#ffffff")

    eq_config(child, "buffers.left.blend", -0.8)
    eq_config(child, "buffers.right.blend", 1)

    eq_config(child, "buffers.left.textColor", "#123123")
    eq_config(child, "buffers.right.textColor", "#456456")
end

T["setup"]["`common` options spreads it to `left` and `right` buffers"] = function()
    child.lua([[require('no-neck-pain').setup({
        buffers = {
            backgroundColor = "catppuccin-frappe",
            blend = 1,
            textColor = "#000000",
        },
    })]])

    eq_config(child, "buffers.backgroundColor", "#ffffff")
    eq_config(child, "buffers.textColor", "#000000")

    eq_config(child, "buffers.left.backgroundColor", "#ffffff")
    eq_config(child, "buffers.right.backgroundColor", "#ffffff")

    eq_config(child, "buffers.left.blend", 1)
    eq_config(child, "buffers.right.blend", 1)

    eq_config(child, "buffers.left.textColor", "#000000")
    eq_config(child, "buffers.right.textColor", "#000000")
end

T["color"] = MiniTest.new_set()

T["color"]["map integration name to a value"] = function()
    for integration, value in pairs(Co.INTEGRATIONS) do
        child.lua(string.format(
            [[ require('no-neck-pain').setup({
                buffers = {
                    backgroundColor = "%s",
                    left = { backgroundColor = "%s" },
                    right = { backgroundColor = "%s" },
                },
            })]],
            integration,
            integration,
            integration
        ))
        for _, scope in pairs(Co.SIDES) do
            eq_config(child, "buffers." .. scope .. ".backgroundColor", value)
        end
    end
end

T["color"]["buffers: throws with wrong values"] = function()
    local keyValueSetupErrors = {
        { "backgroundColor", "no-neck-pain" },
        { "blend", 30 },
    }

    for _, keyValueSetupError in pairs(keyValueSetupErrors) do
        helpers.expect.error(function()
            child.lua(string.format(
                [[require('no-neck-pain').setup({
                    buffers = {
                        %s = "%s",
                    },
                })]],
                keyValueSetupError[1],
                keyValueSetupError[2]
            ))
        end)
    end
end

return T
