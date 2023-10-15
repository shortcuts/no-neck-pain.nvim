local A = require("no-neck-pain.util.api")
local C = require("no-neck-pain.colors")
local Co = require("no-neck-pain.util.constants")
local D = require("no-neck-pain.util.debug")
local T = require("no-neck-pain.trees")

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

---Closes a window if it's valid.
---
---@param scope string: the scope from where this function is called.
---@param id number: the id of the window.
---@param side "left"|"right": the side of the window being resized, used for logging only.
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

    -- on cleanup we open a new buffer and set the default options
    if cleanup then
        vim.cmd("enew")

        for opt, val in pairs(_G.NoNeckPain.config.buffers[side].bo) do
            vim.api.nvim_buf_set_option(0, opt, val)
        end

        for opt, val in pairs(_G.NoNeckPain.config.buffers[side].wo) do
            vim.api.nvim_win_set_option(0, opt, val)
        end

        return
    end

    local location = ""

    if _G.NoNeckPain.config.buffers[side].scratchPad.location ~= nil then
        assert(
            type(_G.NoNeckPain.config.buffers[side].scratchPad.location) == "string",
            "`scratchPad.location` must be a nil or a string."
        )

        location = _G.NoNeckPain.config.buffers[side].scratchPad.location
    end

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

    vim.api.nvim_buf_set_option(0, "bufhidden", "")
    vim.api.nvim_buf_set_option(0, "buftype", "")
    vim.api.nvim_buf_set_option(0, "buflisted", false)
    vim.api.nvim_buf_set_option(0, "autoread", true)
    vim.o.autowriteall = true
end

---Resizes side buffers, considering the existing trees.
---Closes them if there's not enough space left.
---
---@param scope string: the scope from where this function is called.
---@param paddings table: the paddings of each side window.
---@return number?: the left window id.
---@return number?: the right window id.
---@private
local function resizeOrCloseSideBuffers(scope, paddings)
    for _, side in pairs(Co.SIDES) do
        if State.isSideRegistered(State, side) then
            local padding = paddings[side].padding or W.getPadding(side)

            if padding > _G.NoNeckPain.config.minSideBufferWidth then
                resize(State.getSideID(State, side), padding, side)
            else
                W.close(scope, State.getSideID(State, side), side)
                State.setSideID(State, nil, side)
            end
        end
    end
end

---Creates side buffers with the correct padding, considering the side trees.
--- - A side buffer is not created if there's not enough space.
--- - If it already exists, we resize it.
---
---@param skipTrees boolean?: skip trees action when true.
---@private
function W.createSideBuffers(skipTrees)
    -- before creating side buffers, we determine if we should consider externals
    State.refreshTrees(State)

    local wins = {
        left = { cmd = "topleft vnew", padding = 0 },
        right = { cmd = "botright vnew", padding = 0 },
    }

    local trees = nil

    if not skipTrees then
        trees = T.close()
    end

    for _, side in pairs(Co.SIDES) do
        if _G.NoNeckPain.config.buffers[side].enabled then
            wins[side].padding = W.getPadding(side)

            if wins[side].padding > _G.NoNeckPain.config.minSideBufferWidth and not State.isSideWinValid(State, side) then
                vim.cmd(wins[side].cmd)

                local id = vim.api.nvim_get_current_win()

                if _G.NoNeckPain.config.buffers.setNames then
                    local exist = vim.fn.bufnr("no-neck-pain-" .. side)

                    if exist ~= -1 then
                        vim.api.nvim_buf_delete(exist, { force = true })
                    end

                    vim.api.nvim_buf_set_name(0, "no-neck-pain-" .. side)
                end

                for opt, val in pairs(_G.NoNeckPain.config.buffers[side].bo) do
                    vim.api.nvim_buf_set_option(0, opt, val)
                end

                for opt, val in pairs(_G.NoNeckPain.config.buffers[side].wo) do
                    vim.api.nvim_win_set_option(id, opt, val)
                end

                if _G.NoNeckPain.config.buffers[side].scratchPad.enabled then
                    W.initScratchPad(side)
                    State.setScratchpad(State, true)
                end

                State.setSideID(State, id, side)
            end

            local sideID = State.getSideID(State, side)

            if sideID ~= nil then
                C.init(sideID, side)
            end
        end
    end

    if not skipTrees and trees ~= nil then
        T.reopen(trees)
    end

    resizeOrCloseSideBuffers("W.createSideBuffers", wins)

    -- if we still have side buffers open at this point, and we have vsplit opened,
    -- there might be width issues so we the resize opened vsplits.
    if (State.isSideRegistered(State, 'left') or State.isSideRegistered(State, 'right')) and State.hasSplits(State) then
        local side = State.getSideID(State, 'left') or State.getSideID(State, 'right')
        local sWidth, _ = A.getWidthAndHeight(side)
        local nbSide = 1

        if State.getSideID(State, 'left') and State.getSideID(State, 'right') then
            nbSide = 2
        end

        local tab = State.getTab(State)

        -- get the available usable width (screen size without side paddings)
        sWidth = vim.api.nvim_list_uis()[1].width - sWidth * nbSide
        sWidth = math.floor(sWidth / tab.layers.vsplit)

        for _, split in pairs(tab.wins.splits) do
            if split.vertical then
                resize(split.id, sWidth, "split")
            end
        end
    end

    -- we might have closed trees during the buffer creation process, we re-fetch the latest IDs to prevent inconsistencies
    State.refreshTrees(State)
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

    local tab = State.getTab(State)

    -- we need to see if there's enough space left to have side buffers
    local occupied = _G.NoNeckPain.config.width * tab.layers.vsplit

    -- if there's no space left according to the config width,
    -- then we don't have to create side buffers.
    if occupied >= width then
        D.log(side, "%d vsplits - no space left to create side buffers", tab.layers.vsplit)

        return 0
    end

    D.log(side, "%d currently with splits - computing trees width", occupied)

    -- now we need to determine how much we should substract from the remaining padding
    -- if there's side trees open.
    local paddingToSubstract = 0

    for name, tree in pairs(tab.wins.external.trees) do
        if
            tree ~= nil
            and tree.id ~= nil
            and side == _G.NoNeckPain.config.integrations[tree.configName].position
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
---@param tab table: the table where the tab information are stored.
---@param checkSplits boolean: whether splits state should be considered or not.
---@return boolean: whether all windows are active and valid or not.
---@private
function W.stateWinsActive(tab, checkSplits)
    if not vim.api.nvim_tabpage_is_valid(tab.id) then
        return false
    end

    local wins = vim.api.nvim_tabpage_list_wins(tab.id)
    local swins = tab.wins.main

    if checkSplits and tab.wins.splits ~= nil then
        swins = State.getRegisteredWins(State, true, true, false)
    end

    for _, swin in pairs(swins) do
        if not vim.tbl_contains(wins, swin) then
            return false
        end
    end

    return true
end

return W
