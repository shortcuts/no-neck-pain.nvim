local options = require("no-neck-pain.config").options
local util = require("no-neck-pain.util")
local SIDES = { "left", "right" }

local NoNeckPain = {
    state = {
        enabled = false,
        win = {
            curr = nil,
            left = nil,
            right = nil,
            split = nil,
        },
    },
}

vim.api.nvim_create_augroup("NoNeckPain", {
    clear = true,
})

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
--@param cmd string: the command to execute when creating the buffer
--@param padding number: the "padding" (width) of the buffer
--@param moveTo string: the command to execute to place the buffer at the correct spot.
local function createBuf(cmd, padding, moveTo)
    vim.cmd(cmd)

    local id = vim.api.nvim_get_current_win()

    vim.api.nvim_win_set_width(0, padding)

    for scope, _ in pairs(options.buffers.options) do
        for name, value in pairs(options.buffers.options[scope]) do
            vim[scope][name] = value
        end
    end

    vim.cmd(moveTo)

    return id
end

-- Creates NNP buffers.
--
--@param action string: when called with `init`, creates NNP buffers. Resizes side buffers on any other cases.
local function createWin(action)
    util.print("CreateWin: ", action)

    local padding = getPadding()

    if action == "init" then
        local splitbelow, splitright = vim.o.splitbelow, vim.o.splitright
        vim.o.splitbelow, vim.o.splitright = true, true

        NoNeckPain.state.win = {
            curr = vim.api.nvim_get_current_win(),
        }

        if options.buffers.left then
            NoNeckPain.state.win.left = createBuf("leftabove vnew", padding, "wincmd l")
        end

        if options.buffers.right then
            NoNeckPain.state.win.right = createBuf("vnew", padding, "wincmd h")
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
        return util.print("enable: tried to enable already enabled NNP")
    end

    util.print("enabling NNP")

    createWin("init")

    vim.api.nvim_create_autocmd({ "VimResized" }, {
        callback = function()
            createWin("VimResized")
        end,
        group = "NoNeckPain",
        desc = "Resizes side windows after shell has been resized",
    })

    vim.api.nvim_create_autocmd({ "BufWinEnter" }, {
        callback = function()
            vim.schedule(function()
                if NoNeckPain.state.win.split ~= nil then
                    return util.print("BufWinEnter: already in split view, nothing more to do")
                end

                -- we don't want close action on float window to impact NNP
                if util.isRelativeWindow("BufWinEnter") then
                    return
                end

                local buffers = vim.api.nvim_list_wins()
                local validBuffers = {}

                -- store buffers that are not part of NNP to see if we have opened a split
                for _, buffer in ipairs(buffers) do
                    if
                        not util.isRelativeWindow("BufWinEnter", buffer)
                        and buffer ~= NoNeckPain.state.win.left
                        and buffer ~= NoNeckPain.state.win.right
                        and buffer ~= NoNeckPain.state.win.curr
                    then
                        table.insert(validBuffers, buffer)
                    end
                end

                local nbBuffers = util.tsize(validBuffers)
                local focusedWin = vim.api.nvim_get_current_win()

                if nbBuffers == 0 or not util.contains(validBuffers, focusedWin) then
                    return util.print("BufWinEnter: no valid buffers to handle, no split to handle")
                end

                util.print("BufWinEnter: found ", nbBuffers, " remaining valid buffers")

                -- start by saving the split, because steps below will trigger `WinClosed`
                NoNeckPain.state.win.split = focusedWin

                if NoNeckPain.state.win.left ~= nil then
                    util.print("BufWinEnter: killing left side buffer")

                    vim.api.nvim_win_close(NoNeckPain.state.win.left, true)
                    NoNeckPain.state.win.left = nil
                end

                if NoNeckPain.state.win.right ~= nil then
                    util.print("BufWinEnter: killing right side buffer")

                    vim.api.nvim_win_close(NoNeckPain.state.win.right, true)
                    NoNeckPain.state.win.right = nil
                end
            end)
        end,
        group = "NoNeckPain",
        desc = "Tries to detect when a split/vsplit buf opens",
    })

    vim.api.nvim_create_autocmd({ "WinClosed", "BufDelete" }, {
        callback = function()
            vim.schedule(function()
                -- we don't want close action on float window to impact NNP
                if util.isRelativeWindow("WinClosed, BufDelete") then
                    return
                end

                local buffers = vim.api.nvim_list_wins()

                -- if we are not in split view, ensure we killed one of the main buffers (curr, left, right)
                -- TODO: make killed side buffer decision configurable, we can re-create it
                if
                    NoNeckPain.state.win.split == nil
                    and (
                        not util.contains(buffers, NoNeckPain.state.win.curr)
                        or (options.buffers.left and not util.contains(
                            buffers,
                            NoNeckPain.state.win.left
                        ))
                        or (
                            options.buffers.right
                            and not util.contains(buffers, NoNeckPain.state.win.right)
                        )
                    )
                then
                    util.print("WinClosed, BufDelete: one of the NNP main buffers have been closed")

                    return NoNeckPain.disable()
                end

                if util.tsize(buffers) > 1 then
                    return util.print(
                        "WinClosed, BufDelete: more than one buffer left, no killed split to handle"
                    )
                end

                local lastActiveBuffer = nil

                -- determine which buffer left out of the two curr/split
                for _, buffer in ipairs(buffers) do
                    if NoNeckPain.state.win.split == buffer then
                        lastActiveBuffer = NoNeckPain.state.win.split
                    elseif NoNeckPain.state.win.curr == buffer then
                        lastActiveBuffer = NoNeckPain.state.win.curr
                    else
                        return util.print(
                            "WinClosed, BufDelete: unable to determine which buffer is the last one"
                        )
                    end
                end

                -- set last active as the curr, reset split anyway
                NoNeckPain.state.win.curr = lastActiveBuffer
                NoNeckPain.state.win.split = nil

                -- focus curr
                vim.fn.win_gotoid(NoNeckPain.state.win.curr)

                -- recreate everything
                createWin("init")
            end)
        end,
        group = "NoNeckPain",
        desc = "Aims at restoring NNP enable state after closing a split view",
    })

    vim.api.nvim_create_autocmd({ "WinEnter", "WinClosed" }, {
        callback = function()
            vim.schedule(function()
                if NoNeckPain.state.win.split ~= nil then
                    return util.print("WinEnter, WinClosed: stop because of split view")
                end

                if util.isRelativeWindow("WinEnter, WinClosed") then
                    return
                end

                local focusedWin = vim.api.nvim_get_current_win()

                -- skip if the newly focused window is a side buffer
                if
                    focusedWin == NoNeckPain.state.win.left
                    or focusedWin == NoNeckPain.state.win.right
                then
                    return util.print("WinEnter, WinClosed: focus on side buffer, skipped resize")
                end

                local padding = 0

                -- when opening a new buffer as current, store its padding and resize everything (e.g. side tree)
                if focusedWin ~= NoNeckPain.state.win.curr then
                    padding = vim.api.nvim_win_get_width(focusedWin)
                    util.print("WinEnter, WinClosed: new current buffer found, resizing:", padding)
                end

                local width = vim.api.nvim_list_uis()[1].width
                local totalSideSizes = (width - padding) - options.width

                util.print("WinEnter, WinClosed: resizing side buffers")
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
        return util.print("disable: tried to disable non-enabled NNP")
    end

    util.print("disabling NNP")

    vim.api.nvim_create_augroup("NoNeckPain", {
        clear = true,
    })

    -- shutdowns gracefully by focusing the stored `curr` buffer, if possible
    if
        NoNeckPain.state.win.curr ~= nil
        and vim.api.nvim_win_is_valid(NoNeckPain.state.win.curr)
        and NoNeckPain.state.win.curr ~= vim.api.nvim_get_current_win()
    then
        vim.fn.win_gotoid(NoNeckPain.state.win.curr)
    end

    vim.cmd("only")

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
