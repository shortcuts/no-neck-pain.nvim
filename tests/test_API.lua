local helpers = dofile("tests/helpers.lua")

local child = helpers.new_child_neovim()
local eq_global, eq_option, eq_state =
    helpers.expect.global_equality, helpers.expect.option_equality, helpers.expect.state_equality
local eq_type_global, eq_type_option, eq_type_state =
    helpers.expect.global_type_equality,
    helpers.expect.option_type_equality,
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

T["install"]["sets global loaded variable and provide toggle command"] = function()
    eq_type_global(child, "_G.NoNeckPainLoaded", "boolean")
    eq_global(child, "_G.NoNeckPain", vim.NIL)

    child.cmd("NoNeckPain")
    eq_state(child, "enabled", true)

    child.cmd("NoNeckPain")
    eq_state(child, "enabled", false)
end

T["setup()"] = MiniTest.new_set()

T["setup()"]["sets exposed methods and default options value"] = function()
    child.lua([[require('no-neck-pain').setup()]])

    eq_type_global(child, "_G.NoNeckPain", "table")

    -- public methods
    eq_type_global(child, "_G.NoNeckPain.toggle", "function")
    eq_type_global(child, "_G.NoNeckPain.enable", "function")
    eq_type_global(child, "_G.NoNeckPain.setup", "function")

    -- options
    eq_type_global(child, "_G.NoNeckPain.config", "table")

    eq_type_option(child, "buffers", "table")
    eq_type_option(child, "buffers.background", "table")
    eq_type_option(child, "buffers.options", "table")
    eq_type_option(child, "buffers.options.bo", "table")
    eq_type_option(child, "buffers.options.wo", "table")

    eq_option(child, "width", 100)
    eq_option(child, "debug", false)
    eq_option(child, "disableOnLastBuffer", false)
    eq_option(child, "killAllBuffersOnDisable", false)
    eq_option(child, "buffers.left", true)
    eq_option(child, "buffers.right", true)
    eq_option(child, "buffers.showName", false)

    eq_option(child, "buffers.background.colorCode", vim.NIL)

    eq_option(child, "buffers.options.bo.filetype", "no-neck-pain")
    eq_option(child, "buffers.options.bo.buftype", "nofile")
    eq_option(child, "buffers.options.bo.bufhidden", "hide")
    eq_option(child, "buffers.options.bo.modifiable", false)
    eq_option(child, "buffers.options.bo.buflisted", false)
    eq_option(child, "buffers.options.bo.swapfile", false)

    eq_option(child, "buffers.options.wo.cursorline", false)
    eq_option(child, "buffers.options.wo.cursorcolumn", false)
    eq_option(child, "buffers.options.wo.number", false)
    eq_option(child, "buffers.options.wo.relativenumber", false)
    eq_option(child, "buffers.options.wo.foldenable", false)
    eq_option(child, "buffers.options.wo.list", false)
end

T["setup()"]["overrides default values"] = function()
    child.lua([[require('no-neck-pain').setup({
        width = 42,
        debug = true,
        disableOnLastBuffer = true,
        killAllBuffersOnDisable = true,
        buffers = {
            background = {
                colorCode = "#2E1E2E"
            },
            left = false,
            right = false,
            showName = true,
            options = {
                bo = {
                    filetype = "my-file-type",
                    buftype = "help",
                    bufhidden = "",
                    modifiable = true,
                    buflisted = true,
                    swapfile = true,
                },
                wo = {
                    cursorline = true,
                    cursorcolumn = true,
                    number = true,
                    relativenumber = true,
                    foldenable = true,
                    list = true,
                },
            },
        },
    })]])

    eq_option(child, "width", 42)
    eq_option(child, "debug", true)
    eq_option(child, "disableOnLastBuffer", true)
    eq_option(child, "killAllBuffersOnDisable", true)
    eq_option(child, "buffers.left", false)
    eq_option(child, "buffers.right", false)
    eq_option(child, "buffers.showName", true)

    eq_option(child, "buffers.background.colorCode", "#2E1E2E")

    eq_option(child, "buffers.options.bo.filetype", "my-file-type")
    eq_option(child, "buffers.options.bo.buftype", "help")
    eq_option(child, "buffers.options.bo.bufhidden", "")
    eq_option(child, "buffers.options.bo.modifiable", true)
    eq_option(child, "buffers.options.bo.buflisted", true)
    eq_option(child, "buffers.options.bo.swapfile", true)

    eq_option(child, "buffers.options.wo.cursorline", true)
    eq_option(child, "buffers.options.wo.cursorcolumn", true)
    eq_option(child, "buffers.options.wo.number", true)
    eq_option(child, "buffers.options.wo.relativenumber", true)
    eq_option(child, "buffers.options.wo.foldenable", true)
    eq_option(child, "buffers.options.wo.list", true)
