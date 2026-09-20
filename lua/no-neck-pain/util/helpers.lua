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

--- Matches a filetype against the configured integrations.
---
--- The `dashboard` integration is matched through its `filetypes` list; every
--- other integration is matched on its (lowercased) config key. Applies no
--- `position` policy: callers decide what to do with `position == "none"`.
---
---@param filetype string?: the filetype to match, any case.
---@return string?: the lowercased integration name, nil when no match.
---@return table?: the matched integration config, nil when no match.
---@private
function helpers.match_integration(filetype)
    if filetype == nil or filetype == "" then
        return nil
    end

    local integrations = _G.NoNeckPain.config.integrations
    if integrations == nil then
        return nil
    end

    local ft = string.lower(filetype)

    for key, opts in pairs(integrations) do
        local name = string.lower(key)
        if name == "dashboard" then
            for _, dashboard_ft in ipairs(opts.filetypes or {}) do
                if ft == string.lower(dashboard_ft) then
                    return name, opts
                end
            end
        elseif name == ft or string.find(ft, name, 1, true) then
            return name, opts
        end
    end

    return nil
end

--- Whether the given filetype is an integration that affects the layout.
---
--- `position == "none"` integrations (oil, dap) are excluded: they don't take
--- a side, so they must not stop the plugin from enabling.
---
---@param filetype string?: the filetype to check (typically from vim.bo.filetype).
---@return boolean: whether the filetype is a layout-affecting integration.
---@private
function helpers.is_filetype_integration(filetype)
    local _, opts = helpers.match_integration(filetype)

    return opts ~= nil and opts.position ~= "none"
end

return helpers
