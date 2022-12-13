local NoNeckPain = {}

--- Plugin config
---
--- Default values:
---@eval return MiniDoc.afterlines_to_code(MiniDoc.current.eval_section)
NoNeckPain.options = {
    -- The width of the focused buffer when enabling NNP.
    -- If the available window size is less than `width`, the buffer will take the whole screen.
    width = 100,
    -- Prints useful logs about what event are triggered, and reasons actions are executed.
    debug = false,
    -- Disables NNP if the last valid buffer in the list has been closed.
    disableOnLastBuffer = false,
    -- When `true`, disabling NNP kills every split/vsplit buffers except the main NNP buffer.
    killAllBuffersOnDisable = false,
    -- Options related to the side buffers
    buffers = {
        -- When `false`, the `left` padding buffer won't be created.
        left = true,
        -- When `false`, the `right` padding buffer won't be created.
        right = true,
        -- When `true`, the side buffers will be named `no-neck-pain-left` and `no-neck-pain-right` respectively.
        showName = false,
        -- The buffer options when creating the buffer
        options = {
            -- Buffer-scoped options, below are the default values, but any `vim.bo` options are valid and will be forwarded to the buffer creation.
            bo = {
                filetype = "no-neck-pain",
                buftype = "nofile",
                bufhidden = "hide",
                modifiable = false,
                buflisted = false,
                swapfile = false,
            },
            -- Window-scoped options, below are the default values, but any `vim.wo` options are valid and will be forwarded to the buffer creation.
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

--- Define your no-neck-pain setup.
---
---@param config table Module config table. See |NoNeckPain.config|.
---
---@usage `require("no-neck-pain").setup()` (add `{}` with your `config` table)
function NoNeckPain.setup(config)
    NoNeckPain.options = vim.tbl_deep_extend("keep", config or {}, NoNeckPain.options)

    return NoNeckPain.options
end

return NoNeckPain
