local M = require("no-neck-pain.main")

local NoNeckPain = {}

--- Toggle the plugin by calling the `enable`/`disable` methods respectively.
function NoNeckPain.toggle()
    if _G.NoNeckPain.config == nil then
        _G.NoNeckPain.config = require("no-neck-pain.config").options
    end

    _G.NoNeckPain.state = M.toggle("publicAPI_toggle")
end

--- Sets the config `width` to the given `width` value and resizes the NoNeckPain windows.
---
--- @param width number: any positive integer superior to 0.
function NoNeckPain.resize(width)
    if not _G.NoNeckPain.state.enabled then
        error("no-neck-pain.nvim must be enabled, run `NoNeckPain` first.")
    end

    width = tonumber(width) or 0

    if _G.NoNeckPain.config.width == width then
        return
    end

    if width > 0 then
        _G.NoNeckPain.config = vim.tbl_deep_extend("keep", { width = width }, _G.NoNeckPain.config)
    end

    _G.NoNeckPain.state = M.init("publicAPI_resize", nil, false)
end

--- Initializes the plugin, sets event listeners and internal state.
function NoNeckPain.enable()
    if _G.NoNeckPain.config == nil then
        _G.NoNeckPain.config = require("no-neck-pain.config").options
    end

    _G.NoNeckPain.state = M.enable("publicAPI_enable")
end

--- Disables the plugin, clear highlight groups and autocmds, closes side buffers and resets the internal state.
function NoNeckPain.disable()
    _G.NoNeckPain.state = M.disable("publicAPI_disable")
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
                    -- in the `enableOnVimEnter` hooks. It exists to prevent
                    -- conflicts with other plugins:
                    -- netrw: it works
                    -- dashboard: we skip until we open an other buffer
                    -- nvim-tree: we skip until we open an other buffer
                    if _G.NoNeckPain.state ~= nil and _G.NoNeckPain.state.enabled == true then
                        return
                    end

                    if vim.bo.filetype == "dashboard" or vim.bo.filetype == "NvimTree" then
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
