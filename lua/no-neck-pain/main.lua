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
        M.disable()
    else
        M.enable()
    end
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

-- creates a NNP focused buffer when called with `init`. Resizes sides on `resize`
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
            right = createBuf("vnew", padding, "wincmd h"),
        }

        vim.o.splitbelow, vim.o.splitright = splitbelow, splitright

        return
    end

    -- resize
    for _, side in ipairs(SIDES) do
        if vim.api.nvim_win_is_valid(M.state.win[side]) then
            vim.api.nvim_win_set_width(M.state.win[side], padding)
        end
    end
end

function M.enable()
    util.print("enabling NNP")

    createWin("init")

    vim.api.nvim_create_autocmd({ "VimResized" }, {
        callback = function()
            util.print("VimResized")

            createWin()
        end,
        group = "NoNeckPain",
        desc = "Resizes side windows after shell has been resized",
    })

    vim.api.nvim_create_autocmd({ "BufWinEnter" }, {
        callback = function()
            vim.schedule(function()
                if M.state.win.split ~= nil then
                    return util.print("BufWinEnter: already int split, exiting")
                end

                if
                    vim.api.nvim_win_get_config(0).relative ~= ""
                    or vim.api.nvim_win_get_config(vim.api.nvim_get_current_win()).relative
                        ~= ""
                then
                    return util.print("BufWinEnter: float window detected")
                end

                local buffers = vim.api.nvim_list_wins()
                local nbBuffers = util.tsize(buffers)

                if nbBuffers <= 3 then
                    return util.print("BufWinEnter: we only have 3 buffers, no need to trigger")
                elseif nbBuffers == 4 then
                    for _, id in ipairs(buffers) do
                        if vim.api.nvim_win_get_config(id).relative ~= "" then
                            return util.print(
                                "BufWinEnter: 4 buffers including a relative one, most likely diagnostic or telescope, skipping"
                            )
                        end
                    end
                end

                -- we can now assume we have to handle the vsplit
                for _, buffer in ipairs(buffers) do
                    if M.state.win.left == buffer then
                        vim.api.nvim_win_close(buffer, true)
                        M.state.win.left = nil
                    elseif M.state.win.right == buffer then
                        vim.api.nvim_win_close(buffer, true)
                        M.state.win.right = nil
                    -- one of the last buffer is not curr, so its the split
                    elseif buffer ~= M.state.win.curr then
                        M.state.win.split = buffer
                    end
                end
            end)
        end,
        group = "NoNeckPain",
        desc = "Tries to detect when a split buf opens",
    })

    vim.api.nvim_create_autocmd({ "WinClosed" }, {
        callback = function()
            vim.schedule(function()
                -- resize if it's not a split, just to be sure
                if M.state.win.split == nil then
                    return createWin()
                end

                local buffers = vim.api.nvim_list_wins()

                if util.tsize(buffers) > 1 then
                    return util.print("WinClosed: only one buffer, nothing to do")
                end

                local lastActiveBuffer = nil

                -- determine which buffer to set as new curr
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

                    -- set last active as the curr, reset split anyway
                    M.state.win.curr = lastActiveBuffer
                    M.state.win.split = nil

                    -- focus curr
                    vim.fn.win_gotoid(M.state.win.curr)

                    -- recreate everything
                    createWin("init")

                    return
                end
            end)
        end,
        group = "NoNeckPain",
        desc = "Aims at restoring NNP enable state after closing a split view",
    })

    vim.api.nvim_create_autocmd({ "WinEnter", "WinClosed" }, {
        callback = function()
            vim.schedule(function()
                -- early exit on split view
                if M.state.win.split ~= nil then
                    return util.print("WinEnter, WinClosed: stop because of split view")
                end

                local focusedWin = vim.api.nvim_get_current_win()

                -- trigger on float window (e.g. telescope)
                if
                    vim.api.nvim_win_get_config(0).relative ~= ""
                    or vim.api.nvim_win_get_config(focusedWin).relative ~= ""
                then
                    return util.print("WinEnter, WinClosed: float window detected")
                end

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
    util.print("disabling NNP")

    vim.api.nvim_create_augroup("NoNeckPain", {
        clear = true,
    })

    -- when disabling, if current isn't NNP curr, focus it
    if vim.api.nvim_win_is_valid(M.state.win.curr) then
        if M.state.win.curr ~= vim.api.nvim_get_current_win() then
            vim.fn.win_gotoid(M.state.win.curr)
        end
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
