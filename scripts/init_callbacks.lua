vim.cmd([[let &rtp.=','.getcwd()]])

vim.cmd("set rtp+=deps/mini.nvim")

-- Auto open enabled for the test
require("no-neck-pain").setup({
    width = 50,
    minSideBufferWidth = 5,
    callbacks = {
        preEnable = function(state)
            _G.NoNeckPainPreEnable = state.enabled
        end,
        postEnable = function(state)
            _G.NoNeckPainPostEnable = state.enabled
        end,
        preDisable = function(state)
            _G.NoNeckPainPreDisable = state.enabled
        end,
        postDisable = function(state)
            _G.NoNeckPainPreEnable = nil
            _G.NoNeckPainPostEnable = nil
            _G.NoNeckPainPostDisable = state.enabled
        end,
    },
})
require("mini.test").setup()
