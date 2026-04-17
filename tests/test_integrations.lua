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
-- setup
-- =============================================================================

T["setup: sets default values"] = function()
    child.nnp()

    Helpers.expect.state(child, "tabs[1].wins.integrations", {
        ["neo-tree"] = {
            position = "left",
        },
        dap = {
            position = "none",
        },
        nvimtree = {
            position = "left",
        },
        aerial = {
            position = "right",
        },
        dashboard = {
            enabled = false,
            filetypes = { "dashboard", "alpha", "starter", "snacks" },
        },
        neotest = {
            position = "right",
        },
        oil = {
            position = "none",
        },
        outline = {
            position = "right",
        },
        snacks_picker = {
            position = "left",
        },
        undotree = {
            position = "left",
        },
    })
end

T["setup: overrides default values and add new entries"] = function()
    child.lua([[require('no-neck-pain').setup({
         integrations = {
             NvimTree = {
                 position = "right",
             },
             ["neo-tree"] = {
                 position = "right",
             },
             dap = {
                 position = "right",
             },
             undotree = {
                 position = "right",
             },
             neotest = {
             },
             outline = {
                 position = "left",
             },
             aerial = {
                 position = "left",
             },
             dashboard = {
                 enabled = true,
                 filetypes = { "dashboard", "alpha", "starter", "snacks" }
             },
             FOOBAR = { 
                 position = "left"
            }
         }
      })]])
    child.cmd("NoNeckPain")
    child.wait()

    Helpers.expect.state(child, "tabs[1].wins.integrations", {
        ["neo-tree"] = {
            position = "right",
        },
        dap = {
            position = "right",
        },
        nvimtree = {
            position = "right",
        },
        neotest = {
            position = "right",
        },
        undotree = {
            position = "right",
        },
        outline = {
            position = "left",
        },
        aerial = {
            position = "left",
        },
        dashboard = {
            enabled = true,
            filetypes = { "dashboard", "alpha", "starter", "snacks" },
        },
        oil = {
            position = "none",
        },
        snacks_picker = {
            position = "left",
        },
        foobar = {
            position = "left",
        },
    })
end

-- =============================================================================
-- checkhealth
-- =============================================================================

T["checkhealth: state is in sync"] = function()
    child.lua([[ require('no-neck-pain').setup({width=20}) ]])
    child.nnp()
    child.wait()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })

    child.cmd("checkhealth")
    child.wait()

    if child.fn.has("nvim-0.10") == 0 then
        Helpers.expect.equality(child.get_wins_in_tab(), { 1004 })

        child.nnp()
        child.wait()

        Helpers.expect.equality(child.get_wins_in_tab(), { 1005, 1004, 1006 })
        Helpers.expect.state(child, "tabs[2].wins.main", {
            curr = 1004,
            left = 1005,
            right = 1006,
        })
    else
        Helpers.expect.equality(child.get_wins_in_tab(), { 1003 })

        child.nnp()
        child.wait()

        Helpers.expect.equality(child.get_wins_in_tab(), { 1004, 1003, 1005 })
        Helpers.expect.state(child, "tabs[2].wins.main", {
            curr = 1003,
            left = 1004,
            right = 1005,
        })
    end

    child.cmd("q")
    child.wait()

    Helpers.expect.state(child, "tabs[2]", vim.NIL)

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })
end

T["checkhealth: auto opens side buffers"] = function()
    child.restart({ "-u", "scripts/init_auto_open.lua" })
    child.cmd("e test.lua")
    child.wait(200)

    Helpers.expect.equality(child.get_wins_in_tab(1), { 1001, 1000, 1002 })
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })

    child.cmd("checkhealth")
    child.wait()

    if child.fn.has("nvim-0.10") == 0 then
        Helpers.expect.equality(child.get_wins_in_tab(2), { 1005, 1004, 1006 })
        Helpers.expect.state(child, "tabs[2].wins.main", {
            curr = 1004,
            left = 1005,
            right = 1006,
        })
    else
        Helpers.expect.equality(child.get_wins_in_tab(2), { 1004, 1003, 1005 })
        Helpers.expect.state(child, "tabs[2].wins.main", {
            curr = 1003,
            left = 1004,
            right = 1005,
        })
    end

    child.cmd("q")
    child.wait()

    Helpers.expect.state(child, "tabs[2]", vim.NIL)

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })
end

