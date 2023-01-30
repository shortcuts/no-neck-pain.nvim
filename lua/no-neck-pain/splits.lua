local Sp = {}

-- returns only the list of registered splits that are still active.
function Sp.refresh(splits)
    if splits == nil then
        return nil
    end

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

-- tries to get all of the active splits on the given tab.
function Sp.get(tab)
    local wins = vim.api.nvim_tabpage_list_wins(tab.id)
    local screenWidth = vim.api.nvim_list_uis()[1].width

    local splits = {}
    local nbSplits = 0

    if tab.wins.splits ~= nil then
        for _, split in pairs(tab.wins.splits) do
            nbSplits = nbSplits + 1
            table.insert(splits, split)
        end
    end

    for _, win in pairs(wins) do
        if
            not vim.tbl_contains(
                { tab.wins.main.curr, tab.wins.main.left, tab.wins.main.right },
                win
            )
        then
            nbSplits = nbSplits + 1
            table.insert(splits, {
                id = win,
                vertical = vim.api.nvim_win_get_width(win) < screenWidth,
            })
        end
    end

    if nbSplits == 0 then
        return nil
    end

    return splits
end

-- returns the total number of vertical splits
function Sp.nbVSplits(splits)
    if splits == nil then
        return 1
    end

    local nbVSplits = 1

    for _, split in pairs(splits) do
        if split.vertical then
            nbVSplits = nbVSplits + 1
        end
    end

    return nbVSplits
end

return Sp
