local A = require("no-neck-pain.util.api")
local D = require("no-neck-pain.util.debug")
local C = require("no-neck-pain.colors")
local Co = require("no-neck-pain.util.constants")

local NoNeckPain = {}

--- NoNeckPain's buffer `vim.wo` options.
--- @see window options `:h vim.wo`
---
---@type table
---Default values:
---@eval return MiniDoc.afterlines_to_code(MiniDoc.current.eval_section)
NoNeckPain.bufferOptionsWo = {
    --- @type boolean
    cursorline = false,
    --- @type boolean
    cursorcolumn = false,
    --- @type string
    colorcolumn = "0",
    --- @type boolean
    number = false,
    --- @type boolean
    relativenumber = false,
    --- @type boolean
    foldenable = false,
    --- @type boolean
    list = false,
    --- @type boolean
    wrap = true,
    --- @type boolean
    linebreak = true,
}

--- NoNeckPain's buffer `vim.bo` options.
--- @see buffer options `:h vim.bo`
---
---@type table
---Default values:
---@eval return MiniDoc.afterlines_to_code(MiniDoc.current.eval_section)
NoNeckPain.bufferOptionsBo = {
    --- @type string
    filetype = "no-neck-pain",
    --- @type string
    buftype = "nofile",
    --- @type string
    bufhidden = "hide",
    --- @type boolean
    buflisted = false,
    --- @type boolean
    swapfile = false,
}

