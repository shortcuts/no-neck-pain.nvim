local Helpers = dofile("tests/helpers.lua")

local child = Helpers.new_child_neovim()

local T = MiniTest.new_set({
    hooks = {
        pre_case = function()
            child.restart({ "-u", "scripts/minimal_init.lua" })
        end,
        post_once = child.stop,
    },
})

T["log.notify()"] = MiniTest.new_set()

T["log.notify()"]["verbose=true prints regardless of debug=false"] = function()
    child.lua([[ require('no-neck-pain').setup({debug=false}) ]])

    child.lua([[
        _G.notify_calls = {}
        local original = vim.notify_once
        function vim.notify_once(msg, level, opts)
            table.insert(_G.notify_calls, msg)
        end
    ]])

    child.lua([[
        local log = require('no-neck-pain.util.log')
        log.notify("test", vim.log.levels.INFO, true, "Hello")
    ]])

    local count = child.lua_get("#_G.notify_calls")
    Helpers.expect.equality(count, 1)
end

T["log.notify()"]["verbose=false respects debug=true"] = function()
    child.lua([[ require('no-neck-pain').setup({debug=true}) ]])

    child.lua([[
        _G.notify_calls = {}
        function vim.notify_once(msg, level, opts)
            table.insert(_G.notify_calls, msg)
        end
    ]])

    child.lua([[
        local log = require('no-neck-pain.util.log')
        log.notify("test", vim.log.levels.DEBUG, false, "Hello")
    ]])

    local count = child.lua_get("#_G.notify_calls")
    Helpers.expect.equality(count, 1)
end

T["log.notify()"]["verbose=false skips when debug=false"] = function()
    child.lua([[ require('no-neck-pain').setup({debug=false}) ]])

    child.lua([[
        _G.notify_calls = {}
        function vim.notify_once(msg, level, opts)
            table.insert(_G.notify_calls, msg)
        end
    ]])

    child.lua([[
        local log = require('no-neck-pain.util.log')
        log.notify("test", vim.log.levels.DEBUG, false, "Hello")
    ]])

    local count = child.lua_get("#_G.notify_calls")
    Helpers.expect.equality(count, 0)
end

T["log.notify()"]["formats string with arguments"] = function()
    child.lua([[ require('no-neck-pain').setup({debug=false}) ]])

    child.lua([[
        _G.notify_calls = {}
        function vim.notify_once(msg, level, opts)
            table.insert(_G.notify_calls, msg)
        end
    ]])

    child.lua([[
        local log = require('no-neck-pain.util.log')
        log.notify("fmt", vim.log.levels.WARN, true, "Val %d %s", 42, "text")
    ]])

    local msg = child.lua_get("_G.notify_calls[1]")
    local contains_42 = child.lua_get("string.find(_G.notify_calls[1], '42') ~= nil")
    Helpers.expect.equality(contains_42, true)
end

T["log.notify()"]["includes correct log level"] = function()
    child.lua([[ require('no-neck-pain').setup({debug=false}) ]])

    child.lua([[
        _G.notify_calls = {}
        _G.notify_levels = {}
        function vim.notify_once(msg, level, opts)
            table.insert(_G.notify_calls, msg)
            table.insert(_G.notify_levels, level)
        end
    ]])

    child.lua([[
        local log = require('no-neck-pain.util.log')
        log.notify("test", vim.log.levels.ERROR, true, "Error")
    ]])

    local level = child.lua_get("_G.notify_levels[1]")
    local error_level = child.lua_get("vim.log.levels.ERROR")
    Helpers.expect.equality(level, error_level)
end

T["log.notify()"]["includes title in opts"] = function()
    child.lua([[ require('no-neck-pain').setup({debug=false}) ]])

    child.lua([[
        _G.notify_opts = {}
        function vim.notify_once(msg, level, opts)
            table.insert(_G.notify_opts, opts)
        end
    ]])

    child.lua([[
        local log = require('no-neck-pain.util.log')
        log.notify("test", vim.log.levels.INFO, true, "Message")
    ]])

    local title = child.lua_get("_G.notify_opts[1].title")
    Helpers.expect.equality(title, "no-neck-pain.nvim")
end

