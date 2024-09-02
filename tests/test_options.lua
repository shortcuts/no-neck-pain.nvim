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

T["minSideBufferWidth"] = MiniTest.new_set()

T["minSideBufferWidth"]["closes side buffer respecting the given value"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()

    Helpers.expect.state(child, "tabs[1].wins.main", { curr = 1000, left = 1001, right = 1002 })

    Helpers.expect.buf_width(child, "tabs[1].wins.main.left", 15)
    Helpers.expect.buf_width(child, "tabs[1].wins.main.right", 15)

    child.lua([[
        require('no-neck-pain').disable()
        require('no-neck-pain').setup({width=50, minSideBufferWidth=20})
    ]])
    child.nnp()

    Helpers.expect.state(child, "tabs[1].wins.main", { curr = 1000 })
end

T["killAllBuffersOnDisable"] = MiniTest.new_set()

T["killAllBuffersOnDisable"]["closes every windows when disabling the plugin"] = function()
    child.lua([[ require('no-neck-pain').setup({width=20,killAllBuffersOnDisable=true}) ]])
    child.nnp()

    Helpers.expect.state(child, "tabs[1].wins.main", { curr = 1000, left = 1001, right = 1002 })

    Helpers.expect.equality(child.list_buffers(), { 1, 2, 3 })
    child.cmd("badd 1")
    child.cmd("vsplit")
    child.cmd("split")
    Helpers.expect.equality(child.list_buffers(), { 1, 2, 3, 4 })
    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1004, 1003, 1000, 1002 })

    child.nnp()

    Helpers.expect.equality(child.list_buffers(), { 1, 2, 3, 4 })
    Helpers.expect.equality(child.get_wins_in_tab(), { 1000 })
end

T["fallbackOnBufferDelete"] = MiniTest.new_set()

T["fallbackOnBufferDelete"]["invoking :bd keeps nnp enabled"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50,fallbackOnBufferDelete=true}) ]])

    Helpers.expect.config(child, "fallbackOnBufferDelete", true)
    child.nnp()

    Helpers.expect.state(child, "tabs[1].wins.main", { curr = 1000, left = 1001, right = 1002 })

    child.cmd("badd 1")
    child.cmd("bd")
    child.loop.sleep(500)

    if child.fn.has("nvim-0.10") == 0 then
        Helpers.expect.state(child, "tabs[1].wins.main", { curr = 1003, left = 1004, right = 1005 })
    else
        Helpers.expect.state(child, "tabs[1].wins.main", { curr = 1004, left = 1005, right = 1006 })
    end
end

T["fallbackOnBufferDelete"]["still allows nvim to quit"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50,fallbackOnBufferDelete=true}) ]])
    child.nnp()

    Helpers.expect.state(child, "tabs[1].wins.main", { curr = 1000, left = 1001, right = 1002 })

    child.cmd("badd 1")
    child.cmd("q")

    Helpers.expect.error(function()
        Helpers.expect.state(child, "tabs[1].wins.main", { curr = 1003, left = 1004, right = 1005 })
    end)
end

return T
