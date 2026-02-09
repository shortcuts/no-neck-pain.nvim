--- Utility helpers module for no-neck-pain.nvim
---
--- This module provides helper functions for common patterns used throughout
--- the plugin, including state and config access, validation, and augroup cleanup.
---
---@module "no-neck-pain.util.helpers"

local helpers = {}

local log = require("no-neck-pain.util.log")

--- Gets the complete config table from the global NoNeckPain object.
---
--- @return table | nil The complete config table, or nil if _G.NoNeckPain.config is not set.
---@private
function helpers.get_config()
    if _G.NoNeckPain == nil then
        return nil
    end
    return _G.NoNeckPain.config
end

--- Gets the complete state table from the global NoNeckPain object.
---
--- @return table | nil The complete state table, or nil if _G.NoNeckPain.state is not set.
---@private
function helpers.get_state()
    if _G.NoNeckPain == nil then
        return nil
    end
    return _G.NoNeckPain.state
end

--- Gets a specific field from the config table.
---
--- @param field string The field name to retrieve from config.
--- @return any The value of the config field, or nil if not found or config not initialized.
---@private
function helpers.get_config_field(field)
    local config = helpers.get_config()
    if config == nil then
        return nil
    end
    return config[field]
end

--- Gets a specific field from the state table.
---
--- @param field string The field name to retrieve from state.
--- @return any The value of the state field, or nil if not found or state not initialized.
---@private
function helpers.get_state_field(field)
    local state = helpers.get_state()
    if state == nil then
        return nil
    end
    return state[field]
end

--- Sets the complete config table in the global NoNeckPain object.
---
--- Validates that the config has the required structure (width field exists).
---
--- @param config table The new config table to set.
--- @return boolean True if the config was set successfully, false if validation failed.
---@private
function helpers.set_config(config)
    if config == nil then
        log.warn("helpers", "Cannot set nil config")
        return false
    end

    if _G.NoNeckPain == nil then
        log.warn("helpers", "_G.NoNeckPain is not initialized")
        return false
    end

    -- Validate config structure
    if config.width == nil then
        log.warn("helpers", "Invalid config: missing 'width' field")
        return false
    end

    -- Validate width type
    local width_type = type(config.width)
    if width_type ~= "number" and width_type ~= "string" then
        log.warn("helpers", "Invalid config: 'width' must be number or string, got %s", width_type)
        return false
    end

    _G.NoNeckPain.config = config
    return true
end

--- Sets the complete state table in the global NoNeckPain object.
---
--- Validates that the state has the required structure (enabled field exists and is boolean).
---
--- @param state table The new state table to set.
--- @return boolean True if the state was set successfully, false if validation failed.
---@private
function helpers.set_state(state)
    if state == nil then
        log.warn("helpers", "Cannot set nil state")
        return false
    end

    if _G.NoNeckPain == nil then
        log.warn("helpers", "_G.NoNeckPain is not initialized")
        return false
    end

    -- Validate state structure
    if state.enabled == nil then
        log.warn("helpers", "Invalid state: missing 'enabled' field")
        return false
    end

    if type(state.enabled) ~= "boolean" then
        log.warn("helpers", "Invalid state: 'enabled' must be boolean, got %s", type(state.enabled))
        return false
    end

    _G.NoNeckPain.state = state
    return true
end

--- Merges the provided config updates into the existing config table.
---
--- Uses vim.tbl_deep_extend with "force" strategy to merge the update into the existing config.
--- Validates the merged result before assignment.
---
--- @param updates table The config fields to merge/update.
--- @return boolean True if the merge was successful, false if validation failed.
---@private
function helpers.merge_config(updates)
    if updates == nil then
        log.warn("helpers", "Cannot merge nil config updates")
        return false
    end

    local current_config = helpers.get_config()
    if current_config == nil then
        log.warn("helpers", "Current config is not initialized, cannot merge")
        return false
    end

    -- Perform deep merge
    local merged_config = vim.tbl_deep_extend("force", current_config, updates)

    -- Validate the merged result
    return helpers.set_config(merged_config)
end

--- Ensures the plugin config is loaded and initialized.
---
--- If the global config is not set, it initializes it with the provided
--- config module's options. This prevents redundant initialization and
--- ensures consistent config state across the plugin.
---
---@param config_module table The config module with an `options` field
---@return nil
---@see NoNeckPain.config
---@private
function helpers.ensure_config_loaded(config_module)
    if _G.NoNeckPain.config == nil then
        helpers.set_config(config_module.options)
    end
end

--- Ensures the plugin is currently enabled before proceeding.
---
--- Validates that the plugin state exists and is enabled. Throws an error
--- with a helpful message if the plugin is not enabled, guiding the user
--- to enable it via the `:NoNeckPain` command.
---
---@return nil
---@throws "no-neck-pain.nvim must be enabled, run `NoNeckPain` first."
---@see NoNeckPain.state
---@private
function helpers.ensure_plugin_enabled()
    if _G.NoNeckPain.state == nil or not _G.NoNeckPain.state.enabled then
        error("no-neck-pain.nvim must be enabled, run `NoNeckPain` first.")
    end
end

--- Safely deletes an augroup by name without raising errors.
---
--- Uses pcall to wrap vim.api.nvim_del_augroup_by_name so that attempting
--- to delete a non-existent augroup does not cause an error. This is useful
--- for cleanup operations where the augroup may or may not exist.
---
---@param name string The name of the augroup to delete
---@return nil
---@see vim.api.nvim_del_augroup_by_name
---@private
function helpers.safe_delete_augroup(name)
    pcall(vim.api.nvim_del_augroup_by_name, name)
end

return helpers
