local main = require("no-neck-pain.main")
local log = require("no-neck-pain.util.debug")
local api = require("no-neck-pain.util.api")
local config = require("no-neck-pain.config")

local NoNeckPain = {}

--- Toggle the plugin by calling the `enable`/`disable` methods respectively.
function NoNeckPain.toggle()
    if _G.NoNeckPain.config == nil then
        _G.NoNeckPain.config = config.options
    end

    api.debounce("public_api_toggle", main.toggle)
end

--- Toggles the scratchPad feature of the plugin.
function NoNeckPain.toggleScratchPad()
    if _G.NoNeckPain.state == nil or not _G.NoNeckPain.state.enabled then
        error("no-neck-pain.nvim must be enabled, run `NoNeckPain` first.")
    end

    if _G.NoNeckPain.config == nil then
        _G.NoNeckPain.config = config.options
    end

    main.toggle_scratchPad()
end

--- Sets the config `width` to the given `width` value and resizes the NoNeckPain windows.
---
---@param width number: any positive integer superior to 0.
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

    main.init("public_api_resize", false)
end

--- Toggles the config `${side}.enabled` and re-inits the plugin.
---
---@param side "left" | "right": the side to toggle.
function NoNeckPain.toggleSide(side)
    if _G.NoNeckPain.state == nil or not _G.NoNeckPain.state.enabled then
        error("no-neck-pain.nvim must be enabled, run `NoNeckPain` first.")
    end

    api.debounce("public_api_toggle_side", function(scope)
        main.toggle_side(scope, side)
    end)
end

--- Initializes the plugin, sets event listeners and internal state.
function NoNeckPain.enable(scope)
    if _G.NoNeckPain.config == nil then
        _G.NoNeckPain.config = config.options
    end

    api.debounce(scope or "public_api_enable", main.enable, 10)
end

--- Disables the plugin, clear highlight groups and autocmds, closes side buffers and resets the internal state.
function NoNeckPain.disable()
    api.debounce("public_api_disable", main.disable)
end

-- setup NoNeckPain options and merge them with user provided ones.
function NoNeckPain.setup(opts)
    _G.NoNeckPain.config = config.setup(opts)

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

                    _G.NoNeckPain.config = config.defaults(opts)
                    main.init(p.event)
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

                    api.debounce("enable_on_vim_enter", function()
                        if _G.NoNeckPain.state ~= nil then
                            pcall(vim.api.nvim_del_augroup_by_name, "NoNeckPainVimEnterAutocmd")
                        end
                    end, 20)
                end)
            end,
            group = "NoNeckPainVimEnterAutocmd",
            desc = "Triggers until it finds the correct moment/buffer to enable the plugin.",
        })
    end

    if _G.NoNeckPain.config.autocmds.enableOnTabEnter then
        vim.api.nvim_create_autocmd({ "TabEnter" }, {
            callback = function(p)
                vim.schedule(function()
                    vim.print("bar")
                    if _G.NoNeckPain.state == nil or not _G.NoNeckPain.state.enabled then
                        return log.debug(p.event, "plugin is disabled")
                    end

                    NoNeckPain.enable("enable_on_tab_enter")
                end)
            end,
            group = "NoNeckPainAutocmd",
            desc = "Enables the plugin when entering a new tab.",
        })
    end
end

_G.NoNeckPain = NoNeckPain

return _G.NoNeckPain
