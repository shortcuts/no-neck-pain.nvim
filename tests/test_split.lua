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

T["split"] = new_set()

T["split"]["only one side buffer, closing help doesn't close NNP"] = function()
    child.set_size(500, 500)
    child.lua([[
        require('no-neck-pain').setup({width=50, buffers={right={enabled=false}}})
        require('no-neck-pain').enable()
    ]])

    child.cmd("h")

    eq(
        child.lua_get("vim.api.nvim_tabpage_list_wins(_G.NoNeckPain.state.activeTab)"),
        { 1001, 1002, 1000 }
    )
    eq_state(child, "tabs[1].wins.main.left", 1001)
    eq_state(child, "tabs[1].wins.main.right", vim.NIL)
    eq_state(child, "tabs[1].wins.splits", { { id = 1002, vertical = false } })
    eq_state(child, "tabs[1].wins.main.curr", 1000)

    child.lua("vim.fn.win_gotoid(_G.NoNeckPain.state.tabs[1].wins.splits[1].id)")
    child.cmd("q")

    eq(
        child.lua_get("vim.api.nvim_tabpage_list_wins(_G.NoNeckPain.state.activeTab)"),
        { 1001, 1000 }
    )
    eq(child.lua_get("vim.api.nvim_get_current_win()"), 1000)
    eq_state(child, "enabled", true)
end

T["split"]["closing `curr` makes `split` the new `curr`"] = function()
    child.set_size(200, 200)
    child.lua([[
        require('no-neck-pain').setup({width=50})
        require('no-neck-pain').enable()
    ]])

    child.cmd("split")

    eq(
        child.lua_get("vim.api.nvim_tabpage_list_wins(_G.NoNeckPain.state.activeTab)"),
        { 1001, 1003, 1000, 1002 }
    )
    eq_state(child, "tabs[1].wins.main.left", 1001)
    eq_state(child, "tabs[1].wins.main.right", 1002)
    eq_state(child, "tabs[1].wins.splits", { { id = 1003, vertical = false } })
    eq_state(child, "tabs[1].wins.main.curr", 1000)

    child.lua("vim.fn.win_gotoid(_G.NoNeckPain.state.tabs[1].wins.main.curr)")
    child.cmd("q")

    eq(
        child.lua_get("vim.api.nvim_tabpage_list_wins(_G.NoNeckPain.state.activeTab)"),
        { 1001, 1003, 1002 }
    )
    eq(child.lua_get("vim.api.nvim_get_current_win()"), 1003)
end

T["split"]["keeps side buffers"] = function()
    child.set_size(200, 200)
    child.lua([[
        require('no-neck-pain').setup({width=50})
        require('no-neck-pain').enable()
    ]])

    child.cmd("split")

    eq(
        child.lua_get("vim.api.nvim_tabpage_list_wins(_G.NoNeckPain.state.activeTab)"),
        { 1001, 1003, 1000, 1002 }
    )
    eq_state(child, "tabs[1].wins.main.left", 1001)
    eq_state(child, "tabs[1].wins.main.right", 1002)
    eq_state(child, "tabs[1].wins.splits", { { id = 1003, vertical = false } })

    child.lua("vim.fn.win_gotoid(_G.NoNeckPain.state.tabs[1].wins.splits[1].id)")
    child.cmd("q")

    eq(
        child.lua_get("vim.api.nvim_tabpage_list_wins(_G.NoNeckPain.state.activeTab)"),
        { 1001, 1000, 1002 }
    )
    eq_buf_width(child, "tabs[1].wins.main.left", 15)
    eq_buf_width(child, "tabs[1].wins.main.right", 15)
end

T["split"]["keeps correct focus"] = function()
    child.set_size(300, 300)
    child.lua([[
        require('no-neck-pain').setup({width=50})
        require('no-neck-pain').enable()
    ]])

    eq(child.lua_get("vim.api.nvim_get_current_win()"), 1000)

    child.cmd("split")
    eq(child.lua_get("vim.api.nvim_get_current_win()"), 1003)

    child.cmd("split")
    eq(child.lua_get("vim.api.nvim_get_current_win()"), 1004)

    child.cmd("split")
    eq(child.lua_get("vim.api.nvim_get_current_win()"), 1005)

    child.cmd("q")
    eq(child.lua_get("vim.api.nvim_get_current_win()"), 1004)

    child.cmd("q")
    eq(child.lua_get("vim.api.nvim_get_current_win()"), 1003)

    child.cmd("q")
    eq(child.lua_get("vim.api.nvim_get_current_win()"), 1000)
