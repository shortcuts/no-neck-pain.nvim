local helpers = dofile("tests/helpers.lua")
local Co = require("no-neck-pain.util.constants")

local child = helpers.new_child_neovim()
local eq, eq_config, eq_state, eq_buf_width =
    helpers.expect.equality,
    helpers.expect.config_equality,
    helpers.expect.state_equality,
    helpers.expect.buf_width_equality
local eq_type_config = helpers.expect.config_type_equality

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
            setNames = true,
            bo = {
                filetype = "my-file-type",
                buftype = "help",
                bufhidden = "",
                buflisted = true,
                swapfile = true,
            },
            wo = {
                cursorline = true,
                cursorcolumn = true,
                colorcolumn = "90",
                number = true,
                relativenumber = true,
                foldenable = true,
                list = true,
                wrap = false,
                linebreak = false,
            },
            left = {
                bo = {
                    filetype = "my-file-type",
                    buftype = "help",
                    bufhidden = "",
                    buflisted = true,
                    swapfile = true,
                },
                wo = {
                    cursorline = true,
                    cursorcolumn = true,
                    colorcolumn = "30",
                    number = true,
                    relativenumber = true,
                    foldenable = true,
                    list = true,
                    wrap = false,
                    linebreak = false,
                },
            },
            right = {
                bo = {
                    filetype = "my-file-type",
                    buftype = "help",
                    bufhidden = "",
                    buflisted = true,
                    swapfile = true,
                },
                wo = {
                    cursorline = true,
                    cursorcolumn = true,
                    colorcolumn = "30",
                    number = true,
                    relativenumber = true,
                    foldenable = true,
                    list = true,
                    wrap = false,
                    linebreak = false,
                },
            },
        },
    })]])

    eq_type_config(child, "buffers", "table")
    eq_type_config(child, "buffers.bo", "table")
    eq_type_config(child, "buffers.wo", "table")

    eq_config(child, "buffers.setNames", true)

    eq_config(child, "buffers.bo.filetype", "my-file-type")
    eq_config(child, "buffers.bo.buftype", "help")
    eq_config(child, "buffers.bo.bufhidden", "")
    eq_config(child, "buffers.bo.buflisted", true)
    eq_config(child, "buffers.bo.swapfile", true)

    eq_config(child, "buffers.wo.cursorline", true)
    eq_config(child, "buffers.wo.cursorcolumn", true)
    eq_config(child, "buffers.wo.colorcolumn", "90")
    eq_config(child, "buffers.wo.number", true)
    eq_config(child, "buffers.wo.relativenumber", true)
    eq_config(child, "buffers.wo.foldenable", true)
    eq_config(child, "buffers.wo.list", true)
    eq_config(child, "buffers.wo.wrap", false)
    eq_config(child, "buffers.wo.linebreak", false)

    for _, scope in pairs(Co.SIDES) do
        eq_config(child, "buffers." .. scope .. ".bo.filetype", "my-file-type")
        eq_config(child, "buffers." .. scope .. ".bo.buftype", "help")
        eq_config(child, "buffers." .. scope .. ".bo.bufhidden", "")
        eq_config(child, "buffers." .. scope .. ".bo.buflisted", true)
        eq_config(child, "buffers." .. scope .. ".bo.swapfile", true)

        eq_config(child, "buffers." .. scope .. ".wo.cursorline", true)
        eq_config(child, "buffers." .. scope .. ".wo.cursorcolumn", true)
        eq_config(child, "buffers." .. scope .. ".wo.colorcolumn", "30")
        eq_config(child, "buffers." .. scope .. ".wo.number", true)
        eq_config(child, "buffers." .. scope .. ".wo.relativenumber", true)
        eq_config(child, "buffers." .. scope .. ".wo.foldenable", true)
        eq_config(child, "buffers." .. scope .. ".wo.list", true)
        eq_config(child, "buffers." .. scope .. ".wo.wrap", false)
        eq_config(child, "buffers." .. scope .. ".wo.linebreak", false)
    end
end

T["setup"]["`left` or `right` buffer options overrides `common` ones"] = function()
    child.lua([[require('no-neck-pain').setup({
        buffers = {
            bo = {
                filetype = "TEST",
            },
            wo = {
                cursorline = false,
            },
            left = {
                bo = {
                    filetype = "TEST-left",
                },
                wo = {
                    cursorline = true,
                },
            },
            right = {
                bo = {
                    filetype = "TEST-right",
                },
                wo = {
                    number = true,
                },
            },
        },
    })]])

    eq_config(child, "buffers.bo.filetype", "TEST")
    eq_config(child, "buffers.wo.cursorline", false)

    eq_config(child, "buffers.left.bo.filetype", "TEST-left")
    eq_config(child, "buffers.right.bo.filetype", "TEST-right")

    eq_config(child, "buffers.left.wo.cursorline", true)
    eq_config(child, "buffers.right.wo.number", true)
