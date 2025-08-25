vim.cmd([[let &rtp.=','.getcwd()]])

vim.cmd("set rtp+=deps/mini.nvim")

vim.g.mapleader = ";"

-- Auto open enabled for the test
require("no-neck-pain").setup({
    debug = true,
    width = 50,
    minSideBufferWidth = 5,
    autocmds = { enableOnVimEnter = true, enableOnTabEnter = true },
    mappings = { enabled = true },
    buffers = { right = { enabled = false } },
})
require("mini.test").setup()
