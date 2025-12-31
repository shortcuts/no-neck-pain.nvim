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

T["split"] = MiniTest.new_set()

T["split"]["only one side buffer, closing help doesn't close NNP"] = function()
    child.lua([[ require('no-neck-pain').setup({width=20, buffers={right={enabled=false}}}) ]])
    child.nnp()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000 })

    child.cmd("h")

    Helpers.expect.equality(child.get_wins_in_tab(), { 1002, 1001, 1000 })
    Helpers.expect.state(child, "tabs[1].wins.main", { curr = 1000, left = 1001 })

    child.lua("vim.fn.win_gotoid(1002)")
    child.cmd("q")

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000 })
    Helpers.expect.equality(child.get_current_win(), 1000)
    Helpers.expect.state(child, "enabled", true)
end

T["split"]["closing `curr` makes `split` the new `curr`"] = function()
    child.lua([[ require('no-neck-pain').setup({width=20}) ]])
    child.nnp()

    child.cmd("split")

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1003, 1000, 1002 })
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })

    child.lua("vim.fn.win_gotoid(_G.NoNeckPain.state.tabs[1].wins.main.curr)")
    child.cmd("q")

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1003, 1002 })
    Helpers.expect.equality(child.get_current_win(), 1003)
end

T["split"]["keeps side buffers"] = function()
    child.lua([[ require('no-neck-pain').setup({width=20}) ]])
    child.nnp()

    child.cmd("split")

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1003, 1000, 1002 })
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })

    child.lua("vim.fn.win_gotoid(1003)")
    child.cmd("q")

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })
    Helpers.expect.buf_width_in_range(child, "_G.NoNeckPain.state.tabs[1].wins.main.left", 28, 30)
    Helpers.expect.buf_width_in_range(child, "_G.NoNeckPain.state.tabs[1].wins.main.right", 28, 30)
end

T["split"]["keeps correct focus"] = function()
    child.lua([[ require('no-neck-pain').setup({width=20}) ]])
    child.nnp()

    Helpers.expect.equality(child.get_current_win(), 1000)

    child.cmd("split")
    Helpers.expect.equality(child.get_current_win(), 1003)

    child.cmd("split")
    Helpers.expect.equality(child.get_current_win(), 1004)

    child.cmd("split")
    Helpers.expect.equality(child.get_current_win(), 1005)

    child.cmd("q")
    Helpers.expect.equality(child.get_current_win(), 1004)

    child.cmd("q")
    Helpers.expect.equality(child.get_current_win(), 1003)

    child.cmd("q")
    Helpers.expect.equality(child.get_current_win(), 1000)
end

T["split"]["correctly starts nnp with previously opened splits"] = function()
    child.lua([[ require('no-neck-pain').setup({width=20}) ]])

    child.cmd("split")
    Helpers.expect.equality(child.get_wins_in_tab(1), { 1001, 1000 })

    child.nnp()
    child.wait()

    Helpers.expect.equality(child.get_wins_in_tab(1), { 1002, 1001, 1000, 1003 })

    Helpers.expect.buf_width_in_range(child, "1002", 28, 30)
    Helpers.expect.buf_width_in_range(child, "1003", 28, 30)

    Helpers.expect.buf_width_in_range(child, "1000", 18, 20)
    Helpers.expect.buf_width_in_range(child, "1001", 18, 20)

    Helpers.expect.equality(child.get_wins_in_tab(), { 1002, 1001, 1000, 1003 })
end

T["split"]["correctly starts nnp with previously opened splits (only one side)"] = function()
    child.lua([[ require('no-neck-pain').setup({width=20, buffers={right={enabled=false}}}) ]])

    child.cmd("split")
    Helpers.expect.equality(child.get_wins_in_tab(1), { 1001, 1000 })

    child.nnp()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1002, 1001, 1000 })
end

T["vsplit"] = MiniTest.new_set()

T["vsplit"]["does not create side buffers when there's not enough space"] = function()
    child.cmd("vsplit")
    child.cmd("vsplit")
    child.cmd("vsplit")

    Helpers.expect.equality(child.get_wins_in_tab(1), { 1003, 1002, 1001, 1000 })

    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1003, 1002, 1001, 1000 })
end

T["vsplit"]["correctly size splits when opening helper with side buffers open"] = function()
    child.lua([[ require('no-neck-pain').setup({width=20}) ]])
    child.nnp()

    child.cmd("vsplit")

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1003, 1000, 1002 })

    Helpers.expect.buf_width_in_range(child, "1003", 18, 20)
    Helpers.expect.buf_width_in_range(child, "_G.NoNeckPain.state.tabs[1].wins.main.curr", 18, 20)

    child.cmd("h")

    Helpers.expect.equality(child.get_wins_in_tab(), { 1004, 1001, 1003, 1000, 1002 })

    Helpers.expect.equality(child.lua_get("vim.api.nvim_win_get_width(1004)"), 80)
    Helpers.expect.buf_width_in_range(child, "_G.NoNeckPain.state.tabs[1].wins.main.curr", 18, 20)
