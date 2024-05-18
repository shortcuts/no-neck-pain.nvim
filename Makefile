.SUFFIXES:

TESTFILES=options mappings API splits tabs integrations buffers colors autocmds scratchpad commands

all: documentation lint luals test

test:
	make deps
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
deps:
	git clone --depth 1 https://github.com/nvim-lua/plenary.nvim deps/plenary
	git clone --depth 1 https://github.com/nvim-neotest/nvim-nio deps/nvim-nio
	git clone --depth 1 https://github.com/echasnovski/mini.nvim deps/mini.nvim --branch stable
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
	git clone --depth 1 https://github.com/hedyhli/outline.nvim deps/outline
	git clone --depth 1 https://github.com/b0o/incline.nvim deps/incline

test-ci: deps test

documentation:
	nvim --headless --noplugin -u ./scripts/minimal_init.lua -c "lua require('mini.doc').generate()" -c "qa!"

documentation-ci: deps documentation

lint:
	stylua . -g '*.lua' -g '!deps/' -g '!nightly/'

luals-ci:
	rm -rf .ci/lua-ls/log
	lua-language-server --configpath .luarc.json --logpath .ci/lua-ls/log --check .
	[ -f .ci/lua-ls/log/check.json ] && { cat .ci/lua-ls/log/check.json 2>/dev/null; exit 1; } || true

luals:
	mkdir -p .ci/lua-ls
	curl -sL "https://github.com/LuaLS/lua-language-server/releases/download/3.7.4/lua-language-server-3.7.4-darwin-x64.tar.gz" | tar xzf - -C "${PWD}/.ci/lua-ls"
	make luals-ci