end

T["setup()"]["colorCode: map integration name to a value"] = function()
    local integrationsMapping = {
        { "catppuccin-frappe", "#303446" },
        { "catppuccin-latte", "#EFF1F5" },
        { "catppuccin-macchiato", "#24273A" },
        { "catppuccin-mocha", "#1E1E2E" },
        { "tokyonight-day", "#16161e" },
        { "tokyonight-moon", "#1e2030" },
        { "tokyonight-storm", "#1f2335" },
        { "tokyonight-night", "#16161e" },
        { "rose-pine", "#191724" },
        { "rose-pine-moon", "#232136" },
        { "rose-pine-dawn", "#faf4ed" },
    }

    for _, integration in pairs(integrationsMapping) do
        child.lua(string.format(
            [[require('no-neck-pain').setup({
                buffers = {
                    background = {
                        colorCode = "%s"
                    },
                },
            })]],
            integration[1]
        ))
        eq_option(child, "buffers.background.colorCode", integration[2])
    end
end

T["enable()"] = MiniTest.new_set()

T["enable()"]["sets state and internal methods"] = function()
    child.lua([[
        require('no-neck-pain').setup({width=50})
        require('no-neck-pain').enable()
    ]])

    -- internal methods
    eq_type_global(child, "_G.NoNeckPain.internal.toggle", "function")
    eq_type_global(child, "_G.NoNeckPain.internal.enable", "function")
    eq_type_global(child, "_G.NoNeckPain.internal.disable", "function")

    -- state
    eq_type_global(child, "_G.NoNeckPain.state", "table")

    eq_state(child, "enabled", true)
    eq_state(child, "augroup", 15)

    eq_type_state(child, "win", "table")

    eq_state(child, "win.curr", 1000)
    eq_state(child, "win.left", 1001)
    eq_state(child, "win.right", 1002)
    eq_state(child, "win.split", vim.NIL)
end

T["disable()"] = MiniTest.new_set()

T["disable()"]["resets state and remove internal methods"] = function()
    child.lua([[require('no-neck-pain').disable()]])

    -- state
    eq_type_global(child, "_G.NoNeckPain.state", "table")

    eq_state(child, "enabled", false)
    eq_state(child, "augroup", vim.NIL)

    eq_type_state(child, "win", "table")

    eq_state(child, "win.curr", vim.NIL)
    eq_state(child, "win.left", vim.NIL)
    eq_state(child, "win.right", vim.NIL)
    eq_state(child, "win.split", vim.NIL)
end

T["toggle()"] = MiniTest.new_set()

T["toggle()"]["sets state and internal methods and resets everything when toggled again"] =
    function()
        child.lua([[
        require('no-neck-pain').setup({width=50})
        require('no-neck-pain').enable()
    ]])

        -- internal methods
        eq_type_global(child, "_G.NoNeckPain.internal.toggle", "function")
        eq_type_global(child, "_G.NoNeckPain.internal.enable", "function")
        eq_type_global(child, "_G.NoNeckPain.internal.disable", "function")

        -- state
        eq_type_global(child, "_G.NoNeckPain.state", "table")

        eq_state(child, "enabled", true)
        eq_state(child, "augroup", 15)

        eq_type_state(child, "win", "table")

        eq_state(child, "win.curr", 1000)
        eq_state(child, "win.left", 1001)
        eq_state(child, "win.right", 1002)
        eq_state(child, "win.split", vim.NIL)

        -- disable
        child.lua([[require('no-neck-pain').toggle()]])

        -- state
        eq_type_state(child, "win", "table")

        eq_state(child, "enabled", false)
        eq_state(child, "augroup", vim.NIL)

        eq_type_state(child, "win", "table")

        eq_state(child, "win.curr", vim.NIL)
        eq_state(child, "win.left", vim.NIL)
        eq_state(child, "win.right", vim.NIL)
        eq_state(child, "win.split", vim.NIL)
    end

return T
