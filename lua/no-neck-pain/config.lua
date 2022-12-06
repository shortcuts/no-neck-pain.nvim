local C = {
    options = {
        width = 100,
        debug = false,
    },
}

function C.setup(opts)
    C.options = vim.tbl_deep_extend("keep", opts or {}, C.options)

    return C.options
end

return C
