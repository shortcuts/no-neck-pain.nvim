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

---Determines current state of the split/vsplit windows by comparing widths and heights.
---
---@param tab table: the table where the tab information are stored.
---@param focusedWin number: the id of the current window.
---@return table: the updated tab.
---@return boolean: whether the current window is a vsplit or not.
---@private
function Sp.compute(tab, focusedWin)
    local side = tab.wins.main.left or tab.wins.main.right
    local sWidth, sHeight = 0, 0

    -- when side buffer exists we rely on them, otherwise we fallback to the UI
    if side ~= nil then
        local nbSide = 1

        if A.hasSide(tab, "left") and A.hasSide(tab, "right") then
            nbSide = 2
        end

        sWidth, sHeight = A.getWidthAndHeight(side)
        sWidth = vim.api.nvim_list_uis()[1].width - sWidth * nbSide
    else
        sWidth = vim.api.nvim_list_uis()[1].width
        sHeight = vim.api.nvim_list_uis()[1].height
    end

    local fWidth, fHeight = A.getWidthAndHeight(focusedWin)
    local isVSplit = true

    local splitInF = math.floor(sHeight / fHeight)
    if splitInF < 1 then
        splitInF = 1
    end

    if splitInF > tab.layers.split then
        isVSplit = false
    end

    local vsplitInF = math.floor(sWidth / fWidth)
    if vsplitInF < 1 then
        vsplitInF = 1
    end

    if vsplitInF > tab.layers.vsplit then
        isVSplit = true
    end

    -- update anyway because we want state consistency
    tab.layers.split = splitInF
    tab.layers.vsplit = vsplitInF

    D.log(
        "Sp.compute",
        "[split %d | vsplit %d] new split, vertical: %s",
        tab.layers.split,
        tab.layers.vsplit,
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

        if layers.vsplit < 1 then
            layers.vsplit = 1
        end

        return layers
    end

    layers.split = layers.split - 1

    if layers.split < 1 then
        layers.split = 1
    end

    return layers
end

return Sp
