local C = {}

local integrationMapping = {
    ["catppuccin-frappe"] = "#303446",
    ["catppuccin-frappe-dark"] = "#292c3c",
    ["catppuccin-latte"] = "#eff1f5",
    ["catppuccin-latte-dark"] = "#e6e9ef",
    ["catppuccin-macchiato"] = "#24273a",
    ["catppuccin-macchiato-dark"] = "#1e2030",
    ["catppuccin-mocha"] = "#1e1e2e",
    ["catppuccin-mocha-dark"] = "#181825",
    ["github-nvim-theme-dark"] = "#24292e",
    ["github-nvim-theme-dimmed"] = "#22272e",
    ["github-nvim-theme-light"] = "#ffffff",
    ["onedark"] = "#282c34",
    ["onedark-dark"] = "#000000",
    ["onedark-vivid"] = "#282c34",
    ["onelight"] = "#fafafa",
    ["rose-pine"] = "#191724",
    ["rose-pine-dawn"] = "#faf4ed",
    ["rose-pine-moon"] = "#232136",
    ["tokyonight-day"] = "#16161e",
    ["tokyonight-moon"] = "#1e2030",
    ["tokyonight-night"] = "#16161e",
    ["tokyonight-storm"] = "#1f2335",
}

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
            string.format(
                "`blend` value %s does not match the range constraint, number must be between -1 and 1.",
                factor
            )
        )
    end

    if integrationMapping[colorCode] ~= nil then
        colorCode = integrationMapping[colorCode]
    end

    local hexPattern = "^#" .. "[abcdef0-9]" .. ("[abcdef0-9]"):rep(5) .. "$"
    colorCode = string.lower(colorCode)

    assert(
        colorCode:match(hexPattern) ~= nil,
        string.format("`colorCode` %s  does not match the regex %s", colorCode, hexPattern)
    )

    if factor == 0 then
        return colorCode
    end

    return blend(colorCode, factor)
end

function C.parse(buffers)
    buffers.backgroundColor = matchAndBlend(buffers.backgroundColor, buffers.blend)

    for _, side in pairs({ "left", "right" }) do
        buffers[side].backgroundColor = matchAndBlend(
            buffers[side].backgroundColor,
            buffers[side].blend or buffers.blend
        ) or buffers.backgroundColor

        buffers[side].textColor = buffers[side].textColor
            or buffers.textColor
            or matchAndBlend(buffers[side].backgroundColor, 0.5)
    end

    buffers.textColor = buffers.textColor or buffers.backgroundColor

    return buffers
end

-- Creates highlight groups for a given `win` in a `tab` named:
-- - `NoNeckPain_background_tab_$ID_side_$SIDE` for the background colors.
-- - `NoNeckPain_text_tab_$ID_side_$SIDE` for the text colors.
-- note: `cmd` is used instead of native commands for backward compatibility with Neovim 0.7
function C.init(win, tab, side)
    local backgroundGroup = string.format("NoNeckPain_background_tab_%s_side_%s", tab, side)
    local textGroup = string.format("NoNeckPain_text_tab_%s_side_%s", tab, side)

    local defaultBackground = vim.api.nvim_get_hl_by_name("Normal", true).background

    -- check if the user has a transparent background.
    if defaultBackground == nil then
        defaultBackground = "NONE"
    else
        defaultBackground = string.format("#%06X", defaultBackground)
    end

    local backgroundColor = _G.NoNeckPain.config.buffers[side].backgroundColor or defaultBackground

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
    vim.cmd(
        string.format(
            "highlight! %s guifg=%s guibg=%s",
            textGroup,
            _G.NoNeckPain.config.buffers[side].textColor,
            backgroundColor
        )
    )

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
