local cfg = {}

cfg = {
    width = 100,
    debug = false,
}

function cfg.setup(opts)
    cfg = vim.tbl_deep_extend("keep", opts or {}, cfg)
end

return cfg
