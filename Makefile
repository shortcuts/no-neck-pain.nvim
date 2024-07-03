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
	./scripts/clone_deps.sh 1 || true

deps-lint:
	luarocks install argparse --force
	luarocks install luafilesystem --force
	luarocks install lanes --force
	luarocks install luacheck --force

test-ci: deps test

documentation:
	nvim --headless --noplugin -u ./scripts/minimal_init.lua -c "lua require('mini.doc').generate()" -c "qa!"

documentation-ci: deps documentation

lint:
	stylua . -g '*.lua' -g '!deps/' -g '!nightly/'
	luacheck plugin/ lua/

luals-ci:
	rm -rf .ci/lua-ls/log
	lua-language-server --configpath .luarc.json --logpath .ci/lua-ls/log --check .
	[ -f .ci/lua-ls/log/check.json ] && { cat .ci/lua-ls/log/check.json 2>/dev/null; exit 1; } || true

luals:
	mkdir -p .ci/lua-ls
	curl -sL "https://github.com/LuaLS/lua-language-server/releases/download/3.7.4/lua-language-server-3.7.4-darwin-x64.tar.gz" | tar xzf - -C "${PWD}/.ci/lua-ls"
	make luals-ci
