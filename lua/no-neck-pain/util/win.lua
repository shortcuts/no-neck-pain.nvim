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
    -- cmd: command to create the side buffer
    -- moveTo: the destination of the side buffer
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

    local enabledExternals = {
        NvimTree = false,
    }

    -- we close the side tree if it's already opened to prevent unwanted layout issue.
    if
        _G.NoNeckPain.config.integrations.NvimTree.close
        and wins.external.trees.NvimTree.id ~= nil
    then
        enabledExternals.NvimTree = true
        vim.cmd("NvimTreeClose")
    end

    for _, side in pairs(W.SIDES) do
        if _G.NoNeckPain.config.buffers[side].enabled then
            local padding = W.getPadding(side, wins.external.trees)

            if padding > 0 then
                if wins.main[side] ~= nil then
                    resize(wins.main[side], padding, side)
                else
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

            -- if we've closed the user side tree but they still want it to be opened, we need to reopen it.
            if
                side == _G.NoNeckPain.config.integrations.NvimTree.position
                and enabledExternals.NvimTree
                and _G.NoNeckPain.config.integrations.NvimTree.reopen == true
            then
                vim.cmd("NvimTreeOpen")
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

-- Closes side buffers, quits Neovim if there's no other window left.
function W.closeSideBuffers(scope, wins)
    for _, side in pairs(W.SIDES) do
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
            local padding = W.getPadding(side, wins.external.trees)

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
function W.getPadding(side, trees)
    local uis = vim.api.nvim_list_uis()

    if uis[1] == nil then
        return error("W.getPadding - attempted to get the padding of a non-existing UI.")
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

    local paddingToSubstract = 0

    for name, tree in pairs(trees) do
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

    local padding = math.floor((width - paddingToSubstract - _G.NoNeckPain.config.width) / 2)

    D.log("W.getPadding", "resizing %s with width %d", side, padding)

    return padding
end

return W
