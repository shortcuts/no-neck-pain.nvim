local helpers = dofile("tests/helpers.lua")

local child = helpers.new_child_neovim()
local eq_config = helpers.expect.config_equality

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
        integrations = {
            NvimTree = {
                position = "right",
                close = false,
                reopen = false,
            },
            undotree = {
                position = "right",
            }
        }
    })]])

    eq_config(child, "integrations.NvimTree.position", "right")
    eq_config(child, "integrations.NvimTree.close", false)
    eq_config(child, "integrations.NvimTree.reopen", false)
    eq_config(child, "integrations.undotree.position", "right")
end

T["integrations"] = MiniTest.new_set()

T["integrations"]["NvimTree with wrong values"] = function()
    helpers.expect.error(function()
        child.lua([[ require('no-neck-pain').setup({
                    integrations = {
                        NvimTree = {
                            "position": "nope"
                        },
                    },
                })
            ]])
    end)
end

return T
