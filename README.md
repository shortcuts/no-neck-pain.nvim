<p align="center">
  <h1 align="center">☕ no-neck-pain.nvim</h2>
</p>

<p align="center">
	Dead simple plugin to center the currently focused buffer to the middle of the screen.
</p>

<div align="center">
  <video src="https://user-images.githubusercontent.com/20689156/207925631-deb043f4-4263-4a29-9851-f90558eea228.mp4"/>
</div>

<div align="center">

_[GIF version of the showcase video for mobile users](https://github.com/shortcuts/no-neck-pain.nvim/wiki/Showcase#default-configuration-with-splitvsplit-showcase)_

</div>

## ⚡️ Features

_Creates evenly sized empty buffers on each side of your focused buffer, which acts as padding for your window._

- Plug and play, no configuration required
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
Plug "shortcuts/no-neck-pain.nvim", { "tag": "*" }
-- dev version
Plug "shortcuts/no-neck-pain.nvim"
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

This is all you need! Call `:NoNeckPain` once installed to toggle it.

If you wish to enable the plugin on Neovim start: [-> take a look at the guide <-](https://github.com/shortcuts/no-neck-pain.nvim/wiki/Automate-no-neck-pain-enabling)

## ⚙ Configuration

> The options are also available from Neovim, use `:h NoNeckPain.options` to see all the options, and `:h NoNeckPain.bufferOptions` for the buffer ones.

```lua
require("no-neck-pain").setup({
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
})

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
```

## 🧰 Commands

|   Command   |         Description        |
|-------------|----------------------------|
|`:NoNeckPain`| Toggle the `enabled` state.|

## ⌨ Contributing

PRs and issues are always welcome. Make sure to provide as much context as possible when opening one.

## 🗞 Wiki

You can find guides and showcase of the plugin in [our Wiki](https://github.com/shortcuts/no-neck-pain.nvim/wiki)

- [Automate `no-neck-pain.nvim` enabling](https://github.com/shortcuts/no-neck-pain.nvim/wiki/Automate-%60no-neck-pain.nvim%60-enabling)
  - [When entering Neovim](https://github.com/shortcuts/no-neck-pain.nvim/wiki/Automate-%60no-neck-pain.nvim%60-enabling#when-entering-nvim-vimenter)
  - [With `dashboard-nvim` support](https://github.com/shortcuts/no-neck-pain.nvim/wiki/Automate-%60no-neck-pain.nvim%60-enabling#when-entering-nvim-vimenter)
- [Showcase](https://github.com/shortcuts/no-neck-pain.nvim/wiki/Showcase)
  - [Default configuration](https://github.com/shortcuts/no-neck-pain.nvim/wiki/Showcase#default-configuration-with-splitvsplit-showcase)
  - [Left or right padding only](https://github.com/shortcuts/no-neck-pain.nvim/wiki/Showcase#selective-padding)
  - [Theme blending](https://github.com/shortcuts/no-neck-pain.nvim/wiki/Showcase#selective-padding)
  - [Window resize support](https://github.com/shortcuts/no-neck-pain.nvim/wiki/Showcase#selective-padding)

## 〽 Motivations

Although there's other (amazing!) alternatives that provide a zen-distraction-free-center mode, they usually make assumptions that might alter your workflow, or at least require some configuration to suit your needs.

`no-neck-pain.nvim` aims at providing a non-opinionated buffer centering experience, while being super customizable.