end

T["vsplit"] = new_set()

T["vsplit"]["does not create side buffers when there's not enough space"] = function()
    child.cmd("vsplit")
    child.cmd("vsplit")
    child.cmd("vsplit")

    eq(child.lua_get("vim.api.nvim_tabpage_list_wins(1)"), { 1003, 1002, 1001, 1000 })

    child.lua([[
        require('no-neck-pain').setup({width=50})
        require('no-neck-pain').enable()
    ]])

    eq(
        child.lua_get("vim.api.nvim_tabpage_list_wins(_G.NoNeckPain.state.activeTab)"),
        { 1003, 1002, 1001, 1000 }
    )
end

T["vsplit"]["correctly position side buffers when there's enough space"] = function()
    child.set_size(500, 500)
    child.cmd("vsplit")

    eq(child.lua_get("vim.api.nvim_tabpage_list_wins(1)"), { 1001, 1000 })

    child.lua([[
        require('no-neck-pain').setup({width=50})
        require('no-neck-pain').enable()
    ]])

    eq(
        child.lua_get("vim.api.nvim_tabpage_list_wins(_G.NoNeckPain.state.activeTab)"),
        { 1002, 1001, 1000, 1003 }
    )
end

T["vsplit"]["closing `curr` makes `split` the new `curr`"] = function()
    child.set_size(400, 400)
    child.lua([[
        require('no-neck-pain').setup({width=50})
        require('no-neck-pain').enable()
    ]])

    child.cmd("vsplit")

    eq(
        child.lua_get("vim.api.nvim_tabpage_list_wins(_G.NoNeckPain.state.activeTab)"),
        { 1001, 1003, 1000, 1002 }
    )
    eq_state(child, "tabs[1].wins.main.left", 1001)
    eq_state(child, "tabs[1].wins.main.right", 1002)
    eq_state(child, "tabs[1].wins.splits", { { id = 1003, vertical = false } })
    eq_state(child, "tabs[1].wins.main.curr", 1000)

    child.lua("vim.fn.win_gotoid(_G.NoNeckPain.state.tabs[1].wins.main.curr)")
    child.cmd("q")

    eq_state(child, "tabs[1].wins.main.curr", 1003)
    eq(
        child.lua_get("vim.api.nvim_tabpage_list_wins(_G.NoNeckPain.state.activeTab)"),
        { 1001, 1003, 1002 }
    )
    eq(child.lua_get("vim.api.nvim_get_current_win()"), 1003)
end

T["vsplit"]["hides side buffers"] = function()
    child.lua([[
        require('no-neck-pain').setup({width=50})
        require('no-neck-pain').enable()
    ]])

    child.cmd("vsplit")

    eq(
        child.lua_get("vim.api.nvim_tabpage_list_wins(_G.NoNeckPain.state.activeTab)"),
        { 1003, 1000 }
    )
    eq_state(child, "tabs[1].wins.main.left", vim.NIL)
    eq_state(child, "tabs[1].wins.main.right", vim.NIL)
    eq_state(child, "tabs[1].wins.splits", { { id = 1003, vertical = true } })

    child.lua("vim.fn.win_gotoid(_G.NoNeckPain.state.tabs[1].wins.splits[1].id)")
    child.cmd("q")

    eq(
        child.lua_get("vim.api.nvim_tabpage_list_wins(_G.NoNeckPain.state.activeTab)"),
        { 1004, 1000, 1005 }
    )
    eq_state(child, "tabs[1].wins.main.left", 1004)
    eq_state(child, "tabs[1].wins.main.right", 1005)
    eq_state(child, "tabs[1].wins.splits", vim.NIL)
end

