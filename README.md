# no-neck-pain.nvim

Dead simple plugin to center the currently focused buffer to the middle of the screen.

![Preview](https://i.imgur.com/gOSvAdh.gif)

## Introduction

The plugin creates evenly sized empty buffers on each side of your focused buffer, which acts as padding for your nvim window.

| Before                    | After                     |
|---------------------------|---------------------------|
|`\|current--------------\|`|`\|empty\|current\|empty\|`|

> thanks to @BerkeleyTrue for the drawing

## Installation

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
-- install latest stable version (recommended)
use {"shortcuts/no-neck-pain.nvim", tag = "*" }

-- install unreleased version
use {"shortcuts/no-neck-pain.nvim"}
```

### Using [vim-plug](https://github.com/junegunn/vim-plug)

```lua
-- install latest stable version (recommended)
Plug "shortcuts/no-neck-pain.nvim" , { "tag": "*" }

-- install unreleased version
Plug "shortcuts/no-neck-pain.nvim"
```

## Setup

```lua
-- values below are the default
require("no-neck-pain").setup({
    -- the width of the focused buffer when enabling NNP.
    -- If the available window size is less than `width`, the buffer will take the whole screen.
    width = 100,
    -- prints useful logs about what event are triggered, and reasons actions are executed.
    debug = false,
    -- options related to the side buffers
    buffers = {
        -- if set to `false`, the `left` padding buffer won't be created.
        left = true,
        -- if set to `false`, the `right` padding buffer won't be created.
        right = true,
        -- if set to `true`, the side buffers will be named `no-neck-pain-left` and `no-neck-pain-right` respectively.
        showNames = false,
        -- the buffer options when creating the buffer
        options = {
            bo = {
                filetype = "no-neck-pain",
                buftype = "nofile",
                bufhidden = "hide",
                modifiable = false,
                buflisted = false,
                swapfile = false,
            },
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
})
```

## Commands

|   Command   |         Description        |
|-------------|----------------------------|
|`:NoNeckPain`| Toggle the `enabled` state.|

## Wiki links

- [automate `no-neck-pain` startup](https://github.com/shortcuts/no-neck-pain.nvim/wiki/Automate-no-neck-pain-enabling)
- [showcase](https://github.com/shortcuts/no-neck-pain.nvim/wiki/Showcase)

## Contributing

PRs and issues are always welcome. Make sure to provide as much context as possible when opening one.

## Motivations

While there's many other (amazing!) plugins that does similar stuff, they all require some configuration or alter your NeoVim workflow.

In my case, I only wanted a plugin that: **center the current buffer**.
