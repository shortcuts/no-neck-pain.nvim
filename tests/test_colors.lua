local Helpers = dofile("tests/helpers.lua")
local Co = require("no-neck-pain.util.constants")

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

    Helpers.expect.config(child, "buffers.colors", {
        background = "#828590",
        blend = 0.4,
        text = "#7480c2",
    })

    for _, scope in pairs(Co.SIDES) do
        Helpers.expect.config(child, "buffers." .. scope .. ".colors", {
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

    Helpers.expect.config(child, "buffers.colors", {
        background = "#444858",
        blend = 0.1,
        text = "#7480c2",
    })

    Helpers.expect.config(child, "buffers.left.colors", {
        background = "#08080b",
        blend = -0.8,
        text = "#123123",
    })

    Helpers.expect.config(child, "buffers.right.colors", {
        background = "#ffffff",
        blend = 1,
        text = "#456456",
    })
end

T["setup"]["does not throw on invalid windows"] = function()
    child.restart({ "-u", "scripts/init_auto_open.lua" })
    child.set_size(80, 80)
    child.wait()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })
    Helpers.expect.state(child, "tabs[1].wins.main", { curr = 1000, left = 1001, right = 1002 })

    child.cmd("e aaa.txt")
    child.cmd("vnew aaa.txt")
    child.cmd("mksession! deps/mk.vim")

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1003, 1000, 1002 })
    Helpers.expect.state(child, "tabs[1].wins.main", { curr = 1000, left = 1001, right = 1002 })

    child.restart({ "-u", "scripts/init_auto_open.lua" })
    child.wait()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })

    child.cmd("source deps/mk.vim")
    child.wait()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1000, 1003, 1004, 1005 })
    Helpers.expect.state(child, "tabs[1].wins.main", { curr = 1000, left = 1001, right = 1002 })
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
    ]])
    child.nnp()

    Helpers.expect.state(child, "enabled", true)

    Helpers.expect.config(child, "buffers.colors", {
        background = "#eaeaec",
        blend = 0.9,
        text = "#ff0000",
    })

    Helpers.expect.config(child, "buffers.left.colors", {
        background = "#eaeaec",
        blend = 0.9,
        text = "#ff0000",
    })

    Helpers.expect.config(child, "buffers.right.colors", {
        background = "#eaeaec",
        blend = 0.9,
        text = "#ff0000",
    })
end

T["setup"]["(transparent) assert side buffers have the same colors as the main buffer"] = function()
    child.cmd([[
        highlight Normal guibg=none
        highlight NonText guibg=none
        highlight Normal ctermbg=none
        highlight NonText ctermbg=none
    ]])
    child.lua([[ require('no-neck-pain').setup() ]])
    child.nnp()

    child.lua("vim.fn.win_gotoid(_G.NoNeckPain.state.tabs[1].wins.main.curr)")
    local currbg = child.lua_get("vim.api.nvim_get_hl_by_name('Normal', true).background")

    child.lua("vim.fn.win_gotoid(_G.NoNeckPain.state.tabs[1].wins.main.left)")
    local leftbg = child.lua_get("vim.api.nvim_get_hl_by_name('Normal', true).background")

    child.lua("vim.fn.win_gotoid(_G.NoNeckPain.state.tabs[1].wins.main.right)")
    local rightbg = child.lua_get("vim.api.nvim_get_hl_by_name('Normal', true).background")

    Helpers.expect.equality(currbg, vim.NIL)
    Helpers.expect.equality(currbg, leftbg)
    Helpers.expect.equality(currbg, rightbg)
end

T["setup"]["(normal) assert side buffers have the same colors as the main buffer"] = function()
    child.cmd([[colorscheme blue]])
    child.lua([[ require('no-neck-pain').setup() ]])
    child.nnp()

    child.lua("vim.fn.win_gotoid(_G.NoNeckPain.state.tabs[1].wins.main.curr)")
    local currbg = child.lua_get("vim.api.nvim_get_hl_by_name('Normal', true).background")

    child.lua("vim.fn.win_gotoid(_G.NoNeckPain.state.tabs[1].wins.main.left)")
    local leftbg = child.lua_get("vim.api.nvim_get_hl_by_name('Normal', true).background")

    child.lua("vim.fn.win_gotoid(_G.NoNeckPain.state.tabs[1].wins.main.right)")
    local rightbg = child.lua_get("vim.api.nvim_get_hl_by_name('Normal', true).background")

    Helpers.expect.equality(currbg, leftbg)
    Helpers.expect.equality(currbg, rightbg)
end

T["setup"]["colors.background overrides a nil background when defined"] = function()
    child.lua([[require('no-neck-pain').setup({buffers={colors={background="#abcabc"}}})]])

    Helpers.expect.config(child, "buffers.colors", {
        background = "#abcabc",
        blend = 0,
    })

    Helpers.expect.config(child, "buffers.left.colors", {
        background = "#abcabc",
        blend = 0,
    })

    Helpers.expect.config(child, "buffers.right.colors", {
        background = "#abcabc",
        blend = 0,
    })
end

T["color"] = MiniTest.new_set()

T["color"]["map integration name to a value"] = function()
    for integration, value in pairs(Co.THEMES) do
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
            Helpers.expect.config(child, "buffers." .. scope .. ".colors", {
                background = value,
                blend = 0,
            })
        end
    end
end

T["color"]["buffers: throws with wrong background value"] = function()
    Helpers.expect.error(function()
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
    child.lua(
        [[ require('no-neck-pain').setup({ autocmds = { reloadOnColorSchemeChange=true } }) ]]
    )
    child.nnp()

    Helpers.expect.config(child, "buffers.colors", { blend = 0 })

    child.cmd([[colorscheme peachpuff]])

    Helpers.expect.config(child, "buffers.colors", { blend = 0 })
end

return T
