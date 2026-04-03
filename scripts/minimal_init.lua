vim.cmd([[let &rtp.=','.getcwd()]])

vim.cmd("set rtp+=deps/mini.nvim")

require("mini.test").setup({ silent = true })
require("mini.doc").setup()
