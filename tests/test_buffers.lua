local Helpers = dofile("tests/helpers.lua")
local Co = require("no-neck-pain.util.constants")

local child = Helpers.new_child_neovim()

local T = MiniTest.new_set({
    hooks = {
        pre_case = function()
            child.restart({ "-u", "scripts/minimal_init.lua" })
            child.set_size(10, 200)
        end,
        post_once = child.stop,
    },
})

-- =============================================================================
-- GROUP 1: Setup Tests
-- =============================================================================

T["Setup: sets default filetypes"] = function()
    child.lua([[require('no-neck-pain').setup({width=30})]])
    child.nnp()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })

    Helpers.expect.equality(
        child.lua_get("vim.api.nvim_buf_get_option(vim.api.nvim_win_get_buf(1001), 'filetype')"),
        "no-neck-pain"
    )

    Helpers.expect.equality(
        child.lua_get("vim.api.nvim_buf_get_option(vim.api.nvim_win_get_buf(1002), 'filetype')"),
        "no-neck-pain"
    )
end

T["Setup: overrides default values"] = function()
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

    Helpers.expect.config_type(child, "buffers", "table")
    Helpers.expect.config_type(child, "buffers.bo", "table")
    Helpers.expect.config_type(child, "buffers.wo", "table")

    Helpers.expect.config(child, "buffers.setNames", true)

    Helpers.expect.config(child, "buffers.bo", {
        bufhidden = "",
        buflisted = true,
        buftype = "help",
        filetype = "my-file-type",
        swapfile = true,
    })

    Helpers.expect.config(child, "buffers.wo", {
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
        Helpers.expect.config(child, "buffers." .. scope .. ".bo", {
            bufhidden = "",
            buflisted = true,
            buftype = "help",
            filetype = "my-file-type",
            swapfile = true,
        })

        Helpers.expect.config(child, "buffers." .. scope .. ".wo", {
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

T["Setup: left or right buffer options overrides common ones"] = function()
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

    Helpers.expect.config(child, "buffers.bo.filetype", "TEST")
    Helpers.expect.config(child, "buffers.wo.cursorline", false)

    Helpers.expect.config(child, "buffers.left.bo.filetype", "TEST-left")
    Helpers.expect.config(child, "buffers.right.bo.filetype", "TEST-right")

    Helpers.expect.config(child, "buffers.left.wo.cursorline", true)
    Helpers.expect.config(child, "buffers.right.wo.number", true)
end

T["Setup: common options spreads it to left and right buffers"] = function()
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

    Helpers.expect.config(child, "buffers.bo.filetype", "TEST")
    Helpers.expect.config(child, "buffers.wo.number", true)

    Helpers.expect.config(child, "buffers.left.wo.number", true)
    Helpers.expect.config(child, "buffers.right.wo.number", true)

    Helpers.expect.config(child, "buffers.left.bo.filetype", "TEST")
    Helpers.expect.config(child, "buffers.right.bo.filetype", "TEST")
end

-- =============================================================================
-- GROUP 2: Current Window Tests
-- =============================================================================

T["Curr: have the default width"] = function()
    child.lua([[ require('no-neck-pain').setup() ]])
    child.nnp()

    Helpers.expect.buf_width(child, "tabs[1].wins.main.curr", 80)
end

T["Curr: have the width from the config"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()

    Helpers.expect.buf_width_in_range(child, "_G.NoNeckPain.state.tabs[1].wins.main.curr", 46, 48)
end

T["Curr: closing curr window without any other window quits Neovim"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })
    Helpers.expect.state(child, "tabs[1].wins.main.curr", 1000)

    child.cmd("q")

    Helpers.expect.error(function()
        child.get_wins_in_tab()
    end)
end

-- =============================================================================
-- GROUP 3: Left/Right Side Buffer Tests
-- =============================================================================

T["Left/Right: setNames doesn't throw when re-creating side buffers"] = function()
    child.lua([[require('no-neck-pain').setup({width=50, buffers={setNames=true}})]])

    child.nnp()

    Helpers.expect.buf_width_in_range(child, "_G.NoNeckPain.state.tabs[1].wins.main.left", 13, 15)
    Helpers.expect.buf_width_in_range(child, "_G.NoNeckPain.state.tabs[1].wins.main.right", 13, 15)

    child.nnp()
    child.nnp()

    Helpers.expect.buf_width_in_range(child, "_G.NoNeckPain.state.tabs[1].wins.main.left", 13, 15)
    Helpers.expect.buf_width_in_range(child, "_G.NoNeckPain.state.tabs[1].wins.main.right", 13, 15)
end

T["Left/Right: have the same width"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()

    Helpers.expect.buf_width_in_range(child, "_G.NoNeckPain.state.tabs[1].wins.main.left", 13, 15)
    Helpers.expect.buf_width_in_range(child, "_G.NoNeckPain.state.tabs[1].wins.main.right", 13, 15)
end

T["Left/Right: only creates a left buffer when right.enabled is false"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50,buffers={right={enabled=false}}}) ]])
    child.nnp()

    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
    })

    Helpers.expect.buf_width(child, "tabs[1].wins.main.left", 15)
