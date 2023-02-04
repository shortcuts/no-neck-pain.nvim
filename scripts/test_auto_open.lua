vim.cmd([[let &rtp.=','.getcwd()]])

vim.cmd("set rtp+=deps/mini.nvim")

-- Auto open enabled for the test
require("no-neck-pain").setup({ width = 50, enableOnVimEnter = true, enableOnTabEnter = true })
require("mini.test").setup()
require("mini.doc").setup()
