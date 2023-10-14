vim.cmd([[let &rtp.=','.getcwd()]])

vim.cmd("set rtp+=deps/mini.nvim")
vim.cmd("set rtp+=deps/nvimtree")

require("nvim-tree").setup({})
require("mini.test").setup()
require("no-neck-pain").setup({ width = 1, minSideBufferWidth = 0 })
