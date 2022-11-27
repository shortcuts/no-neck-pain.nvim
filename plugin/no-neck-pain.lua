if _G.noNeckPainLoaded then
    return
end

local NNP = require("no-neck-pain")

_G.noNeckPainLoaded = true

vim.api.nvim_create_user_command("NoNeckPain", function()
    NNP.start()
end, {})
