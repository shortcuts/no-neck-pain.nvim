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
---@param side "left"|"right"|"split": the side of the window being resized, used for logging only.
---@private
local function resize(id, width, side)
    D.log(side, "resizing %d with padding %d", id, width)

    if vim.api.nvim_win_is_valid(id) then
        vim.api.nvim_win_set_width(id, width)
    end
end

---Initializes the given `side` with the options from the user given configuration.
---@param id number: the id of the window.
---@param side "left"|"right"|"split": the side of the window to initialize.
---@private
local function initSideOptions(id, side)
    local bufid = vim.api.nvim_win_get_buf(id)

    for opt, val in pairs(_G.NoNeckPain.config.buffers[side].bo) do
        A.setBufferOption(bufid, opt, val)
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
---@param cleanup boolean?: cleanup the given buffer
---@private
function W.initScratchPad(side, cleanup)
    if not _G.NoNeckPain.config.buffers[side].enabled then
        return
    end

    -- cleanup is used when the `toggle` method disables the scratchPad, we then reinitialize it with the user-given configuration.
    if cleanup then
        vim.cmd("enew")
        return initSideOptions(S.getSideID(S, side), side)
    end

    local location = _G.NoNeckPain.config.buffers[side].scratchPad.location or ""

    if location ~= "" and string.sub(location, -1) ~= "/" then
        location = location .. "/"
    end

    location = string.format(
        "%s%s-%s.%s",
        location,
        _G.NoNeckPain.config.buffers[side].scratchPad.fileName,
        side,
        _G.NoNeckPain.config.buffers[side].bo.filetype
    )

    -- we edit the file if it exists, otherwise we create it
    if vim.fn.filereadable(location) then
        vim.cmd(string.format("edit %s", location))
    else
        vim.api.nvim_buf_set_name(0, location)
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
    S.refreshIntegrations(S, "createSideBuffers")

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
                    W.initScratchPad(side)
                    S.setScratchpad(S, true)
                end

                initSideOptions(id, side)
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

    -- if we still have side buffers open at this point, and we have vsplit opened,
    -- there might be width issues so we the resize opened vsplits.
    if S.checkSides(S, "or", true) and S.hasSplits(S) then
        local side = S.getSideID(S, "left") or S.getSideID(S, "right")
        local sWidth, _ = A.getWidthAndHeight(side)
        local nbSide = 1

        if S.getSideID(S, "left") and S.getSideID(S, "right") then
            nbSide = 2
        end

        local tab = S.getTab(S)

        -- get the available usable width (screen size without side paddings)
        sWidth = vim.api.nvim_list_uis()[1].width - sWidth * nbSide
        sWidth = math.floor(sWidth / tab.layers.vsplit)

        for _, split in pairs(tab.wins.splits) do
            if split.vertical then
                resize(split.id, sWidth, "split")
            end
        end
    end

    -- closing integrations and reopening them means new window IDs
    if closedIntegrations then
        S.refreshIntegrations(S, "createSideBuffers")
    end
end

---Determine the "padding" (width) of the buffer based on the `_G.NoNeckPain.config.width` and the width of the screen.
---
---@param side "left"|"right": the side of the window.
---@return number: the width of the side window.
---@private
function W.getPadding(side)
    local uis = vim.api.nvim_list_uis()

    if uis[1] == nil then
        error("W.getPadding - attempted to get the padding of a non-existing UI.")

        return 0
    end

    local width = uis[1].width

    -- if the available screen size is lower than the config width,
    -- we don't have to create side buffers.
    if _G.NoNeckPain.config.width >= width then
        D.log("W.getPadding", "[%s] - ui %s - no space left to create side buffers", side, width)

        return 0
    end

    local tab = S.getTab(S)

    -- we need to see if there's enough space left to have side buffers
    local occupied = _G.NoNeckPain.config.width * tab.layers.vsplit

    -- if there's no space left according to the config width,
    -- then we don't have to create side buffers.
    if occupied >= width then
        D.log(side, "%d vsplits - no space left to create side buffers", tab.layers.vsplit)

        return 0
    end

    D.log(
        side,
        "%d currently with %d vsplits - computing integrations width",
        occupied,
        tab.layers.vsplit
    )

    -- now we need to determine how much we should substract from the remaining padding
    -- if there's side integrations open.
    local paddingToSubstract = 0

    for name, tree in pairs(tab.wins.integrations) do
        if
            tree ~= nil
            and tree.id ~= nil
            and side == _G.NoNeckPain.config.integrations[name].position
        then
            D.log(
                "W.getPadding",
                "[%s] - have an external open: %s with width %d",
                side,
                name,
                tree.width
            )

            paddingToSubstract = paddingToSubstract + tree.width
        end
    end

    return math.floor(
        (width - paddingToSubstract - (_G.NoNeckPain.config.width * tab.layers.vsplit)) / 2
    )
end

---Determine if the tab wins are still active and valid.
---
---@param checkSplits boolean: whether splits state should be considered or not.
---@return boolean: whether all windows are active and valid or not.
---@private
function W.stateWinsActive(checkSplits)
    if not S.isActiveTabValid(S) then
        return false
    end

    local tab = S.getTabSafe(S)

    if tab == nil then
        return false
    end

    if tab.wins.main ~= nil then
        for _, side in pairs(tab.wins.main) do
            if not vim.api.nvim_win_is_valid(side) then
                return false
            end
        end
    end

    if checkSplits and tab.wins.splits ~= nil then
        for _, split in pairs(tab.wins.splits) do
            if not vim.api.nvim_win_is_valid(split.id) then
                return false
            end
        end
    end

    return true
end

return W
