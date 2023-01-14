local helpers = dofile("tests/helpers.lua")

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

local SCOPES = { "left", "right" }

T["color"] = MiniTest.new_set()

T["color"]["map integration name to a value"] = function()
    local integrationMapping = {
        ["catppuccin-frappe"] = "#303446",
        ["catppuccin-frappe-dark"] = "#292c3c",
        ["catppuccin-latte"] = "#eff1f5",
        ["catppuccin-latte-dark"] = "#e6e9ef",
        ["catppuccin-macchiato"] = "#24273a",
        ["catppuccin-macchiato-dark"] = "#1e2030",
        ["catppuccin-mocha"] = "#1e1e2e",
        ["catppuccin-mocha-dark"] = "#181825",
        ["github-nvim-theme-dark"] = "#24292e",
        ["github-nvim-theme-dimmed"] = "#22272e",
        ["github-nvim-theme-light"] = "#ffffff",
        ["onedark"] = "#282c34",
        ["onedark-dark"] = "#000000",
        ["onedark-vivid"] = "#282c34",
        ["onelight"] = "#fafafa",
        ["rose-pine"] = "#191724",
        ["rose-pine-dawn"] = "#faf4ed",
        ["rose-pine-moon"] = "#232136",
        ["tokyonight-day"] = "#16161e",
        ["tokyonight-moon"] = "#1e2030",
        ["tokyonight-night"] = "#16161e",
        ["tokyonight-storm"] = "#1f2335",
    }

    for integration, value in pairs(integrationMapping) do
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
        for _, scope in pairs(SCOPES) do
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