end

T["vsplit"]["correctly position side buffers when there's enough space"] = function()
    child.cmd("vsplit")

    Helpers.expect.equality(child.get_wins_in_tab(1), { 1001, 1000 })

    child.lua([[ require('no-neck-pain').setup({width=20}) ]])
    child.nnp()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1002, 1001, 1000, 1003 })
end

T["vsplit"]["preserve vsplit width when having side buffers"] = function()
    child.lua([[ require('no-neck-pain').setup({width=20,buffers={right={enabled=false}}}) ]])
    child.nnp()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000 })

    child.cmd("vsplit")

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1002, 1000 })

    Helpers.expect.buf_width_in_range(child, "1002", 32, 36)
    Helpers.expect.buf_width_in_range(child, "_G.NoNeckPain.state.tabs[1].wins.main.curr", 24, 28)
end

T["vsplit"]["closing `curr` makes `split` the new `curr`"] = function()
    child.lua([[ require('no-neck-pain').setup({width=20}) ]])
    child.nnp()

    child.cmd("vsplit")
    child.wait()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1003, 1000, 1002 })
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })

    child.lua("vim.fn.win_gotoid(_G.NoNeckPain.state.tabs[1].wins.main.curr)")
    child.cmd("q")
    child.wait()

    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1003,
        left = 1001,
        right = 1002,
    })
    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1003, 1002 })
    Helpers.expect.equality(child.get_current_win(), 1003)
end

T["vsplit"]["(#425) closing `curr` with only one side buffer and not enough spaces properly resets the state"] = function()
    child.lua([[ require('no-neck-pain').setup({width=55,buffers={right={enabled=false}}}) ]])
    child.nnp()

    Helpers.expect.equality(child.get_current_win(), 1000)
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
    })

    child.cmd("vsplit")
    child.wait()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1002, 1000 })
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
    })

    child.lua("vim.fn.win_gotoid(_G.NoNeckPain.state.tabs[1].wins.main.curr)")
    child.cmd("q")
    child.wait()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1003, 1002 })
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1002,
        left = 1003,
    })
    Helpers.expect.equality(child.get_current_win(), 1002)
end

T["vsplit"]["hides side buffers"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50,minSideBufferWidth=0}) ]])
    child.nnp()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })

    child.cmd("vsplit")
    child.wait()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1003, 1000 })
    Helpers.expect.state(child, "tabs[1].wins.main", { curr = 1000 })

    child.lua("vim.fn.win_gotoid(1003)")
    child.cmd("q")

    Helpers.expect.equality(child.get_wins_in_tab(), { 1004, 1000, 1005 })
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1004,
        right = 1005,
    })
    Helpers.expect.state(child, "tabs[1].wins.splits", vim.NIL)
end

T["vsplit"]["many vsplit leave side buffers open as long as there's space for it"] = function()
    child.lua([[ require('no-neck-pain').setup({width=20}) ]])
    child.nnp()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })

    child.cmd("vsplit")
    child.cmd("vsplit")
    child.wait()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1004, 1003, 1000 })

    child.cmd("q")

    Helpers.expect.equality(child.get_wins_in_tab(), { 1005, 1003, 1000, 1006 })
    Helpers.expect.state(child, "tabs[_G.NoNeckPain.state.active_tab].wins.main", {
        curr = 1000,
        left = 1005,
        right = 1006,
    })
end

T["vsplit"]["keeps correct focus"] = function()
    child.lua([[ require('no-neck-pain').setup({width=10}) ]])
    child.nnp()

    Helpers.expect.equality(child.get_current_win(), 1000)

    child.cmd("vsplit")
    Helpers.expect.equality(child.get_current_win(), 1003)

    child.cmd("vsplit")
    Helpers.expect.equality(child.get_current_win(), 1004)

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1004, 1003, 1000, 1002 })
end

T["vsplit/split"] = MiniTest.new_set()

