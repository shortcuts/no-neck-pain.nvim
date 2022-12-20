local C = require("no-neck-pain.util.color")

local NoNeckPain = {}

--- NoNeckPain buffer options
---
--- Default values:
---@eval return MiniDoc.afterlines_to_code(MiniDoc.current.eval_section)
NoNeckPain.bufferOptions = {
    -- When `false`, the buffer won't be created.
    enabled = true,
    -- Hexadecimal color code to override the current background color of the buffer. (e.g. #24273A)
    -- popular theme are supported by their name:
    -- - catppuccin-frappe
    -- - catppuccin-frappe-dark
    -- - catppuccin-latte
    -- - catppuccin-latte-dark
    -- - catppuccin-macchiato
    -- - catppuccin-macchiato-dark
    -- - catppuccin-mocha
    -- - catppuccin-mocha-dark
    -- - tokyonight-day
    -- - tokyonight-moon
    -- - tokyonight-night
    -- - tokyonight-storm
    -- - rose-pine
    -- - rose-pine-moon
    -- - rose-pine-dawn
    backgroundColor = nil,
    -- buffer-scoped options: any `vim.bo` options is accepted here.
    bo = {
        filetype = "no-neck-pain",
        buftype = "nofile",
        bufhidden = "hide",
        modifiable = false,
        buflisted = false,
        swapfile = false,
    },
    -- window-scoped options: any `vim.wo` options is accepted here.
    wo = {
        cursorline = false,
        cursorcolumn = false,
        number = false,
        relativenumber = false,
        foldenable = false,
        list = false,
    },
}

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
    --- Options related to the side buffers. See |NoNeckPain.bufferOptions|.
    buffers = {
        -- When `true`, the side buffers will be named `no-neck-pain-left` and `no-neck-pain-right` respectively.
        setNames = false,
        -- Common options are set to both buffers, for option scoped to the `left` and/or `right` buffer, see `buffers.left` and `buffers.right`.
        common = NoNeckPain.bufferOptions,
        --- Options applied to the `left` buffer, the options defined here overrides the `common` ones.
        --- When `nil`, the buffer won't be created.
        left = NoNeckPain.bufferOptions,
        --- Options applied to the `left` buffer, the options defined here overrides the `common` ones.
        --- When `nil`, the buffer won't be created.
        right = NoNeckPain.bufferOptions,
    },
    -- lists supported integrations that might clash with `no-neck-pain.nvim`'s behavior
    integrations = {
        -- https://github.com/nvim-tree/nvim-tree.lua
        nvimTree = {
            -- the position of the tree, can be `left` or `right``
            position = "left",
        },
    },
}

--- Define your no-neck-pain setup.
---
---@param options table Module config table. See |NoNeckPain.options|.
---
---@usage `require("no-neck-pain").setup()` (add `{}` with your |NoNeckPain.options| table)
function NoNeckPain.setup(options)
    options = options or {}
    options.buffers = options.buffers or {}
    options.buffers.common =
        vim.tbl_deep_extend("keep", options.buffers.common or {}, NoNeckPain.options.buffers.common)
    options.buffers.left = vim.tbl_deep_extend(
        "keep",
        options.buffers.left or options.buffers.common,
        NoNeckPain.options.buffers.left
    )
    options.buffers.right = vim.tbl_deep_extend(
        "keep",
        options.buffers.right or options.buffers.common,
        NoNeckPain.options.buffers.right
    )
    NoNeckPain.options = vim.tbl_deep_extend("keep", options or {}, NoNeckPain.options)

    NoNeckPain.options.buffers.common.backgroundColor =
        C.matchIntegrationToHexCode(NoNeckPain.options.buffers.common.backgroundColor)
    NoNeckPain.options.buffers.left.backgroundColor = C.matchIntegrationToHexCode(
        NoNeckPain.options.buffers.left.backgroundColor
    ) or NoNeckPain.options.buffers.common.backgroundColor
    NoNeckPain.options.buffers.right.backgroundColor = C.matchIntegrationToHexCode(
        NoNeckPain.options.buffers.right.backgroundColor
    ) or NoNeckPain.options.buffers.common.backgroundColor

    return NoNeckPain.options
end

return NoNeckPain
