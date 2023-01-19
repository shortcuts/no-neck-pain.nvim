local Sp = require("no-neck-pain.util.split")
local C = require("no-neck-pain.util.color")
local D = require("no-neck-pain.util.debug")
local M = require("no-neck-pain.util.map")

local W = {}

W.SIDES = { "left", "right" }

-- Resizes a window if it's valid.
local function resize(id, width, side)
    D.log(side, "resizing with padding %d", width)

    if vim.api.nvim_win_is_valid(id) then
        vim.api.nvim_win_set_width(id, width)
    end
end

-- Closes a window if it's valid.
local function close(scope, id, side)
    D.log(scope, "closing %s window", side)

    if vim.api.nvim_win_is_valid(id) then
        vim.api.nvim_win_close(id, false)
    end
end

-- Creates side buffers with the correct padding.
-- A side buffer is not created if there's not enough space.
-- If it already exists, we resize it.
--
--@param wins list: the current wins state, useful to get `external` trees to consider the padding, and to know if the buffer already exists.
function W.createSideBuffers(wins)
    local cmd = {
        left = { cmd = "topleft vnew", padding = 0 },
        right = { cmd = "botright vnew", padding = 0 },
    }

    local integrations = {
        NvimTree = false,
    }

    -- we close the side tree if it's already opened to prevent unwanted layout issue.
    if wins.external.trees.NvimTree.id ~= nil then
        integrations.NvimTree = true
        vim.cmd("NvimTreeClose")
    end

    for _, side in pairs(W.SIDES) do
        if _G.NoNeckPain.config.buffers[side].enabled then
            cmd[side].padding = W.getPadding(side, wins)

            if cmd[side].padding > 0 and wins.main[side] == nil then
                vim.cmd(cmd[side].cmd)

                local id = vim.api.nvim_get_current_win()

                if _G.NoNeckPain.config.buffers.setNames then
                    vim.api.nvim_buf_set_name(0, "no-neck-pain-" .. side)
                end

                for opt, val in pairs(_G.NoNeckPain.config.buffers[side].bo) do
                    vim.api.nvim_buf_set_option(0, opt, val)
                end

                for opt, val in pairs(_G.NoNeckPain.config.buffers[side].wo) do
                    vim.api.nvim_win_set_option(id, opt, val)
                end

                C.init(
                    id,
                    side,
                    _G.NoNeckPain.config.buffers[side].backgroundColor,
                    _G.NoNeckPain.config.buffers[side].textColor
                )

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

                wins.main[side] = id
            end
        end
    end

    -- if we've closed the user side tree but they still want it to be opened.
    if integrations.NvimTree then
        if _G.NoNeckPain.config.integrations.NvimTree.reopen == true then
            vim.cmd("NvimTreeOpen")
        else
            wins.external.trees.NvimTree = {
                id = nil,
                width = 0,
            }
        end
    end

    return W.resizeOrCloseSideBuffers("W.createSideBuffers", wins)
end

-- returns true if the index 0 window or the current window is relative.
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

-- returns the available wins and their total number, without the `list` ones.
function W.winsExceptState(state, withTrees)
    local wins = vim.api.nvim_list_wins()
    local mergedWins =
        W.mergeState(state.main, state.splits, withTrees and state.external.trees or nil)

    local validWins = {}
    local size = 0

    for _, win in pairs(wins) do
        if not M.contains(mergedWins, win) and not W.isRelativeWindow(win) then
            table.insert(validWins, win)
            size = size + 1
        end
    end

    return validWins, size
end

-- Closes side buffers, quits Neovim if there's no other window left.
function W.closeSideBuffers(scope, wins)
    for _, side in pairs(W.SIDES) do
        if wins[side] ~= nil then
            local activeWins = vim.api.nvim_list_wins()
            local haveOtherWins = false

            for _, activeWin in pairs(activeWins) do
                if wins[side] ~= activeWin and not W.isRelativeWindow(activeWin) then
                    haveOtherWins = true
                end
            end

            -- we don't have any window left if we close this one
            if not haveOtherWins then
                -- either triggered by a :wq or quit event, we can just quit
                if scope == "QuitPre" then
                    return vim.cmd("quit!")
                end

                -- mostly triggered by :bd or similar
                -- we will create a new window and close the other
                vim.cmd("new")
            end

            -- when we have more than 1 window left, we can just close it
            close(scope, wins[side], side)
        end
    end

    return nil, nil
end

-- Resizes side buffers, considering the existing trees.
-- Closes them if there's not enough space left.
function W.resizeOrCloseSideBuffers(scope, wins)
    for _, side in pairs(W.SIDES) do
        if wins.main[side] ~= nil then
            local padding = W.getPadding(side, wins)

            if padding > 0 then
                resize(wins.main[side], padding, side)
            else
                close(scope, wins.main[side], side)
                wins.main[side] = nil
            end
        end
    end

    return wins.main.left, wins.main.right
end

-- Determine the "padding" (width) of the buffer based on the `_G.NoNeckPain.config.width` and the width of the screen.
--
-- @param side string: the side we are creating.
-- @param trees list: the external trees supported with their `width` and `id`.
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
        D.log(
            "W.getPadding",
            "[%s] - ui %s | cfg %s - no space left to create side buffers",
            side,
            width,
            _G.NoNeckPain.config.width
        )

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

    D.log(side, "%d occupied - checking trees", occupied)

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

-- mergeState returns all of the window ids of the state.
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

-- returns `true` if all the state wins are still active in the wins list.
--
-- @param checkSplits bool: checks for splits wins too when `true`.
function W.stateWinsActive(state, checkSplits)
    local wins = vim.api.nvim_list_wins()
    local swins = state.main

    if checkSplits and state.splits ~= nil then
        swins = W.mergeState(state.main, state.splits, nil)
    end

    for _, swin in pairs(swins) do
        if not M.contains(wins, swin) then
            return false
        end
    end

    return true
end

return W
