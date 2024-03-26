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

T["setup"] = MiniTest.new_set()

T["setup"]["does not create mappings by default"] = function()
    child.lua([[require('no-neck-pain').setup()]])

    Helpers.expect.config(child, "mappings.enabled", false)

    -- toggle plugin state
    child.api.nvim_input('<Leader>np')

    Helpers.expect.global(child, "_G.NoNeckPain.state", vim.NIL)

    -- decrease width
    Helpers.expect.global(child, "_G.NoNeckPain.config.width", 100)

    child.api.nvim_input('<Leader>n-')
    child.api.nvim_input('<Leader>n-')
    child.api.nvim_input('<Leader>n-')
    child.api.nvim_input('<Leader>n-')
    child.api.nvim_input('<Leader>n-')
    child.api.nvim_input('<Leader>n-')

    Helpers.expect.global(child, "_G.NoNeckPain.config.width", 100)

    -- increase width
    Helpers.expect.global(child, "_G.NoNeckPain.config.width", 100)

    child.api.nvim_input('<Leader>n+')
    child.api.nvim_input('<Leader>n+')
    child.api.nvim_input('<Leader>n+')
    child.api.nvim_input('<Leader>n+')
    child.api.nvim_input('<Leader>n+')
    child.api.nvim_input('<Leader>n+')

    Helpers.expect.global(child, "_G.NoNeckPain.config.width", 100)

    -- toggle scratchPad
    Helpers.expect.global(child, "_G.NoNeckPain.state", vim.NIL)

    child.api.nvim_input('<Leader>ns')

    Helpers.expect.global(child, "_G.NoNeckPain.state", vim.NIL)
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

    Helpers.expect.config(child, "mappings", {
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

    Helpers.expect.config(child, "mappings", {
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

    Helpers.expect.config(child, "mappings", {
        enabled = true,
        scratchPad = false,
        toggle = false,
        toggleLeftSide = false,
        toggleRightSide = false,
        widthUp = false,
        widthDown = false,
    })

    -- toggle plugin state
    child.api.nvim_input('<Leader>np')

    Helpers.expect.global(child, "_G.NoNeckPain.state", vim.NIL)

    -- decrease width
    Helpers.expect.global(child, "_G.NoNeckPain.config.width", 100)

    child.api.nvim_input('<Leader>n-')
    child.api.nvim_input('<Leader>n-')
    child.api.nvim_input('<Leader>n-')
    child.api.nvim_input('<Leader>n-')
    child.api.nvim_input('<Leader>n-')
    child.api.nvim_input('<Leader>n-')

    Helpers.expect.global(child, "_G.NoNeckPain.config.width", 100)

    -- increase width
    Helpers.expect.global(child, "_G.NoNeckPain.config.width", 100)

    child.api.nvim_input('<Leader>n+')
    child.api.nvim_input('<Leader>n+')
    child.api.nvim_input('<Leader>n+')
    child.api.nvim_input('<Leader>n+')
    child.api.nvim_input('<Leader>n+')
    child.api.nvim_input('<Leader>n+')

    Helpers.expect.global(child, "_G.NoNeckPain.config.width", 100)

    -- toggle scratchPad
    Helpers.expect.global(child, "_G.NoNeckPain.state", vim.NIL)

    child.api.nvim_input('<Leader>ns')

    Helpers.expect.global(child, "_G.NoNeckPain.state", vim.NIL)

    -- toggle left
    Helpers.expect.global(child, "_G.NoNeckPain.state", vim.NIL)

    child.api.nvim_input('<Leader>nql')

    Helpers.expect.global(child, "_G.NoNeckPain.state", vim.NIL)

    -- toggle right
    Helpers.expect.global(child, "_G.NoNeckPain.state", vim.NIL)

    child.api.nvim_input('<Leader>nqr')

    Helpers.expect.global(child, "_G.NoNeckPain.state", vim.NIL)
end

T["setup"]["increase the width with mapping"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50,mappings={enabled=true,widthUp="nn"}}) ]])
    Helpers.toggle(child)

    Helpers.expect.global(child, "_G.NoNeckPain.config.width", 50)
    Helpers.expect.equality(Helpers.winsInTab(child), { 1001, 1000, 1002 })

    child.api.nvim_input('nn')
    child.api.nvim_input('nn')
    child.api.nvim_input('nn')
    child.api.nvim_input('nn')

    Helpers.expect.global(child, "_G.NoNeckPain.config.width", 70)
