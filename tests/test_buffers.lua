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

T["side buffers"] = new_set()

T["side buffers"]["have the same width"] = function()
    child.lua([[
        require('no-neck-pain').setup({width=50})
        require('no-neck-pain').enable()
    ]])

    eq_buf_width(child, "main.left", 15)
    eq_buf_width(child, "main.right", 15)
end

T["side buffers"]["only creates a `left` buffer when `right` is `false`"] = function()
    child.lua([[
        require('no-neck-pain').setup({width=50,buffers={right=false}})
        require('no-neck-pain').enable()
    ]])

    eq_state(child, "win.main.left", 1001)
    eq_state(child, "win.main.right", vim.NIL)

    eq_buf_width(child, "main.left", 15)
end

T["side buffers"]["only creates a `right` buffer when `left` is `false`"] = function()
    child.lua([[
        require('no-neck-pain').setup({width=50,buffers={left=false}})
        require('no-neck-pain').enable()
    ]])

    eq_state(child, "win.main.left", vim.NIL)
    eq_state(child, "win.main.right", 1001)

    eq_buf_width(child, "main.right", 15)
end

T["side buffers"]["closing the `left` buffer kills the `right one"] = function()
    child.lua([[
        require('no-neck-pain').setup({width=50})
        require('no-neck-pain').enable()
    ]])

    eq(child.lua_get("vim.api.nvim_list_wins()"), { 1001, 1000, 1002 })
    eq_state(child, "win.main.left", 1001)
    eq_state(child, "win.main.right", 1002)

    child.lua("vim.api.nvim_win_close(1002, false)")

    eq(child.lua_get("vim.api.nvim_list_wins()"), { 1000 })
end

T["side buffers"]["closing the `right` buffer kills the `left` one"] = function()
    child.lua([[
        require('no-neck-pain').setup({width=50})
        require('no-neck-pain').enable()
    ]])

    eq(child.lua_get("vim.api.nvim_list_wins()"), { 1001, 1000, 1002 })
    eq_state(child, "win.main.left", 1001)
    eq_state(child, "win.main.right", 1002)

    child.lua("vim.api.nvim_win_close(1001, false)")

    eq(child.lua_get("vim.api.nvim_list_wins()"), { 1000 })
end

T["curr buffer"] = new_set()

T["curr buffer"]["have the default width from the config"] = function()
    child.lua([[
        require('no-neck-pain').setup({width=50})
        require('no-neck-pain').enable()
    ]])

    eq_buf_width(child, "main.curr", 48)
end

T["curr buffer"]["closing `curr` buffer without any other window open closes Neovim"] = function()
    child.lua([[
        require('no-neck-pain').setup({width=50})
        require('no-neck-pain').enable()
    ]])

    eq(child.lua_get("vim.api.nvim_list_wins()"), { 1001, 1000, 1002 })
    eq_state(child, "win.main.curr", 1000)

    child.lua("vim.api.nvim_win_close(1000, false)")

    -- neovim is closed, we can't run anything against it
    helpers.expect.error(function()
        child.lua_get("vim.api.nvim_list_wins()")
    end)
end

T["auto command"] = new_set()

T["auto command"]["does not create side buffers window's width < options.width"] = function()
    child.lua([[
            require('no-neck-pain').setup({width=100})
            require('no-neck-pain').enable()
        ]])

    eq(child.lua_get("vim.api.nvim_list_wins()"), { 1000 })
    eq_state(child, "win.main.curr", 1000)
    eq_state(child, "win.main.left", vim.NIL)
    eq_state(child, "win.main.right", vim.NIL)
end

T["auto command"]["closing `curr` makes `split` the new `curr`"] = function()
    child.lua([[
            require('no-neck-pain').setup({width=50})
            require('no-neck-pain').enable()
        ]])

    eq(child.lua_get("vim.api.nvim_list_wins()"), { 1001, 1000, 1002 })
    eq_state(child, "win.main.split", vim.NIL)

    child.cmd("split")
    eq(child.lua_get("vim.api.nvim_list_wins()"), { 1003, 1000 })
    eq_state(child, "win.main.left", vim.NIL)
    eq_state(child, "win.main.right", vim.NIL)
    eq_state(child, "win.main.split", 1003)

    child.lua("vim.api.nvim_win_close(1000, false)")

    eq(child.lua_get("vim.api.nvim_list_wins()"), { 1004, 1003, 1005 })
    eq_state(child, "win.main.curr", 1003)
    eq_state(child, "win.main.left", 1004)
    eq_state(child, "win.main.right", 1005)
    eq_state(child, "win.main.split", vim.NIL)
