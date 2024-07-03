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
---@param side "left"|"right"|"curr"|"vsplit": the side of the window being resized, used for logging only.
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
        if S.getScratchPad(S) and opt == "filetype" then
            goto continue
        end
        A.setBufferOption(bufid, opt, val)
        ::continue::
    end

    for opt, val in pairs(_G.NoNeckPain.config.buffers[side].wo) do
        A.setWindowOption(id, opt, val)
    end
end

---Closes a window if it's valid.
---
---@param scope string: the scope from where this function is called.
---@param id number: the id of the window.
---@param side "left"|"right": the side of the window being closed, used for logging only.
---@private
function W.close(scope, id, side)
    D.log(scope, "closing %s window", side)

    if vim.api.nvim_win_is_valid(id) then
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
---@param skipIntegrations boolean?: skip integrations action when true.
---@private
function W.createSideBuffers(skipIntegrations)
    -- before creating side buffers, we determine if we should consider externals
    S.scanLayout(S, "createSideBuffers")

    local wins = {
        left = { cmd = "topleft vnew", padding = 0 },
        right = { cmd = "botright vnew", padding = 0 },
    }

    local closedIntegrations = false
    if not skipIntegrations then
        closedIntegrations = S.closeIntegration(S)
    end

    for _, side in pairs(Co.SIDES) do
        if _G.NoNeckPain.config.buffers[side].enabled then
            wins[side].padding = W.getPadding(side)

            if
                wins[side].padding > _G.NoNeckPain.config.minSideBufferWidth
                and not S.isSideWinValid(S, side)
            then
                vim.cmd(wins[side].cmd)

                local id = vim.api.nvim_get_current_win()

                if _G.NoNeckPain.config.buffers.setNames then
                    local exist = vim.fn.bufnr("no-neck-pain-" .. side)

                    if exist ~= -1 then
                        vim.api.nvim_buf_delete(exist, { force = true })
                    end

                    vim.api.nvim_buf_set_name(0, "no-neck-pain-" .. side)
                end

                S.setSideID(S, id, side)

                if _G.NoNeckPain.config.buffers[side].scratchPad.enabled then
                    S.setScratchPad(S, true)
                    W.initScratchPad(side, id)
                else
                    W.initSideOptions(side, id)
                end
            end

            local sideID = S.getSideID(S, side)

            if sideID ~= nil then
                C.init(sideID, side)
            end
        end
    end

    if closedIntegrations and not skipIntegrations then
        S.reopenIntegration(S)
    end

    local vsplits, nbVSplits = S.getVSplits(S)
    local leftID = S.getSideID(S, "left")
    local rightID = S.getSideID(S, "right")

    -- if we still have side buffers open at this point, and we have vsplit opened,
    -- there might be width issues so we the resize opened vsplits.
    if (leftID or rightID) and nbVSplits > 0 then
        -- local sWidth = wins.left.padding or wins.right.padding
        -- local nbSide = leftID and rightID and 2 or 1
        --
        -- -- get the available usable width (screen size without side paddings)
        -- sWidth = vim.api.nvim_list_uis()[1].width - sWidth * nbSide
        -- sWidth = math.floor(sWidth / (nbVSplits - nbSide))

        for vsplit, _ in pairs(vsplits) do
            if vsplit ~= leftID and vsplit ~= rightID and vsplit ~= S.getSideID(S, "curr") then
                resize(vsplit, _G.NoNeckPain.config.width, "vsplit")
            end
        end

        resize(S.getSideID(S, "curr"), _G.NoNeckPain.config.width, "curr")
    end

    for _, side in pairs(Co.SIDES) do
        if S.isSideRegistered(S, side) then
            local padding = wins[side].padding or W.getPadding(side)

            if padding > _G.NoNeckPain.config.minSideBufferWidth then
                resize(S.getSideID(S, side), padding, side)
            else
                W.close("W.createSideBuffers", S.getSideID(S, side), side)
                S.setSideID(S, nil, side)
            end
        end
    end

    -- closing integrations and reopening them means new window IDs
    if closedIntegrations then
        S.scanLayout(S, "createSideBuffers")
    end
end

---Determine the "padding" (width) of the buffer based on the `_G.NoNeckPain.config.width` and the width of the screen.
---
---@param side "left"|"right": the side of the window.
---@return number: the width of the side window.
---@private
function W.getPadding(side)
    local scope = string.format("W.getPadding:%s", side)
    local uis = vim.api.nvim_list_uis()

    if uis[1] == nil then
        error("attempted to get the padding of a non-existing UI.")

        return 0
    end

    local width = uis[1].width

    -- if the available screen size is lower than the config width,
    -- we don't have to create side buffers.
    if _G.NoNeckPain.config.width >= width then
        D.log(scope, "[%s] - ui %s - no space left to create side buffers", side, width)

        return 0
    end

    local _, columns = S.getVSplits(S)

    for _, s in ipairs(Co.SIDES) do
        if S.isSideEnabled(S, s) and columns > 1 then
            columns = columns - 1
        end
    end

    -- we need to see if there's enough space left to have side buffers
    local occupied = _G.NoNeckPain.config.width * columns

    D.log(scope, "have %d vsplits", columns)

    -- if there's no space left according to the config width,
    -- then we don't have to create side buffers.
    if occupied >= width then
        D.log(scope, "%d occupied - no space left to create side", occupied)

        return 0
    end

    D.log(scope, "%d/%d with vsplits, computing integrations", occupied, width)

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

    local final = math.floor((width - occupied) / 2)

    D.log(scope, "%d/%d with integrations - final %d", occupied, width, final)

    return final
end

return W