-- =============================================================================
-- nvimdapui
-- =============================================================================

T["nvimdapui: keeps sides open"] = function()
    child.restart({ "-u", "scripts/init_with_nvimdapui.lua" })

    child.nnp()
    child.wait()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })

    child.lua([[require('dapui').open()]])
    child.wait()

    Helpers.expect.equality(
        child.get_wins_in_tab(),
        { 1001, 1010, 1009, 1008, 1007, 1000, 1006, 1003, 1002 }
    )

    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })

    Helpers.expect.state(child, "tabs[1].wins.columns", 5)
end

T["nvimdapui: toggle width stability (issue #470)"] = function()
    child.restart({ "-u", "scripts/init_with_nvimdapui.lua" })

    child.nnp()
    child.wait()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })

    local baseline_left = child.lua_get("vim.api.nvim_win_get_width(1001)")
    local baseline_right = child.lua_get("vim.api.nvim_win_get_width(1002)")

    for cycle = 1, 3 do
        child.lua([[require('dapui').open()]])
        child.wait()

        child.lua([[require('dapui').close()]])
        child.wait()

        local left_id = child.lua_get(
            "_G.NoNeckPain.state.tabs[_G.NoNeckPain.state.active_tab].wins.main.left"
        )
        local right_id = child.lua_get(
            "_G.NoNeckPain.state.tabs[_G.NoNeckPain.state.active_tab].wins.main.right"
        )

        if left_id == vim.NIL or right_id == vim.NIL then
            error(string.format("Cycle %d: side buffers lost after dap toggle", cycle))
        end

        local left_width = child.lua_get("vim.api.nvim_win_get_width(" .. left_id .. ")")
        local right_width = child.lua_get("vim.api.nvim_win_get_width(" .. right_id .. ")")

        if math.abs(left_width - baseline_left) >= 2 then
            error(string.format(
                "Cycle %d: left width drifted from %d to %d",
                cycle, baseline_left, left_width
            ))
        end

        if math.abs(right_width - baseline_right) >= 2 then
            error(string.format(
                "Cycle %d: right width drifted from %d to %d",
                cycle, baseline_right, right_width
            ))
        end

        Helpers.assert_width_invariant(child)
    end
end

-- =============================================================================
-- neotest
-- =============================================================================

T["neotest: keeps sides open"] = function()
    child.restart({ "-u", "scripts/init_with_neotest.lua", "lua/no-neck-pain/main.lua" })

    child.nnp()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })

    child.lua([[require('neotest').summary.open()]])

    Helpers.expect.state(child, "tabs[1].wins.columns", 4)

    Helpers.expect.state(child, "tabs[1].wins.integrations.neotest", {
        id = 1003,
        position = "right",
    })
end

-- =============================================================================
-- outline
-- =============================================================================

T["outline: keeps sides open"] = function()
    child.restart({ "-u", "scripts/init_with_outline.lua", "lua/no-neck-pain/main.lua" })

    child.nnp()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })

    child.cmd("Outline")
    child.wait()

    Helpers.expect.state(child, "tabs[1].wins.columns", 4)

    Helpers.expect.state(child, "tabs[1].wins.integrations.outline", {
        id = 1004,
        position = "right",
    })
end

-- =============================================================================
-- NvimTree
-- =============================================================================

T["NvimTree: keeps sides open"] = function()
    child.restart({ "-u", "scripts/init_with_nvimtree.lua", "foo" })

    child.nnp()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })

    Helpers.expect.state(child, "enabled", true)
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })

    child.cmd([[NvimTreeOpen]])

    Helpers.expect.equality(child.get_wins_in_tab(), { 1004, 1001, 1000, 1002 })

    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })

    Helpers.expect.state(child, "tabs[1].wins.columns", 4)

    Helpers.expect.state(child, "tabs[1].wins.integrations.nvimtree", {
        id = 1004,
        position = "left",
    })
