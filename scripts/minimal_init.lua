vim.cmd([[let &rtp.=','.getcwd()]])

vim.cmd("set rtp+=deps/mini.nvim")

require("mini.test").setup()
require("mini.doc").setup()
require('no-neck-pain').setup({width=50, autocmds = { skipEnteringNoNeckPainBuffer = true }})
