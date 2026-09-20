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

    child.lua(
        [[ _G._nnp_r = require('no-neck-pain.util.helpers').is_filetype_integration('neo-tree') ]]
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

T["is_filetype_integration"]["match_integration reports position=none integrations"] = function()
    child.lua([[ require('no-neck-pain').setup({}) ]])

    child.lua(
        [[ _G._nnp_n, _G._nnp_o = require('no-neck-pain.util.helpers').match_integration('oil') ]]
    )
    Helpers.expect.equality(child.lua_get("_G._nnp_n"), "oil")
    Helpers.expect.equality(child.lua_get("_G._nnp_o.position"), "none")
end

-- ========================================================================
-- Session restore flow
-- ========================================================================

T["session restore"] = MiniTest.new_set()

T["session restore"]["sourcing a non-session .vim file does not break disable()"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])

    -- the plugin must not hijack `:source`
    child.lua([[
        _G._nnp_srccmd = 0
        for _, a in ipairs(vim.api.nvim_get_autocmds({ event = "SourceCmd" })) do
            if a.group_name == "NoNeckPainAutocmd" then
                _G._nnp_srccmd = _G._nnp_srccmd + 1
            end
        end
    ]])
    Helpers.expect.equality(child.lua_get("_G._nnp_srccmd"), 0)

    -- a plain .vim file, at a path containing a space, still sources normally
    child.lua([[
        _G._nnp_vim_file = vim.fn.tempname() .. " nnp source.vim"
        vim.fn.writefile({ "let g:nnp_sourced = 1" }, _G._nnp_vim_file)
        vim.cmd({ cmd = "source", args = { _G._nnp_vim_file } })
    ]])
    child.wait()

    Helpers.expect.equality(child.lua_get("vim.g.nnp_sourced"), 1)

    -- disable() still resets the state after that source
    child.nnp()
    child.wait()
    Helpers.expect.state(child, "enabled", true)

    child.nnp()
    child.wait()
    Helpers.expect.state(child, "enabled", false)
    Helpers.expect.state(child, "tabs", {})
end

return T
