local D = require("no-neck-pain.util.debug")

local Ta = {}

-- returns the current tabpage.
function Ta.refresh(curr)
    local new = vim.api.nvim_win_get_tabpage(0)

    if curr == new then
        return curr
    end

    D.log("Ta.refresh", "new tab page registered: was %d, now %d", curr, new)

    return new
end

return Ta
