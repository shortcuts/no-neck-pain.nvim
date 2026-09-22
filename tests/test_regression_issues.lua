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

T["regression #514: layout consistency after help split close/re-split"] = function()
    child.set_size(10, 200)
    child.lua([[require('no-neck-pain').setup({ width = 100 })]])

    child.nnp()
    child.wait()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })

    local baseline_left = child.lua_get("vim.api.nvim_win_get_width(1001)")
    local baseline_curr = child.lua_get("vim.api.nvim_win_get_width(1000)")
    local baseline_right = child.lua_get("vim.api.nvim_win_get_width(1002)")

    for cycle = 1, 3 do
        child.cmd("help")
        child.wait()

        child.cmd("close")
        child.wait()

        local left_width = child.lua_get("vim.api.nvim_win_get_width(1001)")
        local curr_width = child.lua_get("vim.api.nvim_win_get_width(1000)")
        local right_width = child.lua_get("vim.api.nvim_win_get_width(1002)")

        if math.abs(left_width - baseline_left) >= 2 then
            error(
                string.format(
                    "Cycle %d: left width drifted from %d to %d",
                    cycle,
                    baseline_left,
                    left_width
                )
            )
        end

        if math.abs(curr_width - baseline_curr) >= 2 then
            error(
                string.format(
                    "Cycle %d: curr width drifted from %d to %d",
                    cycle,
                    baseline_curr,
                    curr_width
                )
            )
        end

        if math.abs(right_width - baseline_right) >= 2 then
            error(
                string.format(
                    "Cycle %d: right width drifted from %d to %d",
                    cycle,
                    baseline_right,
                    right_width
                )
            )
        end
    end

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })
end

T["regression #517: side buffers shrink then close when a vsplit opens, and reopen when it closes"] = function()
    child.set_size(50, 200)
    child.lua([[require('no-neck-pain').setup({ width = 60 })]])

    child.nnp()
    child.wait()

    Helpers.expect.equality(child.lua_get("vim.api.nvim_win_get_width(1001)"), 70)
    Helpers.expect.equality(child.lua_get("vim.api.nvim_win_get_width(1002)"), 70)

    child.cmd("vsplit")
    child.wait()

    local wins_after_shrink = child.get_wins_in_tab()
    Helpers.expect.equality(vim.tbl_contains(wins_after_shrink, 1001), true)
    Helpers.expect.equality(vim.tbl_contains(wins_after_shrink, 1002), true)
    Helpers.expect.equality(child.lua_get("vim.api.nvim_win_get_width(1001)"), 40)
    Helpers.expect.equality(child.lua_get("vim.api.nvim_win_get_width(1002)"), 40)

    child.restart({ "-u", "scripts/minimal_init.lua" })
    child.set_size(30, 120)
    child.lua([[require('no-neck-pain').setup({ width = 100 })]])

    child.nnp()
    child.wait()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })
    Helpers.expect.equality(child.lua_get("vim.api.nvim_win_get_width(1001)"), 10)
    Helpers.expect.equality(child.lua_get("vim.api.nvim_win_get_width(1002)"), 10)

    child.cmd("vsplit")
    child.wait()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1003, 1000 })
    Helpers.expect.state(child, "tabs[1].wins.main", { curr = 1000 })

    child.cmd("q")
    child.wait()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1004, 1000, 1005 })
    Helpers.expect.state(child, "tabs[1].wins.main", { curr = 1000, left = 1004, right = 1005 })
    Helpers.expect.equality(child.lua_get("vim.api.nvim_win_get_width(1004)"), 10)
    Helpers.expect.equality(child.lua_get("vim.api.nvim_win_get_width(1005)"), 10)
end

T['regression #470: dap-ui with dap.position = "none" collapses the left side below minSideBufferWidth'] = function()
    child.restart({ "-u", "scripts/init_with_nvimdapui.lua" })
    child.set_size(50, 200)
    child.lua([[
        require('no-neck-pain').setup({
            width = 140,
            buffers = {
                right = { enabled = false },
            },
            integrations = {
                dap = { position = "none" },
            },
        })
    ]])

    child.nnp()
    child.wait()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000 })
    Helpers.expect.state(child, "tabs[1].wins.main", { curr = 1000, left = 1001 })

    child.lua([[require('dapui').open()]])
    child.wait()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1009, 1008, 1007, 1006, 1000, 1005, 1002 })
    Helpers.expect.state(child, "tabs[1].wins.main", { curr = 1000 })
end

