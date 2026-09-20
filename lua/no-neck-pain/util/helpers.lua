--- Utility helpers module for no-neck-pain.nvim
---
--- This module provides helper functions for augroup cleanup, plugin-state
--- validation and integration filetype matching.
---
---@module "no-neck-pain.util.helpers"

local helpers = {}

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

--- Checks if a given filetype matches any configured integration.
---
--- Iterates through the integrations config to determine if the filetype is:
--- - A dashboard filetype (from the dashboard integration array)
--- - A regular integration (string match on the key)
---
--- Returns false for integrations with position "none" (they don't affect layout).
---
--- @param filetype string The filetype to check (typically from vim.bo.filetype)
--- @return boolean True if filetype matches an integration, false otherwise
---@private
function helpers.is_filetype_integration(filetype)
    if filetype == "" or filetype == nil then
        return false
    end

    for key, integration_config in pairs(_G.NoNeckPain.config.integrations) do
        if key == "dashboard" then
            if integration_config.filetypes ~= nil then
                for _, ftype in ipairs(integration_config.filetypes) do
                    if filetype == string.lower(ftype) then
                        return true
                    end
                end
            end
        else
            if
                string.find(filetype, string.lower(key))
                and integration_config.position ~= "none"
            then
                return true
            end
        end
    end

    return false
end

return helpers