end

T["auto command"]["hides side buffers after split"] = function()
    child.lua([[
            require('no-neck-pain').setup({width=50})
            require('no-neck-pain').enable()
        ]])

    -- At start 1 win automatically sorrounded with side buffers
    eq(child.lua_get("vim.api.nvim_list_wins()"), { 1001, 1000, 1002 })
    eq_state(child, "win.main.left", 1001)
    eq_state(child, "win.main.right", 1002)
    eq_state(child, "win.main.split", vim.NIL)

    eq_buf_width(child, "main.left", 15)
    eq_buf_width(child, "main.right", 15)

    -- Opening split hides side buffers
    child.cmd("split")
    eq(child.lua_get("vim.api.nvim_list_wins()"), { 1003, 1000 })
    eq_state(child, "win.main.left", vim.NIL)
    eq_state(child, "win.main.right", vim.NIL)
    eq_state(child, "win.main.split", 1003)

    eq_buf_width(child, "main.split", 80)
    eq_buf_width(child, "main.curr", 80)

    -- Closing split and returning to last window opens side buffers again
    child.cmd("close")
    eq(child.lua_get("vim.api.nvim_list_wins()"), { 1004, 1000, 1005 })
    eq_state(child, "win.main.left", 1004)
    eq_state(child, "win.main.right", 1005)
    eq_state(child, "win.main.split", vim.NIL)

    eq_buf_width(child, "main.left", 15)
    eq_buf_width(child, "main.right", 15)
end

T["auto command"]["hides side buffers after vsplit"] = function()
    child.lua([[
            require('no-neck-pain').setup({width=50})
            require('no-neck-pain').enable()
        ]])

    -- At start 1 win automatically sorrounded with side buffers
    eq(child.lua_get("vim.api.nvim_list_wins()"), { 1001, 1000, 1002 })
    eq_state(child, "win.main.left", 1001)
    eq_state(child, "win.main.right", 1002)
    eq_state(child, "win.main.split", vim.NIL)

    eq_buf_width(child, "main.left", 15)
    eq_buf_width(child, "main.right", 15)

    -- Opening vsplit hides side buffers
    child.cmd("vsplit")
    eq(child.lua_get("vim.api.nvim_list_wins()"), { 1003, 1000 })
    eq_state(child, "win.main.left", vim.NIL)
    eq_state(child, "win.main.right", vim.NIL)
    eq_state(child, "win.main.split", 1003)

    eq_buf_width(child, "main.split", 40)
    eq_buf_width(child, "main.curr", 39)

    -- Closing vsplit and returning to last window opens side buffers again
    child.cmd("close")
    eq(child.lua_get("vim.api.nvim_list_wins()"), { 1004, 1000, 1005 })
    eq_state(child, "win.main.left", 1004)
    eq_state(child, "win.main.right", 1005)
    eq_state(child, "win.main.split", vim.NIL)

    eq_buf_width(child, "main.left", 15)
    eq_buf_width(child, "main.right", 15)
end

T["auto command"]["does not shift using when opening/closing float window"] = function()
    child.lua([[
        require('no-neck-pain').setup({width=50})
        require('no-neck-pain').enable()
    ]])

    -- At start 1 win automatically sorrounded with side buffers
    eq(child.lua_get("vim.api.nvim_list_wins()"), { 1001, 1000, 1002 })
    eq_state(child, "win.main.left", 1001)
    eq_state(child, "win.main.right", 1002)

    eq_buf_width(child, "main.left", 15)
    eq_buf_width(child, "main.right", 15)

    -- Opening float window keeps the buffer here with the same width
    child.lua(
        "vim.api.nvim_open_win(0, true, {width=100,height=100,relative='cursor',row=0,col=0})"
    )

    eq(child.lua_get("vim.api.nvim_list_wins()"), { 1001, 1000, 1002, 1003 })
    eq_state(child, "win.main.left", 1001)
    eq_state(child, "win.main.right", 1002)

    eq_buf_width(child, "main.left", 15)
    eq_buf_width(child, "main.right", 15)

    -- Close float window keeps the buffer here with the same width
    child.lua("vim.api.nvim_win_close(1003, false)")

    eq(child.lua_get("vim.api.nvim_list_wins()"), { 1001, 1000, 1002 })
    eq_state(child, "win.main.left", 1001)
    eq_state(child, "win.main.right", 1002)

    eq_buf_width(child, "main.left", 15)
    eq_buf_width(child, "main.right", 15)
end

return T
