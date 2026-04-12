local Helpers = dofile("tests/helpers.lua")

local child = Helpers.new_child_neovim()

local T = MiniTest.new_set({
    hooks = {
        pre_case = function()
            child.restart({ "-u", "scripts/minimal_init.lua" })
        end,
        post_once = child.stop,
    },
})

-- =============================================================================
-- split
-- =============================================================================

T["split: only one side buffer, closing help doesn't close NNP"] = function()
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

T["split: closing `curr` makes `split` the new `curr`"] = function()
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

T["split: keeps side buffers"] = function()
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

T["split: keeps correct focus"] = function()
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

T["split: correctly starts nnp with previously opened splits"] = function()
    child.lua([[ require('no-neck-pain').setup({width=20}) ]])

    child.cmd("split")
    Helpers.expect.equality(child.get_wins_in_tab(1), { 1001, 1000 })

    child.nnp()
    child.wait()

    Helpers.expect.equality(child.get_wins_in_tab(1), { 1002, 1001, 1003, 1000 })

    Helpers.expect.buf_width_in_range(child, "1002", 28, 32)
    Helpers.expect.buf_width_in_range(child, "1003", 28, 32)

    Helpers.expect.buf_width_in_range(child, "1000", 78, 80)
    Helpers.expect.buf_width_in_range(child, "1001", 16, 20)

    Helpers.expect.equality(child.get_wins_in_tab(), { 1002, 1001, 1003, 1000 })
end

T["split: correctly starts nnp with previously opened splits (only one side)"] = function()
    child.lua([[ require('no-neck-pain').setup({width=20, buffers={right={enabled=false}}}) ]])

    child.cmd("split")
    Helpers.expect.equality(child.get_wins_in_tab(1), { 1001, 1000 })

    child.nnp()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1002, 1001, 1000 })
end

-- =============================================================================
-- vsplit
-- =============================================================================

T["vsplit: does not create side buffers when there's not enough space"] = function()
    child.cmd("vsplit")
    child.cmd("vsplit")
    child.cmd("vsplit")

    Helpers.expect.equality(child.get_wins_in_tab(1), { 1003, 1002, 1001, 1000 })

    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1003, 1002, 1001, 1000 })
end

T["vsplit: correctly size splits when opening helper with side buffers open"] = function()
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

T["vsplit: correctly position side buffers when there's enough space"] = function()
    child.cmd("vsplit")

    Helpers.expect.equality(child.get_wins_in_tab(1), { 1001, 1000 })

    child.lua([[ require('no-neck-pain').setup({width=20}) ]])
    child.nnp()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1002, 1001, 1003, 1000 })
end

T["vsplit: preserve vsplit width when having side buffers"] = function()
    child.lua([[ require('no-neck-pain').setup({width=20,buffers={right={enabled=false}}}) ]])
    child.nnp()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000 })

    child.cmd("vsplit")

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1002, 1000 })

    Helpers.expect.buf_width_in_range(child, "1002", 28, 35)
    Helpers.expect.buf_width_in_range(child, "_G.NoNeckPain.state.tabs[1].wins.main.curr", 20, 30)
end

T["vsplit: closing `curr` makes `split` the new `curr`"] = function()
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

T["vsplit: (#425) closing `curr` with only one side buffer and not enough spaces properly resets the state"] = function()
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

T["vsplit: hides side buffers"] = function()
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

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1003, 1000, 1002 })
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })

    child.lua("vim.fn.win_gotoid(1003)")
    child.cmd("q")

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })
    Helpers.expect.state(child, "tabs[1].wins.splits", vim.NIL)
end

T["vsplit: many vsplit leave side buffers open as long as there's space for it"] = function()
    child.lua([[ require('no-neck-pain').setup({width=20}) ]])
    child.nnp()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })

    child.cmd("vsplit")
    child.cmd("vsplit")
    child.wait()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1004, 1003, 1000, 1002 })

    child.cmd("q")

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1003, 1000, 1002 })
    Helpers.expect.state(child, "tabs[_G.NoNeckPain.state.active_tab].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })
end

T["vsplit: keeps correct focus"] = function()
    child.lua([[ require('no-neck-pain').setup({width=10}) ]])
    child.nnp()

    Helpers.expect.equality(child.get_current_win(), 1000)

    child.cmd("vsplit")
    Helpers.expect.equality(child.get_current_win(), 1003)

    child.cmd("vsplit")
    Helpers.expect.equality(child.get_current_win(), 1004)

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1004, 1003, 1000, 1002 })
end

-- =============================================================================
-- vsplit/split
-- =============================================================================

