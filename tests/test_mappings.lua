local helpers = dofile("tests/helpers.lua")

local child = helpers.new_child_neovim()
local eq, eq_global, eq_config, eq_state =
    helpers.expect.equality,
    helpers.expect.global_equality,
    helpers.expect.config_equality,
    helpers.expect.state_equality

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

T["setup"] = MiniTest.new_set()

T["setup"]["does not create mappings by default"] = function()
    child.lua([[require('no-neck-pain').setup()]])

    eq_config(child, "mappings.enabled", false)

    -- toggle plugin state
    child.lua("vim.api.nvim_input('<Leader>np')")

    eq_global(child, "_G.NoNeckPain.state", vim.NIL)

    -- decrease width
    eq_global(child, "_G.NoNeckPain.config.width", 100)

    child.lua("vim.api.nvim_input('<Leader>n-')")
    child.lua("vim.api.nvim_input('<Leader>n-')")
    child.lua("vim.api.nvim_input('<Leader>n-')")
    child.lua("vim.api.nvim_input('<Leader>n-')")
    child.lua("vim.api.nvim_input('<Leader>n-')")
    child.lua("vim.api.nvim_input('<Leader>n-')")

    eq_global(child, "_G.NoNeckPain.config.width", 100)

    -- increase width
    eq_global(child, "_G.NoNeckPain.config.width", 100)

    child.lua("vim.api.nvim_input('<Leader>n+')")
    child.lua("vim.api.nvim_input('<Leader>n+')")
    child.lua("vim.api.nvim_input('<Leader>n+')")
    child.lua("vim.api.nvim_input('<Leader>n+')")
    child.lua("vim.api.nvim_input('<Leader>n+')")
    child.lua("vim.api.nvim_input('<Leader>n+')")

    eq_global(child, "_G.NoNeckPain.config.width", 100)

    -- toggle scratchPad
    eq_global(child, "_G.NoNeckPain.state", vim.NIL)

    child.lua("vim.api.nvim_input('<Leader>ns')")

    eq_global(child, "_G.NoNeckPain.state", vim.NIL)
end

T["setup"]["overrides default values"] = function()
    child.lua([[require('no-neck-pain').setup({
        mappings = {
            enabled = true,
            toggle = "<Leader>kz",
            widthUp = "<Leader>k-",
            widthDown = "<Leader>k=",
            toggleLeftSide = "<Leader>kl",
            toggleRightSide = "<Leader>kr",
            scratchPad = "<Leader>ks"
        }
    })]])

    eq_config(child, "mappings", {
        enabled = true,
        scratchPad = "<Leader>ks",
        toggle = "<Leader>kz",
        toggleLeftSide = "<Leader>kl",
        toggleRightSide = "<Leader>kr",
        widthDown = "<Leader>k=",
        widthUp = "<Leader>k-",
    })
end

T["setup"]["allow widthUp and widthDown to be configurable"] = function()
    child.lua([[require('no-neck-pain').setup({
        mappings = {
            enabled = true,
            widthUp = {mapping = "<Leader>k-", value = 12},
            widthDown = {mapping = "<Leader>k=", value = 99},
        }
    })]])

    eq_config(child, "mappings", {
        enabled = true,
        scratchPad = "<Leader>ns",
        toggle = "<Leader>np",
        toggleLeftSide = "<Leader>nql",
        toggleRightSide = "<Leader>nqr",
        widthDown = {
            mapping = "<Leader>k=",
            value = 99,
        },
        widthUp = {
            mapping = "<Leader>k-",
            value = 12,
        },
    })
end

T["setup"]["does not create mappings if false"] = function()
    child.lua([[require('no-neck-pain').setup({
        mappings = {
            enabled = true,
            toggle = false,
            toggleLeftSide = false,
            toggleRightSide = false,
            widthUp = false,
            widthDown = false,
            scratchPad = false
        }
    })]])

    eq_config(child, "mappings", {
        enabled = true,
        scratchPad = false,
        toggle = false,
        toggleLeftSide = false,
        toggleRightSide = false,
        widthUp = false,
        widthDown = false,
    })

    -- toggle plugin state
    child.lua("vim.api.nvim_input('<Leader>np')")

    eq_global(child, "_G.NoNeckPain.state", vim.NIL)

    -- decrease width
    eq_global(child, "_G.NoNeckPain.config.width", 100)

    child.lua("vim.api.nvim_input('<Leader>n-')")
    child.lua("vim.api.nvim_input('<Leader>n-')")
    child.lua("vim.api.nvim_input('<Leader>n-')")
    child.lua("vim.api.nvim_input('<Leader>n-')")
    child.lua("vim.api.nvim_input('<Leader>n-')")
    child.lua("vim.api.nvim_input('<Leader>n-')")

    eq_global(child, "_G.NoNeckPain.config.width", 100)

    -- increase width
    eq_global(child, "_G.NoNeckPain.config.width", 100)

    child.lua("vim.api.nvim_input('<Leader>n+')")
    child.lua("vim.api.nvim_input('<Leader>n+')")
    child.lua("vim.api.nvim_input('<Leader>n+')")
    child.lua("vim.api.nvim_input('<Leader>n+')")
    child.lua("vim.api.nvim_input('<Leader>n+')")
    child.lua("vim.api.nvim_input('<Leader>n+')")

    eq_global(child, "_G.NoNeckPain.config.width", 100)

    -- toggle scratchPad
    eq_global(child, "_G.NoNeckPain.state", vim.NIL)

    child.lua("vim.api.nvim_input('<Leader>ns')")

    eq_global(child, "_G.NoNeckPain.state", vim.NIL)

    -- toggle left
    eq_global(child, "_G.NoNeckPain.state", vim.NIL)

    child.lua("vim.api.nvim_input('<Leader>nql')")

    eq_global(child, "_G.NoNeckPain.state", vim.NIL)

    -- toggle right
    eq_global(child, "_G.NoNeckPain.state", vim.NIL)

    child.lua("vim.api.nvim_input('<Leader>nqr')")

    eq_global(child, "_G.NoNeckPain.state", vim.NIL)