end

T["Left/Right: only creates a right buffer when left.enabled is false"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50,buffers={left={enabled=false}}}) ]])
    child.nnp()

    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        right = 1001,
    })

    Helpers.expect.buf_width(child, "tabs[1].wins.main.right", 15)
end

T["Left/Right: closing the left buffer disables NNP"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })

    child.lua("vim.fn.win_gotoid(_G.NoNeckPain.state.tabs[1].wins.main.left)")
    child.cmd("q")

    Helpers.expect.equality(child.get_wins_in_tab(), { 1000 })
end

T["Left/Right: closing the right buffer disables NNP"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })

    child.lua("vim.fn.win_gotoid(_G.NoNeckPain.state.tabs[1].wins.main.right)")
    child.cmd("q")

    Helpers.expect.equality(child.get_wins_in_tab(), { 1000 })
end

-- =============================================================================
-- GROUP 4: Boundary Tests
-- =============================================================================

T["Boundary: side buffers when terminal width exactly equals config width"] = function()
    child.set_size(24, 100)
    child.lua([[ require('no-neck-pain').setup({width=100}) ]])
    child.nnp()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1000 })
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
    })
end

T["Boundary: side buffer with very long colorcolumn value"] = function()
    child.lua([[require('no-neck-pain').setup({
        width=50,
        buffers={
            wo={
                colorcolumn=">100,120,+1",
            },
        },
    })]])

    Helpers.expect.config(child, "buffers.wo.colorcolumn", ">100,120,+1")
    Helpers.expect.config(child, "buffers.left.wo.colorcolumn", ">100,120,+1")
    Helpers.expect.config(child, "buffers.right.wo.colorcolumn", ">100,120,+1")

    child.nnp()

    local wins = child.get_wins_in_tab()
    if #wins >= 2 then
        Helpers.expect.state_type(child, "tabs[1].wins.main.left", "number")
    end
end

T["Boundary: side buffer with empty filetype string"] = function()
    child.lua([[require('no-neck-pain').setup({
        width=50,
        buffers={
            bo={
                filetype="",
            },
        },
    })]])
    child.nnp()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })

    local left_ft =
        child.lua_get("vim.api.nvim_buf_get_option(vim.api.nvim_win_get_buf(1001), 'filetype')")
    local right_ft =
        child.lua_get("vim.api.nvim_buf_get_option(vim.api.nvim_win_get_buf(1002), 'filetype')")

    Helpers.expect.equality(left_ft, "")
    Helpers.expect.equality(right_ft, "")
end

T["Boundary: minSideBufferWidth with only 1 column available per side"] = function()
    child.set_size(24, 102)
    child.lua([[ require('no-neck-pain').setup({width=98, minSideBufferWidth=1}) ]])
    child.nnp()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })
    Helpers.expect.state_type(child, "tabs[1].wins.main.left", "number")
    Helpers.expect.state_type(child, "tabs[1].wins.main.right", "number")
end

T["Boundary: minSideBufferWidth prevents creation when below threshold"] = function()
    child.set_size(24, 110)
    child.lua([[ require('no-neck-pain').setup({width=100, minSideBufferWidth=10}) ]])
    child.nnp()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1000 })
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
    })
end

-- =============================================================================
-- GROUP 5: Property-Based Tests
-- =============================================================================

T["Property-Based: side buffer options work across different width configs"] = function()
    local configs = Helpers.generate_width_configs(40, 90, 5)

    for _, config in ipairs(configs) do
        child.restart({ "-u", "scripts/minimal_init.lua" })

        child.lua(string.format(
            [[
            require('no-neck-pain').setup({
                width=%d,
                minSideBufferWidth=%d,
                buffers={
                    wo={
                        number=true,
                        relativenumber=true,
                    },
                },
            })
        ]],
            config.width,
            config.minSideBufferWidth
        ))

        child.nnp()

        local wins = child.get_wins_in_tab()

        if #wins == 3 then
            local left_number = child.lua_get("vim.api.nvim_win_get_option(1001, 'number')")
            local right_number = child.lua_get("vim.api.nvim_win_get_option(1002, 'number')")
            local left_relnumber =
                child.lua_get("vim.api.nvim_win_get_option(1001, 'relativenumber')")
            local right_relnumber =
                child.lua_get("vim.api.nvim_win_get_option(1002, 'relativenumber')")

            Helpers.expect.equality(left_number, true)
            Helpers.expect.equality(right_number, true)
            Helpers.expect.equality(left_relnumber, true)
            Helpers.expect.equality(right_relnumber, true)
        end
    end
