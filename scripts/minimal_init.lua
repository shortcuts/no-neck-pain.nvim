vim.cmd([[let &rtp.=','.getcwd()]])

vim.cmd("set rtp+=deps/mini.nvim")

-- require('no-neck-pain').setup({width=50})
require("mini.test").setup()
require("mini.doc").setup()