--- NoNeckPain's scratchPad buffer options.
---
--- Leverages the side buffers as notepads, which work like any Neovim buffer and automatically saves its content at the given `location`.
--- note: quitting an unsaved scratchPad buffer is non-blocking, and the content is still saved.
---
---@type table
---Default values:
---@eval return MiniDoc.afterlines_to_code(MiniDoc.current.eval_section)
NoNeckPain.bufferOptionsScratchPad = {
    -- When `true`, automatically sets the following options to the side buffers:
    -- - `autowriteall`
    -- - `autoread`.
    --- @type boolean
    enabled = false,
    -- The name of the generated file. See `location` for more information.
    -- /!\ deprecated /!\ use `pathToFile` instead.
    --- @type string
    --- @example: `no-neck-pain-left.norg`
    --- @deprecated: use `pathToFile` instead.
    fileName = "no-neck-pain",
    -- By default, files are saved at the same location as the current Neovim session.
    -- note: filetype is defaulted to `norg` (https://github.com/nvim-neorg/neorg), but can be changed in `buffers.bo.filetype` or |NoNeckPain.bufferOptions| for option scoped to the `left` and/or `right` buffer.
    -- /!\ deprecated /!\ use `pathToFile` instead.
    --- @type string?
    --- @example: `no-neck-pain-left.norg`
    --- @deprecated: use `pathToFile` instead.
    location = nil,
    -- The path to the file to save the scratchPad content to and load it in the buffer.
    --- @type string?
    --- @example: `~/notes.norg`
    pathToFile = "",
}

--- NoNeckPain's buffer color options.
---
---@type table
---Default values:
---@eval return MiniDoc.afterlines_to_code(MiniDoc.current.eval_section)
NoNeckPain.bufferOptionsColors = {
    -- Hexadecimal color code to override the current background color of the buffer. (e.g. #24273A)
    -- Transparent backgrounds are supported by default.
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
    -- - rose-pine
    -- - rose-pine-dawn
    -- - rose-pine-moon
    -- - tokyonight-day
    -- - tokyonight-moon
    -- - tokyonight-night
    -- - tokyonight-storm
    --- @type string?
    background = nil,
    -- Brighten (positive) or darken (negative) the side buffers background color. Accepted values are [-1..1].
    --- @type integer
    blend = 0,
    -- Hexadecimal color code to override the current text color of the buffer. (e.g. #7480c2)
    --- @type string?
    text = nil,
}

--- NoNeckPain's buffer side buffer option.
---
---@type table
---Default values:
---@eval return MiniDoc.afterlines_to_code(MiniDoc.current.eval_section)
NoNeckPain.bufferOptions = {
    -- When `false`, the buffer won't be created.
    --- @type boolean
    enabled = true,
    --- @see NoNeckPain.bufferOptionsColors `:h NoNeckPain.bufferOptionsColors`
    colors = NoNeckPain.bufferOptionsColors,
    --- @see NoNeckPain.bufferOptionsBo `:h NoNeckPain.bufferOptionsBo`
    bo = NoNeckPain.bufferOptionsBo,
    --- @see NoNeckPain.bufferOptionsWo `:h NoNeckPain.bufferOptionsWo`
    wo = NoNeckPain.bufferOptionsWo,
    --- @see NoNeckPain.bufferOptionsScratchPad `:h NoNeckPain.bufferOptionsScratchPad`
    scratchPad = NoNeckPain.bufferOptionsScratchPad,
}

--- NoNeckPain's plugin config.
---
---@type table
---Default values:
---@eval return MiniDoc.afterlines_to_code(MiniDoc.current.eval_section)
NoNeckPain.options = {
    -- Prints useful logs about triggered events, and reasons actions are executed.
    --- @type boolean
    debug = false,
    -- The width of the focused window that will be centered. When the terminal width is less than the `width` option, the side buffers won't be created.
    --- @type integer|"textwidth"|"colorcolumn"
    width = 100,
    -- Represents the lowest width value a side buffer should be.
    -- This option can be useful when switching window size frequently, example:
    -- in full screen screen, width is 210, you define an NNP `width` of 100, which creates each side buffer with a width of 50. If you resize your terminal to the half of the screen, each side buffer would be of width 5 and thereforce might not be useful and/or add "noise" to your workflow.
    --- @type integer
    minSideBufferWidth = 10,
    -- Adds autocmd (@see `:h autocmd`) which aims at automatically enabling the plugin.
    --- @type table
    autocmds = {
        -- When `true`, enables the plugin when you start Neovim.
        -- If the main window is  a side tree (e.g. NvimTree) or a dashboard, the command is delayed until it finds a valid window.
        -- The command is cleaned once it has successfuly ran once.
        --- @type boolean
        enableOnVimEnter = false,
        -- When `true`, enables the plugin when you enter a new Tab.
        -- note: it does not trigger if you come back to an existing tab, to prevent unwanted interfer with user's decisions.
        --- @type boolean
        enableOnTabEnter = false,
        -- When `true`, deleting the main no-neck-pain buffer with `:bd`, `:bdelete` does not disable the plugin, it fallbacks on the newly focused window and refreshes the state by re-creating side-windows if necessary.
        --- @type boolean
        fallbackOnBufferDelete = true,
        -- When `true`, disabling the plugin closes every other windows except the initially focused one.
        --- @type boolean
        killAllWindowsOnDisable = false,
        -- When `true`, reloads the plugin configuration after a colorscheme change.
        --- @type boolean
        reloadOnColorSchemeChange = false,
        -- When `true`, entering one of no-neck-pain side buffer will automatically skip it and go to the next available buffer.
        --- @type boolean
        skipEnteringNoNeckPainBuffer = false,
    },
    -- Creates mappings for you to easily interact with the exposed commands.
    --- @type table
    mappings = {
        -- When `true`, creates all the mappings that are not set to `false`.
        --- @type boolean
        enabled = false,
        -- Sets a global mapping to Neovim, which allows you to toggle the plugin.
        -- When `false`, the mapping is not created.
        --- @type string
        toggle = "<Leader>np",
        -- Sets a global mapping to Neovim, which allows you to toggle the left side buffer.
        -- When `false`, the mapping is not created.
        --- @type string
        toggleLeftSide = "<Leader>nql",
        -- Sets a global mapping to Neovim, which allows you to toggle the right side buffer.
        -- When `false`, the mapping is not created.
        --- @type string
        toggleRightSide = "<Leader>nqr",
        -- Sets a global mapping to Neovim, which allows you to increase the width (+5) of the main window.
        -- When `false`, the mapping is not created.
        --- @type string | { mapping: string, value: number }
        widthUp = "<Leader>n=",
        -- Sets a global mapping to Neovim, which allows you to decrease the width (-5) of the main window.
        -- When `false`, the mapping is not created.
        --- @type string | { mapping: string, value: number }
        widthDown = "<Leader>n-",
        -- Sets a global mapping to Neovim, which allows you to toggle the scratchPad feature.
        -- When `false`, the mapping is not created.
        --- @type string
        scratchPad = "<Leader>ns",
    },
    --- Common options that are set to both side buffers.
    --- See |NoNeckPain.bufferOptions| for option scoped to the `left` and/or `right` buffer.
    --- @type table
    buffers = {
        -- When `true`, the side buffers will be named `no-neck-pain-left` and `no-neck-pain-right` respectively.
        --- @type boolean
        setNames = false,
        -- Leverages the side buffers as notepads, which work like any Neovim buffer and automatically saves its content at the given `location`.
        -- note: quitting an unsaved scratchPad buffer is non-blocking, and the content is still saved.
        --- see |NoNeckPain.bufferOptionsScratchPad|
        scratchPad = NoNeckPain.bufferOptionsScratchPad,
        -- colors to apply to both side buffers, for buffer scopped options @see |NoNeckPain.bufferOptions|
        --- see |NoNeckPain.bufferOptionsColors|
        colors = NoNeckPain.bufferOptionsColors,
        -- Vim buffer-scoped options: any `vim.bo` options is accepted here.
        --- @see NoNeckPain.bufferOptionsBo `:h NoNeckPain.bufferOptionsBo`
        bo = NoNeckPain.bufferOptionsBo,
        -- Vim window-scoped options: any `vim.wo` options is accepted here.
        --- @see NoNeckPain.bufferOptionsWo `:h NoNeckPain.bufferOptionsWo`
        wo = NoNeckPain.bufferOptionsWo,
        --- Options applied to the `left` buffer, options defined here overrides the `buffers` ones.
        --- @see NoNeckPain.bufferOptions `:h NoNeckPain.bufferOptions`
        left = NoNeckPain.bufferOptions,
        --- Options applied to the `right` buffer, options defined here overrides the `buffers` ones.
        --- @see NoNeckPain.bufferOptions `:h NoNeckPain.bufferOptions`
        right = NoNeckPain.bufferOptions,
    },
    -- Supported integrations that might clash with `no-neck-pain.nvim`'s behavior.
    --- @type table
    integrations = {
        -- By default, if NvimTree is open, we will close it and reopen it when enabling the plugin,
        -- this prevents having the side buffers wrongly positioned.
        -- @link https://github.com/nvim-tree/nvim-tree.lua
        --- @type table
        NvimTree = {
            -- The position of the tree.
            --- @type "left"|"right"
            position = "left",
            -- When `true`, if the tree was opened before enabling the plugin, we will reopen it.
            --- @type boolean
            reopen = true,
        },
        -- By default, if NeoTree is open, we will close it and reopen it when enabling the plugin,
        -- this prevents having the side buffers wrongly positioned.
        -- @link https://github.com/nvim-neo-tree/neo-tree.nvim
        NeoTree = {
            -- The position of the tree.
            --- @type "left"|"right"
            position = "left",
            -- When `true`, if the tree was opened before enabling the plugin, we will reopen it.
            reopen = true,
        },
        -- @link https://github.com/mbbill/undotree
        undotree = {
            -- The position of the tree.
            --- @type "left"|"right"
            position = "left",
        },
        -- @link https://github.com/nvim-neotest/neotest
        neotest = {
            -- The position of the tree.
            --- @type "right"
            position = "right",
            -- When `true`, if the tree was opened before enabling the plugin, we will reopen it.
            reopen = true,
        },
        -- @link https://github.com/nvim-treesitter/playground
        TSPlayground = {
            -- The position of the tree.
            --- @type "right"|"left"
            position = "right",
            -- When `true`, if the tree was opened before enabling the plugin, we will reopen it.
            reopen = true,
        },
        -- @link https://github.com/rcarriga/nvim-dap-ui
        NvimDAPUI = {
            -- The position of the tree.
            --- @type "none"
            position = "none",
            -- When `true`, if the tree was opened before enabling the plugin, we will reopen it.
            reopen = true,
        },
        -- @link https://github.com/hedyhli/outline.nvim
        outline = {
            -- The position of the tree.
            --- @type "left"|"right"
            position = "right",
            -- When `true`, if the tree was opened before enabling the plugin, we will reopen it.
            reopen = true,
        },
        -- @link https://github.com/stevearc/aerial.nvim
        aerial = {
            -- The position of the tree.
            --- @type "left"|"right"
            position = "right",
            -- When `true`, if the tree was opened before enabling the plugin, we will reopen it.
            reopen = true,
        },
    },
}

---@private
local defaults = vim.deepcopy(NoNeckPain.options)

--- Parses the deprecated scratchPad options into the new `pathToFile` option.
---
---@param side "left"|"right" The side of the buffer.
---@param options table Module config table. See |NoNeckPain.bufferOptionsScratchPads|.
---@param fileType string The file extension to leverage.
---
---@private
local function parseDeprecatedScratchPad(side, options, fileType)
    -- set the defaults if the user rely on them
    if A.length(options) == 0 or options.pathToFile == nil then
        options = A.tde(options, defaults.buffers.scratchPad)
    end

    -- handle the deprecation to `fileName` and `location`
    if options.pathToFile == "" then
        if options.location ~= nil then
            options.pathToFile = options.location
        end

        if options.pathToFile ~= "" and string.sub(options.pathToFile, -1) ~= "/" then
            options.pathToFile = options.pathToFile .. "/"
        end

        fileType = fileType or "norg"

        options.pathToFile =
            string.format("%s%s-%s.%s", options.pathToFile, options.fileName, side, fileType)
    end

    return options
end

--- Defaults NoNeckPain options by merging user provided options with the default plugin values.
---
---@param options table Module config table. See |NoNeckPain.options|.
---
---@private
function NoNeckPain.defaults(options)
    options.buffers = options.buffers or {}

    for _, side in pairs(Co.SIDES) do
        options.buffers[side] = options.buffers[side] or {}

        options.buffers[side].bo = A.tde(options.buffers[side].bo, options.buffers.bo)
        options.buffers[side].wo = A.tde(options.buffers[side].wo, options.buffers.wo)
        options.buffers[side].colors = A.tde(options.buffers[side].colors, options.buffers.colors)
        options.buffers[side].scratchPad = parseDeprecatedScratchPad(
            side,
            A.tde(options.buffers[side].scratchPad, options.buffers.scratchPad),
            options.buffers[side].bo.filetype
        )
    end

    NoNeckPain.options = A.tde(options, defaults)
    NoNeckPain.options.buffers = C.parse(NoNeckPain.options.buffers)

    -- assert `width` values through vim options
    if NoNeckPain.options.width == "textwidth" then
        NoNeckPain.options.width = tonumber(vim.api.nvim_buf_get_option(0, "textwidth")) or 0
    end

    if NoNeckPain.options.width == "colorcolumn" then
        NoNeckPain.options.width = tonumber(
            vim.api.nvim_get_option_value("colorcolumn", { scope = "global" })
        ) or 0
    end

    assert(NoNeckPain.options.width > 0, "`width` must be greater than 0.")

    assert(
        NoNeckPain.options.minSideBufferWidth > -1,
        "`minSideBufferWidth` must be equal or greater than 0."
    )

    -- assert `integrations` values
    for _, tree in pairs({ "NvimTree", "NeoTree" }) do
        assert(
            NoNeckPain.options.integrations[tree].position == "left"
                or NoNeckPain.options.integrations[tree].position == "right",
            string.format("%s position can only be `left` or `right`", tree)
        )
    end

    -- cleanup deprecated options to sanitize the saved config
    NoNeckPain.options.buffers.left.scratchPad.location = nil
    NoNeckPain.options.buffers.left.scratchPad.fileName = nil
    NoNeckPain.options.buffers.right.scratchPad.location = nil
    NoNeckPain.options.buffers.right.scratchPad.fileName = nil
    NoNeckPain.options.buffers.scratchPad = nil

    return NoNeckPain.options
end

--- Registers the plugin mappings if the option is enabled.
---
---@param options table The mappins provided by the user.
---@param mappings table A key value map of the mapping name and its command.
---
---@private
local function registerMappings(options, mappings)
    -- all of the mappings are disabled
    if not options.enabled then
        return
    end

    for name, command in pairs(mappings) do
        -- this specific mapping is disabled
        if not options[name] then
            return
        end

        if (name == "widthUp" or name == "widthDown") and type(options[name]) ~= "string" then
            assert(
                type(options[name]) == "table"
                    and options[name]["mapping"] ~= nil
                    and options[name]["value"] ~= nil,
                string.format(
                    "`%s` must be a string or a table with the following properties {mapping: 'your_mapping', value: 5}",
                    name
                )
            )
            vim.api.nvim_set_keymap("n", options[name].mapping, command, { silent = true })
        else
            assert(type(options[name]) == "string", string.format("`%s` must be a string", name))
            vim.api.nvim_set_keymap("n", options[name], command, { silent = true })
        end
    end
end

--- Define your no-neck-pain setup.
---
---@param options table Module config table. See |NoNeckPain.options|.
---
---@usage `require("no-neck-pain").setup()` (add `{}` with your |NoNeckPain.options| table)
function NoNeckPain.setup(options)
    NoNeckPain.options = NoNeckPain.defaults(options or {})

    NoNeckPain.options.hasNvim9 = vim.fn.has("nvim-0.9") == 1

    D.warnDeprecation(NoNeckPain.options)

    registerMappings(NoNeckPain.options.mappings, {
        toggle = ":NoNeckPain<CR>",
        toggleLeftSide = ":NoNeckPainToggleLeftSide<CR>",
        toggleRightSide = ":NoNeckPainToggleRightSide<CR>",
        widthUp = ":NoNeckPainWidthUp<CR>",
        widthDown = ":NoNeckPainWidthDown<CR>",
        scratchPad = ":NoNeckPainScratchPad<CR>",
    })

    return NoNeckPain.options
end

return NoNeckPain
