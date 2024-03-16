.SUFFIXES:

TESTFILES=options mappings API splits tabs integrations buffers colors autocmds scratchpad commands

all:

test:
	nvim --version | head -n 1 && echo ''
	nvim --headless --noplugin -u ./scripts/minimal_init.lua \
		-c "lua MiniTest.run({ execute = { reporter = MiniTest.gen_reporter.stdout({ group_depth = 2 }) } })"

test-nightly:
	bob use nightly
	make test

test-0.8.3:
	bob use 0.8.3
	make test

$(addprefix test-, $(TESTFILES)): test-%:
	nvim --version | head -n 1 && echo ''
	nvim --headless --noplugin -u ./scripts/minimal_init.lua \
		-c "lua MiniTest.run_file('tests/test_$*.lua', { execute = { reporter = MiniTest.gen_reporter.stdout({ group_depth = 2 }) } })"

depsluals:
	@mkdir -p deps
	git clone --depth 1 https://github.com/nvim-lua/plenary.nvim deps/plenary
	git clone --depth 1 https://github.com/folke/neodev.nvim deps/neodev.nvim

deps:
	make depsluals
	git clone --depth 1 https://github.com/echasnovski/mini.nvim deps/mini.nvim
	git clone --depth 1 https://github.com/nvim-treesitter/nvim-treesitter deps/nvim-treesitter
	git clone --depth 1 https://github.com/nvim-treesitter/playground deps/playground
	git clone --depth 1 https://github.com/nvim-neotest/neotest deps/neotest
	git clone --depth 1 https://github.com/nvim-tree/nvim-tree.lua deps/nvimtree
	git clone --depth 1 https://github.com/nvim-neo-tree/neo-tree.nvim deps/neo-tree
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
	stylua . -g '*.lua' -g '!deps/' -g '!nightly/'

luals: deps
	rm -rf .ci/lua-language-server-log
	lua-language-server --configpath .luarc.json --logpath .ci/lua-language-server-log --check .
	[ -f .ci/lua-language-server-log/check.json ] && { cat .ci/lua-language-server-log/check.json 2>/dev/null; exit 1; } || true
