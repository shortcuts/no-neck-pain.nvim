local Co = require("no-neck-pain.util.constants")
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

T["install"] = MiniTest.new_set()

T["install"]["sets global loaded variable"] = function()
    Helpers.expect.global_type(child, "_G.NoNeckPainLoaded", "boolean")
    Helpers.expect.global(child, "_G.NoNeckPain", vim.NIL)
end

T["setup"] = MiniTest.new_set()

T["setup"]["sets exposed methods and default options value"] = function()
    child.lua([[require('no-neck-pain').setup()]])

    Helpers.expect.global_type(child, "_G.NoNeckPain", "table")

    -- public methods
    Helpers.expect.global_type(child, "_G.NoNeckPain.toggle", "function")
    Helpers.expect.global_type(child, "_G.NoNeckPain.enable", "function")
    Helpers.expect.global_type(child, "_G.NoNeckPain.setup", "function")

    -- config
    Helpers.expect.global_type(child, "_G.NoNeckPain.config", "table")
    Helpers.expect.config_type(child, "buffers", "table")

    Helpers.expect.config(child, "width", 100)
    Helpers.expect.config(child, "minSideBufferWidth", 10)
    Helpers.expect.config(child, "debug", false)
    Helpers.expect.config(child, "disableOnLastBuffer", false)
    Helpers.expect.config(child, "killAllBuffersOnDisable", false)

    Helpers.expect.config(child, "autocmds", {
        enableOnVimEnter = false,
        enableOnTabEnter = false,
        reloadOnColorSchemeChange = false,
        skipEnteringNoNeckPainBuffer = false,
    })

    Helpers.expect.config(child, "mappings", {
        enabled = false,
        scratchPad = "<Leader>ns",
        toggle = "<Leader>np",
        toggleLeftSide = "<Leader>nql",
        toggleRightSide = "<Leader>nqr",
        widthUp = "<Leader>n=",
        widthDown = "<Leader>n-",
    })

    -- buffers
    Helpers.expect.config_type(child, "buffers", "table")
    Helpers.expect.config_type(child, "buffers.bo", "table")
    Helpers.expect.config_type(child, "buffers.wo", "table")

    Helpers.expect.config(child, "buffers.setNames", false)

    Helpers.expect.config(child, "buffers.colors", {
        blend = 0,
    })

    Helpers.expect.config(child, "buffers.bo", {
        bufhidden = "hide",
        buflisted = false,
        buftype = "nofile",
        filetype = "no-neck-pain",
        swapfile = false,
    })

    Helpers.expect.config(child, "buffers.wo", {
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
        Helpers.expect.config_type(child, "buffers." .. scope, "table")
        Helpers.expect.config_type(child, "buffers." .. scope .. ".bo", "table")
        Helpers.expect.config_type(child, "buffers." .. scope .. ".wo", "table")

        Helpers.expect.config(child, "buffers." .. scope .. ".colors", {
            blend = 0,
        })

        Helpers.expect.config(child, "buffers." .. scope .. ".bo", {
            bufhidden = "hide",
            buflisted = false,
            buftype = "nofile",
            filetype = "no-neck-pain",
            swapfile = false,
        })

        Helpers.expect.config(child, "buffers." .. scope .. ".wo", {
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

    Helpers.expect.config(child, "integrations", {
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
            skipEnteringNoNeckPainBuffer = true,
        },
        debug = true,
        disableOnLastBuffer = true,
        killAllBuffersOnDisable = true,
    })]])

    Helpers.expect.config(child, "width", 42)
    Helpers.expect.config(child, "minSideBufferWidth", 0)
    Helpers.expect.config(child, "debug", true)
    Helpers.expect.config(child, "disableOnLastBuffer", true)
    Helpers.expect.config(child, "killAllBuffersOnDisable", true)
    Helpers.expect.config(child, "autocmds", {
        enableOnVimEnter = true,
        enableOnTabEnter = true,
        reloadOnColorSchemeChange = true,
        skipEnteringNoNeckPainBuffer = true,
    })
end

T["setup"]["width - defaults to the `textwidth` when specified"] = function()
    child.cmd("set textwidth=30")
    child.lua([[require('no-neck-pain').setup({
        width = "textwidth"
    })]])

    Helpers.expect.config(child, "width", 30)
end

T["setup"]["width - defaults to the `textwidth` when specified"] = function()
    child.cmd("set colorcolumn=65")
    child.lua([[require('no-neck-pain').setup({
        width = "colorcolumn"
    })]])

    Helpers.expect.config(child, "width", 65)
end

T["setup"]["width - throws with non-supported string"] = function()
    Helpers.expect.error(function()
        child.lua([[require('no-neck-pain').setup({ width = "foo" })]])
    end)
end

