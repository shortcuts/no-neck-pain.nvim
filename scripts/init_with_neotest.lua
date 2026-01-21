vim.cmd([[let &rtp.=','.getcwd()]])

vim.cmd("set rtp+=deps/mini.nvim")
vim.cmd("set rtp+=deps/plenary")
vim.cmd("set rtp+=deps/nvim-nio")
vim.cmd("set rtp+=deps/fixcursorhold")
vim.cmd("set rtp+=deps/neotest")

require("neotest").setup({
    floating = { max_width = 0.1 },
    strategies = { integrated = { width = 1 } },
})
require("mini.test").setup()
require("no-neck-pain").setup({
    width = 10,
    minSideBufferWidth = 0,
})
