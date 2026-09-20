.SUFFIXES:

LUA_LS_VERSION := $(shell cat .luals-version)
LUA_LS_TARGET := $(shell uname -s | tr '[:upper:]' '[:lower:]')-$(shell uname -m | sed -e 's/x86_64/x64/' -e 's/aarch64/arm64/')
LUA_LS_BIN := .ci/lua-ls/bin/lua-language-server

TESTFILES=API autocmds buffers callbacks colors commands config_validation constants debug_tabs diagnostic event helpers_coverage integrations log mappings options regression_issues scratchpad splits state_access_regression state_edge_cases tabs width_calculations

all: documentation lint luals test

test:
	make $(addprefix test-, $(TESTFILES))

test-race:
	for i in {1..5}; do make test || break ; done

test-nightly:
	bob use nightly
	make test

$(addprefix test-, $(TESTFILES)): test-%:
	nvim --version | head -n 1 && echo '' ; \
	nvim --headless --noplugin -u ./scripts/minimal_init.lua \
		-c "lua require('mini.test').setup({ silent = true })" \
		-c "lua MiniTest.run_file('tests/test_$*.lua', { silent = true })"

$(addprefix test-race-, $(TESTFILES)): test-race-%:
	for i in {1..10}; do make test-$* || break ; done

deps:
	./scripts/clone_deps.sh 1 || true

deps-lint:
	luarocks install argparse --force
	luarocks install luafilesystem --force
	luarocks install lanes --force

test-ci: deps test-race

documentation:
	nvim --headless --noplugin -u ./scripts/minimal_init.lua -c "lua require('mini.doc').generate()" -c "qa!"

documentation-ci: deps documentation

lint:
	stylua . -g '*.lua' -g '!deps/' -g '!nightly/'

luals-ci:
	rm -rf .ci/lua-ls/log
	lua-language-server --configpath .luarc.json --logpath .ci/lua-ls/log --check .
	[ -f .ci/lua-ls/log/check.json ] && { cat .ci/lua-ls/log/check.json 2>/dev/null; exit 1; } || true

luals-install: $(LUA_LS_BIN)

$(LUA_LS_BIN):
	mkdir -p .ci/lua-ls
	curl -sfL "https://github.com/LuaLS/lua-language-server/releases/download/$(LUA_LS_VERSION)/lua-language-server-$(LUA_LS_VERSION)-$(LUA_LS_TARGET).tar.gz" | tar xzf - -C "$(PWD)/.ci/lua-ls"

luals: luals-install
	PATH="$(PWD)/.ci/lua-ls/bin:$$PATH" $(MAKE) luals-ci
