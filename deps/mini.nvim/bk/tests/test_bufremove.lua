local helpers = dofile("tests/helpers.lua")

local child = helpers.new_child_neovim()
local expect, eq = helpers.expect, helpers.expect.equality
local new_set = MiniTest.new_set

-- Helpers with child processes
--stylua: ignore start
local load_module = function(config) child.mini_load('bufremove', config) end
local unload_module = function() child.mini_unload('bufremove') end
local win_get_buf = function(...) return child.api.nvim_win_get_buf(...) end
local buf_get_option = function(...) return child.api.nvim_buf_get_option(...) end
--stylua: ignore end

-- Make helpers
local setup_layout = function()
    local res = {}

    child.cmd("silent %bwipeout!")

    -- Create two vertical windows (with ids 'win_left' and 'win_right') with the
    -- same active buffer ('buf') but different alternate buffers (with ids
    -- 'buf_left' and 'buf_right' respectively)
    child.cmd("edit buf")
    res["buf"] = child.api.nvim_get_current_buf()

    child.cmd("edit buf_right")
    res["buf_right"], res["win_right"] =
        child.api.nvim_get_current_buf(), child.api.nvim_get_current_win()

    child.cmd("edit # | vsplit | edit buf_left")
    res["buf_left"], res["win_left"] =
        child.api.nvim_get_current_buf(), child.api.nvim_get_current_win()

    child.cmd("edit #")

    return res
end

local validate_unshow_alternate = function(fun_name, layout)
    eq(child.lua_get(("MiniBufremove.%s()"):format(fun_name)), true)

    eq(win_get_buf(layout["win_left"]), layout["buf_left"])
    eq(win_get_buf(layout["win_right"]), layout["buf_right"])
end

local validate_unshow_bprevious = function(fun_name, layout)
    child.cmd("bwipeout " .. layout["buf_left"])
    local bprevious_buf = child.api.nvim_create_buf(true, false)

    eq(child.lua_get(("MiniBufremove.%s()"):format(fun_name)), true)

    eq(win_get_buf(layout["win_left"]), bprevious_buf)
    eq(win_get_buf(layout["win_right"]), layout["buf_right"])
end

local validate_unshow_scratch = function(fun_name, layout)
    -- Wipeout all buffers except current
    child.cmd(".+,$bwipeout")

    eq(child.lua_get(("MiniBufremove.%s()"):format(fun_name)), true)

    -- Verify that created buffer is scratch buffer
    local new_buf = child.api.nvim_get_current_buf()
    expect.no_equality(new_buf, layout["buf"])
    eq(buf_get_option(new_buf, "buflisted"), true)
    eq(buf_get_option(new_buf, "buftype"), "nofile")

    eq(win_get_buf(layout["win_left"]), new_buf)
    eq(win_get_buf(layout["win_right"]), new_buf)
end

local validate_args_validation = function(fun_name, args)
    if vim.tbl_contains(args, "buf_id") then
        local command = ("MiniBufremove.%s(100)"):format(fun_name)
        eq(child.lua_get(command), false)
        local last_message = child.cmd_capture("1messages")
        eq(last_message, "(mini.bufremove) 100 is not a valid buffer id.")
    end

    if args["force"] then
        local command = ("MiniBufremove.%s(nil, 1)"):format(fun_name)
        eq(child.lua_get(command), false)
        local last_message = child.cmd_capture("1messages")
        eq(last_message, "(mini.bufremove) `force` should be boolean.")
    end
end

local validate_unshow_with_buf_id = function(fun_name, layout)
    local command = ("MiniBufremove.%s(...)"):format(fun_name)
    eq(child.lua_get(command, { layout["buf"] }), true)

    eq(win_get_buf(layout["win_left"]), layout["buf_left"])
    eq(win_get_buf(layout["win_right"]), layout["buf_right"])
end

local validate_force_argument = function(fun_name, layout)
    child.api.nvim_buf_set_lines(layout["buf"], 0, -1, true, { "aaa" })
    -- Avoid hit-enter prompt due to long message
    child.o.cmdheight = 10

    local output = child.lua_get(("MiniBufremove.%s()"):format(fun_name))
    eq(output, false)
    eq(win_get_buf(layout["win_left"]), layout["buf"])
    eq(win_get_buf(layout["win_right"]), layout["buf"])

    local last_message = child.cmd_capture("1message")
    expect.match(last_message, "Buffer " .. layout["buf"] .. " has unsaved changes%..*Use.*force")

    output = child.lua_get(("MiniBufremove.%s(nil, true)"):format(fun_name))
    eq(output, true)
    eq(win_get_buf(layout["win_left"]), layout["buf_left"])
    eq(win_get_buf(layout["win_right"]), layout["buf_right"])