end

-- =============================================================================
-- neo-tree
-- =============================================================================

T["neo-tree: keeps sides open"] = function()
    child.restart({ "-u", "scripts/init_with_neotree.lua", "foo" })

    child.nnp()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })

    Helpers.expect.state(child, "enabled", true)
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })

    child.cmd([[Neotree reveal]])
    child.wait()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1004, 1000, 1002 })

    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })

    Helpers.expect.state(child, "tabs[1].wins.columns", 4)

    Helpers.expect.state(child, "tabs[1].wins.integrations", {
        aerial = {
            position = "right",
        },
        dap = {
            position = "none",
        },
        dashboard = {
            enabled = false,
            filetypes = { "dashboard", "alpha", "starter", "snacks" },
        },
        ["neo-tree"] = {
            id = 1004,
            position = "left",
        },
        neotest = {
            position = "right",
        },
        nvimtree = {
            position = "left",
        },
        oil = {
            position = "none",
        },
        outline = {
            position = "right",
        },
        snacks_picker = {
            position = "left",
        },
        undotree = {
            position = "left",
        },
    })

    child.nnp()
    child.nnp()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1004, 1005, 1000, 1006 })

    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1005,
        right = 1006,
    })

    Helpers.expect.state(child, "tabs[1].wins.columns", 4)

    Helpers.expect.state(child, "tabs[1].wins.integrations", {
        aerial = {
            position = "right",
        },
        dap = {
            position = "none",
        },
        dashboard = {
            enabled = false,
            filetypes = { "dashboard", "alpha", "starter", "snacks" },
        },
        ["neo-tree"] = {
            id = 1004,
            position = "left",
        },
        neotest = {
            position = "right",
        },
        nvimtree = {
            position = "left",
        },
        oil = {
            position = "none",
        },
        outline = {
            position = "right",
        },
        snacks_picker = {
            position = "left",
        },
        undotree = {
            position = "left",
        },
    })
end

T["neo-tree: properly enables nnp with tree already opened"] = function()
    child.restart({ "-u", "scripts/init_with_neotree.lua", "." })

    Helpers.expect.equality(child.get_wins_in_tab(1), { 1002, 1000 })

    child.cmd("e Makefile")

    child.nnp()

    if child.fn.has("nvim-0.10") == 0 then
        Helpers.expect.equality(child.get_wins_in_tab(), { 1003, 1002, 1000, 1004 })
    else
        Helpers.expect.equality(child.get_wins_in_tab(), { 1002, 1004, 1000, 1005 })
    end

    Helpers.expect.state(child, "enabled", true)

    -- Extract actual neo-tree window ID (can vary based on window creation order)
    local neotree_id = child.lua_get("_G.NoNeckPain.state.tabs[1].wins.integrations['neo-tree'].id")

    Helpers.expect.state(child, "tabs[1].wins.integrations", {
        aerial = {
            position = "right",
        },
        dap = {
            position = "none",
        },
        dashboard = {
            enabled = false,
            filetypes = { "dashboard", "alpha", "starter", "snacks" },
        },
        ["neo-tree"] = {
            id = neotree_id,
            position = "left",
        },
        neotest = {
            position = "right",
        },
        nvimtree = {
            position = "left",
        },
        oil = {
            position = "none",
        },
        outline = {
            position = "right",
        },
        snacks_picker = {
            position = "left",
        },
        undotree = {
            position = "left",
        },
    })

    if child.fn.has("nvim-0.10") == 0 then
        Helpers.expect.state(child, "tabs[1].wins.main", {
            curr = 1000,
            left = 1003,
            right = 1004,
        })
    else
        Helpers.expect.state(child, "tabs[1].wins.main", {
            curr = 1000,
            left = 1004,
            right = 1005,
        })
    end
end

-- =============================================================================
-- aerial
-- =============================================================================