end

T["setup"]["`common` options spreads it to `left` and `right` buffers"] = function()
    child.lua([[require('no-neck-pain').setup({
        buffers = {
            bo = {
                filetype = "TEST",
            },
            wo = {
                number = true,
            },
        },
    })]])

    eq_config(child, "buffers.bo.filetype", "TEST")
    eq_config(child, "buffers.wo.number", true)

    eq_config(child, "buffers.left.wo.number", true)
    eq_config(child, "buffers.right.wo.number", true)

    eq_config(child, "buffers.left.bo.filetype", "TEST")
    eq_config(child, "buffers.right.bo.filetype", "TEST")
end

T["curr"] = MiniTest.new_set()

T["curr"]["have the default width"] = function()
    child.lua([[
        require('no-neck-pain').setup()
        require('no-neck-pain').enable()
    ]])

    -- need to know why the child isn't precise enough
    eq_buf_width(child, "tabs[1].wins.main.curr", 80)
end

T["curr"]["have the width from the config"] = function()
    child.lua([[
        require('no-neck-pain').setup({width=50})
        require('no-neck-pain').enable()
    ]])

    -- need to know why the child isn't precise enough
    eq_buf_width(child, "tabs[1].wins.main.curr", 48)
end

T["curr"]["closing `curr` window without any other window quits Neovim"] = function()
    child.lua([[
        require('no-neck-pain').setup({width=50})
        require('no-neck-pain').enable()
    ]])

    eq(helpers.winsInTab(child), { 1001, 1000, 1002 })
    eq_state(child, "tabs[1].wins.main.curr", 1000)

    child.cmd("q")

    -- neovim is closed, so it errors
    helpers.expect.error(function()
        helpers.winsInTab(child)
    end)
end

T["left/right"] = MiniTest.new_set()

T["left/right"]["setNames doesn't throw when re-creating side buffers"] = function()
    child.lua([[require('no-neck-pain').setup({width=50, buffers={setNames=true}})]])

    -- enable
    child.cmd([[NoNeckPain]])

    eq_buf_width(child, "tabs[1].wins.main.left", 15)
    eq_buf_width(child, "tabs[1].wins.main.right", 15)

    -- toggle
    child.cmd([[NoNeckPain]])
    child.cmd([[NoNeckPain]])

    eq_buf_width(child, "tabs[1].wins.main.left", 15)
    eq_buf_width(child, "tabs[1].wins.main.right", 15)
end

T["left/right"]["have the same width"] = function()
    child.lua([[
        require('no-neck-pain').setup({width=50})
        require('no-neck-pain').enable()
    ]])

    eq_buf_width(child, "tabs[1].wins.main.left", 15)
    eq_buf_width(child, "tabs[1].wins.main.right", 15)
end

T["left/right"]["only creates a `left` buffer when `right.enabled` is `false`"] = function()
    child.lua([[
        require('no-neck-pain').setup({width=50,buffers={right={enabled=false}}})
        require('no-neck-pain').enable()
    ]])

    eq_state(child, "tabs[1].wins.main.left", 1001)
    eq_state(child, "tabs[1].wins.main.right", vim.NIL)

    eq_buf_width(child, "tabs[1].wins.main.left", 15)
end

T["left/right"]["only creates a `right` buffer when `left.enabled` is `false`"] = function()
    child.lua([[
        require('no-neck-pain').setup({width=50,buffers={left={enabled=false}}})
        require('no-neck-pain').enable()
    ]])

    eq_state(child, "tabs[1].wins.main.left", vim.NIL)
    eq_state(child, "tabs[1].wins.main.right", 1001)

    eq_buf_width(child, "tabs[1].wins.main.right", 15)
end

T["left/right"]["closing the `left` buffer disables NNP"] = function()
    child.lua([[
        require('no-neck-pain').setup({width=50})
        require('no-neck-pain').enable()
    ]])

    eq(helpers.winsInTab(child), { 1001, 1000, 1002 })
    eq_state(child, "tabs[1].wins.main.left", 1001)
    eq_state(child, "tabs[1].wins.main.right", 1002)

    child.lua("vim.fn.win_gotoid(_G.NoNeckPain.state.tabs[1].wins.main.left)")
    child.cmd("q")

    eq(helpers.winsInTab(child), { 1000 })
end

T["left/right"]["closing the `right` buffer disables NNP"] = function()
    child.lua([[
        require('no-neck-pain').setup({width=50})
        require('no-neck-pain').enable()
    ]])

    eq(helpers.winsInTab(child), { 1001, 1000, 1002 })
    eq_state(child, "tabs[1].wins.main.left", 1001)
    eq_state(child, "tabs[1].wins.main.right", 1002)

    child.lua("vim.fn.win_gotoid(_G.NoNeckPain.state.tabs[1].wins.main.right)")
    child.cmd("q")

    eq(helpers.winsInTab(child), { 1000 })
end

return T
