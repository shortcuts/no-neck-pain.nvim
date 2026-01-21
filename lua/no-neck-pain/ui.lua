local api = require("no-neck-pain.util.api")
local colors = require("no-neck-pain.colors")
local constants = require("no-neck-pain.util.constants")
local log = require("no-neck-pain.util.log")
local state = require("no-neck-pain.state")

local ui = {}

--- Initializes the given `side` with the options from the user given configuration.
---@param side "left"|"right"|"curr": the side of the window to initialize.
---@param id number: the id of the window.
---@private
function ui.init_side_options(side, id)
    local bufid = vim.api.nvim_win_get_buf(id)

    for opt, val in pairs(_G.NoNeckPain.config.buffers[side].bo) do
        if not (state:get_scratch_pad() and opt == "filetype") then
            api.set_buffer_option(bufid, opt, val)
        end
    end

    for opt, val in pairs(_G.NoNeckPain.config.buffers[side].wo) do
        api.set_window_option(id, opt, val)
    end
end

--- Moves the side buffers to their initial place
---
---@param scope string: the scope from where this function is called.
---@private
function ui.move_sides(scope)
    local sides = {
        left = vim.api.nvim_replace_termcodes("normal <C-W>H", true, false, true),
        right = vim.api.nvim_replace_termcodes("normal <C-W>L", true, false, true),
    }

    for side, keys in pairs(sides) do
        local sscope = string.format("%s:%s", scope, side)

        local id = state:get_side_id(side)
        if id ~= nil then
            local wins = vim.api.nvim_tabpage_list_wins(state.active_tab)
            local curr = vim.api.nvim_get_current_win()

            if curr ~= id then
                vim.api.nvim_set_current_win(id)
            end

            vim.cmd(keys)

            if (side == "left" and wins[1] ~= id) or (side == "right" and wins[#wins] ~= id) then
                log.debug(
                    sscope,
                    "wrong position after window move, focusing %s, should be %d, wins order %s",
                    curr,
                    id,
                    vim.inspect(wins)
                )
            end
        end
    end
end

--- Closes a window if it's valid.
---
---@param scope string: the scope from where this function is called.
---@param id number: the id of the window.
---@param side "left"|"right": the side of the window being closed, used for logging only.
---@private
function ui.close_win(scope, id, side)
    if id ~= nil and vim.api.nvim_win_is_valid(id) then
        log.debug(scope, "closing %s window", side)

        vim.api.nvim_win_close(id, false)
    end
end

--- Sets options to the side buffers to toggle the scratch_pad.
---
---@param side "left"|"right": the side of the window being resized, used for logging only.
---@param id number: the side window Idebug.
---@param cleanup boolean?: cleanup the given buffer
---@private
function ui.init_scratch_pad(side, id, cleanup)
    if not _G.NoNeckPain.config.buffers[side].enabled then
        return
    end

    -- cleanup is used when the `toggle` method disables the scratch_pad, we then reinitialize it with the user-given configuration.
    if cleanup then
        vim.cmd("enew")
        return ui.init_side_options(side, id)
    end

    log.debug(
        string.format("ui.init_scratch_pad:%s", side),
        "enabled with location %s",
        _G.NoNeckPain.config.buffers[side].scratchPad.pathToFile
    )

    ui.init_side_options(side, id)

    local path = vim.fn.fnameescape(_G.NoNeckPain.config.buffers[side].scratchPad.pathToFile)
    vim.cmd(string.format("edit %s", path))

    api.set_buffer_option(0, "bufhidden", "")
    api.set_buffer_option(0, "buftype", "")
    api.set_buffer_option(0, "buflisted", false)
    api.set_buffer_option(0, "autoread", true)
    api.set_window_option(id, "conceallevel", 2)

    -- users might want to use a filetype that isn't supported by neovim, we should let them
    -- if they've defined it on the configuration side.
    if vim.api.nvim_buf_get_option(0, "filetype") == "" then
        local filetype = _G.NoNeckPain.config.buffers[side].bo.filetype
        if filetype == "" or filetype == "no-neck-pain" then
            filetype = "norg"
        end
        api.set_buffer_option(0, "filetype", filetype)
    end

    vim.o.autowriteall = true
end

--- Creates side buffers with the correct padding, considering the side integrations.
--- - A side buffer is not created if there's not enough space.
--- - If it already exists, we resized it.
---
---@private
function ui.create_side_buffers()
    local wins = {
        left = { cmd = "topleft vnew", padding = ui.get_side_width("left") },
        right = { cmd = "botright vnew", padding = ui.get_side_width("right") },
    }

    for _, side in pairs(constants.SIDES) do
        if
            wins[side].padding > _G.NoNeckPain.config.minSideBufferWidth
            and not state:is_side_enabled_and_valid(side)
        then
            vim.cmd(wins[side].cmd)

            state:set_side_id(vim.api.nvim_get_current_win(), side)

            if _G.NoNeckPain.config.buffers.set_names then
                local exist = vim.fn.bufnr("no-neck-pain-" .. side)

                if exist ~= -1 then
                    vim.api.nvim_buf_delete(exist, { force = true })
                end

                vim.api.nvim_buf_set_name(0, "no-neck-pain-" .. side)
            end

            if _G.NoNeckPain.config.buffers[side].scratchPad.enabled then
                state:set_scratch_pad(true)
                ui.init_scratch_pad(side, state:get_side_id(side))
            else
                ui.init_side_options(side, state:get_side_id(side))
            end

            colors.init(state:get_side_id(side), side)
        end
    end

    for _, side in pairs(constants.SIDES) do
        if state:is_side_enabled_and_valid(side) then
            local padding = wins[side].padding or ui.get_side_width(side)
            local scope = string.format("ui.create_side_buffers:%s", side)

            if padding > _G.NoNeckPain.config.minSideBufferWidth then
                state:resize_win(scope, side, padding)
            else
                ui.close_win(scope, state:get_side_id(side), side)
                state:set_side_id(nil, side)
            end
        end
    end
end

--- Determine the "padding" (width) of a side window (`left` or `right` nnp buffer)
--- considering the currently occupied columns (vsplit) on the screen.
--- The reminder is the sum of: (nvim width - columns width) / 2
---
--- When 0 is returned, it means we can't and should not create the current side.
---
---@param side "left"|"right": the side of the window.
---@return number: the width of the side window.
---@private
function ui.get_side_width(side)
    local scope = string.format("get_side_width:%s", side)

    if not state:is_side_enabled(side) then
        log.debug(scope, "disabled")

        return 0
    end

    local width = vim.o.columns

    -- if the available screen size is lower than the config width,
    -- we don't have to create side buffers.
    if _G.NoNeckPain.config.width >= vim.o.columns then
        log.debug(
            scope,
            "defined width in config is bigger than the current ui %d/%d",
            _G.NoNeckPain.config.width,
            width
        )

        return 0
    end

    local columns = state:get_columns()

    log.debug(scope, "%d width available, %d vsplit columns", width, columns)

    for _, _side in pairs(constants.SIDES) do
        if state:is_side_enabled_and_valid(_side) then
            columns = columns - 1
        end
    end

    -- remove columns of registered integrations
    for name, opts in pairs(state:get_integrations()) do
        if opts.id ~= nil and side == opts.position then
            local integration_width = vim.api.nvim_win_get_width(opts.id)

            log.debug(scope, "%s opened with width %d", name, integration_width)

            width = width - integration_width
            columns = columns - 1
        end
    end

    log.debug(
        scope,
        "%d/%d after integrations - %d columns remaining",
        width,
        vim.o.columns,
        columns
    )

    while columns > 0 do
        width = width - _G.NoNeckPain.config.width
        columns = columns - 1
    end

    log.debug(scope, "%d/%d after vsplits - %d columns remaining", width, vim.o.columns, columns)

    local final = math.floor(width / 2)

    if final <= _G.NoNeckPain.config.minSideBufferWidth or final < 0 then
        log.debug(scope, "no space left to create side buffer")

        return 0
    end

    return final
end

return ui
