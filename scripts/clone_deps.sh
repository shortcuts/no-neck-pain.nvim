DEPTH=""

if [[ -n $1 ]]; then
    DEPTH="--depth $1"
fi

git clone $DEPTH https://github.com/MunifTanjim/nui.nvim deps/nui
git clone $DEPTH https://github.com/antoinemadec/FixCursorHold.nvim deps/fixcursorhold
git clone $DEPTH https://github.com/b0o/incline.nvim deps/incline
git clone https://github.com/echasnovski/mini.nvim deps/mini.nvim --branch stable
git clone $DEPTH https://github.com/hedyhli/outline.nvim deps/outline
git clone $DEPTH https://github.com/mfussenegger/nvim-dap deps/nvimdap
git clone $DEPTH https://github.com/nvim-lua/plenary.nvim deps/plenary
git clone $DEPTH https://github.com/nvim-neo-tree/neo-tree.nvim deps/neo-tree
git clone $DEPTH https://github.com/nvim-neotest/neotest deps/neotest
git clone $DEPTH https://github.com/nvim-neotest/nvim-nio deps/nvim-nio
git clone $DEPTH https://github.com/nvim-tree/nvim-tree.lua deps/nvimtree
git clone $DEPTH https://github.com/nvim-tree/nvim-web-devicons deps/nvim-web-devicons
git clone $DEPTH https://github.com/nvim-treesitter/nvim-treesitter deps/nvim-treesitter
git clone $DEPTH https://github.com/nvim-treesitter/playground deps/playground
git clone $DEPTH https://github.com/rcarriga/nvim-dap-ui deps/nvimdapui
git clone $DEPTH https://github.com/stevearc/aerial.nvim deps/aerial
