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

T["setup"]["overrides default values"] = function()
    child.lua([[require('no-neck-pain').setup({
        buffers = {
            scratchPad = {
                enabled = true,
                location = "~/Documents",
            }
        },
    })]])

    Helpers.expect.config(child, "buffers.scratchPad", {
        enabled = true,
        fileName = "no-neck-pain",
        location = "~/Documents",
    })

    Helpers.expect.config(child, "buffers.left.scratchPad", {
        enabled = true,
        fileName = "no-neck-pain",
        location = "~/Documents",
    })

    Helpers.expect.config(child, "buffers.right.scratchPad", {
        enabled = true,
        fileName = "no-neck-pain",
        location = "~/Documents",
    })
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
    Helpers.toggle(child)
    Helpers.expect.equality(Helpers.winsInTab(child), { 1001, 1000, 1002 })

    local cwd = child.lua_get("vim.fn.getcwd()")
    local left = cwd .. "/no-neck-pain-left.norg"
    local right = cwd .. "/no-neck-pain-right.norg"

    Helpers.expect.equality(
        child.lua_get("vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(1001))"),
        left
    )
    Helpers.expect.equality(
        child.lua_get("vim.api.nvim_buf_get_option(vim.api.nvim_win_get_buf(1001), 'buflisted')"),
        false
    )

    Helpers.expect.equality(
        child.lua_get("vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(1002))"),
        right
    )
    Helpers.expect.equality(
        child.lua_get("vim.api.nvim_buf_get_option(vim.api.nvim_win_get_buf(1002), 'buflisted')"),
        false
    )
end

T["scratchPad"]["override of filetype is reflected to the buffer"] = function()
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
    Helpers.toggle(child)

    Helpers.expect.equality(Helpers.winsInTab(child), { 1001, 1000, 1002 })

    local cwd = child.lua_get("vim.fn.getcwd()")
    local left = cwd .. "/no-neck-pain-left.md"
    local right = cwd .. "/no-neck-pain-right.txt"

    Helpers.expect.equality(
        child.lua_get("vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(1001))"),
        left
    )
    Helpers.expect.equality(
        child.lua_get("vim.api.nvim_buf_get_option(vim.api.nvim_win_get_buf(1001), 'buflisted')"),
        false
    )

    Helpers.expect.equality(
        child.lua_get("vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(1002))"),
        right
    )
    Helpers.expect.equality(
        child.lua_get("vim.api.nvim_buf_get_option(vim.api.nvim_win_get_buf(1002), 'buflisted')"),
        false
    )
end

T["scratchPad"]["side buffer can have their own definition"] = function()
    child.lua([[require('no-neck-pain').setup({
        width = 50,
        buffers = {
            left = {
                scratchPad = {
                    enabled = true,
                    location = "./lua"
                },
            },
            right = {
                scratchPad = {
                    enabled = true
                },
            }
        },
    })]])
    Helpers.toggle(child)

    Helpers.expect.equality(Helpers.winsInTab(child), { 1001, 1000, 1002 })

    local cwd = child.lua_get("vim.fn.getcwd()")
    local left = cwd .. "/lua/no-neck-pain-left.norg"
    local right = cwd .. "/no-neck-pain-right.norg"

    Helpers.expect.equality(
        child.lua_get("vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(1001))"),
        left
    )
    Helpers.expect.equality(
        child.lua_get("vim.api.nvim_buf_get_option(vim.api.nvim_win_get_buf(1001), 'buflisted')"),
        false
    )

    Helpers.expect.equality(
        child.lua_get("vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(1002))"),
        right
    )
    Helpers.expect.equality(
        child.lua_get("vim.api.nvim_buf_get_option(vim.api.nvim_win_get_buf(1002), 'buflisted')"),
        false
    )
end

T["scratchPad"]["side buffer definition overrides global one"] = function()
    child.lua([[require('no-neck-pain').setup({
        width = 50,
        buffers = {
            scratchPad = {
                enabled = true,
                location = "./doc"
            },
            left = {
                scratchPad = {
                    enabled = true,
                    location = "./lua"
                },
            },
        },
    })]])
    Helpers.toggle(child)

    Helpers.expect.equality(Helpers.winsInTab(child), { 1001, 1000, 1002 })

    local cwd = child.lua_get("vim.fn.getcwd()")
    local left = cwd .. "/lua/no-neck-pain-left.norg"
    local right = cwd .. "/doc/no-neck-pain-right.norg"

    Helpers.expect.equality(
        child.lua_get("vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(1001))"),
        left
    )
    Helpers.expect.equality(
        child.lua_get("vim.api.nvim_buf_get_option(vim.api.nvim_win_get_buf(1001), 'buflisted')"),
        false
    )

    Helpers.expect.equality(
        child.lua_get("vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(1002))"),
        right
    )
    Helpers.expect.equality(
        child.lua_get("vim.api.nvim_buf_get_option(vim.api.nvim_win_get_buf(1002), 'buflisted')"),
        false
    )
end

T["scratchPad"]["throws with invalid location"] = function()
    Helpers.expect.error(function()
        child.lua(
            [[require('no-neck-pain').setup({buffers = { scratchPad = { enabled = true, location = 10 }}})]]
        )
        Helpers.toggle(child)
    end)
end

T["scratchPad"]["forwards the given filetype to the scratchpad"] = function()
    child.lua([[require('no-neck-pain').setup({
        width = 50,
        buffers = {
            scratchPad = {
                enabled = true
            },
            bo = {
                filetype = "custom"
            },
        },
    })]])
    Helpers.toggle(child)

    Helpers.expect.equality(Helpers.winsInTab(child), { 1001, 1000, 1002 })

    child.lua("vim.fn.win_gotoid(1001)")
    Helpers.expect.equality(child.lua_get("vim.api.nvim_buf_get_option(0, 'filetype')"), "custom")

    child.lua("vim.fn.win_gotoid(1002)")
    Helpers.expect.equality(child.lua_get("vim.api.nvim_buf_get_option(0, 'filetype')"), "custom")
end

return T
