local NNP = {}

function NNP.start()
    local main = require("no-neck-pain.main")

    NNP.state = main.state
    NNP.internal = {
        toggle = main.toggle,
        enable = main.enable,
        disable = main.disable,
    }

    main.toggle()
end

function NNP.setup(opts)
    NNP.config = {
        options = require("no-neck-pain.config").setup(opts),
    }
end

_G.NoNeckPain = NNP

return NNP
