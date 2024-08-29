local M = require("no-neck-pain.main")
local D = require("no-neck-pain.util.debug")
local A = require("no-neck-pain.util.api")
local C = require("no-neck-pain.config")

local NoNeckPain = {}

--- Toggle the plugin by calling the `enable`/`disable` methods respectively.
function NoNeckPain.toggle()
    if _G.NoNeckPain.config == nil then
        _G.NoNeckPain.config = C.options
    end

    A.debounce("public_api_toggle", M.toggle)
end

--- Toggles the scratchPad feature of the plugin.
function NoNeckPain.toggleScratchPad()
    if _G.NoNeckPain.state == nil or not _G.NoNeckPain.state.enabled then
        error("no-neck-pain.nvim must be enabled, run `NoNeckPain` first.")
    end

    if _G.NoNeckPain.config == nil then
        _G.NoNeckPain.config = C.options
    end

    M.toggle_scratchPad()
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

    M.init("public_api_resize", false)
end

--- Toggles the config `${side}.enabled` and re-inits the plugin.
---
--- @param side "left" | "right": the side to toggle.
function NoNeckPain.toggleSide(side)
    if _G.NoNeckPain.state == nil or not _G.NoNeckPain.state.enabled then
        error("no-neck-pain.nvim must be enabled, run `NoNeckPain` first.")
    end

    A.debounce("public_api_toggle_side", function(scope)
        M.toggle_side(scope, side)
    end)
end

--- Initializes the plugin, sets event listeners and internal state.
function NoNeckPain.enable()
    if _G.NoNeckPain.config == nil then
        _G.NoNeckPain.config = C.options
    end

    A.debounce("public_api_enable", M.enable, 10)
end

--- Disables the plugin, clear highlight groups and autocmds, closes side buffers and resets the internal state.
function NoNeckPain.disable()
    A.debounce("public_api_disable", M.disable)
end

-- setup NoNeckPain options and merge them with user provided ones.
function NoNeckPain.setup(opts)
    _G.NoNeckPain.config = C.setup(opts)

    if
        _G.NoNeckPain.config.autocmds.enableOnVimEnter
        or _G.NoNeckPain.config.autocmds.enableOnTabEnter
        or _G.NoNeckPain.config.autocmds.reloadOnColorSchemeChange
    then
        vim.api.nvim_create_augroup("NoNeckPainAutocmd", { clear = true })
        vim.api.nvim_create_augroup("NoNeckPainVimEnterAutocmd", { clear = true })
    end

    if _G.NoNeckPain.config.autocmds.reloadOnColorSchemeChange then
        vim.api.nvim_create_autocmd({ "ColorScheme" }, {
            pattern = "*",
            callback = function(p)
                vim.schedule(function()
                    if _G.NoNeckPain.state == nil or not _G.NoNeckPain.state.enabled then
                        return
                    end

                    _G.NoNeckPain.config = C.defaults(opts)
                    M.init(p.event)
                end)
            end,
            group = "NoNeckPainAutocmd",
            desc = "Triggers until it finds the correct moment/buffer to enable the plugin.",
        })
    end

    if _G.NoNeckPain.config.autocmds.enableOnVimEnter then
        vim.api.nvim_create_autocmd({ "BufEnter" }, {
            pattern = "*",
            callback = function()
                vim.schedule(function()
                    if _G.NoNeckPain.state ~= nil and _G.NoNeckPain.state.enabled then
                        return
                    end

                    NoNeckPain.enable()

                    A.debounce("enable_on_vim_enter", function()
                        if _G.NoNeckPain.state ~= nil then
                            pcall(vim.api.nvim_del_augroup_by_name, "NoNeckPain_vim_enter_autocmd")
                        end
                    end, 20)
                end)
            end,
            group = "NoNeckPainVimEnterAutocmd",
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
