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
    -- Hexadecimal color code to override the current text color of the buffer. (e.g. #7480c2)
    textColor = nil,
    -- vim buffer-scoped options: any `vim.bo` options is accepted here.
    bo = {
        filetype = "no-neck-pain",
        buftype = "nofile",
        bufhidden = "hide",
        modifiable = false,
        buflisted = false,
        swapfile = false,
    },
    -- vim window-scoped options: any `vim.wo` options is accepted here.
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
    --- Common options that are set to both buffers, for option scoped to the `left` and/or `right` buffer, see `buffers.left` and `buffers.right`.
    --- See |NoNeckPain.bufferOptions|.
    buffers = {
        -- When `true`, the side buffers will be named `no-neck-pain-left` and `no-neck-pain-right` respectively.
        setNames = false,
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
        -- Hexadecimal color code to override the current text color of the buffer. (e.g. #7480c2)
        textColor = nil,
        -- vim buffer-scoped options: any `vim.bo` options is accepted here.
        bo = {
            filetype = "no-neck-pain",
            buftype = "nofile",
            bufhidden = "hide",
            modifiable = false,
            buflisted = false,
            swapfile = false,
        },
        -- vim window-scoped options: any `vim.wo` options is accepted here.
        wo = {
            cursorline = false,
            cursorcolumn = false,
            number = false,
            relativenumber = false,
            foldenable = false,
            list = false,
        },
        --- Options applied to the `left` buffer, the options defined here overrides the ones at the root of the `buffers` level.
        --- See |NoNeckPain.bufferOptions|.
        left = NoNeckPain.bufferOptions,
        --- Options applied to the `right` buffer, the options defined here overrides the ones at the root of the `buffers` level.
        --- See |NoNeckPain.bufferOptions|.
        right = NoNeckPain.bufferOptions,
    },
    -- lists supported integrations that might clash with `no-neck-pain.nvim`'s behavior
    integrations = {
        -- https://github.com/nvim-tree/nvim-tree.lua
        NvimTree = {
            -- the position of the tree, can be `left` or `right``
            position = "left",
        },
        -- https://github.com/mbbill/undotree
        undotree = {
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
    NoNeckPain.options = vim.tbl_deep_extend("keep", options, NoNeckPain.options)
    NoNeckPain.options.buffers.left = vim.tbl_deep_extend(
        "keep",
        options.buffers.left or NoNeckPain.options.buffers,
        NoNeckPain.options.buffers.left
    )
    NoNeckPain.options.buffers.right = vim.tbl_deep_extend(
        "keep",
        options.buffers.right or NoNeckPain.options.buffers,
        NoNeckPain.options.buffers.right
    )

    NoNeckPain.options.buffers.backgroundColor =
        C.matchIntegrationToHexCode(NoNeckPain.options.buffers.backgroundColor)
    NoNeckPain.options.buffers.left.backgroundColor = C.matchIntegrationToHexCode(
        NoNeckPain.options.buffers.left.backgroundColor
    ) or NoNeckPain.options.buffers.backgroundColor
    NoNeckPain.options.buffers.right.backgroundColor = C.matchIntegrationToHexCode(
        NoNeckPain.options.buffers.right.backgroundColor
    ) or NoNeckPain.options.buffers.backgroundColor

    NoNeckPain.options.buffers.textColor = NoNeckPain.options.buffers.textColor
        or NoNeckPain.options.buffers.backgroundColor
    NoNeckPain.options.buffers.left.textColor = NoNeckPain.options.buffers.left.textColor
        or NoNeckPain.options.buffers.textColor
        or NoNeckPain.options.buffers.left.backgroundColor
    NoNeckPain.options.buffers.right.textColor = NoNeckPain.options.buffers.right.textColor
        or NoNeckPain.options.buffers.textColor
        or NoNeckPain.options.buffers.right.backgroundColor

    return NoNeckPain.options
end

return NoNeckPain
