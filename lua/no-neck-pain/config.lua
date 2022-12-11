local NoNeckPain = {}

--- Plugin config
---
--- Default values:
---@eval return MiniDoc.afterlines_to_code(MiniDoc.current.eval_section)
NoNeckPain.options = {
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
        -- if set to `true`, the side buffers will be named `no-neck-pain-left` and `no-neck-pain-right` respectively.
        showNames = false,
        -- the buffer options when creating the buffer
        options = {
            -- vim.bo buffer scoped options
            bo = {
                filetype = "no-neck-pain",
                buftype = "nofile",
                bufhidden = "hide",
                modifiable = false,
                buflisted = false,
                swapfile = false,
            },
            -- vim.wo window scoped options
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
