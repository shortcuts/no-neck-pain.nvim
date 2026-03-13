# v3 Audit Fixes — Fix 31 Remaining Test Failures

## TL;DR

> **Quick Summary**: Fix all 31 remaining test failures caused by agent-introduced regressions (bad `child.set_size`, unwanted WinEnter auto-registration, premature state initialization) and minor test infrastructure issues. Tasks 1-2 from the original plan are already complete.
> 
> **Deliverables**:
> - All 31 currently-failing tests passing (375 total test cases, 0 failures)
> - 3 agent-introduced regressions reverted (set_size, WinEnter auto-reg, early state init)
> - pathToFile config resolution fixed
> - Test infrastructure issues fixed (mappings vim.NIL, diagnostic child.start)
> - Window ordering assertions corrected in split and integration tests
> - `make lint && make test && make documentation` all passing
> 
> **Estimated Effort**: Medium
> **Parallel Execution**: YES - 3 waves
> **Critical Path**: Task 3 (remove set_size) + Task 4 (remove WinEnter auto-reg) → Task 8 (fix splits/integrations) → Task 10 (full verification) → F1-F4

---

## Context

### Original Request
Audit the codebase for the `feat/integrations` branch (PR #513). Find and fix all failing tests. Ensure `make lint`, `make test`, and `make documentation` all pass.

### Previous Work (Completed)
- **Task 1** (DONE): State nil safety + redraw field initialization in `state.lua`
- **Task 2** (DONE): Debouncer race condition fix in `api.lua`
- Full audit: ran `make test`, found 31 failures out of 375 test cases (246 passing)
- 3 explore agents investigated all failures and traced them to specific commits

### Root Cause Analysis (31 failures, 7 root causes)

**Root Cause 1: `child.set_size(10, 200)` in test hooks (~12 failures)**
Commit `561a326` ("chore: cleanup test pattern") added `child.set_size(10, 200)` to `pre_case` hooks of 8 test files, changing child Neovim from default 80 columns to 200 columns, WITHOUT updating hardcoded width assertions. Tests calibrated for 80 cols now get width 98 (200-100=100 padding, 50 per side, minus adjustments) instead of expected values.
- Files affected: test_buffers (5), test_commands (2), test_autocmds (1), test_options (1), test_colors (1), test_integrations (partial), test_scratchpad (1), test_API (partial)

**Root Cause 2: WinEnter auto-registration bug (~17 failures)**
Commit `d4c6e1c` ("Task 7: Auto-init side buffers on new tabs when globally enabled") added auto-tab-registration in `main.lua` lines 216-219. This auto-registers new tabs via WinEnter before TabEnter fires, causing: (a) non-auto-open tabs get unwanted side buffers, (b) TabEnter's `enable()` finds tab already registered and skips, (c) `nnp()` toggle on auto-registered tab DISABLES instead of no-op.
- Files affected: test_tabs (13), test_API (2), test_integrations (1), test_state_edge_cases (1)

**Root Cause 3: State initialization too early (3 failures)**
Commit `9eac3d0` ("fix(state): Initialize _G.NoNeckPain.state during module load") added `state:save()` during module load (init.lua lines 163-165), making `_G.NoNeckPain.state` always a table even before plugin is enabled. Tests expect `nil` until `enable()`.
- Files affected: test_event (1), test_state_edge_cases (1), test_tabs (1 — overlaps with RC2)

**Root Cause 4: pathToFile config resolution (1 failure)**
`config.lua:parse_deprecated_scratchPad()` constructs absolute path with `vim.fn.getcwd()` when `pathToFile == ""`, but `test_API.lua` expects relative `"no-neck-pain-left.norg"`.

**Root Cause 5: Test infrastructure issues (3 failures)**
- `test_mappings.lua` (2 failures): `child.lua_get()` cannot marshal `vim.NIL` cross-process — "Cannot convert given Lua type"
- `test_diagnostic.lua` (1 failure): "Child process is not running" — missing `child.start()` call

**Root Cause 6: Split window ordering (7 failures)**
`test_splits.lua` expects specific window ID ordering (e.g., `{1002, 1001, 1003, 1000}`) but gets different ordering (e.g., `{1002, 1001, 1000, 1003}`). Default 80 columns (no set_size in this file). Window creation order changed.

**Root Cause 7: Integration neo-tree window ordering (2 failures)**
Window IDs for left/right are swapped when neo-tree is open: `{1004, 1005, 1000, 1006}` vs expected `{1005, 1004, 1000, 1006}`.

### Metis Review
Metis consultation timed out. Self-review applied:
- Verified all 31 failures are mapped to root causes (no orphans)
- Confirmed Tasks 1-2 already complete — plan starts from Task 3
- Validated that removing agent-introduced code is the safest fix approach
- Guardrails set against scope creep (no new features, no refactoring)

---

## Work Objectives

### Core Objective
Fix all 31 remaining test failures by reverting agent-introduced regressions and fixing test infrastructure issues, achieving 0 failures across all 375 test cases.

### Concrete Deliverables
- 8 test files with `child.set_size(10, 200)` removed from pre_case hooks
- `main.lua` lines 216-219 removed (WinEnter auto-registration)
- `init.lua` lines 163-165 removed (early state initialization)
- `config.lua` pathToFile resolution fixed
- `test_mappings.lua` vim.NIL comparison fixed
- `test_diagnostic.lua` child.start() added
- `test_splits.lua` window ordering assertions updated
- `test_integrations.lua` neo-tree window ordering assertions updated

### Definition of Done
- [ ] `make test` passes with 0 failures (375 test cases)
- [ ] `make documentation` passes without errors
- [ ] `stylua --check . -g '*.lua' -g '!deps/' -g '!nightly/'` passes
- [ ] No regressions in previously-passing tests

### Must Have
- All 31 failing tests fixed and passing
- Removal of `child.set_size(10, 200)` from 8 test file hooks
- Removal of WinEnter auto-registration from main.lua
- Removal of early state initialization from init.lua
- pathToFile config resolution producing relative filenames
- test_mappings vim.NIL handling fixed
- test_diagnostic child.start() call added
- Split and integration window ordering assertions corrected

### Must NOT Have (Guardrails)
- **No new features**: This is strictly bug-fix and test-fix work
- **No unnecessary refactors**: Changes must be minimal and directly fix identified bugs
- **No public API changes**: All commands and config options must remain stable
- **No test rewrites**: Fix failing tests with minimal changes; don't rewrite test logic unless fundamentally broken
- **No documentation additions**: Only update docs if `make documentation` requires it
- **No config structure changes**: Preserve all config field names and types
- **No integration system redesign**: Fix integration bugs without restructuring
- **No adding child.set_size to files that don't have it**: Only REMOVE the bad set_size calls
- **No changing window creation order in plugin source**: Fix test assertions, not source window ordering (unless source is provably wrong)

---

## Verification Strategy

> **ZERO HUMAN INTERVENTION** — ALL verification is agent-executed. No exceptions.

### Test Decision
- **Infrastructure exists**: YES
- **Automated tests**: Tests-after (fix existing tests + verify fixes)
- **Framework**: MiniTest (via `make test`)
- **Test command**: `nvim --headless --noplugin -u ./scripts/minimal_init.lua -c "lua MiniTest.run(...)"`

### QA Policy
Every task MUST run relevant `make test-{file}` after changes and verify 0 failures.
Evidence saved to `.sisyphus/evidence/task-{N}-{scenario-slug}.txt`.

- **All tasks**: Use Bash — run `make test-{file}`, capture output, verify PASS count and 0 FAIL
- **Final verification**: Use Bash — run full `make test`, `make documentation`, `stylua --check`

---

## Execution Strategy

### Parallel Execution Waves

```
Wave 1 (Start Immediately — independent fixes, MAX PARALLEL):
├── Task 3: Remove child.set_size(10, 200) from 8 test files [quick]
├── Task 4: Remove WinEnter auto-registration from main.lua [quick]
├── Task 5: Remove early state initialization from init.lua [quick]
├── Task 6: Fix pathToFile config resolution [quick]
├── Task 7: Fix test infrastructure (mappings + diagnostic) [quick]

Wave 2 (After Wave 1 — fixes requiring Wave 1 changes):
├── Task 8: Fix test_splits.lua window ordering assertions [unspecified-high]
├── Task 9: Fix test_integrations.lua remaining failures [unspecified-high]

Wave 3 (After Wave 2 — full verification):
├── Task 10: Full make test + make documentation + stylua verification [deep]

Wave FINAL (After ALL tasks — independent review, 4 parallel):
├── Task F1: Plan compliance audit (oracle)
├── Task F2: Code quality review (unspecified-high)
├── Task F3: Real manual QA — full make test (unspecified-high)
├── Task F4: Scope fidelity check (deep)

Critical Path: Tasks 3+4+5 → Task 8 → Task 10 → F1-F4
Parallel Speedup: ~65% faster than sequential
Max Concurrent: 5 (Wave 1)
```

### Dependency Matrix

| Task | Depends On | Blocks |
|------|-----------|--------|
| 3 | — | 8, 9, 10 |
| 4 | — | 8, 9, 10 |
| 5 | — | 10 |
| 6 | — | 10 |
| 7 | — | 10 |
| 8 | 3, 4 | 10 |
| 9 | 3, 4 | 10 |
| 10 | 3-9 (ALL) | F1-F4 |
| F1-F4 | 10 | — |

### Agent Dispatch Summary

- **Wave 1**: **5** — T3 → `quick`, T4 → `quick`, T5 → `quick`, T6 → `quick`, T7 → `quick`
- **Wave 2**: **2** — T8 → `unspecified-high`, T9 → `unspecified-high`
- **Wave 3**: **1** — T10 → `deep`
- **FINAL**: **4** — F1 → `oracle`, F2 → `unspecified-high`, F3 → `unspecified-high`, F4 → `deep`

---

## Previously Completed Tasks

- [x] 1. State nil safety + redraw field initialization (state.lua)
- [x] 2. Debouncer race condition fix (api.lua)

---

## TODOs

- [x] 3. Remove `child.set_size(10, 200)` from 8 test file hooks

  **What to do**:
  - Remove `child.set_size(10, 200)` from the `pre_case` hook in these 8 test files:
    1. `tests/test_buffers.lua` — line 10 in `pre_case` hook
    2. `tests/test_commands.lua` — in `pre_case` hook
    3. `tests/test_autocmds.lua` — in `pre_case` hook
    4. `tests/test_options.lua` — in `pre_case` hook
    5. `tests/test_colors.lua` — in `pre_case` hook (this file originally had `child.set_size(80, 80)` INSIDE a specific test body, NOT in the hook — restore that if present)
    6. `tests/test_integrations.lua` — line 9 in `pre_case` hook
    7. `tests/test_scratchpad.lua` — in `pre_case` hook
    8. `tests/test_API.lua` — in `pre_case` hook
  - DO NOT touch `tests/test_splits.lua`, `tests/test_tabs.lua`, or `tests/test_mappings.lua` — these do NOT have `child.set_size(10, 200)` in hooks
  - After removing, all tests in these files should run with the MiniTest default child window size (80 columns), which is what the assertions were originally calibrated for
  - For `test_colors.lua` specifically: check if there was an original `child.set_size(80, 80)` call inside a test body (not the hook). If so, keep that — it's intentional per-test sizing. Only remove the one in the `pre_case` hook.

  **Must NOT do**:
  - Do not add `child.set_size` to files that don't already have it
  - Do not update any width assertions — the point is that default 80 cols matches existing assertions
  - Do not change test logic or add new tests
  - Do not touch any source (non-test) files in this task

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Simple deletion of one line from 8 files — mechanical, no logic needed
  - **Skills**: []
  - **Skills Evaluated but Omitted**:
    - `git-master`: Not needed — simple file edits, not git operations

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 4, 5, 6, 7)
  - **Blocks**: Tasks 8, 9, 10
  - **Blocked By**: None (can start immediately)

  **References**:

  **Pattern References** (existing code to follow):
  - `tests/test_splits.lua` — Example of a test file that does NOT have `child.set_size` in hook (this is the correct pattern)
  - `tests/test_tabs.lua` — Another file without `child.set_size` in hook

  **API/Type References**:
  - `child.set_size(rows, cols)` — MiniTest API that sets child Neovim terminal dimensions. Default is 80x24.

  **Test References**:
  - `tests/test_buffers.lua:10` — `child.set_size(10, 200)` to remove from pre_case
  - `tests/test_commands.lua` — `child.set_size(10, 200)` to remove from pre_case
  - `tests/test_autocmds.lua` — `child.set_size(10, 200)` to remove from pre_case
  - `tests/test_options.lua` — `child.set_size(10, 200)` to remove from pre_case
  - `tests/test_colors.lua` — `child.set_size(10, 200)` to remove from pre_case; may have original `child.set_size(80, 80)` in test body to preserve
  - `tests/test_integrations.lua:9` — `child.set_size(10, 200)` to remove from pre_case
  - `tests/test_scratchpad.lua` — `child.set_size(10, 200)` to remove from pre_case
  - `tests/test_API.lua` — `child.set_size(10, 200)` to remove from pre_case

  **WHY Each Reference Matters**:
  - Each test file reference shows exactly where to find and remove the bad `set_size` call
  - `test_splits.lua` shows the correct pattern (no set_size in hook) — files should look like this after fix
  - The tests were all written for 80-column default; the 200-column change broke all hardcoded width assertions

  **Acceptance Criteria**:

  - [ ] No `child.set_size(10, 200)` remains in any `pre_case` hook across all 8 files
  - [ ] `grep -r "set_size(10, 200)" tests/` returns 0 matches
  - [ ] `make test-buffers` shows improvement (fewer failures than before)
  - [ ] `make test-commands` shows improvement
  - [ ] `make test-colors` shows improvement

  **QA Scenarios**:

  ```
  Scenario: No set_size(10, 200) in any test hook
    Tool: Bash
    Preconditions: All 8 files edited
    Steps:
      1. Run `grep -rn "set_size(10, 200)" tests/`
      2. Assert 0 matches returned
    Expected Result: No occurrences of set_size(10, 200) in tests directory
    Failure Indicators: Any grep match returned
    Evidence: .sisyphus/evidence/task-3-no-set-size.txt

  Scenario: Buffer tests pass after set_size removal
    Tool: Bash
    Preconditions: child.set_size removed from test_buffers.lua
    Steps:
      1. Run `make test-buffers`
      2. Capture stdout
      3. Count FAIL occurrences
    Expected Result: Fewer failures than baseline 5 (ideally 0 for set_size-related failures)
    Failure Indicators: Same or more failures than baseline
    Evidence: .sisyphus/evidence/task-3-buffers.txt

  Scenario: Commands tests pass after set_size removal
    Tool: Bash
    Preconditions: child.set_size removed from test_commands.lua
    Steps:
      1. Run `make test-commands`
      2. Capture stdout
      3. Assert "FAIL" does not appear
    Expected Result: 0 failures in command tests
    Failure Indicators: Any "FAIL" in output
    Evidence: .sisyphus/evidence/task-3-commands.txt
  ```

  **Commit**: YES
  - Message: `fix(tests): remove incorrect child.set_size(10, 200) from test hooks`
  - Files: `tests/test_buffers.lua`, `tests/test_commands.lua`, `tests/test_autocmds.lua`, `tests/test_options.lua`, `tests/test_colors.lua`, `tests/test_integrations.lua`, `tests/test_scratchpad.lua`, `tests/test_API.lua`
  - Pre-commit: `make test-buffers && make test-commands`

