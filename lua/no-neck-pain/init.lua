local M = require("no-neck-pain.main")
local D = require("no-neck-pain.util.debug")
local E = require("no-neck-pain.util.event")

local NoNeckPain = {}
_G.NoNeckPain = _G.NoNeckPain or {}

--- Toggle the plugin by calling the `enable`/`disable` methods respectively.
function NoNeckPain.toggle()
    if _G.NoNeckPain.config == nil then
        _G.NoNeckPain.config = require("no-neck-pain.config").options
    end

    local enabled, state = M.toggle()

    _G.NoNeckPain.state = state

    if not enabled then
        _G.NoNeckPain.internal = {
            toggle = nil,
            enable = nil,
            disable = nil,
        }

        return
    end

    _G.NoNeckPain.internal = M
end

--- Initializes the plugin, sets event listeners and internal state.
function NoNeckPain.enable()
    if _G.NoNeckPain.config == nil then
        _G.NoNeckPain.config = require("no-neck-pain.config").options
    end

    _G.NoNeckPain.state = M.enable()
    _G.NoNeckPain.internal = M
end

--- Disables the plugin, clear highlight groups and autocmds, closes side buffers and resets the internal state.
function NoNeckPain.disable()
    _G.NoNeckPain.state = M.disable()
    _G.NoNeckPain.internal = {
        toggle = nil,
        enable = nil,
        disable = nil,
    }
end

-- setup NoNeckPain options and merge them with user provided ones.
function NoNeckPain.setup(opts)
    _G.NoNeckPain.config = require("no-neck-pain.config").setup(opts)

    if _G.NoNeckPain.config.enableOnVimEnter then
        vim.api.nvim_create_augroup("NoNeckPainBufWinEnter", { clear = true })
        vim.api.nvim_create_autocmd({ "BufWinEnter" }, {
            group = "NoNeckPainBufWinEnter",
            pattern = "*",
            callback = function(p)
                vim.schedule(function()
                    if E.abortEnable(_G.NoNeckPain.state, vim.bo.filetype) then
                        return
                    end

                    _G.NoNeckPain.enable()
                    vim.api.nvim_del_autocmd(p.id)
                end)
            end,
            desc = "Triggers until it find the correct moment/buffer to enable the plugin.",
        })
    end
end

_G.NoNeckPain = NoNeckPain

return _G.NoNeckPain
