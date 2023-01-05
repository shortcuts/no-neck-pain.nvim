local D = require("no-neck-pain.util.debug")
local C = {}

-- converts an hex color code to RGB, values are returned independently.
local function hexToRGB(hex)
    local r, g, b = hex:sub(2, 3), hex:sub(4, 5), hex:sub(6, 7)

    return tonumber("0x" .. r), tonumber("0x" .. g), tonumber("0x" .. b)
end

-- blend the given `colorCode` RGB for the given `factor`.
local function blend(colorCode, factor)
    local r, g, b = hexToRGB(colorCode)
    local format = "#%02x%02x%02x"

    if factor < 0 then
        factor = 1 + factor
        return string.lower(string.format(format, r * factor, g * factor, b * factor))
    end

    return string.lower(
        string.format(
            format,
            (255 - r) * factor + r,
            (255 - g) * factor + g,
            (255 - b) * factor + b
        )
    )
end

-- tries to match the given `colorCode` to an integration name, defaults to the given `colorCode` if not found.
-- if a `factor` is provided, the color will be blended (brighten/darken) before being returned.
local function matchAndBlend(colorCode, factor)
    if colorCode == nil then
        return nil
    end

    if factor ~= nil then
        assert(
            factor >= -1 and factor <= 1,
            "`blend` "
                .. colorCode
                .. " does not match the range constraint, number must be between -1 and 1 "
        )
    end

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

    local hexPattern = "^#" .. "[abcdef0-9]" .. ("[abcdef0-9]"):rep(5) .. "$"
    colorCode = string.lower(colorCode)

    assert(
        colorCode:match(hexPattern) ~= nil,
        "`colorCode` " .. colorCode .. " does not match the regex " .. hexPattern
    )

    if factor == 0 then
        return colorCode
    end

    local blended = blend(colorCode, factor)

    assert(
        blended:match(hexPattern) ~= nil,
        "`colorCode` blended " .. blended .. " does not match the regex " .. hexPattern
    )

    return blended
end

function C.parseColors(buffers)
    buffers.backgroundColor = matchAndBlend(buffers.backgroundColor, buffers.blend)
    buffers.left.backgroundColor = matchAndBlend(
        buffers.left.backgroundColor,
        buffers.left.blend or buffers.blend
    ) or buffers.backgroundColor
    buffers.right.backgroundColor = matchAndBlend(
        buffers.right.backgroundColor,
        buffers.right.blend or buffers.blend
    ) or buffers.backgroundColor

    buffers.textColor = buffers.textColor or buffers.backgroundColor
    buffers.left.textColor = buffers.left.textColor
        or buffers.textColor
        or buffers.left.backgroundColor
    buffers.right.textColor = buffers.right.textColor
        or buffers.textColor
        or buffers.right.backgroundColor

    return buffers
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
    vim.cmd(string.format("highlight! %s guifg=%s guibg=%s", textGroup, textColor, backgroundColor))

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
