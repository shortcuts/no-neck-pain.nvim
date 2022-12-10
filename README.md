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
use {'shortcuts/no-neck-pain.nvim'}
```

### Using [vim-plug](https://github.com/junegunn/vim-plug)

```lua
Plug 'shortcuts/no-neck-pain.nvim'
```

## Setup

```lua
-- values below are the default
require("no-neck-pain").setup({
    -- the width of the current buffer. If the available screen size is less than `width`,
    -- the buffer will take the whole screen.
    width = 100,
    -- prints useful logs about what event are triggered, and reasons actions are executed.
    debug = false,
    -- only add a left buffer as "padding", which leave all the current buffer expand
    -- to the right of the screen.
    leftPaddingOnly = false,
})
```

## Commands

|   Command   |         Description        |
|-------------|----------------------------|
|`:NoNeckPain`| Toggle the `enabled` state.|

### Enable on VimEnter

> The following snippet will start the plugin after entering NeoVim.

```lua
vim.api.nvim_create_augroup("OnVimEnter", { clear = true })
vim.api.nvim_create_autocmd({ "VimEnter" }, {
	group = "OnVimEnter",
	pattern = "*",
	callback = function()
		vim.schedule(function()
			require("no-neck-pain").start()
		end)
	end,
})
```

## Contributing

PRs and issues are always welcome. Make sure to provide as much context as possible when opening one.

## Motivations

While there's many other (amazing!) plugins that does similar stuff, they all require some configuration or alter your NeoVim workflow.

In my case, I only wanted a plugin that: **center the current buffer**.
