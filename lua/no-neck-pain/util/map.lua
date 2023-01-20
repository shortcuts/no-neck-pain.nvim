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

return M
