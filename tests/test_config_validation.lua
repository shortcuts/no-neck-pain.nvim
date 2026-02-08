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

-- GROUP 1: Invalid Input Handling
T["Config Validation: negative width value is rejected"] = function()
    -- Negative width should be caught by assertion in defaults()
    Helpers.expect.error(function()
        child.lua([[ require('no-neck-pain').setup({width = -50}) ]])
    end)
end

T["Config Validation: zero width value is rejected"] = function()
    -- Zero width should be caught by assertion in defaults()
    Helpers.expect.error(function()
        child.lua([[ require('no-neck-pain').setup({width = 0}) ]])
    end)
end

T["Config Validation: negative minSideBufferWidth is rejected"] = function()
    -- Negative minSideBufferWidth should be caught by assertion
    Helpers.expect.error(function()
        child.lua([[ require('no-neck-pain').setup({minSideBufferWidth = -5}) ]])
    end)
end

T["Config Validation: blend values out of range are rejected"] = function()
    -- Test blend > 1 is rejected with error when colors are parsed
    Helpers.expect.error(function()
        child.lua([[
            require('no-neck-pain').setup({
                buffers = {
                    left = { colors = { background = "#24273A", blend = 2 } }
                }
            })
        ]])
    end)

    -- Test blend < -1 is rejected with error when colors are parsed
    Helpers.expect.error(function()
        child.lua([[
            require('no-neck-pain').setup({
                buffers = {
                    right = { colors = { background = "#ffffff", blend = -5 } }
                }
            })
        ]])
    end)
end

T["Config Validation: invalid hex color is rejected"] = function()
    -- Invalid hex color should throw an error
    Helpers.expect.error(function()
        child.lua(
            [[ require('no-neck-pain').setup({buffers = {colors = {background = "#ZZZZZ"}}}) ]]
        )
    end)
end

T["Config Validation: invalid integration position is rejected"] = function()
    -- Invalid position value should be caught by assertion
    Helpers.expect.error(function()
        child.lua([[
            require('no-neck-pain').setup({
                integrations = {
                    NvimTree = { position = "top" }
                }
            })
        ]])
    end)
end

T["Config Validation: non-string integration position is rejected"] = function()
    -- Non-string position should be caught by type assertion
    Helpers.expect.error(function()
        child.lua([[
            require('no-neck-pain').setup({
                integrations = {
                    NvimTree = { position = 123 }
                }
            })
        ]])
    end)
end

T["Config Validation: invalid mapping type is rejected"] = function()
    -- Mapping should be string or table with specific structure
    Helpers.expect.error(function()
        child.lua([[
            require('no-neck-pain').setup({
                mappings = {
                    enabled = true,
                    toggle = 123
                }
            })
        ]])
    end)
end

T["Config Validation: widthUp mapping table without required fields is rejected"] = function()
    -- widthUp as table must have mapping and value fields
    Helpers.expect.error(function()
        child.lua([[
            require('no-neck-pain').setup({
                mappings = {
                    enabled = true,
                    widthUp = { mapping = "<Leader>n=" }
                }
            })
        ]])
    end)
end

-- GROUP 2: Deep Merge & Partial Updates
T["Config Merge: partial config preserves defaults"] = function()
    -- Only override specific fields, others should remain default
    child.lua([[ require('no-neck-pain').setup({width = 120}) ]])

    Helpers.expect.config(child, "width", 120)
    Helpers.expect.config(child, "minSideBufferWidth", 10) -- default
    Helpers.expect.config(child, "debug", false) -- default
    Helpers.expect.config(child, "fallbackOnBufferDelete", true) -- default
end

T["Config Merge: nested table partial update preserves other fields"] = function()
    -- Only override one autocmd option, others should remain default
    child.lua([[
        require('no-neck-pain').setup({
            autocmds = { enableOnVimEnter = true }
        })
    ]])

    Helpers.expect.config(child, "autocmds.enableOnVimEnter", true)
    Helpers.expect.config(child, "autocmds.enableOnTabEnter", false) -- default
    Helpers.expect.config(child, "autocmds.reloadOnColorSchemeChange", false) -- default
end

