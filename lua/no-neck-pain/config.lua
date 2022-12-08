local C = {}

C.options = {
    -- the width of the current buffer. If the available screen size is less than `width`,
    -- the buffer will take the whole screen.
    width = 100,
    -- prints useful logs about what event are triggered, and reasons actions are executed.
    debug = false,
    -- only add a left buffer as "padding", which leave all the current buffer expand
    -- to the right of the screen.
    leftPaddingOnly = false,
}

function C.setup(opts)
    C.options = vim.tbl_deep_extend("keep", opts or {}, C.options)

    return C.options
end

return C
