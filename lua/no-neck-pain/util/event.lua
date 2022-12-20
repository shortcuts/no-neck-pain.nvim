local D = require("no-neck-pain.util.debug")
local W = require("no-neck-pain.util.win")

local E = {}

-- determines if we should skip the event.
function E.skip(scope, enabled, split)
    if not enabled then
        D.print(scope, "event received but NNP is disabled")

        return true
    end

    if split ~= nil or W.isRelativeWindow() then
        D.print(scope, "already in split view or float window detected, nothing more to do")

        return true
    end

    return false
end

return E
