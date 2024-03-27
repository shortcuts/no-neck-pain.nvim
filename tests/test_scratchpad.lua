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
                pathToFile = "~/Documents/foo.md"
            }
        },
    })]])

    Helpers.expect.config(child, "buffers.left.scratchPad", {
        enabled = true,
        pathToFile = "~/Documents/foo.md",
    })

    Helpers.expect.config(child, "buffers.right.scratchPad", {
        enabled = true,
        pathToFile = "~/Documents/foo.md",
    })
end

T["setup"]["converts deprecate options to pathToFile"] = function()
    child.lua([[require('no-neck-pain').setup({
        buffers = {
            scratchPad = {
                enabled = true,
                fileName = "foo",
                location = "~/bar"
            }
        },
    })]])

    Helpers.expect.config(child, "buffers.left.scratchPad", {
        enabled = true,
        pathToFile = "~/bar/foo-left.norg",
    })

    Helpers.expect.config(child, "buffers.right.scratchPad", {
        enabled = true,
        pathToFile = "~/bar/foo-right.norg",
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

T["scratchPad"]["forwards the given filetype to the scratchPad"] = function()
    child.lua([[require('no-neck-pain').setup({
        width = 50,
        buffers = {
            scratchPad = {
                enabled = true,
                pathToFile = "foo.custom"
            },
            bo = {
                filetype = "custom"
            }
        },
    })]])
    Helpers.toggle(child)

    Helpers.expect.equality(Helpers.winsInTab(child), { 1001, 1000, 1002 })

    child.fn.win_gotoid(1001)
    Helpers.expect.equality(child.lua_get("vim.api.nvim_buf_get_option(0, 'filetype')"), "custom")

    child.fn.win_gotoid(1002)
    Helpers.expect.equality(child.lua_get("vim.api.nvim_buf_get_option(0, 'filetype')"), "custom")
end

T["scratchPad"]["toggling the scratchPad sets the buffer/window options"] = function()
    child.lua([[require('no-neck-pain').setup({
        width = 50,
        buffers = { scratchPad = { enabled = false }, },
        mappings = { scratchPad = "foo" },
    })]])
    Helpers.toggle(child)

    Helpers.expect.equality(Helpers.winsInTab(child), { 1001, 1000, 1002 })

    child.fn.win_gotoid(1001)
    Helpers.expect.equality(child.lua_get("vim.api.nvim_buf_get_option(0, 'buflisted')"), false)

    child.fn.win_gotoid(1002)
    Helpers.expect.equality(child.lua_get("vim.api.nvim_buf_get_option(0, 'buflisted')"), false)

    child.api.nvim_input("foo")

    child.fn.win_gotoid(1001)
    Helpers.expect.equality(child.lua_get("vim.api.nvim_buf_get_option(0, 'buflisted')"), false)

    child.fn.win_gotoid(1002)
    Helpers.expect.equality(child.lua_get("vim.api.nvim_buf_get_option(0, 'buflisted')"), false)
end

return T