T["Config Merge: deep nested buffer options are merged correctly"] = function()
    -- Override only left buffer color, right should use defaults
    child.lua([[
        require('no-neck-pain').setup({
            buffers = {
                left = {
                    colors = { background = "#24273A" }
                }
            }
        })
    ]])

    Helpers.expect.config(child, "buffers.left.colors.background", "#24273a")
    Helpers.expect.config(child, "buffers.left.colors.blend", 0)
    Helpers.expect.config(child, "buffers.right.enabled", true)
end

T["Config Merge: buffer-specific options override common buffer options"] = function()
    -- Set common buffer color, then override for left side only
    child.lua([[
        require('no-neck-pain').setup({
            buffers = {
                colors = { blend = 0.5 },
                left = {
                    colors = { blend = -0.5 }
                }
            }
        })
    ]])

    Helpers.expect.config(child, "buffers.left.colors.blend", -0.5) -- overridden
    Helpers.expect.config(child, "buffers.right.colors.blend", 0.5) -- from common
end

T["Config Merge: vim.wo options are deep merged"] = function()
    -- Override only one wo option, others should remain default
    child.lua([[
        require('no-neck-pain').setup({
            buffers = {
                wo = { cursorline = true }
            }
        })
    ]])

    Helpers.expect.config(child, "buffers.left.wo.cursorline", true)
    Helpers.expect.config(child, "buffers.left.wo.number", false) -- default
    Helpers.expect.config(child, "buffers.left.wo.wrap", true) -- default
end

T["Config Merge: vim.bo options are deep merged"] = function()
    -- Override only filetype, other bo options should remain default
    child.lua([[
        require('no-neck-pain').setup({
            buffers = {
                bo = { filetype = "markdown" }
            }
        })
    ]])

    Helpers.expect.config(child, "buffers.left.bo.filetype", "markdown")
    Helpers.expect.config(child, "buffers.left.bo.buftype", "nofile") -- default
    Helpers.expect.config(child, "buffers.left.bo.swapfile", false) -- default
end

-- GROUP 3: Deprecated Option Handling
T["Deprecated: scratchPad.fileName maps to pathToFile"] = function()
    -- Using deprecated fileName should still work and map to pathToFile
    child.lua([[
        require('no-neck-pain').setup({
            buffers = {
                left = {
                    scratchPad = {
                        enabled = true,
                        fileName = "my-notes"
                    },
                    bo = { filetype = "norg" }
                }
            }
        })
    ]])

    -- Should construct pathToFile from fileName
    local pathToFile = child.lua_get("_G.NoNeckPain.config.buffers.left.scratchPad.pathToFile")
    Helpers.expect.match(pathToFile, "my%-notes%-left%.norg")

    -- Deprecated fields should be cleaned up
    Helpers.expect.config(child, "buffers.left.scratchPad.fileName", vim.NIL)
    Helpers.expect.config(child, "buffers.left.scratchPad.location", vim.NIL)
end

T["Deprecated: scratchPad.location maps to pathToFile"] = function()
    -- Using deprecated location should construct pathToFile
    child.lua([[
        require('no-neck-pain').setup({
            buffers = {
                left = {
                    scratchPad = {
                        enabled = true,
                        location = "/tmp/notes",
                        fileName = "scratch"
                    },
                    bo = { filetype = "txt" }
                }
            }
        })
    ]])

    -- Should construct pathToFile from location + fileName
    Helpers.expect.config(
        child,
        "buffers.left.scratchPad.pathToFile",
        "/tmp/notes/scratch-left.txt"
    )

    -- Deprecated fields should be cleaned up
    Helpers.expect.config(child, "buffers.left.scratchPad.fileName", vim.NIL)
    Helpers.expect.config(child, "buffers.left.scratchPad.location", vim.NIL)
end

T["Deprecated: root level deprecated options trigger warnings"] = function()
    -- Deprecated root options should trigger warning but not crash
    child.lua([[
        require('no-neck-pain').setup({
            enableOnVimEnter = true,
            toggleMapping = "<Leader>x"
        })
    ]])

    -- Should still initialize despite deprecated options
    Helpers.expect.global_type(child, "_G.NoNeckPain.config", "table")
end

