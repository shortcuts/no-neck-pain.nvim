local C = require("no-neck-pain.util.color")
local D = require("no-neck-pain.util.debug")
local M = require("no-neck-pain.util.map")
local W = require("no-neck-pain.util.win")

-- internal methods
local NoNeckPain = {}

-- state
local S = {
    enabled = false,
    augroup = nil,
    win = {
        main = {
            curr = nil,
            left = nil,
            right = nil,
            split = nil,
        },
        external = {
            tree = {
                id = nil,
                width = 0,
            },
        },
    },
}

--- Toggle the plugin by calling the `enable`/`disable` methods respectively.
function NoNeckPain.toggle()
    if S.enabled then
        NoNeckPain.disable()

        return false
    end

    NoNeckPain.enable()

    return true
end

-- Determine the "padding" (width) of the buffer based on the `_G.NoNeckPain.config.width` parameter.
--
-- @param paddingToSubstract number: a value to be substracted to the `width` of the screen
local function getPadding(paddingToSubstract)
    paddingToSubstract = paddingToSubstract or 0
    local width = vim.api.nvim_list_uis()[1].width

    if _G.NoNeckPain.config.width >= width then
        return 1
    end

    return math.floor((width - paddingToSubstract - _G.NoNeckPain.config.width) / 2)
end

-- Creates a buffer for the given "padding" (width), at the given `moveTo` direction.
-- Options from `_G.NoNeckPain.config.buffer.options` are applied to the created buffer.
--
--@param name string: the name of the buffer, `no-neck-pain-` will be prepended.
--@param cmd string: the command to execute when creating the buffer
--@param padding number: the "padding" (width) of the buffer
--@param moveTo string: the command to execute to place the buffer at the correct spot.
local function createBuf(name, cmd, padding, moveTo)
    if vim.api.nvim_list_uis()[1].width < _G.NoNeckPain.config.width then
        return D.print("createBuf: not enough space to create side buffer " .. name)
    end

    vim.cmd(cmd)

    local id = vim.api.nvim_get_current_win()

    vim.api.nvim_win_set_width(0, padding)

    if _G.NoNeckPain.config.buffers.showName then
        vim.api.nvim_buf_set_name(0, "no-neck-pain-" .. name)
    end

    for scope, _ in pairs(_G.NoNeckPain.config.buffers.options) do
        for key, value in pairs(_G.NoNeckPain.config.buffers.options[scope]) do
            vim[scope][key] = value
        end
    end

    vim.cmd(moveTo)

    if _G.NoNeckPain.config.buffers.background.colorCode ~= nil then
        D.print("CreateWin: setting `colorCode` for buffer " .. id)

        C.init(id, _G.NoNeckPain.config.buffers.background.colorCode)
    end

    return id
end

-- Creates NNP buffers.
--
--@param action string: when called with `init`, creates NNP buffers. Resizes side buffers on any other cases.
local function createWin(action)
    D.print("CreateWin: ", action)

    local padding = getPadding()

    if action == "init" then
        local splitbelow, splitright = vim.o.splitbelow, vim.o.splitright
        vim.o.splitbelow, vim.o.splitright = true, true

        S.win.main.curr = vim.api.nvim_get_current_win()

        if _G.NoNeckPain.config.buffers.left then
            S.win.main.left = createBuf("left", "leftabove vnew", padding, "wincmd l")
        end

        if _G.NoNeckPain.config.buffers.right then
            S.win.main.right = createBuf("right", "vnew", padding, "wincmd h")
        end

        vim.o.splitbelow, vim.o.splitright = splitbelow, splitright

        return
    end

    W.resize("createWin", S.win.main.left, getPadding(S.win.external.tree.width * 2))
    W.resize("createWin", S.win.main.right, getPadding())
end

