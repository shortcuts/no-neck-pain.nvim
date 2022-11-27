local NNP = {}

local cfg = require("no-neck-pain.config")
local main = require("no-neck-pain.main")

NNP.config = cfg

NNP.state = main.state

NNP.fns = {
    main.disable,
    main.enable,
    main.toggle,
}

function NNP.start()
    main.toggle()
end

function NNP.setup(opts)
    cfg.setup(opts)
end

_G.NoNeckPain = NNP

return NNP