- [x] 4. Remove WinEnter auto-registration from main.lua

  **What to do**:
  - Remove lines 216-219 from `lua/no-neck-pain/main.lua`:
    ```lua
    if state.enabled and not state:is_active_tab_registered() then
        state:set_tab(state.active_tab)
    end
    ```
  - This code was added by commit `d4c6e1c` ("Task 7: Auto-init side buffers on new tabs when globally enabled"). It auto-registers new tabs via the WinEnter autocmd BEFORE TabEnter fires, causing 17+ test failures.
  - The TabEnter autocmd in `init.lua` (lines 144-158) already correctly handles `enableOnTabEnter`. The removed code is redundant AND harmful.
  - After removal, verify the surrounding code still makes sense. The WinEnter handler should still do its other work (resize, skip buffer, etc.) — only remove the auto-registration block.
  - **IMPORTANT**: The exact line numbers may have shifted due to Task 1 changes. Search for the pattern `if state.enabled and not state:is_active_tab_registered() then` to find the correct location.

  **Must NOT do**:
  - Do not change any other WinEnter handler logic
  - Do not modify the TabEnter autocmd in init.lua
  - Do not add replacement logic — the TabEnter handler is sufficient
  - Do not change any test files in this task

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: 3-4 line deletion from one file
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 3, 5, 6, 7)
  - **Blocks**: Tasks 8, 9, 10
  - **Blocked By**: None (can start immediately)

  **References**:

  **Pattern References**:
  - `lua/no-neck-pain/main.lua:216-219` — The exact lines to remove (auto-registration block)
  - `lua/no-neck-pain/init.lua:144-158` — TabEnter autocmd that already handles `enableOnTabEnter` correctly

  **Test References**:
  - `tests/test_tabs.lua` — 13 failures caused by this code; should all resolve after removal
  - `tests/test_API.lua` — 2 failures from multi-tab tests caused by auto-registration

  **WHY Each Reference Matters**:
  - Lines 216-219 are the EXACT code to delete — nothing more, nothing less
  - init.lua TabEnter handler proves the removed code is redundant
  - test_tabs.lua is the primary verification target — 13 failures should resolve

  **Acceptance Criteria**:

  - [ ] No `is_active_tab_registered` call in WinEnter handler path of main.lua
  - [ ] `grep -n "is_active_tab_registered" lua/no-neck-pain/main.lua` returns 0 matches in the WinEnter handler section
  - [ ] `make test-tabs` passes with 0 failures (13 fixed)
  - [ ] `make test-API` shows improvement (2 multi-tab failures fixed)

  **QA Scenarios**:

  ```
  Scenario: WinEnter auto-registration code removed
    Tool: Bash
    Preconditions: main.lua edited
    Steps:
      1. Run `grep -n "is_active_tab_registered" lua/no-neck-pain/main.lua`
      2. Verify no matches are in the WinEnter handler section (around lines 200-230)
      3. Verify the grep output does NOT contain a line inside the WinEnter callback
    Expected Result: No auto-registration code in WinEnter handler
    Failure Indicators: Pattern found inside WinEnter handler
    Evidence: .sisyphus/evidence/task-4-no-auto-reg.txt

  Scenario: Tab tests pass after removing auto-registration
    Tool: Bash
    Preconditions: Auto-registration removed from main.lua
    Steps:
      1. Run `make test-tabs`
      2. Capture full stdout
      3. Assert "FAIL" does not appear in output
      4. Assert exit code is 0
    Expected Result: All 13 previously-failing tab tests pass
    Failure Indicators: Any "FAIL" in output
    Evidence: .sisyphus/evidence/task-4-tabs.txt

  Scenario: API multi-tab tests pass
    Tool: Bash
    Preconditions: Auto-registration removed
    Steps:
      1. Run `make test-API`
      2. Capture stdout
      3. Check for multi-tab related failures
    Expected Result: Multi-tab API tests pass (2 failures fixed)
    Failure Indicators: "FAIL" in multi-tab test output
    Evidence: .sisyphus/evidence/task-4-api.txt
  ```

  **Commit**: YES
  - Message: `fix(main): remove WinEnter auto-registration that breaks tab tests`
  - Files: `lua/no-neck-pain/main.lua`
  - Pre-commit: `make test-tabs`

