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

T["auto command"] = MiniTest.new_set()

T["auto command"]["does not create side buffers window's width < options.width"] = function()
    child.lua([[ require('no-neck-pain').setup({width=1000}) ]])
    child.nnp()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1000 })
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
    })
end

T["auto command"]["starts the plugin on VimEnter"] = function()
    child.restart({ "-u", "scripts/init_auto_open.lua" })
    child.wait()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })
    Helpers.expect.state(child, "enabled", true)
end

T["auto command"]["disabling clears VimEnter autocmd"] = function()
    child.restart({ "-u", "scripts/init_auto_open.lua" })
    child.nnp()
    child.wait()

    -- errors because it doesn't exist
    Helpers.expect.error(function()
        child.api.nvim_get_autocmds({ group = "NoNeckPainVimEnterAutocmd" })
    end)
end

T["auto command"]["does not shift when opening/closing float window"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })

    Helpers.expect.buf_width_in_range(child, "_G.NoNeckPain.state.tabs[1].wins.main.left", 13, 15)
    Helpers.expect.buf_width_in_range(child, "_G.NoNeckPain.state.tabs[1].wins.main.right", 13, 15)

    child.api.nvim_open_win(
        0,
        true,
        { width = 100, height = 100, relative = "cursor", row = 0, col = 0 }
    )

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002, 1003 })
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })

    Helpers.expect.buf_width_in_range(child, "_G.NoNeckPain.state.tabs[1].wins.main.left", 13, 15)
    Helpers.expect.buf_width_in_range(child, "_G.NoNeckPain.state.tabs[1].wins.main.right", 13, 15)

    -- Close float window keeps the buffer here with the same width
    child.fn.win_gotoid(1003)
    child.cmd("q")

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })

    Helpers.expect.buf_width_in_range(child, "_G.NoNeckPain.state.tabs[1].wins.main.left", 13, 15)
    Helpers.expect.buf_width_in_range(child, "_G.NoNeckPain.state.tabs[1].wins.main.right", 13, 15)
end

T["skipEnteringNoNeckPainBuffer"] = MiniTest.new_set()

T["skipEnteringNoNeckPainBuffer"]["goes to new valid buffer when entering side"] = function()
    child.lua(
        [[ require('no-neck-pain').setup({width=50, autocmds = { skipEnteringNoNeckPainBuffer = true }}) ]]
    )
    child.nnp()

    Helpers.expect.config(child, "autocmds.skipEnteringNoNeckPainBuffer", true)

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })
    Helpers.expect.equality(child.api.nvim_get_current_win(), 1000)

    child.fn.win_gotoid(1001)
    child.wait()
    Helpers.expect.equality(child.api.nvim_get_current_win(), 1000)

    child.fn.win_gotoid(1002)
    child.wait()
    Helpers.expect.equality(child.api.nvim_get_current_win(), 1000)

    child.cmd("split")

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1003, 1000, 1002 })
    Helpers.expect.equality(child.api.nvim_get_current_win(), 1003)

    child.fn.win_gotoid(1000)
    child.wait()
    Helpers.expect.equality(child.api.nvim_get_current_win(), 1000)

    child.fn.win_gotoid(1003)
    child.wait()
    Helpers.expect.equality(child.api.nvim_get_current_win(), 1003)

    child.fn.win_gotoid(1001)
    child.wait()
    Helpers.expect.equality(child.api.nvim_get_current_win(), 1000)

    child.fn.win_gotoid(1002)
    child.wait()
    Helpers.expect.equality(child.api.nvim_get_current_win(), 1003)
end

T["skipEnteringNoNeckPainBuffer"]["handles ltr and rtl on many buffers"] = function()
    child.lua(
        [[ require('no-neck-pain').setup({width=50, autocmds = { skipEnteringNoNeckPainBuffer = true }}) ]]
    )
    child.nnp()

    Helpers.expect.config(child, "autocmds.skipEnteringNoNeckPainBuffer", true)

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })
    Helpers.expect.equality(child.api.nvim_get_current_win(), 1000)

    child.cmd("top new")
    child.cmd("top new")
    child.wait()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1004, 1003, 1001, 1000, 1002 })
    Helpers.expect.equality(child.api.nvim_get_current_win(), 1004)

    child.fn.win_gotoid(1003)
    child.wait()
    Helpers.expect.equality(child.api.nvim_get_current_win(), 1003)

    child.fn.win_gotoid(1001)
    child.wait()
    Helpers.expect.equality(child.api.nvim_get_current_win(), 1000)

    child.fn.win_gotoid(1000)
    child.wait()
    Helpers.expect.equality(child.api.nvim_get_current_win(), 1000)

    child.fn.win_gotoid(1001)
    child.wait()
    Helpers.expect.equality(child.api.nvim_get_current_win(), 1003)
end

T["skipEnteringNoNeckPainBuffer"]["does not register if scratchPad feature is enabled (global)"] = function()
    child.lua(
        [[ require('no-neck-pain').setup({width=50, buffers = { scratchPad = { enabled = true } }, autocmds = { skipEnteringNoNeckPainBuffer = true }}) ]]
    )
    child.nnp()

    Helpers.expect.config(child, "buffers.left.scratchPad.enabled", true)
    Helpers.expect.config(child, "buffers.right.scratchPad.enabled", true)
    Helpers.expect.config(child, "autocmds.skipEnteringNoNeckPainBuffer", true)

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })
    Helpers.expect.equality(child.api.nvim_get_current_win(), 1000)

    child.fn.win_gotoid(1001)
    child.wait()
    Helpers.expect.equality(child.api.nvim_get_current_win(), 1001)
