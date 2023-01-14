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

T["curr"] = new_set()

T["curr"]["have the default width"] = function()
    child.lua([[
        require('no-neck-pain').setup()
        require('no-neck-pain').enable()
    ]])

    -- need to know why the child isn't precise enough
    eq_buf_width(child, "main.curr", 80)
end

T["curr"]["have the width from the config"] = function()
    child.lua([[
        require('no-neck-pain').setup({width=50})
        require('no-neck-pain').enable()
    ]])

    -- need to know why the child isn't precise enough
    eq_buf_width(child, "main.curr", 48)
end

T["curr"]["closing `curr` window without any other window quits Neovim"] = function()
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

T["left/right"] = new_set()

T["left/right"]["have the same width"] = function()
    child.lua([[
        require('no-neck-pain').setup({width=50})
        require('no-neck-pain').enable()
    ]])

    eq_buf_width(child, "main.left", 15)
    eq_buf_width(child, "main.right", 15)
end

T["left/right"]["only creates a `left` buffer when `right.enabled` is `false`"] = function()
    child.lua([[
        require('no-neck-pain').setup({width=50,buffers={right={enabled=false}}})
        require('no-neck-pain').enable()
    ]])

    eq_state(child, "win.main.left", 1001)
    eq_state(child, "win.main.right", vim.NIL)

    eq_buf_width(child, "main.left", 15)
end

T["left/right"]["only creates a `right` buffer when `left.enabled` is `false`"] = function()
    child.lua([[
        require('no-neck-pain').setup({width=50,buffers={left={enabled=false}}})
        require('no-neck-pain').enable()
    ]])

    eq_state(child, "win.main.left", vim.NIL)
    eq_state(child, "win.main.right", 1001)

    eq_buf_width(child, "main.right", 15)
end

T["left/right"]["closing the `left` buffer disables NNP"] = function()
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

T["left/right"]["closing the `right` buffer disables NNP"] = function()
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

return T
