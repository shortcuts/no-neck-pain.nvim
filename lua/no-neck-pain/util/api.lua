local A = {}

-- creates an augroup with the given `name`, compatible with Neovim 0.6.
function A.augroup(name)
    if vim.fn.has("nvim-0.7") == 1 then
        return vim.api.nvim_create_augroup(name, { clear = true })
    end

    vim.cmd([[
        augroup name
            autocmd!
        augroup END
    ]])
end

return A
