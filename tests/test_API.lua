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
    child.wait()
    Helpers.expect.global(child, "_G.NoNeckPain", vim.NIL)
    Helpers.expect.global_type(child, "_G.NoNeckPainLoaded", "boolean")
end

T["setup"] = MiniTest.new_set()

T["setup"]["sets exposed methods and default options value"] = function()
    child.lua([[require('no-neck-pain').setup()]])

    Helpers.expect.global_type(child, "_G.NoNeckPain", "table")

    -- public methods
    Helpers.expect.global_type(child, "_G.NoNeckPain.toggle", "function")
    Helpers.expect.global_type(child, "_G.NoNeckPain.enable", "function")
    Helpers.expect.global_type(child, "_G.NoNeckPain.setup", "function")
    Helpers.expect.global_type(child, "_G.NoNeckPain.resize", "function")
    Helpers.expect.global_type(child, "_G.NoNeckPain.disable", "function")
    Helpers.expect.global_type(child, "_G.NoNeckPain.toggleSide", "function")
    Helpers.expect.global_type(child, "_G.NoNeckPain.toggleScratchPad", "function")

    -- config
    Helpers.expect.global_type(child, "_G.NoNeckPain.config", "table")
    Helpers.expect.config_type(child, "buffers", "table")

    Helpers.expect.config(child, "", {
        width = 100,
        minSideBufferWidth = 10,
        debug = false,
        disableOnLastBuffer = false,
        killAllBuffersOnDisable = false,
        fallbackOnBufferDelete = true,
        autocmds = {
            enableOnVimEnter = false,
            enableOnTabEnter = false,
            reloadOnColorSchemeChange = false,
            skipEnteringNoNeckPainBuffer = false,
        },
        mappings = {
            enabled = false,
            scratchPad = "<Leader>ns",
            toggle = "<Leader>np",
            toggleLeftSide = "<Leader>nql",
            toggleRightSide = "<Leader>nqr",
            widthUp = "<Leader>n=",
            widthDown = "<Leader>n-",
        },
        callbacks = {},
        buffers = {
            setNames = false,
            colors = { blend = 0 },
            bo = {
                bufhidden = "hide",
                buflisted = false,
                buftype = "nofile",
                filetype = "no-neck-pain",
                swapfile = false,
            },
            wo = {
                colorcolumn = "0",
                cursorcolumn = false,
                cursorline = false,
                foldenable = false,
                linebreak = true,
                list = false,
                number = false,
                relativenumber = false,
                wrap = true,
            },
            left = {
                enabled = true,
                scratchPad = {
                    enabled = false,
                    pathToFile = "no-neck-pain-left.norg",
                },
                colors = { blend = 0 },
                bo = {
                    bufhidden = "hide",
                    buflisted = false,
                    buftype = "nofile",
                    filetype = "no-neck-pain",
                    swapfile = false,
                },
                wo = {
                    colorcolumn = "0",
                    cursorcolumn = false,
                    cursorline = false,
                    foldenable = false,
                    linebreak = true,
                    list = false,
                    number = false,
                    relativenumber = false,
                    wrap = true,
                },
            },
            right = {
                enabled = true,
                scratchPad = {
                    enabled = false,
                    pathToFile = "no-neck-pain-right.norg",
                },
                colors = { blend = 0 },
                bo = {
                    bufhidden = "hide",
                    buflisted = false,
                    buftype = "nofile",
                    filetype = "no-neck-pain",
                    swapfile = false,
                },
                wo = {
                    colorcolumn = "0",
                    cursorcolumn = false,
                    cursorline = false,
                    foldenable = false,
                    linebreak = true,
                    list = false,
                    number = false,
                    relativenumber = false,
                    wrap = true,
                },
            },
        },
        integrations = {
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
            outline = {
                position = "right",
                reopen = true,
            },
            aerial = {
                position = "right",
                reopen = true,
            },
            dashboard = {
                enabled = false,
                filetype = nil,
            },
        },
    })
end

