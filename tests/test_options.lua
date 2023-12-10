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

T["minSideBufferWidth"] = new_set()

T["minSideBufferWidth"]["closes side buffer respecting the given value"] = function()
    child.set_size(500, 500)
    child.lua([[
        require('no-neck-pain').setup({width=50})
        require('no-neck-pain').enable()
    ]])

    eq_state(child, "tabs[1].wins.main", { curr = 1000, left = 1001, right = 1002 })

    eq_buf_width(child, "tabs[1].wins.main.left", 15)
    eq_buf_width(child, "tabs[1].wins.main.right", 15)

    child.lua([[
        require('no-neck-pain').disable()
        require('no-neck-pain').setup({width=50, minSideBufferWidth=20})
        require('no-neck-pain').enable()
    ]])

    eq_state(child, "tabs[1].wins.main", { curr = 1000 })
end

T["killAllBuffersOnDisable"] = new_set()

T["killAllBuffersOnDisable"]["closes every windows when disabling the plugin"] = function()
    child.set_size(500, 500)
    child.lua([[
        require('no-neck-pain').setup({width=50,killAllBuffersOnDisable=true})
        require('no-neck-pain').enable()
    ]])

    eq_state(child, "tabs[1].wins.main", { curr = 1000, left = 1001, right = 1002 })

    eq(helpers.listBuffers(child), { 1, 2, 3 })
    child.cmd("badd 1")
    child.cmd("vsplit")
    child.cmd("split")
    eq(helpers.listBuffers(child), { 1, 2, 3, 4 })
    eq(helpers.winsInTab(child), { 1001, 1004, 1003, 1000, 1002 })

    child.lua([[
        require('no-neck-pain').disable()
    ]])

    eq(helpers.listBuffers(child), { 1, 2, 3, 4 })
    eq(helpers.winsInTab(child), { 1000 })
end

T["fallbackOnBufferDelete"] = new_set()

T["fallbackOnBufferDelete"]["invoking :bd keeps nnp enabled"] = function()
    child.set_size(500, 500)
    child.lua([[
        require('no-neck-pain').setup({width=50,fallbackOnBufferDelete=true})
        require('no-neck-pain').enable()
    ]])

    eq_state(child, "tabs[1].wins.main", { curr = 1000, left = 1001, right = 1002 })

    child.cmd("badd 1")
    child.cmd("bd")
    child.loop.sleep(500)

    eq_state(child, "tabs[1].wins.main", { curr = 1003, left = 1004, right = 1005 })
end

T["fallbackOnBufferDelete"]["still allows nvim to quit"] = function()
    child.set_size(500, 500)
    child.lua([[
        require('no-neck-pain').setup({width=50,fallbackOnBufferDelete=true})
        require('no-neck-pain').enable()
    ]])

    eq_state(child, "tabs[1].wins.main", { curr = 1000, left = 1001, right = 1002 })

    child.cmd("badd 1")
    child.cmd("q")

    helpers.expect.error(function()
        eq_state(child, "tabs[1].wins.main", { curr = 1003, left = 1004, right = 1005 })
    end)
end

return T