T["aerial: keeps sides open"] = function()
    if child.fn.has("nvim-0.11") == 0 then
        MiniTest.skip("aerial doesn't support version below 11")

        return
    end

    child.restart({ "-u", "scripts/init_with_aerial.lua" })

    child.nnp()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })

    Helpers.expect.state(child, "enabled", true)
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })

    child.cmd("AerialToggle")
    child.wait()

    Helpers.expect.state(child, "tabs[1].wins.columns", 4)

    Helpers.expect.equality(child.lua_get("vim.api.nvim_win_get_width(1004)"), 14)
    Helpers.expect.state(child, "tabs[1].wins.integrations.aerial.id", 1004)

    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })

    child.cmd("AerialToggle")
    child.wait()

    Helpers.expect.state(child, "tabs[1].wins.integrations.aerial", {
        position = "right",
    })
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })
end

-- =============================================================================
-- snacks_picker
-- =============================================================================

T["snacks_picker: detects col-based explorer integration"] = function()
    child.set_size(10, 300)
    child.lua([[
        require('no-neck-pain').setup({
            width = 100,
            integrations = {
                snacks_picker = { position = "left" },
            }
        })
    ]])

    child.nnp()
    child.wait()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })

    -- Simulate snacks_picker col layout: a vertical split with two stacked windows
    -- This creates the col structure: ["col", {leaf(list), leaf(input)}]
    child.cmd("topleft 40vnew")
    child.wait()
    child.bo.filetype = "snacks_picker_list"
    child.wait()

    -- Split the picker window to create the col (list on top, input on bottom)
    child.cmd("split")
    child.wait()
    child.bo.filetype = "snacks_picker_input"
    child.wait()

    -- Navigate back to main window
    child.cmd("wincmd l")
    child.wait(50)

    -- The col-based integration should be detected
    Helpers.expect.state(child, "tabs[1].wins.integrations.snacks_picker.position", "left")
    Helpers.expect.state_type(child, "tabs[1].wins.integrations.snacks_picker.id", "number")

    -- Layout: col(snacks_picker) + left_pad + main + right_pad = 4 columns
    Helpers.expect.state(child, "tabs[1].wins.columns", 4)
end

-- =============================================================================
-- edge_cases
-- =============================================================================

T["edge_cases: multiple integrations on same side (left)"] = function()
    child.set_size(10, 300)
    child.lua([[
        require('no-neck-pain').setup({
            width = 100,
            integrations = {
                NvimTree = { position = "left" },
                undotree = { position = "left" }
            }
        })
    ]])

    child.nnp()
    child.wait()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })

    -- Create first integration on left
    child.cmd("topleft 30vnew")
    child.wait()
    child.bo.filetype = "NvimTree"
    child.wait()
    local nvimtree_win = child.get_current_win()

    -- Move to main window, then create second integration
    child.cmd("wincmd l")
    child.wait()

    child.cmd("topleft 25vnew")
    child.wait()
    child.bo.filetype = "undotree"
    child.wait()
    local undotree_win = child.get_current_win()

    -- Move back to main window
    child.cmd("wincmd l")
    child.wait(50)

    -- Verify first integration is tracked
    Helpers.expect.state(child, "tabs[1].wins.integrations.nvimtree.id", nvimtree_win)

    -- Verify second integration is tracked
    Helpers.expect.state(child, "tabs[1].wins.integrations.undotree.id", undotree_win)

    -- Verify both are on left side
    Helpers.expect.state(child, "tabs[1].wins.integrations.nvimtree.position", "left")
    Helpers.expect.state(child, "tabs[1].wins.integrations.undotree.position", "left")

    -- Main window should still exist
    local curr_id =
        child.lua_get("_G.NoNeckPain.state.tabs[_G.NoNeckPain.state.active_tab].wins.main.curr")
    Helpers.expect.no_equality(curr_id, vim.NIL)
end

