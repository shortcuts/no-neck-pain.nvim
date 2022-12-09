local options = require("no-neck-pain.config").options
local util = require("no-neck-pain.util")
local SIDES = { "left", "right" }

local M = {
    -- State of NoNeckPain
    state = {
        enabled = false,
        win = {
            -- side buffer/windows options
            opts = {
                bo = {
                    buftype = "nofile",
                    bufhidden = "hide",
                    modifiable = false,
                    buflisted = false,
                    swapfile = false,
                },
                wo = {
                    cursorline = false,
                    cursorcolumn = false,
                    number = false,
                    relativenumber = false,
                    foldenable = false,
                    list = false,
                },
            },
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

-- toggle plugin and restart states
function M.toggle()
    if M.state.enabled then
        return M.disable()
    end

    M.enable()
end

-- gets the padding to size the side windows, based on the options.width and the current window size
local function getPadding()
    local width = vim.api.nvim_list_uis()[1].width

    if options.width >= width then
        return 1
    end

    return math.floor((width - options.width) / 2)
end

-- creates a buffer for the given padding, at the given direction
local function createBuf(cmd, padding, moveTo)
    vim.cmd(cmd)

    local id = vim.api.nvim_get_current_win()

    vim.api.nvim_win_set_width(0, padding)

    for scope, _ in pairs(M.state.win.opts) do
        for name, value in pairs(M.state.win.opts[scope]) do
            vim[scope][name] = value
        end
    end

    vim.cmd(moveTo)

    return id
end

-- creates a NNP focused buffer when called with `init`. Resizes sides on any other cases.
local function createWin(action)
    util.print("CreateWin: ", action)

    local padding = getPadding()

    if action == "init" then
        local splitbelow, splitright = vim.o.splitbelow, vim.o.splitright
        vim.o.splitbelow, vim.o.splitright = true, true

        M.state.win = {
            opts = M.state.win.opts,
            curr = vim.api.nvim_get_current_win(),
            left = createBuf("leftabove vnew", padding, "wincmd l"),
        }

        if not options.leftPaddingOnly then
            M.state.win.right = createBuf("vnew", padding, "wincmd h")
        end

        vim.o.splitbelow, vim.o.splitright = splitbelow, splitright

        return
    end

    -- resize
    for _, side in ipairs(SIDES) do
        if M.state.win[side] ~= nil and vim.api.nvim_win_is_valid(M.state.win[side]) then
            vim.api.nvim_win_set_width(M.state.win[side], padding)
        end
    end
end

-- initializes NNP and sets event listeners.
function M.enable()
    if M.state.enabled then
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
                if M.state.win.split ~= nil then
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
                        and buffer ~= M.state.win.left
                        and buffer ~= M.state.win.right
                        and buffer ~= M.state.win.curr
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
                M.state.win.split = focusedWin

                if M.state.win.left ~= nil then
                    util.print("BufWinEnter: killing left side buffer")

                    vim.api.nvim_win_close(M.state.win.left, true)
                    M.state.win.left = nil
                end

                if M.state.win.right ~= nil then
                    util.print("BufWinEnter: killing right side buffer")

                    vim.api.nvim_win_close(M.state.win.right, true)
                    M.state.win.right = nil
                end
            end)
        end,
        group = "NoNeckPain",
        desc = "Tries to detect when a split/vsplit buf opens",
    })

    vim.api.nvim_create_autocmd({ "WinClosed" }, {
        callback = function()
            vim.schedule(function()
                -- we don't want close action on float window to impact NNP
                if util.isRelativeWindow("WinClosed") then
                    return
                end

                local buffers = vim.api.nvim_list_wins()

                -- if we are not in split view, ensure we killed one of the main buffers (curr, left, right)
                -- TODO: make killed side buffer decision configurable, we can re-create it
                if
                    M.state.win.split == nil
                    and (
                        not util.contains(buffers, M.state.win.curr)
                        or not util.contains(buffers, M.state.win.left)
                        or not util.contains(buffers, M.state.win.right)
                    )
                then
                    util.print("WinClosed: one of the NNP main buffers have been closed")

                    return M.disable()
                end

                if util.tsize(buffers) > 1 then
                    return util.print(
                        "WinClosed: more than one buffer left, no killed split to handle"
                    )
                end

                local lastActiveBuffer = nil

                -- determine which buffer left out of the two curr/split
                for _, buffer in ipairs(buffers) do
                    if M.state.win.split == buffer then
                        lastActiveBuffer = M.state.win.split
                    elseif M.state.win.curr == buffer then
                        lastActiveBuffer = M.state.win.curr
                    else
                        return util.print(
                            "Winclosed: unable to determine which buffer is the last one"
                        )
                    end
                end

                -- set last active as the curr, reset split anyway
                M.state.win.curr = lastActiveBuffer
                M.state.win.split = nil

                -- focus curr
                vim.fn.win_gotoid(M.state.win.curr)

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
                if M.state.win.split ~= nil then
                    return util.print("WinEnter, WinClosed: stop because of split view")
                end

                if util.isRelativeWindow("WinEnter, WinClosed") then
                    return
                end

                local focusedWin = vim.api.nvim_get_current_win()

                -- skip if the newly focused window is a side buffer
                if focusedWin == M.state.win.left or focusedWin == M.state.win.right then
                    return util.print("WinEnter, WinClosed: focus on side buffer, skipped resize")
                end

                local padding = 0

                -- when opening a new buffer as current, store its padding and resize everything (e.g. side tree)
                if focusedWin ~= M.state.win.curr then
                    padding = vim.api.nvim_win_get_width(focusedWin)
                    util.print("WinEnter, WinClosed: new current buffer found, resizing:", padding)
                end

                local width = vim.api.nvim_list_uis()[1].width
                local totalSideSizes = (width - padding) - options.width

                util.print("WinEnter, WinClosed: resizing side buffers")
                for _, side in ipairs(SIDES) do
                    if M.state.win[side] ~= nil then
                        if vim.api.nvim_win_is_valid(M.state.win[side]) then
                            vim.api.nvim_win_set_width(
                                M.state.win[side],
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

    M.state.enabled = true
end

function M.disable()
    if not M.state.enabled then
        return util.print("disable: tried to disable non-enabled NNP")
    end

    util.print("disabling NNP")

    vim.api.nvim_create_augroup("NoNeckPain", {
        clear = true,
    })

    -- shutdowns gracefully by focusing the stored `curr` buffer, if possible
    if
        M.state.win.curr ~= nil
        and vim.api.nvim_win_is_valid(M.state.win.curr)
        and M.state.win.curr ~= vim.api.nvim_get_current_win()
    then
        vim.fn.win_gotoid(M.state.win.curr)
    end

    vim.cmd("only")

    M.state = {
        enabled = false,
        win = {
            opts = M.state.win.opts,
            curr = nil,
            left = nil,
            right = nil,
            split = nil,
        },
    }
end

return M
