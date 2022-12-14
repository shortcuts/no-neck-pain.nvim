local M = require("no-neck-pain.main")
local E = require("no-neck-pain.util.event")

local NoNeckPain = {}

--- Toggle the plugin by calling the `enable`/`disable` methods respectively.
function NoNeckPain.toggle()
    if _G.NoNeckPain.config == nil then
        _G.NoNeckPain.config = require("no-neck-pain.config").options
    end

    _G.NoNeckPain.state = M.toggle()
end

--- Initializes the plugin, sets event listeners and internal state.
function NoNeckPain.enable()
    if _G.NoNeckPain.config == nil then
        _G.NoNeckPain.config = require("no-neck-pain.config").options
    end

    _G.NoNeckPain.state = M.enable()
end

--- Disables the plugin, clear highlight groups and autocmds, closes side buffers and resets the internal state.
function NoNeckPain.disable()
    _G.NoNeckPain.state = M.disable()
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

                    NoNeckPain.enable()
                    vim.api.nvim_del_autocmd(p.id)
                end)
            end,
            desc = "Triggers until it find the correct moment/buffer to enable the plugin.",
        })
    end
end

_G.NoNeckPain = NoNeckPain

return _G.NoNeckPain