T["log.notify()"]["pads scope names for alignment"] = function()
    child.lua([[ require('no-neck-pain').setup({debug=false}) ]])

    child.lua([[
        _G.notify_calls = {}
        function vim.notify_once(msg, level, opts)
            table.insert(_G.notify_calls, msg)
        end
    ]])

    child.lua([[
        local log = require('no-neck-pain.util.log')
        log.notify("a", vim.log.levels.INFO, true, "Msg1")
        log.notify("very_long_scope", vim.log.levels.INFO, true, "Msg2")
    ]])

    local count = child.lua_get("#_G.notify_calls")
    Helpers.expect.equality(count, 2)
end

T["log.debug()"] = MiniTest.new_set()

T["log.debug()"]["prints with debug=true"] = function()
    child.lua([[ require('no-neck-pain').setup({debug=true}) ]])

    child.lua([[
        _G.notify_calls = {}
        function vim.notify_once(msg, level, opts)
            table.insert(_G.notify_calls, msg)
        end
    ]])

    child.lua([[
        local log = require('no-neck-pain.util.log')
        log.debug("scope", "Debug msg")
    ]])

    local count = child.lua_get("#_G.notify_calls")
    Helpers.expect.equality(count, 1)
end

T["log.debug()"]["skips with debug=false"] = function()
    child.lua([[ require('no-neck-pain').setup({debug=false}) ]])

    child.lua([[
        _G.notify_calls = {}
        function vim.notify_once(msg, level, opts)
            table.insert(_G.notify_calls, msg)
        end
    ]])

    child.lua([[
        local log = require('no-neck-pain.util.log')
        log.debug("scope", "Debug msg")
    ]])

    local count = child.lua_get("#_G.notify_calls")
    Helpers.expect.equality(count, 0)
end

T["log.debug()"]["uses DEBUG level"] = function()
    child.lua([[ require('no-neck-pain').setup({debug=true}) ]])

    child.lua([[
        _G.notify_levels = {}
        function vim.notify_once(msg, level, opts)
            table.insert(_G.notify_levels, level)
        end
    ]])

    child.lua([[
        local log = require('no-neck-pain.util.log')
        log.debug("scope", "Msg")
    ]])

    local level = child.lua_get("_G.notify_levels[1]")
    local debug_level = child.lua_get("vim.log.levels.DEBUG")
    Helpers.expect.equality(level, debug_level)
end

T["log.debug()"]["formats message correctly"] = function()
    child.lua([[ require('no-neck-pain').setup({debug=true}) ]])

    child.lua([[
        _G.notify_calls = {}
        function vim.notify_once(msg, level, opts)
            table.insert(_G.notify_calls, msg)
        end
    ]])

    child.lua([[
        local log = require('no-neck-pain.util.log')
        log.debug("fmt", "Num %d", 99)
    ]])

    local msg = child.lua_get("_G.notify_calls[1]")
    Helpers.expect.equality(msg:find("99") ~= nil, true)
end

T["log.warn_deprecation()"] = MiniTest.new_set()

T["log.warn_deprecation()"]["detects enableOnVimEnter deprecation"] = function()
    child.lua([[ require('no-neck-pain').setup({debug=false}) ]])

    child.lua([[
        _G.notify_calls = {}
        function vim.notify_once(msg, level, opts)
            table.insert(_G.notify_calls, msg)
        end
    ]])

    child.lua([[
        local log = require('no-neck-pain.util.log')
        local opts = {
            enableOnVimEnter = true,
            buffers = { left = {}, right = {} }
        }
        log.warn_deprecation(opts)
    ]])

    local count = child.lua_get("#_G.notify_calls")
    Helpers.expect.equality(count > 1, true)

    local has_deprecation = child.lua_get("string.find(_G.notify_calls[1], 'deprecated') ~= nil")
    Helpers.expect.equality(has_deprecation, true)
end

T["log.warn_deprecation()"]["detects toggleMapping deprecation"] = function()
    child.lua([[ require('no-neck-pain').setup({debug=false}) ]])

    child.lua([[
        _G.notify_calls = {}
        function vim.notify_once(msg, level, opts)
            table.insert(_G.notify_calls, msg)
        end
    ]])

    child.lua([[
        local log = require('no-neck-pain.util.log')
        local opts = {
            toggleMapping = "<Leader>np",
            buffers = { left = {}, right = {} }
        }
        log.warn_deprecation(opts)
    ]])

    local count = child.lua_get("#_G.notify_calls")
    Helpers.expect.equality(count > 1, true)
end

