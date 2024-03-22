vim.cmd([[let &rtp.=','.getcwd()]])

vim.cmd("set rtp+=deps/mini.nvim")
vim.cmd("set rtp+=deps/nvim-nio")
vim.cmd("set rtp+=deps/nvimdap")
vim.cmd("set rtp+=deps/nvimdapui")

require("dapui").setup()
require("mini.test").setup()
require("no-neck-pain").setup({
    width = 1,
    minSideBufferWidth = 0,
    integrations = { NvimDAPUI = { reopen = true } },
})
