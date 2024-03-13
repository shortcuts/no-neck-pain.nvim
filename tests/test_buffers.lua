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

    Helpers.expect.config_type_equality(child, "buffers", "table")
    Helpers.expect.config_type_equality(child, "buffers.bo", "table")
    Helpers.expect.config_type_equality(child, "buffers.wo", "table")

    Helpers.expect.config_equality(child, "buffers.setNames", true)

    Helpers.expect.config_equality(child, "buffers.bo", {
        bufhidden = "",
        buflisted = true,
        buftype = "help",
        filetype = "my-file-type",
        swapfile = true,
    })

    Helpers.expect.config_equality(child, "buffers.wo", {
        colorcolumn = "90",
        cursorcolumn = true,
        cursorline = true,
        foldenable = true,
        linebreak = false,
        list = true,
        number = true,
        relativenumber = true,
        wrap = false,
    })

    for _, scope in pairs(Co.SIDES) do
        Helpers.expect.config_equality(child, "buffers." .. scope .. ".bo", {
            bufhidden = "",
            buflisted = true,
            buftype = "help",
            filetype = "my-file-type",
            swapfile = true,
        })

        Helpers.expect.config_equality(child, "buffers." .. scope .. ".wo", {
            colorcolumn = "30",
            cursorcolumn = true,
            cursorline = true,
            foldenable = true,
            linebreak = false,
            list = true,
            number = true,
            relativenumber = true,
            wrap = false,
        })
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

    Helpers.expect.config_equality(child, "buffers.bo.filetype", "TEST")
    Helpers.expect.config_equality(child, "buffers.wo.cursorline", false)

    Helpers.expect.config_equality(child, "buffers.left.bo.filetype", "TEST-left")
    Helpers.expect.config_equality(child, "buffers.right.bo.filetype", "TEST-right")

    Helpers.expect.config_equality(child, "buffers.left.wo.cursorline", true)
    Helpers.expect.config_equality(child, "buffers.right.wo.number", true)
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

    Helpers.expect.config_equality(child, "buffers.bo.filetype", "TEST")
    Helpers.expect.config_equality(child, "buffers.wo.number", true)

    Helpers.expect.config_equality(child, "buffers.left.wo.number", true)
    Helpers.expect.config_equality(child, "buffers.right.wo.number", true)

    Helpers.expect.config_equality(child, "buffers.left.bo.filetype", "TEST")
    Helpers.expect.config_equality(child, "buffers.right.bo.filetype", "TEST")
end

T["curr"] = MiniTest.new_set()

T["curr"]["have the default width"] = function()
    child.lua([[
        require('no-neck-pain').setup()
        require('no-neck-pain').enable()
    ]])

    -- need to know why the child isn't precise enough
    Helpers.expect.buf_width_equality(child, "tabs[1].wins.main.curr", 80)
end

T["curr"]["have the width from the config"] = function()
    child.lua([[
        require('no-neck-pain').setup({width=50})
        require('no-neck-pain').enable()
    ]])

    -- need to know why the child isn't precise enough
    Helpers.expect.buf_width_equality(child, "tabs[1].wins.main.curr", 48)
end

T["curr"]["closing `curr` window without any other window quits Neovim"] = function()
    child.lua([[
        require('no-neck-pain').setup({width=50})
        require('no-neck-pain').enable()
    ]])

    Helpers.expect.equality(Helpers.winsInTab(child), { 1001, 1000, 1002 })
    Helpers.expect.state_equality(child, "tabs[1].wins.main.curr", 1000)

    child.cmd("q")

    -- neovim is closed, so it errors
    Helpers.expect.error(function()
        helpers.winsInTab(child)
    end)
end

T["left/right"] = MiniTest.new_set()

T["left/right"]["setNames doesn't throw when re-creating side buffers"] = function()
    child.lua([[require('no-neck-pain').setup({width=50, buffers={setNames=true}})]])

    -- enable
    child.cmd([[NoNeckPain]])

    Helpers.expect.buf_width_equality(child, "tabs[1].wins.main.left", 15)
    Helpers.expect.buf_width_equality(child, "tabs[1].wins.main.right", 15)

    -- toggle
    child.cmd([[NoNeckPain]])
    child.cmd([[NoNeckPain]])

    Helpers.expect.buf_width_equality(child, "tabs[1].wins.main.left", 15)
    Helpers.expect.buf_width_equality(child, "tabs[1].wins.main.right", 15)
end

T["left/right"]["have the same width"] = function()
    child.lua([[
        require('no-neck-pain').setup({width=50})
        require('no-neck-pain').enable()
    ]])

    Helpers.expect.buf_width_equality(child, "tabs[1].wins.main.left", 15)
    Helpers.expect.buf_width_equality(child, "tabs[1].wins.main.right", 15)
end

T["left/right"]["only creates a `left` buffer when `right.enabled` is `false`"] = function()
    child.lua([[
        require('no-neck-pain').setup({width=50,buffers={right={enabled=false}}})
        require('no-neck-pain').enable()
    ]])

    Helpers.expect.state_equality(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
    })

    Helpers.expect.buf_width_equality(child, "tabs[1].wins.main.left", 15)
end

T["left/right"]["only creates a `right` buffer when `left.enabled` is `false`"] = function()
    child.lua([[
        require('no-neck-pain').setup({width=50,buffers={left={enabled=false}}})
        require('no-neck-pain').enable()
    ]])

    Helpers.expect.state_equality(child, "tabs[1].wins.main", {
        curr = 1000,
        right = 1001,
    })

    Helpers.expect.buf_width_equality(child, "tabs[1].wins.main.right", 15)
end

T["left/right"]["closing the `left` buffer disables NNP"] = function()
    child.lua([[
        require('no-neck-pain').setup({width=50})
        require('no-neck-pain').enable()
    ]])

    Helpers.expect.equality(Helpers.winsInTab(child), { 1001, 1000, 1002 })
    Helpers.expect.state_equality(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })

    child.lua("vim.fn.win_gotoid(_G.NoNeckPain.state.tabs[1].wins.main.left)")
    child.cmd("q")

    Helpers.expect.equality(Helpers.winsInTab(child), { 1000 })
end

T["left/right"]["closing the `right` buffer disables NNP"] = function()
    child.lua([[
        require('no-neck-pain').setup({width=50})
        require('no-neck-pain').enable()
    ]])

    Helpers.expect.equality(Helpers.winsInTab(child), { 1001, 1000, 1002 })
    Helpers.expect.state_equality(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })

    child.lua("vim.fn.win_gotoid(_G.NoNeckPain.state.tabs[1].wins.main.right)")
    child.cmd("q")

    Helpers.expect.equality(Helpers.winsInTab(child), { 1000 })
end

return T
