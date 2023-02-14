local Co = require("no-neck-pain.util.constants")

local C = {}

---Converts an hex color code to RGB, values are returned independently.
---
---@param hex string: the hex color to conver to rgb.
---@return number?: the r color
---@return number?: the g color
---@return number?: the b color
---@private
local function hexToRGB(hex)
    local r, g, b = hex:sub(2, 3), hex:sub(4, 5), hex:sub(6, 7)

    return tonumber("0x" .. r), tonumber("0x" .. g), tonumber("0x" .. b)
end

---Blend the given `colorCode` RGB for the given `factor`.
---
---@param colorCode string: the color code string, e.g. #ffffff.
---@param factor number: Brighten (positive) or darken (negative) the side buffers background color. Accepted values are [-1..1].
---@return string: the blended color code.
---@private
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

---Tries to match the given `colorCode` to an integration name, defaults to the given `colorCode` if not found.
---if a `factor` is provided, the color will be blended (brighten/darken) before being returned.
---
---@param colorCode string: the color code string, e.g. #ffffff.
---@param factor number: Brighten (positive) or darken (negative) the side buffers background color. Accepted values are [-1..1].
---@return string?: the blended color code.
---@private
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

    if Co.INTEGRATIONS[colorCode] ~= nil then
        colorCode = Co.INTEGRATIONS[colorCode]
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

    return blend(colorCode, factor or 0)
end

---Parses to color for each buffer parameters, considering transparent backgrounds.
---
---@param buffers table: the buffers table to parse.
---@return table: the parsed buffers.
---@private
function C.parse(buffers)
    local defaultBackground = vim.api.nvim_get_hl_by_name("Normal", true).background

    -- if the user did not provided a custom background color, and have a transparent bg,
    -- we set it to the global options and let the loop do the spread below.
    if
        buffers.backgroundColor == nil
        and (defaultBackground == nil or string.lower(defaultBackground) == "none")
    then
        buffers.backgroundColor = "NONE"
        buffers.textColor = "#ffffff"
    else
        buffers.backgroundColor = matchAndBlend(
            buffers.backgroundColor or string.format("#%06X", defaultBackground),
            buffers.blend
        )
    end

    for _, side in pairs(Co.SIDES) do
        if buffers[side].enabled then
            -- if the side buffer backgroundColor is not defined, we fallback to the common option.
            buffers[side].backgroundColor = matchAndBlend(
                buffers[side].backgroundColor,
                buffers[side].blend or buffers.blend
            ) or buffers.backgroundColor

            local defaultTextColor = buffers[side].backgroundColor

            -- if we have a transparent bg we won't be able,
            -- to default a text color so we set it to white
            if buffers[side].backgroundColor == "NONE" then
                defaultTextColor = "#ffffff"
            end

            buffers[side].textColor = buffers[side].textColor
                or buffers.textColor
                or matchAndBlend(defaultTextColor, 0.5)
        end
    end

    return buffers
end

---Creates highlight groups for a given `win` in a `tab` named:
---- `NoNeckPain_background_tab_$ID_side_$SIDE` for the background colors.
---- `NoNeckPain_text_tab_$ID_side_$SIDE` for the text colors.
---note: `cmd` is used instead of native commands for backward compatibility with Neovim 0.7
---
---@param win number: the id of the win to init.
---@param tab table: the table where the tab information are stored.
---@param side "left"|"right": the side of the window being resized, used for logging only.
---@private
function C.init(win, tab, side)
    local backgroundGroup = string.format("NoNeckPain_background_tab_%s_side_%s", tab, side)
    local textGroup = string.format("NoNeckPain_text_tab_%s_side_%s", tab, side)

    -- clear groups
    vim.cmd(string.format("highlight! clear %s NONE", backgroundGroup))
    vim.cmd(string.format("highlight! clear %s NONE", textGroup))

    -- create group for background
    vim.cmd(
        string.format(
            "highlight! %s guifg=%s guibg=%s",
            backgroundGroup,
            _G.NoNeckPain.config.buffers[side].backgroundColor,
            _G.NoNeckPain.config.buffers[side].backgroundColor
        )
    )

    -- create group for text
    vim.cmd(
        string.format(
            "highlight! %s guifg=%s guibg=%s",
            textGroup,
            _G.NoNeckPain.config.buffers[side].textColor,
            _G.NoNeckPain.config.buffers[side].backgroundColor
        )
    )

    local groups = {
        Normal = textGroup,
        NormalNC = textGroup,
    }

    -- on transparent backgrounds we don't set those two to prevent white lines.
    if _G.NoNeckPain.config.buffers[side].backgroundColor ~= "NONE" then
        groups = vim.tbl_extend("keep", groups, {
            WinSeparator = backgroundGroup,
            VertSplit = backgroundGroup,
            EndOfBuffer = backgroundGroup,
            CursorColumn = backgroundGroup,
            CursorLineNr = backgroundGroup,
            NonText = backgroundGroup,
            SignColumn = backgroundGroup,
            Cursor = backgroundGroup,
            LineNr = backgroundGroup,
        })
    end

    local stringGroups = {}

    for hl, group in pairs(groups) do
        table.insert(stringGroups, string.format("%s:%s", hl, group))
    end

    vim.api.nvim_win_set_option(win, "winhl", table.concat(stringGroups, ","))
end

return C