end

T["setup"]["increase the width with custom mapping and value"] = function()
    child.lua(
        [[ require('no-neck-pain').setup({width=50,mappings={enabled=true,widthUp={mapping="nn", value=10}}}) ]]
    )
    Helpers.toggle(child)

    Helpers.expect.global(child, "_G.NoNeckPain.config.width", 50)
    Helpers.expect.equality(Helpers.winsInTab(child), { 1001, 1000, 1002 })

    child.api.nvim_input('nn')
    child.api.nvim_input('nn')
    child.api.nvim_input('nn')
    child.api.nvim_input('nn')

    Helpers.expect.global(child, "_G.NoNeckPain.config.width", 90)
end

T["setup"]["throws with wrong widthUp configuration"] = function()
    Helpers.expect.error(function()
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
    Helpers.expect.error(function()
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
    child.lua(
        [[ require('no-neck-pain').setup({width=50,mappings={enabled=true,widthDown="nn"}}) ]]
    )
    Helpers.toggle(child)

    Helpers.expect.global(child, "_G.NoNeckPain.config.width", 50)
    Helpers.expect.equality(Helpers.winsInTab(child), { 1001, 1000, 1002 })


    child.api.nvim_input('nn')
    child.api.nvim_input('nn')
    child.api.nvim_input('nn')
    child.api.nvim_input('nn')

    Helpers.expect.global(child, "_G.NoNeckPain.config.width", 30)
end

T["setup"]["decrease the width with custom mapping and value"] = function()
    child.lua(
        [[ require('no-neck-pain').setup({width=50,mappings={enabled=true,widthDown={mapping="nn",value=7}}}) ]]
    )
    Helpers.toggle(child)

    Helpers.expect.global(child, "_G.NoNeckPain.config.width", 50)
    Helpers.expect.equality(Helpers.winsInTab(child), { 1001, 1000, 1002 })

    child.api.nvim_input('nn')
    child.api.nvim_input('nn')
    child.api.nvim_input('nn')
    child.api.nvim_input('nn')

    Helpers.expect.global(child, "_G.NoNeckPain.config.width", 22)
end

T["setup"]["toggles scratchPad"] = function()
    child.lua(
        [[ require('no-neck-pain').setup({width=50,mappings={enabled=true,scratchPad="ns"}}) ]]
    )
    Helpers.toggle(child)

    Helpers.expect.global(child, "_G.NoNeckPain.config.buffers.scratchPad.enabled", false)
    Helpers.expect.global(child, "_G.NoNeckPain.state.tabs[1].scratchPadEnabled", false)

    child.api.nvim_input("ns")
    Helpers.wait(child)

    Helpers.expect.global(child, "_G.NoNeckPain.config.buffers.scratchPad.enabled", false)
    Helpers.expect.global(child, "_G.NoNeckPain.state.tabs[1].scratchPadEnabled", true)
end

T["setup"]["toggle sides and disable if none"] = function()
    child.lua(
        [[ require('no-neck-pain').setup({width=50,mappings={enabled=true,toggleLeftSide="nl",toggleRightSide="nr"}}) ]]
    )
    Helpers.toggle(child)

    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })

    child.api.nvim_input("nl")
    Helpers.wait(child)

    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = nil,
        right = 1002,
    })

    child.api.nvim_input("nl")
    Helpers.wait(child)

    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1003,
        right = 1002,
    })

    child.api.nvim_input("nr")
    Helpers.wait(child)

    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1003,
        right = nil,
    })

    child.api.nvim_input("nl")
    Helpers.wait(child)

    Helpers.expect.state(child, "enabled", false)
end

return T
