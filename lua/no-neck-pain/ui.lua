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
        if not (state.get_scratchPad(state) and opt == "filetype") then
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

        local id = state.get_side_id(state, side)
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
    if vim.api.nvim_win_is_valid(id) then
        log.debug(scope, "closing %s window", side)

        vim.api.nvim_win_close(id, false)
    end
end

--- Sets options to the side buffers to toggle the scratchPad.
---
---@param side "left"|"right": the side of the window being resized, used for logging only.
---@param id number: the side window Idebug.
---@param cleanup boolean?: cleanup the given buffer
---@private
function ui.init_scratchPad(side, id, cleanup)
    if not _G.NoNeckPain.config.buffers[side].enabled then
        return
    end

    -- cleanup is used when the `toggle` method disables the scratchPad, we then reinitialize it with the user-given configuration.
    if cleanup then
        vim.cmd("enew")
        return ui.init_side_options(side, id)
    end

    log.debug(
        string.format("ui.init_scratchPad:%s", side),
        "enabled with location %s",
        _G.NoNeckPain.config.buffers[side].scratchPad.pathToFile
    )

    ui.init_side_options(side, id)

    vim.cmd(string.format("edit %s", _G.NoNeckPain.config.buffers[side].scratchPad.pathToFile))

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
        if _G.NoNeckPain.config.buffers[side].enabled then
            if
                wins[side].padding > _G.NoNeckPain.config.minSideBufferWidth
                and not state.is_side_enabled_and_valid(state, side)
            then
                vim.cmd(wins[side].cmd)

                state.set_side_id(state, vim.api.nvim_get_current_win(), side)

                if _G.NoNeckPain.config.buffers.set_names then
                    local exist = vim.fn.bufnr("no-neck-pain-" .. side)

                    if exist ~= -1 then
                        vim.api.nvim_buf_delete(exist, { force = true })
                    end

                    vim.api.nvim_buf_set_name(0, "no-neck-pain-" .. side)
                end

                if _G.NoNeckPain.config.buffers[side].scratchPad.enabled then
                    state.set_scratchPad(state, true)
                    ui.init_scratchPad(side, state.get_side_id(state, side))
                else
                    ui.init_side_options(side, state.get_side_id(state, side))
                end

                colors.init(state.get_side_id(state, side), side)
            end
        end
    end

    for _, side in pairs(constants.SIDES) do
        if state.is_side_enabled_and_valid(state, side) then
            local padding = wins[side].padding or ui.get_side_width(side)

            if padding > _G.NoNeckPain.config.minSideBufferWidth then
                state.resize_win(state, state.get_side_id(state, side), padding, side)
            else
                ui.close_win("ui.create_side_buffers", state.get_side_id(state, side), side)
                state.set_side_id(state, nil, side)
            end
        end
    end
end

--- Determine the "padding" (width) of the buffer based on the `_G.NoNeckPain.config.width` and the width of the screen.
---
---@param side "left"|"right": the side of the window.
---@return number: the width of the side window.
---@private
function ui.get_side_width(side)
    local scope = string.format("get_side_width:%s", side)
    -- if the available screen size is lower than the config width,
    -- we don't have to create side buffers.
    if _G.NoNeckPain.config.width >= vim.o.columns then
        log.debug(scope, "[%s] - ui %s - no space left to create side buffers", side, vim.o.columns)

        return 0
    end

    local columns = state.get_columns(state)

    for _, s in ipairs(constants.SIDES) do
        -- remove sides but always keep 1 column for the curr, which will be computed with "splits"
        if state.is_side_enabled_and_valid(state, s) and columns > 1 then
            columns = columns - 1
        end
    end

    log.debug(scope, "%d/%d columns after side removal", columns, state.get_columns(state))

    local integration_width = 0

    -- remove columns of registered integrations
    for name, opts in pairs(state.get_integrations(state)) do
        if opts.id ~= nil then
            if
                not state.is_side_enabled_and_valid(state, side)
                or side == _G.NoNeckPain.config.integrations[name].position
            then
                local width = vim.api.nvim_win_get_width(opts.id)

                log.debug(scope, "%s opened with width %d", name, integration_width)

                integration_width = integration_width + width
            end

            columns = columns - 1
        end
    end

    log.debug(scope, "%d/%d columns after integration removal", columns, state.get_columns(state))

    if integration_width > 0 then
        log.debug(
            scope,
            "%d total width integrations - %d columns remaining",
            integration_width,
            columns
        )
    end

    local columns_width = 0

    while columns > 0 do
        columns_width = columns_width + _G.NoNeckPain.config.width
        columns = columns - 1
    end

    log.debug(scope, "%d total width columns - %d columns remaining", columns_width, columns)

    local final = math.floor((vim.o.columns - columns_width) / 2) - integration_width

    if final <= _G.NoNeckPain.config.minSideBufferWidth then
        log.debug(scope, "%d/%d not enough space", final, vim.o.columns)
    end

    return final
end

return ui
