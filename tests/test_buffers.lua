local helpers = dofile("tests/helpers.lua")

local child = helpers.new_child_neovim()
local eq = helpers.expect.equality
local eq_state, eq_buf_width = helpers.expect.state_equality, helpers.expect.buf_width_equality

local new_set = MiniTest.new_set

local T = new_set({
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

T["curr buffer"] = new_set()

T["curr buffer"]["have the default width"] = function()
    child.lua([[
        require('no-neck-pain').setup()
        require('no-neck-pain').enable()
    ]])

    -- need to know why the child isn't precise enough
    eq_buf_width(child, "main.curr", 80)
end

T["curr buffer"]["have the width from the config"] = function()
    child.lua([[
        require('no-neck-pain').setup({width=50})
        require('no-neck-pain').enable()
    ]])

    -- need to know why the child isn't precise enough
    eq_buf_width(child, "main.curr", 48)
end

T["curr buffer"]["closing `curr` window without any other window quits Neovim"] = function()
    child.lua([[
        require('no-neck-pain').setup({width=50})
        require('no-neck-pain').enable()
    ]])

    eq(child.lua_get("vim.api.nvim_list_wins()"), { 1001, 1000, 1002 })
    eq_state(child, "win.main.curr", 1000)

    child.cmd("q")

    -- neovim is closed, so it errors
    helpers.expect.error(function()
        child.lua_get("vim.api.nvim_list_wins()")
    end)
end

T["side buffers"] = new_set()

T["side buffers"]["have the same width"] = function()
    child.lua([[
        require('no-neck-pain').setup({width=50})
        require('no-neck-pain').enable()
    ]])

    eq_buf_width(child, "main.left", 15)
    eq_buf_width(child, "main.right", 15)
end

T["side buffers"]["only creates a `left` buffer when `right.enabled` is `false`"] = function()
    child.lua([[
        require('no-neck-pain').setup({width=50,buffers={right={enabled=false}}})
        require('no-neck-pain').enable()
    ]])

    eq_state(child, "win.main.left", 1001)
    eq_state(child, "win.main.right", vim.NIL)

    eq_buf_width(child, "main.left", 15)
end

T["side buffers"]["only creates a `right` buffer when `left.enabled` is `false`"] = function()
    child.lua([[
        require('no-neck-pain').setup({width=50,buffers={left={enabled=false}}})
        require('no-neck-pain').enable()
    ]])

    eq_state(child, "win.main.left", vim.NIL)
    eq_state(child, "win.main.right", 1001)

    eq_buf_width(child, "main.right", 15)
end

T["side buffers"]["closing the `left` buffer disables NNP"] = function()
    child.lua([[
        require('no-neck-pain').setup({width=50})
        require('no-neck-pain').enable()
    ]])

    eq(child.lua_get("vim.api.nvim_list_wins()"), { 1001, 1000, 1002 })
    eq_state(child, "win.main.left", 1001)
    eq_state(child, "win.main.right", 1002)

    child.lua("vim.fn.win_gotoid(_G.NoNeckPain.state.win.main.left)")
    child.cmd("q")

    eq(child.lua_get("vim.api.nvim_list_wins()"), { 1000 })

    eq_state(child, "enabled", false)
end

T["side buffers"]["closing the `right` buffer disables NNP"] = function()
    child.lua([[
        require('no-neck-pain').setup({width=50})
        require('no-neck-pain').enable()
    ]])

    eq(child.lua_get("vim.api.nvim_list_wins()"), { 1001, 1000, 1002 })
    eq_state(child, "win.main.left", 1001)
    eq_state(child, "win.main.right", 1002)

    child.lua("vim.fn.win_gotoid(_G.NoNeckPain.state.win.main.right)")
    child.cmd("q")

    eq(child.lua_get("vim.api.nvim_list_wins()"), { 1000 })

    eq_state(child, "enabled", false)
end

T["auto command"] = new_set()

T["auto command"]["does not create side buffers window's width < options.width"] = function()
    child.lua([[
        require('no-neck-pain').setup({width=1000})
        require('no-neck-pain').enable()
    ]])

    eq(child.lua_get("vim.api.nvim_list_wins()"), { 1000 })
    eq_state(child, "win.main.curr", 1000)
    eq_state(child, "win.main.left", vim.NIL)
    eq_state(child, "win.main.right", vim.NIL)
end

T["auto command"]["(split) closing `curr` makes `split` the new `curr`"] = function()
    child.set_size(200, 200)
    child.lua([[
        require('no-neck-pain').setup({width=50})
        require('no-neck-pain').enable()
    ]])

    child.cmd("split")

    eq(child.lua_get("vim.api.nvim_list_wins()"), { 1001, 1003, 1000, 1002 })
    eq_state(child, "win.main.left", 1001)
    eq_state(child, "win.main.right", 1002)
    eq_state(child, "win.main.split", 1003)
    eq_state(child, "win.main.curr", 1000)
    eq_state(child, "vsplit", false)

    child.lua("vim.fn.win_gotoid(_G.NoNeckPain.state.win.main.curr)")
    child.cmd("q")

    eq(child.lua_get("vim.api.nvim_list_wins()"), { 1001, 1003, 1002 })
    eq(child.lua_get("vim.api.nvim_get_current_win()"), 1003)
end

T["auto command"]["(vsplit) closing `curr` makes `split` the new `curr`"] = function()
    child.lua([[
        require('no-neck-pain').setup({width=50})
        require('no-neck-pain').enable()
    ]])

    child.cmd("vsplit")

    eq(child.lua_get("vim.api.nvim_list_wins()"), { 1003, 1000 })
    eq_state(child, "win.main.left", vim.NIL)
    eq_state(child, "win.main.right", vim.NIL)
    eq_state(child, "win.main.split", 1003)
    eq_state(child, "win.main.curr", 1000)
    eq_state(child, "vsplit", true)

    child.lua("vim.fn.win_gotoid(_G.NoNeckPain.state.win.main.curr)")
    child.cmd("q")

    eq(child.lua_get("vim.api.nvim_list_wins()"), { 1004, 1003, 1005 })
    eq(child.lua_get("vim.api.nvim_get_current_win()"), 1003)
end

T["auto command"]["split keeps side buffers"] = function()
    child.set_size(200, 200)
    child.lua([[
        require('no-neck-pain').setup({width=50})
        require('no-neck-pain').enable()
    ]])

    child.cmd("split")

    eq(child.lua_get("vim.api.nvim_list_wins()"), { 1001, 1003, 1000, 1002 })
    eq_state(child, "win.main.left", 1001)
    eq_state(child, "win.main.right", 1002)
    eq_state(child, "win.main.split", 1003)
    eq_state(child, "vsplit", false)

    child.lua("vim.fn.win_gotoid(_G.NoNeckPain.state.win.main.split)")
    child.cmd("q")

    eq(child.lua_get("vim.api.nvim_list_wins()"), { 1001, 1000, 1002 })

    eq_buf_width(child, "main.left", 15)
    eq_buf_width(child, "main.right", 15)
end

T["auto command"]["hides side buffers after vsplit"] = function()
    child.lua([[
        require('no-neck-pain').setup({width=50})
        require('no-neck-pain').enable()
    ]])

    child.cmd("vsplit")

    eq(child.lua_get("vim.api.nvim_list_wins()"), { 1003, 1000 })
    eq_state(child, "win.main.left", vim.NIL)
    eq_state(child, "win.main.right", vim.NIL)
    eq_state(child, "win.main.split", 1003)
    eq_state(child, "vsplit", true)

    child.lua("vim.fn.win_gotoid(_G.NoNeckPain.state.win.main.split)")
    child.cmd("q")

    eq(child.lua_get("vim.api.nvim_list_wins()"), { 1004, 1000, 1005 })
    eq_state(child, "win.main.left", 1004)
    eq_state(child, "win.main.right", 1005)
    eq_state(child, "win.main.split", vim.NIL)
    eq_state(child, "vsplit", false)
end

T["auto command"]["does not shift using when opening/closing float window"] = function()
    child.set_size(200, 200)
    child.lua([[
        require('no-neck-pain').setup({width=50})
        require('no-neck-pain').enable()
    ]])

    eq(child.lua_get("vim.api.nvim_list_wins()"), { 1001, 1000, 1002 })
    eq_state(child, "win.main.left", 1001)
    eq_state(child, "win.main.right", 1002)

    eq_buf_width(child, "main.left", 15)
    eq_buf_width(child, "main.right", 15)

    child.lua("vim.api.nvim_open_win(0,true, {width=100,height=100,relative='cursor',row=0,col=0})")

    eq(child.lua_get("vim.api.nvim_list_wins()"), { 1001, 1000, 1002, 1003 })
    eq_state(child, "win.main.left", 1001)
    eq_state(child, "win.main.right", 1002)

    eq_buf_width(child, "main.left", 15)
    eq_buf_width(child, "main.right", 15)

    -- Close float window keeps the buffer here with the same width
    child.lua("vim.fn.win_gotoid(1003)")
    child.cmd("q")

    eq(child.lua_get("vim.api.nvim_list_wins()"), { 1001, 1000, 1002 })
    eq_state(child, "win.main.left", 1001)
    eq_state(child, "win.main.right", 1002)

    eq_buf_width(child, "main.left", 15)
    eq_buf_width(child, "main.right", 15)
end

return T
