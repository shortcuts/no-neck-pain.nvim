local A = require("no-neck-pain.util.api")
local C = require("no-neck-pain.colors")
local Co = require("no-neck-pain.util.constants")
local D = require("no-neck-pain.util.debug")
local S = require("no-neck-pain.state")

local W = {}

--- Resizes a window if it's valid.
---
---@param id number: the id of the window.
---@param width number: the width to apply to the window.
---@param side "left"|"right"|"curr"|"unregistered": the side of the window being resized, used for logging only.
---@private
function W.resize(id, width, side)
    D.log(side, "resizing %d with padding %d", id, width)

    if vim.api.nvim_win_is_valid(id) then
        vim.api.nvim_win_set_width(id, width)
    end
end

--- Initializes the given `side` with the options from the user given configuration.
---@param side "left"|"right"|"curr": the side of the window to initialize.
---@param id number: the id of the window.
---@private
function W.init_side_options(side, id)
    local bufid = vim.api.nvim_win_get_buf(id)

    for opt, val in pairs(_G.NoNeckPain.config.buffers[side].bo) do
        if not S.get_scratchPad(S) and opt ~= "filetype" then
            A.set_buffer_option(bufid, opt, val)
        end
    end

    for opt, val in pairs(_G.NoNeckPain.config.buffers[side].wo) do
        A.set_window_option(id, opt, val)
    end
end