- [x] 5. Remove early state initialization from init.lua

  **What to do**:
  - Remove lines 163-165 from `lua/no-neck-pain/init.lua`:
    ```lua
    if _G.NoNeckPain.state == nil then
        state:save()
    end
    ```
  - This code was added by commit `9eac3d0` ("fix(state): Initialize _G.NoNeckPain.state during module load"). It makes `_G.NoNeckPain.state` always a table even before the plugin is enabled. Tests expect `state` to be `nil` until `enable()` is called.
  - State initializes properly when `main.enable()` is called (which calls `state:set_tab()` which calls `state:save()`). The removed code is redundant.
  - **IMPORTANT**: The exact line numbers may have shifted. Search for the pattern `if _G.NoNeckPain.state == nil then` near `state:save()` to find the correct location.

  **Must NOT do**:
  - Do not change state initialization logic in `main.enable()` or `state:set_tab()`
  - Do not modify any test files in this task
  - Do not add alternative initialization logic

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: 3 line deletion from one file
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 3, 4, 6, 7)
  - **Blocks**: Task 10
  - **Blocked By**: None (can start immediately)

  **References**:

  **Pattern References**:
  - `lua/no-neck-pain/init.lua:163-165` — The exact lines to remove
  - `lua/no-neck-pain/main.lua` — `enable()` function where state properly initializes via `state:set_tab()` → `state:save()`

  **Test References**:
  - `tests/test_event.lua:22` — "skip() returns true when plugin is not enabled" — expects `_G.NoNeckPain.state` to be `nil`
  - `tests/test_state_edge_cases.lua:538` — "empty state initialization" — expects state to be `nil` before enable
  - `tests/test_tabs.lua:545` — "does not pick tab 1" — state should be `nil` before first enable

  **WHY Each Reference Matters**:
  - init.lua lines 163-165 are the EXACT code to delete
  - main.lua `enable()` proves state initializes properly without the removed code
  - Test references show the 3 specific tests that break due to premature initialization

  **Acceptance Criteria**:

  - [ ] No `_G.NoNeckPain.state == nil` check with `state:save()` in init.lua module-level code
  - [ ] `make test-event` passes with 0 failures
  - [ ] `_G.NoNeckPain.state` is `nil` before first `enable()` call

  **QA Scenarios**:

  ```
  Scenario: Early state initialization removed
    Tool: Bash
    Preconditions: init.lua edited
    Steps:
      1. Run `grep -n "state:save()" lua/no-neck-pain/init.lua`
      2. Verify no match at module level (should only appear inside function bodies, if at all)
    Expected Result: No module-level state:save() call
    Failure Indicators: state:save() found outside function body
    Evidence: .sisyphus/evidence/task-5-no-early-init.txt

  Scenario: Event test passes (state is nil before enable)
    Tool: Bash
    Preconditions: Early init removed
    Steps:
      1. Run `make test-event`
      2. Capture stdout
      3. Assert "FAIL" does not appear
    Expected Result: skip() test passes — state is nil
    Failure Indicators: "FAIL" in output
    Evidence: .sisyphus/evidence/task-5-event.txt
  ```

  **Commit**: YES
  - Message: `fix(init): remove premature state initialization on module load`
  - Files: `lua/no-neck-pain/init.lua`
  - Pre-commit: `make test-event`

