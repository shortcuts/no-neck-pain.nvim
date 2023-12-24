local helpers = dofile("tests/helpers.lua")
local Co = require("no-neck-pain.util.constants")

local child = helpers.new_child_neovim()
local eq, eq_config, eq_state =
    helpers.expect.equality, helpers.expect.config_equality, helpers.expect.state_equality

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

    eq_config(child, "buffers.colors", {
        background = "#828590",
        blend = 0.4,
        text = "#7480c2",
    })

    for _, scope in pairs(Co.SIDES) do
        eq_config(child, "buffers." .. scope .. ".colors", {
            background = "#595c6b",
            blend = 0.2,
            text = "#7480c2",
        })
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

    eq_config(child, "buffers.colors", {
        background = "#444858",
        blend = 0.1,
        text = "#7480c2",
    })

    eq_config(child, "buffers.left.colors", {
        background = "#08080b",
        blend = -0.8,
        text = "#123123",
    })

    eq_config(child, "buffers.right.colors", {
        background = "#ffffff",
        blend = 1,
        text = "#456456",
    })
end

T["setup"]["`common` options spreads it to `left` and `right` buffers"] = function()
    child.cmd([[colorscheme peachpuff]])
    child.lua([[
        require('no-neck-pain').setup({ buffers = {
            colors = {
                background = "catppuccin-frappe",
                blend = 0.9,
                text = "#ff0000",
            },
        }})
        require('no-neck-pain').enable() 
    ]])

    eq_state(child, "enabled", true)

    eq_config(child, "buffers.colors", {
        background = "#eaeaec",
        blend = 0.9,
        text = "#ff0000",
    })

    eq_config(child, "buffers.left.colors", {
        background = "#eaeaec",
        blend = 0.9,
        text = "#ff0000",
    })

    eq_config(child, "buffers.right.colors", {
        background = "#eaeaec",
        blend = 0.9,
        text = "#ff0000",
    })

    -- TODO: enable this when mini.test accepts it
    -- eq(
    --     child.lua_get("vim.api.nvim_get_hl_by_name('NoNeckPain_background_tab_1_side_left', true)"),
    --     {
    --         background = 1,
    --         foreground = 2,
    --     }
    -- )
    --
    -- eq(
    --     child.lua_get("vim.api.nvim_get_hl_by_name('NoNeckPain_background_tab_1_side_right', true)"),
    --     {
    --         background = 1,
    --         foreground = 2,
    --     }
    -- )
end

T["setup"]["(transparent) assert side buffers have the same colors as the main buffer"] = function()
    child.cmd([[
        highlight Normal guibg=none
        highlight NonText guibg=none
        highlight Normal ctermbg=none
        highlight NonText ctermbg=none
    ]])
    child.lua([[
        require('no-neck-pain').setup()
        require('no-neck-pain').enable()
    ]])

    child.lua("vim.fn.win_gotoid(_G.NoNeckPain.state.tabs[1].wins.main.curr)")
    local currbg = child.lua_get("vim.api.nvim_get_hl_by_name('Normal', true).background")

    child.lua("vim.fn.win_gotoid(_G.NoNeckPain.state.tabs[1].wins.main.left)")
    local leftbg = child.lua_get("vim.api.nvim_get_hl_by_name('Normal', true).background")

    child.lua("vim.fn.win_gotoid(_G.NoNeckPain.state.tabs[1].wins.main.right)")
    local rightbg = child.lua_get("vim.api.nvim_get_hl_by_name('Normal', true).background")

    eq(currbg, vim.NIL)
    eq(currbg, leftbg)
    eq(currbg, rightbg)
end

T["setup"]["(normal) assert side buffers have the same colors as the main buffer"] = function()
    child.cmd([[colorscheme blue]])
    child.lua([[
        require('no-neck-pain').setup()
        require('no-neck-pain').enable()
    ]])

    child.lua("vim.fn.win_gotoid(_G.NoNeckPain.state.tabs[1].wins.main.curr)")
    local currbg = child.lua_get("vim.api.nvim_get_hl_by_name('Normal', true).background")

    child.lua("vim.fn.win_gotoid(_G.NoNeckPain.state.tabs[1].wins.main.left)")
    local leftbg = child.lua_get("vim.api.nvim_get_hl_by_name('Normal', true).background")

    child.lua("vim.fn.win_gotoid(_G.NoNeckPain.state.tabs[1].wins.main.right)")
    local rightbg = child.lua_get("vim.api.nvim_get_hl_by_name('Normal', true).background")

    eq(currbg, leftbg)
    eq(currbg, rightbg)
end

T["setup"]["colors.background overrides a nil background when defined"] = function()
    child.lua([[require('no-neck-pain').setup({buffers={colors={background="#abcabc"}}})]])

    eq_config(child, "buffers.colors", {
        background = "#abcabc",
        blend = 0,
    })

    eq_config(child, "buffers.left.colors", {
        background = "#abcabc",
        blend = 0,
    })

    eq_config(child, "buffers.right.colors", {
        background = "#abcabc",
        blend = 0,
    })
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
            eq_config(child, "buffers." .. scope .. ".colors", {
                background = value,
                blend = 0,
            })
        end
    end
end

T["color"]["buffers: throws with wrong background value"] = function()
    helpers.expect.error(function()
        child.lua([[
        require('no-neck-pain').setup({
            buffers = {
                colors = {
                    background = "no-neck-pain",
                },
            },
        })
        ]])
    end)
end

T["color"]["refreshes the stored color when changing colorscheme"] = function()
    child.cmd([[
        highlight Normal guibg=none
        highlight NonText guibg=none
        highlight Normal ctermbg=none
        highlight NonText ctermbg=none
    ]])
    child.lua([[
        require('no-neck-pain').setup({ autocmds = { reloadOnColorSchemeChange=true } })
        require('no-neck-pain').enable()
    ]])

    eq_config(child, "buffers.colors", { blend = 0 })

    child.cmd([[colorscheme peachpuff]])

    eq_config(child, "buffers.colors", { blend = 0 })
end

return T
