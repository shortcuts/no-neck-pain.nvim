local A = require("no-neck-pain.util.api")
local C = require("no-neck-pain.colors")
local Co = require("no-neck-pain.util.constants")
local D = require("no-neck-pain.util.debug")
local S = require("no-neck-pain.state")

local W = {}

---Resizes a window if it's valid.
---
---@param id number: the id of the window.
---@param width number: the width to apply to the window.
---@param side "left"|"right"|"curr"|"unregistered": the side of the window being resized, used for logging only.
---@private
local function resize(id, width, side)
    D.log(side, "resizing %d with padding %d", id, width)

    if vim.api.nvim_win_is_valid(id) then
        vim.api.nvim_win_set_width(id, width)
    end
end

---Initializes the given `side` with the options from the user given configuration.
---@param side "left"|"right"|"curr": the side of the window to initialize.
---@param id number: the id of the window.
---@private
function W.initSideOptions(side, id)
    local bufid = vim.api.nvim_win_get_buf(id)

    for opt, val in pairs(_G.NoNeckPain.config.buffers[side].bo) do
        if not S.getScratchPad(S) and opt ~= "filetype" then
            A.setBufferOption(bufid, opt, val)
        end
    end

    for opt, val in pairs(_G.NoNeckPain.config.buffers[side].wo) do
        A.setWindowOption(id, opt, val)
    end
end

---Moves a side window to its original position
---
---@param scope string: the scope from where this function is called.
---@param side "left"|"right": the side of the window being closed, used for logging only.
---@private
function W.move(scope, side)
    local id = S.getSideID(S, side)
    if id == nil then
        return
    end

    if vim.api.nvim_win_is_valid(id) then
        local wins = vim.api.nvim_tabpage_list_wins(S.activeTab)

        if side == "left" then
            if wins[1] == id then
                return
            end
            vim.fn.win_splitmove(id, wins[1], { vertical = true })
        else
            if wins[#wins] == id then
                return
            end
            vim.fn.win_splitmove(id, wins[#wins], { vertical = true })
        end

        D.log(scope, "moving %s window", side)
    end
end

---Closes a window if it's valid.
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

---Sets options to the side buffers to toggle the scratchPad.
---
---@param side "left"|"right": the side of the window being resized, used for logging only.
---@param id number: the side window ID.
---@param cleanup boolean?: cleanup the given buffer
---@private
function W.initScratchPad(side, id, cleanup)
    if not _G.NoNeckPain.config.buffers[side].enabled then
        return
    end

    -- cleanup is used when the `toggle` method disables the scratchPad, we then reinitialize it with the user-given configuration.
    if cleanup then
        vim.cmd("enew")
        return W.initSideOptions(side, id)
    end

    D.log(
        string.format("W.initScratchPad:%s", side),
        "enabled with location %s",
        _G.NoNeckPain.config.buffers[side].scratchPad.pathToFile
    )

    W.initSideOptions(side, id)

    vim.cmd(string.format("edit %s", _G.NoNeckPain.config.buffers[side].scratchPad.pathToFile))

    A.setBufferOption(0, "bufhidden", "")
    A.setBufferOption(0, "buftype", "")
    A.setBufferOption(0, "buflisted", false)
    A.setBufferOption(0, "autoread", true)
    A.setWindowOption(id, "conceallevel", 2)

    -- users might want to use a filetype that isn't supported by neovim, we should let them
    -- if they've defined it on the configuration side.
    if vim.api.nvim_buf_get_option(0, "filetype") == "" then
        local filetype = _G.NoNeckPain.config.buffers[side].bo.filetype
        if filetype == "" or filetype == "no-neck-pain" then
            filetype = "norg"
        end
        A.setBufferOption(0, "filetype", filetype)
    end

    vim.o.autowriteall = true
end

---Creates side buffers with the correct padding, considering the side integrations.
--- - A side buffer is not created if there's not enough space.
--- - If it already exists, we resize it.
---
---@private
function W.createSideBuffers()
    local wins = {
        left = { cmd = "topleft vnew", padding = 0 },
        right = { cmd = "botright vnew", padding = 0 },
    }

    for _, side in pairs(Co.SIDES) do
        if _G.NoNeckPain.config.buffers[side].enabled then
            wins[side].padding = W.getPadding(side)

            if
                wins[side].padding > _G.NoNeckPain.config.minSideBufferWidth
                and not S.isSideWinValid(S, side)
            then
                vim.cmd(wins[side].cmd)

                S.setSideID(S, vim.api.nvim_get_current_win(), side)

                if _G.NoNeckPain.config.buffers.setNames then
                    local exist = vim.fn.bufnr("no-neck-pain-" .. side)

                    if exist ~= -1 then
                        vim.api.nvim_buf_delete(exist, { force = true })
                    end

                    vim.api.nvim_buf_set_name(0, "no-neck-pain-" .. side)
                end

                if _G.NoNeckPain.config.buffers[side].scratchPad.enabled then
                    S.setScratchPad(S, true)
                    W.initScratchPad(side, S.getSideID(S, side))
                else
                    W.initSideOptions(side, S.getSideID(S, side))
                end
            end

            C.init(S.getSideID(S, side), side)
        end
    end

    for _, side in pairs(Co.SIDES) do
        if S.isSideWinValid(S, side) then
            local padding = wins[side].padding or W.getPadding(side)

            if padding > _G.NoNeckPain.config.minSideBufferWidth then
                resize(S.getSideID(S, side), padding, side)
            else
                W.close("W.createSideBuffers", S.getSideID(S, side), side)
                S.setSideID(S, nil, side)
            end
        end
    end

    local columns = S.getColumns(S)
    local leftID = S.getSideID(S, "left")
    local rightID = S.getSideID(S, "right")

    -- if we still have side buffers open at this point, and we have vsplit opened,
    -- there might be width issues so we the resize opened vsplits.
    if (leftID or rightID) and columns > 1 then
        local sWidth = wins.left.padding or wins.right.padding
        local nbSide = leftID and rightID and 2 or 1

        -- get the available usable width (screen size without side paddings)
        sWidth = vim.o.columns - sWidth * nbSide
        local remainingVSplits = columns - nbSide

        if remainingVSplits < 1 then
            remainingVSplits = 1
        end

        sWidth = math.floor(sWidth / remainingVSplits)

        D.log(
            "splitResize",
            "%d/%d screen width remaining, %d columns including %d sides",
            sWidth,
            vim.o.columns,
            columns,
            nbSide
        )

        for _, win in pairs(S.getUnregisteredWins(S)) do
            resize(win, sWidth, string.format("unregistered:%d", win))
        end
    end
end

---Determine the "padding" (width) of the buffer based on the `_G.NoNeckPain.config.width` and the width of the screen.
---
---@param side "left"|"right": the side of the window.
---@return number: the width of the side window.
---@private
function W.getPadding(side)
    local scope = string.format("W.getPadding:%s", side)
    -- if the available screen size is lower than the config width,
    -- we don't have to create side buffers.
    if _G.NoNeckPain.config.width >= vim.o.columns then
        D.log(scope, "[%s] - ui %s - no space left to create side buffers", side, vim.o.columns)

        return 0
    end

    local columns = S.getColumns(S)

    for _, s in ipairs(Co.SIDES) do
        if S.isSideWinValid(S, s) and columns > 1 then
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
    for name, tree in pairs(S.getIntegrations(S)) do
        if
            tree.id ~= nil
            and (
                not S.isSideWinValid(S, side)
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
