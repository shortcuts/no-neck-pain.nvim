local colors = require("no-neck-pain.colors")
local constants = require("no-neck-pain.util.constants")
local log = require("no-neck-pain.util.log")
local state = require("no-neck-pain.state")

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
    local buffer = _G.NoNeckPain.config.buffers[side]

    for opt, val in pairs(buffer.bo) do
        if not (state:get_scratch_pad() and opt == "filetype") then
            vim.api.nvim_set_option_value(opt, val, { buf = bufid })
        end
    end

    for opt, val in pairs(buffer.wo) do
        vim.api.nvim_set_option_value(opt, val, { win = id, scope = "local" })
    end
end

--- Moves the side buffers to their place, see `ui.get_side_target`.
---
---@param scope string: the scope from where this function is called.
---@private
function ui.move_sides(scope)
    local eventignore = vim.o.eventignore
    vim.o.eventignore = "all"

    for _, side in ipairs(constants.SIDES) do
        local id = state:get_side_id(side)
        if id ~= nil and vim.api.nvim_win_is_valid(id) then
            local win, split, placed = ui.get_side_target(side)

            if not placed then
                log.debug(string.format("%s:%s", scope, side), "moving next to %d", win)

                local width = vim.api.nvim_win_get_width(id)
                vim.api.nvim_win_set_config(id, { win = win, split = split })
                -- a moved split gets a default width, moving is position-only.
                vim.api.nvim_win_set_width(id, width)
            end
        end
    end

    vim.o.eventignore = eventignore
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
    local buffer = _G.NoNeckPain.config.buffers[side]
    if not buffer.enabled then
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
        buffer.scratchPad.pathToFile
    )

    -- Switch to the side window before editing the buffer
    local curr_win = vim.api.nvim_get_current_win()
    if vim.api.nvim_win_is_valid(id) then
        vim.api.nvim_set_current_win(id)
    end

    local scratchpad_config = buffer.scratchPad
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
        local filetype = buffer.bo.filetype
        if filetype == "" or filetype == "no-neck-pain" then
            filetype = "norg"
        end
        vim.api.nvim_set_option_value("filetype", filetype, { buf = buf_id })
    end

    vim.o.autowriteall = true
end

