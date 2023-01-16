local D = require("no-neck-pain.util.debug")

local S = {}

-- returns only the list of registered splits that are still active.
function S.refreshSplits(splits)
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

-- returns the list of registered splits without the given split `id`.
function S.removeSplit(splits, id)
    local actives = {}
    local hasActives = false

    for _, split in pairs(splits) do
        if split.id ~= id then
            hasActives = true
            table.insert(actives, split)
        end
    end

    if not hasActives then
        return nil
    end

    return actives
end

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

-- returns `true` if all the state wins are still present in the active wins list.
--
-- @param checkSplits bool: checks for splits wins too when `true`.
function S.stateWinsPresent(state, checkSplits)
    local wins = vim.api.nvim_list_wins()
    local swins = state.main

    if checkSplits and state.splits ~= nil then
        swins = S.mergeStateWins(state.main, state.splits, nil)
    end

    for _, swin in pairs(swins) do
        local found = false

        for _, win in pairs(wins) do
            if swin == win then
                found = true
                break
            end
        end

        if not found then
            return false
        end
    end

    return true
end

return S
