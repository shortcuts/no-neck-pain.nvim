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
    buffers = {
        -- The background options of the side buffer(s).
        background = {
            -- Hexadecimal color code to override the current background color of the buffer. (e.g. #24273A)
            -- popular theme are supported by their name:
            -- - catppuccin-frappe
            -- - catppuccin-latte
            -- - catppuccin-macchiato
            -- - catppuccin-mocha
            -- - tokyonight-day
            -- - tokyonight-moon
            -- - tokyonight-night
            -- - tokyonight-storm
            -- - rose-pine
            -- - rose-pine-moon
            -- - rose-pine-dawn
            colorCode = nil,
        },
        -- When `false`, the `left` padding buffer won't be created.
        left = true,
        -- When `false`, the `right` padding buffer won't be created.
        right = true,
        -- When `true`, the side buffers will be named `no-neck-pain-left` and `no-neck-pain-right` respectively.
        showName = false,
        -- The buffer options when creating the buffer.
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
---@param options table Module config table. See |NoNeckPain.options|.
---
---@usage `require("no-neck-pain").setup()` (add `{}` with your |NoNeckPain.options| table)
function NoNeckPain.setup(options)
    options = vim.tbl_deep_extend("keep", options or {}, NoNeckPain.options)
    options.buffers.background.colorCode =
        C.matchIntegrationToHexCode(options.buffers.background.colorCode)

    NoNeckPain.options = options

    return NoNeckPain.options
end

return NoNeckPain
