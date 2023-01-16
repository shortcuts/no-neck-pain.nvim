local Sp = {}

-- returns only the list of registered splits that are still active.
function Sp.refresh(splits)
    local actives = {}
    local hasActives = false

    for _, split in pairs(splits) do
        if vim.api.nvim_win_is_valid(split.id) then
            hasActives = true
            table.insert(actives, split)
        end
    end

    if not hasActives then
        return nil
    end

    return actives
end

-- returns the list of registered splits, except the given split `id`.
function Sp.remove(splits, id)
    local remainings = {}
    local hasRemainings = false

    for _, split in pairs(splits) do
        if split.id ~= id then
            hasRemainings = true
            table.insert(remainings, split)
        end
    end

    if not hasRemainings then
        return nil
    end

    return remainings
end

-- insert a new split window to the splits internal state list.
function Sp.insert(splits, winID, vsplit)
    splits = splits or {}

    table.insert(splits, {
        id = winID,
        vertical = vsplit,
    })

    return splits
end

return Sp