--- Computes where the `side` buffer belongs: at the screen edge, or against
--- the integrations positioned on that `side`. Integrations are never moved,
--- so the plugin does not compete with them for the edge.
---
---@param side "left"|"right": the side of the window.
---@return number: the window to split from, `-1` for the whole tab.
---@return "left"|"right": the split direction relative to that window.
---@return boolean: whether the `side` buffer already is at its place.
---@private
function ui.get_side_target(side)
    local id = state:get_side_id(side)
    local layout = vim.fn.winlayout()
    local nodes = layout[1] == "row" and layout[2] or { layout }

    local integrations = {}
    for _, opts in pairs(state:get_integrations()) do
        if opts.id ~= nil and opts.position == side then
            integrations[opts.id] = true
        end
    end

    local function has_integration(node)
        if node[1] == "leaf" then
            return integrations[node[2]] == true
        end
        for _, child in ipairs(node[2]) do
            if has_integration(child) then
                return true
            end
        end
        return false
    end

    -- walk from the `side` edge towards the middle of the screen.
    local ordered = {}
    local only_integrations = true
    for i = 1, #nodes do
        local node = side == "left" and nodes[i] or nodes[#nodes - i + 1]
        if not (node[1] == "leaf" and node[2] == id) then
            table.insert(ordered, node)
            only_integrations = only_integrations and has_integration(node)
        elseif only_integrations then
            -- the side buffer must not have any integration further inside.
            local rest_has_integration = false
            for j = i + 1, #nodes do
                local rest = side == "left" and nodes[j] or nodes[#nodes - j + 1]
                rest_has_integration = rest_has_integration or has_integration(rest)
            end
            if not rest_has_integration then
                return -1, side, true
            end
        end
    end

    local opposite = side == "left" and "right" or "left"
    local outer
    for _, node in ipairs(ordered) do
        if not has_integration(node) then
            if outer == nil then
                return -1, side, false
            end
            -- splitting a direct leaf of the top-level row keeps the full height.
            if node[1] == "leaf" then
                return node[2], side, false
            end
            if outer[1] == "leaf" then
                return outer[2], opposite, false
            end
            break
        end
        outer = node
    end

    -- ponytail: no full-height leaf to split from, the edge wins over the integrations.
    return -1, side, false
end

--- Creates side buffers with the correct padding, considering the side integrations.
--- - A side buffer is not created if there's not enough space.
--- - If it already exists, we resized it.
---
---@private
function ui.create_side_buffers()
    local config = _G.NoNeckPain.config
    local wins = {
        left = { anchor = "NW", padding = ui.get_side_width("left") },
        right = { anchor = "SE", padding = ui.get_side_width("right") },
    }

    for _, side in ipairs(constants.SIDES) do
        if
            wins[side].padding >= config.minSideBufferWidth
            and not state:is_side_valid(side)
            and wins[side].padding > 0
        then
            local bufid = vim.api.nvim_create_buf(false, false)
            local target, split = ui.get_side_target(side)

            if config.buffers.setNames then
                local exist = vim.fn.bufnr("no-neck-pain-" .. side)

                if exist ~= -1 then
                    vim.api.nvim_buf_delete(exist, { force = true })
                end

                vim.api.nvim_buf_set_name(bufid, "no-neck-pain-" .. side)
            end

            state:set_side_id(
                vim.api.nvim_open_win(bufid, false, {
                    win = target,
                    vertical = true,
                    split = split,
                    anchor = wins[side].anchor,
                    width = wins[side].padding,
                    noautocmd = true,
                }),
                side
            )

            if config.buffers[side].scratchPad.enabled then
                state:set_scratch_pad(true)
                ui.init_scratch_pad(side, state:get_side_id(side))
            else
                ui.init_side_options(side, state:get_side_id(side))
            end

            colors.init(state:get_side_id(side), side)
        end
    end

    -- Refresh column count after creating new windows so the second loop
    -- computes widths with the correct number of columns. This call can be the
    -- response to a pending redraw request, so drain the flag through the
    -- guarded accessor: a debounced caller can run after the tab was
    -- unregistered.
    state:scan_layout("ui.create_side_buffers:rescan")
    state:consume_redraw()

    for _, side in ipairs(constants.SIDES) do
        local scope = string.format("ui.create_side_buffers:%s", side)
        if state:is_side_valid(side) then
            local padding = ui.get_side_width(side)

            if padding > 0 then
                local current_width = vim.api.nvim_win_get_width(state:get_side_id(side))
                if math.abs(current_width - padding) > 1 then
                    state:resize_win(scope, side, padding)
                end
            else
                ui.close_win(scope, state:get_side_id(side), side)
                state:set_side_id(nil, side)
            end
        end
    end

    -- a side-positioned integration (e.g. nvim-dap-ui's sidebar) splits itself
    -- off `curr` directly, which permanently takes width away from it: nvim's
    -- own split/close redistribution never routes that width back to `curr`
    -- once its side pad has shrunk or closed to make room (freed pad width
    -- goes to the integration's own column, its immediate neighbour, not to
    -- `curr`). Reclaim it explicitly so `curr` stays at `config.width`
    -- whenever there is room for it.
    local curr_id = state:get_side_id("curr")
    if curr_id ~= nil and vim.api.nvim_win_is_valid(curr_id) and config.width < vim.o.columns then
        local has_side_integration = false
        for _, opts in pairs(state:get_integrations()) do
            if opts.id ~= nil and (opts.position == "left" or opts.position == "right") then
                has_side_integration = true
                break
            end
        end

        if has_side_integration and vim.api.nvim_win_get_width(curr_id) ~= config.width then
            vim.api.nvim_win_set_width(curr_id, config.width)
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
    local config = _G.NoNeckPain.config

    if not state:is_side_enabled(side) then
        log.debug(scope, "disabled")

        return 0
    end

    local width = vim.o.columns

    -- if the available screen size is lower than the config width,
    -- we don't have to create side buffers.
    if config.width >= vim.o.columns then
        log.debug(
            scope,
            "defined width in config is bigger than the current ui %d/%d",
            config.width,
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
        elseif opts.id ~= nil and (opts.position == "left" or opts.position == "right") then
            -- a real, side-specific integration column that belongs to the
            -- other side: its width is (or will be) accounted for by that
            -- side's own `get_side_width` call, so it must not also fall
            -- into this side's generic per-column charge below, which
            -- assumes `config.width` for anything it can't identify.
            log.debug(scope, "%s belongs to the other side, excluding from generic charge", name)

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
        width = width - config.width
        columns = columns - 1
    end

    log.debug(scope, "%d/%d after vsplits - %d columns remaining", width, vim.o.columns, columns)

    local final = math.floor(width / 2)

    local other_side = side == "left" and "right" or "left"

    if final < 0 and not state:is_side_enabled(other_side) then
        log.debug(scope, "no space left and only one side active, closing")

        return -1
    end

    if final < 0 then
        log.debug(scope, "no space left to create side buffer")

        return 0
    end

    local minWidth = config.minSideBufferWidth

    if minWidth > 0 and final < minWidth then
        log.debug(scope, "side buffer too small, closing")

        return -1
    end

    return final
end

return ui