T["setup"]["starts the plugin on VimEnter"] = function()
    child.restart({ "-u", "scripts/init_auto_open.lua" })
    Helpers.wait(child)

    Helpers.expect.equality(Helpers.winsInTab(child), { 1001, 1000, 1002 })
    Helpers.expect.state(child, "enabled", true)

    child.stop()
end

T["enable"] = MiniTest.new_set()

T["enable"]["(single tab) sets state"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    Helpers.toggle(child)

    -- state
    Helpers.expect.global_type(child, "_G.NoNeckPain.state", "table")

    Helpers.expect.state(child, "enabled", true)
    Helpers.expect.state(child, "activeTab", 1)

    Helpers.expect.state_type(child, "tabs", "table")

    Helpers.expect.state_type(child, "tabs[1].wins", "table")
    Helpers.expect.state_type(child, "tabs[1].wins.main", "table")
    Helpers.expect.state_type(child, "tabs[1].wins.integrations", "table")

    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })

    Helpers.expect.state(child, "tabs[1].wins.splits", vim.NIL)

    Helpers.expect.state_type(child, "tabs[1].wins.integrations", "table")

    Helpers.expect.state(child, "tabs[1].wins.integrations", Co.INTEGRATIONS)
end

T["enable"]["(multiple tab) sets state"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    Helpers.toggle(child)

    -- tab 1
    Helpers.expect.global_type(child, "_G.NoNeckPain.state", "table")

    Helpers.expect.state(child, "enabled", true)
    Helpers.expect.state(child, "activeTab", 1)

    Helpers.expect.state_type(child, "tabs", "table")

    Helpers.expect.state_type(child, "tabs[1].wins", "table")
    Helpers.expect.state_type(child, "tabs[1].wins.main", "table")
    Helpers.expect.state_type(child, "tabs[1].wins.integrations", "table")

    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })
    Helpers.expect.state(child, "tabs[1].wins.splits", vim.NIL)

    Helpers.expect.state_type(child, "tabs[1].wins.integrations", "table")

    Helpers.expect.state(child, "tabs[1].wins.integrations", Co.INTEGRATIONS)

    -- tab 2
    child.cmd("tabnew")
    Helpers.toggle(child)

    Helpers.expect.state(child, "enabled", true)
    Helpers.expect.state(child, "activeTab", 2)

    Helpers.expect.state_type(child, "tabs", "table")

    Helpers.expect.state_type(child, "tabs[2].wins", "table")
    Helpers.expect.state_type(child, "tabs[2].wins.main", "table")
    Helpers.expect.state_type(child, "tabs[2].wins.integrations", "table")

    Helpers.expect.state(child, "tabs[2].wins.main", {
        curr = 1003,
        left = 1004,
        right = 1005,
    })
    Helpers.expect.state(child, "tabs[2].wins.splits", vim.NIL)

    Helpers.expect.state_type(child, "tabs[2].wins.integrations", "table")

    Helpers.expect.state(child, "tabs[2].wins.integrations", Co.INTEGRATIONS)
end

T["disable"] = MiniTest.new_set()

T["disable"]["(single tab) resets state"] = function()
    Helpers.toggle(child)

    Helpers.expect.global_type(child, "_G.NoNeckPain.state", "table")

    Helpers.expect.state(child, "enabled", true)
    Helpers.expect.state(child, "activeTab", 1)

    Helpers.expect.state_type(child, "tabs", "table")

    Helpers.toggle(child)

    Helpers.expect.global_type(child, "_G.NoNeckPain.state", "table")

    Helpers.expect.state(child, "enabled", false)
    Helpers.expect.state(child, "activeTab", 1)

    Helpers.expect.state(child, "tabs", vim.NIL)
end

T["disable"]["(multiple tab) resets state"] = function()
    Helpers.toggle(child)

    Helpers.expect.global_type(child, "_G.NoNeckPain.state", "table")

    Helpers.expect.state(child, "enabled", true)
    Helpers.expect.state(child, "activeTab", 1)

    Helpers.expect.state_type(child, "tabs", "table")

    child.cmd("tabnew")
    Helpers.toggle(child)

    Helpers.expect.global_type(child, "_G.NoNeckPain.state", "table")

    Helpers.expect.state(child, "enabled", true)
    Helpers.expect.state(child, "activeTab", 2)

    Helpers.expect.state_type(child, "tabs", "table")

    -- disable tab 2
    Helpers.toggle(child)

    Helpers.expect.state(child, "enabled", true)
    Helpers.expect.state(child, "activeTab", 2)

    Helpers.expect.state_type(child, "tabs", "table")

    -- disable tab 1
    child.cmd("tabprevious")
    Helpers.toggle(child)

    Helpers.expect.state(child, "enabled", false)
    Helpers.expect.state(child, "activeTab", 1)

    Helpers.expect.state(child, "tabs", vim.NIL)
end

return T