end

-- Race Condition & Rapid Event Tests
T["RaceConditions"] = MiniTest.new_set()

T["RaceConditions"]["rapid WinEnter events maintain state consistency"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })
    Helpers.expect.state(child, "enabled", true)

    child.cmd("doautocmd WinEnter")
    child.cmd("doautocmd WinEnter")
    child.cmd("doautocmd WinEnter")

    child.wait(200)

    Helpers.expect.state(child, "enabled", true)
    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })
end

T["RaceConditions"]["QuitPre and BufDelete sequence maintains state"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })

    child.cmd("split")
    child.wait()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1003, 1000, 1002 })

    child.fn.win_gotoid(1003)
    child.cmd("q")
    child.wait(200)

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })
    Helpers.expect.state(child, "enabled", true)
end

T["RaceConditions"]["VimResized during side buffer creation"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()

    child.cmd("doautocmd VimResized")
    child.wait()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })
    Helpers.expect.state(child, "enabled", true)
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })
end

T["RaceConditions"]["TabEnter while side windows exist"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })

    child.cmd("tabnew")
    child.wait(200)

    child.cmd("tabprev")
    child.wait()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })
    Helpers.expect.state(child, "enabled", true)
end

T["RaceConditions"]["rapid enable disable enable cycle"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])

    child.nnp()
    child.wait(100)
    child.nnp()
    child.wait(100)
    child.nnp()

    child.wait(200)

    Helpers.expect.state(child, "enabled", true)
    local wins = child.get_wins_in_tab()
    Helpers.expect.equality(#wins, 3)
end

T["RaceConditions"]["multiple rapid window navigations"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()

    child.cmd("split")
    child.cmd("split")
    child.wait()

    local initial_wins = child.get_wins_in_tab()

    child.cmd("wincmd w")
    child.cmd("wincmd w")
    child.cmd("wincmd w")
    child.wait()

    Helpers.expect.state(child, "enabled", true)
    local final_wins = child.get_wins_in_tab()
    Helpers.expect.equality(#initial_wins, #final_wins)
end

T["RaceConditions"]["disabling during autocmd execution cleans up"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })

    child.cmd("doautocmd WinEnter")
    child.nnp()

    child.wait(200)

    Helpers.expect.state(child, "enabled", false)
end

T["RaceConditions"]["multiple tabs with overlapping autocmds"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()

    child.cmd("tabnew")
    child.wait()
    child.nnp()
    child.cmd("tabnew")
    child.wait()
    child.nnp()

    child.cmd("doautocmd WinEnter")
    child.cmd("tabprev")
    child.cmd("doautocmd WinEnter")
    child.wait()

    Helpers.expect.state(child, "enabled", true)
end

T["RaceConditions"]["autocmd cleanup when plugin disabled mid-operation"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })

    child.cmd("split")
    child.nnp()

    child.wait(200)

    Helpers.expect.state(child, "enabled", false)
end

T["RaceConditions"]["rapid TabEnter events are debounced"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()

    child.cmd("tabnew")
    child.cmd("tabnew")
    child.wait()

    child.cmd("tabprev")
    child.cmd("tabnext")
    child.cmd("tabprev")
    child.wait(200)

    Helpers.expect.state(child, "enabled", true)
end

T["RaceConditions"]["debounce preserves important state changes"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()

    local initial_tab = child.lua_get("_G.NoNeckPain.state.active_tab")

    child.cmd("tabnew")
    child.wait(200)

    local new_tab = child.lua_get("_G.NoNeckPain.state.active_tab")
    Helpers.expect.no_equality(initial_tab, new_tab)
end

T["RaceConditions"]["WinClosed during layout adjustment"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()

    child.cmd("split")
    child.cmd("split")
    child.wait()

    local wins_before = child.get_wins_in_tab()

    child.cmd("close")
    child.cmd("doautocmd WinClosed")
    child.wait()

    Helpers.expect.state(child, "enabled", true)
    local wins_after = child.get_wins_in_tab()
    Helpers.expect.equality(#wins_after, #wins_before - 1)
end

T["RaceConditions"]["rapid resize events"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()

    child.cmd("doautocmd VimResized")
    child.cmd("doautocmd VimResized")
    child.cmd("doautocmd VimResized")
    child.wait()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })
    Helpers.expect.state(child, "enabled", true)
end

T["RaceConditions"]["BufDelete on main window with fallback"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50, fallbackOnBufferDelete=true}) ]])
    child.nnp()

    Helpers.expect.config(child, "fallbackOnBufferDelete", true)
    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })

    child.cmd("e foo")
    child.wait()
    child.cmd("e bar")
    child.wait()
    child.cmd("bd")
    child.wait(200)

    Helpers.expect.state(child, "enabled", true)
end

T["RaceConditions"]["concurrent split and window close"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()

    child.cmd("split")
    child.wait()

    local split_win = child.api.nvim_get_current_win()

    child.cmd("split")
    child.fn.win_gotoid(split_win)
    child.cmd("close")
    child.wait()

    Helpers.expect.state(child, "enabled", true)
    local wins = child.get_wins_in_tab()
    Helpers.expect.equality(#wins >= 3, true)
end

T["RaceConditions"]["window focus changes during disable"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()

    child.cmd("split")
    child.wait()

    local new_win = child.api.nvim_get_current_win()
    child.nnp()
    child.fn.win_gotoid(new_win)

    child.wait(200)

    Helpers.expect.state(child, "enabled", false)
end

return T
