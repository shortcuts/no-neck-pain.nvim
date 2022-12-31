local E = require("no-neck-pain.util.event")

local NNP = {}

-- toggles NNP switch between enabled/disable state.
function NNP.toggle()
    if NNP.config == nil then
        NNP.config = require("no-neck-pain.config").options
    end
    local main = require("no-neck-pain.main")

    if main[1].toggle() then
        NNP.internal = {
            toggle = main[1].toggle,
            enable = main[1].enable,
            disable = main[1].disable,
        }
    else
        NNP.internal = {
            toggle = nil,
            enable = nil,
            disable = nil,
        }
    end

    NNP.state = main[2]
end

-- starts NNP and set internal functions and state.
function NNP.enable()
    local main = require("no-neck-pain.main")

    main[1].enable()

    NNP.state = main[2]
    NNP.internal = {
        toggle = main[1].toggle,
        enable = main[1].enable,
        disable = main[1].disable,
    }
end

-- disables NNP and reset internal functions and state.
function NNP.disable()
    local main = require("no-neck-pain.main")

    main[1].disable()

    NNP.state = main[2]
end

-- setup NNP options and merge them with user provided ones.
function NNP.setup(opts)
    NNP.config = require("no-neck-pain.config").setup(opts)

    if NNP.config.enableOnVimEnter then
        vim.api.nvim_create_augroup("NoNeckPainBufWinEnter", { clear = true })
        vim.api.nvim_create_autocmd({ "BufWinEnter" }, {
            group = "NoNeckPainBufWinEnter",
            pattern = "*",
            callback = function(p)
                vim.schedule(function()
                    if E.abortEnable(NNP.state, vim.bo.filetype) then
                        return
                    end

                    NNP.enable()
                    vim.api.nvim_del_autocmd(p.id)
                end)
            end,
            desc = "Triggers until it find the correct moment/buffer to enable the plugin.",
        })
    end
end

_G.NoNeckPain = NNP

return NNP
