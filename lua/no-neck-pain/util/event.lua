local D = require("no-neck-pain.util.debug")
local W = require("no-neck-pain.util.win")

local E = {}

-- abortEnable ensure we don't proceed the `enable` method
-- in the `enableOnVimEnter` hooks. It exists to prevent
-- conflicts with other plugins:
-- netrw: it works
-- dashboard: we skip until we open an other buffer
-- nvim-tree: we skip until we open an other buffer
function E.abortEnable(state, filetype)
    if state ~= nil and state.enabled == true then
        return true
    end

    if filetype == "dashboard" or filetype == "NvimTree" then
        return true
    end

    return false
end

-- determines if we should skip the event.
function E.skip(scope, enabled, split)
    if not enabled then
        return true
    end

    if split ~= nil or W.isRelativeWindow() then
        D.log(scope, "already in split view or float window detected, skipped")

        return true
    end

    return false
end

return E
