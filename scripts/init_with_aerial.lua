vim.cmd([[let &rtp.=','.getcwd()]])

vim.cmd("set rtp+=deps/mini.nvim")
vim.cmd("set rtp+=deps/nvim-treesitter")
vim.cmd("set rtp+=deps/nvim-web-devicons")
vim.cmd("set rtp+=deps/aerial")

require("mini.test").setup()
require("no-neck-pain").setup({
    width = 20,
    minSideBufferWidth = 0,
})
require("aerial").setup({
    -- optionally use on_attach to set keymaps when aerial has attached to a buffer
    on_attach = function(bufnr)
        -- Jump forwards/backwards with '{' and '}'
        vim.keymap.set("n", "{", "<cmd>AerialPrev<CR>", { buffer = bufnr })
        vim.keymap.set("n", "}", "<cmd>AerialNext<CR>", { buffer = bufnr })
    end,
})
