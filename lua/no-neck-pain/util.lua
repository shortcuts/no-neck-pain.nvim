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

-- returns the buffers without the NNP ones, and their number.
function Util.bufferListWithoutNNP(scope, nnpBuffers)
    local buffers = vim.api.nvim_list_wins()
    local validBuffers = {}
    local size = 0

    for _, buffer in pairs(buffers) do
        if
            buffer ~= nnpBuffers.curr
            and buffer ~= nnpBuffers.left
            and buffer ~= nnpBuffers.right
            and not Util.isRelativeWindow(scope, buffer)
        then
            table.insert(validBuffers, buffer)
            size = size + 1
        end
    end

    return validBuffers, size
end

-- returns true if the given `map` contains the `element`.
function Util.contains(map, element)
    for _, v in pairs(map) do
        if v == element then
            return true
        end
    end

    return false
end

-- returns true if the given `map` contains every `elements`.
function Util.every(map, ...)
    local nbElements = Util.tsize(...)
    local count = 0

    for _, v in pairs(map) do
        for _, el in pairs(...) do
            if v == el then
                count = count + 1
                break
            end
        end
    end

    return count == nbElements
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

-- closes a window if it exists and is valid.
function Util.close(win)
    if win ~= nil and vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
    end
end

return Util
