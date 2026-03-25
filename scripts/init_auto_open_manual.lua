vim.cmd([[let &rtp.=','.getcwd()]])

vim.cmd("set rtp+=deps/mini.nvim")

-- Setup without auto-enable
require("no-neck-pain").setup({
    debug = true,
    width = 50,
    minSideBufferWidth = 5,
    autocmds = { enableOnVimEnter = false, enableOnTabEnter = true },
    buffers = { colors = { background = "tokyonight-moon" } },
})

-- Manually enable on BufEnter instead of relying on BufRead
vim.api.nvim_create_autocmd({ "BufEnter" }, {
    pattern = "*",
    callback = function()
        require("no-neck-pain").enable("manual_init")
    end,
})

require("mini.test").setup({silent=true})