--- Reposition the side buffers to their initial place
---
---@param scope string: the scope from where this function is called.
---@private
function W.reposition(scope)
    local sides = {
        left = vim.api.nvim_replace_termcodes("normal <C-W>H", true, false, true),
        right = vim.api.nvim_replace_termcodes("normal <C-W>L", true, false, true),
    }

    local restore_focus = false

    for side, keys in pairs(sides) do
        local sscope = string.format("%s:%s", scope, side)

        local id = S.get_side_id(S, side)
        if id ~= nil then
            local wins = vim.api.nvim_tabpage_list_wins(S.active_tab)
            local curr = vim.api.nvim_get_current_win()

            if curr ~= id then
                D.log(sscope, "wrong win focused %d re-routing to %d", curr, id)

                vim.api.nvim_set_current_win(id)
            end

            vim.cmd(keys)

            wins = vim.api.nvim_tabpage_list_wins(S.active_tab)

            if (side == "left" and wins[1] ~= id) or (side == "right" and wins[#wins] ~= id) then
                D.log(
                    sscope,
                    "wrong position after window move, focusing %s, should be %d, wins order %s",
                    vim.api.nvim_get_current_win(),
                    id,
                    vim.inspect(wins)
                )
            end

            restore_focus = true
        end
    end

    if restore_focus and S.get_side_id(S, "curr") ~= nil then
        vim.api.nvim_set_current_win(S.get_side_id(S, "curr"))
    end
end

--- Closes a window if it's valid.
---
---@param scope string: the scope from where this function is called.
---@param id number: the id of the window.
---@param side "left"|"right": the side of the window being closed, used for logging only.
---@private
function W.close(scope, id, side)
    if vim.api.nvim_win_is_valid(id) then
        D.log(scope, "closing %s window", side)

        vim.api.nvim_win_close(id, false)
    end
end

--- Sets options to the side buffers to toggle the scratchPad.
---
---@param side "left"|"right": the side of the window being resized, used for logging only.
---@param id number: the side window ID.
---@param cleanup boolean?: cleanup the given buffer
---@private
function W.init_scratchPad(side, id, cleanup)
    if not _G.NoNeckPain.config.buffers[side].enabled then
        return
    end

    -- cleanup is used when the `toggle` method disables the scratchPad, we then reinitialize it with the user-given configuration.
    if cleanup then
        vim.cmd("enew")
        return W.init_side_options(side, id)
    end

    D.log(
        string.format("W.init_scratchPad:%s", side),
        "enabled with location %s",
        _G.NoNeckPain.config.buffers[side].scratchPad.pathToFile
    )

    W.init_side_options(side, id)

    vim.cmd(string.format("edit %s", _G.NoNeckPain.config.buffers[side].scratchPad.pathToFile))

    A.set_buffer_option(0, "bufhidden", "")
    A.set_buffer_option(0, "buftype", "")
    A.set_buffer_option(0, "buflisted", false)
    A.set_buffer_option(0, "autoread", true)
    A.set_window_option(id, "conceallevel", 2)

    -- users might want to use a filetype that isn't supported by neovim, we should let them
    -- if they've defined it on the configuration side.
    if vim.api.nvim_buf_get_option(0, "filetype") == "" then
        local filetype = _G.NoNeckPain.config.buffers[side].bo.filetype
        if filetype == "" or filetype == "no-neck-pain" then
            filetype = "norg"
        end
        A.set_buffer_option(0, "filetype", filetype)
    end

    vim.o.autowriteall = true
end

--- Creates side buffers with the correct padding, considering the side integrations.
--- - A side buffer is not created if there's not enough space.
--- - If it already exists, we resize it.
---
---@private
function W.create_side_buffers()
    local wins = {
        left = { cmd = "topleft vnew", padding = 0 },
        right = { cmd = "botright vnew", padding = 0 },
    }

    for _, side in pairs(Co.SIDES) do
        if _G.NoNeckPain.config.buffers[side].enabled then
            wins[side].padding = W.get_padding(side)

            if
                wins[side].padding > _G.NoNeckPain.config.minSideBufferWidth
                and not S.is_side_win_valid(S, side)
            then
                vim.cmd(wins[side].cmd)

                S.set_side_id(S, vim.api.nvim_get_current_win(), side)

                if _G.NoNeckPain.config.buffers.set_names then
                    local exist = vim.fn.bufnr("no-neck-pain-" .. side)

                    if exist ~= -1 then
                        vim.api.nvim_buf_delete(exist, { force = true })
                    end

                    vim.api.nvim_buf_set_name(0, "no-neck-pain-" .. side)
                end

                if _G.NoNeckPain.config.buffers[side].scratchPad.enabled then
                    S.set_scratchPad(S, true)
                    W.init_scratchPad(side, S.get_side_id(S, side))
                else
                    W.init_side_options(side, S.get_side_id(S, side))
                end
            end

            C.init(S.get_side_id(S, side), side)
        end
    end

    for _, side in pairs(Co.SIDES) do
        if S.is_side_win_valid(S, side) then
            local padding = wins[side].padding or W.get_padding(side)

            if padding > _G.NoNeckPain.config.minSideBufferWidth then
                W.resize(S.get_side_id(S, side), padding, side)
            else
                W.close("W.create_side_buffers", S.get_side_id(S, side), side)
                S.set_side_id(S, nil, side)
            end
        end
    end
end

--- Determine the "padding" (width) of the buffer based on the `_G.NoNeckPain.config.width` and the width of the screen.
---
---@param side "left"|"right": the side of the window.
---@return number: the width of the side window.
---@private
function W.get_padding(side)
    local scope = string.format("W.get_padding:%s", side)
    -- if the available screen size is lower than the config width,
    -- we don't have to create side buffers.
    if _G.NoNeckPain.config.width >= vim.o.columns then
        D.log(scope, "[%s] - ui %s - no space left to create side buffers", side, vim.o.columns)

        return 0
    end

    local columns = S.get_columns(S)

    for _, s in ipairs(Co.SIDES) do
        if S.is_side_win_valid(S, s) and columns > 1 then
            columns = columns - 1
        end
    end

    -- we need to see if there's enough space left to have side buffers
    local occupied = _G.NoNeckPain.config.width * columns

    D.log(scope, "have %d columns", columns)

    -- if there's no space left according to the config width,
    -- then we don't have to create side buffers.
    if occupied >= vim.o.columns then
        D.log(scope, "%d occupied - no space left to create side", occupied)

        return 0
    end

    D.log(scope, "%d/%d with columns, computing integrations", occupied, vim.o.columns)

    -- now we need to determine how much we should substract from the remaining padding
    -- if there's side integrations open.
    for name, tree in pairs(S.get_integrations(S)) do
        if
            tree.id ~= nil
            and (
                not S.is_side_win_valid(S, side)
                or side == _G.NoNeckPain.config.integrations[name].position
            )
        then
            D.log(scope, "%s opened with width %d", name, tree.width)

            occupied = occupied + tree.width
        end
    end

    local final = math.floor((vim.o.columns - occupied) / 2)

    D.log(scope, "%d/%d with integrations - final %d", occupied, vim.o.columns, final)

    return final
end

return W
