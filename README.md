<p align="center">
  <h1 align="center">no-neck-pain.nvim</h2>
</p>

<p align="center">
	Dead simple plugin to center the currently focused buffer to the middle of the screen.
</p>

<div align="center">
  <video src="https://user-images.githubusercontent.com/20689156/207925631-deb043f4-4263-4a29-9851-f90558eea228.mp4"/>
</div>

<div align="center">

[GIF version for mobile users](https://github.com/shortcuts/no-neck-pain.nvim/wiki/Showcase#default-configuration-with-splitvsplit-showcase)

</div>

## Introduction

The plugin creates evenly sized empty buffers on each side of your focused buffer, which acts as padding for your nvim window.

<div align="center">

| Before                    | After                     |
|:---------------------------|:---------------------------:|
|`\|current--------------\|`|`\|empty\|current\|empty\|`|

</div>

> thanks to @BerkeleyTrue for the drawing

## Installation

### Using [wbthomason/packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
-- install latest stable version (recommended)
use {"shortcuts/no-neck-pain.nvim", tag = "*" }

-- install unreleased version
use {"shortcuts/no-neck-pain.nvim"}
```

### Using [junegunn/vim-plug](https://github.com/junegunn/vim-plug)

```lua
-- install latest stable version (recommended)
Plug "shortcuts/no-neck-pain.nvim", { "tag": "*" }

-- install unreleased version
Plug "shortcuts/no-neck-pain.nvim"
```

This is all you need! Call `:NoNeckPain` once installed to toggle it.

If you wish to enable the plugin on Neovim start: [-> take a look at the guide <-](https://github.com/shortcuts/no-neck-pain.nvim/wiki/Automate-no-neck-pain-enabling)

## Configuration

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
})

NoNeckPain.bufferOptions = {
    -- When `false`, the buffer won't be created.
    enabled = true,
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
```

## Commands

|   Command   |         Description        |
|-------------|----------------------------|
|`:NoNeckPain`| Toggle the `enabled` state.|

## Contributing

PRs and issues are always welcome. Make sure to provide as much context as possible when opening one.

## Wiki links

- [Automate `no-neck-pain.nvim` enabling](https://github.com/shortcuts/no-neck-pain.nvim/wiki/Automate-%60no-neck-pain.nvim%60-enabling)
  - [When entering Neovim](https://github.com/shortcuts/no-neck-pain.nvim/wiki/Automate-%60no-neck-pain.nvim%60-enabling#when-entering-nvim-vimenter)
  - [With `dashboard-nvim` support](https://github.com/shortcuts/no-neck-pain.nvim/wiki/Automate-%60no-neck-pain.nvim%60-enabling#when-entering-nvim-vimenter)
- [Showcase](https://github.com/shortcuts/no-neck-pain.nvim/wiki/Showcase)
  - [Default configuration](https://github.com/shortcuts/no-neck-pain.nvim/wiki/Showcase#default-configuration-with-splitvsplit-showcase)
  - [Left or right padding only](https://github.com/shortcuts/no-neck-pain.nvim/wiki/Showcase#selective-padding)
  - [Theme blending](https://github.com/shortcuts/no-neck-pain.nvim/wiki/Showcase#selective-padding)
  - [Window resize support](https://github.com/shortcuts/no-neck-pain.nvim/wiki/Showcase#selective-padding)

## Motivations

Although there's other (amazing!) alternatives that provide a zen-distraction-free-center mode, they usually make assumptions that might alter your workflow, or at least require some configuration to suit your needs.

`no-neck-pain.nvim` aims at providing a non-opinionated buffer centering experience, while being super customizable.
