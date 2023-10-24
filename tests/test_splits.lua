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
    child.loop.sleep(50)

    eq(helpers.winsInTab(child), { 1001, 1002, 1000 })
    eq_state(child, "tabs[1].wins.main", { curr = 1000, left = 1001 })
    eq_state(child, "tabs[1].wins.splits[1002]", { id = 1002, vertical = false })

    child.lua("vim.fn.win_gotoid(_G.NoNeckPain.state.tabs[1].wins.splits[1002].id)")
    child.cmd("q")

    eq(helpers.winsInTab(child), { 1001, 1000 })
    eq(helpers.currentWin(child), 1000)
    eq_state(child, "enabled", true)
end

T["split"]["closing `curr` makes `split` the new `curr`"] = function()
    child.set_size(200, 200)
    child.lua([[
        require('no-neck-pain').setup({width=50})
        require('no-neck-pain').enable()
    ]])

    child.cmd("split")
    child.loop.sleep(50)

    eq(helpers.winsInTab(child), { 1001, 1003, 1000, 1002 })
    eq_state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })
    eq_state(child, "tabs[1].wins.splits[1003]", { id = 1003, vertical = false })

    child.lua("vim.fn.win_gotoid(_G.NoNeckPain.state.tabs[1].wins.main.curr)")
    child.cmd("q")

    eq(helpers.winsInTab(child), { 1001, 1003, 1002 })
    eq(helpers.currentWin(child), 1003)
end

T["split"]["keeps side buffers"] = function()
    child.set_size(200, 200)
    child.lua([[
        require('no-neck-pain').setup({width=50})
        require('no-neck-pain').enable()
    ]])

    child.cmd("split")
    child.loop.sleep(50)

    eq(helpers.winsInTab(child), { 1001, 1003, 1000, 1002 })
    eq_state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })
    eq_state(child, "tabs[1].wins.splits[1003]", { id = 1003, vertical = false })

    child.lua("vim.fn.win_gotoid(_G.NoNeckPain.state.tabs[1].wins.splits[1003].id)")
    child.cmd("q")

    eq(helpers.winsInTab(child), { 1001, 1000, 1002 })
    eq_buf_width(child, "tabs[1].wins.main.left", 15)
    eq_buf_width(child, "tabs[1].wins.main.right", 15)
end

T["split"]["keeps correct focus"] = function()
    child.set_size(300, 300)
    child.lua([[
        require('no-neck-pain').setup({width=50})
        require('no-neck-pain').enable()
    ]])

    eq(helpers.currentWin(child), 1000)

    child.cmd("split")
    eq(helpers.currentWin(child), 1003)

    child.cmd("split")
    eq(helpers.currentWin(child), 1004)

    child.cmd("split")
    eq(helpers.currentWin(child), 1005)

    child.cmd("q")
    eq(helpers.currentWin(child), 1004)

    child.cmd("q")
    eq(helpers.currentWin(child), 1003)

    child.cmd("q")
    eq(helpers.currentWin(child), 1000)
end

T["vsplit"] = new_set()

T["vsplit"]["does not create side buffers when there's not enough space"] = function()
    child.cmd("vsplit")
    child.cmd("vsplit")
    child.cmd("vsplit")

    eq(helpers.winsInTab(child, 1), { 1003, 1002, 1001, 1000 })

    child.lua([[
        require('no-neck-pain').setup({width=50})
        require('no-neck-pain').enable()
    ]])

    eq(helpers.winsInTab(child), { 1003, 1002, 1001, 1000 })
end

T["vsplit"]["corretly size splits when opening helper with side buffers open"] = function()
    child.set_size(150, 150)
    child.lua([[
        require('no-neck-pain').setup({width=50})
        require('no-neck-pain').enable()
    ]])

    child.cmd("vsplit")
    child.loop.sleep(50)

    eq(helpers.winsInTab(child), { 1001, 1003, 1000, 1002 })

    eq_buf_width(child, "tabs[1].wins.splits[1003].id", 50)
    eq_buf_width(child, "tabs[1].wins.main.curr", 67)

    child.cmd("h")
    child.loop.sleep(50)

    eq(helpers.winsInTab(child), { 1004, 1001, 1003, 1000, 1002 })

    eq_buf_width(child, "tabs[1].wins.splits[1004].id", 150)
    eq_buf_width(child, "tabs[1].wins.main.curr", 67)
