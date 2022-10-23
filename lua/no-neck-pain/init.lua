local M = {}

function M.start()
    require("no-neck-pain.main").toggle()
end

function M.setup(opts)
    require("no-neck-pain.config").setup(opts)
end

return M
