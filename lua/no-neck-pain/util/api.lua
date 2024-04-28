local D = require("no-neck-pain.util.debug")

local A = { debouncers = {} }

---Returns the current tab page or 1 if it's nil.
---
---@return number: the tabpage id.
---@private
function A.getCurrentTab()
    return vim.api.nvim_get_current_tabpage() or 1
end

---Returns the number of keys in the given table
---
---@param tbl table: the table to count the keys.
---@return number: the number of keys in the table.
---@private
function A.length(tbl)
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end

function A.tde(t1, t2)
    return vim.deepcopy(vim.tbl_deep_extend("keep", t1 or {}, t2 or {}))
end

---Returns the name of the augroup for the given tab ID.
---
---@param id number?: the id of the tab.
---@return string: the initialied state
---@private
function A.getAugroupName(id)
    return string.format("NoNeckPain-%d", id)
end

---returns the width a given window if valid.
---
---@param win number?: the win number, defaults to 0 if nil.
---@return number: the width of the window.
---@private
function A.getWidth(win)
    win = win or 0

    if win ~= 0 and not vim.api.nvim_win_is_valid(win) then
        win = 0
    end

    return vim.api.nvim_win_get_width(win)
end

---Determines if the given `win` or the current window is relative.
---
---@param win number?: the id of the window.
---@return boolean: true if the window is relative.
---@private
function A.isRelativeWindow(win)
    win = win or vim.api.nvim_get_current_win()

    if
        vim.api.nvim_win_get_config(0).relative ~= ""
        or vim.api.nvim_win_get_config(win).relative ~= ""
    then
        return true
    end

    return false
end

---Sets buffer option with backward compatibility (nvim <9).
---
---@param id number: the id of the buffer.
---@param opt string: the opt name.
---@param val string|number|boolean: the opt value.
---@private
function A.setBufferOption(id, opt, val)
    if _G.NoNeckPain.config.hasNvim9 then
        vim.api.nvim_set_option_value(opt, val, { buf = id })
    else
        vim.api.nvim_buf_set_option(id, opt, val)
    end
end

---Sets window option with backward compatibility (nvim <9).
---
---@param id number: the id of the window.
---@param opt string: the opt name.
---@param val string|number: the opt value.
---@private
function A.setWindowOption(id, opt, val)
    if _G.NoNeckPain.config.hasNvim9 then
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

---Execute callback timeout ms after the latest invocation with context.
---Waiting invocations for that context will be discarded.
---Invocation will be rescheduled while a callback is being executed.
---Caller must ensure that callback performs the same or functionally equivalent actions.
---
---@param context string: identifies the callback to debounce.
---@param callback function: to execute on completion.
---@param timeout number?: ms to wait for before execution.
---@private
function A.debounce(context, callback, timeout)
    timeout = timeout or 2
    -- all execution here is done in a synchronous context; no thread safety required

    A.debouncers[context] = A.debouncers[context] or {}
    local debouncer = A.debouncers[context]

    -- cancel waiting or executing timer
    if debouncer.timer then
        timer_stop_close(debouncer.timer)
    end

    local timer = vim.loop.new_timer()
    debouncer.timer = timer
    timer:start(timeout, 0, function()
        timer_stop_close(timer)

        if debouncer.executing then
            D.log(context, "already running on debounce, rescheduling...")
            return A.debounce(context, callback, timeout)
        end

        debouncer.executing = true
        vim.schedule(function()
            callback(context)
            debouncer.executing = false

            -- no other timer waiting
            if debouncer.timer == timer then
                A.debouncers[context] = nil
            end
        end)
    end)
end

return A
