vim.cmd([[let &rtp.=','.getcwd()]])

vim.cmd("set rtp+=deps/mini.nvim")

require("mini.test").setup()
require("mini.doc").setup()