T["log.warn_deprecation()"]["detects backgroundColor deprecation"] = function()
    child.lua([[ require('no-neck-pain').setup({debug=false}) ]])

    child.lua([[
        _G.notify_calls = {}
        function vim.notify_once(msg, level, opts)
            table.insert(_G.notify_calls, msg)
        end
    ]])

    child.lua([[
        local log = require('no-neck-pain.util.log')
        local opts = {
            buffers = {
                backgroundColor = "#123456",
                left = {},
                right = {}
            }
        }
        log.warn_deprecation(opts)
    ]])

    local count = child.lua_get("#_G.notify_calls")
    Helpers.expect.equality(count > 1, true)
end

T["log.warn_deprecation()"]["detects textColor deprecation in left buffer"] = function()
    child.lua([[ require('no-neck-pain').setup({debug=false}) ]])

    child.lua([[
        _G.notify_calls = {}
        function vim.notify_once(msg, level, opts)
            table.insert(_G.notify_calls, msg)
        end
    ]])

    child.lua([[
        local log = require('no-neck-pain.util.log')
        local opts = {
            buffers = {
                left = { textColor = "#fff" },
                right = {}
            }
        }
        log.warn_deprecation(opts)
    ]])

    local count = child.lua_get("#_G.notify_calls")
    Helpers.expect.equality(count > 1, true)
end

T["log.warn_deprecation()"]["detects blend deprecation in right buffer"] = function()
    child.lua([[ require('no-neck-pain').setup({debug=false}) ]])

    child.lua([[
        _G.notify_calls = {}
        function vim.notify_once(msg, level, opts)
            table.insert(_G.notify_calls, msg)
        end
    ]])

    child.lua([[
        local log = require('no-neck-pain.util.log')
        local opts = {
            buffers = {
                left = {},
                right = { blend = 50 }
            }
        }
        log.warn_deprecation(opts)
    ]])

    local count = child.lua_get("#_G.notify_calls")
    Helpers.expect.equality(count > 1, true)
end

T["log.warn_deprecation()"]["shows help message when deprecation found"] = function()
    child.lua([[ require('no-neck-pain').setup({debug=false}) ]])

    child.lua([[
        _G.notify_calls = {}
        function vim.notify_once(msg, level, opts)
            table.insert(_G.notify_calls, msg)
        end
    ]])

    child.lua([[
        local log = require('no-neck-pain.util.log')
        local opts = {
            enableOnTabEnter = true,
            buffers = { left = {}, right = {} }
        }
        log.warn_deprecation(opts)
    ]])

    local count = child.lua_get("#_G.notify_calls")
    Helpers.expect.equality(count > 1, true)

    local has_help =
        child.lua_get("string.find(_G.notify_calls[#_G.notify_calls] or '', 'NoNeckPain') ~= nil")
    Helpers.expect.equality(has_help, true)
end

T["log.warn_deprecation()"]["does nothing for no deprecated options"] = function()
    child.lua([[ require('no-neck-pain').setup({debug=false}) ]])

    child.lua([[
        _G.notify_calls = {}
        function vim.notify_once(msg, level, opts)
            table.insert(_G.notify_calls, msg)
        end
    ]])

    child.lua([[
        local log = require('no-neck-pain.util.log')
        local opts = {
            width = 100,
            buffers = { left = {}, right = {} }
        }
        log.warn_deprecation(opts)
    ]])

    local count = child.lua_get("#_G.notify_calls")
    Helpers.expect.equality(count, 0)
end

T["log.warn_deprecation()"]["handles multiple deprecated options"] = function()
    child.lua([[ require('no-neck-pain').setup({debug=false}) ]])

    child.lua([[
        _G.notify_calls = {}
        function vim.notify_once(msg, level, opts)
            table.insert(_G.notify_calls, msg)
        end
    ]])

    child.lua([[
        local log = require('no-neck-pain.util.log')
        local opts = {
            enableOnVimEnter = true,
            widthDownMapping = "<Leader>-",
            buffers = { left = {}, right = {} }
        }
        log.warn_deprecation(opts)
    ]])

    local count = child.lua_get("#_G.notify_calls")
    Helpers.expect.equality(count > 2, true)
end

T["edge cases"] = MiniTest.new_set()

