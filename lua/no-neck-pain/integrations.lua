local S = require("no-neck-pain.state")

local T = {}

---Closes side integrations if opened.
---
---@return table: the integrations mapping with a boolean set to true, if we closed one of them.
---@private
function T.close()
    local tab = S.getTab(S)

    for _, opts in pairs(tab.wins.integrations) do
        if opts.id ~= nil and opts.close ~= nil then
            vim.cmd(opts.close)
        end
    end

    return tab.wins.integrations
end

---Reopens the integrations if they were previously closed.
---
---@param integrations table: the integrations mappings with their associated boolean value, `true` if we closed it previously.
---@private
function T.reopen(integrations)
    for _, opts in pairs(integrations) do
        if
            opts.id ~= nil
            and opts.open ~= nil
            and _G.NoNeckPain.config.integrations[opts.configName].reopen == true
        then
            vim.cmd(opts.open)
        end
    end
end

return T
