if _G.NoNeckPainLoaded then
    return
end

_G.NoNeckPainLoaded = true

if vim.fn.has("nvim-0.7") == 0 then
    vim.cmd("command NoNeckPain lua require('no-neck-pain').toggle()")
else
    vim.api.nvim_create_user_command("NoNeckPain", function()
        require("no-neck-pain").toggle()
    end, {})
end
