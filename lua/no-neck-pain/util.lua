local cfg = require("no-neck-pain.config").options
local M = {}

function M.print(...)
    if cfg.debug then
        print("[debug] " .. os.time() .. ": " .. ...)
    end
end

function M.tprint(map, indent)
    if not cfg.debug then
        return
    end

    if not indent then
        indent = 0
    end
    for k, v in pairs(map) do
        local formatting = string.rep("  ", indent) .. k .. ": "
        if type(v) == "table" then
            print(formatting)
            M.tprint(v, indent + 1)
        elseif type(v) == "boolean" then
            print(formatting .. tostring(v))
        else
            print(formatting .. v)
        end
    end
end

function M.tsize(map)
    local count = 0

    for _ in pairs(map) do
        count = count + 1
    end

    return count
end

return M