- [x] 6. Fix pathToFile config resolution

  **What to do**:
  - In `lua/no-neck-pain/config.lua`, find the `parse_deprecated_scratchPad()` function (around line 359).
  - The issue: when `pathToFile` is `""` (the default), the function constructs an absolute path using `vim.fn.getcwd()`, producing something like `"/Users/k/Documents/no-neck-pain.nvim/no-neck-pain-left.norg"`. But `test_API.lua` expects the relative filename `"no-neck-pain-left.norg"`.
  - The fix: when `pathToFile` is `""`, store the RELATIVE filename (e.g., `"no-neck-pain-left.norg"`) in the config. Let `ui.lua:121` handle expansion via `vim.fn.expand()` at runtime when actually opening the file.
  - Check what `ui.lua:init_scratch_pad()` does with `pathToFile` — it should call `vim.fn.expand()` or `vim.fn.fnameescape()` on it. The config should store the unexpanded form.
  - The legacy `fileName` and `location` fields should still work: if `location` is set, use `location .. "/" .. fileName .. "-" .. side .. ".norg"`. If neither is set, use just `fileName .. "-" .. side .. ".norg"` (relative to cwd).

  **Must NOT do**:
  - Do not remove the deprecated `fileName`/`location` fields
  - Do not change scratchPad config structure
  - Do not change `ui.lua:init_scratch_pad()` behavior
  - Do not auto-create directories

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Small logic change in one function in config.lua
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 3, 4, 5, 7)
  - **Blocks**: Task 10
  - **Blocked By**: None (can start immediately)

  **References**:

  **Pattern References**:
  - `lua/no-neck-pain/config.lua:~359` — `parse_deprecated_scratchPad()` function — scope of change
  - `lua/no-neck-pain/ui.lua:85-124` — `init_scratch_pad()` — consumes `pathToFile`, calls `vim.fn.expand()`

  **Test References**:
  - `tests/test_API.lua` — "sets exposed methods" test expects `scratchPad.pathToFile` to be `"no-neck-pain-left.norg"` (relative), not absolute

  **WHY Each Reference Matters**:
  - `parse_deprecated_scratchPad()` is where the bug is — it constructs absolute path instead of relative
  - `init_scratch_pad()` shows how pathToFile is consumed — it expands at runtime, so config should store relative
  - test_API shows the expected format for the assertion

  **Acceptance Criteria**:

  - [ ] When `pathToFile` is `""` and `location` is `nil`, config stores relative filename like `"no-neck-pain-left.norg"`
  - [ ] `make test-API` passes with 0 failures for the "sets exposed methods" test

  **QA Scenarios**:

  ```
  Scenario: pathToFile stores relative filename
    Tool: Bash
    Preconditions: config.lua fix applied
    Steps:
      1. Run `make test-API`
      2. Capture stdout
      3. Assert "FAIL" does not appear for "sets exposed methods" test
    Expected Result: API test passes — pathToFile is relative
    Failure Indicators: "FAIL" mentioning pathToFile or scratchPad
    Evidence: .sisyphus/evidence/task-6-pathtofile.txt
  ```

  **Commit**: YES
  - Message: `fix(config): preserve relative pathToFile for scratchpad`
  - Files: `lua/no-neck-pain/config.lua`
  - Pre-commit: `make test-API`

