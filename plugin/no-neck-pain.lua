if vim.g.noNeckPain then
    return
end
vim.g.noNeckPain = true

vim.api.nvim_create_user_command("NoNeckPain", function()
    require("no-neck-pain").start()
end, {})
