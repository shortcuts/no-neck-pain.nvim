vim.cmd([[let &rtp.=','.getcwd()]])

vim.cmd("set rtp+=deps/mini.nvim")
vim.cmd("set rtp+=deps/plenary")
vim.cmd("set rtp+=deps/nvim-web-devicons")
vim.cmd("set rtp+=deps/nui")
vim.cmd("set rtp+=deps/neo-tree")

require("neo-tree").setup({
    default_component_configs = {
        indent = {
            indent_size = 1,
            padding = 1,
        },
    },
    window = {
        width = 20,
    },
    close_if_last_window = true,
})
require("mini.test").setup()
require("no-neck-pain").setup({
    width = 20,
    minSideBufferWidth = 0,
    integrations = { NeoTree = { reopen = true } },
    autocmds = { skipEnteringNoNeckPainBuffer = true }
})
