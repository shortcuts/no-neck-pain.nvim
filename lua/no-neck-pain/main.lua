local options = require("no-neck-pain.config").options
local C = require("no-neck-pain.util.color")
local D = require("no-neck-pain.util.debug")
local M = require("no-neck-pain.util.map")
local W = require("no-neck-pain.util.win")
local SIDES = { "left", "right" }

local NoNeckPain = {
    state = {
        enabled = false,
        augroup = nil,
        win = {
            curr = nil,
            left = nil,
            right = nil,
            split = nil,
        },
    },
}

--- Toggle the plugin by calling the `enable`/`disable` methods respectively.
function NoNeckPain.toggle()
    if NoNeckPain.state.enabled then
        return NoNeckPain.disable()
    end

    NoNeckPain.enable()
end

-- Determine the "padding" (width) of the buffer based on the `options.width` parameter.
local function getPadding()
    local width = vim.api.nvim_list_uis()[1].width

    if options.width >= width then
        return 1
    end

    return math.floor((width - options.width) / 2)
end

-- Creates a buffer for the given "padding" (width), at the given `moveTo` direction.
-- Options from `options.buffer.options` are applied to the created buffer.
--
--@param name string: the name of the buffer, `no-neck-pain-` will be prepended.
--@param cmd string: the command to execute when creating the buffer
--@param padding number: the "padding" (width) of the buffer
--@param moveTo string: the command to execute to place the buffer at the correct spot.
local function createBuf(name, cmd, padding, moveTo)
    vim.cmd(cmd)

    local id = vim.api.nvim_get_current_win()

    vim.api.nvim_win_set_width(0, padding)

    if options.buffers.showName then
        vim.api.nvim_buf_set_name(0, "no-neck-pain-" .. name)
    end

    for scope, _ in pairs(options.buffers.options) do
        for key, value in pairs(options.buffers.options[scope]) do
            vim[scope][key] = value
        end
    end

    vim.cmd(moveTo)

    if options.buffers.background.colorCode ~= nil then
        D.print("CreateWin: setting `colorCode` for buffer" .. id)

        C.init(id, options.buffers.background.colorCode)
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

        NoNeckPain.state.win = {
            curr = vim.api.nvim_get_current_win(),
        }

        if options.buffers.left then
            NoNeckPain.state.win.left = createBuf("left", "leftabove vnew", padding, "wincmd l")
        end

        if options.buffers.right then
            NoNeckPain.state.win.right = createBuf("right", "vnew", padding, "wincmd h")
        end

        vim.o.splitbelow, vim.o.splitright = splitbelow, splitright

        return
    end

    -- resize
    for _, side in ipairs(SIDES) do
        if
            NoNeckPain.state.win[side] ~= nil
            and vim.api.nvim_win_is_valid(NoNeckPain.state.win[side])
        then
            vim.api.nvim_win_set_width(NoNeckPain.state.win[side], padding)
        end
    end
end

