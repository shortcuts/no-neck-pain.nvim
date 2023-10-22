vim.cmd([[let &rtp.=','.getcwd()]])

vim.cmd("set rtp+=deps/mini.nvim")
vim.cmd("set rtp+=deps/neotest")

require("neotest").setup({
    floating = { max_width = 0.1 },
    strategies = { integrated = { width = 1 } },
})
require("mini.test").setup()
require("no-neck-pain").setup({
    width = 1,
    minSideBufferWidth = 1,
    integrations = { neotest = { reopen = true } },
})
