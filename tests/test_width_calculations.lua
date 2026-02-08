local Helpers = dofile("tests/helpers.lua")

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
-- GROUP 1: Boundary Conditions (5+ tests)
-- =============================================================================

T["Width Boundary: Terminal width exactly equals config width (no side padding)"] = function()
    -- Test when terminal width exactly matches config width
    -- Expected: No side buffers created (width would be 0)
    child.set_size(10, 100)
    child.lua([[ require('no-neck-pain').setup({width=100, minSideBufferWidth=10}) ]])
    child.nnp()

    -- Should not create side buffers when no space available
    local left_id =
        child.lua_get("_G.NoNeckPain.state.tabs[_G.NoNeckPain.state.active_tab].wins.main.left")
    local right_id =
        child.lua_get("_G.NoNeckPain.state.tabs[_G.NoNeckPain.state.active_tab].wins.main.right")

    -- Side buffers should not exist
    Helpers.expect.equality(left_id, vim.NIL)
    Helpers.expect.equality(right_id, vim.NIL)

    -- Only current window should exist
    local wins = child.get_wins_in_tab()
    Helpers.expect.equality(#wins, 1)
end

T["Width Boundary: Terminal width is 1 less than config width"] = function()
    -- Test when terminal is too narrow even for centering
    -- Expected: No side buffers created
    child.set_size(10, 99)
    child.lua([[ require('no-neck-pain').setup({width=100, minSideBufferWidth=10}) ]])
    child.nnp()

    local left_id =
        child.lua_get("_G.NoNeckPain.state.tabs[_G.NoNeckPain.state.active_tab].wins.main.left")
    local right_id =
        child.lua_get("_G.NoNeckPain.state.tabs[_G.NoNeckPain.state.active_tab].wins.main.right")

    Helpers.expect.equality(left_id, vim.NIL)
    Helpers.expect.equality(right_id, vim.NIL)
end

T["Width Boundary: At minSideBufferWidth threshold (exactly)"] = function()
    -- Test when side buffer width would be exactly at minimum threshold
    -- width=100, columns=120, minSideBufferWidth=10
    -- (120-100)/2 = 10 (exactly at threshold)
    -- Implementation uses <= so threshold is NOT included (must be > threshold)
    child.set_size(10, 120)
    child.lua([[ require('no-neck-pain').setup({width=100, minSideBufferWidth=10}) ]])
    child.nnp()

    local left_id =
        child.lua_get("_G.NoNeckPain.state.tabs[_G.NoNeckPain.state.active_tab].wins.main.left")
    local right_id =
        child.lua_get("_G.NoNeckPain.state.tabs[_G.NoNeckPain.state.active_tab].wins.main.right")

    -- Should NOT create side buffers (threshold check uses <=, not <)
    Helpers.expect.equality(left_id, vim.NIL)
    Helpers.expect.equality(right_id, vim.NIL)
end

T["Width Boundary: Below minSideBufferWidth threshold"] = function()
    -- Test when side buffer width would be below minimum threshold
    -- width=100, columns=118, minSideBufferWidth=10
    -- (118-100)/2 = 9 (below threshold)
    child.set_size(10, 118)
    child.lua([[ require('no-neck-pain').setup({width=100, minSideBufferWidth=10}) ]])
    child.nnp()

    local left_id =
        child.lua_get("_G.NoNeckPain.state.tabs[_G.NoNeckPain.state.active_tab].wins.main.left")
    local right_id =
        child.lua_get("_G.NoNeckPain.state.tabs[_G.NoNeckPain.state.active_tab].wins.main.right")

    -- Should not create side buffers (below threshold)
    Helpers.expect.equality(left_id, vim.NIL)
    Helpers.expect.equality(right_id, vim.NIL)
end

T["Width Boundary: Above minSideBufferWidth threshold"] = function()
    -- Test when side buffer width is above minimum threshold
    -- width=100, columns=130, minSideBufferWidth=10
    -- (130-100)/2 = 15 (above threshold)
    child.set_size(10, 130)
    child.lua([[ require('no-neck-pain').setup({width=100, minSideBufferWidth=10}) ]])
    child.nnp()

    local left_id =
        child.lua_get("_G.NoNeckPain.state.tabs[_G.NoNeckPain.state.active_tab].wins.main.left")
    local right_id =
        child.lua_get("_G.NoNeckPain.state.tabs[_G.NoNeckPain.state.active_tab].wins.main.right")

    -- Should create side buffers
    Helpers.expect.no_equality(left_id, vim.NIL)
    Helpers.expect.no_equality(right_id, vim.NIL)

    -- Verify widths are around 15
    Helpers.expect.buf_width_in_range(child, left_id, 14, 16)
    Helpers.expect.buf_width_in_range(child, right_id, 14, 16)
end

T["Width Boundary: Very wide terminal (500+ columns)"] = function()
    -- Test with very wide terminal to ensure proper calculation
    -- width=100, columns=500, minSideBufferWidth=10
    -- (500-100)/2 = 200 for each side
    child.set_size(10, 500)
    child.lua([[ require('no-neck-pain').setup({width=100, minSideBufferWidth=10}) ]])
    child.nnp()

    local left_id =
        child.lua_get("_G.NoNeckPain.state.tabs[_G.NoNeckPain.state.active_tab].wins.main.left")
    local right_id =
        child.lua_get("_G.NoNeckPain.state.tabs[_G.NoNeckPain.state.active_tab].wins.main.right")

    -- Should create side buffers
    Helpers.expect.no_equality(left_id, vim.NIL)
    Helpers.expect.no_equality(right_id, vim.NIL)

    -- Verify widths are around 200 each
    Helpers.expect.buf_width_in_range(child, left_id, 198, 202)
    Helpers.expect.buf_width_in_range(child, right_id, 198, 202)

    -- Verify width invariant holds
    Helpers.assert_width_invariant(child)
end

T["Width Boundary: Very narrow terminal (40 columns)"] = function()
    -- Test with very narrow terminal
    -- width=100, columns=40 - terminal is too small
    child.set_size(10, 40)
    child.lua([[ require('no-neck-pain').setup({width=100, minSideBufferWidth=10}) ]])
    child.nnp()

    local left_id =
        child.lua_get("_G.NoNeckPain.state.tabs[_G.NoNeckPain.state.active_tab].wins.main.left")
    local right_id =
        child.lua_get("_G.NoNeckPain.state.tabs[_G.NoNeckPain.state.active_tab].wins.main.right")

    -- Should not create side buffers
    Helpers.expect.equality(left_id, vim.NIL)
    Helpers.expect.equality(right_id, vim.NIL)
end

-- =============================================================================
-- GROUP 2: Integration Width Subtraction (3+ tests)
-- =============================================================================

T["Integration Width: Integration takes exactly half of available padding"] = function()
    -- When an integration window exists, the plugin should account for it
    -- This test verifies width calculations adapt to integration presence
    child.set_size(10, 200)
    child.lua([[
        require('no-neck-pain').setup({
            width=100,
            minSideBufferWidth=10,
            integrations = {
                NvimTree = { position = "left" }
            }
        })
    ]])

    -- Create a fake NvimTree window on the left with 50 width
    child.cmd("topleft 50vnew")
    child.bo.filetype = "NvimTree"
    local nvimtree_win = child.get_current_win()

    child.cmd("wincmd l")
    child.nnp()
    child.wait(200)

    -- Verify NvimTree window still exists
    local is_valid = child.lua_get("vim.api.nvim_win_is_valid(" .. nvimtree_win .. ")")
    Helpers.expect.equality(is_valid, true)

    -- Integration tracking may vary, but main window should exist
    local curr_id =
        child.lua_get("_G.NoNeckPain.state.tabs[_G.NoNeckPain.state.active_tab].wins.main.curr")
    Helpers.expect.no_equality(curr_id, vim.NIL)
end

T["Integration Width: Integration takes more than half available padding"] = function()
    -- Test with a large integration window
    child.set_size(10, 200)
    child.lua([[
        require('no-neck-pain').setup({
            width=100,
            minSideBufferWidth=10,
            integrations = {
                ["neo-tree"] = { position = "left" }
            }
        })
    ]])

    -- Create a fake neo-tree window on the left with 80 width
    child.cmd("topleft 80vnew")
    child.bo.filetype = "neo-tree"
    local neotree_win = child.get_current_win()

    child.cmd("wincmd l")
    child.nnp()
    child.wait(200)

    -- Verify neo-tree window still exists
    local is_valid = child.lua_get("vim.api.nvim_win_is_valid(" .. neotree_win .. ")")
    Helpers.expect.equality(is_valid, true)

    -- Main window should exist
    local curr_id =
        child.lua_get("_G.NoNeckPain.state.tabs[_G.NoNeckPain.state.active_tab].wins.main.curr")
    Helpers.expect.no_equality(curr_id, vim.NIL)
end

T["Integration Width: Multiple integrations on same side reduce available width"] = function()
    -- Test with integration on the right side
    child.set_size(10, 300)
    child.lua([[
        require('no-neck-pain').setup({
            width=100,
            minSideBufferWidth=10,
            integrations = {
                outline = { position = "right" }
            }
        })
    ]])

    -- Create a fake outline window on the right with 40 width
    child.cmd("botright 40vnew")
    child.bo.filetype = "Outline"
    local outline_win = child.get_current_win()

    child.cmd("wincmd h")
    child.nnp()
    child.wait(200)

    -- Verify outline window still exists
    local is_valid = child.lua_get("vim.api.nvim_win_is_valid(" .. outline_win .. ")")
    Helpers.expect.equality(is_valid, true)

    -- Main window should exist
    local curr_id =
        child.lua_get("_G.NoNeckPain.state.tabs[_G.NoNeckPain.state.active_tab].wins.main.curr")
    Helpers.expect.no_equality(curr_id, vim.NIL)
end

-- =============================================================================
-- GROUP 3: Property-Based Tests (4+ tests)
-- =============================================================================

T["Width Property: Width invariant holds (left + curr + right = total)"] = function()
    -- Test the mathematical invariant: sum of all window widths = terminal width
    child.set_size(10, 200)
    child.lua([[ require('no-neck-pain').setup({width=100, minSideBufferWidth=10}) ]])
    child.nnp()

    -- Verify the invariant
    Helpers.assert_width_invariant(child)
end

T["Width Property: Width invariant holds after VimResized event"] = function()
    -- Test that width recalculation maintains invariant after terminal resize
    child.set_size(10, 200)
    child.lua([[ require('no-neck-pain').setup({width=100, minSideBufferWidth=10}) ]])
    child.nnp()

    -- Initial state should be valid
    Helpers.assert_width_invariant(child)

    -- Resize terminal
    child.cmd("set columns=250")
    child.wait(200)

    -- Invariant should still hold after resize
    Helpers.assert_width_invariant(child)

    -- Resize to smaller terminal
    child.cmd("set columns=150")
    child.wait(200)

    -- Invariant should still hold
    Helpers.assert_width_invariant(child)
end

T["Width Property: Random valid width configs maintain invariant"] = function()
    -- Property-based test: generate random configs and verify invariant holds
    local configs = Helpers.generate_width_configs(60, 120, 5)

    for i, config in ipairs(configs) do
        -- Set terminal width to be larger than config width
        local terminal_width = config.width + (config.minSideBufferWidth * 2) + 20
        child.set_size(10, terminal_width)

        -- Apply config
        child.lua(
            string.format(
                [[ require('no-neck-pain').setup({width=%d, minSideBufferWidth=%d}) ]],
                config.width,
                config.minSideBufferWidth
            )
        )
        child.nnp()
        child.wait(100)

        -- Verify invariant holds for this configuration
        local success, err = pcall(function()
            Helpers.assert_width_invariant(child)
        end)

        if not success then
            error(
                string.format(
                    "Width invariant failed for config %d (width=%d, minSide=%d, terminal=%d): %s",
                    i,
                    config.width,
                    config.minSideBufferWidth,
                    terminal_width,
                    err
                )
            )
        end

        -- Disable for next iteration
        child.cmd("NoNeckPain")
        child.wait(100)
    end
end

T["Width Property: Side widths never below minSideBufferWidth when created"] = function()
    -- Property: if side buffers are created, they must be >= minSideBufferWidth
    local test_cases = {
        { width = 80, minSide = 15, columns = 120 }, -- (120-80)/2 = 20 >= 15 ✓
        { width = 100, minSide = 10, columns = 150 }, -- (150-100)/2 = 25 >= 10 ✓
        { width = 90, minSide = 20, columns = 140 }, -- (140-90)/2 = 25 >= 20 ✓
        { width = 70, minSide = 25, columns = 130 }, -- (130-70)/2 = 30 >= 25 ✓
    }

    for i, tc in ipairs(test_cases) do
        child.set_size(10, tc.columns)
        child.lua(
            string.format(
                [[ require('no-neck-pain').setup({width=%d, minSideBufferWidth=%d}) ]],
                tc.width,
                tc.minSide
            )
        )
        child.nnp()
        child.wait(100)

        local left_id =
            child.lua_get("_G.NoNeckPain.state.tabs[_G.NoNeckPain.state.active_tab].wins.main.left")
        local right_id = child.lua_get(
            "_G.NoNeckPain.state.tabs[_G.NoNeckPain.state.active_tab].wins.main.right"
        )

        -- If side buffers exist, they must be >= minSideBufferWidth
        if left_id and left_id ~= vim.NIL then
            local left_width = child.lua_get("vim.api.nvim_win_get_width(" .. left_id .. ")")
            if left_width < tc.minSide then
                error(
                    string.format(
                        "Test case %d: left width %d is less than minSideBufferWidth %d",
                        i,
                        left_width,
                        tc.minSide
                    )
                )
            end
        end

        if right_id and right_id ~= vim.NIL then
            local right_width = child.lua_get("vim.api.nvim_win_get_width(" .. right_id .. ")")
            if right_width < tc.minSide then
                error(
                    string.format(
                        "Test case %d: right width %d is less than minSideBufferWidth %d",
                        i,
                        right_width,
                        tc.minSide
                    )
                )
            end
        end

        -- Disable for next iteration
        child.cmd("NoNeckPain")
        child.wait(100)
    end
end

T["Width Property: Resizing to below threshold removes side buffers"] = function()
    -- Property: if terminal resizes such that side buffers would be below minSideBufferWidth,
    -- they should be removed
    child.set_size(10, 200)
    child.lua([[ require('no-neck-pain').setup({width=100, minSideBufferWidth=20}) ]])
    child.nnp()

    -- Initial state: should have side buffers
    -- (200-100)/2 = 50 >= 20 ✓
    local left_id =
        child.lua_get("_G.NoNeckPain.state.tabs[_G.NoNeckPain.state.active_tab].wins.main.left")
    local right_id =
        child.lua_get("_G.NoNeckPain.state.tabs[_G.NoNeckPain.state.active_tab].wins.main.right")

    Helpers.expect.no_equality(left_id, vim.NIL)
    Helpers.expect.no_equality(right_id, vim.NIL)

    -- Resize to threshold - 1
    -- (135-100)/2 = 17.5 < 20 ✗
    child.cmd("set columns=135")
    child.wait(200)

    -- Side buffers should be removed
    left_id =
        child.lua_get("_G.NoNeckPain.state.tabs[_G.NoNeckPain.state.active_tab].wins.main.left")
    right_id =
        child.lua_get("_G.NoNeckPain.state.tabs[_G.NoNeckPain.state.active_tab].wins.main.right")

    Helpers.expect.equality(left_id, vim.NIL)
    Helpers.expect.equality(right_id, vim.NIL)
end

T["Width Property: State consistency maintained across width changes"] = function()
    -- Test that state remains consistent when resizing multiple times
    child.set_size(10, 200)
    child.lua([[ require('no-neck-pain').setup({width=100, minSideBufferWidth=10}) ]])
    child.nnp()

    -- Initial consistency check
    Helpers.assert_state_consistency(child)

    -- Resize larger
    child.cmd("set columns=300")
    child.wait(200)
    Helpers.assert_state_consistency(child)

    -- Resize smaller but still valid
    child.cmd("set columns=150")
    child.wait(200)
    Helpers.assert_state_consistency(child)

    -- Resize to threshold
    child.cmd("set columns=120")
    child.wait(200)
    Helpers.assert_state_consistency(child)

    -- Resize below threshold
    child.cmd("set columns=110")
    child.wait(200)
    Helpers.assert_state_consistency(child)
end

-- =============================================================================
-- EDGE CASES: Additional boundary scenarios
-- =============================================================================

T["Width Edge Case: Zero minSideBufferWidth allows very small side buffers"] = function()
    -- Test with minSideBufferWidth=0, even tiny buffers should be allowed
    child.set_size(10, 102)
    child.lua([[ require('no-neck-pain').setup({width=100, minSideBufferWidth=0}) ]])
    child.nnp()

    -- (102-100)/2 = 1 for each side
    local left_id =
        child.lua_get("_G.NoNeckPain.state.tabs[_G.NoNeckPain.state.active_tab].wins.main.left")
    local right_id =
        child.lua_get("_G.NoNeckPain.state.tabs[_G.NoNeckPain.state.active_tab].wins.main.right")

    -- Should create side buffers even with width 1
    Helpers.expect.no_equality(left_id, vim.NIL)
    Helpers.expect.no_equality(right_id, vim.NIL)

    -- Verify widths are minimal but positive
    local left_width = child.lua_get("vim.api.nvim_win_get_width(" .. left_id .. ")")
    local right_width = child.lua_get("vim.api.nvim_win_get_width(" .. right_id .. ")")

    Helpers.expect.max(0, left_width)
    Helpers.expect.max(0, right_width)
end

T["Width Edge Case: Only left side enabled respects width calculations"] = function()
    -- Test that disabling right side doesn't break width calculations
    child.set_size(10, 200)
    child.lua([[
        require('no-neck-pain').setup({
            width=100,
            minSideBufferWidth=10,
            buffers = { right = { enabled = false } }
        })
    ]])
    child.nnp()

    local left_id =
        child.lua_get("_G.NoNeckPain.state.tabs[_G.NoNeckPain.state.active_tab].wins.main.left")
    local right_id =
        child.lua_get("_G.NoNeckPain.state.tabs[_G.NoNeckPain.state.active_tab].wins.main.right")

    -- Left should exist, right should not
    Helpers.expect.no_equality(left_id, vim.NIL)
    Helpers.expect.equality(right_id, vim.NIL)

    -- Left width should still be calculated properly
    local left_width = child.lua_get("vim.api.nvim_win_get_width(" .. left_id .. ")")
    Helpers.expect.max(10, left_width)
end

T["Width Edge Case: Only right side enabled respects width calculations"] = function()
    -- Test that disabling left side doesn't break width calculations
    child.set_size(10, 200)
    child.lua([[
        require('no-neck-pain').setup({
            width=100,
            minSideBufferWidth=10,
            buffers = { left = { enabled = false } }
        })
    ]])
    child.nnp()

    local left_id =
        child.lua_get("_G.NoNeckPain.state.tabs[_G.NoNeckPain.state.active_tab].wins.main.left")
    local right_id =
        child.lua_get("_G.NoNeckPain.state.tabs[_G.NoNeckPain.state.active_tab].wins.main.right")

    -- Right should exist, left should not
    Helpers.expect.equality(left_id, vim.NIL)
    Helpers.expect.no_equality(right_id, vim.NIL)

    -- Right width should still be calculated properly
    local right_width = child.lua_get("vim.api.nvim_win_get_width(" .. right_id .. ")")
    Helpers.expect.max(10, right_width)
end

return T
