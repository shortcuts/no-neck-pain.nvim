local colors = require("no-neck-pain.colors")
local constants = require("no-neck-pain.util.constants")
local log = require("no-neck-pain.util.log")
local state = require("no-neck-pain.state")
local helpers = require("no-neck-pain.util.helpers")

local ui = {}

--- Initializes the given `side` with the options from the user given configuration.
---@param side "left"|"right"|"curr": the side of the window to initialize.
---@param id number?: the id of the window.
---@private
function ui.init_side_options(side, id)
    if id == nil then
        return
    end
    local bufid = vim.api.nvim_win_get_buf(id)

    for opt, val in pairs(helpers.get_config_field("buffers")[side].bo) do
        if not (state:get_scratch_pad() and opt == "filetype") then
            vim.api.nvim_set_option_value(opt, val, { buf = bufid })
        end
    end

    for opt, val in pairs(helpers.get_config_field("buffers")[side].wo) do
        vim.api.nvim_set_option_value(opt, val, { win = id, scope = "local" })
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

    local curr_win = vim.api.nvim_get_current_win()

    for _, side in ipairs(constants.SIDES) do
        local keys = sides[side]
        local sscope = string.format("%s:%s", scope, side)

        local id = state:get_side_id(side)
        if id ~= nil then
            local wins = vim.api.nvim_tabpage_list_wins(state.active_tab)

            if curr_win ~= id and vim.api.nvim_win_is_valid(id) then
                vim.cmd("noautocmd lua vim.api.nvim_set_current_win(" .. id .. ")")
            end

            vim.cmd("noautocmd " .. keys)

            if (side == "left" and wins[1] ~= id) or (side == "right" and wins[#wins] ~= id) then
                log.debug(
                    sscope,
                    "wrong position after window move, focusing %s, should be %d, wins order %s",
                    curr_win,
                    id,
                    vim.inspect(wins)
                )
            end
        end
    end

    if vim.api.nvim_win_is_valid(curr_win) then
        vim.cmd("noautocmd lua vim.api.nvim_set_current_win(" .. curr_win .. ")")
    end
end

--- Closes a window if it's valid.
---
---@param scope string: the scope from where this function is called.
---@param id number?: the id of the window.
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
---@param id number?: the side window id.
---@param cleanup boolean?: cleanup the given buffer
---@private
function ui.init_scratch_pad(side, id, cleanup)
    if id == nil then
        return
    end
    if not helpers.get_config_field("buffers")[side].enabled then
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
        helpers.get_config_field("buffers")[side].scratchPad.pathToFile
    )

    -- Switch to the side window before editing the buffer
    local curr_win = vim.api.nvim_get_current_win()
    if vim.api.nvim_win_is_valid(id) then
        vim.api.nvim_set_current_win(id)
    end

    local scratchpad_config = helpers.get_config_field("buffers")[side].scratchPad
    local path = scratchpad_config.pathToFile

    -- Handle empty/nil pathToFile by constructing default path
    if path == nil or path == "" then
        local location = scratchpad_config.location
        local fileName = scratchpad_config.fileName

        -- Check if deprecated location field is populated
        if location and location ~= "" then
            path = location .. "/" .. fileName .. "-" .. side .. ".norg"
        else
            -- Default: use current working directory
            path = vim.fn.getcwd() .. "/" .. "no-neck-pain-" .. side .. ".norg"
        end
    end

    -- Expand ~ and environment variables
    path = vim.fn.expand(path)
    path = vim.fn.fnameescape(path)
    vim.cmd(string.format("edit %s", path))

    -- Restore the previous window
    if vim.api.nvim_win_is_valid(curr_win) then
        vim.api.nvim_set_current_win(curr_win)
    end

    local buf_id = vim.api.nvim_win_get_buf(id)

    vim.api.nvim_set_option_value("bufhidden", "", { buf = buf_id })
    vim.api.nvim_set_option_value("buftype", "", { buf = buf_id })
    vim.api.nvim_set_option_value("buflisted", false, { buf = buf_id })
    vim.api.nvim_set_option_value("autoread", true, { buf = buf_id })
    vim.api.nvim_set_option_value("conceallevel", 2, { win = id, scope = "local" })

    -- users might want to use a filetype that isn't supported by neovim, we should let them
    -- if they've defined it on the configuration side.
    if vim.api.nvim_get_option_value("filetype", { buf = buf_id }) == "" then
        local filetype = helpers.get_config_field("buffers")[side].bo.filetype
        if filetype == "" or filetype == "no-neck-pain" then
            filetype = "norg"
        end
        vim.api.nvim_set_option_value("filetype", filetype, { buf = buf_id })
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
        left = { anchor = "NW", padding = ui.get_side_width("left") },
        right = { anchor = "SE", padding = ui.get_side_width("right") },
    }

    local created_in_first_loop = {}

    for _, side in ipairs(constants.SIDES) do
        if
            wins[side].padding >= helpers.get_config_field("minSideBufferWidth")
            and not state:is_side_valid(side)
            and wins[side].padding > 0
        then
            local bufid = vim.api.nvim_create_buf(false, false)

            if helpers.get_config_field("buffers").setNames then
                local exist = vim.fn.bufnr("no-neck-pain-" .. side)

                if exist ~= -1 then
                    vim.api.nvim_buf_delete(exist, { force = true })
                end

                vim.api.nvim_buf_set_name(bufid, "no-neck-pain-" .. side)
            end

            state:set_side_id(
                vim.api.nvim_open_win(bufid, false, {
                    vertical = true,
                    split = side,
                    anchor = wins[side].anchor,
                    width = wins[side].padding,
                    noautocmd = true,
                }),
                side
            )

            if helpers.get_config_field("buffers")[side].scratchPad.enabled then
                state:set_scratch_pad(true)
                ui.init_scratch_pad(side, state:get_side_id(side))
            else
                ui.init_side_options(side, state:get_side_id(side))
            end

            colors.init(state:get_side_id(side), side)
            created_in_first_loop[side] = true
        end
    end

    -- Refresh column count after creating new windows so the second loop
    -- computes widths with the correct number of columns.
    state:scan_layout("ui.create_side_buffers:rescan")
    state.tabs[state.active_tab].redraw = false

    for _, side in ipairs(constants.SIDES) do
        local scope = string.format("ui.create_side_buffers:%s", side)
        if state:is_side_valid(side) then
            local padding = ui.get_side_width(side)
            local minWidth = helpers.get_config_field("minSideBufferWidth")

            if padding < minWidth and padding > 0 then
                ui.close_win(scope, state:get_side_id(side), side)
                state:set_side_id(nil, side)
            elseif padding > 0 then
                local current_width = vim.api.nvim_win_get_width(state:get_side_id(side))
                if math.abs(current_width - padding) > 1 then
                    state:resize_win(scope, side, padding)
                end
            end
        else
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
    if helpers.get_config_field("width") >= vim.o.columns then
        log.debug(
            scope,
            "defined width in config is bigger than the current ui %d/%d",
            helpers.get_config_field("width"),
            width
        )

        return 0
    end

    local columns = state:get_columns()

    log.debug(scope, "%d width available, %d vsplit columns", width, columns)

    for _, _side in pairs(constants.SIDES) do
        if state:is_side_valid(_side) then
            columns = columns - 1
        end
    end

    -- remove columns of registered integrations
    for name, opts in pairs(state:get_integrations()) do
        if opts.id ~= nil and opts.position == side then
            local integration_width = vim.api.nvim_win_get_width(opts.id)

            log.debug(scope, "%s opened with width %d", name, integration_width)

            width = width - integration_width
            columns = columns - 1
        end
    end

    columns = columns - state:get_none_columns()

    log.debug(
        scope,
        "%d/%d after integrations - %d columns remaining",
        width,
        vim.o.columns,
        columns
    )

    while columns > 0 do
        width = width - helpers.get_config_field("width")
        columns = columns - 1
    end

    log.debug(scope, "%d/%d after vsplits - %d columns remaining", width, vim.o.columns, columns)

    local final = math.floor(width / 2)

    if final < helpers.get_config_field("minSideBufferWidth") or final < 0 then
        log.debug(scope, "no space left to create side buffer")

        return 0
    end

    return final
end

return ui
