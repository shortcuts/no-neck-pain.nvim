local main = require("no-neck-pain.main")
local log = require("no-neck-pain.util.log")
local api = require("no-neck-pain.util.api")
local config = require("no-neck-pain.config")
local helpers = require("no-neck-pain.util.helpers")

local NoNeckPain = {}

--- Toggle the plugin by calling the `enable`/`disable` methods respectively.
function NoNeckPain.toggle()
    _G.NoNeckPain.config = _G.NoNeckPain.config or config.options

    api.debounce("public_api_toggle", main.toggle)
end

--- Toggles the scratch_pad feature of the plugin.
function NoNeckPain.toggle_scratch_pad()
    helpers.ensure_plugin_enabled()

    _G.NoNeckPain.config = _G.NoNeckPain.config or config.options

    main.toggle_scratch_pad()
end

--- Toggles the debug mode of the plugin.
function NoNeckPain.toggle_debug()
    helpers.ensure_plugin_enabled()

    _G.NoNeckPain.config = _G.NoNeckPain.config or config.options

    _G.NoNeckPain.config.debug = not _G.NoNeckPain.config.debug
end

--- Sets the config `width` to the given `width` value and resizes the NoNeckPain windows.
---
---@param width number: any positive integer superior to 0.
function NoNeckPain.resize(width)
    helpers.ensure_plugin_enabled()

    width = tonumber(width) or 0

    if _G.NoNeckPain.config.width == width then
        return
    end

    if width > 0 then
        _G.NoNeckPain.config = vim.tbl_deep_extend("keep", { width = width }, _G.NoNeckPain.config)
    end

    main.init("public_api_resize")
end

--- Toggles the config `${side}.enabled` and re-inits the plugin.
---
---@param side "left" | "right": the side to toggle.
function NoNeckPain.toggle_side(side)
    helpers.ensure_plugin_enabled()

    api.debounce("public_api_toggle_side", function(scope)
        main.toggle_side(scope, side)
    end)
end

--- Initializes the plugin, sets event listeners and internal state.
function NoNeckPain.enable(scope)
    _G.NoNeckPain.config = _G.NoNeckPain.config or config.options

    main.enable(string.format("public_api_enable:%s", scope))
end

--- Disables the plugin, clear highlight groups and autocmds, closes side buffers and resets the internal state.
function NoNeckPain.disable()
    api.debounce("public_api_disable", main.disable)
end

-- setup NoNeckPain options and merge them with user provided ones.
function NoNeckPain.setup(opts)
    _G.NoNeckPain.config = config.setup(opts)
    local autocmds = _G.NoNeckPain.config.autocmds

    vim.api.nvim_create_augroup("NoNeckPainAutocmd", { clear = true })
    vim.api.nvim_create_augroup("NoNeckPainVimEnterAutocmd", { clear = true })

    if autocmds.reloadOnColorSchemeChange then
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

    if autocmds.enableOnVimEnter ~= nil and autocmds.enableOnVimEnter ~= false then
        vim.api.nvim_create_autocmd({ "VimEnter", "BufEnter" }, {
            pattern = "*",
            callback = function()
                -- opening windows while Neovim still loads `-o`/`-O` files makes it
                -- skip or misplace them, VimEnter fires once they are all in place.
                if vim.v.vim_did_enter == 0 then
                    return
                end

                local scope = string.format(
                    "enable_on_vim_enter:%s:%s",
                    config.options.integrations.dashboard.enabled,
                    config.options.autocmds.enableOnVimEnter
                )

                if config.options.autocmds.enableOnVimEnter == "safe" then
                    api.debounce(scope, function()
                        NoNeckPain.enable(scope)
                        if _G.NoNeckPain.state ~= nil then
                            pcall(vim.api.nvim_del_augroup_by_name, "NoNeckPainVimEnterAutocmd")
                        end
                    end, 5)
                else
                    NoNeckPain.enable(scope)

                    api.debounce(string.format("%s:cleanup", scope), function()
                        if _G.NoNeckPain.state ~= nil then
                            pcall(vim.api.nvim_del_augroup_by_name, "NoNeckPainVimEnterAutocmd")
                        end
                    end)
                end
            end,
            group = "NoNeckPainVimEnterAutocmd",
            desc = "Triggers until it finds the correct moment/buffer to enable the plugin.",
        })

        -- FileType safety net: handles deferred filetype resolution
        vim.api.nvim_create_autocmd({ "FileType" }, {
            pattern = "*",
            callback = function()
                -- the plugin has already run at least once; enabling/disabling on a
                -- filetype change is not this net's job.
                if _G.NoNeckPain.state ~= nil or vim.v.vim_did_enter == 0 then
                    return
                end

                local filetype = string.lower(vim.bo.filetype)
                if filetype == "" or helpers.is_filetype_integration(filetype) then
                    return
                end

                NoNeckPain.enable(
                    string.format(
                        "enable_on_filetype:%s:%s",
                        config.options.integrations.dashboard.enabled,
                        config.options.autocmds.enableOnVimEnter
                    )
                )
                helpers.safe_delete_augroup("NoNeckPainVimEnterAutocmd")
            end,
            group = "NoNeckPainVimEnterAutocmd",
            desc = "Safety net for deferred filetype resolution.",
        })
    end

    if autocmds.enableOnTabEnter then
        vim.api.nvim_create_autocmd({ "TabEnter" }, {
            callback = function(p)
                vim.schedule(function()
                    if _G.NoNeckPain.state == nil or not _G.NoNeckPain.state.enabled then
                        return log.debug(p.event, "plugin is disabled")
                    end

                    NoNeckPain.enable(p.event)
                end)
            end,
            group = "NoNeckPainAutocmd",
            desc = "Enables the plugin when entering a new tab.",
        })
    end

    vim.api.nvim_create_autocmd({ "SessionLoadPost" }, {
        callback = function()
            vim.schedule(function()
                local state_ref = _G.NoNeckPain.state
                if state_ref and state_ref.enabled and state_ref:is_active_tab_registered() then
                    state_ref:scan_layout("SessionLoadPost")
                    main.init("SessionLoadPost")
                end
            end)
        end,
        group = "NoNeckPainAutocmd",
        desc = "Restore plugin state after session load",
    })
end

_G.NoNeckPain = NoNeckPain

return _G.NoNeckPain
