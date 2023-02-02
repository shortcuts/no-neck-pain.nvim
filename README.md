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
- [Themed side buffers](https://github.com/shortcuts/no-neck-pain.nvim/wiki/Showcase#custom-background-color)
- [Support split/vsplit windows](https://github.com/shortcuts/no-neck-pain.nvim/wiki/Showcase#window-layout-support)
- [Fully integrates with side trees, tmux, and more!](https://github.com/shortcuts/no-neck-pain.nvim/wiki/Showcase#window-layout-support)
- Keep your workflow intact
- Neovim >= 0.5 support

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
    debug = false,
    -- When `true`, enables the plugin when you start Neovim.
    enableOnVimEnter = false,
    -- The width of the focused window that will be centered:
    -- - Any integer > 0 is accepted.
    -- When the terminal width is less than the `width` option, the side buffers won't be created.
    width = 100,
    -- Sets a global mapping to Neovim, which allows you to toggle the plugin.
    -- When `false`, the mapping is not created.
    toggleMapping = "<Leader>np",
    -- Disables the plugin if the last valid buffer in the list have been closed.
    disableOnLastBuffer = false,
    -- When `true`, disabling the plugin closes every other windows except the initially focused one.
    killAllBuffersOnDisable = false,
    --- Common options that are set to both side buffers.
    --- See |NoNeckPain.bufferOptions| for option scoped to the `left` and/or `right` buffer.
    buffers = {
        -- When `true`, the side buffers will be named `no-neck-pain-left` and `no-neck-pain-right` respectively.
        setNames = false,
        -- Leverages the side buffers as notepads, which work like any Neovim buffer and automatically save the content at the given `location`.
        -- note: quitting an unsaved scratchpad buffer is non-blocking.
        scratchPad = {
            -- When `true`, automatically sets the following options to the side buffers:
            -- - `autowriteall`
            -- - `autoread`.
            enabled = false,
            -- The name of the generated file. See `location` for more information.
            -- @example: `no-neck-pain-left.norg`
            fileName = "no-neck-pain",
            -- By default, files are saved at the same location as the current Neovim session.
            -- note: filetype is defaulted to `norg` (https://github.com/nvim-neorg/neorg), but can be changed from the buffer options globally `buffers.bo.filetype` or see |NoNeckPain.bufferOptions| for option scoped to the `left` and/or `right` buffer.
            -- @example: `no-neck-pain-left.norg`
            location = nil,
        },
        -- Hexadecimal color code to override the current background color of the buffer. (e.g. #24273A)
        -- Transparent backgrounds are supported by default.
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
            -- When `true`, if the tree was opened before enabling the plugin, we will reopen it.
            reopen = true,
        },
        -- @link https://github.com/mbbill/undotree
        undotree = {
            -- The position of the tree, either `left` or `right`.
            position = "left",
        },
    },
})

NoNeckPain.bufferOptions = {
    -- When `false`, the buffer won't be created.
    enabled = true,
    -- Hexadecimal color code to override the current background color of the buffer. (e.g. #24273A)
    -- Transparent backgrounds are supported by default.
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
```

</details>

## 🧰 Commands

|   Command   |         Description        |
|-------------|----------------------------|
|`:NoNeckPain`| Toggles the plugin state, between enable and disable. |
|`:NoNeckPainResize INT`| Updates the config `width` with the given `INT` value and resizes the no-neck-pain windows. |

## ⌨ Contributing

PRs and issues are always welcome. Make sure to provide as much context as possible when opening one.

## 🗞 Wiki

You can find guides and showcase of the plugin on [the Wiki](https://github.com/shortcuts/no-neck-pain.nvim/wiki)

## 🎭 Motivations

Although there's other (amazing!) alternatives that provide a zen-distraction-free-center mode, they usually make assumptions that might alter your workflow, or at least require some configuration to suit your needs.

`no-neck-pain.nvim` aims at providing a seamless non-opinionated buffer centering experience, while being super customizable.
