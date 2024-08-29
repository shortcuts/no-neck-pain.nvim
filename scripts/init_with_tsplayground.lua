vim.cmd([[let &rtp.=','.getcwd()]])

vim.cmd("set rtp+=deps/mini.nvim")
vim.cmd("set rtp+=deps/nvim-treesitter")
vim.cmd("set rtp+=deps/playground")

require("nvim-treesitter.configs").setup({
    playground = {
        enable = true,
    },
})
require("mini.test").setup()
require("no-neck-pain").setup({ debug=true, width = 1 })