T["edge cases"]["handles empty message string"] = function()
    child.lua([[ require('no-neck-pain').setup({debug=false}) ]])

    child.lua([[
        _G.notify_calls = {}
        function vim.notify_once(msg, level, opts)
            table.insert(_G.notify_calls, msg)
        end
    ]])

    child.lua([[
        local log = require('no-neck-pain.util.log')
        log.notify("scope", vim.log.levels.INFO, true, "")
    ]])

    local count = child.lua_get("#_G.notify_calls")
    Helpers.expect.equality(count, 1)
end

T["edge cases"]["handles very long scope names"] = function()
    child.lua([[ require('no-neck-pain').setup({debug=false}) ]])

    child.lua([[
        _G.notify_calls = {}
        function vim.notify_once(msg, level, opts)
            table.insert(_G.notify_calls, msg)
        end
    ]])

    child.lua([[
        local log = require('no-neck-pain.util.log')
        local long_scope = string.rep("a", 100)
        log.notify(long_scope, vim.log.levels.INFO, true, "Message")
    ]])

    local count = child.lua_get("#_G.notify_calls")
    Helpers.expect.equality(count, 1)
end

T["edge cases"]["handles special characters in message"] = function()
    child.lua([[ require('no-neck-pain').setup({debug=false}) ]])

    child.lua([[
        _G.notify_calls = {}
        function vim.notify_once(msg, level, opts)
            table.insert(_G.notify_calls, msg)
        end
    ]])

    child.lua([[
        local log = require('no-neck-pain.util.log')
        log.notify("special", vim.log.levels.INFO, true, "Value: %s [%d]", "test", 42)
    ]])

    local count = child.lua_get("#_G.notify_calls")
    Helpers.expect.equality(count, 1)
end

T["edge cases"]["handles many format arguments"] = function()
    child.lua([[ require('no-neck-pain').setup({debug=false}) ]])

    child.lua([[
        _G.notify_calls = {}
        function vim.notify_once(msg, level, opts)
            table.insert(_G.notify_calls, msg)
        end
    ]])

    child.lua([[
        local log = require('no-neck-pain.util.log')
        log.notify("many", vim.log.levels.INFO, true, "%s %d %s %d", "a", 1, "b", 2)
    ]])

    local count = child.lua_get("#_G.notify_calls")
    Helpers.expect.equality(count, 1)
end

T["edge cases"]["consecutive debug calls persist state"] = function()
    child.lua([[ require('no-neck-pain').setup({debug=true}) ]])

    child.lua([[
        _G.notify_calls = {}
        function vim.notify_once(msg, level, opts)
            table.insert(_G.notify_calls, msg)
        end
    ]])

    child.lua([[
        local log = require('no-neck-pain.util.log')
        log.debug("loop", "Msg 1")
        log.debug("loop", "Msg 2")
        log.debug("loop", "Msg 3")
    ]])

    local count = child.lua_get("#_G.notify_calls")
    Helpers.expect.equality(count, 3)
end

T["edge cases"]["all vim log levels work"] = function()
    child.lua([[ require('no-neck-pain').setup({debug=false}) ]])

    child.lua([[
        _G.notify_calls = {}
        function vim.notify_once(msg, level, opts)
            table.insert(_G.notify_calls, msg)
        end
    ]])

    child.lua([[
        local log = require('no-neck-pain.util.log')
        log.notify("t", vim.log.levels.TRACE, true, "T")
        log.notify("d", vim.log.levels.DEBUG, true, "D")
        log.notify("i", vim.log.levels.INFO, true, "I")
        log.notify("w", vim.log.levels.WARN, true, "W")
        log.notify("e", vim.log.levels.ERROR, true, "E")
    ]])

    local count = child.lua_get("#_G.notify_calls")
    Helpers.expect.equality(count, 5)
end

T["edge cases"]["deprecated options with nil values are skipped"] = function()
    child.lua([[ require('no-neck-pain').setup({debug=false}) ]])

    child.lua([[
        _G.notify_calls = {}
        function vim.notify_once(msg, level, opts)
            table.insert(_G.notify_calls, msg)
        end
    ]])

    child.lua([[
        local log = require('no-neck-pain.util.log')
        local opts = {
            enableOnVimEnter = nil,
            toggleMapping = nil,
            buffers = { left = {}, right = {} }
        }
        log.warn_deprecation(opts)
    ]])

    local count = child.lua_get("#_G.notify_calls")
    Helpers.expect.equality(count, 0)
end

return T
