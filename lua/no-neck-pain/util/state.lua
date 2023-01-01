local S = {}

-- Merges the state windows to get a list of ids.
function S.mergeStateWins(main, splits, trees)
    local wins = {}

    for _, side in pairs(main) do
        table.insert(wins, side)
    end

    if splits ~= nil then
        for _, split in pairs(splits) do
            table.insert(wins, split.id)
        end
    end

    if trees ~= nil then
        for _, tree in pairs(trees) do
            table.insert(wins, tree.id)
        end
    end

    return wins
end

-- insert a new split window to the splits internal state list.
function S.insertInSplits(splits, winID, vsplit)
    splits = splits or {}

    table.insert(splits, {
        id = winID,
        vertical = vsplit,
    })

    return splits
end

function S.getNbVerticalSplit(splits)
    local nbVerticalSplit = 0

    for _, split in pairs(splits) do
        if split.vertical then
            nbVerticalSplit = nbVerticalSplit + 1
        end
    end

    return nbVerticalSplit
end

function S.deleteFromSplits(splits, winID) end

return S