end

local validate_disable = function(var_type, fun_name, layout)
    child[var_type].minibufremove_disable = true
    local output = child.lua_get(("MiniBufremove.%s()"):format(fun_name))
    eq(output, vim.NIL)

    -- Check that lyout didn't change
    eq(win_get_buf(layout["win_left"]), layout["buf"])
    eq(win_get_buf(layout["win_right"]), layout["buf"])
end

local validate_bufhidden_option = function(fun_name, bufhidden_value)
    local layout = setup_layout()
    child.api.nvim_buf_set_option(layout["buf"], "bufhidden", bufhidden_value)

    local command = ("MiniBufremove.%s(...)"):format(fun_name)
    local output = child.lua_get(command, { layout["buf"] })
    eq(output, true)

    if fun_name == "wipeout" or bufhidden_value == "wipe" then
        eq(child.api.nvim_buf_is_valid(layout["buf"]), false)
    else
        eq(buf_get_option(layout["buf"], "buflisted"), false)
    end
end

-- Output test set ============================================================
local layout
T = new_set({
    hooks = {
        pre_case = function()
            child.setup()
            layout = setup_layout()
            load_module()
        end,
        post_once = child.stop,
    },
})

-- Unit tests =================================================================
T["setup()"] = new_set()

T["setup()"]["creates side effects"] = function()
    -- Global variable
    eq(child.lua_get("type(_G.MiniBufremove)"), "table")

    -- Sets appropriate settings
    eq(child.lua_get("vim.o.hidden"), true)
end

T["setup()"]["creates `config` field"] = function()
    eq(child.lua_get("type(_G.MiniBufremove.config)"), "table")

    -- Check default values
    eq(child.lua_get("MiniBufremove.config.set_vim_settings"), true)
end

T["setup()"]["respects `config` argument"] = function()
    unload_module()
    load_module({ set_vim_settings = false })
    eq(child.lua_get("MiniBufremove.config.set_vim_settings"), false)
end

T["setup()"]["validates `config` argument"] = function()
    unload_module()

    local expect_config_error = function(config, name, target_type)
        expect.error(load_module, vim.pesc(name) .. ".*" .. vim.pesc(target_type), config)
    end

    expect_config_error("a", "config", "table")
    expect_config_error({ set_vim_settings = "a" }, "set_vim_settings", "boolean")
end

T["unshow()"] = new_set()

T["unshow()"]["uses alternate buffer"] = function()
    validate_unshow_alternate("unshow", layout)
    eq(buf_get_option(layout["buf"], "buflisted"), true)
end

T["unshow()"]["uses `bprevious`"] = function()
    validate_unshow_bprevious("unshow", layout)
    eq(buf_get_option(layout["buf"], "buflisted"), true)
end

T["unshow()"]["creates a scratch buffer"] = function()
    validate_unshow_scratch("unshow", layout)
    eq(buf_get_option(layout["buf"], "buflisted"), true)
end

T["unshow()"]["validates arguments"] = function()
    validate_args_validation("unshow", { "buf_id" })
end

T["unshow()"]["respects `buf_id` argument"] = function()
    validate_unshow_with_buf_id("unshow", layout)
    eq(buf_get_option(layout["buf"], "buflisted"), true)
end

T["unshow()"]["respects `vim.{g,b}.minibufremove_disable`"] = new_set({
    parametrize = { { "g" }, { "b" } },
}, {
    test = function(var_type)
        validate_disable(var_type, "unshow", layout)
    end,
})

T["unshow_in_window()"] = new_set()

T["unshow_in_window()"]["uses alternate buffer"] = function()
    eq(child.lua_get("MiniBufremove.unshow_in_window()"), true)
    eq(win_get_buf(layout["win_left"]), layout["buf_left"])
    eq(win_get_buf(layout["win_right"]), layout["buf"])

    -- Ensure that buffer is not deleted
    eq(buf_get_option(layout["buf"], "buflisted"), true)
end

T["unshow_in_window()"]["uses `bprevious`"] = function()
    child.cmd("bwipeout " .. layout["buf_left"])
    local previous_buf = child.api.nvim_create_buf(true, false)

    eq(child.lua_get("MiniBufremove.unshow_in_window()"), true)
    eq(win_get_buf(layout["win_left"]), previous_buf)
    eq(win_get_buf(layout["win_right"]), layout["buf"])

    -- Ensure that buffer is not deleted
    eq(buf_get_option(layout["buf"], "buflisted"), true)