- [x] 7. Fix test infrastructure (mappings vim.NIL + diagnostic child.start)

  **What to do**:
  - **test_mappings.lua (2 failures)**: Lines ~24 and ~139 use `child.lua_get()` to retrieve values that may be `vim.NIL`. The MiniTest child process cannot marshal `vim.NIL` across the process boundary — it throws "Cannot convert given Lua type".
  - Fix: Instead of `child.lua_get("vim.keymap...")` which returns `vim.NIL`, use an indirect approach:
    - Option A: Use `child.lua("return type(vim.keymap...)")` and assert the type string instead
    - Option B: Use `child.lua_get("vim.fn.maparg(...)")` which returns an empty string instead of vim.NIL
    - Option C: Wrap in `child.lua_get("tostring(vim.keymap...)")` to convert nil to string "nil"
  - Choose whichever approach best matches the existing test pattern in the file.
  - **test_diagnostic.lua (1 failure)**: "Child process is not running" — the test file is missing a `child.start()` call before running tests. Check if there's a `pre_case` hook or `pre_once` hook that should start the child. Compare with other test files like `test_buffers.lua` for the correct pattern.
  - Check whether `test_diagnostic.lua` is even in the Makefile's TESTFILES list. If not, it may have been added by an agent without being registered. If it IS in the list, add the missing `child.start()` in the appropriate hook. If NOT in the list, note this but still fix it since `make test` runs all test files.

  **Must NOT do**:
  - Do not rewrite test logic beyond fixing the vim.NIL comparison issue
  - Do not delete test cases
  - Do not change mapping logic in source code
  - Do not remove test_diagnostic.lua even if it's not in Makefile

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Two small fixes in two files — one comparison change, one missing function call
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 3, 4, 5, 6)
  - **Blocks**: Task 10
  - **Blocked By**: None (can start immediately)

  **References**:

  **Pattern References**:
  - `tests/test_buffers.lua` — Example of correct test file structure with `pre_case` hook containing `child.start()` and `child.setup()`
  - `tests/test_mappings.lua:~24` — First failure: `child.lua_get()` returning vim.NIL
  - `tests/test_mappings.lua:~139` — Second failure: same vim.NIL issue
  - `tests/test_diagnostic.lua` — Missing `child.start()` call

  **API/Type References**:
  - `child.lua_get(expr)` — MiniTest API that evaluates Lua expression in child and returns result. Cannot marshal vim.NIL.
  - `child.lua(expr)` — MiniTest API that evaluates Lua expression without returning value
  - `child.start()` — MiniTest API that starts the child Neovim process

  **WHY Each Reference Matters**:
  - test_buffers.lua shows the canonical hook pattern (child.start → child.setup → test)
  - test_mappings.lua lines show exactly where vim.NIL comparison breaks
  - MiniTest API knowledge is needed to choose the right fix approach

  **Acceptance Criteria**:

  - [ ] `make test-mappings` passes with 0 failures (2 fixed)
  - [ ] `test_diagnostic.lua` no longer crashes with "Child process is not running"
  - [ ] No `vim.NIL` is passed through `child.lua_get()` in test_mappings.lua

  **QA Scenarios**:

  ```
  Scenario: Mappings tests pass without vim.NIL error
    Tool: Bash
    Preconditions: vim.NIL comparison fixed
    Steps:
      1. Run `make test-mappings`
      2. Capture stdout
      3. Assert "FAIL" does not appear
      4. Assert "Cannot convert given Lua type" does not appear
    Expected Result: All mapping tests pass
    Failure Indicators: "FAIL" or "Cannot convert" in output
    Evidence: .sisyphus/evidence/task-7-mappings.txt

  Scenario: Diagnostic test doesn't crash
    Tool: Bash
    Preconditions: child.start() added to test_diagnostic.lua
    Steps:
      1. Run the diagnostic test file directly
      2. Assert "Child process is not running" does not appear
    Expected Result: Diagnostic test runs without child process error
    Failure Indicators: "Child process is not running" in output
    Evidence: .sisyphus/evidence/task-7-diagnostic.txt
  ```

  **Commit**: YES
  - Message: `fix(tests): fix mappings vim.NIL comparison and diagnostic child.start`
  - Files: `tests/test_mappings.lua`, `tests/test_diagnostic.lua`
  - Pre-commit: `make test-mappings`