end

T["vsplit"]["correctly position side buffers when there's enough space"] = function()
    child.set_size(500, 500)
    child.cmd("vsplit")

    eq(helpers.winsInTab(child, 1), { 1001, 1000 })

    child.lua([[
        require('no-neck-pain').setup({width=50})
        require('no-neck-pain').enable()
    ]])

    eq(helpers.winsInTab(child), { 1002, 1001, 1000, 1003 })
end

T["vsplit"]["preserve vsplit width when having side buffers"] = function()
    child.set_size(500, 500)
    child.lua([[
        require('no-neck-pain').setup({width=50,buffers={right={enabled=false}}})
        require('no-neck-pain').enable()
    ]])

    eq(helpers.winsInTab(child), { 1001, 1000 })

    child.cmd("vsplit")
    child.loop.sleep(50)

    eq(helpers.winsInTab(child), { 1001, 1002, 1000 })

    eq_buf_width(child, "tabs[1].wins.splits[1002].id", 65)
end

T["vsplit"]["closing `curr` makes `split` the new `curr`"] = function()
    child.set_size(400, 400)
    child.lua([[
        require('no-neck-pain').setup({width=50})
        require('no-neck-pain').enable()
    ]])

    child.cmd("vsplit")
    child.loop.sleep(50)

    eq(helpers.winsInTab(child), { 1001, 1003, 1000, 1002 })
    eq_state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })
    eq_state(child, "tabs[1].wins.splits[1003]", { id = 1003, vertical = true })

    child.lua("vim.fn.win_gotoid(_G.NoNeckPain.state.tabs[1].wins.main.curr)")
    child.cmd("q")

    eq_state(child, "tabs[1].wins.main", {
        curr = 1003,
        left = 1001,
        right = 1002,
    })
    eq(helpers.winsInTab(child), { 1001, 1003, 1002 })
    eq(helpers.currentWin(child), 1003)
end

T["vsplit"]["hides side buffers"] = function()
    child.lua([[
        require('no-neck-pain').setup({width=50})
        require('no-neck-pain').enable()
    ]])

    child.cmd("vsplit")
    child.loop.sleep(50)

    eq(helpers.winsInTab(child), { 1003, 1000 })
    eq_state(child, "tabs[1].wins.main", {
        curr = 1000,
    })
    eq_state(child, "tabs[1].wins.splits[1003]", { id = 1003, vertical = true })

    child.lua("vim.fn.win_gotoid(_G.NoNeckPain.state.tabs[1].wins.splits[1003].id)")
    child.cmd("q")

    eq(helpers.winsInTab(child), { 1004, 1000, 1005 })
    eq_state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1004,
        right = 1005,
    })
    eq_state(child, "tabs[1].wins.splits", vim.NIL)
end

T["vsplit"]["many vsplit leave side buffers open as long as there's space for it"] = function()
    child.set_size(100, 100)
    child.lua([[
        require('no-neck-pain').setup({width=50}) 
        require('no-neck-pain').enable() 
    ]])

    eq(helpers.winsInTab(child), { 1001, 1000, 1002 })

    child.cmd("vsplit")
    child.loop.sleep(50)
    child.cmd("vsplit")
    child.loop.sleep(50)

    eq(helpers.winsInTab(child), { 1004, 1003, 1000 })

    child.cmd("q")
    child.loop.sleep(50)

    eq(helpers.winsInTab(child), { 1005, 1003, 1000, 1006 })
    eq_state(child, "tabs[_G.NoNeckPain.state.activeTab].wins.main", {
        curr = 1000,
        left = 1005,
        right = 1006,
    })
end

