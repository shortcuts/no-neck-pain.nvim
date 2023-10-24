local Co = require("no-neck-pain.util.constants")
local helpers = dofile("tests/helpers.lua")

local child = helpers.new_child_neovim()
local eq, eq_global, eq_config, eq_state =
    helpers.expect.equality,
    helpers.expect.global_equality,
    helpers.expect.config_equality,
    helpers.expect.state_equality
local eq_type_global, eq_type_config, eq_type_state =
    helpers.expect.global_type_equality,
    helpers.expect.config_type_equality,
    helpers.expect.state_type_equality

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

T["install"] = MiniTest.new_set()

T["install"]["sets global loaded variable"] = function()
    eq_type_global(child, "_G.NoNeckPainLoaded", "boolean")
    eq_global(child, "_G.NoNeckPain", vim.NIL)
end

T["setup"] = MiniTest.new_set()

T["setup"]["sets exposed methods and default options value"] = function()
    child.cmd([[
        highlight Normal guibg=black guifg=white
        set background=dark
    ]])
    child.lua([[require('no-neck-pain').setup()]])

    eq_type_global(child, "_G.NoNeckPain", "table")

    -- public methods
    eq_type_global(child, "_G.NoNeckPain.toggle", "function")
    eq_type_global(child, "_G.NoNeckPain.enable", "function")
    eq_type_global(child, "_G.NoNeckPain.setup", "function")

    -- config
    eq_type_global(child, "_G.NoNeckPain.config", "table")
    eq_type_config(child, "buffers", "table")

    eq_config(child, "width", 100)
    eq_config(child, "minSideBufferWidth", 10)
    eq_config(child, "debug", false)
    eq_config(child, "disableOnLastBuffer", false)
    eq_config(child, "killAllBuffersOnDisable", false)

    eq_config(child, "autocmds", {
        enableOnVimEnter = false,
        enableOnTabEnter = false,
        reloadOnColorSchemeChange = false,
    })

    eq_config(child, "mappings", {
        enabled = false,
        scratchPad = "<Leader>ns",
        toggle = "<Leader>np",
        widthUp = "<Leader>n=",
        widthDown = "<Leader>n-",
    })

    -- buffers
    eq_type_config(child, "buffers", "table")
    eq_type_config(child, "buffers.bo", "table")
    eq_type_config(child, "buffers.wo", "table")

    eq_config(child, "buffers.setNames", false)

    eq_config(child, "buffers.colors", {
        background = "#000000",
        blend = 0,
    })

    eq_config(child, "buffers.bo", {
        bufhidden = "hide",
        buflisted = false,
        buftype = "nofile",
        filetype = "no-neck-pain",
        swapfile = false,
    })

    eq_config(child, "buffers.wo", {
        colorcolumn = "0",
        cursorcolumn = false,
        cursorline = false,
        foldenable = false,
        linebreak = true,
        list = false,
        number = false,
        relativenumber = false,
        wrap = true,
    })

    for _, scope in pairs(Co.SIDES) do
        eq_type_config(child, "buffers." .. scope, "table")
        eq_type_config(child, "buffers." .. scope .. ".bo", "table")
        eq_type_config(child, "buffers." .. scope .. ".wo", "table")

        eq_config(child, "buffers." .. scope .. ".colors", {
            background = "#000000",
            blend = 0,
            text = "#7f7f7f",
        })

        eq_config(child, "buffers." .. scope .. ".bo", {
            bufhidden = "hide",
            buflisted = false,
            buftype = "nofile",
            filetype = "no-neck-pain",
            swapfile = false,
        })

        eq_config(child, "buffers." .. scope .. ".wo", {
            colorcolumn = "0",
            cursorcolumn = false,
            cursorline = false,
            foldenable = false,
            linebreak = true,
            list = false,
            number = false,
            relativenumber = false,
            wrap = true,
        })
    end

    eq_config(child, "integrations", {
        NeoTree = {
            position = "left",
            reopen = true,
        },
        NvimDAPUI = {
            position = "none",
            reopen = true,
        },
        NvimTree = {
            position = "left",
            reopen = true,
        },
        TSPlayground = {
            position = "right",
            reopen = true,
        },
        neotest = {
            position = "right",
            reopen = true,
        },
        undotree = {
            position = "left",
        },
    })
end

T["setup"]["overrides default values"] = function()
    child.lua([[require('no-neck-pain').setup({
        width = 42,
        minSideBufferWidth = 0,
        autocmds = {
            enableOnVimEnter = true,
            enableOnTabEnter = true,
            reloadOnColorSchemeChange = true,
        },
        debug = true,
        disableOnLastBuffer = true,
        killAllBuffersOnDisable = true,
    })]])

    eq_config(child, "width", 42)
    eq_config(child, "minSideBufferWidth", 0)
    eq_config(child, "debug", true)
    eq_config(child, "disableOnLastBuffer", true)
    eq_config(child, "killAllBuffersOnDisable", true)
    eq_config(child, "autocmds", {
        enableOnVimEnter = true,
        enableOnTabEnter = true,
        reloadOnColorSchemeChange = true,
    })
end

