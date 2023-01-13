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
    -- - github-nvim-theme-dark
    -- - github-nvim-theme-dimmed
    -- - github-nvim-theme-light
    -- - tokyonight-day
    -- - tokyonight-moon
    -- - tokyonight-night
    -- - tokyonight-storm
    -- - rose-pine
    -- - rose-pine-moon
    -- - rose-pine-dawn
    backgroundColor = nil,
    -- Brighten (positive) or darken (negative) the side buffers background color. Accepted values are [-1..1].
    blend = 0,
    -- Hexadecimal color code to override the current text color of the buffer. (e.g. #7480c2)
    textColor = nil,
    -- Vim buffer-scoped options: any `vim.bo` options is accepted here.
    bo = {
        filetype = "no-neck-pain",
        buftype = "nofile",
        bufhidden = "hide",
        buflisted = false,
        swapfile = false,
    },
    -- Vim window-scoped options: any `vim.wo` options is accepted here.
    wo = {
        cursorline = false,
        cursorcolumn = false,
        number = false,
        relativenumber = false,
        foldenable = false,
        list = false,
        wrap = true,
        linebreak = true,
    },
}

--- Plugin config
---
--- Default values:
---@eval return MiniDoc.afterlines_to_code(MiniDoc.current.eval_section)
NoNeckPain.options = {
    -- Prints useful logs about what event are triggered, and reasons actions are executed.
    debug = false,
    -- When `true`, enables the plugin when you start Neovim.
    enableOnVimEnter = false,
    -- The width of the focused buffer when enabling NNP.
    -- If the available window size is less than `width`, the buffer will take the whole screen.
    width = 100,
    -- Set globally to Neovim, it allows you to toggle the enable/disable state.
    -- When `false`, the mapping is not created.
    toggleMapping = "<Leader>np",
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
        -- - github-nvim-theme-dark
        -- - github-nvim-theme-dimmed
        -- - github-nvim-theme-light
        -- - tokyonight-day
        -- - tokyonight-moon
        -- - tokyonight-night
        -- - tokyonight-storm
        -- - rose-pine
        -- - rose-pine-moon
        -- - rose-pine-dawn
        backgroundColor = nil,
        -- Brighten (positive) or darken (negative) the side buffers background color. Accepted values are [-1..1].
        blend = 0,
        -- Hexadecimal color code to override the current text color of the buffer. (e.g. #7480c2)
        textColor = nil,
        -- Vim buffer-scoped options: any `vim.bo` options is accepted here.
        bo = {
            filetype = "no-neck-pain",
            buftype = "nofile",
            bufhidden = "hide",
            buflisted = false,
            swapfile = false,
        },
        -- Vim window-scoped options: any `vim.wo` options is accepted here.
        wo = {
            cursorline = false,
            cursorcolumn = false,
            number = false,
            relativenumber = false,
            foldenable = false,
            list = false,
            wrap = true,
            linebreak = true,
        },
        --- Options applied to the `left` buffer, the options defined here overrides the ones at the root of the `buffers` level.
        --- See |NoNeckPain.bufferOptions|.
        left = NoNeckPain.bufferOptions,
        --- Options applied to the `right` buffer, the options defined here overrides the ones at the root of the `buffers` level.
        --- See |NoNeckPain.bufferOptions|.
        right = NoNeckPain.bufferOptions,
    },
    -- Supported integrations that might clash with `no-neck-pain.nvim`'s behavior.
    integrations = {
        -- By default, if NvimTree is open, we will close it and reopen it when enabling the plugin,
        -- this prevents having the side buffers wrongly positioned.
        -- @link https://github.com/nvim-tree/nvim-tree.lua
        NvimTree = {
            -- The position of the tree, either `left` or `right`.
            position = "left",
            -- When `true`, we close NvimTree if it's currently open when enabling the plugin.
            close = true,
            -- Paired with the `close` parameter, when `false` we don't re-open the side tree.
            reopen = true,
        },
        -- @link https://github.com/mbbill/undotree
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

    assert(NoNeckPain.options.width > 0, "`width` must be greater than 0.")

    assert(
        NoNeckPain.options.integrations.NvimTree.position == "left"
            or NoNeckPain.options.integrations.NvimTree.position == "right",
        "NvimTree position can only be `left` or `right`"
    )

    for _, side in pairs({ "left", "right" }) do
        NoNeckPain.options.buffers[side] = vim.tbl_deep_extend(
            "keep",
            options.buffers[side] or NoNeckPain.options.buffers,
            NoNeckPain.options.buffers[side]
        )
    end

    NoNeckPain.options.buffers = C.parseColors(NoNeckPain.options.buffers)

    if NoNeckPain.options.toggleMapping ~= false then
        assert(
            type(NoNeckPain.options.toggleMapping) == "string",
            "`toggleMapping` must be a string"
        )

        vim.api.nvim_set_keymap("n", NoNeckPain.options.toggleMapping, ":NoNeckPain<CR>", {
            silent = true,
        })
    end

    return NoNeckPain.options
end

return NoNeckPain