T["vsplit/split"]["state is correctly sync'd even after many changes"] = function()
    child.lua([[ require('no-neck-pain').setup({width=20}) ]])

    Helpers.expect.equality(child.get_wins_in_tab(1), { 1000 })

    child.nnp()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })

    child.cmd("split")
    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1003, 1000, 1002 })
    child.cmd("q")

    child.cmd("vsplit")

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1004, 1000, 1002 })

    child.cmd("vsplit")
    child.wait()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1005, 1004, 1000 })

    child.cmd("q")
    child.cmd("q")

    Helpers.expect.equality(child.get_wins_in_tab(), { 1006, 1004, 1007 })
    Helpers.expect.state(child, "tabs[_G.NoNeckPain.state.active_tab].wins.main", {
        curr = 1004,
        left = 1006,
        right = 1007,
    })
end

T["vsplit/split"]["closing side buffers because of splits restores focus"] = function()
    child.lua([[ require('no-neck-pain').setup({width=20}) ]])
    child.nnp()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })

    child.cmd("vsplit")

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1003, 1000, 1002 })

    child.cmd("vsplit")
    child.cmd("vsplit")
    child.wait()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1005, 1004, 1003, 1000 })

    child.cmd("q")
    child.cmd("q")
    Helpers.expect.equality(child.get_wins_in_tab(), { 1006, 1003, 1000, 1007 })

    Helpers.expect.equality(child.get_current_win(), 1000)
end

T["vsplit/split"]["closing help page doens't break layout"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })

    child.cmd("split")
    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1003, 1000, 1002 })

    child.cmd("h")
    Helpers.expect.equality(child.get_wins_in_tab(), { 1004, 1001, 1003, 1000, 1002 })

    Helpers.expect.buf_width_in_range(child, "_G.NoNeckPain.state.tabs[1].wins.main.curr", 46, 48)

    Helpers.expect.equality(child.get_current_win(), 1004)
    child.cmd("q")
    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1003, 1000, 1002 })

    Helpers.expect.equality(child.get_current_win(), 1003)

    Helpers.expect.buf_width_in_range(child, "_G.NoNeckPain.state.tabs[1].wins.main.curr", 26, 48)
end

T["vsplit/split"]["splits and vsplits keeps a correct size"] = function()
    child.lua([[ require('no-neck-pain').setup({width=20}) ]])
    child.nnp()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })
    Helpers.expect.equality(child.get_current_win(), 1000)

    child.cmd("split")

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1003, 1000, 1002 })
    Helpers.expect.equality(child.get_current_win(), 1003)
    Helpers.expect.buf_width_in_range(child, "_G.NoNeckPain.state.tabs[1].wins.main.curr", 18, 20)
    Helpers.expect.buf_width_in_range(child, "1003", 18, 20)

    child.cmd("vsplit")
    child.wait()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1004, 1003, 1000, 1002 })
    Helpers.expect.equality(child.get_current_win(), 1004)

    Helpers.expect.buf_width_in_range(child, "_G.NoNeckPain.state.tabs[1].wins.main.curr", 38, 40)
    Helpers.expect.buf_width_in_range(child, "1003", 16, 18)
end

T["InspectTree"] = MiniTest.new_set()

T["InspectTree"]["keeps sides open"] = function()
    child.lua([[ require('no-neck-pain').setup({width=10}) ]])
    child.nnp()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })

    Helpers.expect.state(child, "enabled", true)
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })

    child.cmd("InspectTree")
    child.wait()

    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })
end

-- T["InspectTree"]["reduces `left` side if only active when integration is on `right`"] = function()
--     child.lua([[
--         require('no-neck-pain').setup({
--             width = 20,
--             buffers = {
--                 right = {
--                     enabled = false,
--                 },
--             },
--         })
--     ]])
--     child.nnp()
--     child.wait()
--
--     Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000 })
--
--     Helpers.expect.state(child, "enabled", true)
--     Helpers.expect.state(child, "tabs[1].wins.main", {
--         curr = 1000,
--         left = 1001,
--         right = nil,
--     })
--     Helpers.expect.buf_width(child, "tabs[1].wins.main.left", 30)
--
--     child.cmd("InspectTree")
--     child.wait()
--
--     Helpers.expect.buf_width_in_range(child, "_G.NoNeckPain.state.tabs[1].wins.main.left", 18, 20)
--     Helpers.expect.buf_width_in_range(child, "1003", 26, 38)
--     Helpers.expect.state(child, "tabs[1].wins.main", {
--         curr = 1000,
--         left = 1001,
--         right = nil,
--     })
--
--     child.cmd("InspectTree")
--     child.wait()
--
--     Helpers.expect.state(child, "tabs[1].wins.columns", 2)
--
--     Helpers.expect.state(child, "tabs[1].wins.main", {
--         curr = 1000,
--         left = 1001,
--         right = nil,
--     })
--     Helpers.expect.buf_width_in_range(child, "_G.NoNeckPain.state.tabs[1].wins.main.left", 28, 40)
-- end

return T
