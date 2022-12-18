local NNP = {}

-- toggles NNP switch between enabled/disable state.
function NNP.toggle()
    local main = require("no-neck-pain.main")

    if main.toggle() then
        NNP.internal = {
            toggle = main.toggle,
            enable = main.enable,
            disable = main.disable,
        }
    else
        NNP.internal = {
            toggle = nil,
            enable = nil,
            disable = nil,
        }
    end

    NNP.state = main.state
end

-- starts NNP and set internal functions and state.
function NNP.enable()
    local main = require("no-neck-pain.main")

    main.enable()

    NNP.state = main.state
    NNP.internal = {
        toggle = main.toggle,
        enable = main.enable,
        disable = main.disable,
    }
end

-- disables NNP and reset internal functions and state.
function NNP.disable()
    local main = require("no-neck-pain.main")

    main.disable()

    NNP.state = main.state
end

-- setup NNP options and merge them with user provided ones.
function NNP.setup(opts)
    NNP.config = require("no-neck-pain.config").setup(opts)
end

_G.NoNeckPain = NNP

return NNP
