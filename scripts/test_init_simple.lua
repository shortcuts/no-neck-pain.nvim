vim.cmd([[let &rtp.=','.getcwd()]])
vim.cmd("set rtp+=deps/mini.nvim")

-- Enable debug to see what's happening
local no_neck_pain = require("no-neck-pain")
no_neck_pain.setup({
    debug = true,
    width = 50,
    minSideBufferWidth = 5,
    autocmds = { enableOnVimEnter = true },
})

-- Create a file to edit
vim.cmd("e /tmp/test_simple.lua")

-- Wait and check state
vim.defer_fn(function()
    local state = _G.NoNeckPain and _G.NoNeckPain.state
    print("\n=== FINAL STATE ===")
    print("state:", vim.inspect(state))
    print("state.enabled:", state and state.enabled)
    vim.cmd("q!")
end, 1000)
