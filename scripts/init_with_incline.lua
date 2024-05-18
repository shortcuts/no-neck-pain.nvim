vim.cmd([[let &rtp.=','.getcwd()]])

vim.cmd("set rtp+=deps/mini.nvim")
vim.cmd("set rtp+=deps/nvim-web-devicons")
vim.cmd("set rtp+=deps/incline")

require("mini.test").setup()
require("no-neck-pain").setup({
    width = 1,
    minSideBufferWidth = 0,
    integrations = { NeoTree = { reopen = true } },
})
local helpers = require("incline.helpers")
local devicons = require("nvim-web-devicons")
require("incline").setup({
    window = {
        padding = 0,
        margin = { horizontal = 0 },
    },
    render = function(props)
        local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(props.buf), ":t")
        if filename == "" then
            filename = "[No Name]"
        end
        local ft_icon, ft_color = devicons.get_icon_color(filename)
        local modified = vim.bo[props.buf].modified
        return {
            ft_icon and {
                " ",
                ft_icon,
                " ",
                guibg = ft_color,
                guifg = helpers.contrast_color(ft_color),
            } or "",
            " ",
            { filename, gui = modified and "bold,italic" or "bold" },
            " ",
            guibg = "#44406e",
        }
    end,
})
