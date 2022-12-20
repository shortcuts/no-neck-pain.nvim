local D = require("no-neck-pain.util.debug")
local C = {}

-- tries to match the provided `colorCode` to an integration name, defaults to the provided string if not successful.
function C.matchIntegrationToHexCode(colorCode)
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
    elseif colorCode == "rose-pine" then
        colorCode = "#191724"
    elseif colorCode == "rose-pine-moon" then
        colorCode = "#232136"
    elseif colorCode == "rose-pine-dawn" then
        colorCode = "#faf4ed"
    end

    return colorCode
end

-- creates an highlight group `NNPBuffers` with the given `backgroundColor` and assign it to the side buffer of the given `id`.
-- `cmd` is used instead of native commands for backward compatibility with Neovim 0.7
function C.init(win, backgroundColor)
    local groupName = "NNPBuffers"
    local defaultBackground = vim.api.nvim_get_hl_by_name("Normal", true).background

    -- check if the user has a transparent background or not
    if defaultBackground == nil then
        defaultBackground = "NONE"
    else
        -- if it's not transparent, get the user's current background color
        defaultBackground = string.format("#%06X", defaultBackground)
    end

    backgroundColor = backgroundColor or defaultBackground

    D.print(
        string.format(
            "Color.init: groupName `%s` - window `%s` - backgroundColor `%s`",
            groupName,
            win,
            backgroundColor
        )
    )

    vim.cmd(string.format("highlight! clear %s NONE", groupName))
    vim.cmd(
        string.format(
            "highlight! %s guifg=%s guibg=%s",
            groupName,
            backgroundColor,
            backgroundColor
        )
    )

    vim.api.nvim_win_set_option(
        win,
        "winhl",
        string.format(
            "Normal:%s,NormalNC:%s,CursorColumn:%s,CursorLineNr:%s,NonText:%s,SignColumn:%s,Cursor:%s,LineNr:%s,EndOfBuffer:%s,WinSeparator:%s,VertSplit:%s",
            groupName,
            groupName,
            groupName,
            groupName,
            groupName,
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
