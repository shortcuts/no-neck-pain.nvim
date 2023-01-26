local W = require("no-neck-pain.util.win")

local E = {}

-- skips the event if:
-- - the plugin is not enabled
-- - we have splits open (when `skipSplit` is `true`)
-- - we are focusing a floating window
-- - we are focusing one of the side buffer
function E.skip(state, skipSplit, skipTab)
    if not _G.NoNeckPain.state.enabled then
        return true
    end

    if state ~= nil and skipTab then
        if vim.api.nvim_win_get_tabpage(0) ~= state.tabs then
            return true
        end
    end

    if skipSplit or W.isRelativeWindow() then
        return true
    end

    if state ~= nil then
        local curr = vim.api.nvim_get_current_win()

        if curr == state.wins.main.left or curr == state.wins.main.right then
            return true
        end
    end

    return false
end

return E