T["setup"]["overrides default values"] = function()
    child.lua([[require('no-neck-pain').setup({
        width = 42,
        minSideBufferWidth = 0,
        debug = true,
        disableOnLastBuffer = true,
        killAllBuffersOnDisable = true,
        fallbackOnBufferDelete = false,
        autocmds = {
            enableOnVimEnter = true,
            enableOnTabEnter = true,
            reloadOnColorSchemeChange = true,
            skipEnteringNoNeckPainBuffer = true,
        },
        mappings = {enabled = true}
    })]])

    Helpers.expect.config(child, "", {
        width = 42,
        minSideBufferWidth = 0,
        debug = true,
        disableOnLastBuffer = true,
        killAllBuffersOnDisable = true,
        fallbackOnBufferDelete = false,
        autocmds = {
            enableOnVimEnter = true,
            enableOnTabEnter = true,
            reloadOnColorSchemeChange = true,
            skipEnteringNoNeckPainBuffer = true,
        },
        callbacks = {},
        mappings = {
            enabled = true,
            scratchPad = "<Leader>ns",
            toggle = "<Leader>np",
            toggleLeftSide = "<Leader>nql",
            toggleRightSide = "<Leader>nqr",
            widthUp = "<Leader>n=",
            widthDown = "<Leader>n-",
        },
        buffers = {
            setNames = false,
            colors = { blend = 0 },
            bo = {
                bufhidden = "hide",
                buflisted = false,
                buftype = "nofile",
                filetype = "no-neck-pain",
                swapfile = false,
            },
            wo = {
                colorcolumn = "0",
                cursorcolumn = false,
                cursorline = false,
                foldenable = false,
                linebreak = true,
                list = false,
                number = false,
                relativenumber = false,
                wrap = true,
            },
            left = {
                enabled = true,
                scratchPad = {
                    enabled = false,
                    pathToFile = "no-neck-pain-left.norg",
                },
                colors = { blend = 0 },
                bo = {
                    bufhidden = "hide",
                    buflisted = false,
                    buftype = "nofile",
                    filetype = "no-neck-pain",
                    swapfile = false,
                },
                wo = {
                    colorcolumn = "0",
                    cursorcolumn = false,
                    cursorline = false,
                    foldenable = false,
                    linebreak = true,
                    list = false,
                    number = false,
                    relativenumber = false,
                    wrap = true,
                },
            },
            right = {
                enabled = true,
                scratchPad = {
                    enabled = false,
                    pathToFile = "no-neck-pain-right.norg",
                },
                colors = { blend = 0 },
                bo = {
                    bufhidden = "hide",
                    buflisted = false,
                    buftype = "nofile",
                    filetype = "no-neck-pain",
                    swapfile = false,
                },
                wo = {
                    colorcolumn = "0",
                    cursorcolumn = false,
                    cursorline = false,
                    foldenable = false,
                    linebreak = true,
                    list = false,
                    number = false,
                    relativenumber = false,
                    wrap = true,
                },
            },
        },
        integrations = {
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
            outline = {
                position = "right",
                reopen = true,
            },
            aerial = {
                position = "right",
                reopen = true,
            },
            dashboard = {
                enabled = false,
                filetype = nil,
            },
        },
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

T["enable"] = MiniTest.new_set()

T["enable"]["(single tab) sets state"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()

    -- state
    Helpers.expect.global_type(child, "_G.NoNeckPain.state", "table")

    Helpers.expect.state(child, "enabled", true)
    Helpers.expect.state(child, "active_tab", 1)

    Helpers.expect.state_type(child, "tabs", "table")

    Helpers.expect.state_type(child, "tabs[1].wins", "table")
    Helpers.expect.state_type(child, "tabs[1].wins.main", "table")
    Helpers.expect.state_type(child, "tabs[1].wins.integrations", "table")

    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })

    Helpers.expect.state(child, "tabs[1].wins.columns", 3)

    Helpers.expect.state_type(child, "tabs[1].wins.integrations", "table")

    Helpers.expect.state(child, "tabs[1].wins.integrations", Co.INTEGRATIONS)
end

T["enable"]["(multiple tab) sets state"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()

    -- tab 1
    Helpers.expect.global_type(child, "_G.NoNeckPain.state", "table")

    Helpers.expect.state(child, "enabled", true)
    Helpers.expect.state(child, "active_tab", 1)

    Helpers.expect.state_type(child, "tabs", "table")

    Helpers.expect.state_type(child, "tabs[1].wins", "table")
    Helpers.expect.state_type(child, "tabs[1].wins.main", "table")
    Helpers.expect.state_type(child, "tabs[1].wins.integrations", "table")

    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })
    Helpers.expect.state(child, "tabs[1].wins.columns", 3)

    Helpers.expect.state_type(child, "tabs[1].wins.integrations", "table")

    Helpers.expect.state(child, "tabs[1].wins.integrations", Co.INTEGRATIONS)

    -- tab 2
    child.cmd("tabnew")
    child.nnp()

    Helpers.expect.state(child, "enabled", true)
    Helpers.expect.state(child, "active_tab", 2)

    Helpers.expect.state_type(child, "tabs", "table")

    Helpers.expect.state_type(child, "tabs[2].wins", "table")
    Helpers.expect.state_type(child, "tabs[2].wins.main", "table")
    Helpers.expect.state_type(child, "tabs[2].wins.integrations", "table")

    Helpers.expect.state(child, "tabs[2].wins.main", {
        curr = 1003,
        left = 1004,
        right = 1005,
    })
    Helpers.expect.state(child, "tabs[2].wins.columns", 3)

    Helpers.expect.state_type(child, "tabs[2].wins.integrations", "table")

    Helpers.expect.state(child, "tabs[2].wins.integrations", Co.INTEGRATIONS)
