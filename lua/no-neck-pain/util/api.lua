local debug = require("no-neck-pain.util.debug")

local api = { debouncers = {} }

--- Returns the current tab page or 1 if it's nil.
---
---@return number: the tabpage id.
---@private
function api.get_current_tab()
    return vim.api.nvim_get_current_tabpage() or 1
end

function api.tde(t1, t2)
    return vim.deepcopy(vim.tbl_deep_extend("keep", t1 or {}, t2 or {}))
end

--- Returns the name of the augroup for the given tab Idebug.
---
---@param id number?: the id of the tab.
---@return string: the initialied state
---@private
function api.get_augroup_name(id)
    return string.format("NoNeckPain-%d", id)
end

--- Determines if the given `win` or the current window is relative.
---
---@param win number?: the id of the window.
---@return boolean: true if the window is relative.
---@private
function api.is_relative_window(win)
    win = win or vim.api.nvim_get_current_win()

    if
        vim.api.nvim_win_get_config(0).relative ~= ""
        or vim.api.nvim_win_get_config(win).relative ~= ""
    then
        return true
    end

    return false
end

--- Sets buffer option with backward compatibility (nvim <9).
---
---@param id number: the id of the buffer.
---@param opt string: the opt name.
---@param val string|number|boolean: the opt value.
---@private
function api.set_buffer_option(id, opt, val)
    if _G.NoNeckPain.config.has_nvim9 then
        vim.api.nvim_set_option_value(opt, val, { buf = id })
    else
        vim.api.nvim_buf_set_option(id, opt, val)
    end
end

--- Sets window option with backward compatibility (nvim <9).
---
---@param id number: the id of the window.
---@param opt string: the opt name.
---@param val string|number: the opt value.
---@private
function api.set_window_option(id, opt, val)
    if _G.NoNeckPain.config.has_nvim9 then
        vim.api.nvim_set_option_value(opt, val, { win = id, scope = "local" })
    else
        vim.api.nvim_win_set_option(id, opt, val)
    end
end

local function timer_stop_close(timer)
    if timer:is_active() then
        timer:stop()
    end
    if not timer:is_closing() then
        timer:close()
    end
end

--- Execute callback timeout ms after the latest invocation with context.
--- Waiting invocations for that context will be discarded.
--- Invocation will be rescheduled while a callback is being executed.
--- Caller must ensure that callback performs the same or functionally equivalent actions.
---
---@param context string: identifies the callback to debounce.
---@param callback function: to execute on completion.
---@param timeout number?: ms to wait for before execution.
---@private
function api.debounce(context, callback, timeout)
    timeout = timeout or 2
    -- all execution here is done in a synchronous context; no thread safety required

    api.debouncers[context] = api.debouncers[context] or {}
    local debouncer = api.debouncers[context]

    -- cancel waiting or executing timer
    if debouncer.timer then
        timer_stop_close(debouncer.timer)
    end

    local timer = vim.loop.new_timer()
    debouncer.timer = timer
    timer:start(timeout, 0, function()
        timer_stop_close(timer)

        if debouncer.executing then
            debug.log(context, "already running on debounce, rescheduling...")
            return api.debounce(context, callback, timeout)
        end

        debouncer.executing = true
        vim.schedule(function()
            debug.log(context, ">> debouncer triggered")
            callback(context)
            debouncer.executing = false

            -- no other timer waiting
            if debouncer.timer == timer then
                api.debouncers[context] = nil
            end
        end)
    end)
end

--- Returns a map of opened buffer name with a boolean indicating if they are modified or not.
---
---@return table
---@private
function api.get_opened_buffers()
    local opened = {}

    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.fn.buflisted(buf) ~= 0 then
            local name = vim.api.nvim_buf_get_name(buf)

            if name == nil or name == "" then
                name = string.format("NoNamePain%s", buf)
            end

            opened[name] = vim.api.nvim_buf_get_option(buf, "modified")
        end
    end

    return opened
end

return api
