local M = require("no-neck-pain.main")

local NoNeckPain = {}

--- Toggle the plugin by calling the `enable`/`disable` methods respectively.
function NoNeckPain.toggle()
    if _G.NoNeckPain.config == nil then
        _G.NoNeckPain.config = require("no-neck-pain.config").options
    end

    _G.NoNeckPain.state = M.toggle("publicAPI_toggle")
end

--- Toggles the scratchPad feature of the plugin.
function NoNeckPain.toggleScratchPad()
    if _G.NoNeckPain.state == nil or not _G.NoNeckPain.state.enabled then
        error("no-neck-pain.nvim must be enabled, run `NoNeckPain` first.")
    end

    if _G.NoNeckPain.config == nil then
        _G.NoNeckPain.config = require("no-neck-pain.config").options
    end

    _G.NoNeckPain.state = M.toggleScratchPad()
end

--- Sets the config `width` to the given `width` value and resizes the NoNeckPain windows.
---
--- @param width number: any positive integer superior to 0.
function NoNeckPain.resize(width)
    if _G.NoNeckPain.state == nil or not _G.NoNeckPain.state.enabled then
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

    local state = M.enable("publicAPI_enable")

    if state ~= nil then
        _G.NoNeckPain.state = state
    end

    return state
end

--- Disables the plugin, clear highlight groups and autocmds, closes side buffers and resets the internal state.
function NoNeckPain.disable()
    _G.NoNeckPain.state = M.disable("publicAPI_disable")
end

-- setup NoNeckPain options and merge them with user provided ones.
function NoNeckPain.setup(opts)
    _G.NoNeckPain.config = require("no-neck-pain.config").setup(opts)

    if
        _G.NoNeckPain.config.autocmds.enableOnVimEnter
        or _G.NoNeckPain.config.autocmds.enableOnTabEnter
    then
        vim.api.nvim_create_augroup("NoNeckPainAutocmd", { clear = true })
    end

    if _G.NoNeckPain.config.autocmds.enableOnVimEnter then
        vim.api.nvim_create_autocmd({ "BufEnter" }, {
            pattern = "*",
            callback = function(p)
                vim.schedule(function()
                    if _G.NoNeckPain.state ~= nil and _G.NoNeckPain.state.enabled then
                        return
                    end

                    local state = NoNeckPain.enable()

                    if state ~= nil then
                        vim.api.nvim_del_autocmd(p.id)
                    end
                end)
            end,
            group = "NoNeckPainAutocmd",
            desc = "Triggers until it finds the correct moment/buffer to enable the plugin.",
        })
    end

    if _G.NoNeckPain.config.autocmds.enableOnTabEnter then
        vim.api.nvim_create_autocmd({ "TabNewEntered" }, {
            callback = function()
                vim.schedule(function()
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
