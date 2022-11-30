<img src="https://github.com/echasnovski/media/blob/main/mini.nvim/logo/logo_indentscope.png" style="width: 100%"/>

<!-- badges: start -->
[![GitHub license](https://badgen.net/github/license/echasnovski/mini.nvim)](https://github.com/echasnovski/mini.nvim/blob/main/LICENSE)
<!-- badges: end -->

### Visualize and operate on indent scope

- Customizable debounce delay, animation style, and scope computation options.
- Implements scope-related motions and textobjects.

See more details in [Features](#features) and [help file](../doc/mini-indentscope.txt).

---

⦿ This is a part of [mini.nvim](https://github.com/echasnovski/mini.nvim) library. Please use [this link](https://github.com/echasnovski/mini.nvim/blob/main/readmes/mini-indentscope.md) if you want to mention this module.

⦿ All contributions (issues, pull requests, discussions, etc.) are done inside of 'mini.nvim'.

⦿ See the repository page to learn about common design principles and configuration recipes.

---

If you want to help this project grow but don't know where to start, check out [contributing guides of 'mini.nvim'](https://github.com/echasnovski/mini.nvim/blob/main/CONTRIBUTING.md) or leave a Github star for 'mini.nvim' project and/or any its standalone Git repositories.

## Demo

https://user-images.githubusercontent.com/24854248/173044654-f5f0b928-6bd9-4064-a916-1f980044c7ad.mp4

## Features

- Visualize scope with **animated** vertical line. It is very fast and done automatically in a non-blocking way (other operations can be performed, like moving cursor). You can customize debounce delay and animation rule.
- Customization of scope computation options can be done on global level (in `MiniIndentscope.config`), for a certain buffer (using `vim.b.miniindentscope_config` buffer variable), or within a call (using `opts` variable in `MiniIndentscope.get_scope()`).
- Customizable notion of a border: which adjacent lines with strictly lower indent are recognized as such. This is useful for a certain filetypes (for example, Python or plain text).
- Customizable way of line to be considered "border first". This is useful if you want to place cursor on function header and get scope of its body.
- There are textobjects and motions to operate on scope. Support `v:count` and dot-repeat (in operator pending mode).

## Installation

This plugin can be installed as part of 'mini.nvim' library (**recommended**) or as a standalone Git repository.

There are two branches to install from:

- `main` (default, **recommended**) will have latest development version of plugin. All changes since last stable release should be perceived as being in beta testing phase (meaning they already passed alpha-testing and are moderately settled).
- `stable` will be updated only upon releases with code tested during public beta-testing phase in `main` branch.

Here are code snippets for some common installation methods (use only one):

- Using [wbthomason/packer.nvim](https://github.com/wbthomason/packer.nvim):

<table>
    <thead>
        <tr>
            <th>Github repo</th>
            <th>Branch</th> <th>Code snippet</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td rowspan=2>'mini.nvim' library</td>
            <td>Main</td> <td><code>use 'echasnovski/mini.nvim'</code></td>
        </tr>
        <tr>
            <td>Stable</td> <td><code>use { 'echasnovski/mini.nvim', branch = 'stable' }</code></td>
        </tr>
        <tr>
            <td rowspan=2>Standalone plugin</td> <td>Main</td> <td><code>use 'echasnovski/mini.indentscope'</code></td>
        </tr>
        <tr>
            <td>Stable</td> <td><code>use { 'echasnovski/mini.indentscope', branch = 'stable' }</code></td>
        </tr>
    </tbody>
</table>

- Using [junegunn/vim-plug](https://github.com/junegunn/vim-plug):

<table>
    <thead>
        <tr>
            <th>Github repo</th>
            <th>Branch</th> <th>Code snippet</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td rowspan=2>'mini.nvim' library</td>
            <td>Main</td> <td><code>Plug 'echasnovski/mini.nvim'</code></td>
        </tr>
        <tr>
            <td>Stable</td> <td><code>Plug 'echasnovski/mini.nvim', { 'branch': 'stable' }</code></td>
        </tr>
        <tr>
            <td rowspan=2>Standalone plugin</td> <td>Main</td> <td><code>Plug 'echasnovski/mini.indentscope'</code></td>
        </tr>
        <tr>
            <td>Stable</td> <td><code>Plug 'echasnovski/mini.indentscope', { 'branch': 'stable' }</code></td>
        </tr>
    </tbody>
</table>

**Important**: don't forget to call `require('mini.indentscope').setup()` to enable its functionality.

**Note**: if you are on Windows, there might be problems with too long file paths (like `error: unable to create file <some file name>: Filename too long`). Try doing one of the following:
- Enable corresponding git global config value: `git config --system core.longpaths true`. Then try to reinstall.
- Install plugin in other place with shorter path.

## Default config

```lua
-- No need to copy this inside `setup()`. Will be used automatically.
{
  draw = {
    -- Delay (in ms) between event and start of drawing scope indicator
    delay = 100,

    -- Animation rule for scope's first drawing. A function which, given
    -- next and total step numbers, returns wait time (in ms). See
    -- |MiniIndentscope.gen_animation()| for builtin options. To disable
    -- animation, use `require('mini.indentscope').gen_animation('none')`.
    animation = --<function: implements constant 20ms between steps>,
  },

  -- Module mappings. Use `''` (empty string) to disable one.
  mappings = {
    -- Textobjects
    object_scope = 'ii',
    object_scope_with_border = 'ai',

    -- Motions (jump to respective border line; if not present - body line)
    goto_top = '[i',
    goto_bottom = ']i',
  },

  -- Options which control scope computation
  options = {
    -- Type of scope's border: which line(s) with smaller indent to
    -- categorize as border. Can be one of: 'both', 'top', 'bottom', 'none'.
    border = 'both',

    -- Whether to use cursor column when computing reference indent.
    -- Useful to see incremental scopes with horizontal cursor movements.
    indent_at_cursor = true,

    -- Whether to first check input line to be a border of adjacent scope.
    -- Use it if you want to place cursor on function header to get scope of
    -- its body.
    try_as_border = false,
  },

  -- Which character to use for drawing scope indicator
  symbol = '╎',
}
```

## Similar plugins

- [lukas-reineke/indent-blankline.nvim](https://github.com/lukas-reineke/indent-blankline.nvim)
- [michaeljsmith/vim-indent-object](https://github.com/michaeljsmith/vim-indent-object)
