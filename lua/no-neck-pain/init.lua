local M = require("no-neck-pain.main")
local D = require("no-neck-pain.util.debug")
local A = require("no-neck-pain.util.api")
local cfg = require("no-neck-pain.config")

local NoNeckPain = {}

--- Toggle the plugin by calling the `enable`/`disable` methods respectively.
function NoNeckPain.toggle()
    if _G.NoNeckPain.config == nil then
        _G.NoNeckPain.config = cfg.options
    end

    A.debounce("publicAPI_toggle", M.toggle)
end

--- Toggles the scratchPad feature of the plugin.
function NoNeckPain.toggleScratchPad()
    if _G.NoNeckPain.state == nil or not _G.NoNeckPain.state.enabled then
        error("no-neck-pain.nvim must be enabled, run `NoNeckPain` first.")
    end

    if _G.NoNeckPain.config == nil then
        _G.NoNeckPain.config = cfg.options
    end

    A.debounce("publicAPI_toggleScratchPad", M.toggleScratchPad)
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

    A.debounce("publicAPI_resize", function(scope)
        M.init(scope, false)
    end)
end

--- Toggles the config `${side}.enabled` and re-inits the plugin.
---
--- @param side "left" | "right": the side to toggle.
function NoNeckPain.toggleSide(side)
    if _G.NoNeckPain.state == nil or not _G.NoNeckPain.state.enabled then
        error("no-neck-pain.nvim must be enabled, run `NoNeckPain` first.")
    end

    A.debounce("publicAPI_toggleSide", function(scope)
        M.toggleSide(scope, side)
    end)
end

--- Initializes the plugin, sets event listeners and internal state.
function NoNeckPain.enable()
    if _G.NoNeckPain.config == nil then
        _G.NoNeckPain.config = cfg.options
    end

    A.debounce("publicAPI_enable", M.enable)
end

--- Disables the plugin, clear highlight groups and autocmds, closes side buffers and resets the internal state.
function NoNeckPain.disable()
    A.debounce("publicAPI_disable", M.disable)
end

-- setup NoNeckPain options and merge them with user provided ones.
function NoNeckPain.setup(opts)
    _G.NoNeckPain.config = cfg.setup(opts)

    if
        _G.NoNeckPain.config.autocmds.enableOnVimEnter
        or _G.NoNeckPain.config.autocmds.enableOnTabEnter
        or _G.NoNeckPain.config.autocmds.reloadOnColorSchemeChange
    then
        vim.api.nvim_create_augroup("NoNeckPainAutocmd", { clear = true })
    end

    if _G.NoNeckPain.config.autocmds.reloadOnColorSchemeChange then
        vim.api.nvim_create_autocmd({ "ColorScheme" }, {
            pattern = "*",
            callback = function()
                vim.schedule(function()
                    if _G.NoNeckPain.state == nil or not _G.NoNeckPain.state.enabled then
                        return
                    end

                    _G.NoNeckPain.config = cfg.defaults(opts)
                    A.debounce("ColorScheme", M.init)
                end)
            end,
            group = "NoNeckPainAutocmd",
            desc = "Triggers until it finds the correct moment/buffer to enable the plugin.",
        })
    end

    if _G.NoNeckPain.config.autocmds.enableOnVimEnter then
        vim.api.nvim_create_autocmd({ "BufEnter" }, {
            pattern = "*",
            callback = function(p)
                vim.schedule(function()
                    if _G.NoNeckPain.state ~= nil and _G.NoNeckPain.state.enabled then
                        return
                    end

                    NoNeckPain.enable()

                    if _G.NoNeckPain.state ~= nil then
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
            callback = function(p)
                vim.schedule(function()
                    if _G.NoNeckPain.state == nil or not _G.NoNeckPain.state.enabled then
                        return D.log(p.event, "plugin is disabled")
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
