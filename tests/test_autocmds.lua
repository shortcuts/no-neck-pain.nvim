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
    Helpers.toggle(child)

    Helpers.expect.equality(Helpers.winsInTab(child), { 1000 })
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
    })
end

T["auto command"]["disabling clears VimEnter autocmd"] = function()
    child.restart({ "-u", "scripts/init_auto_open.lua" })
    Helpers.toggle(child)
    Helpers.wait(child, 299)

    -- errors because it doesn't exist
    Helpers.expect.error(function()
        child.api.nvim_get_autocmds({ group = "NoNeckPainVimEnterAutocmd" })
    end)
end

T["auto command"]["does not shift when opening/closing float window"] = function()
    child.set_size(5, 200)
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    Helpers.toggle(child)

    Helpers.expect.equality(Helpers.winsInTab(child), { 1001, 1000, 1002 })
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })

    Helpers.expect.buf_width(child, "tabs[1].wins.main.left", 15)
    Helpers.expect.buf_width(child, "tabs[1].wins.main.right", 15)

    child.api.nvim_open_win(
        0,
        true,
        { width = 100, height = 100, relative = "cursor", row = 0, col = 0 }
    )

    Helpers.expect.equality(Helpers.winsInTab(child), { 1001, 1000, 1002, 1003 })
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })

    Helpers.expect.buf_width(child, "tabs[1].wins.main.left", 15)
    Helpers.expect.buf_width(child, "tabs[1].wins.main.right", 15)

    -- Close float window keeps the buffer here with the same width
    child.fn.win_gotoid(1003)
    child.cmd("q")

    Helpers.expect.equality(Helpers.winsInTab(child), { 1001, 1000, 1002 })
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })

    Helpers.expect.buf_width(child, "tabs[1].wins.main.left", 15)
    Helpers.expect.buf_width(child, "tabs[1].wins.main.right", 15)
end

T["skipEnteringNoNeckPainBuffer"] = MiniTest.new_set()

T["skipEnteringNoNeckPainBuffer"]["goes to new valid buffer when entering side"] = function()
    child.set_size(5, 200)
    child.lua(
        [[ require('no-neck-pain').setup({width=50, autocmds = { skipEnteringNoNeckPainBuffer = true }}) ]]
    )
    Helpers.toggle(child)

    Helpers.expect.config(child, "autocmds.skipEnteringNoNeckPainBuffer", true)

    Helpers.expect.equality(Helpers.winsInTab(child), { 1001, 1000, 1002 })
    Helpers.expect.equality(child.api.nvim_get_current_win(), 1000)

    child.fn.win_gotoid(1001)
    Helpers.wait(child)
    Helpers.expect.equalityUntil(child, child.api.nvim_get_current_win(), 1000)

    child.fn.win_gotoid(1002)
    Helpers.wait(child)
    Helpers.expect.equality(child.api.nvim_get_current_win(), 1000)

    child.cmd("split")

    Helpers.expect.equality(Helpers.winsInTab(child), { 1001, 1003, 1000, 1002 })
    Helpers.expect.equality(child.api.nvim_get_current_win(), 1003)

    child.fn.win_gotoid(1000)
    Helpers.wait(child)
    Helpers.expect.equality(child.api.nvim_get_current_win(), 1000)

    child.fn.win_gotoid(1003)
    Helpers.wait(child)
    Helpers.expect.equality(child.api.nvim_get_current_win(), 1003)

    child.fn.win_gotoid(1001)
    Helpers.wait(child)
    Helpers.expect.equality(child.api.nvim_get_current_win(), 1003)

    child.fn.win_gotoid(1002)
    Helpers.wait(child)
    Helpers.expect.equality(child.api.nvim_get_current_win(), 1003)
end

T["skipEnteringNoNeckPainBuffer"]["does not register if scratchPad feature is enabled (global)"] = function()
    child.set_size(5, 200)
    child.lua(
        [[ require('no-neck-pain').setup({width=50, buffers = { scratchPad = { enabled = true } }, autocmds = { skipEnteringNoNeckPainBuffer = true }}) ]]
    )
    Helpers.toggle(child)

    Helpers.expect.config(child, "buffers.left.scratchPad.enabled", true)
    Helpers.expect.config(child, "buffers.right.scratchPad.enabled", true)
    Helpers.expect.config(child, "autocmds.skipEnteringNoNeckPainBuffer", true)

    Helpers.expect.equality(Helpers.winsInTab(child), { 1001, 1000, 1002 })
    Helpers.expect.equality(child.api.nvim_get_current_win(), 1000)

    child.fn.win_gotoid(1001)
    Helpers.wait(child)
    Helpers.expect.equality(child.api.nvim_get_current_win(), 1001)
end

