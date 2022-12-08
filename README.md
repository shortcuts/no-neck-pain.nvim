# no-neck-pain.nvim

## Introduction

Dead simple plugin to center the current buffer to the middle of the screen.

## Why an other focus-zen-center-buffer plugin?

While there's many other (amazing!) plugins that does similar stuff, they all require some configuration or alter your NeoVim workflow.

In my case, I only wanted a plugin that: **center the current buffer**.

## Installation

### packer.nvim

```lua
use {'shortcuts/no-neck-pain.nvim'}
```

### vim-plug

```lua
Plug 'shortcuts/no-neck-pain.nvim'
```

## Getting started

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

### Toggle on VimEnter

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