end

T["unshow_in_window()"]["creates a scratch buffer"] = function()
    child.cmd(".+,$bwipeout")
    eq(child.lua_get("MiniBufremove.unshow_in_window()"), true)

    -- Verify that created buffer is scratch buffer
    local new_buf = child.api.nvim_get_current_buf()
    eq(buf_get_option(new_buf, "buflisted"), true)
    eq(buf_get_option(new_buf, "buftype"), "nofile")

    eq(win_get_buf(layout["win_left"]), new_buf)
    eq(win_get_buf(layout["win_right"]), layout["buf"])

    -- Ensure that buffer is not deleted
    eq(buf_get_option(layout["buf"], "buflisted"), true)
end

T["unshow_in_window()"]["validates arguments"] = function()
    eq(child.lua_get("MiniBufremove.unshow_in_window(100)"), false)
    local last_message = child.cmd_capture("1messages")
    eq(last_message, "(mini.bufremove) 100 is not a valid window id.")
end

T["unshow_in_window()"]["respects `win_id` argument"] = function()
    local output = child.lua_get("MiniBufremove.unshow_in_window(...)", { layout["win_left"] })
    eq(output, true)
    eq(win_get_buf(layout["win_left"]), layout["buf_left"])
    eq(win_get_buf(layout["win_right"]), layout["buf"])
end

T["unshow_in_window()"]["respects `vim.{g,b}.minibufremove_disable`"] = new_set({
    parametrize = { { "g" }, { "b" } },
}, {
    test = function(var_type)
        validate_disable(var_type, "unshow_in_window", layout)
    end,
})

T["delete()"] = new_set()

T["delete()"]["uses alternate buffer"] = function()
    validate_unshow_alternate("delete", layout)
    eq(buf_get_option(layout["buf"], "buflisted"), false)
end

T["delete()"]["uses `bprevious`"] = function()
    validate_unshow_bprevious("delete", layout)
    eq(buf_get_option(layout["buf"], "buflisted"), false)
end

T["delete()"]["creates a scratch buffer"] = function()
    validate_unshow_scratch("delete", layout)
    eq(buf_get_option(layout["buf"], "buflisted"), false)
end

T["delete()"]["validates arguments"] = function()
    validate_args_validation("delete", { "buf_id", "force" })
end

T["delete()"]["respects `buf_id` argument"] = function()
    validate_unshow_with_buf_id("delete", layout)
    eq(buf_get_option(layout["buf"], "buflisted"), false)
end

T["delete()"]["respects `force` argument"] = function()
    validate_force_argument("delete", layout)
end

T["delete()"]["respects `vim.{g,b}.minibufremove_disable`"] = new_set({
    parametrize = { { "g" }, { "b" } },
}, {
    test = function(var_type)
        validate_disable(var_type, "delete", layout)
    end,
})

T["delete()"]["works with different 'bufhidden' options"] = function()
    validate_bufhidden_option("delete", "delete")
    validate_bufhidden_option("delete", "wipe")
end

T["wipeout()"] = new_set()

T["wipeout()"]["uses alternate buffer"] = function()
    validate_unshow_alternate("wipeout", layout)
    eq(child.api.nvim_buf_is_valid(layout["buf"]), false)
end

T["wipeout()"]["uses `bprevious`"] = function()
    validate_unshow_bprevious("wipeout", layout)
    eq(child.api.nvim_buf_is_valid(layout["buf"]), false)
end

T["wipeout()"]["creates a scratch buffer"] = function()
    validate_unshow_scratch("wipeout", layout)
    eq(child.api.nvim_buf_is_valid(layout["buf"]), false)
end

T["wipeout()"]["validates arguments"] = function()
    validate_args_validation("wipeout", { "buf_id", "force" })
end

T["wipeout()"]["respects `buf_id` argument"] = function()
    validate_unshow_with_buf_id("wipeout", layout)
    eq(child.api.nvim_buf_is_valid(layout["buf"]), false)
end

T["wipeout()"]["respects `force` argument"] = function()
    validate_force_argument("wipeout", layout)
end

T["wipeout()"]["respects `vim.{g,b}.minibufremove_disable`"] = new_set({
    parametrize = { { "g" }, { "b" } },
}, {
    test = function(var_type)
        validate_disable(var_type, "wipeout", layout)
    end,
})

T["wipeout()"]["works with different 'bufhidden' options"] = function()
    validate_bufhidden_option("wipeout", "delete")
    validate_bufhidden_option("wipeout", "wipe")
end

return T
