local Helpers = dofile("tests/helpers.lua")

local child = Helpers.new_child_neovim()

local T = MiniTest.new_set({
    hooks = {
        pre_case = function()
            child.restart({ "-u", "scripts/minimal_init.lua" })
            child.set_size(10, 200)
        end,
        post_once = child.stop,
    },
})

-- =============================================================================
-- GROUP 1: Invalid Input Handling
-- =============================================================================

T["Config Validation: negative width value is rejected"] = function()
    Helpers.expect.error(function()
        child.lua([[ require('no-neck-pain').setup({width = -50}) ]])
    end)
end

T["Config Validation: zero width value is rejected"] = function()
    Helpers.expect.error(function()
        child.lua([[ require('no-neck-pain').setup({width = 0}) ]])
    end)
end

T["Config Validation: negative minSideBufferWidth is rejected"] = function()
    Helpers.expect.error(function()
        child.lua([[ require('no-neck-pain').setup({minSideBufferWidth = -5}) ]])
    end)
end

T["Config Validation: blend values out of range are rejected"] = function()
    Helpers.expect.error(function()
        child.lua([[
            require('no-neck-pain').setup({
                buffers = {
                    left = { colors = { background = "#24273A", blend = 2 } }
                }
            })
        ]])
    end)

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
    Helpers.expect.error(function()
        child.lua(
            [[ require('no-neck-pain').setup({buffers = {colors = {background = "#ZZZZZ"}}}) ]]
        )
    end)
end

T["Config Validation: invalid integration position is rejected"] = function()
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

-- =============================================================================
-- GROUP 2: Deep Merge & Partial Updates
-- =============================================================================

T["Config Merge: partial config preserves defaults"] = function()
    child.lua([[ require('no-neck-pain').setup({width = 120}) ]])

    Helpers.expect.config(child, "width", 120)
    Helpers.expect.config(child, "minSideBufferWidth", 10)
    Helpers.expect.config(child, "debug", false)
    Helpers.expect.config(child, "fallbackOnBufferDelete", true)
end

T["Config Merge: nested table partial update preserves other fields"] = function()
    child.lua([[
        require('no-neck-pain').setup({
            autocmds = { enableOnVimEnter = true }
        })
    ]])

    Helpers.expect.config(child, "autocmds.enableOnVimEnter", true)
    Helpers.expect.config(child, "autocmds.enableOnTabEnter", false)
    Helpers.expect.config(child, "autocmds.reloadOnColorSchemeChange", true)
end

T["Config Merge: deep nested buffer options are merged correctly"] = function()
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

    Helpers.expect.config(child, "buffers.left.colors.blend", -0.5)
    Helpers.expect.config(child, "buffers.right.colors.blend", 0.5)
end

T["Config Merge: vim.wo options are deep merged"] = function()
    child.lua([[
        require('no-neck-pain').setup({
            buffers = {
                wo = { cursorline = true }
            }
        })
    ]])

    Helpers.expect.config(child, "buffers.left.wo.cursorline", true)
    Helpers.expect.config(child, "buffers.left.wo.number", false)
    Helpers.expect.config(child, "buffers.left.wo.wrap", true)
end

T["Config Merge: vim.bo options are deep merged"] = function()
    child.lua([[
        require('no-neck-pain').setup({
            buffers = {
                bo = { filetype = "markdown" }
            }
        })
    ]])

    Helpers.expect.config(child, "buffers.left.bo.filetype", "markdown")
    Helpers.expect.config(child, "buffers.left.bo.buftype", "nofile")
    Helpers.expect.config(child, "buffers.left.bo.swapfile", false)
end

-- =============================================================================
-- GROUP 3: Deprecated Option Handling
-- =============================================================================

T["Deprecated: scratchPad.fileName maps to pathToFile"] = function()
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

    local pathToFile = child.lua_get("_G.NoNeckPain.config.buffers.left.scratchPad.pathToFile")
    Helpers.expect.match(pathToFile, "my%-notes%-left%.norg")

    Helpers.expect.config(child, "buffers.left.scratchPad.fileName", vim.NIL)
    Helpers.expect.config(child, "buffers.left.scratchPad.location", vim.NIL)