end

T["setup"]["increase the width with mapping"] = function()
    child.lua([[
    require('no-neck-pain').setup({width=50,mappings={enabled=true,widthUp="nn"}})
    require('no-neck-pain').enable()
    ]])

    eq_global(child, "_G.NoNeckPain.config.width", 50)
    eq(helpers.winsInTab(child), { 1001, 1000, 1002 })

    child.lua("vim.api.nvim_input('nn')")
    child.lua("vim.api.nvim_input('nn')")
    child.lua("vim.api.nvim_input('nn')")
    child.lua("vim.api.nvim_input('nn')")

    eq_global(child, "_G.NoNeckPain.config.width", 70)
end

T["setup"]["increase the width with custom mapping and value"] = function()
    child.lua([[
    require('no-neck-pain').setup({width=50,mappings={enabled=true,widthUp={mapping="nn", value=10}}})
    require('no-neck-pain').enable()
    ]])

    eq_global(child, "_G.NoNeckPain.config.width", 50)
    eq(helpers.winsInTab(child), { 1001, 1000, 1002 })

    child.lua("vim.api.nvim_input('nn')")
    child.lua("vim.api.nvim_input('nn')")
    child.lua("vim.api.nvim_input('nn')")
    child.lua("vim.api.nvim_input('nn')")

    eq_global(child, "_G.NoNeckPain.config.width", 90)
end

T["setup"]["throws with wrong widthUp configuration"] = function()
    helpers.expect.error(function()
        child.lua([[ require('no-neck-pain').setup({
                    mappings = {
                        enabled = true,
                        widthUp = { foo = bar },
                    },
                })
            ]])
    end)
end

T["setup"]["throws with wrong widthDown configuration"] = function()
    helpers.expect.error(function()
        child.lua([[ require('no-neck-pain').setup({
                    mappings = {
                        enabled = true,
                        widthDown = { foo = bar },
                    },
                })
            ]])
    end)
end

T["setup"]["decrease the width with mapping"] = function()
    child.lua([[
    require('no-neck-pain').setup({width=50,mappings={enabled=true,widthDown="nn"}})
    require('no-neck-pain').enable()
    ]])

    eq_global(child, "_G.NoNeckPain.config.width", 50)
    eq(helpers.winsInTab(child), { 1001, 1000, 1002 })

    child.lua("vim.api.nvim_input('nn')")
    child.lua("vim.api.nvim_input('nn')")
    child.lua("vim.api.nvim_input('nn')")
    child.lua("vim.api.nvim_input('nn')")

    eq_global(child, "_G.NoNeckPain.config.width", 30)
end

T["setup"]["decrease the width with custom mapping and value"] = function()
    child.lua([[
    require('no-neck-pain').setup({width=50,mappings={enabled=true,widthDown={mapping="nn",value=7}}})
    require('no-neck-pain').enable()
    ]])

    eq_global(child, "_G.NoNeckPain.config.width", 50)
    eq(helpers.winsInTab(child), { 1001, 1000, 1002 })

    child.lua("vim.api.nvim_input('nn')")
    child.lua("vim.api.nvim_input('nn')")
    child.lua("vim.api.nvim_input('nn')")
    child.lua("vim.api.nvim_input('nn')")

    eq_global(child, "_G.NoNeckPain.config.width", 22)
end

T["setup"]["toggles scratchPad"] = function()
    child.lua([[
    require('no-neck-pain').setup({width=50,mappings={enabled=true,scratchPad="ns"}})
    require('no-neck-pain').enable()
    ]])

    eq_global(child, "_G.NoNeckPain.config.buffers.scratchPad.enabled", false)
    eq_global(child, "_G.NoNeckPain.state.tabs[1].scratchPadEnabled", false)

    child.lua("vim.api.nvim_input('ns')")

    eq_global(child, "_G.NoNeckPain.config.buffers.scratchPad.enabled", false)
    eq_global(child, "_G.NoNeckPain.state.tabs[1].scratchPadEnabled", true)
end

T["setup"]["toggle sides and disable if none"] = function()
    child.lua([[
        require('no-neck-pain').setup({width=50,mappings={enabled=true,toggleLeftSide="nl",toggleRightSide="nr"}})
        require('no-neck-pain').enable()
    ]])

    eq_state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })

    child.lua("vim.api.nvim_input('nl')")
    eq_state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = nil,
        right = 1002,
    })

    child.lua("vim.api.nvim_input('nl')")
    eq_state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1003,
        right = 1002,
    })

    child.lua("vim.api.nvim_input('nr')")
    eq_state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1003,
        right = nil,
    })

    child.lua("vim.api.nvim_input('nl')")
    eq_state(child, "enabled", false)
end

return T