T["edge_cases: integration appearing after NNP enabled"] = function()
    child.set_size(10, 200)
    child.lua([[
        require('no-neck-pain').setup({
            width = 80,
            integrations = {
                outline = { position = "right" }
            }
        })
    ]])

    child.nnp()
    child.wait()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })
    Helpers.expect.state(child, "tabs[1].wins.integrations.outline", {
        position = "right",
    })

    -- Create integration window after NNP is already enabled
    child.cmd("botright 30vnew")
    child.bo.filetype = "Outline"
    local outline_win = child.get_current_win()

    child.cmd("wincmd h")
    child.wait()

    -- Integration should be tracked after appearing
    Helpers.expect.state(child, "tabs[1].wins.integrations.outline.id", outline_win)

    -- Main window should remain intact
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })
end

T["edge_cases: integration window resize"] = function()
    child.set_size(10, 300)
    child.lua([[
        require('no-neck-pain').setup({
            width = 100,
            integrations = {
                NvimTree = { position = "left" }
            }
        })
    ]])

    child.nnp()
    child.wait()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })

    -- Create integration after enabling
    child.cmd("topleft 30vnew")
    child.bo.filetype = "NvimTree"
    local nvimtree_win = child.get_current_win()

    child.cmd("wincmd l")
    child.wait()

    -- Resize the integration window
    child.lua([[vim.api.nvim_win_set_width(]] .. nvimtree_win .. [[, 50)]])
    child.wait()

    -- Integration should still be valid
    local is_valid = child.lua_get("vim.api.nvim_win_is_valid(" .. nvimtree_win .. ")")
    Helpers.expect.equality(is_valid, true)

    -- Main window should still exist
    local curr_id =
        child.lua_get("_G.NoNeckPain.state.tabs[_G.NoNeckPain.state.active_tab].wins.main.curr")
    Helpers.expect.no_equality(curr_id, vim.NIL)
end

T["edge_cases: integration closing and reopening"] = function()
    child.set_size(10, 200)
    child.lua([[
        require('no-neck-pain').setup({
            width = 80,
            integrations = {
                outline = { position = "right" }
            }
        })
    ]])

    child.nnp()
    child.wait()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })

    -- Open integration
    child.cmd("botright 25vnew")
    child.bo.filetype = "Outline"
    local outline_win1 = child.get_current_win()

    child.cmd("wincmd h")
    child.wait()

    Helpers.expect.state(child, "tabs[1].wins.integrations.outline.id", outline_win1)

    -- Close integration
    child.lua([[vim.api.nvim_win_close(]] .. outline_win1 .. [[, true)]])
    child.wait()

    -- Integration should be reset to position only
    Helpers.expect.state(child, "tabs[1].wins.integrations.outline", {
        position = "right",
    })

    -- Reopen integration
    child.cmd("botright 30vnew")
    child.bo.filetype = "Outline"
    local outline_win2 = child.get_current_win()

    child.cmd("wincmd h")
    child.wait()

    -- New integration window should be tracked
    Helpers.expect.state(child, "tabs[1].wins.integrations.outline.id", outline_win2)
    Helpers.expect.no_equality(outline_win1, outline_win2)
end

T["edge_cases: unknown integration filetype (graceful handling)"] = function()
    child.set_size(10, 200)
    child.lua([[
        require('no-neck-pain').setup({
            width = 80
        })
    ]])

    child.nnp()
    child.wait()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })

    -- Create window with unknown filetype
    child.cmd("topleft 30vnew")
    child.bo.filetype = "unknownintegration123"
    local unknown_win = child.get_current_win()

    child.cmd("wincmd l")
    child.wait()

    -- Unknown window should not be registered as integration
    local integrations =
        child.lua_get("_G.NoNeckPain.state.tabs[_G.NoNeckPain.state.active_tab].wins.integrations")

    -- Check that unknownintegration123 is NOT in integrations
    local has_unknown = false
    for name, _ in pairs(integrations) do
        if name == "unknownintegration123" then
            has_unknown = true
            break
        end
    end
    Helpers.expect.equality(has_unknown, false)

    -- Unknown window should still be valid
    local is_valid = child.lua_get("vim.api.nvim_win_is_valid(" .. unknown_win .. ")")
    Helpers.expect.equality(is_valid, true)

    -- Main window should still exist
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })
end

