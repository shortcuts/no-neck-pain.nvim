local cfg = require("no-neck-pain.config").options
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

local function getPadding()
    local width = vim.api.nvim_list_uis()[1].width

    if cfg.width >= width then
        return 1
    end

    local curr_width = cfg.width * 3
    if curr_width > width then
        local available_space = width - cfg.width
        return (available_space % 2 > 0 and ((available_space - 1) / 2) or available_space / 2)
    end

    return cfg.width
end

-- Creates a buffer for the given padding, at the given direction
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
    createWin("init")

    vim.api.nvim_create_autocmd({ "VimResized" }, {
        callback = function()
            createWin()
        end,
        group = "NoNeckPain",
        desc = "Resizes side windows after shell has been resized",
    })

    vim.api.nvim_create_autocmd({ "WinClosed" }, {
        callback = function()
            vim.schedule(function()
                -- disable NNP if the current window is closed
                if M.state.enabled and vim.api.nvim_get_current_win() ~= M.state.win.curr then
                    M.disable()
                end
            end)
        end,
        group = "NoNeckPain",
        desc = "Disables NoNeckPain when main window is closed",
    })

    vim.api.nvim_create_autocmd({ "WinEnter" }, {
        callback = function()
            vim.schedule(function()
                if not M.state.enabled and cfg.enableOnWinEnter then
                    M.enable()
                end
            end)
        end,
        group = "NoNeckPain",
        desc = "Disables NoNeckPain when main window is closed",
    })

    vim.api.nvim_create_autocmd({ "WinEnter", "WinClosed" }, {
        callback = function()
            vim.schedule(function()
                -- trigger on float window (e.g. telescope)
                if vim.api.nvim_win_get_config(0).relative ~= "" then
                    createWin()

                    return
                end

                -- skip if the newly focused window is a side buffer
                if
                    vim.api.nvim_get_current_win() == M.state.win.left
                    or vim.api.nvim_get_current_win() == M.state.win.right
                then
                    return
                end

                local padding = 0

                -- when opening a new buffer as current, store its padding and resize everything (e.g. side tree)
                if vim.api.nvim_get_current_win() ~= M.state.win.curr then
                    padding = vim.api.nvim_win_get_width(0)
                end

                local width = vim.api.nvim_list_uis()[1].width
                local totalSideSizes = (width - padding) - cfg.width

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
    -- when disabling, if current isn't NNP curr, focus it
    if vim.api.nvim_win_is_valid(M.state.win.curr) then
        if M.state.win.curr ~= vim.api.nvim_get_current_win() then
            vim.fn.win_gotoid(M.state.win.curr)
        end
    end

    vim.cmd("only")

    vim.api.nvim_create_augroup("NoNeckPain", {
        clear = true,
    })

    M.state = {
        enabled = false,
        win = {
            opts = M.state.win.opts,
            curr = nil,
            left = nil,
            right = nil,
        },
    }
end

return M