T["vsplit"]["keeps correct focus"] = function()
    child.set_size(200, 200)
    child.lua([[
        require('no-neck-pain').setup({width=50})
        require('no-neck-pain').enable()
    ]])

    eq(helpers.currentWin(child), 1000)

    child.cmd("vsplit")
    eq(helpers.currentWin(child), 1003)

    child.cmd("vsplit")
    eq(helpers.currentWin(child), 1004)

    eq(helpers.winsInTab(child), { 1001, 1004, 1003, 1000, 1002 })
end

T["vsplit/split"] = new_set()

T["vsplit/split"]["state is correctly sync'd even after many changes"] = function()
    child.set_size(100, 100)
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])

    eq(helpers.winsInTab(child, 1), { 1000 })

    child.lua([[ require('no-neck-pain').enable() ]])

    eq(helpers.winsInTab(child), { 1001, 1000, 1002 })

    child.cmd("split")
    eq(helpers.winsInTab(child), { 1001, 1003, 1000, 1002 })
    child.cmd("q")

    child.cmd("vsplit")
    child.loop.sleep(50)

    eq(helpers.winsInTab(child), { 1001, 1004, 1000, 1002 })

    child.cmd("vsplit")
    child.loop.sleep(50)

    eq(helpers.winsInTab(child), { 1005, 1004, 1000 })

    child.cmd("q")
    child.cmd("q")

    eq(helpers.winsInTab(child), { 1006, 1004, 1007 })
    eq_state(child, "tabs[_G.NoNeckPain.state.activeTab].wins.main", {
        curr = 1004,
        left = 1006,
        right = 1007,
    })
end

T["vsplit/split"]["closing side buffers because of splits restores focus"] = function()
    child.set_size(100, 100)
    child.lua([[
        require('no-neck-pain').setup({width=50})
        require('no-neck-pain').enable() 
    ]])

    eq(helpers.winsInTab(child), { 1001, 1000, 1002 })

    child.cmd("vsplit")
    child.loop.sleep(50)

    eq(helpers.winsInTab(child), { 1001, 1003, 1000, 1002 })

    child.cmd("vsplit")
    child.loop.sleep(50)
    child.cmd("vsplit")
    child.loop.sleep(50)

    eq(helpers.winsInTab(child), { 1005, 1004, 1003, 1000 })

    child.cmd("q")
    child.cmd("q")
    eq(helpers.winsInTab(child), { 1006, 1003, 1000, 1007 })

    eq(helpers.currentWin(child), 1000)
end

T["vsplit/split"]["closing help page doens't break layout"] = function()
    child.lua([[
        require('no-neck-pain').setup({width=50})
        require('no-neck-pain').enable() 
    ]])

    eq(helpers.winsInTab(child), { 1001, 1000, 1002 })

    child.cmd("split")
    child.cmd("h")
    eq(helpers.winsInTab(child), { 1004, 1001, 1003, 1000, 1002 })

    eq_buf_width(child, "tabs[1].wins.main.curr", 48)

    child.cmd("q")
    eq(helpers.winsInTab(child), { 1001, 1003, 1000, 1002 })

    eq(helpers.currentWin(child), 1003)

    eq_buf_width(child, "tabs[1].wins.main.curr", 48)
end

T["vsplit/split"]["splits and vsplits keeps a correct size"] = function()
    child.set_size(50, 500)
    child.lua([[
        require('no-neck-pain').setup({width=50})
        require('no-neck-pain').enable() 
    ]])

    eq(helpers.winsInTab(child), { 1001, 1000, 1002 })
    eq(helpers.currentWin(child), 1000)

    child.cmd("split")
    vim.loop.sleep(50)

    eq(helpers.winsInTab(child), { 1001, 1003, 1000, 1002 })
    eq(helpers.currentWin(child), 1003)
    eq_buf_width(child, "tabs[1].wins.main.curr", 468)

    child.cmd("vsplit")
    vim.loop.sleep(50)

    eq(helpers.winsInTab(child), { 1001, 1004, 1003, 1000, 1002 })
    eq(helpers.currentWin(child), 1004)

    eq_buf_width(child, "tabs[1].wins.main.curr", 468)
    eq(child.lua_get("vim.api.nvim_win_get_width(1003)"), 417)
    eq(child.lua_get("vim.api.nvim_win_get_width(1000)"), 468)
end

return T
