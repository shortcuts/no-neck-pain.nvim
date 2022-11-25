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
    width = 100, -- the size of the main buffer
    debug = false, -- prints some debugging logs on events when switching buffers/windows
})
```

### Toggle on VimEnter

The snippet below will start NNP when opening neovim

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