T['regression #470: dap-ui with dap.position = "right" keeps the main buffer width stable (right side disabled)'] = function()
    child.restart({ "-u", "scripts/init_with_nvimdapui.lua" })
    child.set_size(50, 200)
    child.lua([[
        require('no-neck-pain').setup({
            width = 140,
            buffers = {
                right = { enabled = false },
            },
            integrations = {
                dap = { position = "right" },
            },
        })
    ]])

    child.nnp()
    child.wait()

    local curr_id =
        child.lua_get("_G.NoNeckPain.state.tabs[_G.NoNeckPain.state.active_tab].wins.main.curr")

    child.lua([[require('dapui').open()]])
    child.wait()

    local curr_after = child.lua_get("vim.api.nvim_win_get_width(" .. curr_id .. ")")

    -- with the dapui sidebar (a real, side-positioned column NNP does not
    -- control) taking real screen width on the right, the main buffer can no
    -- longer keep the exact width it had before dapui opened (there simply
    -- isn't room for both): the meaningful stability guarantee is that it
    -- settles back at the user's configured `width` instead of being left
    -- with whatever nvim's own window-close/split redistribution happens to
    -- hand it (the original #470 regression, e.g. shrinking to under 110).
    if math.abs(curr_after - 140) >= 3 then
        error(
            string.format(
                'main buffer width is %d after opening dapui with dap.position = "right", expected ~140 (config.width)',
                curr_after
            )
        )
    end
end

T['regression #470: dap-ui with dap.position = "right" keeps the main buffer width stable (both sides enabled)'] = function()
    child.restart({ "-u", "scripts/init_with_nvimdapui.lua" })
    child.set_size(50, 200)
    child.lua([[
        require('no-neck-pain').setup({
            width = 140,
            integrations = {
                dap = { position = "right" },
            },
        })
    ]])

    child.nnp()
    child.wait()

    local curr_id =
        child.lua_get("_G.NoNeckPain.state.tabs[_G.NoNeckPain.state.active_tab].wins.main.curr")

    child.lua([[require('dapui').open()]])
    child.wait()

    local curr_after = child.lua_get("vim.api.nvim_win_get_width(" .. curr_id .. ")")

    -- see the comment in the right-side-disabled variant above: the
    -- reachable stability guarantee is settling back at `config.width`.
    if math.abs(curr_after - 140) >= 3 then
        error(
            string.format(
                'main buffer width is %d after opening dapui with dap.position = "right", expected ~140 (config.width)',
                curr_after
            )
        )
    end
end

T["regression #507: closing window with splits does not exit nvim"] = function()
    child.set_size(10, 200)
    child.lua([[require('no-neck-pain').setup({ width = 100 })]])

    child.nnp()
    child.wait()

    local main_id =
        child.lua_get("_G.NoNeckPain.state.tabs[_G.NoNeckPain.state.active_tab].wins.main.curr")

    for _ = 1, 2 do
        child.cmd("vsplit")
        child.wait()

        child.cmd("close")
        child.wait()
    end

    Helpers.expect.state(child, "enabled", true)

    local main_valid = child.lua_get("vim.api.nvim_win_is_valid(" .. main_id .. ")")
    Helpers.expect.equality(main_valid, true)
end

T["regression #444: plugin works with unfamiliar filetype windows"] = function()
    child.set_size(10, 200)
    child.lua([[
        require('no-neck-pain').setup({
            width = 100,
            integrations = {
                edgy = { position = "left" },
            },
        })
    ]])

    child.nnp()
    child.wait()

    child.cmd("topleft 30vnew")
    child.wait()
    child.bo.filetype = "edgy"
    child.wait()

    child.cmd("wincmd l")
    child.wait()

    local total_cols = child.o.columns
    local wins = child.get_wins_in_tab()

    local sum = 0
    for _, win_id in ipairs(wins) do
        sum = sum + child.lua_get("vim.api.nvim_win_get_width(" .. win_id .. ")")
    end

    local separators = #wins - 1
    local effective_sum = sum + separators

    if math.abs(effective_sum - total_cols) > 2 then
        error(
            string.format(
                "Width invariant failed: sum(%d) + separators(%d) = %d, expected ~%d",
                sum,
                separators,
                effective_sum,
                total_cols
            )
        )
    end
end

T["regression #227: side buffers restore width after external resize"] = function()
    child.set_size(10, 200)
    child.lua([[require('no-neck-pain').setup({ width = 100 })]])

    child.nnp()
    child.wait()

    local baseline_left = child.lua_get("vim.api.nvim_win_get_width(1001)")
    local baseline_right = child.lua_get("vim.api.nvim_win_get_width(1002)")

    child.lua("vim.api.nvim_win_set_width(1001, 10)")
    child.wait()

    Helpers.expect.state(child, "enabled", true)

    child.nnp()
    child.wait()
    child.nnp()
    child.wait()

    local left_id =
        child.lua_get("_G.NoNeckPain.state.tabs[_G.NoNeckPain.state.active_tab].wins.main.left")
    local right_id =
        child.lua_get("_G.NoNeckPain.state.tabs[_G.NoNeckPain.state.active_tab].wins.main.right")

    local left_new = child.lua_get("vim.api.nvim_win_get_width(" .. left_id .. ")")
    local right_new = child.lua_get("vim.api.nvim_win_get_width(" .. right_id .. ")")

    if math.abs(left_new - baseline_left) >= 2 then
        error(
            string.format(
                "Left width not restored after toggle: now %d (baseline %d)",
                left_new,
                baseline_left
            )
        )
    end

    if math.abs(right_new - baseline_right) >= 2 then
        error(
            string.format(
                "Right width drifted after toggle: now %d (baseline %d)",
                right_new,
                baseline_right
            )
        )
    end

    Helpers.assert_width_invariant(child)
end

T["regression #436: enableOnVimEnter with deferred filetype buffer"] = function()
    child.restart({ "-u", "scripts/init_auto_open.lua" })
    child.set_size(10, 200)
    child.wait(200)

    Helpers.expect.state(child, "enabled", true)

    child.bo.filetype = "man"
    child.wait()

    Helpers.expect.state(child, "enabled", true)

    local wins = child.get_wins_in_tab()
    Helpers.expect.equality(#wins, 3)

    Helpers.assert_width_invariant(child)
end

T["regression #297: custom user-defined integrations are recognized"] = function()
    child.set_size(10, 200)
    child.lua([[
        require('no-neck-pain').setup({
            width = 100,
            integrations = {
                my_custom_tree = { position = "left" },
            },
        })
    ]])

    child.nnp()
    child.wait()

    child.cmd("topleft 30vnew")
    child.wait()
    child.bo.filetype = "my_custom_tree"
    child.wait()

    child.cmd("wincmd l")
    child.wait()

    local total_cols = child.o.columns
    local wins = child.get_wins_in_tab()

    local sum = 0
    for _, win_id in ipairs(wins) do
        sum = sum + child.lua_get("vim.api.nvim_win_get_width(" .. win_id .. ")")
    end

    local separators = #wins - 1
    local effective_sum = sum + separators

    if math.abs(effective_sum - total_cols) > 2 then
        error(
            string.format(
                "Width invariant failed: sum(%d) + separators(%d) = %d, expected ~%d",
                sum,
                separators,
                effective_sum,
                total_cols
            )
        )
    end
end

T["regression: FileType safety net never disables the plugin on an integration filetype"] = function()
    child.set_size(10, 200)

    local setup = [[require('no-neck-pain').setup({
        width = 50,
        minSideBufferWidth = 5,
        autocmds = { enableOnVimEnter = true },
    })]]

    child.lua(setup)
    child.nnp()
    child.wait()

    Helpers.expect.state(child, "enabled", true)
    Helpers.expect.equality(#child.get_wins_in_tab(), 3)

    -- The first BufEnter after an enable deletes NoNeckPainVimEnterAutocmd, so
    -- re-run setup to re-arm the FileType net while the plugin is enabled: that is
    -- the window in which the net used to call NoNeckPain.disable().
    child.lua(setup)
    child.wait()

    child.bo.filetype = "NvimTree"
    child.wait()

    Helpers.expect.state(child, "enabled", true)
    Helpers.expect.equality(#child.get_wins_in_tab(), 3)
end

T["regression: move_sides ignores user <C-W>H / <C-W>L mappings"] = function()
    child.set_size(10, 200)
    child.lua([[require('no-neck-pain').setup({ width = 100 })]])

    child.nnp()
    child.wait()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })

    -- A user remapping the window-move keys must not be able to intercept the
    -- side repositioning: `:wincmd` ignores mappings, `:normal` did not.
    child.lua([[
        _G.hijacked = false
        vim.keymap.set("n", "<C-W>H", function() _G.hijacked = true end)
        vim.keymap.set("n", "<C-W>L", function() _G.hijacked = true end)
    ]])

    child.lua([[require('no-neck-pain.ui').move_sides("test")]])
    child.wait()

    Helpers.expect.equality(child.lua_get("_G.hijacked"), false)

    -- and the layout is still the one NNP believes it has
    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })
end

return T
