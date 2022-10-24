local config = {}

config.options = {
    width = 100,
    enableOnWinEnter = false, -- enable NNP if it's currently disabled on WinEnter 
}

function config.setup(opts)
    config.options = vim.tbl_deep_extend("keep", opts or {}, config.options)
end

return config
