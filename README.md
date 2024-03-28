<p align="center">
  <h1 align="center">☕ no-neck-pain.nvim</h2>
</p>

<p align="center">
	Dead simple plugin to center the currently focused buffer to the middle of the screen.
</p>

<div align="center">
  <video src="https://user-images.githubusercontent.com/20689156/215357783-b69f4339-a681-410f-982a-44655986f0ce.mp4"/>
</div>

<div align="center">

_[Alternative GIF showcase video for mobile users](https://github.com/shortcuts/no-neck-pain.nvim/wiki/Showcase#default-configuration-with-splitvsplit-showcase)_

</div>

## ⚡️ Features

_Creates evenly sized empty buffers on each side of your focused buffer, which acts as padding for your window._

- Plug and play, no configuration required
- Seamless experience with your workflow.
- Multiple tabs support
- [Highly customizable experience](https://github.com/shortcuts/no-neck-pain.nvim#configuration)
- [Support split/vsplit windows](https://github.com/shortcuts/no-neck-pain.nvim/wiki/Showcase#window-layout-support)
- [Built-in scratchPad feature](https://github.com/shortcuts/no-neck-pain.nvim/wiki/Showcase#side-buffer-as-scratch-pad)
- [Themed side buffers](https://github.com/shortcuts/no-neck-pain.nvim/wiki/Showcase#custom-background-color)
- Fully integrates with [neo-tree.nvim](https://github.com/nvim-neo-tree/neo-tree.nvim), [nvim-tree.lua](https://github.com/nvim-tree/nvim-tree.lua), [undotree](https://github.com/mbbill/undotree), [tmux, and more!](https://github.com/shortcuts/no-neck-pain.nvim/wiki/Showcase#window-layout-support)
- Keep your workflow intact
- Neovim >= 0.6 support

> Want to see it in action? Take a look at [the showcase section](https://github.com/shortcuts/no-neck-pain.nvim/wiki/Showcase)

## 📋 Installation

<div align="center">
<table>
<thead>
<tr>
<th>Package manager</th>
<th>Snippet</th>
</tr>
</thead>
<tbody>
<tr>
<td>

[wbthomason/packer.nvim](https://github.com/wbthomason/packer.nvim)

</td>
<td>

```lua
-- stable version
use {"shortcuts/no-neck-pain.nvim", tag = "*" }
-- dev version
use {"shortcuts/no-neck-pain.nvim"}
```

</td>
</tr>
<tr>
<td>

[junegunn/vim-plug](https://github.com/junegunn/vim-plug)

</td>
<td>

```lua
-- stable version
Plug 'shortcuts/no-neck-pain.nvim', { 'tag': '*' }
-- dev version
Plug 'shortcuts/no-neck-pain.nvim'
```

</td>
</tr>
<tr>
<td>

[folke/lazy.nvim](https://github.com/folke/lazy.nvim)

</td>
<td>

```lua
-- stable version
require("lazy").setup({{"shortcuts/no-neck-pain.nvim", version = "*"}})
-- dev version
require("lazy").setup({"shortcuts/no-neck-pain.nvim"})
```

</td>
</tr>
</tbody>
</table>
</div>

## 🏗 v1.0.0 breaking changes

See [the release description](https://github.com/shortcuts/no-neck-pain.nvim/pull/201) for the full list of breaking changes.

## ☄ Getting started

No configuration/setup steps needed! Sit back, relax and call `:NoNeckPain`.

## ⚙ Configuration

> **Note**:
> Need some inspiration on customizing your experience? [Take a look at the showcase](https://github.com/shortcuts/no-neck-pain.nvim/wiki/Showcase)

<details>
<summary>Click to unfold the full list of options with their default values</summary>

> **Note**: The options are also available in Neovim by using:
> - `:h NoNeckPain.options` to see the global plugin options.
> - `:h NoNeckPain.bufferOptions` to see the side buffer options.

```lua
require("no-neck-pain").setup({
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
    -- Disables the plugin if the last valid buffer in the list have been closed.
    --- @type boolean
    disableOnLastBuffer = false,
    -- When `true`, disabling the plugin closes every other windows except the initially focused one.
    --- @type boolean
    killAllBuffersOnDisable = false,
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
    },
})

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
    -- The path to the file to save the scratchPad content to and load it in the buffer.
    --- @type string?
    --- @example: `~/notes.norg`
    pathToFile = "",
}

NoNeckPain.bufferOptionsColors = {
    -- Hexadecimal color code to override the current background color of the buffer. (e.g. #24273A)
    -- Transparent backgrounds are supported by default.
    --- @type string?
    background = nil,
    -- Brighten (positive) or darken (negative) the side buffers background color. Accepted values are [-1..1].
    --- @type integer
    blend = 0,
    -- Hexadecimal color code to override the current text color of the buffer. (e.g. #7480c2)
    --- @type string?
    text = nil,
}
```

</details>

## 🧰 Commands

|   Command   |         Description        |
|-------------|----------------------------|
|`:NoNeckPain`| Toggles the plugin state, between enable and disable. |
|`:NoNeckPainResize INT`| Updates the config `width` with the given `INT` value and resizes the no-neck-pain windows. |
|`:NoNeckPainToggleLeftSide`| Toggles the left side buffer (open/close). |
|`:NoNeckPainToggleRightSide`| Toggles the right side buffer (open/close). |
|`:NoNeckPainWidthUp`| Increases the config `width` by 5 and resizes the no-neck-pain windows. |
|`:NoNeckPainWidthDown`| Decreases the config `width` by 5 and resizes the no-neck-pain windows. |

## ⌨ Contributing

PRs and issues are always welcome. Make sure to provide as much context as possible when opening one.

See [Makefile](./Makefile) for the available commends

> You'll need to install [Bob](https://github.com/MordechaiHadad/bob), a useful nvim version manager in order to run the test suite for every supported versions.

## 🗞 Wiki

You can find guides and showcase of the plugin on [the Wiki](https://github.com/shortcuts/no-neck-pain.nvim/wiki)

## 🎭 Motivations

Although there's other (amazing!) alternatives that provide a zen-distraction-free-center mode, they usually make assumptions that might alter your workflow, or at least require some configuration to suit your needs.

`no-neck-pain.nvim` aims at providing a seamless non-opinionated buffer centering experience, while being super customizable.
