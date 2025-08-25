if _G.NoNeckPainLoaded then
    return
end

_G.NoNeckPainLoaded = true

vim.api.nvim_create_user_command("NoNeckPain", function()
    require("no-neck-pain").toggle()
end, { desc = "Toggles the plugin." })

vim.api.nvim_create_user_command("NoNeckPainToggleLeftSide", function()
    require("no-neck-pain").toggle_side("left")
end, { desc = "Toggles the left side buffer (open/close)." })

vim.api.nvim_create_user_command("NoNeckPainToggleRightSide", function()
    require("no-neck-pain").toggle_side("right")
end, { desc = "Toggles the right side buffer (open/close)." })

vim.api.nvim_create_user_command("NoNeckPainResize", function(tbl)
    require("no-neck-pain").resize(tbl.args)
end, { desc = "Resizes the main centered window for the given argument.", nargs = 1 })

vim.api.nvim_create_user_command("NoNeckPainWidthUp", function()
    local increment = _G.NoNeckPain.config.mappings.widthUp.value or 5

    require("no-neck-pain").resize(_G.NoNeckPain.config.width + increment)
end, { desc = "Increase the width of the main window by 5." })

vim.api.nvim_create_user_command("NoNeckPainWidthDown", function()
    local decrement = _G.NoNeckPain.config.mappings.widthDown.value or 5

    require("no-neck-pain").resize(_G.NoNeckPain.config.width - decrement)
end, { desc = "Decrease the width of the main window by 5." })

vim.api.nvim_create_user_command("NoNeckPainScratchPad", function()
    require("no-neck-pain").toggle_scratch_pad()
end, { desc = "Toggles the scratchPad feature of the plugin." })

vim.api.nvim_create_user_command("NoNeckPainDebug", function()
    require("no-neck-pain").toggle_debug()
end, { desc = "Toggles the debug mode of the plugin." })
