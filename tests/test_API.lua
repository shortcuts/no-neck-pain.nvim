local helpers = dofile("tests/helpers.lua")

local child = helpers.new_child_neovim()
local eq, eq_global, eq_config, eq_state =
    helpers.expect.equality,
    helpers.expect.global_equality,
    helpers.expect.config_equality,
    helpers.expect.state_equality
local eq_type_global, eq_type_config, eq_type_state =
    helpers.expect.global_type_equality,
    helpers.expect.config_type_equality,
    helpers.expect.state_type_equality

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

local SCOPES = { "left", "right" }
local EXTERNALS = { "NvimTree", "undotree" }

T["install"] = MiniTest.new_set()

T["install"]["sets global loaded variable and provide toggle command"] = function()
    eq_type_global(child, "_G.NoNeckPainLoaded", "boolean")
    eq_global(child, "_G.NoNeckPain", vim.NIL)

    child.cmd("NoNeckPain")
    eq_state(child, "enabled", true)

    child.cmd("NoNeckPain")
    eq_state(child, "enabled", false)
end

T["setup"] = MiniTest.new_set()

T["setup"]["sets exposed methods and default options value"] = function()
    child.lua([[require('no-neck-pain').setup()]])

    eq_type_global(child, "_G.NoNeckPain", "table")

    -- public methods
    eq_type_global(child, "_G.NoNeckPain.toggle", "function")
    eq_type_global(child, "_G.NoNeckPain.enable", "function")
    eq_type_global(child, "_G.NoNeckPain.setup", "function")

    -- config
    eq_type_global(child, "_G.NoNeckPain.config", "table")
    eq_type_config(child, "buffers", "table")

    eq_config(child, "width", 100)
    eq_config(child, "enableOnVimEnter", false)
    eq_config(child, "toggleMapping", "<Leader>np")
    eq_config(child, "debug", false)
    eq_config(child, "disableOnLastBuffer", false)
    eq_config(child, "killAllBuffersOnDisable", false)

    -- buffers
    eq_type_config(child, "buffers", "table")
    eq_type_config(child, "buffers.bo", "table")
    eq_type_config(child, "buffers.wo", "table")

    eq_config(child, "buffers.setNames", false)
    eq_config(child, "buffers.backgroundColor", vim.NIL)
    eq_config(child, "buffers.blend", 0)
    eq_config(child, "buffers.textColor", vim.NIL)

    eq_config(child, "buffers.bo.filetype", "no-neck-pain")
    eq_config(child, "buffers.bo.buftype", "nofile")
    eq_config(child, "buffers.bo.bufhidden", "hide")
    eq_config(child, "buffers.bo.buflisted", false)
    eq_config(child, "buffers.bo.swapfile", false)

    eq_config(child, "buffers.wo.cursorline", false)
    eq_config(child, "buffers.wo.cursorcolumn", false)
    eq_config(child, "buffers.wo.number", false)
    eq_config(child, "buffers.wo.relativenumber", false)
    eq_config(child, "buffers.wo.foldenable", false)
    eq_config(child, "buffers.wo.list", false)
    eq_config(child, "buffers.wo.wrap", true)
    eq_config(child, "buffers.wo.linebreak", true)

    for _, scope in pairs(SCOPES) do
        eq_type_config(child, "buffers." .. scope, "table")
        eq_type_config(child, "buffers." .. scope .. ".bo", "table")
        eq_type_config(child, "buffers." .. scope .. ".wo", "table")

        eq_config(child, "buffers." .. scope .. ".backgroundColor", vim.NIL)
        eq_config(child, "buffers." .. scope .. ".blend", 0)
        eq_config(child, "buffers." .. scope .. ".textColor", vim.NIL)

        eq_config(child, "buffers." .. scope .. ".bo.filetype", "no-neck-pain")
        eq_config(child, "buffers." .. scope .. ".bo.buftype", "nofile")
        eq_config(child, "buffers." .. scope .. ".bo.bufhidden", "hide")
        eq_config(child, "buffers." .. scope .. ".bo.buflisted", false)
        eq_config(child, "buffers." .. scope .. ".bo.swapfile", false)

        eq_config(child, "buffers." .. scope .. ".wo.cursorline", false)
        eq_config(child, "buffers." .. scope .. ".wo.cursorcolumn", false)
        eq_config(child, "buffers." .. scope .. ".wo.number", false)
        eq_config(child, "buffers." .. scope .. ".wo.relativenumber", false)
        eq_config(child, "buffers." .. scope .. ".wo.foldenable", false)
        eq_config(child, "buffers." .. scope .. ".wo.list", false)
        eq_config(child, "buffers." .. scope .. ".wo.wrap", true)
        eq_config(child, "buffers." .. scope .. ".wo.linebreak", true)
    end

    eq_config(child, "integrations.NvimTree.position", "left")
    eq_config(child, "integrations.NvimTree.reopen", true)
    eq_config(child, "integrations.undotree.position", "left")
end

T["setup"]["overrides default values"] = function()
    child.lua([[require('no-neck-pain').setup({
        width = 42,
        enableOnVimEnter = true,
        toggleMapping = "<Leader>kz",
        debug = true,
        disableOnLastBuffer = true,
        killAllBuffersOnDisable = true,
    })]])

    eq_config(child, "width", 42)
    eq_config(child, "enableOnVimEnter", true)
    eq_config(child, "toggleMapping", "<Leader>kz")
    eq_config(child, "debug", true)
    eq_config(child, "disableOnLastBuffer", true)
    eq_config(child, "killAllBuffersOnDisable", true)
