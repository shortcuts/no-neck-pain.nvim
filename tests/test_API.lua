local helpers = dofile("tests/helpers.lua")

local child = helpers.new_child_neovim()
local _, eq = helpers.expect, helpers.expect.equality
local new_set, _ = MiniTest.new_set, MiniTest.finally

local T = new_set({
    hooks = {
        -- This will be executed before every (even nested) case
        pre_case = function()
            -- Restart child process with custom 'init.lua' script
            child.restart({ "-u", "scripts/minimal_init.lua" })
            -- Load tested plugin
            child.lua([[M = require('no-neck-pain')]])
        end,
        -- This will be executed one after all tests from this set are finished
        post_once = child.stop,
    },
})

----------------- require

T["require()"] = new_set()

T["require()"]["sets global loaded variable"] = function()
    eq(child.lua_get("type(_G.noNeckPainLoaded)"), "boolean")
end

----------------- setup

T["setup()"] = new_set()

T["setup()"]["sets exposed methods and config"] = function()
    child.lua([[M = require('no-neck-pain').setup()]])

    eq(child.lua_get("type(_G.NoNeckPain)"), "table")

    -- public methods
    eq(child.lua_get("type(_G.NoNeckPain.start)"), "function")
    eq(child.lua_get("type(_G.NoNeckPain.setup)"), "function")

    -- config
    eq(child.lua_get("type(_G.NoNeckPain.config)"), "table")

    local expect_config = function(field, value)
        eq(child.lua_get("_G.NoNeckPain.config.options." .. field), value)
    end

    expect_config("width", 100)
    expect_config("debug", false)
end

T["setup()"]["overrides default values"] = function()
    child.lua([[M = require('no-neck-pain').setup({width=42,debug=true})]])

    local expect_config = function(field, value)
        eq(child.lua_get("_G.NoNeckPain.config.options." .. field), value)
    end

    expect_config("width", 42)
    expect_config("debug", true)
end

----------------- start

T["start()"] = new_set()

T["start()"]["sets state and internal methods"] = function()
    child.lua([[M = require('no-neck-pain').start()]])

    -- internal methods
    eq(child.lua_get("type(_G.NoNeckPain.internal.toggle)"), "function")
    eq(child.lua_get("type(_G.NoNeckPain.internal.enable)"), "function")
    eq(child.lua_get("type(_G.NoNeckPain.internal.disable)"), "function")

    -- state
    eq(child.lua_get("type(_G.NoNeckPain.state)"), "table")

    local expect_state = function(field, value)
        eq(child.lua_get("_G.NoNeckPain.state." .. field), value)
    end

    -- status
    expect_state("enabled", true)

    -- opts for side buffers
    expect_state("win.opts.bo.buftype", "nofile")
    expect_state("win.opts.bo.bufhidden", "hide")
    expect_state("win.opts.bo.modifiable", false)
    expect_state("win.opts.bo.buflisted", false)
    expect_state("win.opts.bo.swapfile", false)

    expect_state("win.opts.wo.cursorline", false)
    expect_state("win.opts.wo.cursorcolumn", false)
    expect_state("win.opts.wo.number", false)
    expect_state("win.opts.wo.relativenumber", false)
    expect_state("win.opts.wo.foldenable", false)
    expect_state("win.opts.wo.list", false)

    -- stored window ids
    expect_state("win.curr", 1000)
    expect_state("win.left", 1001)
    expect_state("win.right", 1002)
    expect_state("win.split", vim.NIL)
end

return T
