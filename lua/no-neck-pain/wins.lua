local C = require("no-neck-pain.color")
local Co = require("no-neck-pain.util.constants")
local D = require("no-neck-pain.util.debug")
local Sp = require("no-neck-pain.splits")
local T = require("no-neck-pain.trees")

local W = {}

---Resizes a window if it's valid.
---
---@param id number: the id of the window.
---@param width number: the width to apply to the window.
---@param side "left"|"right": the side of the window being resized, used for logging only.
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

---Creates side buffers with the correct padding, considering the side trees.
--- - A side buffer is not created if there's not enough space.
--- - If it already exists, we resize it.
---
---@param tab table: the table where the tab information are stored.
---@return table: the updated tab.
---@private
function W.createSideBuffers(tab)
    -- before creating side buffers, we determine if we should consider externals
    tab.wins.external.trees = T.refresh(tab)

    local wins = {
        left = { cmd = "topleft vnew", padding = 0 },
        right = { cmd = "botright vnew", padding = 0 },
    }

    local integrations = {
        NvimTree = false,
    }

    -- we close the side tree if it's already opened to prevent unwanted layout issue.
    if tab.wins.external.trees.NvimTree.id ~= nil then
        integrations.NvimTree = true
        vim.cmd("NvimTreeClose")
    end

    for _, side in pairs(Co.SIDES) do
        if _G.NoNeckPain.config.buffers[side].enabled then
            local valid = tab.wins.main[side] ~= nil
                and vim.api.nvim_win_is_valid(tab.wins.main[side])

            wins[side].padding = W.getPadding(side, tab.wins)

            if wins[side].padding > _G.NoNeckPain.config.minSideBufferWidth and not valid then
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

                C.init(id, tab.id, side)

                -- default options for scratchpad
                if _G.NoNeckPain.config.buffers.scratchPad.enabled then
                    local location = ""

                    if _G.NoNeckPain.config.buffers.scratchPad.location ~= nil then
                        assert(
                            type(_G.NoNeckPain.config.buffers.scratchPad.location) == "string",
                            "`buffers.scratchPad.location` must be a nil or a string."
                        )

                        location = _G.NoNeckPain.config.buffers.scratchPad.location
                    end

                    if location ~= "" and string.sub(location, -1) ~= "/" then
                        location = location .. "/"
                    end

                    location = location
                        .. _G.NoNeckPain.config.buffers.scratchPad.fileName
                        .. "-"
                        .. side
                        .. "."
                        .. _G.NoNeckPain.config.buffers[side].bo.filetype

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

                tab.wins.main[side] = id
            end
        end
    end

    -- if we've closed the user side tree but they still want it to be opened.
    if integrations.NvimTree and _G.NoNeckPain.config.integrations.NvimTree.reopen == true then
        vim.cmd("NvimTreeOpen")
    end

    tab.wins.main.left, tab.wins.main.right =
        W.resizeOrCloseSideBuffers("W.createSideBuffers", tab.wins, wins)

    -- we might have closed trees during the buffer creation process, we re-fetch the latest IDs to prevent inconsistencies
    tab.wins.external.trees = T.refresh(tab)

    return tab
end

---Determines if the given `win` or the current window is relative.
---
---@param win number?: the id of the window.
---@return boolean: true if the window is relative.
---@private
function W.isRelativeWindow(win)
    win = win or vim.api.nvim_get_current_win()

    if
        vim.api.nvim_win_get_config(0).relative ~= ""
        or vim.api.nvim_win_get_config(win).relative ~= ""
    then
        return true
    end

    return false
end

---Gets all wins that are not already registered in the given `tab`, we consider side trees if provided.
---
---@param tab table: the table where the tab information are stored.
---@param withTrees boolean: whether we should consider external windows or not.
---@return table: the wins that are not in `tab`.
---@return number: the total number of `wins`.
---@private
function W.winsExceptState(tab, withTrees)
    local wins = vim.api.nvim_tabpage_list_wins(tab.id)
    local mergedWins =
        W.mergeState(tab.wins.main, tab.wins.splits, withTrees and tab.wins.external.trees or nil)

    local validWins = {}
    local size = 0

    for _, win in pairs(wins) do
        if not vim.tbl_contains(mergedWins, win) and not W.isRelativeWindow(win) then
            table.insert(validWins, win)
            size = size + 1
        end
    end

    return validWins, size
end

---Resizes side buffers, considering the existing trees.
---Closes them if there's not enough space left.
---
---@param scope string: the scope from where this function is called.
---@param wins table: the state wins for the current tab.
---@param paddings table: the paddings of each side window.
---@return number?: the left window id.
---@return number?: the right window id.
---@private
function W.resizeOrCloseSideBuffers(scope, wins, paddings)
    for _, side in pairs(Co.SIDES) do
        if wins.main[side] ~= nil then
            local padding = 0

            if paddings ~= nil then
                padding = paddings[side].padding
            else
                padding = W.getPadding(side, wins)
            end

            if padding > _G.NoNeckPain.config.minSideBufferWidth then
                resize(wins.main[side], padding, side)
            else
                W.close(scope, wins.main[side], side)
                wins.main[side] = nil
            end
        end
    end

    return wins.main.left, wins.main.right
end

---Determine the "padding" (width) of the buffer based on the `_G.NoNeckPain.config.width` and the width of the screen.
---
---@param side "left"|"right": the side of the window.
---@param wins table: the state wins for the current tab.
---@return number: the width of the side window.
---@private
function W.getPadding(side, wins)
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

    -- we need to see if there's enough space left to have side buffers
    local nbVSplits = Sp.nbVSplits(wins.splits)
    local occupied = _G.NoNeckPain.config.width * nbVSplits

    -- if there's no space left according to the config width,
    -- then we don't have to create side buffers.
    if occupied >= width then
        D.log(side, "%d vsplits - no space left to create side buffers", nbVSplits)

        return 0
    end

    D.log(side, "%d currently occupied - checking for external trees", occupied)

    -- now we need to determine how much we should substract from the remaining padding
    -- if there's side trees open.
    local paddingToSubstract = 0

    for name, tree in pairs(wins.external.trees) do
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

    return math.floor((width - paddingToSubstract - (_G.NoNeckPain.config.width * nbVSplits)) / 2)
end

---Merges the state windows in a single table containing all of their IDs.
---
---@param main table: the `main` window state.
---@param splits table: the `splits` window state.
---@param trees table?: the `external.trees` window state.
---@return table: the state window IDs.
---@private
function W.mergeState(main, splits, trees)
    local wins = {}

    for _, side in pairs(main) do
        table.insert(wins, side)
    end

    if splits ~= nil then
        for _, split in pairs(splits) do
            table.insert(wins, split.id)
        end
    end

    if trees ~= nil then
        for _, tree in pairs(trees) do
            table.insert(wins, tree.id)
        end
    end

    return wins
end

---Determine if the tab wins are still active and valid.
---
---@param tab table: the table where the tab information are stored.
---@param checkSplits boolean: whether splits state should be considered or not.
---@return boolean: whether all windows are active and valid or not.
---@private
function W.stateWinsActive(tab, checkSplits)
    local wins = vim.api.nvim_tabpage_list_wins(tab.id)
    local swins = tab.wins.main

    if checkSplits and tab.wins.splits ~= nil then
        swins = W.mergeState(tab.wins.main, tab.wins.splits, nil)
    end

    for _, swin in pairs(swins) do
        if not vim.tbl_contains(wins, swin) then
            return false
        end
    end

    return true
end

return W
