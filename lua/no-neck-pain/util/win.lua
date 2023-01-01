local C = require("no-neck-pain.util.color")
local D = require("no-neck-pain.util.debug")
local M = require("no-neck-pain.util.map")
local W = {}
local SIDES = { "left", "right" }

-- Creates side buffers with the correct padding.
--
--@param wins list: the current wins state, useful to get `external` trees to consider the padding, and to know if the buffer already exists.
function W.createSideBuffers(wins)
    -- cmd: command to create the side buffer
    -- moveTo: the destination of the side buffer
    -- id: the id stored in the internal state
    local config = {
        left = {
            cmd = "leftabove vnew",
            moveTo = "wincmd l",
            id = wins.main.left,
        },
        right = {
            cmd = "vnew",
            moveTo = "wincmd h",
            id = wins.main.right,
        },
    }

    for _, side in pairs(SIDES) do
        if _G.NoNeckPain.config.buffers[side].enabled and wins.main[side] == nil then
            local padding = W.getPadding(side, wins.external.trees)

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

            vim.cmd(config[side].moveTo)

            C.init(
                id,
                side,
                _G.NoNeckPain.config.buffers[side].backgroundColor,
                _G.NoNeckPain.config.buffers[side].textColor
            )

            config[side].id = id
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
function W.resizeSideBuffers(scope, wins)
    D.log(scope, "resizing side buffers")

    for _, side in pairs(SIDES) do
        if wins.main[side] ~= nil then
            local padding = W.getPadding(side, wins.external.trees)

            if vim.api.nvim_win_is_valid(wins.main[side]) then
                vim.api.nvim_win_set_width(wins.main[side], padding)
            end
        end
    end
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
        if fileType == "NvimTree" or fileType == "undotree" then
            trees[fileType] = {
                id = win,
                width = vim.api.nvim_win_get_width(win) * 2,
            }
        end
    end

    return trees
end

-- Determine the "padding" (width) of the buffer based on the `_G.NoNeckPain.config.width` and the width of the screen.
--
-- @param trees list: the external trees supported with their `width` and `id`.
function W.getPadding(side, trees)
    local wins = vim.api.nvim_list_uis()

    if wins[1] == nil then
        return D.log("W.getPadding", "attempted to get the padding of a non-existing window.")
    end

    local width = wins[1].width

    if _G.NoNeckPain.config.width >= width then
        return 1
    end

    local paddingToSubstract = 0

    for name, tree in pairs(trees) do
        if side == _G.NoNeckPain.config.integrations[name].position and tree.id ~= nil then
            paddingToSubstract = paddingToSubstract + tree.width
        end
    end

    return math.floor((width - paddingToSubstract - _G.NoNeckPain.config.width) / 2)
end

return W
