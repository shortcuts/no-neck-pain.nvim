vim.cmd([[let &rtp.=','.getcwd()]])

vim.cmd("set rtp+=deps/mini.nvim")

-- Auto open enabled for the test
require("no-neck-pain").setup({
    width = 50,
    minSideBufferWidth = 5,
    autocmds = { enableOnVimEnter = true, enableOnTabEnter = true },
    buffers = { colors = { background = "tokyonight-moon" } },
})
require("mini.test").setup()
