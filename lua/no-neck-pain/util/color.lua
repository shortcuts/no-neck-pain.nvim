local D = require("no-neck-pain.util.debug")
local C = {}

-- tries to match the provided `colorCode` to an integration name, defaults to the provided string if not successful.
function C.matchIntegrationToHexCode(colorCode)
    if colorCode == "catppuccin-frappe" then
        colorCode = "#303446"
    elseif colorCode == "catppuccin-latte" then
        colorCode = "#EFF1F5"
    elseif colorCode == "catppuccin-macchiato" then
        colorCode = "#24273A"
    elseif colorCode == "catppuccin-mocha" then
        colorCode = "#1E1E2E"
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

-- creates an highlight group `NoNeckPain` with the given `colorCode` and assign it to the side buffer of the given `id`.
-- `cmd` is used instead of native commands for backward compatibility with Neovim 0.7
function C.init(win, colorCode)
    local groupName = "nnpcolorname"

    D.print(
        "Color.init: initializing background mode with groupname "
            .. groupName
            .. " for win "
            .. win
            .. " with color "
            .. colorCode
    )

    vim.cmd(string.format([[highlight! clear %s NONE]], groupName))
    vim.cmd(
        string.format(
            [[highlight! %s guifg=%s guibg=%s]],
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
            "Normal:%s,NormalNC:%s,CursorColumn:%s,CursorColumnNr:%s,NonText:%s,SignColumn:%s,Cursor:%s,LineNr:%s,EndOfBuffer:%s,WinSeparator:%s,VertSplit:%s",
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
