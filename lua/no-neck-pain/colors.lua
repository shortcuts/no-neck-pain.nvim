local api = require("no-neck-pain.util.api")
local constants = require("no-neck-pain.util.constants")
local D = require("no-neck-pain.util.debug")
local S = require("no-neck-pain.state")

local C = {}

--- Converts an hex color code to RGB, values are returned independently.
---
---@param hex string: the hex color to conver to rgb.
---@return number?: the r color
---@return number?: the g color
---@return number?: the b color
---@private
local function hex_to_rgb(hex)
    local r, g, b = hex:sub(2, 3), hex:sub(4, 5), hex:sub(6, 7)

    return tonumber("0x" .. r), tonumber("0x" .. g), tonumber("0x" .. b)
end

--- Blend the given `color_code` RGB for the given `factor`.
---
---@param color_code string: the color code string, e.g. #ffffff.
---@param factor number: Brighten (positive) or darken (negative) the side buffers background color. Accepted values are [-1..1].
---@return string: the blended color code.
---@private
local function blend(color_code, factor)
    local r, g, b = hex_to_rgb(color_code)
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

--- Tries to match the given `color_code` to an integration name, defaults to the given `color_code` if not found.
--- if a `factor` is provided, the color will be blended (brighten/darken) before being returned.
---
---@param color_code string: the color code string, e.g. #ffffff.
---@param factor number: Brighten (positive) or darken (negative) the side buffers background color. Accepted values are [-1..1].
---@return string?: the blended color code.
---@private
function C.match_and_blend(color_code, factor)
    if color_code == nil or string.lower(color_code) == "none" then
        return nil
    end

    if factor ~= nil then
        assert(
            type(factor) == "number" and factor >= -1 and factor <= 1,
            string.format(
                "`blend` value %s does not match the range constraint, number must be between -1 and 1.",
                factor
            )
        )
    end

    if constants.THEMES[color_code] ~= nil then
        color_code = constants.THEMES[color_code]
    end

    local hex_pattern = "^#" .. "[abcdef0-9]" .. ("[abcdef0-9]"):rep(5) .. "$"
    color_code = string.lower(color_code)

    assert(
        color_code:match(hex_pattern) ~= nil,
        string.format("`color_code` %s  does not match the regex %s", color_code, hex_pattern)
    )

    if factor == 0 then
        return color_code
    end

    return blend(color_code, factor or 0)
end

--- Parses to color for each buffer parameters, considering transparent backgrounds.
---
---@param buffers table: the buffers table to parse.
---@return table: the parsed buffers.
---@private
function C.parse(buffers)
    buffers.colors.background = C.match_and_blend(buffers.colors.background, buffers.colors.blend)

    for _, side in pairs(constants.SIDES) do
        if buffers[side].enabled then
            buffers[side].colors.background = C.match_and_blend(
                buffers[side].colors.background,
                buffers[side].colors.blend or buffers.colors.blend
            ) or buffers.colors.background

            buffers[side].colors.text = buffers[side].colors.text or buffers.colors.text
        end
    end

    return buffers
end

--- Creates highlight groups for a given `win` in a `tab` named:
--- - `NoNeckPain_background_tab_$ID_side_$SIDE` for the background colors.
--- - `NoNeckPain_text_tab_$ID_side_$SIDE` for the text colors.
--- note: `cmd` is used instead of native commands for backward compatibility with Neovim 0.7
---
---@param win number: the id of the win to init.
---@param side "left"|"right": the side of the window being resized, used for logging only.
---@private
function C.init(win, side)
    if win == nil then
        return
    end

    if
        _G.NoNeckPain.config.buffers[side].colors.background == nil
        and _G.NoNeckPain.config.buffers[side].colors.text == nil
        and _G.NoNeckPain.config.buffers[side].colors.blend == 0
    then
        return D.log("C.init", "skipping color initialization for side %s", side)
    end

    -- init namespace for the current tab
    local id, _ = S.set_namespace(S, side)
    local bufnr = vim.api.nvim_win_get_buf(win)

    -- create groups to assign them to the namespace
    local background_group =
        string.format("NoNeckPain_background_tab_%s_side_%s", S.active_tab, side)
    local text_group = string.format("NoNeckPain_text_tab_%s_side_%s", S.active_tab, side)

    vim.cmd(
        string.format(
            "hi! %s guifg=%s guibg=%s",
            background_group,
            _G.NoNeckPain.config.buffers[side].colors.background,
            _G.NoNeckPain.config.buffers[side].colors.background
        )
    )
    vim.cmd(
        string.format(
            "hi! %s guifg=%s guibg=%s",
            text_group,
            _G.NoNeckPain.config.buffers[side].colors.text,
            _G.NoNeckPain.config.buffers[side].colors.background
        )
    )

    -- assign groups to the namespace
    vim.api.nvim_buf_add_highlight(bufnr, id, background_group, 0, 0, -1)
    vim.api.nvim_buf_add_highlight(bufnr, id, text_group, 0, 0, -1)

    -- link nnp and neovim hl groups
    local groups = { Normal = text_group, NormalNC = text_group }

    -- we only set those for non transparent backgrouns to prevent white lines.
    if _G.NoNeckPain.config.buffers[side].colors.background ~= "NONE" then
        groups = vim.tbl_extend("keep", groups, {
            WinSeparator = background_group,
            VertSplit = background_group,
            EndOfBuffer = background_group,
            CursorColumn = background_group,
            CursorLineNr = background_group,
            NonText = background_group,
            SignColumn = background_group,
            Cursor = background_group,
            LineNr = background_group,
            StatusLine = background_group,
            StatusLineNC = background_group,
        })
    end

    local string_groups = {}

    for hl, group in pairs(groups) do
        table.insert(string_groups, string.format("%s:%s", hl, group))
    end

    api.set_window_option(win, "winhl", table.concat(string_groups, ","))
end

return C