- [ ] 8. Fix test_splits.lua window ordering assertions (7 failures)

  **What to do**:
  - After Tasks 3 and 4 are complete, run `make test-splits` to see which tests still fail.
  - **Root cause**: `test_splits.lua` does NOT have `child.set_size(10, 200)` — it uses default 80 columns. The failures are purely window ordering mismatches: tests expect specific window ID arrays like `{1002, 1001, 1003, 1000}` but get `{1002, 1001, 1000, 1003}`.
  - **Investigation needed**: Determine whether window ordering changed due to source code changes or is just non-deterministic. Steps:
    1. Run `make test-splits` and capture exact actual vs expected for each failure
    2. Check if the window IDs are correct but in wrong order, or if wrong windows are present
    3. If same windows but different order: update test assertions to match actual order
    4. If different windows: investigate source code changes that altered window creation
  - **Key pattern**: The `Helpers.expect.equality(child.get_wins_in_tab(), {...})` helper does EXACT array comparison. If window order is non-deterministic, consider using a sorted comparison or set comparison.
  - Check `tests/helpers.lua` for the `get_wins_in_tab()` implementation — does it sort? If not, the fix may need to sort both sides before comparing, OR update the expected values to match the consistent actual order.
  - **Prefer updating expected values** over changing comparison logic, IF the actual order is deterministic (same every run).

  **Must NOT do**:
  - Do not change window creation order in `lua/no-neck-pain/ui.lua`
  - Do not add sorting to plugin source code
  - Do not rewrite the test helper comparison functions unless necessary
  - Do not add `child.set_size` to this file

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: Requires investigation — run tests, analyze output, determine correct fix, update 7 assertions
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Task 9)
  - **Blocks**: Task 10
  - **Blocked By**: Tasks 3, 4

  **References**:

  **Pattern References**:
  - `lua/no-neck-pain/ui.lua:32-63` — `ui.move_sides()`: positions side buffers — determines window order
  - `lua/no-neck-pain/state.lua:346-353` — `get_unregistered_wins()`: filters wins from tabpage list

  **Test References**:
  - `tests/test_splits.lua` — 7 failing tests with window ordering mismatches
  - `tests/helpers.lua` — `get_wins_in_tab()` implementation and `expect.equality()` comparison logic

  **WHY Each Reference Matters**:
  - `move_sides()` determines where side buffers end up in the window list
  - `get_wins_in_tab()` may or may not sort results — affects whether order is deterministic
  - Each failing test shows exact expected vs actual, which guides whether to update expectations or fix logic

  **Acceptance Criteria**:

  - [ ] `make test-splits` passes with 0 failures (all 7 fixed)
  - [ ] Fix approach documented: either "updated expected values" or "changed comparison logic"

  **QA Scenarios**:

  ```
  Scenario: All split tests pass
    Tool: Bash
    Preconditions: Tasks 3, 4 completed; window ordering assertions updated
    Steps:
      1. Run `make test-splits`
      2. Capture full stdout
      3. Assert "FAIL" does not appear in output
      4. Assert exit code is 0
    Expected Result: All 7 previously-failing split tests pass
    Failure Indicators: Any "FAIL" in output
    Evidence: .sisyphus/evidence/task-8-splits.txt

  Scenario: Split tests stable on second run
    Tool: Bash
    Preconditions: First run passed
    Steps:
      1. Run `make test-splits` again
      2. Assert "FAIL" does not appear
    Expected Result: Same result — no flakiness in window ordering
    Failure Indicators: Different result than first run
    Evidence: .sisyphus/evidence/task-8-splits-stability.txt
  ```

  **Commit**: YES (groups with Task 9)
  - Message: `fix(tests): update window ordering assertions in splits and integrations`
  - Files: `tests/test_splits.lua`
  - Pre-commit: `make test-splits`

