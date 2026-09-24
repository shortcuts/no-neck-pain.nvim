vim.cmd([[let &rtp.=','.getcwd()]])

vim.cmd("set rtp+=deps/mini.nvim")

-- unlike init_auto_open.lua, never call enable(): the VimEnter autocmd must do it
require("no-neck-pain").setup({
    width = 50,
    autocmds = { enableOnVimEnter = true },
})

require("mini.test").setup({ silent = true })
