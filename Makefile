all: test documentation

test:
	nvim --version | head -n 1 && echo ''
	nvim --headless --noplugin -u ./scripts/minimal_init.lua \
		-c "lua require('mini.test').setup()" \
		-c "lua MiniTest.run({ execute = { reporter = MiniTest.gen_reporter.stdout({ group_depth = 1 }) } })"

deps/mini.nvim:
	@mkdir -p deps
	git clone --depth 1 https://github.com/echasnovski/mini.nvim $@

test-ci: deps/mini.nvim
	nvim --headless --noplugin -u ./scripts/minimal_init.lua \
		-c "lua require('mini.test').setup()" \
		-c "lua MiniTest.run()"

documentation:
	$(NVIM_EXEC) --headless --noplugin -u ./scripts/minimal_init.lua -c "lua require('mini.doc').generate()" -c "qa!"

lint:
	stylua .