T["vsplit"]["many vsplit leave side buffers open as long as there's space for it"] = function()
    child.set_size(300, 300)
    child.lua([[ require('no-neck-pain').setup({width=70}) ]])

    eq(child.lua_get("vim.api.nvim_tabpage_list_wins(1)"), { 1000 })

    child.lua([[ require('no-neck-pain').enable() ]])

    eq(
        child.lua_get("vim.api.nvim_tabpage_list_wins(_G.NoNeckPain.state.activeTab)"),
        { 1001, 1000, 1002 }
    )

    eq_state(child, "tabs[1].wins.main.left", 1001)
    eq_state(child, "tabs[1].wins.main.right", 1002)

    child.cmd("vsplit")
    child.cmd("vsplit")
    child.cmd("vsplit")
    eq(
        child.lua_get("vim.api.nvim_tabpage_list_wins(_G.NoNeckPain.state.activeTab)"),
        { 1005, 1004, 1003, 1000 }
    )

    eq_state(child, "tabs[1].wins.main.left", vim.NIL)
    eq_state(child, "tabs[1].wins.main.right", vim.NIL)
end

T["vsplit"]["keeps correct focus"] = function()
    child.set_size(400, 400)
    child.lua([[
        require('no-neck-pain').setup({width=50})
        require('no-neck-pain').enable()
    ]])

    eq(child.lua_get("vim.api.nvim_get_current_win()"), 1000)

    child.cmd("vsplit")
    eq(child.lua_get("vim.api.nvim_get_current_win()"), 1003)

    child.cmd("vsplit")
    eq(child.lua_get("vim.api.nvim_get_current_win()"), 1004)

    child.cmd("vsplit")
    eq(child.lua_get("vim.api.nvim_get_current_win()"), 1005)

    child.cmd("q")
    eq(child.lua_get("vim.api.nvim_get_current_win()"), 1004)

    child.cmd("q")
    eq(child.lua_get("vim.api.nvim_get_current_win()"), 1003)

    child.cmd("q")
    eq(child.lua_get("vim.api.nvim_get_current_win()"), 1000)
end

T["vsplit/split"] = new_set()

T["vsplit/split"]["state is correctly sync'd even after many changes"] = function()
    child.set_size(100, 100)
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])

    eq(child.lua_get("vim.api.nvim_tabpage_list_wins(1)"), { 1000 })

    child.lua([[ require('no-neck-pain').enable() ]])

    eq(
        child.lua_get("vim.api.nvim_tabpage_list_wins(_G.NoNeckPain.state.activeTab)"),
        { 1001, 1000, 1002 }
    )

    child.cmd("split")
    eq(
        child.lua_get("vim.api.nvim_tabpage_list_wins(_G.NoNeckPain.state.activeTab)"),
        { 1001, 1003, 1000, 1002 }
    )
    child.cmd("q")

    child.cmd("vsplit")
    eq(
        child.lua_get("vim.api.nvim_tabpage_list_wins(_G.NoNeckPain.state.activeTab)"),
        { 1004, 1000 }
    )
    child.cmd("q")

    eq(
        child.lua_get("vim.api.nvim_tabpage_list_wins(_G.NoNeckPain.state.activeTab)"),
        { 1005, 1000, 1006 }
    )
end

T["vsplit/split"]["closing side buffers because of splits restores focus"] = function()
    child.set_size(150, 150)
    child.lua([[
        require('no-neck-pain').setup({width=50})
        require('no-neck-pain').enable() 
    ]])

    eq(
        child.lua_get("vim.api.nvim_tabpage_list_wins(_G.NoNeckPain.state.activeTab)"),
        { 1001, 1000, 1002 }
    )

    child.cmd("vsplit")
    eq(
        child.lua_get("vim.api.nvim_tabpage_list_wins(_G.NoNeckPain.state.activeTab)"),
        { 1001, 1003, 1000, 1002 }
    )

    child.cmd("vsplit")
    eq(
        child.lua_get("vim.api.nvim_tabpage_list_wins(_G.NoNeckPain.state.activeTab)"),
        { 1004, 1003, 1000 }
    )

    child.cmd("q")
    eq(
        child.lua_get("vim.api.nvim_tabpage_list_wins(_G.NoNeckPain.state.activeTab)"),
        { 1005, 1003, 1000, 1006 }
    )

    eq(child.lua_get("vim.api.nvim_get_current_win()"), 1000)
end

return T