--- Initializes NNP and sets event listeners.
function NoNeckPain.enable()
    if NoNeckPain.state.enabled then
        return D.print("Enable: tried to enable already enabled NNP")
    end

    D.print("enabling NNP")

    NoNeckPain.state.augroup = vim.api.nvim_create_augroup("NoNeckPain", {
        clear = true,
    })

    createWin("init")

    vim.api.nvim_create_autocmd({ "VimResized" }, {
        callback = function()
            createWin("VimResized")
        end,
        group = "NoNeckPain",
        desc = "Resizes side windows after shell has been resized",
    })

    vim.api.nvim_create_autocmd({ "WinEnter" }, {
        callback = function()
            vim.schedule(function()
                if
                    NoNeckPain.state.win.split ~= nil
                    -- we don't want close action on float window to impact NNP
                    or W.isRelativeWindow("WinEnter")
                then
                    return D.print(
                        "WinEnter: already in split view or float window detected, nothing more to do"
                    )
                end

                local buffers, total = W.bufferListWithoutNNP("WinEnter", NoNeckPain.state.win)
                local focusedWin = vim.api.nvim_get_current_win()

                if total == 0 or not M.contains(buffers, focusedWin) then
                    return D.print("WinEnter: no valid buffers to handle, no split to handle")
                end

                D.print("WinEnter: found ", total, " remaining valid buffers")

                -- start by saving the split, because steps below will trigger `WinClosed`
                NoNeckPain.state.win.split = focusedWin

                local ok = W.close("WinEnter", NoNeckPain.state.win.left)
                if ok then
                    NoNeckPain.state.win.left = nil
                end

                ok = W.close("WinEnter", NoNeckPain.state.win.right)
                if ok then
                    NoNeckPain.state.win.right = nil
                end
            end)
        end,
        group = "NoNeckPain",
        desc = "WinEnter covers the split/vsplit management",
    })

    vim.api.nvim_create_autocmd({ "WinClosed", "BufDelete" }, {
        callback = function()
            vim.schedule(function()
                -- we don't want close action on float window to impact NNP
                if W.isRelativeWindow("WinClosed, BufDelete") then
                    return
                end

                local buffers = vim.api.nvim_list_wins()

                -- if we are not in split view, we check if we killed one of the main buffers (curr, left, right) to disable NNP
                -- TODO: make killed side buffer decision configurable, we can re-create it
                if
                    NoNeckPain.state.win.split == nil
                    and not M.every(buffers, NoNeckPain.state.win)
                then
                    D.print(
                        "WinClosed, BufDelete: one of the NNP main buffers have been closed, disabling..."
                    )

                    return NoNeckPain.disable()
                end

                local _, total =
                    W.bufferListWithoutNNP("WinClosed, BufDelete", NoNeckPain.state.win)

                if
                    options.disableOnLastBuffer
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

                NoNeckPain.state.win.curr = buffers[0]
                NoNeckPain.state.win.split = nil

                -- focus curr
                vim.fn.win_gotoid(NoNeckPain.state.win.curr)

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
                if NoNeckPain.state.win.split ~= nil or W.isRelativeWindow("WinEnter") then
                    return D.print("WinEnter: stop because of split view or float window")
                end

                local focusedWin = vim.api.nvim_get_current_win()

                -- skip if the newly focused window is a side buffer
                if
                    focusedWin == NoNeckPain.state.win.left
                    or focusedWin == NoNeckPain.state.win.right
                then
                    return D.print("WinEnter, WinClosed: focus on side buffer, skipped resize")
                end

                local padding = 0

                -- when opening a new buffer as current, store its padding and resize everything (e.g. side tree)
                if focusedWin ~= NoNeckPain.state.win.curr then
                    D.print(
                        "WinEnter, WinClosed: new current buffer found",
                        focusedWin,
                        "resizing:",
                        padding
                    )

                    padding = vim.api.nvim_win_get_width(focusedWin)
                end

                local width = vim.api.nvim_list_uis()[1].width
                local totalSideSizes = (width - padding) - options.width

                D.print("WinEnter, WinClosed: resizing side buffers")
                for _, side in ipairs(SIDES) do
                    if NoNeckPain.state.win[side] ~= nil then
                        if vim.api.nvim_win_is_valid(NoNeckPain.state.win[side]) then
                            vim.api.nvim_win_set_width(
                                NoNeckPain.state.win[side],
                                math.floor(totalSideSizes / 2)
                            )
                        end
                    end
                end
            end)
        end,
        group = "NoNeckPain",
        desc = "Resize to apply on WinEnter/Closed",
    })

    NoNeckPain.state.enabled = true
end

--- Disable NNP and reset windows, leaving the `curr` focused window as focused.
function NoNeckPain.disable()
    if not NoNeckPain.state.enabled then
        return D.print("Disable: tried to disable non-enabled NNP")
    end

    D.print("disabling NNP")

    D.print(NoNeckPain.state.augroup)

    vim.api.nvim_del_augroup_by_id(NoNeckPain.state.augroup)

    if not options.killAllBuffersOnDisable then
        W.close("Disable left", NoNeckPain.state.win.left)
        W.close("Disable right", NoNeckPain.state.win.right)
    end

    -- shutdowns gracefully by focusing the stored `curr` buffer, if possible
    if
        NoNeckPain.state.win.curr ~= nil
        and vim.api.nvim_win_is_valid(NoNeckPain.state.win.curr)
        and NoNeckPain.state.win.curr ~= vim.api.nvim_get_current_win()
    then
        vim.fn.win_gotoid(NoNeckPain.state.win.curr)
    end

    if options.killAllBuffersOnDisable then
        vim.cmd("only")
    end

    NoNeckPain.state = {
        enabled = false,
        win = {
            curr = nil,
            left = nil,
            right = nil,
            split = nil,
        },
    }
end

return NoNeckPain
