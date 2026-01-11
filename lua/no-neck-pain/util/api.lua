local log = require("no-neck-pain.util.log")

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
        -- Check if timer is still valid before processing
        if timer:is_closing() then
            return
        end

        timer_stop_close(timer)

        if debouncer.executing then
            -- Use a new timer for recursion instead of reusing the same one
            return api.debounce(context, callback, timeout)
        end

        debouncer.executing = true
        vim.schedule(function()
            log.debug(context, ">> debouncer triggered")
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

--- Whether the given id is a side id or not.
---
---@param side number?: the id of the side to compare.
---@param id number: the id to compare to the side.
---@return boolean
---@private
function api.is_side_id(side, id)
    if side == nil then
        return false
    end

    return side == id
end

--- Itherates over a given list of wins, starting from a given index, walking from a given step (+1/-1).
--- Once an id that is not any of the side is found, return the position in the table, nil otherwise.
---
---@param start_idx number: the idx to start from in `wins`.
---@param step -1|1: the walk direction in `wins`, from `start_idx`.
---@param wins table: the table of wins ids to walk in.
---@param current_side number: the `left` or `right` side id.
---@param other_side number: the `left` or `right` side id.
---@param previously_focused number: the previously focused window.
---@return number?
---@private
function api.find_next_side_idx(start_idx, step, wins, current_side, other_side, previously_focused)
    local n = #wins

    for k = 1, n do
        -- Calculate the next index using modular arithmetic
        local index = (start_idx + (k - 1) * step - 1) % n + 1

        if
            not api.is_side_id(current_side, wins[index])
            and not api.is_side_id(other_side, wins[index])
            and wins[index] ~= previously_focused
            and vim.api.nvim_win_get_config(wins[index]).focusable
        then
            return index
        end
    end

    -- Fallback in case no valid index is found
    return nil
end

return api