end

T["disable"] = MiniTest.new_set()

T["disable"]["(single tab) resets state"] = function()
    child.nnp()

    Helpers.expect.global_type(child, "_G.NoNeckPain.state", "table")

    Helpers.expect.state(child, "enabled", true)
    Helpers.expect.state(child, "active_tab", 1)

    Helpers.expect.state_type(child, "tabs", "table")

    child.nnp()

    Helpers.expect.global_type(child, "_G.NoNeckPain.state", "table")

    Helpers.expect.state(child, "enabled", false)
    Helpers.expect.state(child, "active_tab", 1)

    Helpers.expect.state(child, "tabs", {})
end

T["disable"]["(multiple tab) resets state"] = function()
    child.nnp()

    Helpers.expect.global_type(child, "_G.NoNeckPain.state", "table")

    Helpers.expect.state(child, "enabled", true)
    Helpers.expect.state(child, "active_tab", 1)

    Helpers.expect.state_type(child, "tabs", "table")

    child.cmd("tabnew")
    child.nnp()

    Helpers.expect.global_type(child, "_G.NoNeckPain.state", "table")

    Helpers.expect.state(child, "enabled", true)
    Helpers.expect.state(child, "active_tab", 2)

    Helpers.expect.state_type(child, "tabs", "table")

    -- disable tab 2
    child.nnp()

    Helpers.expect.state(child, "enabled", true)
    Helpers.expect.state(child, "active_tab", 2)

    Helpers.expect.state_type(child, "tabs", "table")

    -- disable tab 1
    child.cmd("tabprevious")
    child.nnp()

    Helpers.expect.state(child, "enabled", false)
    Helpers.expect.state(child, "active_tab", 1)

    Helpers.expect.state(child, "tabs", {})
end

T["disable"]["(no file) does not close the window if unsaved buffer"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()

    Helpers.expect.state(child, "enabled", true)
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })
    Helpers.expect.equality(child.list_buffers(), { 1, 2, 3 })

    child.api.nvim_buf_set_lines(1, 0, 1, false, { "foo" })
    Helpers.expect.equality(child.lua_get("vim.api.nvim_buf_get_option(1, 'modified')"), true)

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })
    Helpers.expect.equality(child.lua_get("vim.api.nvim_get_current_win()"), 1000)

    child.cmd("quit")

    Helpers.expect.equality(child.is_running(), true)
end

T["disable"]["(on file) does not close the window if unsaved buffer"] = function()
    child.restart({ "-u", "scripts/minimal_init.lua", "lua/no-neck-pain/main.lua" })
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()

    Helpers.expect.state(child, "enabled", true)
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })
    Helpers.expect.equality(child.list_buffers(), { 1, 2, 3 })

    child.api.nvim_buf_set_lines(1, 0, 1, false, { "foo" })
    Helpers.expect.equality(child.lua_get("vim.api.nvim_buf_get_option(1, 'modified')"), true)

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })
    Helpers.expect.equality(child.lua_get("vim.api.nvim_get_current_win()"), 1000)

    child.cmd("quit")

    Helpers.expect.equality(child.is_running(), true)
end

T["disable"]["relative window doesn't prevent quitting nvim"] = function()
    child.restart({ "-u", "scripts/init_with_incline.lua" })
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()

    Helpers.expect.state(child, "enabled", true)
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1003,
        right = 1004,
    })
    Helpers.expect.equality(child.get_wins_in_tab(), { 1003, 1000, 1004, 1002 })
    vim.fn.win_gotoid(1000)

    child.cmd("quit")

    Helpers.expect.error(function()
        -- error because instance is closed
        Helpers.expect.equality(child.get_wins_in_tab(), { 1003, 1000, 1004, 1002 })
    end)
end

return T