end

T["Property-Based: state consistency maintained with property-based configs"] = function()
    local configs = Helpers.generate_width_configs(50, 100, 3)

    for _, config in ipairs(configs) do
        child.restart({ "-u", "scripts/minimal_init.lua" })

        child.lua(string.format(
            [[
            require('no-neck-pain').setup({
                width=%d,
                minSideBufferWidth=%d,
            })
        ]],
            config.width,
            config.minSideBufferWidth
        ))

        child.nnp()
        child.wait()

        Helpers.assert_state_consistency(child)
    end
end

-- =============================================================================
-- GROUP 6: Edge Cases
-- =============================================================================

T["Edge-Cases: side buffers with all window options disabled"] = function()
    child.lua([[require('no-neck-pain').setup({
        width=50,
        buffers={
            wo={
                cursorline=false,
                cursorcolumn=false,
                colorcolumn="0",
                number=false,
                relativenumber=false,
                foldenable=false,
                list=false,
                wrap=false,
                linebreak=false,
            },
        },
    })]])
    child.nnp()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })

    local left_win = 1001
    Helpers.expect.equality(
        child.lua_get("vim.api.nvim_win_get_option(" .. left_win .. ", 'cursorline')"),
        false
    )
    Helpers.expect.equality(
        child.lua_get("vim.api.nvim_win_get_option(" .. left_win .. ", 'cursorcolumn')"),
        false
    )
    Helpers.expect.equality(
        child.lua_get("vim.api.nvim_win_get_option(" .. left_win .. ", 'number')"),
        false
    )
    Helpers.expect.equality(
        child.lua_get("vim.api.nvim_win_get_option(" .. left_win .. ", 'relativenumber')"),
        false
    )
    Helpers.expect.equality(
        child.lua_get("vim.api.nvim_win_get_option(" .. left_win .. ", 'foldenable')"),
        false
    )
    Helpers.expect.equality(
        child.lua_get("vim.api.nvim_win_get_option(" .. left_win .. ", 'list')"),
        false
    )
    Helpers.expect.equality(
        child.lua_get("vim.api.nvim_win_get_option(" .. left_win .. ", 'wrap')"),
        false
    )
    Helpers.expect.equality(
        child.lua_get("vim.api.nvim_win_get_option(" .. left_win .. ", 'linebreak')"),
        false
    )
end

T["Edge-Cases: side buffers with all buffer options modified"] = function()
    child.lua([[require('no-neck-pain').setup({
        width=50,
        buffers={
            bo={
                filetype="custom-type",
                buftype="acwrite",
                bufhidden="wipe",
                buflisted=true,
                swapfile=true,
            },
        },
    })]])
    child.nnp()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })

    local left_buf = child.lua_get("vim.api.nvim_win_get_buf(1001)")
    Helpers.expect.equality(
        child.lua_get("vim.api.nvim_buf_get_option(" .. left_buf .. ", 'filetype')"),
        "custom-type"
    )
    Helpers.expect.equality(
        child.lua_get("vim.api.nvim_buf_get_option(" .. left_buf .. ", 'buftype')"),
        "acwrite"
    )
    Helpers.expect.equality(
        child.lua_get("vim.api.nvim_buf_get_option(" .. left_buf .. ", 'bufhidden')"),
        "wipe"
    )
    Helpers.expect.equality(
        child.lua_get("vim.api.nvim_buf_get_option(" .. left_buf .. ", 'buflisted')"),
        true
    )
    Helpers.expect.equality(
        child.lua_get("vim.api.nvim_buf_get_option(" .. left_buf .. ", 'swapfile')"),
        true
    )
end

T["Edge-Cases: rapid resize operations preserve buffer state"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })

    local left_buf_orig = child.lua_get("vim.api.nvim_win_get_buf(1001)")
    local right_buf_orig = child.lua_get("vim.api.nvim_win_get_buf(1002)")

    for i = 1, 5 do
        local new_size = 100 + (i * 20)
        child.set_size(24, new_size)
        child.wait(50)
    end

    local wins = child.get_wins_in_tab()
    Helpers.expect.equality(#wins, 3)

    Helpers.assert_state_consistency(child)
end

T["Edge-Cases: zero-width colorcolumn edge case"] = function()
    child.lua([[require('no-neck-pain').setup({
        width=50,
        buffers={
            wo={
                colorcolumn="0",
            },
        },
    })]])
    child.nnp()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })

    local left_cc = child.lua_get("vim.api.nvim_win_get_option(1001, 'colorcolumn')")
    Helpers.expect.equality(left_cc, "0")
end

return T
