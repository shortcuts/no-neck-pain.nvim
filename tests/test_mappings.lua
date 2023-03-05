local helpers = dofile("tests/helpers.lua")

local child = helpers.new_child_neovim()
local eq, eq_global, eq_config =
    helpers.expect.equality, helpers.expect.global_equality, helpers.expect.config_equality

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
            scratchPad = "<Leader>ks"
        }
    })]])

    eq_config(child, "mappings.enabled", true)
    eq_config(child, "mappings.toggle", "<Leader>kz")
    eq_config(child, "mappings.widthUp", "<Leader>k-")
    eq_config(child, "mappings.widthDown", "<Leader>k=")
    eq_config(child, "mappings.scratchPad", "<Leader>ks")
end

T["setup"]["does not create mappings if false"] = function()
    child.lua([[require('no-neck-pain').setup({
        mappings = {
            enabled = true,
            toggle = false,
            widthUp = false,
            widthDown = false,
            scratchPad = false
        }
    })]])

    eq_config(child, "mappings.enabled", true)
    eq_config(child, "mappings.toggle", false)
    eq_config(child, "mappings.widthUp", false)
    eq_config(child, "mappings.widthDown", false)
    eq_config(child, "mappings.scratchPad", false)

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

T["setup"]["increase the width with mapping"] = function()
    child.lua([[
        require('no-neck-pain').setup({width=50,mappings={enabled=true,widthUp="nn"}})
        require('no-neck-pain').enable()
    ]])

    eq_global(child, "_G.NoNeckPain.config.width", 50)
    eq(
        child.lua_get("vim.api.nvim_tabpage_list_wins(_G.NoNeckPain.state.activeTab)"),
        { 1001, 1000, 1002 }
    )

    child.lua("vim.api.nvim_input('nn')")
    child.lua("vim.api.nvim_input('nn')")
    child.lua("vim.api.nvim_input('nn')")
    child.lua("vim.api.nvim_input('nn')")

    eq_global(child, "_G.NoNeckPain.config.width", 70)
end

T["setup"]["decrease the width with mapping"] = function()
    child.lua([[
        require('no-neck-pain').setup({width=50,mappings={enabled=true,widthDown="nn"}})
        require('no-neck-pain').enable()
    ]])

    eq_global(child, "_G.NoNeckPain.config.width", 50)
    eq(
        child.lua_get("vim.api.nvim_tabpage_list_wins(_G.NoNeckPain.state.activeTab)"),
        { 1001, 1000, 1002 }
    )

    child.lua("vim.api.nvim_input('nn')")
    child.lua("vim.api.nvim_input('nn')")
    child.lua("vim.api.nvim_input('nn')")
    child.lua("vim.api.nvim_input('nn')")

    eq_global(child, "_G.NoNeckPain.config.width", 30)
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

return T
