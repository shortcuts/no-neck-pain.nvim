local options = require("no-neck-pain.config").options
local Util = {}

-- prints only if debug is true.
function Util.print(...)
    if options.debug then
        print("[" .. os.time() .. "] --> ", ...)
    end
end

-- prints table only if debug is true.
function Util.tprint(table, indent)
    if not options.debug then
        return
    end

    if not indent then
        indent = 0
    end

    for k, v in pairs(table) do
        local formatting = string.rep("  ", indent) .. k .. ": "
        if type(v) == "table" then
            print(formatting)
            Util.tprint(v, indent + 1)
        elseif type(v) == "boolean" then
            print(formatting .. tostring(v))
        else
            print(formatting .. v)
        end
    end
end

-- returns the size of a given `map`.
function Util.tsize(map)
    local count = 0

    for _ in pairs(map) do
        count = count + 1
    end

    return count
end

-- returns true if the given `map` contains the element.
function Util.contains(map, el)
    for _, v in pairs(map) do
        if v == el then
            return true
        end
    end

    return false
end

-- returns true if the index 0 window or the current window is relative.
function Util.isRelativeWindow(scope, win)
    win = win or vim.api.nvim_get_current_win()

    if
        vim.api.nvim_win_get_config(0).relative ~= ""
        or vim.api.nvim_win_get_config(win).relative ~= ""
    then
        Util.print(scope, "float window detected")

        return true
    end
end

return Util
