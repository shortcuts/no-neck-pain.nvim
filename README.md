<p align="center">
  <h1 align="center">no-neck-pain.nvim</h2>
</p>

<p align="center">
	Dead simple plugin to center the currently focused buffer to the middle of the screen.
</p>

<div align="center">
  <video src="https://user-images.githubusercontent.com/20689156/207925631-deb043f4-4263-4a29-9851-f90558eea228.mp4"/>
</div>

## Introduction

The plugin creates evenly sized empty buffers on each side of your focused buffer, which acts as padding for your nvim window.

| Before                    | After                     |
|:---------------------------|:---------------------------:|
|`\|current--------------\|`|`\|empty\|current\|empty\|`|

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

> To see the available options, either call `:h NoNeckPain.options` from Neovim, or [head to the wiki!](https://github.com/shortcuts/no-neck-pain.nvim/blob/main/doc/no-neck-pain.txt#L4)

```lua
require("no-neck-pain").setup({
    -- your custom config goes here
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
