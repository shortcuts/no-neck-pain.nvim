vim.cmd([[let &rtp.=','.getcwd()]])

vim.cmd("set rtp+=deps/mini.nvim")

-- Auto open enabled for the test
require("no-neck-pain").setup({
    debug = true,
    width = 50,
    autocmds = { enableOnVimEnter = true, enableOnTabEnter = true },
})
require("mini.test").setup()
vim.print(_G.NoNeckPain.state)
