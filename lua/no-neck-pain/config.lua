local C = {}

C.options = {
    -- the width of the focused buffer when enabling NNP.
    -- If the available window size is less than `width`, the buffer will take the whole screen.
    width = 100,
    -- prints useful logs about what event are triggered, and reasons actions are executed.
    debug = false,
    -- options related to the side buffers
    buffers = {
        -- if set to `false`, the `left` padding buffer won't be created.
        left = true,
        -- if set to `false`, the `right` padding buffer won't be created.
        right = true,
        -- the buffer options when creating the buffer
        options = {
            bo = {
                filetype = "no-neck-pain",
                buftype = "nofile",
                bufhidden = "hide",
                modifiable = false,
                buflisted = false,
                swapfile = false,
            },
            wo = {
                cursorline = false,
                cursorcolumn = false,
                number = false,
                relativenumber = false,
                foldenable = false,
                list = false,
            },
        },
    },
}

function C.setup(opts)
    C.options = vim.tbl_deep_extend("keep", opts or {}, C.options)

    return C.options
end

return C