--- Initializes NNP and sets event listeners.
function NoNeckPain.enable()
    if S.enabled then
        return D.print("Enable: tried to enable already enabled NNP")
    end

    D.print("enabling NNP")

    S.augroup = vim.api.nvim_create_augroup("NoNeckPain", {
        clear = true,
    })

    createWin("init")

    vim.api.nvim_create_autocmd({ "VimResized" }, {
        callback = function()
            vim.schedule(function()
                if not S.enabled then
                    return D.print("VimResized: event received but NNP is disabled")
                end

                if
                    S.win.main.split ~= nil
                    -- we don't want close action on float window to impact NNP
                    or W.isRelativeWindow("VimEnter")
                then
                    return D.print(
                        "VimResized: already in split view or float window detected, nothing more to do"
                    )
                end

                local width = vim.api.nvim_list_uis()[1].width

                if width > _G.NoNeckPain.config.width then
                    D.print("VimResized: window's width is above the `width` option")

                    if S.win.main.left == nil and S.win.main.right == nil then
                        D.print("VimResized: no side buffer found, creating...")

                        return createWin("init")
                    end

                    D.print("VimResized: buffers are here, resizing...")

                    return createWin("VimResized")
                end

                D.print(
                    "VimResized: window's width is below the `width` option, closing opened buffers..."
                )

                local ok = W.close("VimResized", S.win.main.left)
                if ok then
                    S.win.main.left = nil
                end

                ok = W.close("VimResized", S.win.main.right)
                if ok then
                    S.win.main.right = nil
                end
            end)
        end,
        group = "NoNeckPain",
        desc = "Resizes side windows after shell has been resized",
    })

    vim.api.nvim_create_autocmd({ "WinEnter" }, {
        callback = function()
            vim.schedule(function()
                if not S.enabled then
                    return D.print("WinEnter: event received but NNP is disabled")
                end

                if
                    S.win.main.split ~= nil
                    -- we don't want close action on float window to impact NNP
                    or W.isRelativeWindow("WinEnter")
                then
                    return D.print(
                        "WinEnter: already in split view or float window detected, nothing more to do"
                    )
                end

                local buffers, total = W.bufferListWithoutNNP("WinEnter", S.win.main)
                local focusedWin = vim.api.nvim_get_current_win()

                if total == 0 or not M.contains(buffers, focusedWin) then
                    return D.print("WinEnter: no valid buffers to handle, no split to handle")
                end

                D.print("WinEnter: found ", total, " remaining valid buffers")

                -- below we will check for plugins that opens windows as splits (e.g. tree)
                -- and early return while storing its NoNeckPain.
                if vim.api.nvim_buf_get_option(0, "filetype") == "NvimTree" then
                    S.win.external.tree.id = focusedWin

                    return D.print("WinEnter: encoutered an NvimTree split")
                end

                -- start by saving the split, because steps below will trigger `WinClosed`
                S.win.main.split = focusedWin

                if W.close("WinEnter", S.win.main.left) then
                    S.win.main.left = nil
                end

                if W.close("WinEnter", S.win.main.right) then
                    S.win.main.right = nil
                end
            end)
        end,
        group = "NoNeckPain",
        desc = "WinEnter covers the split/vsplit management",
    })

    vim.api.nvim_create_autocmd({ "WinClosed", "BufDelete" }, {
        callback = function()
            vim.schedule(function()
                if not S.enabled then
                    return D.print("WinClose, BufDelete: event received but NNP is disabled")
                end

                -- we don't want close action on float window to impact NNP
                if W.isRelativeWindow("WinClosed, BufDelete") then
                    return
                end

                local buffers = vim.api.nvim_list_wins()

                -- if we are not in split view, we check if we killed one of the main buffers (curr, left, right) to disable NNP
                -- TODO: make killed side buffer decision configurable, we can re-create it
                if S.win.main.split == nil and not M.every(buffers, S.win.main) then
                    D.print(
                        "WinClosed, BufDelete: one of the NNP main buffers have been closed, disabling..."
                    )

                    return NoNeckPain.disable()
                end

                local _, total = W.bufferListWithoutNNP("WinClosed, BufDelete", {
                    S.win.main.curr,
                    S.win.main.left,
                    S.win.main.right,
                    S.win.external.tree.id,
                })

                if
                    _G.NoNeckPain.config.disableOnLastBuffer
                    and total == 0
                    and vim.api.nvim_buf_get_option(0, "buftype") == ""
                    and vim.api.nvim_buf_get_option(0, "filetype") == ""
                    and vim.api.nvim_buf_get_option(0, "bufhidden") == "wipe"
                then
                    D.print("WinClosed, BufDelete: found last `wipe` buffer in list, disabling...")

                    return NoNeckPain.disable()
                elseif M.tsize(buffers) > 1 then
                    return D.print(
                        "WinClosed, BufDelete: more than one buffer left, no killed split to handle"
                    )
                end

                S.win.main.curr = buffers[0]
                S.win.main.split = nil

                -- focus curr
                vim.fn.win_gotoid(S.win.main.curr)

                -- recreate everything
                createWin("init")
            end)
        end,
        group = "NoNeckPain",
        desc = "Aims at restoring NNP enable state after closing a split/vsplit buffer or a main buffer",
    })

    vim.api.nvim_create_autocmd({ "WinEnter", "WinClosed" }, {
        callback = function()
            vim.schedule(function()
                if not S.enabled then
                    return D.print("WinEnter, WinClosed: event received but NNP is disabled")
                end

                if S.win.main.split ~= nil or W.isRelativeWindow("WinEnter") then
                    return D.print("WinEnter: stop because of split view or float window")
                end

                local focusedWin = vim.api.nvim_get_current_win()

                -- skip if the newly focused window is a side buffer
                if focusedWin == S.win.main.left or focusedWin == S.win.main.right then
                    return D.print("WinEnter, WinClosed: focus on side buffer, skipped resize")
                end

                -- when opening a new buffer as current, store its padding and resize everything (e.g. side tree)
                if focusedWin ~= S.win.main.curr then
                    S.win.external.tree.width = vim.api.nvim_win_get_width(focusedWin)

                    D.print(
                        "WinEnter, WinClosed: new current buffer with width:",
                        S.win.external.tree.width
                    )
                end

                if not M.contains(vim.api.nvim_list_wins(), S.win.external.tree.id) then
                    S.win.external.tree = {
                        id = nil,
                        width = 0,
                    }
                end

                -- TODO: Make this configurable, here we assume the tree is on the left of the screen.
                W.resize(
                    "WinEnter, WinClosed",
                    S.win.main.left,
                    getPadding(S.win.external.tree.width * 2)
                )
                W.resize("WinEnter, WinClosed", S.win.main.right, getPadding())
            end)
        end,
        group = "NoNeckPain",
        desc = "Resize to apply on WinEnter/Closed",
    })

    S.enabled = true
end

--- Disable NNP and reset windows, leaving the `curr` focused window as focused.
function NoNeckPain.disable()
    if not S.enabled then
        return D.print("Disable: tried to disable non-enabled NNP")
    end

    D.print("disabling NNP")

    S.enabled = false
    vim.api.nvim_del_augroup_by_id(S.augroup)

    W.close("Disable left", S.win.main.left)
    W.close("Disable right", S.win.main.right)

    -- shutdowns gracefully by focusing the stored `curr` buffer, if possible
    if
        S.win.main.curr ~= nil
        and vim.api.nvim_win_is_valid(S.win.main.curr)
        and S.win.main.curr ~= vim.api.nvim_get_current_win()
    then
        vim.fn.win_gotoid(S.win.main.curr)
    end

    if _G.NoNeckPain.config.killAllBuffersOnDisable then
        vim.cmd("only")
    end

    S.augroup = nil
    S.win = {
        main = {
            curr = nil,
            left = nil,
            right = nil,
            split = nil,
        },
        external = {
            tree = {
                id = nil,
                width = 0,
            },
        },
    }
end

return { NoNeckPain, S }
