local A = require("no-neck-pain.util.api")
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

    if _G.NoNeckPain.config.enableOnVimEnter or _G.NoNeckPain.config.enableOnTabEnter then
        A.augroup("NoNeckPainAutocmd")
    end

    if _G.NoNeckPain.config.enableOnVimEnter then
        vim.api.nvim_create_autocmd({ "BufWinEnter" }, {
            pattern = "*",
            callback = function(p)
                vim.schedule(function()
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
            group = "NoNeckPainAutocmd",
            desc = "Triggers until it find the correct moment/buffer to enable the plugin.",
        })
    end

    if _G.NoNeckPain.config.enableOnTabEnter then
        vim.api.nvim_create_autocmd({ "TabNewEntered" }, {
            callback = function()
                vim.schedule(function()
                    if vim.bo.filetype == "dashboard" or vim.bo.filetype == "NvimTree" then
                        return
                    end

                    NoNeckPain.enable()
                end)
            end,
            group = "NoNeckPainAutocmd",
            desc = "Enables the plugin when entering a new tab.",
        })
    end
end

_G.NoNeckPain = NoNeckPain

return _G.NoNeckPain