end

T["setup"]["enables the plugin with mapping"] = function()
    child.lua([[
        require('no-neck-pain').setup({width=50,toggleMapping="nn"})
    ]])

    eq(child.lua_get("vim.api.nvim_list_wins()"), { 1000 })
    eq_type_global(child, "_G.NoNeckPainLoaded", "boolean")

    child.lua("vim.api.nvim_input('nn')")

    eq(child.lua_get("vim.api.nvim_list_wins()"), { 1001, 1000, 1002 })
    eq_state(child, "enabled", true)

    child.lua("vim.api.nvim_input('nn')")

    eq(child.lua_get("vim.api.nvim_list_wins()"), { 1000 })
    eq_state(child, "enabled", false)
end

T["setup"]["starts the plugin on VimEnter"] = function()
    child.restart({ "-u", "scripts/test_auto_open.lua" })

    eq(child.lua_get("vim.api.nvim_list_wins()"), { 1001, 1000, 1002 })
    eq_state(child, "enabled", true)

    child.stop()
end

T["enable"] = MiniTest.new_set()

T["enable"]["sets state"] = function()
    child.lua([[
        require('no-neck-pain').setup({width=50})
        require('no-neck-pain').enable()
    ]])

    -- state
    eq_type_global(child, "_G.NoNeckPain.state", "table")

    eq_state(child, "enabled", true)
    eq_type_state(child, "augroup", "number")

    eq_type_state(child, "win", "table")
    eq_type_state(child, "win.main", "table")
    eq_type_state(child, "win.external", "table")

    eq_state(child, "win.main.curr", 1000)
    eq_state(child, "win.main.left", 1001)
    eq_state(child, "win.main.right", 1002)
    eq_state(child, "win.splits", vim.NIL)

    eq_type_state(child, "win.external.trees", "table")

    for _, external in pairs(EXTERNALS) do
        eq_state(child, "win.external.trees." .. external .. ".id", vim.NIL)
        eq_state(child, "win.external.trees." .. external .. ".width", 0)
    end
end

T["disable"] = MiniTest.new_set()

T["disable"]["resets state"] = function()
    child.lua([[
        require('no-neck-pain').enable()
        require('no-neck-pain').disable()
    ]])

    -- state
    eq_type_global(child, "_G.NoNeckPain.state", "table")

    eq_state(child, "enabled", false)
    eq_type_state(child, "augroup", "nil")

    eq_type_state(child, "win", "table")
    eq_type_state(child, "win.main", "table")
    eq_type_state(child, "win.external", "table")

    eq_state(child, "win.main.curr", vim.NIL)
    eq_state(child, "win.main.left", vim.NIL)
    eq_state(child, "win.main.right", vim.NIL)
    eq_state(child, "win.splits", vim.NIL)

    eq_type_state(child, "win.external.trees", "table")

    for _, external in pairs(EXTERNALS) do
        eq_state(child, "win.external.trees." .. external .. ".id", vim.NIL)
        eq_state(child, "win.external.trees." .. external .. ".width", 0)
    end
end

T["toggle()"] = MiniTest.new_set()

T["toggle()"]["sets state and resets everything when toggled again"] = function()
    child.lua([[
        require('no-neck-pain').setup({width=50})
        require('no-neck-pain').enable()
    ]])

    -- config -- shouldn't reset
    eq_type_global(child, "_G.NoNeckPain.config", "table")

    -- state
    eq_type_global(child, "_G.NoNeckPain.state", "table")

    eq_state(child, "enabled", true)
    eq_type_state(child, "augroup", "number")

    eq_type_state(child, "win", "table")
    eq_type_state(child, "win.main", "table")
    eq_type_state(child, "win.external", "table")

    eq_state(child, "win.main.curr", 1000)
    eq_state(child, "win.main.left", 1001)
    eq_state(child, "win.main.right", 1002)
    eq_state(child, "win.splits", vim.NIL)

    eq_type_state(child, "win.external.trees", "table")

    for _, external in pairs(EXTERNALS) do
        eq_state(child, "win.external.trees." .. external .. ".id", vim.NIL)
        eq_state(child, "win.external.trees." .. external .. ".width", 0)
    end

    -- disable
    child.lua([[require('no-neck-pain').toggle()]])

    -- state
    eq_type_state(child, "win", "table")

    eq_state(child, "enabled", false)
    eq_state(child, "augroup", vim.NIL)

    eq_type_state(child, "win", "table")
    eq_type_state(child, "win.main", "table")
    eq_type_state(child, "win.external", "table")

    eq_state(child, "win.main.curr", vim.NIL)
    eq_state(child, "win.main.left", vim.NIL)
    eq_state(child, "win.main.right", vim.NIL)
    eq_state(child, "win.splits", vim.NIL)

    eq_type_state(child, "win.external.trees", "table")

    for _, external in pairs(EXTERNALS) do
        eq_state(child, "win.external.trees." .. external .. ".id", vim.NIL)
        eq_state(child, "win.external.trees." .. external .. ".width", 0)
    end
end

return T
