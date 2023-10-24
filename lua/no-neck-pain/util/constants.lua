local C = {}

---Sides where the buffers are created.
---
---@private
C.SIDES = { "left", "right" }

---Available color integrations aliases.
---
---@private
C.INTEGRATIONS = {
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

C.integrations = {
    NvimTree = {
        fileTypePattern = "nvimtree",
        close = "NvimTreeClose",
        open = "NvimTreeOpen",
    },
    NeoTree = {
        fileTypePattern = "neo-tree",
        close = "Neotree close",
        open = "Neotree reveal",
    },
    neotest = {
        fileTypePattern = "neotest",
        close = "lua require('neotest').summary.close()",
        open = "lua require('neotest').summary.open()",
    },
    undotree = {
        fileTypePattern = "undotree",
        close = "UndotreeToggle",
        open = "UndotreeToggle",
    },
    TSPlayground = {
        fileTypePattern = "tsplayground",
        close = "TSPlaygroundToggle",
        open = "TSPlaygroundToggle",
    },
    NvimDAPUI = {
        fileTypePattern = "dap",
        close = "lua require('dapui').close()",
        open = "lua require('dapui').open()",
    },
}

return C
