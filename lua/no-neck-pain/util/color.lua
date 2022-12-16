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

-- creates a namespace for `no-neck-pain`, and assign the provided `colorCode` to the side buffers.
function C.init(colorCode)
    local namespaceID = vim.api.nvim_create_namespace("no-neck-pain")

    vim.api.nvim_set_hl(namespaceID, "Normal", {
        bg = colorCode,
    })
    vim.api.nvim_set_hl(namespaceID, "NormalNC", {
        bg = colorCode,
    })
    vim.api.nvim_set_hl(namespaceID, "EndOfBuffer", {
        fg = colorCode,
    })
    vim.api.nvim_set_hl(namespaceID, "WinSeparator", {
        bg = colorCode,
        fg = colorCode,
    })
    vim.api.nvim_set_hl(namespaceID, "VertSplit", {
        bg = colorCode,
        fg = colorCode,
    })

    return namespaceID
end

return C