T["edge_cases: dashboard + enableOnVimEnter safe timing"] = function()
    child.restart({ "-u", "scripts/minimal_init.lua" })

    child.set_size(10, 200)

    -- Set filetype to dashboard before enabling
    child.bo.filetype = "dashboard"

    child.lua([[
        require('no-neck-pain').setup({
            width = 80,
            integrations = {
                dashboard = {
                    enabled = true,
                    filetypes = { "dashboard", "alpha", "starter", "snacks" }
                }
            }
        })
    ]])

    child.wait()

    -- Open a real file (dashboard should not block NNP)
    child.cmd("edit foo.txt")
    child.wait()

    -- Manually enable NNP after leaving dashboard
    child.nnp()
    child.wait()

    -- Verify state is valid after leaving dashboard
    Helpers.expect.state(child, "enabled", true)
    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })

    -- Dashboard integration should be configured
    Helpers.expect.state(child, "tabs[1].wins.integrations.dashboard", {
        enabled = true,
        filetypes = { "dashboard", "alpha", "starter", "snacks" },
    })
end

T["edge_cases: integration width subtraction with multiple integrations"] = function()
    child.set_size(10, 400)
    child.lua([[
        require('no-neck-pain').setup({
            width = 100,
            minSideBufferWidth = 10,
            integrations = {
                NvimTree = { position = "left" },
                outline = { position = "right" },
                aerial = { position = "right" }
            }
        })
    ]])

    child.nnp()
    child.wait()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })

    -- Create left integration
    child.cmd("topleft 40vnew")
    child.bo.filetype = "NvimTree"
    local nvimtree_win = child.get_current_win()

    -- Create first right integration
    child.cmd("botright 30vnew")
    child.bo.filetype = "Outline"
    local outline_win = child.get_current_win()

    -- Create second right integration
    child.cmd("botright 35vnew")
    child.bo.filetype = "aerial"
    local aerial_win = child.get_current_win()

    -- Focus main window area
    child.cmd("wincmd h")
    child.cmd("wincmd h")
    child.cmd("wincmd h")
    child.wait()

    -- All integrations should be tracked
    Helpers.expect.state(child, "tabs[1].wins.integrations.nvimtree.id", nvimtree_win)
    Helpers.expect.state(child, "tabs[1].wins.integrations.outline.id", outline_win)
    Helpers.expect.state(child, "tabs[1].wins.integrations.aerial.id", aerial_win)

    -- Main window should be valid
    local curr_id =
        child.lua_get("_G.NoNeckPain.state.tabs[_G.NoNeckPain.state.active_tab].wins.main.curr")
    Helpers.expect.no_equality(curr_id, vim.NIL)
end

T["edge_cases: config override for integration position changes"] = function()
    child.set_size(10, 200)
    child.lua([[
        require('no-neck-pain').setup({
            width = 80,
            integrations = {
                outline = { position = "left" }
            }
        })
    ]])

    child.nnp()
    child.wait()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })

    -- Initial position should be left
    Helpers.expect.state(child, "tabs[1].wins.integrations.outline", {
        position = "left",
    })

    -- Disable NNP
    child.nnp()
    child.wait()

    Helpers.expect.state(child, "enabled", false)

    -- Reconfigure with different position
    child.lua([[
        require('no-neck-pain').setup({
            width = 80,
            integrations = {
                outline = { position = "right" }
            }
        })
    ]])

    child.nnp()
    child.wait()

    -- Verify we have 3 windows (left, main, right)
    local wins = child.get_wins_in_tab()
    Helpers.expect.equality(#wins, 3)

    -- Position should be updated to right
    Helpers.expect.state(child, "tabs[1].wins.integrations.outline", {
        position = "right",
    })

    -- Main window structure should be valid
    local main = child.lua_get("_G.NoNeckPain.state.tabs[_G.NoNeckPain.state.active_tab].wins.main")
    Helpers.expect.no_equality(main.curr, vim.NIL)
    Helpers.expect.no_equality(main.left, vim.NIL)
    Helpers.expect.no_equality(main.right, vim.NIL)
end

return T
