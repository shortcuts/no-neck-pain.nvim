vim.cmd([[let &rtp.=','.getcwd()]])
vim.cmd("set rtp+=deps/mini.nvim")

-- Auto open enabled for the test
require("no-neck-pain").setup({ width = 50, enableOnVimEnter = true })

-- Set up 'mini.test'
require("mini.test").setup()

-- Set up 'mini.doc'
require("mini.doc").setup()
