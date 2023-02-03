if _G.NoNeckPainLoaded then
    return
end

_G.NoNeckPainLoaded = true

if vim.fn.has("nvim-0.7") == 0 then
    vim.cmd("command NoNeckPain lua require('no-neck-pain').toggle()")
    vim.cmd("command -nargs=1 NoNeckPainResize lua require('no-neck-pain').toggle()")
else
    vim.api.nvim_create_user_command("NoNeckPain", function()
        require("no-neck-pain").toggle()
    end, { desc = "Toggles the plugin" })

    vim.api.nvim_create_user_command("NoNeckPainResize", function(tbl)
        require("no-neck-pain").resize(tbl.args)
    end, { desc = "Resizes the main centered window", nargs = 1 })
end