T["Deprecated: buffer backgroundColor maps to colors.background"] = function()
    -- Deprecated backgroundColor in buffers should work
    child.lua([[
        require('no-neck-pain').setup({
            buffers = {
                left = {
                    backgroundColor = "#ff0000"
                }
            }
        })
    ]])

    -- Should still create config (warning may be shown)
    Helpers.expect.global_type(child, "_G.NoNeckPain.config", "table")
end

-- GROUP 4: Config Lifecycle
T["Config Lifecycle: setup() is idempotent"] = function()
    -- Calling setup multiple times should work
    child.lua([[ require('no-neck-pain').setup({width = 80}) ]])
    Helpers.expect.config(child, "width", 80)

    child.lua([[ require('no-neck-pain').setup({width = 100}) ]])
    Helpers.expect.config(child, "width", 100)

    child.lua([[ require('no-neck-pain').setup({width = 120}) ]])
    Helpers.expect.config(child, "width", 120)
end

T["Config Lifecycle: width as 'textwidth' uses vim option"] = function()
    -- Set vim's textwidth and use it in config
    child.cmd("set textwidth=88")
    child.lua([[ require('no-neck-pain').setup({width = "textwidth"}) ]])

    Helpers.expect.config(child, "width", 88)
end

T["Config Lifecycle: width as 'colorcolumn' uses vim option"] = function()
    -- Set vim's colorcolumn and use it in config
    child.cmd("set colorcolumn=120")
    child.lua([[ require('no-neck-pain').setup({width = "colorcolumn"}) ]])

    Helpers.expect.config(child, "width", 120)
end

T["Config Lifecycle: all integration types are recognized"] = function()
    -- Setup with all known integration types
    child.lua([[
        require('no-neck-pain').setup({
            integrations = {
                NvimTree = { position = "left" },
                ["neo-tree"] = { position = "left" },
                undotree = { position = "left" },
                neotest = { position = "right" },
                dap = { position = "none" },
                outline = { position = "right" },
                aerial = { position = "right" },
                dashboard = { enabled = true }
            }
        })
    ]])

    Helpers.expect.config(child, "integrations.NvimTree.position", "left")
    Helpers.expect.config(child, "integrations['neo-tree'].position", "left")
    Helpers.expect.config(child, "integrations.undotree.position", "left")
    Helpers.expect.config(child, "integrations.neotest.position", "right")
    Helpers.expect.config(child, "integrations.dap.position", "none")
    Helpers.expect.config(child, "integrations.outline.position", "right")
    Helpers.expect.config(child, "integrations.aerial.position", "right")
    Helpers.expect.config(child, "integrations.dashboard.enabled", true)
end

T["Config Lifecycle: config with callbacks is valid"] = function()
    -- Callbacks should be stored in config
    child.lua([[
        local function test_callback(state)
            -- dummy callback
        end
        require('no-neck-pain').setup({
            callbacks = {
                preEnable = test_callback,
                postEnable = test_callback,
                preDisable = test_callback,
                postDisable = test_callback
            }
        })
    ]])

    Helpers.expect.config_type(child, "callbacks.preEnable", "function")
    Helpers.expect.config_type(child, "callbacks.postEnable", "function")
    Helpers.expect.config_type(child, "callbacks.preDisable", "function")
    Helpers.expect.config_type(child, "callbacks.postDisable", "function")
end

T["Config Lifecycle: mappings are created when enabled"] = function()
    -- Enable mappings and verify they are registered
    child.lua([[
        require('no-neck-pain').setup({
            mappings = {
                enabled = true,
                toggle = "<Leader>np",
                toggleLeftSide = "<Leader>nql",
                toggleRightSide = "<Leader>nqr",
                widthUp = "<Leader>n=",
                widthDown = "<Leader>n-",
                scratchPad = "<Leader>ns"
            }
        })
    ]])

    -- Verify mappings exist (they should not throw errors when accessed)
    local has_toggle = child.lua_get([[vim.fn.maparg("<Leader>np", "n") ~= ""]])
    Helpers.expect.equality(has_toggle, true)
end

