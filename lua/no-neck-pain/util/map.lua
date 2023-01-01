local M = {}

-- returns true if the given `map` contains the `element`.
function M.contains(map, element)
    for _, v in pairs(map) do
        if v == element then
            return true
        end
    end

    return false
end

-- returns true if the given `map` contains every `elements`.
function M.every(map, elements)
    local nbElements = M.tsize(elements)
    local count = 0

    for _, v in pairs(map) do
        for _, el in pairs(elements) do
            if v == el then
                count = count + 1
                break
            end
        end
    end

    return count == nbElements
end

-- returns the size of a given `map`.
function M.tsize(map)
    local count = 0

    for _ in pairs(map) do
        count = count + 1
    end

    return count
end

-- insert to a map if it exists or initializes insert
function M.initOrAdd(map, winID, vsplit)
    map = map or {}

    table.insert(map, {
        id = winID,
        vsplit = vsplit,
    })

    return map
end

return M
