if _G.NoNeckPainLoaded then
    return
end

_G.NoNeckPainLoaded = true

vim.api.nvim_create_user_command("NoNeckPain", function()
    require("no-neck-pain").toggle()
end, {})