- [ ] 9. Fix test_integrations.lua remaining failures (2-3 failures)

  **What to do**:
  - After Tasks 3 and 4 are complete, run `make test-integrations` to see which tests still fail. Task 3 removes `child.set_size(10, 200)` from this file's hook, and Task 4 removes the WinEnter auto-registration. Some failures may self-resolve.
  - **Known remaining issues**:
    1. Neo-tree window ordering: Window IDs for left/right side buffers are swapped when neo-tree is open. Expected `{1005, 1004, 1000, 1006}` but got `{1004, 1005, 1000, 1006}`. The left and right side buffer IDs are in different positions.
    2. Checkhealth state sync: expects `{1001, 1000, 1002}` (3 windows with sides) but gets `{1000}` (1 window, no sides). This may be caused by Task 4's auto-registration issue — if so, it self-resolves after Task 4.
  - **Fix approach**:
    1. Run tests after Tasks 3+4 to see actual remaining failures
    2. For window ordering: update test expected values to match actual order (same windows, different order)
    3. For state issues: if still failing after Task 4, investigate whether the test's setup correctly enables NNP before asserting window state
  - This task is diagnostic-first: run tests, analyze remaining failures, then fix.

  **Must NOT do**:
  - Do not change integration detection logic
  - Do not alter neo-tree or NvimTree specific handling in source code
  - Do not add new integration tests
  - Do not change `child.set_size` (already removed by Task 3)

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: Requires investigation — must run tests after upstream fixes, diagnose remaining failures, update assertions
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Task 8)
  - **Blocks**: Task 10
  - **Blocked By**: Tasks 3, 4

  **References**:

  **Pattern References**:
  - `lua/no-neck-pain/state.lua:462-500` — `scan_layout()`: how integration windows are detected and positioned
  - `lua/no-neck-pain/ui.lua:32-63` — `ui.move_sides()`: how side buffers are positioned alongside integrations

  **Test References**:
  - `tests/test_integrations.lua` — Failing tests with neo-tree window ordering and checkhealth state
  - `tests/helpers.lua` — `get_wins_in_tab()` and assertion helpers

  **WHY Each Reference Matters**:
  - `scan_layout()` determines how integration windows affect side buffer positioning
  - Test file shows exact expected vs actual values for each failure
  - After Tasks 3+4, some failures may self-resolve — must check first

  **Acceptance Criteria**:

  - [ ] `make test-integrations` passes with 0 failures
  - [ ] All integration tests pass consistently (run twice to verify)

  **QA Scenarios**:

  ```
  Scenario: All integration tests pass
    Tool: Bash
    Preconditions: Tasks 3, 4 completed; remaining assertions updated
    Steps:
      1. Run `make test-integrations`
      2. Capture full stdout
      3. Assert "FAIL" does not appear in output
      4. Assert exit code is 0
    Expected Result: All integration tests pass
    Failure Indicators: Any "FAIL" in output
    Evidence: .sisyphus/evidence/task-9-integrations.txt
  ```

  **Commit**: YES (groups with Task 8)
  - Message: `fix(tests): update window ordering assertions in splits and integrations`
  - Files: `tests/test_integrations.lua`
  - Pre-commit: `make test-integrations`

- [ ] 10. Full verification — run complete test suite and documentation

  **What to do**:
  - This is the final verification task after ALL implementation and test fix tasks (3-9) are complete.
  - Run the following commands in sequence and verify all pass:
    1. `stylua --check . -g '*.lua' -g '!deps/' -g '!nightly/'` — Lint check
    2. `make test` — Full test suite (all 375 cases across all test files)
    3. `make documentation` — Documentation generation
  - If ANY failures occur:
    1. Identify which specific test(s) fail
    2. Trace back to the responsible root cause (RC1-RC7)
    3. Determine if it's a task that didn't fully resolve (e.g., Task 3 removed set_size but an assertion still expects wrong value)
    4. Fix the issue with minimal change
    5. Re-run the full suite to confirm no regressions
  - Run `make test` a second time after any fixes to confirm stability (no flaky tests).
  - **IMPORTANT**: Some tests may have OVERLAPPING root causes. For example, `test_buffers.lua` has failures from BOTH Root Cause 1 (set_size) and Root Cause 5 (Invalid channel). Task 3 fixes RC1, but RC5 ("Invalid channel: 140/142") may need investigation here. If buffer close crashes persist:
    1. Check if `vim.api.nvim_win_is_valid(win)` is called before `nvim_win_close(win)` in all close paths
    2. Check if this is a MiniTest child process timing issue (child crashes during rapid buffer operations)
    3. If it's a test infrastructure issue, add a small `vim.wait()` before the close operation in the test
  - Similarly, `test_scratchpad.lua` may have residual failures after Task 3 (set_size removal) if the `buflisted` assertion failure has a different cause.

  **Must NOT do**:
  - Do not skip any of the three verification commands
  - Do not mark as complete if ANY command fails
  - Do not add new features or refactoring during verification

  **Recommended Agent Profile**:
  - **Category**: `deep`
    - Reason: Must run full test suite, analyze any remaining failures, trace root causes, and fix with minimal changes
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Wave 3 (sequential, alone)
  - **Blocks**: Final Verification Wave (F1-F4)
  - **Blocked By**: Tasks 3-9 (ALL must be complete)

  **References**:

  **Pattern References**:
  - `Makefile` — All test targets, lint, documentation commands
  - All `tests/test_*.lua` files — Full test inventory
  - All `lua/no-neck-pain/*.lua` files — All source files that may have been modified

  **WHY Each Reference Matters**:
  - Makefile defines exact commands — must use these, not custom invocations
  - Test files are the comprehensive verification — all 375 cases must pass
  - Source files must be checked for unintended changes from earlier tasks

  **Acceptance Criteria**:

  - [ ] `stylua --check . -g '*.lua' -g '!deps/' -g '!nightly/'` exits 0
  - [ ] `make test` exits 0 with 0 failures across all 375 test cases
  - [ ] `make documentation` exits 0 with no errors
  - [ ] Second `make test` run also exits 0 (confirms no flaky tests)

  **QA Scenarios**:

  ```
  Scenario: Full lint check passes
    Tool: Bash
    Preconditions: All tasks 3-9 completed
    Steps:
      1. Run `stylua --check . -g '*.lua' -g '!deps/' -g '!nightly/'`
      2. Assert exit code is 0
    Expected Result: All Lua files pass style check
    Failure Indicators: Non-zero exit code, style diff output
    Evidence: .sisyphus/evidence/task-10-lint.txt

  Scenario: Full test suite passes
    Tool: Bash
    Preconditions: Lint passes
    Steps:
      1. Run `make test`
      2. Capture full stdout
      3. Assert "FAIL" does not appear in output
      4. Assert exit code is 0
      5. Count total tests — should be 375 or more
    Expected Result: 375/375 tests pass, 0 failures
    Failure Indicators: Any "FAIL" in output, non-zero exit code
    Evidence: .sisyphus/evidence/task-10-test-suite.txt

  Scenario: Documentation generation succeeds
    Tool: Bash
    Preconditions: Tests pass
    Steps:
      1. Run `make documentation`
      2. Assert exit code is 0
    Expected Result: Documentation generated without errors
    Failure Indicators: Non-zero exit code or error messages
    Evidence: .sisyphus/evidence/task-10-documentation.txt

  Scenario: Test suite stability (second run)
    Tool: Bash
    Preconditions: First test run passed
    Steps:
      1. Run `make test` again
      2. Assert "FAIL" does not appear in output
      3. Assert exit code is 0
    Expected Result: 375/375 tests pass on second run (no flaky tests)
    Failure Indicators: Any test that passed first time but fails second time
    Evidence: .sisyphus/evidence/task-10-stability.txt
  ```

  **Commit**: YES (if any fixes needed during verification)
  - Message: `chore: fix remaining test failures found during full verification`
  - Files: (any remaining fixes)
  - Pre-commit: `make test && make documentation`

