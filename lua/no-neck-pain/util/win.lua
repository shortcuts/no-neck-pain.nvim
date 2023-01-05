local C = require("no-neck-pain.util.color")
local D = require("no-neck-pain.util.debug")
local M = require("no-neck-pain.util.map")
local W = {}
local SIDES = { "left", "right" }

-- Creates side buffers with the correct padding. Side buffers are not created if there's not enough space.
--
-- @param wins list: the current wins state.
function W.createSideBuffers(wins)
    -- cmd: command to create the side buffer
    -- id: the id stored in the internal state
    local config = {
        left = {
            cmd = "topleft vnew",
            id = wins.main.left,
        },
        right = {
            cmd = "botright vnew",
            id = wins.main.right,
        },
    }

    for _, side in pairs(SIDES) do
        if _G.NoNeckPain.config.buffers[side].enabled and config[side].id == nil then
            local padding = W.getPadding(side, wins)

            if padding ~= 0 then
                vim.cmd(config[side].cmd)

                local id = vim.api.nvim_get_current_win()

                vim.api.nvim_win_set_width(0, padding)

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

                config[side].id = id
            end
        end
    end

    return config.left.id, config.right.id
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
function W.listWinsExcept(list)
    local wins = vim.api.nvim_list_wins()
    local validWins = {}
    local size = 0

    for _, win in pairs(wins) do
        if not M.contains(list, win) and not W.isRelativeWindow(win) then
            table.insert(validWins, win)
            size = size + 1
        end
    end

    return validWins, size
end

-- returns the available buffers and their total number, without the `list` ones.
function W.listBufsExcept(list)
    local bufs = vim.api.nvim_list_bufs()
    local validBufs = {}
    local size = 0

    for _, buf in pairs(bufs) do
        if not M.contains(list, buf) then
            table.insert(validBufs, buf)
            size = size + 1
        end
    end

    return validBufs, size
end

-- gets the bufs of the given `wins` list, if win are valid.
function W.winsGetBufs(wins)
    local bufs = {}

    for _, win in pairs(wins) do
        if win ~= nil and vim.api.nvim_win_is_valid(win) then
            table.insert(bufs, vim.api.nvim_win_get_buf(win))
        end
    end

    return bufs
end

-- Closes side buffers, quits Neovim if there's no other window left.
function W.closeSideBuffers(scope, wins)
    for _, side in pairs(SIDES) do
        if wins[side] ~= nil then
            local _, wsize = W.listWinsExcept({ wins[side] })

            -- we don't have any window left if we close this one
            if wsize == 0 then
                -- either triggered by a :wq or quit event, we can just quit
                if scope == "QuitPre" then
                    return vim.cmd("quit!")
                end

                -- mostly triggered by :bd or similar
                -- we will create a new window and close the other
                vim.cmd("new")
            end

            -- when we have more than 1 window left, we can just close it
            if vim.api.nvim_win_is_valid(wins[side]) then
                D.log(scope, "closing %s window", side)

                vim.api.nvim_win_close(wins[side], false)
            end
        end
    end

    return nil, nil
end

-- Resizes side buffers, considering the existing trees.
function W.resizeOrCloseSideBuffers(scope, wins)
    for _, side in pairs(SIDES) do
        if wins.main[side] ~= nil then
            local padding = W.getPadding(side, wins)

            D.log(scope, "[%s] padding %d", side, padding)

            if vim.api.nvim_win_is_valid(wins.main[side]) then
                if padding > 0 then
                    vim.api.nvim_win_set_width(wins.main[side], padding)
                else
                    vim.api.nvim_win_close(wins.main[side], false)
                    wins.main[side] = nil
                end
            end
        end
    end

    return wins.main.left, wins.main.right
end

function W.getSideTrees()
    local wins = vim.api.nvim_list_wins()
    local trees = {
        NvimTree = {
            id = nil,
            width = 0,
        },
        undotree = {
            id = nil,
            width = 0,
        },
    }

    for _, win in pairs(wins) do
        local fileType = vim.api.nvim_buf_get_option(vim.api.nvim_win_get_buf(win), "filetype")

        if W.isSideTree(fileType) then
            trees[fileType] = {
                id = win,
                width = vim.api.nvim_win_get_width(win) * 2,
            }
        end
    end

    return trees
end

function W.isSideTree(fileType)
    return fileType == "NvimTree" or fileType == "undotree"
end

-- Determine the padding of the buffer based on the `_G.NoNeckPain.config.width` and the width of the screen.
--
-- @param side string: the side of the buffer, left or right.
-- @param wins list: the current wins state.
function W.getPadding(side, wins)
    local uis = vim.api.nvim_list_uis()

    if uis[1] == nil then
        return D.log(side, "attempted to get the padding of a non-existing UI.")
    end

    local width = uis[1].width

    -- if the available screen size is lowe than the config width,
    -- we don't have to create side buffers.
    if _G.NoNeckPain.config.width >= width then
        D.log(side, "ui - no space left to create side buffers")

        return 0
    end

    -- we need to see if there's enough space left to have side buffers
    local nbVSplits = 1

    if wins.splits ~= nil then
        D.tprint(wins.splits)
        for _, split in pairs(wins.splits) do
            if split.vertical then
                nbVSplits = nbVSplits + 1
            end
        end
    end

    local occupied = _G.NoNeckPain.config.width * nbVSplits

    -- if there's no space left according to the config width,
    -- then we don't have to create side buffers.
    if occupied >= width then
        D.log(side, "vsplit - no space left to create side buffers")

        return 0
    end

    D.log(side, "%d occupied - checking trees", occupied)

    -- now we need to determine how much we should substract from the remaining padding
    -- if there's side trees open.
    local paddingToSubstract = 0

    for name, tree in pairs(wins.external.trees) do
        if side == _G.NoNeckPain.config.integrations[name].position and tree.id ~= nil then
            paddingToSubstract = paddingToSubstract + tree.width
        end
    end

    return math.floor((width - paddingToSubstract - (_G.NoNeckPain.config.width * nbVSplits)) / 2)
end

return W
