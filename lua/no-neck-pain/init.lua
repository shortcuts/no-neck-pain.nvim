local main = require("no-neck-pain.main")
local log = require("no-neck-pain.util.log")
local api = require("no-neck-pain.util.api")
local config = require("no-neck-pain.config")
local helpers = require("no-neck-pain.util.helpers")
local state = require("no-neck-pain.state")

local NoNeckPain = {}

--- Toggle the plugin by calling the `enable`/`disable` methods respectively.
function NoNeckPain.toggle()
    helpers.ensure_config_loaded(config)

    api.debounce("public_api_toggle", main.toggle)
end

--- Toggles the scratch_pad feature of the plugin.
function NoNeckPain.toggle_scratch_pad()
    helpers.ensure_plugin_enabled()

    helpers.ensure_config_loaded(config)

    main.toggle_scratch_pad()
end

--- Toggles the debug mode of the plugin.
function NoNeckPain.toggle_debug()
    helpers.ensure_plugin_enabled()

    helpers.ensure_config_loaded(config)

    local current_debug = helpers.get_config_field("debug")
    helpers.merge_config({ debug = not current_debug })
end

--- Sets the config `width` to the given `width` value and resizes the NoNeckPain windows.
---
---@param width number: any positive integer superior to 0.
function NoNeckPain.resize(width)
    helpers.ensure_plugin_enabled()

    width = tonumber(width) or 0

    if helpers.get_config_field("width") == width then
        return
    end

    if width > 0 then
        helpers.merge_config({ width = width })
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
    helpers.ensure_config_loaded(config)

    main.enable(string.format("public_api_enable:%s", scope))
end

--- Disables the plugin, clear highlight groups and autocmds, closes side buffers and resets the internal state.
function NoNeckPain.disable()
    api.debounce("public_api_disable", main.disable)
end

-- setup NoNeckPain options and merge them with user provided ones.
function NoNeckPain.setup(opts)
    helpers.set_config(config.setup(opts))

    if
        helpers.get_config_field("autocmds").enableOnVimEnter
        or helpers.get_config_field("autocmds").enableOnTabEnter
        or helpers.get_config_field("autocmds").reloadOnColorSchemeChange
    then
        vim.api.nvim_create_augroup("NoNeckPainAutocmd", { clear = true })
        vim.api.nvim_create_augroup("NoNeckPainVimEnterAutocmd", { clear = true })
    end

    if helpers.get_config_field("autocmds").reloadOnColorSchemeChange then
        vim.api.nvim_create_autocmd({ "ColorScheme" }, {
            pattern = "*",
            callback = function(p)
                vim.schedule(function()
                    if helpers.get_state() == nil or not helpers.get_state_field("enabled") then
                        return
                    end

                    helpers.set_config(config.defaults(opts))
                    main.init(p.event)
                end)
            end,
            group = "NoNeckPainAutocmd",
            desc = "Triggers until it finds the correct moment/buffer to enable the plugin.",
        })
    end

    if
        helpers.get_config_field("autocmds").enableOnVimEnter ~= nil
        and helpers.get_config_field("autocmds").enableOnVimEnter ~= false
    then
        vim.api.nvim_create_autocmd({ "BufEnter" }, {
            pattern = "*",
            callback = function()
                local scope = string.format(
                    "enable_on_vim_enter:%s:%s",
                    config.options.integrations.dashboard.enabled,
                    config.options.autocmds.enableOnVimEnter
                )

                if config.options.autocmds.enableOnVimEnter == "safe" then
                    api.debounce(scope, function()
                        NoNeckPain.enable(scope)
                        if helpers.get_state() ~= nil then
                            pcall(vim.api.nvim_del_augroup_by_name, "NoNeckPainVimEnterAutocmd")
                        end
                    end, 5)
                else
                    NoNeckPain.enable(scope)

                    api.debounce(string.format("%s:cleanup", scope), function()
                        if helpers.get_state() ~= nil then
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
                local filetype = string.lower(vim.bo.filetype)
                local state = helpers.get_state()

                -- Disable path: if enabled and filetype is integration
                if state ~= nil and filetype ~= "" then
                    if helpers.is_filetype_integration(filetype) then
                        NoNeckPain.disable()
                        pcall(vim.api.nvim_del_augroup_by_name, "NoNeckPainVimEnterAutocmd")
                        return
                    end
                end

                -- Enable path: if not yet enabled and filetype is not integration
                if state == nil and filetype ~= "" then
                    if not helpers.is_filetype_integration(filetype) then
                        local scope = string.format(
                            "enable_on_filetype:%s:%s",
                            config.options.integrations.dashboard.enabled,
                            config.options.autocmds.enableOnVimEnter
                        )
                        NoNeckPain.enable(scope)
                        pcall(vim.api.nvim_del_augroup_by_name, "NoNeckPainVimEnterAutocmd")
                    end
                end
            end,
            group = "NoNeckPainVimEnterAutocmd",
            desc = "Safety net for deferred filetype resolution.",
        })
    end

    if helpers.get_config_field("autocmds").enableOnTabEnter then
        vim.api.nvim_create_autocmd({ "TabEnter" }, {
            callback = function(p)
                vim.schedule(function()
                    if helpers.get_state() == nil or not helpers.get_state_field("enabled") then
                        return log.debug(p.event, "plugin is disabled")
                    end

                    NoNeckPain.enable(p.event)
                end)
            end,
            group = "NoNeckPainAutocmd",
            desc = "Enables the plugin when entering a new tab.",
        })
    end

    vim.api.nvim_create_autocmd({ "SourceCmd" }, {
        pattern = "*.vim",
        callback = function(p)
            main.signal_session_restore_start()
            vim.cmd("source " .. p.file)
        end,
        group = "NoNeckPainAutocmd",
        desc = "Detect session restore from :source command",
    })

    vim.api.nvim_create_autocmd({ "SessionLoadPost" }, {
        callback = function(p)
            vim.schedule(function()
                main.signal_session_restore_complete()
                local state_ref = helpers.get_state()
                if state_ref and state_ref:is_active_tab_registered() then
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
