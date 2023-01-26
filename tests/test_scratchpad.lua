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

T["setup"] = MiniTest.new_set()

T["setup"]["overrides default values"] = function()
    child.lua([[require('no-neck-pain').setup({
        buffers = {
            scratchPad = {
                enabled = true,
                location = "~/Documents",
            }
        },
    })]])

    eq_config(child, "buffers.scratchPad.enabled", true)
    eq_config(child, "buffers.scratchPad.location", "~/Documents")
end

T["scratchPad"] = MiniTest.new_set()

T["scratchPad"]["default to `norg` fileType"] = function()
    child.lua([[require('no-neck-pain').setup({
        width = 50,
        buffers = {
            scratchPad = {
                enabled = true
            }
        },
    })]])
    child.lua([[require('no-neck-pain').enable()]])

    eq(
        child.lua_get("vim.api.nvim_tabpage_list_wins(_G.NoNeckPain.state.tabs)"),
        { 1001, 1000, 1002 }
    )

    local cwd = child.lua_get("vim.fn.getcwd()")
    local left = cwd .. "/no-neck-pain-left.norg"
    local right = cwd .. "/no-neck-pain-right.norg"

    eq(child.lua_get("vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(1001))"), left)
    eq(
        child.lua_get("vim.api.nvim_buf_get_option(vim.api.nvim_win_get_buf(1001), 'buflisted')"),
        false
    )

    eq(child.lua_get("vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(1002))"), right)
    eq(
        child.lua_get("vim.api.nvim_buf_get_option(vim.api.nvim_win_get_buf(1002), 'buflisted')"),
        false
    )
end

T["scratchPad"]["override to md is reflected to the buffer"] = function()
    child.lua([[require('no-neck-pain').setup({
        width = 50,
        buffers = {
            scratchPad = {
                enabled = true
            },
            left = {
                bo = {
                    filetype = "md",
                },
            },
            right = {
                bo = {
                    filetype = "txt",
                }
            }
        },
    })]])
    child.lua([[require('no-neck-pain').enable()]])

    eq(
        child.lua_get("vim.api.nvim_tabpage_list_wins(_G.NoNeckPain.state.tabs)"),
        { 1001, 1000, 1002 }
    )

    local cwd = child.lua_get("vim.fn.getcwd()")
    local left = cwd .. "/no-neck-pain-left.md"
    local right = cwd .. "/no-neck-pain-right.txt"

    eq(child.lua_get("vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(1001))"), left)
    eq(
        child.lua_get("vim.api.nvim_buf_get_option(vim.api.nvim_win_get_buf(1001), 'buflisted')"),
        false
    )

    eq(child.lua_get("vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(1002))"), right)
    eq(
        child.lua_get("vim.api.nvim_buf_get_option(vim.api.nvim_win_get_buf(1002), 'buflisted')"),
        false
    )
end

return T
