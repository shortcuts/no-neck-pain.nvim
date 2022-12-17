local C = {}

-- tries to match the provided `colorCode` to an integration name, defaults to the provided string if not successful.
function C.matchIntegrationToHexCode(colorCode)
    if colorCode == nil then
        return colorCode
    end

    if colorCode == "catppuccin-frappe" then
        colorCode = "#292C3C"
    elseif colorCode == "catppuccin-latte" then
        colorCode = "#E6E9EF"
    elseif colorCode == "catppuccin-macchiato" then
        colorCode = "#1E2030"
    elseif colorCode == "catppuccin-mocha" then
        colorCode = "#181825"
    elseif colorCode == "tokyonight-day" then
        colorCode = "#16161e"
    elseif colorCode == "tokyonight-moon" then
        colorCode = "#1e2030"
    elseif colorCode == "tokyonight-night" then
        colorCode = "#16161e"
    elseif colorCode == "tokyonight-storm" then
        colorCode = "#1f2335"
    end

    return colorCode
end

-- creates an highlight group `NoNeckPain` with the given `colorCode` and assign it to the side buffer of the given `id`.
function C.init(win, colorCode)
    local groupName = "NoNeckPain"
    vim.cmd(
        string.format(
            [[highlight %s guifg=%s guibg=%s]],
            groupName,
            colorCode,
            colorCode,
            colorCode,
            colorCode
        )
    )
    vim.api.nvim_win_set_option(
        win,
        "winhl",
        string.format(
            "Normal:%s,NormalNC:%s,NonText:%s,EndOfBuffer:%s,WinSeparator:%s,VertSplit:%s",
            groupName,
            groupName,
            groupName,
            groupName,
            groupName,
            groupName
        )
    )
end

return C
