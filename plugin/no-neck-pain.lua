if _G.NoNeckPainLoaded then
    return
end

_G.NoNeckPainLoaded = true

if vim.fn.has("nvim-0.7") == 0 then
    vim.cmd("command! NoNeckPain lua require('no-neck-pain').toggle()")
    vim.cmd("command! -nargs=1 NoNeckPainResize lua require('no-neck-pain').resize(<f-args>)")
    vim.cmd(
        "command! NoNeckPainWidthUp lua require('no-neck-pain').resize(_G.NoNeckPain.config.width + 5)"
    )
    vim.cmd(
        "command! NoNeckPainWidthDown lua require('no-neck-pain').resize(_G.NoNeckPain.config.width - 5)"
    )
    vim.cmd("command! NoNeckPainScratchPad lua require('no-neck-pain').toggleScratchPad()")
else
    vim.api.nvim_create_user_command("NoNeckPain", function()
        require("no-neck-pain").toggle()
    end, { desc = "Toggles the plugin." })

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
        require("no-neck-pain").toggleScratchPad()
    end, { desc = "Toggles the scratchPad feature of the plugin." })
end
