local NNP = {}

-- toggles NNP
function NNP.toggle()
    local main = require("no-neck-pain.main")

    main.toggle()

    NNP.state = main.state
    NNP.internal = {
        toggle = main.toggle,
        enable = main.enable,
        disable = main.disable,
    }
end

-- starts NNP
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

-- setup NNP
function NNP.setup(opts)
    NNP.config = {
        options = require("no-neck-pain.config").setup(opts),
    }
end

_G.NoNeckPain = NNP

return NNP