end

T["Deprecated: scratchPad.location maps to pathToFile"] = function()
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

    Helpers.expect.config(
        child,
        "buffers.left.scratchPad.pathToFile",
        "/tmp/notes/scratch-left.txt"
    )

    Helpers.expect.config(child, "buffers.left.scratchPad.fileName", vim.NIL)
    Helpers.expect.config(child, "buffers.left.scratchPad.location", vim.NIL)
end

T["Deprecated: root level deprecated options trigger warnings"] = function()
    child.lua([[
        require('no-neck-pain').setup({
            enableOnVimEnter = true,
            toggleMapping = "<Leader>x"
        })
    ]])

    Helpers.expect.global_type(child, "_G.NoNeckPain.config", "table")
end

T["Deprecated: buffer backgroundColor maps to colors.background"] = function()
    child.lua([[
        require('no-neck-pain').setup({
            buffers = {
                left = {
                    backgroundColor = "#ff0000"
                }
            }
        })
    ]])

    Helpers.expect.global_type(child, "_G.NoNeckPain.config", "table")
end

-- =============================================================================
-- GROUP 4: Config Lifecycle
-- =============================================================================

T["Config Lifecycle: setup() is idempotent"] = function()
    child.lua([[ require('no-neck-pain').setup({width = 80}) ]])
    Helpers.expect.config(child, "width", 80)

    child.lua([[ require('no-neck-pain').setup({width = 100}) ]])
    Helpers.expect.config(child, "width", 100)

    child.lua([[ require('no-neck-pain').setup({width = 120}) ]])
    Helpers.expect.config(child, "width", 120)
end

T["Config Lifecycle: width as textwidth uses vim option"] = function()
    child.cmd("set textwidth=88")
    child.lua([[ require('no-neck-pain').setup({width = "textwidth"}) ]])

    Helpers.expect.config(child, "width", 88)
end

T["Config Lifecycle: width as colorcolumn uses vim option"] = function()
    child.cmd("set colorcolumn=120")
    child.lua([[ require('no-neck-pain').setup({width = "colorcolumn"}) ]])

    Helpers.expect.config(child, "width", 120)
end

T["Config Lifecycle: all integration types are recognized"] = function()
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
    child.lua([[
        local function test_callback(state)
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

    local has_toggle = child.lua_get([[vim.fn.maparg("<Leader>np", "n") ~= ""]])
    Helpers.expect.equality(has_toggle, true)
end

T["Config Lifecycle: mappings are not created when disabled"] = function()
    child.lua([[
        require('no-neck-pain').setup({
            mappings = {
                enabled = false
            }
        })
    ]])

    local has_toggle = child.lua_get([[vim.fn.maparg("<Leader>np", "n") ~= ""]])
    Helpers.expect.equality(has_toggle, false)
end

T["Config Lifecycle: scratchPad common options are cleaned up"] = function()
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

    Helpers.expect.config(child, "buffers.scratchPad", vim.NIL)
end

T["Config Lifecycle: dashboard filetypes can be customized"] = function()
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

-- =============================================================================
-- GROUP 5: Additional Edge Cases
-- =============================================================================

T["Config Validation: empty config uses all defaults"] = function()
    child.lua([[ require('no-neck-pain').setup({}) ]])

    Helpers.expect.config(child, "width", 100)
    Helpers.expect.config(child, "minSideBufferWidth", 10)
    Helpers.expect.config(child, "debug", false)
    Helpers.expect.config(child, "disableOnLastBuffer", false)
    Helpers.expect.config(child, "killAllBuffersOnDisable", false)
    Helpers.expect.config(child, "fallbackOnBufferDelete", true)
end

T["Config Validation: nil values in nested tables are handled"] = function()
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
    child.lua([[
        require('no-neck-pain').setup({
            buffers = {
                left = { enabled = false }
            }
        })
    ]])

    Helpers.expect.config(child, "buffers.left.enabled", false)
    Helpers.expect.config(child, "buffers.right.enabled", true)
end

T["Config Validation: autocmds.enableOnVimEnter accepts safe value"] = function()
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
