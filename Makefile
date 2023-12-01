.SUFFIXES:

all:

test:
	nvim --version | head -n 1 && echo ''
	nvim --headless --noplugin -u ./scripts/minimal_init.lua \
		-c "lua MiniTest.run({ execute = { reporter = MiniTest.gen_reporter.stdout({ group_depth = 2 }) } })"

test-integrations:
	nvim --version | head -n 1 && echo ''
	nvim --headless --noplugin -u ./scripts/minimal_init.lua \
		-c "lua MiniTest.run_file('tests/test_integrations.lua', { execute = { reporter = MiniTest.gen_reporter.stdout({ group_depth = 2 }) } })"

test-splits:
	nvim --version | head -n 1 && echo ''
	nvim --headless --noplugin -u ./scripts/minimal_init.lua \
		-c "lua MiniTest.run_file('tests/test_splits.lua', { execute = { reporter = MiniTest.gen_reporter.stdout({ group_depth = 2 }) } })"

test-tabs:
	nvim --version | head -n 1 && echo ''
	nvim --headless --noplugin -u ./scripts/minimal_init.lua \
		-c "lua MiniTest.run_file('tests/test_tabs.lua', { execute = { reporter = MiniTest.gen_reporter.stdout({ group_depth = 2 }) } })"

deps:
	@mkdir -p deps
	git clone --depth 1 https://github.com/echasnovski/mini.nvim deps/mini.nvim
	git clone --depth 1 https://github.com/nvim-treesitter/nvim-treesitter deps/nvim-treesitter
	git clone --depth 1 https://github.com/nvim-treesitter/playground deps/playground
	git clone --depth 1 https://github.com/nvim-neotest/neotest deps/neotest
	git clone --depth 1 https://github.com/nvim-tree/nvim-tree.lua deps/nvimtree
	git clone --depth 1 https://github.com/nvim-neo-tree/neo-tree.nvim deps/neo-tree
	git clone --depth 1 https://github.com/nvim-lua/plenary.nvim deps/plenary
	git clone --depth 1 https://github.com/nvim-tree/nvim-web-devicons deps/nvim-web-devicons
	git clone --depth 1 https://github.com/MunifTanjim/nui.nvim deps/nui
	git clone --depth 1 https://github.com/antoinemadec/FixCursorHold.nvim deps/fixcursorhold
	git clone --depth 1 https://github.com/mfussenegger/nvim-dap deps/nvimdap
	git clone --depth 1 https://github.com/rcarriga/nvim-dap-ui deps/nvimdapui
	

test-ci: deps test

documentation:
	nvim --headless --noplugin -u ./scripts/minimal_init.lua -c "lua require('mini.doc').generate()" -c "qa!"

documentation-ci: deps documentation

lint:
	stylua . -g '*.lua' -g '!deps/'
