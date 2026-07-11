local Co = require("no-neck-pain.util.constants")

local T = MiniTest.new_set({
    hooks = {
        pre_case = function() end,
        post_once = function() end,
    },
})

-- =============================================================================
-- GROUP 1: SIDES Tests
-- =============================================================================

T["SIDES: should be a table"] = function()
    MiniTest.expect.equality(type(Co.SIDES), "table")
end

T["SIDES: should contain left and right"] = function()
    MiniTest.expect.equality(Co.SIDES, { "left", "right" })
end

T["SIDES: should have exactly 2 elements"] = function()
    MiniTest.expect.equality(#Co.SIDES, 2)
end

T["SIDES: first element should be left"] = function()
    MiniTest.expect.equality(Co.SIDES[1], "left")
end

T["SIDES: second element should be right"] = function()
    MiniTest.expect.equality(Co.SIDES[2], "right")
end

T["SIDES: should be iterable"] = function()
    local count = 0
    for _ in pairs(Co.SIDES) do
        count = count + 1
    end
    MiniTest.expect.equality(count, 2)
end

-- =============================================================================
-- GROUP 2: THEMES Tests
-- =============================================================================

T["THEMES: should be a table"] = function()
    MiniTest.expect.equality(type(Co.THEMES), "table")
end

T["THEMES: should have entries"] = function()
    MiniTest.expect.equality(#(vim.tbl_keys(Co.THEMES)) > 0, true)
end

T["THEMES: catppuccin-frappe should map to correct hex"] = function()
    MiniTest.expect.equality(Co.THEMES["catppuccin-frappe"], "#303446")
end

T["THEMES: catppuccin-frappe-dark should map to correct hex"] = function()
    MiniTest.expect.equality(Co.THEMES["catppuccin-frappe-dark"], "#292c3c")
end

T["THEMES: catppuccin-latte should map to correct hex"] = function()
    MiniTest.expect.equality(Co.THEMES["catppuccin-latte"], "#eff1f5")
end

T["THEMES: catppuccin-latte-dark should map to correct hex"] = function()
    MiniTest.expect.equality(Co.THEMES["catppuccin-latte-dark"], "#e6e9ef")
end

T["THEMES: catppuccin-macchiato should map to correct hex"] = function()
    MiniTest.expect.equality(Co.THEMES["catppuccin-macchiato"], "#24273a")
end

T["THEMES: catppuccin-macchiato-dark should map to correct hex"] = function()
    MiniTest.expect.equality(Co.THEMES["catppuccin-macchiato-dark"], "#1e2030")
end

T["THEMES: catppuccin-mocha should map to correct hex"] = function()
    MiniTest.expect.equality(Co.THEMES["catppuccin-mocha"], "#1e1e2e")
end

T["THEMES: catppuccin-mocha-dark should map to correct hex"] = function()
    MiniTest.expect.equality(Co.THEMES["catppuccin-mocha-dark"], "#181825")
end

T["THEMES: github-nvim-theme-dark should map to correct hex"] = function()
    MiniTest.expect.equality(Co.THEMES["github-nvim-theme-dark"], "#24292e")
end

T["THEMES: github-nvim-theme-dimmed should map to correct hex"] = function()
    MiniTest.expect.equality(Co.THEMES["github-nvim-theme-dimmed"], "#22272e")
end

T["THEMES: github-nvim-theme-light should map to correct hex"] = function()
    MiniTest.expect.equality(Co.THEMES["github-nvim-theme-light"], "#ffffff")
end

T["THEMES: onedark should map to correct hex"] = function()
    MiniTest.expect.equality(Co.THEMES["onedark"], "#282c34")
end

T["THEMES: onedark-dark should map to correct hex"] = function()
    MiniTest.expect.equality(Co.THEMES["onedark-dark"], "#000000")
end

T["THEMES: onedark-vivid should map to correct hex"] = function()
    MiniTest.expect.equality(Co.THEMES["onedark-vivid"], "#282c34")
end

T["THEMES: onelight should map to correct hex"] = function()
    MiniTest.expect.equality(Co.THEMES["onelight"], "#fafafa")
end

T["THEMES: rose-pine should map to correct hex"] = function()
    MiniTest.expect.equality(Co.THEMES["rose-pine"], "#191724")
end

T["THEMES: rose-pine-dawn should map to correct hex"] = function()
    MiniTest.expect.equality(Co.THEMES["rose-pine-dawn"], "#faf4ed")
end

T["THEMES: rose-pine-moon should map to correct hex"] = function()
    MiniTest.expect.equality(Co.THEMES["rose-pine-moon"], "#232136")
end

T["THEMES: tokyonight-day should map to correct hex"] = function()
    MiniTest.expect.equality(Co.THEMES["tokyonight-day"], "#16161e")
end

T["THEMES: tokyonight-moon should map to correct hex"] = function()
    MiniTest.expect.equality(Co.THEMES["tokyonight-moon"], "#1e2030")
end

T["THEMES: tokyonight-night should map to correct hex"] = function()
    MiniTest.expect.equality(Co.THEMES["tokyonight-night"], "#16161e")
end

T["THEMES: tokyonight-storm should map to correct hex"] = function()
    MiniTest.expect.equality(Co.THEMES["tokyonight-storm"], "#1f2335")
end

T["THEMES: should have 22 theme entries"] = function()
    local theme_keys = vim.tbl_keys(Co.THEMES)
    MiniTest.expect.equality(#theme_keys, 22)
end

T["THEMES: all values should be hex color strings"] = function()
    for theme_name, hex_value in pairs(Co.THEMES) do
        MiniTest.expect.equality(type(hex_value), "string")
        MiniTest.expect.equality(string.match(hex_value, "^#[0-9a-fA-F]+$") ~= nil, true)
        MiniTest.expect.equality(#hex_value == 7, true)
    end
end

-- =============================================================================
-- GROUP 3: Module Tests
-- =============================================================================

T["Module: should export the constants table"] = function()
    MiniTest.expect.equality(type(Co), "table")
end

T["Module: should have SIDES constant"] = function()
    MiniTest.expect.equality(Co.SIDES ~= nil, true)
end

T["Module: should have THEMES constant"] = function()
    MiniTest.expect.equality(Co.THEMES ~= nil, true)
end

T["Module: should have no extra unexpected keys"] = function()
    local keys = vim.tbl_keys(Co)
    MiniTest.expect.equality(#keys, 2)
    MiniTest.expect.equality(vim.tbl_contains(keys, "SIDES"), true)
    MiniTest.expect.equality(vim.tbl_contains(keys, "THEMES"), true)
end

return T
