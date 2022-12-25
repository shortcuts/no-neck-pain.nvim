local D = require("no-neck-pain.util.debug")
local C = {}

-- tries to match the provided `colorCode` to an integration name, defaults to the provided string if not successful.
function C.matchIntegrationToHexCode(colorCode)
    if colorCode == "catppuccin-frappe" then
        colorCode = "#303446"
    elseif colorCode == "catppuccin-frappe-dark" then
        colorCode = "#292C3C"
    elseif colorCode == "catppuccin-latte" then
        colorCode = "#EFF1F5"
    elseif colorCode == "catppuccin-latte-dark" then
        colorCode = "#E6E9EF"
    elseif colorCode == "catppuccin-macchiato" then
        colorCode = "#24273A"
    elseif colorCode == "catppuccin-macchiato-dark" then
        colorCode = "#1E2030"
    elseif colorCode == "catppuccin-mocha" then
        colorCode = "#1E1E2E"
    elseif colorCode == "catppuccin-mocha-dark" then
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

-- creates two highlight groups for a given `win` named `NNPBuffers_Background_$NAME` and `NNPBuffers_Text_$NAME`.
-- `cmd` is used instead of native commands for backward compatibility with Neovim 0.7
function C.init(win, name, backgroundColor, textColor)
    local backgroundGroup = "NNPBuffers_Background_" .. name
    local textGroup = "NNPBuffers_Text_" .. name
    local defaultBackground = vim.api.nvim_get_hl_by_name("Normal", true).background

    -- check if the user has a transparent background or not
    if defaultBackground == nil then
        defaultBackground = "NONE"
    else
        -- if it's not transparent, get the user's current background color
        defaultBackground = string.format("#%06X", defaultBackground)
    end

    backgroundColor = backgroundColor or defaultBackground

    D.log(
        "Color.init",
        "groupName `%s` - window `%s` - backgroundColor `%s`\ngroupName `%s` - window `%s` - textColor `%s`",
        backgroundGroup,
        win,
        backgroundColor,
        textGroup,
        win,
        textColor
    )

    -- clear groups
    vim.cmd(string.format("highlight! clear %s NONE", backgroundGroup))
    vim.cmd(string.format("highlight! clear %s NONE", textGroup))

    -- create group for background
    vim.cmd(
        string.format(
            "highlight! %s guifg=%s guibg=%s",
            backgroundGroup,
            backgroundColor,
            backgroundColor
        )
    )

    -- create group for text
    vim.cmd(string.format("highlight! %s guifg=%s", textGroup, textColor))

    vim.api.nvim_win_set_option(
        win,
        "winhl",
        string.format(
            "Normal:%s,NormalNC:%s,CursorColumn:%s,CursorLineNr:%s,NonText:%s,SignColumn:%s,Cursor:%s,LineNr:%s,EndOfBuffer:%s,WinSeparator:%s,VertSplit:%s",
            textGroup,
            textGroup,
            backgroundGroup,
            backgroundGroup,
            backgroundGroup,
            backgroundGroup,
            backgroundGroup,
            backgroundGroup,
            backgroundGroup,
            backgroundGroup,
            backgroundGroup
        )
    )
end

return C
