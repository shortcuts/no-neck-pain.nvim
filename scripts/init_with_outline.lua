vim.cmd([[let &rtp.=','.getcwd()]])

vim.cmd("set rtp+=deps/mini.nvim")
vim.cmd("set rtp+=deps/outline")

require("mini.test").setup()
require("outline").setup()
require("no-neck-pain").setup({
    width = 1,
    minSideBufferWidth = 0,
    integrations = { outline = { reopen = true } },
})