---

## Final Verification Wave (MANDATORY — after ALL implementation tasks)

> 4 review agents run in PARALLEL. ALL must APPROVE. Rejection → fix → re-run.

- [ ] F1. **Plan Compliance Audit** — `oracle`
  Read the plan end-to-end. For each "Must Have": verify implementation exists (read file, run command). For each "Must NOT Have": search codebase for forbidden patterns — reject with file:line if found. Check evidence files exist in `.sisyphus/evidence/`. Compare deliverables against plan.
  Output: `Must Have [N/N] | Must NOT Have [N/N] | Tasks [N/N] | VERDICT: APPROVE/REJECT`

- [ ] F2. **Code Quality Review** — `unspecified-high`
  Run `make test` + `stylua --check . -g '*.lua' -g '!deps/' -g '!nightly/'`. Review all changed files for: empty catches, debug prints in prod, commented-out code, unused requires. Check AI slop: excessive comments, over-abstraction, generic names.
  Output: `Test [PASS/FAIL] | Lint [PASS/FAIL] | Files [N clean/N issues] | VERDICT`

- [ ] F3. **Real Manual QA — full make test** — `unspecified-high`
  Run `make test` twice to verify stability. Capture output for each run. If any run fails, report which test failed.
  Output: `Run 1 [PASS/FAIL] | Run 2 [PASS/FAIL] | Flaky tests [list] | VERDICT`

- [ ] F4. **Scope Fidelity Check** — `deep`
  For each task: read "What to do", read actual diff (`git diff`). Verify 1:1 — everything in spec was built (no missing), nothing beyond spec was built (no creep). Check "Must NOT do" compliance. Flag unaccounted changes.
  Output: `Tasks [N/N compliant] | Unaccounted [CLEAN/N files] | VERDICT`

---

## Commit Strategy

| Commit | Scope | Message | Files | Pre-commit |
|--------|-------|---------|-------|------------|
| 1 | Wave 1 | `fix(tests): remove incorrect child.set_size(10, 200) from test hooks` | 8 test files | `make test-buffers && make test-commands` |
| 2 | Wave 1 | `fix(main): remove WinEnter auto-registration that breaks tab tests` | main.lua | `make test-tabs` |
| 3 | Wave 1 | `fix(init): remove premature state initialization on module load` | init.lua | `make test-event` |
| 4 | Wave 1 | `fix(config): preserve relative pathToFile for scratchpad` | config.lua | `make test-API` |
| 5 | Wave 1 | `fix(tests): fix mappings vim.NIL comparison and diagnostic child.start` | test_mappings.lua, test_diagnostic.lua | `make test-mappings` |
| 6 | Wave 2 | `fix(tests): update window ordering assertions in splits and integrations` | test_splits.lua, test_integrations.lua | `make test-splits && make test-integrations` |
| 7 | Wave 3 | `chore: verify all 375 tests pass` | — | `make test && make documentation` |

---

## Success Criteria

### Verification Commands
```bash
make test           # Expected: 375/375 tests pass, 0 failures
make documentation  # Expected: exit 0, no errors
stylua --check . -g '*.lua' -g '!deps/' -g '!nightly/'  # Expected: exit 0
```

### Final Checklist
- [ ] All 31 previously-failing tests now pass
- [ ] All 246 previously-passing tests still pass (no regressions)
- [ ] `make test` exits with 0 failures
- [ ] `make documentation` succeeds
- [ ] `stylua` formatting check passes
- [ ] No new global mutable state introduced
- [ ] Public API unchanged (all commands work identically)
- [ ] All changes are minimal and scoped to identified bugs
- [ ] No `child.set_size(10, 200)` remaining in any test pre_case hook
- [ ] No WinEnter auto-registration code in main.lua
- [ ] No premature state:save() in init.lua module load