T["skipEnteringNoNeckPainBuffer"]["does not register if scratchPad feature is enabled (left)"] = function()
    child.set_size(5, 200)
    child.lua(
        [[ require('no-neck-pain').setup({width=50, buffers = { left = { scratchPad = { enabled = true } } }, autocmds = { skipEnteringNoNeckPainBuffer = true }}) ]]
    )
    Helpers.toggle(child)

    Helpers.expect.config(child, "buffers.left.scratchPad.enabled", true)
    Helpers.expect.config(child, "buffers.right.scratchPad.enabled", false)
    Helpers.expect.config(child, "autocmds.skipEnteringNoNeckPainBuffer", true)

    Helpers.expect.equality(Helpers.winsInTab(child), { 1001, 1000, 1002 })
    Helpers.expect.equality(child.api.nvim_get_current_win(), 1000)

    child.fn.win_gotoid(1001)
    Helpers.wait(child)
    Helpers.expect.equality(child.api.nvim_get_current_win(), 1001)
end

T["skipEnteringNoNeckPainBuffer"]["does not register if scratchPad feature is enabled (right)"] = function()
    child.set_size(5, 200)
    child.lua(
        [[ require('no-neck-pain').setup({width=50, buffers = { right = { scratchPad = { enabled = true } } }, autocmds = { skipEnteringNoNeckPainBuffer = true }}) ]]
    )
    Helpers.toggle(child)

    Helpers.expect.config(child, "buffers.left.scratchPad.enabled", false)
    Helpers.expect.config(child, "buffers.right.scratchPad.enabled", true)
    Helpers.expect.config(child, "autocmds.skipEnteringNoNeckPainBuffer", true)

    Helpers.expect.equality(Helpers.winsInTab(child), { 1001, 1000, 1002 })
    Helpers.expect.equality(child.api.nvim_get_current_win(), 1000)

    child.fn.win_gotoid(1001)
    Helpers.wait(child)
    Helpers.expect.equality(child.api.nvim_get_current_win(), 1001)
end

T["skipEnteringNoNeckPainBuffer"]["do not come back to initial position if top or bottom window"] = function()
    child.set_size(5, 200)
    child.lua(
        [[ require('no-neck-pain').setup({width=50, autocmds = { skipEnteringNoNeckPainBuffer = true }}) ]]
    )
    Helpers.toggle(child)

    Helpers.expect.config(child, "autocmds.skipEnteringNoNeckPainBuffer", true)

    child.cmd("topleft new")

    Helpers.expect.equality(Helpers.winsInTab(child), { 1003, 1001, 1000, 1002 })
    Helpers.expect.equality(child.api.nvim_get_current_win(), 1003)

    child.fn.win_gotoid(1001)
    Helpers.wait(child)
    Helpers.expect.equality(child.api.nvim_get_current_win(), 1000)
end

T["killAllWindowsOnDisable"] = MiniTest.new_set()

T["killAllWindowsOnDisable"]["closes every windows when disabling the plugin"] = function()
    child.set_size(500, 500)
    child.lua(
        [[ require('no-neck-pain').setup({width=20,autocmds={killAllWindowsOnDisable=true}}) ]]
    )
    Helpers.toggle(child)

    Helpers.expect.state(child, "tabs[1].wins.main", { curr = 1000, left = 1001, right = 1002 })

    Helpers.expect.equality(Helpers.listBuffers(child), { 1, 2, 3 })
    child.cmd("badd 1")
    child.cmd("vsplit")
    child.cmd("split")
    Helpers.wait(child, 500)
    Helpers.expect.equality(Helpers.listBuffers(child), { 1, 2, 3, 4 })
    Helpers.expect.equality(Helpers.winsInTab(child), { 1001, 1004, 1003, 1000, 1002 })

    Helpers.toggle(child)

    Helpers.expect.equality(Helpers.listBuffers(child), { 1, 2, 3, 4 })
    Helpers.expect.equality(Helpers.winsInTab(child), { 1000 })
end

T["fallbackOnBufferDelete"] = MiniTest.new_set()

T["fallbackOnBufferDelete"]["invoking :bd keeps nnp enabled"] = function()
    child.set_size(500, 500)
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    Helpers.toggle(child)

    Helpers.expect.state(child, "tabs[1].wins.main", { curr = 1000, left = 1001, right = 1002 })

    child.cmd("badd 1")
    child.cmd("bd")
    Helpers.wait(child, 500)

    Helpers.expect.state(child, "tabs[1].wins.main", { curr = 1004, left = 1005, right = 1006 })
end

T["fallbackOnBufferDelete"]["still allows nvim to quit"] = function()
    child.set_size(500, 500)
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    Helpers.toggle(child)

    Helpers.expect.state(child, "tabs[1].wins.main", { curr = 1000, left = 1001, right = 1002 })

    child.cmd("badd 1")
    child.cmd("q")

    Helpers.expect.error(function()
        Helpers.expect.state(child, "tabs[1].wins.main", { curr = 1003, left = 1004, right = 1005 })
    end)
end

return T
