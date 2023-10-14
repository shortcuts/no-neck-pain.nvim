vim.cmd([[let &rtp.=','.getcwd()]])

vim.cmd("set rtp+=deps/mini.nvim")
vim.cmd("set rtp+=deps/neotest")

require("neotest").setup({})
require("mini.test").setup()
require("no-neck-pain").setup({ width = 30 })
