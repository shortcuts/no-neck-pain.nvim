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
})
```

### Toggle on WinEnter

The snippet below will start NNP on WinEnter event

```lua
-- enables NNP on WinEnter if it's not the case yet
vim.api.nvim_create_augroup("OnWinEnter", { clear = true })
vim.api.nvim_create_autocmd({ "WinEnter" }, {
	group = "OnWinEnter",
	pattern = "*",
	callback = function()
        require("no-neck-pain").start()
	end,
})
```
