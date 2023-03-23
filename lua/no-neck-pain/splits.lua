local A = require("no-neck-pain.util.api")
local D = require("no-neck-pain.util.debug")

local Sp = {}

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

---Creates side buffers with the correct padding, considering the side trees.
--- - A side buffer is not created if there's not enough space.
--- - If it already exists, we resize it.
---
---@param tab table: the table where the tab information are stored.
---@param focusedWin number: the id of the current window.
---@return table: the updated tab.
---@return boolean: whether the current window is a vsplit or not.
---@private
function Sp.compute(tab, focusedWin)
    local side = tab.wins.main.left or tab.wins.main.right
    local sWidth, sHeight = 0, 0

    if side ~= nil then
        sWidth, sHeight = A.getWidthAndHeight(side)
        sWidth = vim.api.nvim_list_uis()[1].width - sWidth
    else
        sWidth = vim.api.nvim_list_uis()[1].width
        sHeight = vim.api.nvim_list_uis()[1].height
    end

    D.tprint(tab)

    local fWidth, fHeight = A.getWidthAndHeight(focusedWin)

    local isVSplit = true

    local splitInF = math.floor(sHeight / fHeight)
    if splitInF < 1 then
        splitInF = 1
    end

    if splitInF > tab.layers.split then
        isVSplit = false
    end
    tab.layers.split = splitInF

    local vsplitInF = math.floor(sWidth / fWidth)
    if vsplitInF < 1 then
        vsplitInF = 1
    end

    if vsplitInF > tab.layers.vsplit then
        isVSplit = true
    end
    tab.layers.vsplit = vsplitInF

    D.log(
        "Sp.compute",
        "[split %d | vsplit %d] new split window [H %d W %d / H %d W %d], vertical: %s",
        tab.layers.split,
        tab.layers.vsplit,
        fHeight,
        fWidth,
        sHeight,
        sWidth,
        isVSplit
    )

    return tab, isVSplit
end

---Decreases the layers state values.
---
---@param layers table: the layers state.
---@param isVSplit boolean: whether the window is a vsplit or not.
---@return table: the updated layers state.
---@private
function Sp.decreaseLayers(layers, isVSplit)
    if isVSplit then
        layers.vsplit = layers.vsplit - 1

        return layers
    end

    layers.split = layers.split - 1

    return layers
end

return Sp
