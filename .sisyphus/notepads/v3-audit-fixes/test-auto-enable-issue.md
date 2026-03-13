# Auto-Enable Test Issue Investigation

## Problem
9 tests in test_tabs.lua failing because state.enabled stays false after auto-enable via BufRead.

Tests use `scripts/init_auto_open.lua` with:
- enableOnVimEnter = true
- enableOnTabEnter = true

When test does: `child.restart()` → `child.cmd("e test.lua")` → `child.wait_for_plugin_enabled()`
Expected: state.enabled = true
Actual: state.enabled = false (times out after 2s)

## Key Findings

### Direct Neovim Test Works
Running: `nvim --headless -u scripts/test_init_simple.lua`
Result: state.enabled = true ✓

This proves the enable mechanism itself works fine. The issue is test-environment-specific.

### BufRead Handler Code Path
1. setup() registers BufRead autocmd (init.lua line 113)
2. On `:e test.lua`, BufRead should fire
3. BufRead calls NoNeckPain.enable(scope) (line 130)
4. enable() calls state:set_enabled() (main.lua line 159)
5. enable() calls main.init() (line 171)
6. main.init() calls state:save() (line 139)
7. state:save() calls helpers.set_state() which sets _G.NoNeckPain.state (helpers.lua line 124)

All code paths exist and work in direct Neovim.

### MiniTest Child Process Issue
Theory: BufRead may not fire properly in MiniTest child process, OR
state persistence across async boundaries is broken, OR
there's a timing race condition.

## Next Steps

Option 1: Change enableOnVimEnter from true to "safe" (adds debounce delay)
Option 2: Make tests explicitly call child.nnp() after file open as fallback
Option 3: Debug MiniTest child to confirm BufRead is actually firing
Option 4: Add explicit enable call in test initialization before files opened

## Hypothesis to Test
Change `enableOnVimEnter = true` → `enableOnVimEnter = "safe"` in init_auto_open.lua
This adds a 5ms debounce which might give vim.schedule callbacks time to complete.

## If "safe" works
- Update init_auto_open.lua
- Run make test-tabs
- If 9 failures → 0, apply fix
- Consider if "safe" mode is correct default for tests vs prod

## Hypothesis Test: enableOnVimEnter="safe" (2026-03-13)

**Hypothesis**: Changing `enableOnVimEnter = true` to `enableOnVimEnter = "safe"` would fix 9 failing test_tabs.lua tests by allowing debounced async enable time to complete properly.

**Test Result**: **FAILED** ✗

**Changes Made**:
- scripts/init_auto_open.lua line 10: `enableOnVimEnter = "safe"` (was `true`)
- Ran `make test-tabs`

**Outcome**:
- Still 9 failures (identical failures)
- Same test cases failing in same locations
- The debounce/vim.schedule approach does NOT solve the sync/async timing issue in test environment

**Conclusion**: The root cause is NOT about immediate vs debounced enable timing. The "safe" mode adds a 5ms schedule delay but tests still expect instant synchronous behavior.

**What This Tells Us**:
1. Tests run in MiniTest child environment with specific timing expectations
2. The failures are NOT due to enableOnVimEnter timing
3. Must investigate: 
   - test_tabs.lua expectations vs actual behavior
   - Whether MiniTest child env has different semantics for tab handling
   - Whether enableOnTabEnter is actually triggering properly

