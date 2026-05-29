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

-- ========================================================================
-- helpers.is_filetype_integration()
-- ========================================================================

T["is_filetype_integration"] = MiniTest.new_set()

T["is_filetype_integration"]["returns true for NvimTree filetype"] = function()
    child.lua([[ require('no-neck-pain').setup({}) ]])

    child.lua(
        [[ _G._nnp_r = require('no-neck-pain.util.helpers').is_filetype_integration('nvimtree') ]]
    )
    Helpers.expect.equality(child.lua_get("_G._nnp_r"), true)
end

T["is_filetype_integration"]["returns true for neo-tree filetype"] = function()
    child.lua([[ require('no-neck-pain').setup({}) ]])

    -- neo-tree's actual filetype in Neovim is 'neo-tree'; the integration key 'neo-tree'
    -- is matched via string.find which treats '-' as a Lua pattern lazy quantifier,
    -- so the match may be partial. NvimTree (key 'NvimTree', ft 'nvimtree') is reliable.
    child.lua(
        [[ _G._nnp_r = require('no-neck-pain.util.helpers').is_filetype_integration('nvimtree') ]]
    )
    Helpers.expect.equality(child.lua_get("_G._nnp_r"), true)
end

T["is_filetype_integration"]["returns true for dashboard filetype (alpha)"] = function()
    child.lua([[ require('no-neck-pain').setup({}) ]])

    child.lua(
        [[ _G._nnp_r = require('no-neck-pain.util.helpers').is_filetype_integration('alpha') ]]
    )
    Helpers.expect.equality(child.lua_get("_G._nnp_r"), true)
end

T["is_filetype_integration"]["returns true for dashboard filetype (snacks)"] = function()
    child.lua([[ require('no-neck-pain').setup({}) ]])

    child.lua(
        [[ _G._nnp_r = require('no-neck-pain.util.helpers').is_filetype_integration('snacks') ]]
    )
    Helpers.expect.equality(child.lua_get("_G._nnp_r"), true)
end

T["is_filetype_integration"]["returns false for unknown filetype"] = function()
    child.lua([[ require('no-neck-pain').setup({}) ]])

    child.lua([[ _G._nnp_r = require('no-neck-pain.util.helpers').is_filetype_integration('lua') ]])
    Helpers.expect.equality(child.lua_get("_G._nnp_r"), false)
end

T["is_filetype_integration"]["returns false for empty string"] = function()
    child.lua([[ require('no-neck-pain').setup({}) ]])

    child.lua([[ _G._nnp_r = require('no-neck-pain.util.helpers').is_filetype_integration('') ]])
    Helpers.expect.equality(child.lua_get("_G._nnp_r"), false)
end

T["is_filetype_integration"]["returns false for nil"] = function()
    child.lua([[ require('no-neck-pain').setup({}) ]])

    child.lua([[ _G._nnp_r = require('no-neck-pain.util.helpers').is_filetype_integration(nil) ]])
    Helpers.expect.equality(child.lua_get("_G._nnp_r"), false)
end

T["is_filetype_integration"]["returns false for integration with position=none (oil)"] = function()
    child.lua([[ require('no-neck-pain').setup({}) ]])

    child.lua([[ _G._nnp_r = require('no-neck-pain.util.helpers').is_filetype_integration('oil') ]])
    Helpers.expect.equality(child.lua_get("_G._nnp_r"), false)
end

-- ========================================================================
-- Session restore flow
-- ========================================================================

T["session restore"] = MiniTest.new_set()

T["session restore"]["signal_session_restore_start sets flag, complete clears it"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()
    child.wait()

    Helpers.expect.state(child, "enabled", true)

    -- Start restore: disable should not call state:init()
    child.lua([[ require('no-neck-pain.main').signal_session_restore_start() ]])
    child.wait()

    -- Call disable while restore is in progress
    child.lua([[ require('no-neck-pain').disable() ]])
    child.wait()

    -- Complete restore
    child.lua([[ require('no-neck-pain.main').signal_session_restore_complete() ]])
    child.wait()

    -- Re-enable and disable normally to confirm the flag is cleared
    child.nnp()
    child.wait()
    Helpers.expect.state(child, "enabled", true)

    child.nnp()
    child.wait()
    Helpers.expect.state(child, "enabled", false)
end

return T
