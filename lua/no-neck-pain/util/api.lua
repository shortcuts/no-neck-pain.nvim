local D = require("no-neck-pain.util.debug")

local A = { debouncers = {} }

---Returns the name of the augroup for the given tab ID.
---
---@param id number?: the id of the tab.
---@return string: the initialied state
---@private
function A.getAugroupName(id)
    return string.format("NoNeckPain-%d", id)
end

---returns the width and height of a given window
---
---@param win number?: the win number, defaults to 0 if nil
---@return number: the width of the window
---@return number: the height of the window
---@private
function A.getWidthAndHeight(win)
    win = win or 0

    if win ~= 0 and not vim.api.nvim_win_is_valid(win) then
        win = 0
    end

    return vim.api.nvim_win_get_width(win), vim.api.nvim_win_get_height(win)
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
---@param context string: identifies the callback to debounce
---@param callback function: to execute on completion
---@private
function A.debounce(context, callback)
    local timeout = 50
    -- all execution here is done in a synchronous context; no thread safety required

    A.debouncers[context] = A.debouncers[context] or {}
    local debouncer = A.debouncers[context]

    -- cancel waiting or executing timer
    if debouncer.timer then
        D.log(context, "cancelling ongoing debouncers")

        timer_stop_close(debouncer.timer)
    end

    local timer = vim.loop.new_timer()
    debouncer.timer = timer
    timer:start(timeout, 0, function()
        timer_stop_close(timer)

        -- reschedule when callback is running
        if debouncer.executing then
            D.log(context, "already running, skipping")
            return A.debounce(context, callback)
        end

        -- callback at a safe time
        debouncer.executing = true
        vim.schedule(function()
            D.log(context, "running on debounce")
            callback()
            debouncer.executing = false

            -- no other timer waiting
            if debouncer.timer == timer then
                A.debouncers[context] = nil
            end
        end)
    end)
end

return A