T["setup"]["width - defaults to the `textwidth` when specified"] = function()
    child.cmd("set textwidth=30")
    child.lua([[require('no-neck-pain').setup({
        width = "textwidth"
    })]])

    eq_config(child, "width", 30)
end

T["setup"]["width - defaults to the `textwidth` when specified"] = function()
    child.cmd("set colorcolumn=65")
    child.lua([[require('no-neck-pain').setup({
        width = "colorcolumn"
    })]])

    eq_config(child, "width", 65)
end

T["setup"]["width - throws with non-supported string"] = function()
    helpers.expect.error(function()
        child.lua([[require('no-neck-pain').setup({ width = "foo" })]])
    end)
end

T["setup"]["starts the plugin on VimEnter"] = function()
    child.restart({ "-u", "scripts/init_auto_open.lua" })

    eq(helpers.winsInTab(child), { 1001, 1000, 1002 })
    eq_state(child, "enabled", true)

    child.stop()
end

T["enable"] = MiniTest.new_set()

T["enable"]["(single tab) sets state"] = function()
    child.lua([[
        require('no-neck-pain').setup({width=50})
        require('no-neck-pain').enable()
    ]])

    -- state
    eq_type_global(child, "_G.NoNeckPain.state", "table")

    eq_state(child, "enabled", true)
    eq_state(child, "activeTab", 1)

    eq_type_state(child, "tabs", "table")

    eq_type_state(child, "tabs[1].wins", "table")
    eq_type_state(child, "tabs[1].wins.main", "table")
    eq_type_state(child, "tabs[1].wins.integrations", "table")

    eq_state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })

    eq_state(child, "tabs[1].wins.splits", vim.NIL)

    eq_type_state(child, "tabs[1].wins.integrations", "table")

    eq_state(child, "tabs[1].wins.integrations", Co.integrations)
end

T["enable"]["(multiple tab) sets state"] = function()
    child.lua([[
        require('no-neck-pain').setup({width=50})
        require('no-neck-pain').enable()
    ]])

    -- tab 1
    eq_type_global(child, "_G.NoNeckPain.state", "table")

    eq_state(child, "enabled", true)
    eq_state(child, "activeTab", 1)

    eq_type_state(child, "tabs", "table")

    eq_type_state(child, "tabs[1].wins", "table")
    eq_type_state(child, "tabs[1].wins.main", "table")
    eq_type_state(child, "tabs[1].wins.integrations", "table")

    eq_state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })
    eq_state(child, "tabs[1].wins.splits", vim.NIL)

    eq_type_state(child, "tabs[1].wins.integrations", "table")

    eq_state(child, "tabs[1].wins.integrations", Co.integrations)

    -- tab 2
    child.cmd("tabnew")
    child.lua([[ require('no-neck-pain').enable() ]])

    eq_state(child, "enabled", true)
    eq_state(child, "activeTab", 2)

    eq_type_state(child, "tabs", "table")

    eq_type_state(child, "tabs[2].wins", "table")
    eq_type_state(child, "tabs[2].wins.main", "table")
    eq_type_state(child, "tabs[2].wins.integrations", "table")

    eq_state(child, "tabs[2].wins.main", {
        curr = 1003,
        left = 1004,
        right = 1005,
    })
    eq_state(child, "tabs[2].wins.splits", vim.NIL)

    eq_type_state(child, "tabs[2].wins.integrations", "table")

    eq_state(child, "tabs[2].wins.integrations", Co.integrations)
end

T["disable"] = MiniTest.new_set()

T["disable"]["(single tab) resets state"] = function()
    child.lua([[ require('no-neck-pain').enable() ]])

    eq_type_global(child, "_G.NoNeckPain.state", "table")

    eq_state(child, "enabled", true)
    eq_state(child, "activeTab", 1)

    eq_type_state(child, "tabs", "table")

    child.lua([[ require('no-neck-pain').disable() ]])

    eq_type_global(child, "_G.NoNeckPain.state", "table")

    eq_state(child, "enabled", false)
    eq_state(child, "activeTab", 1)

    eq_state(child, "tabs", vim.NIL)
end

T["disable"]["(multiple tab) resets state"] = function()
    child.lua([[ require('no-neck-pain').enable() ]])

    eq_type_global(child, "_G.NoNeckPain.state", "table")

    eq_state(child, "enabled", true)
    eq_state(child, "activeTab", 1)

    eq_type_state(child, "tabs", "table")

    child.cmd("tabnew")
    child.lua([[ require('no-neck-pain').enable() ]])

    eq_type_global(child, "_G.NoNeckPain.state", "table")

    eq_state(child, "enabled", true)
    eq_state(child, "activeTab", 2)

    eq_type_state(child, "tabs", "table")

    -- disable tab 2
    child.lua([[ require('no-neck-pain').disable() ]])

    eq_state(child, "enabled", true)
    eq_state(child, "activeTab", 2)

    eq_type_state(child, "tabs", "table")

    -- disable tab 1
    child.cmd("tabprevious")
    child.lua([[ require('no-neck-pain').disable() ]])

    eq_state(child, "enabled", false)
    eq_state(child, "activeTab", 1)

    eq_state(child, "tabs", vim.NIL)
end

return T