T["vsplit/split: state is correctly sync'd even after many changes"] = function()
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

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1005, 1004, 1000, 1002 })

    child.cmd("q")
    child.cmd("q")

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })
    Helpers.expect.state(child, "tabs[_G.NoNeckPain.state.active_tab].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })
end

T["vsplit/split: closing side buffers because of splits restores focus"] = function()
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
    Helpers.expect.equality(child.get_wins_in_tab(), { 1006, 1007, 1003, 1000 })

    Helpers.expect.equality(child.get_current_win(), 1000)
end

T["vsplit/split: closing help page doesn't break layout"] = function()
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

T["vsplit/split: splits and vsplits keeps a correct size"] = function()
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
    Helpers.expect.buf_width_in_range(child, "1003", 17, 19)
end

T["vsplit/split: side buffer widths restore after split then vsplit then close"] = function()
    child.lua([[ require('no-neck-pain').setup({width=20}) ]])
    child.nnp()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })

    -- Verify initial state with both side buffers
    Helpers.expect.buf_width_in_range(child, "_G.NoNeckPain.state.tabs[1].wins.main.left", 28, 35)
    Helpers.expect.buf_width_in_range(child, "_G.NoNeckPain.state.tabs[1].wins.main.right", 28, 35)

    child.cmd("split")
    child.cmd("vsplit")
    child.wait()

    -- After split and vsplit, side buffers should be smaller due to more columns
    Helpers.expect.buf_width_in_range(child, "_G.NoNeckPain.state.tabs[1].wins.main.left", 15, 25)
    Helpers.expect.buf_width_in_range(child, "_G.NoNeckPain.state.tabs[1].wins.main.right", 15, 25)

    -- Close vsplit and split - verify main window is still centered
    child.cmd("q")
    child.cmd("q")

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })

    -- After closing splits, side buffers should remain valid and proportional
    Helpers.expect.buf_width_in_range(child, "_G.NoNeckPain.state.tabs[1].wins.main.left", 10, 35)
    Helpers.expect.buf_width_in_range(child, "_G.NoNeckPain.state.tabs[1].wins.main.right", 10, 35)
end

T["split/vsplit: split then vsplit then close side buffers reopen"] = function()
    child.lua([[ require('no-neck-pain').setup({width=20}) ]])
    child.nnp()
    child.wait(50)

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })

    local left_before = child.lua_get("_G.NoNeckPain.state.tabs[1].wins.main.left")
    local right_before = child.lua_get("_G.NoNeckPain.state.tabs[1].wins.main.right")
    Helpers.expect.equality(left_before ~= nil and left_before > 0, true)
    Helpers.expect.equality(right_before ~= nil and right_before > 0, true)

    child.cmd("split")
    child.wait(100)

    child.cmd("vsplit")
    child.wait(200)

    local all_wins = child.get_wins_in_tab()

    child.cmd("q")
    child.wait(100)

    child.cmd("q")
    child.wait(200)

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })
    Helpers.expect.equality(child.get_current_win(), 1000)

    local left_after = child.lua_get("_G.NoNeckPain.state.tabs[1].wins.main.left")
    local right_after = child.lua_get("_G.NoNeckPain.state.tabs[1].wins.main.right")

    Helpers.expect.equality(left_after ~= nil and left_after > 0, true)
    Helpers.expect.equality(right_after ~= nil and right_after > 0, true)
end

T["split/vsplit: split then vsplit then close side buffers reopen (with only one side buffer)"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50, buffers={right={enabled=false}}}) ]])
    child.nnp()
    child.wait(50)

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000 })

    local left_before = child.lua_get("_G.NoNeckPain.state.tabs[1].wins.main.left")
    local right_before = child.lua_get("_G.NoNeckPain.state.tabs[1].wins.main.right")
    Helpers.expect.equality(left_before ~= nil and left_before > 0, true)
    Helpers.expect.equality(right_before, vim.NIL)

    child.cmd("split")
    child.wait(100)

    child.cmd("vsplit")
    child.wait(200)

    local all_wins = child.get_wins_in_tab()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1003, 1002, 1000 })
    Helpers.expect.equality(child.get_current_win(), 1003)

    -- close vsplit
    child.cmd("q")
    child.wait(200)

    Helpers.expect.equality(child.get_wins_in_tab(), { 1004, 1002, 1000 })
    Helpers.expect.equality(child.get_current_win(), 1002)

    local left_after = child.lua_get("_G.NoNeckPain.state.tabs[1].wins.main.left")
    local right_after = child.lua_get("_G.NoNeckPain.state.tabs[1].wins.main.right")

    Helpers.expect.equality(left_after ~= nil and left_after > 0, true)
    Helpers.expect.equality(right_after, vim.NIL)
end

return T
