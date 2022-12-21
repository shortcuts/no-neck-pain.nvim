local D = require("no-neck-pain.util.debug")
local W = require("no-neck-pain.util.win")

local E = {}

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
