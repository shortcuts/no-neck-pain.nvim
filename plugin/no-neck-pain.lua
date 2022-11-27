if _G.noNeckPainLoaded then
    return
end

_G.noNeckPainLoaded = true

vim.api.nvim_create_user_command("NoNeckPain", function()
    require("no-neck-pain").start()
end, {})
