vim.cmd([[let &rtp.=','.getcwd()]])

vim.cmd("set rtp+=deps/mini.nvim")

-- Auto open enabled for the test
require("no-neck-pain").setup({
    debug = true,
    width = 50,
    minSideBufferWidth = 5,
    autocmds = { enableOnVimEnter = true, enableOnTabEnter = true },
    buffers = { colors = { background = "tokyonight-moon" } },
})

-- Explicitly enable to initialize state before tests run
require("no-neck-pain").enable()

require("mini.test").setup({ silent = true })
