local W = require("no-neck-pain.util.win")

local E = {}

-- skips the event if:
-- - the plugin is not enabled
-- - we have splits open (when `skipSplit` is `true`)
-- - we are focusing a floating window
-- - we are focusing one of the side buffer
function E.skip(tab, skipSplit)
    if not _G.NoNeckPain.state.enabled then
        return true
    end

    if skipSplit or W.isRelativeWindow() then
        return true
    end

    if tab ~= nil then
        if vim.api.nvim_win_get_tabpage(0) ~= tab.id then
            return true
        end

        local curr = vim.api.nvim_get_current_win()

        if curr == tab.wins.main.left or curr == tab.wins.main.right then
            return true
        end
    end

    return false
end

return E
