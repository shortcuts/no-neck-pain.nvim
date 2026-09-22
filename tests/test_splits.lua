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

    Helpers.expect.equality(child.get_wins_in_tab(), { 1003, 1000 })
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
    })

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

    -- the vsplit is a genuine extra column: both sides shrink to make room for
    -- it, and `curr` (the col's bottom leaf) spans the two subdivided columns.
    Helpers.expect.state(child, "tabs[1].wins.columns", 4)
    Helpers.expect.buf_width_in_range(child, "_G.NoNeckPain.state.tabs[1].wins.main.left", 18, 21)
    Helpers.expect.buf_width_in_range(child, "_G.NoNeckPain.state.tabs[1].wins.main.right", 18, 21)
    Helpers.expect.buf_width_in_range(child, "_G.NoNeckPain.state.tabs[1].wins.main.curr", 38, 42)
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

    -- the vsplit adds a real column, so both sides shrink to make room for it
    Helpers.expect.buf_width_in_range(child, "_G.NoNeckPain.state.tabs[1].wins.main.left", 18, 21)
    Helpers.expect.buf_width_in_range(child, "_G.NoNeckPain.state.tabs[1].wins.main.right", 18, 21)

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

    -- the vsplit is a real extra column: 2 x 50 leaves no room for the padding,
    -- so it is closed here and recreated once the vsplit goes away
    Helpers.expect.equality(child.get_wins_in_tab(), { 1003, 1002, 1000 })
    Helpers.expect.equality(child.get_current_win(), 1003)
    Helpers.expect.equality(child.lua_get("_G.NoNeckPain.state.tabs[1].wins.main.left"), vim.NIL)

    child.cmd("q")
    child.wait(200)

    Helpers.expect.equality(child.get_wins_in_tab(), { 1004, 1002, 1000 })
    Helpers.expect.equality(child.get_current_win(), 1002)

    local left_after = child.lua_get("_G.NoNeckPain.state.tabs[1].wins.main.left")
    local right_after = child.lua_get("_G.NoNeckPain.state.tabs[1].wins.main.right")

    Helpers.expect.equality(left_after, 1004)
    Helpers.expect.equality(right_after, vim.NIL)
end

T["split/vsplit: vsplitting the main buffer closes the left padding once no room is left (only left enabled)"] = function()
    child.set_size(10, 200)
    child.lua([[ require('no-neck-pain').setup({ buffers = { right = { enabled = false } } }) ]])
    child.nnp()
    child.wait(200)

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000 })

    local left_id = child.lua_get("_G.NoNeckPain.state.tabs[1].wins.main.left")
    Helpers.expect.equality(child.lua_get("vim.api.nvim_win_get_width(" .. left_id .. ")"), 50)
    Helpers.expect.state(child, "tabs[1].wins.columns", 2)

    -- a horizontal split subdivides the main column, it adds none
    child.cmd("split")
    child.wait(200)

    Helpers.expect.state(child, "tabs[1].wins.columns", 2)
    Helpers.expect.equality(child.lua_get("_G.NoNeckPain.state.tabs[1].wins.main.left"), left_id)
    Helpers.expect.equality(child.lua_get("vim.api.nvim_win_get_width(" .. left_id .. ")"), 50)

    -- the vsplit is a real extra column: 2 x 100 fills the 200 available
    -- columns, so the padding no longer fits and must be closed
    child.cmd("vsplit")
    child.wait(300)

    Helpers.expect.equality(child.lua_get("_G.NoNeckPain.state.tabs[1].wins.main.left"), vim.NIL)

    -- closing the vsplit frees the column again, the padding comes back at its
    -- computed width instead of a default half-of-the-column one
    child.cmd("q")
    child.wait(300)

    local left_again = child.lua_get("_G.NoNeckPain.state.tabs[1].wins.main.left")
    Helpers.expect.no_equality(left_again, vim.NIL)
    Helpers.expect.equality(child.lua_get("vim.api.nvim_win_get_width(" .. left_again .. ")"), 50)
end

T["split/vsplit: enabling on an existing horizontal split keeps the padding at its computed width (only left enabled)"] = function()
    child.set_size(10, 200)
    child.lua([[ require('no-neck-pain').setup({ buffers = { right = { enabled = false } } }) ]])

    child.cmd("split")
    child.wait()

    child.nnp()
    child.wait(200)

    local left_id = child.lua_get("_G.NoNeckPain.state.tabs[1].wins.main.left")
    Helpers.expect.no_equality(left_id, vim.NIL)

    -- 200 columns - 100 for the main buffer = 100 spare, halved = 50. The side
    -- is created inside the split and then repositioned with `wincmd H`, which
    -- used to hand it a fresh default width (half of the 200-wide column).
    Helpers.expect.equality(child.lua_get("vim.api.nvim_win_get_width(" .. left_id .. ")"), 50)
    Helpers.assert_sides_full_height(child)
end

T["resize: VimResized is honored after programmatic tab switch"] = function()
    child.lua([[ require('no-neck-pain').setup({ width = 50 }) ]])
    child.nnp()
    child.cmd("tabnew")
    child.lua("vim.api.nvim_set_current_tabpage(vim.api.nvim_list_tabpages()[1])")
    child.set_size(10, 160)
    child.lua("vim.api.nvim_exec_autocmds('VimResized', {})")
    child.wait(50)
    local left_id =
        child.lua_get("_G.NoNeckPain.state.tabs[_G.NoNeckPain.state.active_tab].wins.main.left")
    Helpers.expect.equality(
        child.lua_get(string.format("vim.api.nvim_win_is_valid(%d)", left_id or 0)),
        true
    )
end

T["move_sides: restores eventignore"] = function()
    child.lua([[ require('no-neck-pain').setup({width=20}) ]])
    child.nnp()

    child.lua([[ vim.o.eventignore = "CursorMoved" ]])
    child.lua([[ require('no-neck-pain.ui').move_sides('test') ]])

    Helpers.expect.equality(child.lua_get("vim.o.eventignore"), "CursorMoved")
end

T["vsplit: recreated side buffer spans the full tab height (regression 66d96a5)"] = function()
    child.set_size(30, 200)
    child.lua([[require('no-neck-pain').setup({
        width = 20,
        minSideBufferWidth = 85,
        buffers = { right = { enabled = false } },
    })]])
    child.nnp()
    child.wait(50)

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000 })
    Helpers.assert_sides_full_height(child)

    -- a horizontal split nests `curr` inside a `col`
    child.cmd("split")
    child.wait(50)
    Helpers.expect.state(child, "tabs[1].wins.main.left", 1001)

    -- a full-height vsplit takes a column, leaving no room for the left side
    child.cmd("botright vnew")
    child.wait(100)
    Helpers.expect.state(child, "tabs[1].wins.main.left", vim.NIL)

    -- closing it frees the column, so the side is recreated while the focused
    -- window lives inside the `col`
    child.cmd("close")
    child.wait(200)

    Helpers.expect.state_type(child, "tabs[1].wins.main.left", "number")
    Helpers.assert_sides_full_height(child)
end

return T
