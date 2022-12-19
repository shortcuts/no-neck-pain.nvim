local C = require("no-neck-pain.util.color")

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
    -- Options related to the side buffers.
    -- When `true`, the side buffers will be named `no-neck-pain-left` and `no-neck-pain-right` respectively.
    setBufferNames = false,
    buffers = {
        left = {
            enabled = true,
            -- Hex color for setting the background color of the NNP buffer as well as some other
            -- highlight groups to make it look clean
            backgroundColor = nil,
            -- buffer-scoped options
            -- Note: any `vim.bo` options will work here
            bo = {
                filetype = "no-neck-pain",
                buftype = "nofile",
                bufhidden = "hide",
                modifiable = false,
                buflisted = false,
                swapfile = false
            },
            wo = {
                -- window-scoped options
                -- Note: any `vim.wo` options will work here
                cursorline = false,
                cursorcolumn = false,
                number = false,
                relativenumber = false,
                foldenable = false,
                list = false
            }
        },
        right = {
            enabled = true,
            -- Hex color for setting the background color of the NNP buffer as well as some other
            -- highlight groups to make it look clean
            color = nil,
            bo = {
                -- buffer-scoped options
                -- Note: any `vim.bo` options will work here
                filetype = "no-neck-pain",
                buftype = "nofile",
                bufhidden = "hide",
                modifiable = false,
                buflisted = false,
                swapfile = false
            },
            wo = {
                -- window-scoped options
                -- Note: any `vim.wo` options will work here
                cursorline = false,
                cursorcolumn = false,
                number = false,
                relativenumber = false,
                foldenable = false,
                list = false
            }
        }
    }
}

--- Define your no-neck-pain setup.
---
---@param options table Module config table. See |NoNeckPain.options|.
---
---@usage `require("no-neck-pain").setup()` (add `{}` with your |NoNeckPain.options| table)
function NoNeckPain.setup(options)
    NoNeckPain.options = vim.tbl_deep_extend("keep", options or {}, NoNeckPain.options)

    NoNeckPain.options.buffers.left.color =
        C.matchIntegrationToHexCode(NoNeckPain.options.buffers.left.color)

    NoNeckPain.options.buffers.right.color =
        C.matchIntegrationToHexCode(NoNeckPain.options.buffers.right.color)

    return NoNeckPain.options
end

return NoNeckPain