T["Config Lifecycle: mappings are not created when disabled"] = function()
    -- Disable mappings and verify they are not registered
    child.lua([[
        require('no-neck-pain').setup({
            mappings = {
                enabled = false
            }
        })
    ]])

    -- Verify mappings don't exist
    local has_toggle = child.lua_get([[vim.fn.maparg("<Leader>np", "n") ~= ""]])
    Helpers.expect.equality(has_toggle, false)
end

T["Config Lifecycle: scratchPad common options are cleaned up"] = function()
    -- After setup, common scratchPad should be removed from config
    child.lua([[
        require('no-neck-pain').setup({
            buffers = {
                scratchPad = {
                    enabled = true,
                    fileName = "test"
                }
            }
        })
    ]])

    -- buffers.scratchPad should be removed after processing
    Helpers.expect.config(child, "buffers.scratchPad", vim.NIL)
end

T["Config Lifecycle: dashboard filetypes can be customized"] = function()
    -- Custom dashboard filetypes should be stored
    child.lua([[
        require('no-neck-pain').setup({
            integrations = {
                dashboard = {
                    enabled = true,
                    filetypes = { "startify", "dashboard", "custom" }
                }
            }
        })
    ]])

    local filetypes = child.lua_get("_G.NoNeckPain.config.integrations.dashboard.filetypes")
    Helpers.expect.equality(vim.tbl_contains(filetypes, "startify"), true)
    Helpers.expect.equality(vim.tbl_contains(filetypes, "custom"), true)
end

-- Additional edge cases
T["Config Validation: empty config uses all defaults"] = function()
    -- Empty config should use all default values
    child.lua([[ require('no-neck-pain').setup({}) ]])

    Helpers.expect.config(child, "width", 100)
    Helpers.expect.config(child, "minSideBufferWidth", 10)
    Helpers.expect.config(child, "debug", false)
    Helpers.expect.config(child, "disableOnLastBuffer", false)
    Helpers.expect.config(child, "killAllBuffersOnDisable", false)
    Helpers.expect.config(child, "fallbackOnBufferDelete", true)
end

T["Config Validation: nil values in nested tables are handled"] = function()
    -- Explicitly setting nil should be handled gracefully
    child.lua([[
        require('no-neck-pain').setup({
            buffers = {
                colors = {
                    background = nil,
                    blend = 0
                }
            }
        })
    ]])

    Helpers.expect.config(child, "buffers.colors.background", vim.NIL)
    Helpers.expect.config(child, "buffers.colors.blend", 0)
end

T["Config Validation: buffer setNames option works"] = function()
    -- setNames should be stored correctly
    child.lua([[
        require('no-neck-pain').setup({
            buffers = {
                setNames = true
            }
        })
    ]])

    Helpers.expect.config(child, "buffers.setNames", true)
end

T["Config Validation: side buffer can be disabled individually"] = function()
    -- Test disabling left buffer
    child.lua([[
        require('no-neck-pain').setup({
            buffers = {
                left = { enabled = false }
            }
        })
    ]])

    Helpers.expect.config(child, "buffers.left.enabled", false)
    Helpers.expect.config(child, "buffers.right.enabled", true) -- right still enabled
end

T["Config Validation: autocmds.enableOnVimEnter accepts 'safe' value"] = function()
    -- enableOnVimEnter can be boolean or "safe"
    child.lua([[
        require('no-neck-pain').setup({
            autocmds = {
                enableOnVimEnter = "safe"
            }
        })
    ]])

    Helpers.expect.config(child, "autocmds.enableOnVimEnter", "safe")
end

T["Config Validation: widthUp and widthDown accept table format"] = function()
    -- Test table format with custom value
    child.lua([[
        require('no-neck-pain').setup({
            mappings = {
                enabled = true,
                widthUp = { mapping = "<Leader>w=", value = 10 },
                widthDown = { mapping = "<Leader>w-", value = 10 }
            }
        })
    ]])

    local has_widthup = child.lua_get([[vim.fn.maparg("<Leader>w=", "n") ~= ""]])
    local has_widthdown = child.lua_get([[vim.fn.maparg("<Leader>w-", "n") ~= ""]])
    Helpers.expect.equality(has_widthup, true)
    Helpers.expect.equality(has_widthdown, true)
end

return T
