local A = require("no-neck-pain.util.api")
local Co = require("no-neck-pain.util.constants")
local S = require("no-neck-pain.state")

local E = {}

function E.skip()
    if not S.isActiveTabValid(S) then
        return true
    end

    if A.isRelativeWindow() then
        return true
    end

    if A.getCurrentTab() ~= S.getActiveTab(S) then
        return true
    end
end

--- determines if we should skip the enabling of the plugin:
---  1. if a tab definition already exists in the state
---  2. if we are focusing a relative window
---  3. if we are focusing a side tree or a dashboard
--- - the plugin is not enabled
--- - we have splits open (when `skipSplit` is `true`)
--- - we are focusing a floating window
--- - we are focusing one of the side buffer
---
---@private
function E.skipEnable()
    if S.isActiveTabRegistered(S) then
        return true
    end

    if A.isRelativeWindow() then
        return true
    end

    -- dashboards delays the plugin enable step until next buffer entered
    if vim.tbl_contains(Co.DASHBOARDS, vim.bo.filetype) then
        return true
    end

    return S.isSupportedIntegration(S, "E.skipEnable", nil)
end

return E
