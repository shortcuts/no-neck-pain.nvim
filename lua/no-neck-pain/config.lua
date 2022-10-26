local config = {}

config.options = {
    width = 100,
}

function config.setup(opts)
    config.options = vim.tbl_deep_extend("keep", opts or {}, config.options)
end

return config
