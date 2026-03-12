# v3 Audit Fixes — Bug Fixes, Race Conditions, and Test Coverage

## TL;DR

> **Quick Summary**: Fix all 39 failing tests, resolve 13 identified source bugs (including 3 critical race conditions/nil safety issues), and add missing test coverage for the `feat/integrations` branch (PR #513).
> 
> **Deliverables**:
> - All 39 currently-failing tests passing
> - 13 source bugs fixed (3 critical, 4 high, 4 medium, 2 low)
> - Race conditions in debouncer and stale window IDs resolved
> - Nil safety guards added to state access methods
> - Missing test coverage added for edge cases
> - `make lint && make test && make documentation` all passing
> 
> **Estimated Effort**: Large
> **Parallel Execution**: YES - 4 waves
> **Critical Path**: Task 1 (state fixes) → Task 3 (UI threshold fix) → Task 7 (test fixes for tabs/API) → Task 11 (final integration tests) → F1-F4

---

## Context

### Original Request
Audit the codebase for the `feat/integrations` branch (PR #513) which fixes bugs listed in the PR and adds new features. Find and fix all failing tests, identify bugs and race conditions, and ensure `make lint`, `make test`, and `make documentation` all pass.

### Interview Summary
**Key Discussions**:
- Three explore agents completed full audits: core source (13 issues), test suite (39 failures root-caused), PR issue verification (8 issues checked)
- All 8 PR issues verified: 4 fully fixed, 4 partially fixed/mitigated
- Test framework is MiniTest with real Neovim child processes
- `make lint` fails due to `luacheck` not being installed (stylua passes)

**Research Findings**:
- Missing `redraw` field in `state:set_tab()` (line 170) causes nil access in `consume_redraw()` (line 389) and `set_layout_windows()` (line 410)
- Inconsistent threshold operator: `>` on line 139 of ui.lua vs `<=` on line 260 — creates off-by-one for padding == minSideBufferWidth
- `state:get_side_id()` (line 328) directly accesses `self.tabs[self.active_tab]` without nil check — called from 50+ locations
- Debouncer (api.lua:91-130) recursive call on line 115 creates new timer while `executing=true` — potential unbounded timer growth
- Scratchpad `pathToFile` defaults to empty string `""` — `vim.fn.fnameescape("")` produces empty edit command
- `columns` count includes side buffers in `scan_layout()` — tests expect 1 column after enable but get 3

### Metis Review
**Identified Gaps** (addressed):
- State nil access pattern validated: `self.tabs[self.active_tab]` is nil when tab not registered or `active_tab` is stale
- Debouncer race condition confirmed: recursive `api.debounce()` call on line 115 creates new timer context entry without cleaning up old one
- Test-to-source-bug mapping created (see individual tasks)
- Guardrails added for scope creep prevention
- `make lint` scope clarified: only `stylua` is required, `luacheck` is optional CI dependency

---

## Work Objectives

### Core Objective
Fix all identified source bugs and make all 39 failing tests pass, while ensuring no regressions in the existing 334 passing tests.

### Concrete Deliverables
- Fixed `lua/no-neck-pain/state.lua` — nil safety + `redraw` field initialization
- Fixed `lua/no-neck-pain/ui.lua` — threshold operator consistency
- Fixed `lua/no-neck-pain/util/api.lua` — debouncer race condition
- Fixed `lua/no-neck-pain/main.lua` — stale window ID checks, state cleanup order
- All 10 test files passing (373 total test cases)
- `make test && make documentation` both passing

### Definition of Done
- [ ] `make test` passes with 0 failures
- [ ] `make documentation` passes without errors
- [ ] `stylua . -g '*.lua' -g '!deps/' -g '!nightly/'` passes (the enforceable part of `make lint`)
- [ ] No regressions in previously-passing tests

### Must Have
- All 39 failing tests fixed and passing
- Nil safety guards on `state:get_side_id()` and related methods
- `redraw` field initialized in `state:set_tab()`
- Threshold operator consistency in `ui.lua`
- Debouncer race condition fixed
- State cleanup order corrected in `main.disable()`

### Must NOT Have (Guardrails)
- **No new features**: This is strictly bug-fix and test-fix work
- **No unnecessary refactors**: Changes must be minimal and directly fix identified bugs
- **No public API changes**: All commands and config options must remain stable
- **No test rewrites**: Fix failing tests with minimal changes; don't rewrite test logic unless fundamentally broken
- **No documentation additions**: Only update docs if `make documentation` requires it
- **No config structure changes**: Preserve all config field names and types
- **No integration system redesign**: Fix integration bugs without restructuring

---

## Verification Strategy

> **ZERO HUMAN INTERVENTION** — ALL verification is agent-executed. No exceptions.

### Test Decision
- **Infrastructure exists**: YES
- **Automated tests**: Tests-after (fix existing tests + verify fixes)
- **Framework**: MiniTest (via `make test`)
- **Test command**: `nvim --headless --noplugin -u ./scripts/minimal_init.lua -c "lua MiniTest.run(...)"`

### QA Policy
Every task MUST run `make test-{relevant_file}` after changes and verify 0 failures.
Evidence saved to `.sisyphus/evidence/task-{N}-{scenario-slug}.txt`.

- **All tasks**: Use Bash — run `make test-{file}`, capture output, verify PASS count and 0 FAIL
- **Final verification**: Use Bash — run full `make test`, `make documentation`, `stylua --check`

---

## Execution Strategy

### Parallel Execution Waves

```
Wave 1 (Start Immediately — foundation source fixes):
├── Task 1: State nil safety + redraw field initialization [deep]
├── Task 2: Debouncer race condition fix [deep]
├── Task 3: UI threshold operator consistency [quick]
├── Task 4: Scratchpad pathToFile resolution [quick]
├── Task 5: Lint compliance (stylua) [quick]

Wave 2 (After Wave 1 — dependent source fixes):
├── Task 6: Main.lua stale window ID + state cleanup order [deep]
├── Task 7: Fix test_tabs.lua + test_API.lua failures [unspecified-high]
├── Task 8: Fix test_scratchpad.lua failures [unspecified-high]
├── Task 9: Fix test_splits.lua window ordering failures [unspecified-high]

Wave 3 (After Wave 2 — remaining test fixes):
├── Task 10: Fix test_autocmds.lua + test_colors.lua failures [unspecified-high]
├── Task 11: Fix test_buffers.lua + test_integrations.lua + test_state_edge_cases.lua failures [unspecified-high]
├── Task 12: Fix test_width_calculations.lua failure [quick]

Wave 4 (After Wave 3 — full verification):
├── Task 13: Full make test + make documentation + stylua verification [deep]

Wave FINAL (After ALL tasks — independent review, 4 parallel):
├── Task F1: Plan compliance audit (oracle)
├── Task F2: Code quality review (unspecified-high)
├── Task F3: Real manual QA — full make test-race (unspecified-high)
├── Task F4: Scope fidelity check (deep)

Critical Path: Task 1 → Task 6 → Task 7 → Task 11 → Task 13 → F1-F4
Parallel Speedup: ~60% faster than sequential
Max Concurrent: 5 (Wave 1)
```

### Dependency Matrix

| Task | Depends On | Blocks |
|------|-----------|--------|
| 1 | — | 6, 7, 8, 9, 10, 11, 12 |
| 2 | — | 6, 10 |
| 3 | — | 9, 12 |
| 4 | — | 8 |
| 5 | — | 13 |
| 6 | 1, 2 | 7, 10, 11 |
| 7 | 1, 6 | 13 |
| 8 | 1, 4 | 13 |
| 9 | 1, 3 | 13 |
| 10 | 1, 2, 6 | 13 |
| 11 | 1, 6 | 13 |
| 12 | 1, 3 | 13 |
| 13 | 5, 7, 8, 9, 10, 11, 12 | F1-F4 |
| F1-F4 | 13 | — |

### Agent Dispatch Summary

- **Wave 1**: **5** — T1 → `deep`, T2 → `deep`, T3 → `quick`, T4 → `quick`, T5 → `quick`
- **Wave 2**: **4** — T6 → `deep`, T7 → `unspecified-high`, T8 → `unspecified-high`, T9 → `unspecified-high`
- **Wave 3**: **3** — T10 → `unspecified-high`, T11 → `unspecified-high`, T12 → `quick`
- **Wave 4**: **1** — T13 → `deep`
- **FINAL**: **4** — F1 → `oracle`, F2 → `unspecified-high`, F3 → `unspecified-high`, F4 → `deep`

---

## TODOs

- [x] 1. State nil safety + redraw field initialization

  **What to do**:
  - Add `redraw = false` to the tab initialization in `state:set_tab()` (state.lua line 170-182). The `redraw` field is set in `set_layout_windows()` (line 410) and read in `consume_redraw()` (line 389), but never initialized — causing nil access on first `consume_redraw()` call.
  - Add nil guard to `state:get_side_id()` (state.lua line 328-330). Currently does `return self.tabs[self.active_tab].wins.main[side]` without checking if `self.tabs[self.active_tab]` is nil. This is called from 50+ locations and crashes when tab is not registered.
  - Add nil guard to `state:get_columns()` (state.lua line 380-382). Same pattern — accesses `self.tabs[self.active_tab].wins.columns` without nil check.
  - Add nil guard to `state:get_integrations()` (state.lua line 219-221). Same pattern.
  - Add nil guard to `state:consume_redraw()` (state.lua line 388-394). Should return `false` if tab not registered.
  - Add nil guard to `state:set_side_id()` (state.lua line 337-339). Should no-op if tab not registered.
  - Add nil guard to `state:get_scratch_pad()` (state.lua line 555-557). Should return `false` if tab not registered.
  - Add nil guard to `state:set_scratch_pad()` (state.lua line 547-549). Should no-op if tab not registered.

  **Must NOT do**:
  - Do not change the state structure beyond adding `redraw = false`
  - Do not refactor method signatures
  - Do not add logging to every nil guard (only add where already present)

  **Recommended Agent Profile**:
  - **Category**: `deep`
    - Reason: Core state management changes affecting 50+ call sites; requires careful nil guard placement
  - **Skills**: []
  - **Skills Evaluated but Omitted**:
    - `playwright`: No browser interaction needed
    - `git-master`: Standard file edits, not git operations

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 2, 3, 4, 5)
  - **Blocks**: Tasks 6, 7, 8, 9, 10, 11, 12
  - **Blocked By**: None (can start immediately)

  **References**:

  **Pattern References**:
  - `lua/no-neck-pain/state.lua:101-105` — `is_active_tab_registered()` method shows the existing nil-check pattern: `self:has_tabs() and self.tabs[self.active_tab] ~= nil`
  - `lua/no-neck-pain/state.lua:127-135` — `get_tab()` method shows safe access pattern returning nil

  **API/Type References**:
  - `lua/no-neck-pain/state.lua:170-182` — `set_tab()` where `redraw` field must be added
  - `lua/no-neck-pain/state.lua:328-330` — `get_side_id()` needing nil guard
  - `lua/no-neck-pain/state.lua:380-382` — `get_columns()` needing nil guard
  - `lua/no-neck-pain/state.lua:388-394` — `consume_redraw()` needing nil guard
  - `lua/no-neck-pain/state.lua:219-221` — `get_integrations()` needing nil guard
  - `lua/no-neck-pain/state.lua:337-339` — `set_side_id()` needing nil guard
  - `lua/no-neck-pain/state.lua:547-557` — `get_scratch_pad()` and `set_scratch_pad()` needing nil guards

  **Test References**:
  - `tests/test_state_edge_cases.lua` — Tests that directly exercise state nil access patterns
  - `tests/test_tabs.lua` — Tests accessing `_G.NoNeckPain.state` for tab state assertions

  **WHY Each Reference Matters**:
  - `is_active_tab_registered()` shows the exact guard pattern to replicate: check `has_tabs()` AND `tabs[active_tab] ~= nil`
  - `get_tab()` shows the safe return-nil pattern for getters
  - Each line reference is where the specific fix must be applied

  **Acceptance Criteria**:

  - [ ] `redraw = false` present in `state:set_tab()` initialization block
  - [ ] `state:get_side_id()` returns `nil` (not crash) when `self.tabs[self.active_tab]` is nil
  - [ ] `state:get_columns()` returns `0` (not crash) when tab not registered
  - [ ] `state:consume_redraw()` returns `false` (not crash) when tab not registered
  - [ ] `state:get_integrations()` returns `{}` (not crash) when tab not registered
  - [ ] `make test-state_edge_cases` passes with 0 failures

  **QA Scenarios**:

  ```
  Scenario: State methods don't crash when tab is not registered
    Tool: Bash
    Preconditions: Plugin source files modified with nil guards
    Steps:
      1. Run `make test-state_edge_cases`
      2. Capture stdout
      3. Assert output contains "PASS" and does not contain "FAIL"
      4. Assert exit code is 0
    Expected Result: All state edge case tests pass
    Failure Indicators: Output contains "FAIL" or "Error" or exit code != 0
    Evidence: .sisyphus/evidence/task-1-state-edge-cases.txt

  Scenario: Redraw field is properly initialized
    Tool: Bash
    Preconditions: `redraw = false` added to set_tab()
    Steps:
      1. Run `grep -n "redraw" lua/no-neck-pain/state.lua`
      2. Verify line in set_tab() block (around line 170-183) contains `redraw = false`
      3. Run `make test-tabs`
      4. Assert output contains "PASS" and does not contain "FAIL"
    Expected Result: redraw field found in initialization AND tab tests pass
    Failure Indicators: grep finds no redraw in set_tab block, or tests fail
    Evidence: .sisyphus/evidence/task-1-redraw-init.txt
  ```

  **Commit**: YES
  - Message: `fix(state): add nil safety guards and initialize redraw field`
  - Files: `lua/no-neck-pain/state.lua`
  - Pre-commit: `make test-state_edge_cases`

- [x] 2. Debouncer race condition fix

  **What to do**:
  - Fix the recursive `api.debounce()` call in `api.lua` line 115. When `debouncer.executing` is true, the current code calls `api.debounce(context, callback, timeout)` recursively, which creates a NEW timer context entry. The old timer was already stopped on line 111, but the `executing` flag belongs to the old debouncer context object. The recursive call creates a fresh debouncer entry (line 95-96), losing the `executing` state.
  - The fix: instead of recursive call, set a flag like `debouncer.reschedule = true` and check it after `callback()` completes in the `vim.schedule` block (lines 119-128). If `reschedule` is true, create a new timer inline.
  - Ensure timer cleanup: verify `timer_stop_close()` is called on old timer before creating new one (already done on lines 99-101, but verify the recursive path also cleans up).
  - Verify the `debouncer.timer == timer` check on line 125 is correct after the fix (it should be, since we're no longer recursing).

  **Must NOT do**:
  - Do not change the debounce API signature
  - Do not add global timer tracking or registry (over-engineering)
  - Do not change the default timeout value

  **Recommended Agent Profile**:
  - **Category**: `deep`
    - Reason: Race condition fix requires understanding async timer lifecycle and Lua closure semantics
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 1, 3, 4, 5)
  - **Blocks**: Tasks 6, 10
  - **Blocked By**: None (can start immediately)

  **References**:

  **Pattern References**:
  - `lua/no-neck-pain/util/api.lua:73-80` — `timer_stop_close()` helper — the correct pattern for cleaning up libuv timers
  - `lua/no-neck-pain/util/api.lua:91-130` — Full debounce function — the entire function is the scope of change

  **API/Type References**:
  - `vim.loop.new_timer()` — libuv timer creation (Neovim API)
  - `timer:start(timeout, repeat, callback)` — timer start with repeat=0 for one-shot
  - `timer:stop()`, `timer:close()`, `timer:is_active()`, `timer:is_closing()` — timer lifecycle

  **External References**:
  - Neovim libuv docs: timer lifecycle — timers must be stopped then closed, not just abandoned

  **WHY Each Reference Matters**:
  - `timer_stop_close()` is the existing safe cleanup pattern — reuse it, don't invent a new one
  - The full debounce function at lines 91-130 is the complete scope — understand the closure over `debouncer` and `timer` variables

  **Acceptance Criteria**:

  - [ ] No recursive `api.debounce()` call inside the timer callback
  - [ ] `debouncer.reschedule` flag (or equivalent) used instead of recursion
  - [ ] Old timer is always cleaned up before new timer creation
  - [ ] `make test-autocmds` passes with 0 failures

  **QA Scenarios**:

  ```
  Scenario: Debouncer handles rapid invocations without timer leak
    Tool: Bash
    Preconditions: Debouncer fix applied
    Steps:
      1. Run `make test-autocmds`
      2. Capture stdout
      3. Assert output contains "PASS" and does not contain "FAIL"
      4. Assert exit code is 0
    Expected Result: All autocmd tests pass (they exercise debounced event handlers)
    Failure Indicators: "FAIL" in output, timeout, or exit code != 0
    Evidence: .sisyphus/evidence/task-2-debouncer-autocmds.txt

  Scenario: No recursive api.debounce call in source
    Tool: Bash
    Preconditions: Fix applied
    Steps:
      1. Run `grep -n "api.debounce" lua/no-neck-pain/util/api.lua`
      2. Verify the only occurrence of `api.debounce` is the function definition line, NOT inside the function body
    Expected Result: No recursive call found inside debounce function body
    Failure Indicators: `api.debounce` appears inside the timer callback (between lines ~105-128)
    Evidence: .sisyphus/evidence/task-2-no-recursion.txt
  ```

  **Commit**: YES
  - Message: `fix(api): resolve debouncer race condition with timer cleanup`
  - Files: `lua/no-neck-pain/util/api.lua`
  - Pre-commit: `make test-autocmds`

- [ ] 3. UI threshold operator consistency

  **What to do**:
  - In `ui.lua` line 139, the condition for creating a new side buffer is `wins[side].padding > helpers.get_config_field("minSideBufferWidth")`. This uses strict `>`.
  - In `ui.lua` line 260, the condition for returning 0 (no space) is `final <= helpers.get_config_field("minSideBufferWidth")`. This uses `<=`.
  - In `ui.lua` line 180, the condition for closing an existing side buffer is `padding < helpers.get_config_field("minSideBufferWidth")`. This uses strict `<`.
  - The semantics should be consistent: if `minSideBufferWidth` is 10, a padding of exactly 10 should be ALLOWED (it meets the minimum). Therefore:
    - Line 139: change `>` to `>=` (allow creation when padding equals min)
    - Line 180: keep `<` as-is (close only when BELOW minimum)
    - Line 260: change `<=` to `<` (return 0 only when BELOW minimum, matching line 180)
  - This makes the invariant: padding >= minSideBufferWidth → allowed; padding < minSideBufferWidth → not allowed.

  **Must NOT do**:
  - Do not change the `minSideBufferWidth` default value
  - Do not add new configuration options
  - Do not change the width calculation logic itself

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Two single-character changes on specific lines
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 1, 2, 4, 5)
  - **Blocks**: Tasks 9, 12
  - **Blocked By**: None (can start immediately)

  **References**:

  **Pattern References**:
  - `lua/no-neck-pain/ui.lua:139` — Creation threshold: `wins[side].padding > helpers.get_config_field("minSideBufferWidth")`
  - `lua/no-neck-pain/ui.lua:180` — Closure threshold: `padding < helpers.get_config_field("minSideBufferWidth")`
  - `lua/no-neck-pain/ui.lua:260` — Calculation return-zero threshold: `final <= helpers.get_config_field("minSideBufferWidth")`

  **WHY Each Reference Matters**:
  - These three lines define the complete decision boundary for side buffer creation/destruction — they MUST be consistent

  **Acceptance Criteria**:

  - [ ] Line 139 uses `>=` (was `>`)
  - [ ] Line 260 uses `<` (was `<=`)
  - [ ] Line 180 remains `<` (unchanged)
  - [ ] `make test-width_calculations` passes with 0 failures

  **QA Scenarios**:

  ```
  Scenario: Threshold operators are consistent
    Tool: Bash
    Preconditions: Threshold fix applied
    Steps:
      1. Run `grep -n "minSideBufferWidth" lua/no-neck-pain/ui.lua`
      2. Verify line 139 contains `>=`
      3. Verify line 180 contains `<` (strict less than, no equals)
      4. Verify line 260 contains `<` (strict less than, no equals)
      5. Run `make test-width_calculations`
      6. Assert 0 failures
    Expected Result: All three operators consistent AND width tests pass
    Failure Indicators: Operators still inconsistent or tests fail
    Evidence: .sisyphus/evidence/task-3-threshold-operators.txt
  ```

  **Commit**: YES (groups with Task 1)
  - Message: `fix(ui): use consistent threshold operator for minSideBufferWidth`
  - Files: `lua/no-neck-pain/ui.lua`
  - Pre-commit: `make test-width_calculations`

- [ ] 4. Scratchpad pathToFile resolution

  **What to do**:
  - In `ui.lua` line 104, `pathToFile` is accessed via `helpers.get_config_field("buffers")[side].scratchPad.pathToFile`. The default value is `""` (empty string, see config.lua scratchPad defaults).
  - When `pathToFile` is empty, `vim.fn.fnameescape("")` returns `""`, and `vim.cmd("edit ")` opens a new unnamed buffer instead of loading a file — causing test assertions on buffer name to fail.
  - The fix: in `ui.init_scratch_pad()`, if `pathToFile` is empty or nil, construct a default path using the legacy `fileName` and `location` fields (backward compat), or fall back to `vim.fn.getcwd() .. "/" .. "no-neck-pain-" .. side .. ".norg"`.
  - Check if the legacy `fileName`/`location` fields are populated first (they may be set by users who haven't migrated to `pathToFile`). If `location` is non-nil, use `location .. "/" .. fileName .. "-" .. side .. ".norg"`. If both are nil/empty, use current directory.
  - Ensure `vim.fn.expand()` is called on the final path to resolve `~` and environment variables.

  **Must NOT do**:
  - Do not remove the deprecated `fileName`/`location` fields
  - Do not change scratchPad config structure
  - Do not auto-create directories for the path

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Small logic addition in one function
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 1, 2, 3, 5)
  - **Blocks**: Task 8
  - **Blocked By**: None (can start immediately)

  **References**:

  **Pattern References**:
  - `lua/no-neck-pain/ui.lua:85-124` — Full `init_scratch_pad()` function — scope of change
  - `lua/no-neck-pain/ui.lua:104` — Current path access: `helpers.get_config_field("buffers")[side].scratchPad.pathToFile`
  - `lua/no-neck-pain/ui.lua:105` — Current edit command: `vim.cmd(string.format("edit %s", path))`

  **API/Type References**:
  - `lua/no-neck-pain/config.lua` — scratchPad config defaults showing `pathToFile = ""`, `fileName = "no-neck-pain"`, `location = nil`

  **Test References**:
  - `tests/test_scratchpad.lua` — 6 failing tests expecting buffer names to match file paths

  **WHY Each Reference Matters**:
  - `init_scratch_pad()` is the exact function to modify
  - Config defaults show the legacy migration path: `fileName` + `location` → `pathToFile`
  - Scratchpad tests show exact expected buffer name format

  **Acceptance Criteria**:

  - [ ] When `pathToFile` is `""` or nil, a default path is constructed using legacy fields or cwd
  - [ ] `vim.fn.expand()` is called on the final path
  - [ ] `make test-scratchpad` passes with 0 failures

  **QA Scenarios**:

  ```
  Scenario: Scratchpad creates files with correct default paths
    Tool: Bash
    Preconditions: pathToFile fix applied
    Steps:
      1. Run `make test-scratchpad`
      2. Capture stdout
      3. Assert output contains "PASS" and does not contain "FAIL"
      4. Assert exit code is 0
    Expected Result: All 6 previously-failing scratchpad tests pass
    Failure Indicators: "FAIL" in output or exit code != 0
    Evidence: .sisyphus/evidence/task-4-scratchpad.txt

  Scenario: Empty pathToFile doesn't produce empty edit command
    Tool: Bash
    Preconditions: Fix applied
    Steps:
      1. Run `grep -A5 "pathToFile" lua/no-neck-pain/ui.lua | grep -v "^--"`
      2. Verify there is a fallback/default path construction when pathToFile is empty
    Expected Result: Code contains a conditional check for empty pathToFile with fallback
    Failure Indicators: No fallback logic found
    Evidence: .sisyphus/evidence/task-4-pathToFile-fallback.txt
  ```

  **Commit**: YES (groups with Task 3)
  - Message: `fix(ui): handle empty scratchpad pathToFile gracefully`
  - Files: `lua/no-neck-pain/ui.lua`
  - Pre-commit: `make test-scratchpad`

- [ ] 5. Lint compliance (stylua)

  **What to do**:
  - Run `stylua --check . -g '*.lua' -g '!deps/' -g '!nightly/'` to verify formatting compliance
  - If any files are non-compliant, run `stylua . -g '*.lua' -g '!deps/' -g '!nightly/'` to auto-fix
  - Note: `make lint` also runs `luacheck` which requires external installation — this is a CI-only dependency. The local lint obligation is stylua only.
  - Verify `make documentation` passes (it must pass independently of lint)

  **Must NOT do**:
  - Do not install luacheck (it's a CI dependency, not local)
  - Do not change stylua configuration
  - Do not reformat files in deps/ or nightly/

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Single command execution and potential auto-fix
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 1, 2, 3, 4)
  - **Blocks**: Task 13
  - **Blocked By**: None (can start immediately)

  **References**:

  **Pattern References**:
  - `Makefile:44-46` — lint target: `stylua . -g '*.lua' -g '!deps/' -g '!nightly/'` then `luacheck plugin/ lua/`
  - `Makefile:39-40` — documentation target

  **WHY Each Reference Matters**:
  - Makefile shows exact commands to run

  **Acceptance Criteria**:

  - [ ] `stylua --check . -g '*.lua' -g '!deps/' -g '!nightly/'` exits with 0
  - [ ] `make documentation` exits with 0

  **QA Scenarios**:

  ```
  Scenario: Stylua formatting check passes
    Tool: Bash
    Preconditions: Any formatting issues auto-fixed
    Steps:
      1. Run `stylua --check . -g '*.lua' -g '!deps/' -g '!nightly/'`
      2. Assert exit code is 0
    Expected Result: All Lua files pass formatting check
    Failure Indicators: Exit code != 0, files listed as non-compliant
    Evidence: .sisyphus/evidence/task-5-stylua.txt

  Scenario: Documentation generation passes
    Tool: Bash
    Preconditions: None
    Steps:
      1. Run `make documentation`
      2. Assert exit code is 0
    Expected Result: Documentation generated successfully
    Failure Indicators: Exit code != 0 or error messages
    Evidence: .sisyphus/evidence/task-5-documentation.txt
  ```

  **Commit**: NO (formatting changes will be included in other commits)

- [ ] 6. Main.lua stale window ID checks + state cleanup order

  **What to do**:
  - **Stale window IDs in `main.init()`** (main.lua lines 126-136): Window validity is checked but then the window could be deleted between check and use. Add `vim.api.nvim_win_is_valid()` checks immediately before each `vim.api.nvim_set_current_win()` call.
  - **State cleanup order in `main.disable()`** (main.lua lines 492-498): Currently `state:refresh_tabs()` → `state:init()` is called on line 497 BEFORE namespace removal on lines 500-505. But `state:init()` resets `self.tabs = {}`, so by the time we try to remove namespaces, the side buffer IDs have been lost. Fix: save side IDs before `refresh_tabs`, then do namespace removal, THEN let state clean up. Note: this is ALREADY done correctly — sides are saved on line 489 before refresh_tabs. The issue is that `state:remove_namespace()` (line 502) accesses `self.namespaces` which is NOT reset by `state:init()`. Verify this is actually safe by reading the namespace removal code. If `state:init()` doesn't touch `self.namespaces`, the current code is fine.
  - **Unsafe `vim.cmd("rightbelow vertical split")` in `main.disable()`** (main.lua line 275): After this split command, verify a new window was actually created before using `vim.api.nvim_get_current_win()`. If the split fails silently (e.g., only window, E36), the code assumes a new window exists.
  - **Missing win validity check in `toggle_scratch_pad()`** (main.lua line 39): `vim.api.nvim_set_current_win(id)` is called after checking `id ~= nil` but not `vim.api.nvim_win_is_valid(id)`. Add validity check.
  - **Missing win validity check on line 45**: `vim.api.nvim_set_current_win(state:get_previously_focused_win())` — should check validity first.

  **Must NOT do**:
  - Do not restructure enable/disable flow
  - Do not change callback invocation order
  - Do not modify augroup creation logic

  **Recommended Agent Profile**:
  - **Category**: `deep`
    - Reason: Multiple safety checks across main orchestration logic; must understand control flow
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Wave 2 (with Tasks 7, 8, 9 — but this task should complete first in Wave 2 as others may depend on it)
  - **Blocks**: Tasks 7, 10, 11
  - **Blocked By**: Tasks 1, 2

  **References**:

  **Pattern References**:
  - `lua/no-neck-pain/main.lua:126-136` — Window validity checks in `init()`: checks `is_valid` then uses ID later
  - `lua/no-neck-pain/main.lua:25-48` — `toggle_scratch_pad()`: window set without validity check
  - `lua/no-neck-pain/main.lua:275` — `vim.cmd("rightbelow vertical split")` without verification
  - `lua/no-neck-pain/main.lua:489-505` — `disable()` cleanup sequence
  - `lua/no-neck-pain/state.lua:54-58` — `state:init()` — what gets reset (tabs, active_tab, enabled)
  - `lua/no-neck-pain/state.lua:528-538` — `state:remove_namespace()` — uses `self.namespaces`, not `self.tabs`

  **WHY Each Reference Matters**:
  - Lines 126-136 show the pattern where stale IDs can crash — add `is_valid` guard immediately before `set_current_win`
  - `state:init()` at line 54-58 shows it does NOT reset `self.namespaces` — so namespace removal after `init()` is safe
  - `toggle_scratch_pad()` at line 39 calls `set_current_win(id)` after only nil check, missing validity

  **Acceptance Criteria**:

  - [ ] Every `vim.api.nvim_set_current_win()` call in main.lua is preceded by `vim.api.nvim_win_is_valid()` check
  - [ ] `main.disable()` state cleanup order is verified safe (namespace removal uses `self.namespaces`, not `self.tabs`)
  - [ ] `make test-tabs` passes with 0 failures
  - [ ] `make test-commands` passes with 0 failures

  **QA Scenarios**:

  ```
  Scenario: Main.lua window validity guards are in place
    Tool: Bash
    Preconditions: Validity checks added
    Steps:
      1. Run `grep -n "nvim_set_current_win" lua/no-neck-pain/main.lua`
      2. For each occurrence, verify the preceding line contains `nvim_win_is_valid` or equivalent guard
      3. Run `make test-tabs`
      4. Assert 0 failures
    Expected Result: All set_current_win calls are guarded AND tab tests pass
    Failure Indicators: Unguarded set_current_win calls or test failures
    Evidence: .sisyphus/evidence/task-6-window-guards.txt

  Scenario: Disable doesn't crash on namespace cleanup
    Tool: Bash
    Preconditions: State cleanup verified
    Steps:
      1. Run `make test-commands`
      2. Capture stdout
      3. Assert 0 failures
    Expected Result: All command tests including toggle on/off pass
    Failure Indicators: "FAIL" in output mentioning namespace or state errors
    Evidence: .sisyphus/evidence/task-6-disable-cleanup.txt
  ```

  **Commit**: YES
  - Message: `fix(main): add window validity checks and fix state cleanup order`
  - Files: `lua/no-neck-pain/main.lua`
  - Pre-commit: `make test-tabs && make test-commands`

- [ ] 7. Fix test_tabs.lua + test_API.lua failures (10 + 2 = 12 failures)

  **What to do**:
  - After Task 1 (state nil safety + redraw) and Task 6 (main.lua fixes) are complete, run `make test-tabs` and `make test-API` to see which tests now pass.
  - **Root causes for test_tabs.lua failures (10 tests)**:
    - `_G.NoNeckPain.state` is nil — should be fixed by Task 1 (nil safety guards)
    - Tab state structure mismatch (missing `redraw` field) — fixed by Task 1
    - Integration `columns` field value differs from expected — `scan_layout()` counts ALL windows including side buffers as columns. Tests expect `columns = 1` after enable, but get `columns = 3` (left + main + right). Investigate whether the test expectation is wrong or the column counting logic is wrong.
    - If column counting is correct (3 columns IS the right answer with side buffers), update test assertions to match.
    - If column counting should exclude side buffers, fix `set_layout_windows()` to skip side buffer windows.
  - **Root causes for test_API.lua failures (2 tests)**:
    - Same `columns` field issue — tests expect 1 column but get 3
  - For each remaining failure: read the test, understand the assertion, compare with actual behavior, and fix EITHER the test assertion OR the source code (whichever is wrong).
  - **Decision principle**: If the test was written for the NEW v3 behavior (feat/integrations branch), the test is likely correct and the source needs fixing. If the test is from main branch and the behavior intentionally changed in v3, update the test.

  **Must NOT do**:
  - Do not rewrite test structure or organization
  - Do not add new test cases (that's Task 12's scope if needed)
  - Do not change column counting semantics without understanding the full impact

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: Requires careful investigation of column counting semantics + updating multiple assertions
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES (after Wave 1 + Task 6)
  - **Parallel Group**: Wave 2 (with Tasks 8, 9)
  - **Blocks**: Task 13
  - **Blocked By**: Tasks 1, 6

  **References**:

  **Pattern References**:
  - `lua/no-neck-pain/state.lua:402-418` — `set_layout_windows()`: counts columns including all leaf windows
  - `lua/no-neck-pain/state.lua:462-500` — `scan_layout()`: orchestrates layout scanning
  - `lua/no-neck-pain/state.lua:76-78` — `init_columns()`: resets to 0 before recount

  **Test References**:
  - `tests/test_tabs.lua` — 10 failing tests; check assertions on `_G.NoNeckPain.state.tabs[N].wins.columns`
  - `tests/test_API.lua` — 2 failing tests; same `columns` assertions

  **WHY Each Reference Matters**:
  - `set_layout_windows()` is where columns are counted — understanding this logic tells you whether 3 is correct or wrong
  - Test files show exact assertions to compare against

  **Acceptance Criteria**:

  - [ ] `make test-tabs` passes with 0 failures (all 10 fixed)
  - [ ] `make test-API` passes with 0 failures (all 2 fixed)
  - [ ] Column counting semantics are consistent between source and tests

  **QA Scenarios**:

  ```
  Scenario: All tab tests pass
    Tool: Bash
    Preconditions: Tasks 1 and 6 completed, column assertions fixed
    Steps:
      1. Run `make test-tabs`
      2. Capture full stdout
      3. Assert "FAIL" does not appear in output
      4. Assert exit code is 0
    Expected Result: All tab tests pass including TabEnter, tabnew, tabclose
    Failure Indicators: Any "FAIL" in output
    Evidence: .sisyphus/evidence/task-7-tabs.txt

  Scenario: All API tests pass
    Tool: Bash
    Preconditions: Column semantics aligned
    Steps:
      1. Run `make test-API`
      2. Assert 0 failures
    Expected Result: All API tests pass
    Failure Indicators: Any "FAIL" in output
    Evidence: .sisyphus/evidence/task-7-api.txt
  ```

  **Commit**: YES (groups with Task 6)
  - Message: `fix(tests): align tab and API test assertions with corrected column counting`
  - Files: `tests/test_tabs.lua`, `tests/test_API.lua`, optionally `lua/no-neck-pain/state.lua`
  - Pre-commit: `make test-tabs && make test-API`

- [ ] 8. Fix test_scratchpad.lua failures (6 failures)

  **What to do**:
  - After Task 1 (state nil safety) and Task 4 (pathToFile resolution) are complete, run `make test-scratchpad` to see which tests now pass.
  - **Root cause**: Scratchpad buffer names are empty string `""` instead of expected file paths. Task 4 fixes the pathToFile resolution. These 6 tests should pass after Task 4.
  - If any still fail, investigate:
    - Is the buffer name being set correctly after `vim.cmd("edit <path>")`?
    - Is `vim.api.nvim_buf_get_name()` returning the expected format?
    - Are tests checking exact path format (absolute vs relative)?
  - Fix any remaining assertion mismatches by aligning test expectations with actual behavior.

  **Must NOT do**:
  - Do not rewrite scratchpad logic beyond what Task 4 already fixes
  - Do not change scratchPad config defaults

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: Requires running tests, diagnosing any remaining failures, and fixing assertions
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Tasks 7, 9)
  - **Blocks**: Task 13
  - **Blocked By**: Tasks 1, 4

  **References**:

  **Test References**:
  - `tests/test_scratchpad.lua` — 6 failing tests checking buffer names after scratchpad enable

  **Pattern References**:
  - `lua/no-neck-pain/ui.lua:85-124` — `init_scratch_pad()` as fixed by Task 4

  **WHY Each Reference Matters**:
  - Test file shows exact expected buffer name format
  - Fixed `init_scratch_pad()` is the source of the correct path

  **Acceptance Criteria**:

  - [ ] `make test-scratchpad` passes with 0 failures (all 6 fixed)

  **QA Scenarios**:

  ```
  Scenario: All scratchpad tests pass
    Tool: Bash
    Preconditions: Tasks 1 and 4 completed
    Steps:
      1. Run `make test-scratchpad`
      2. Capture full stdout
      3. Assert "FAIL" does not appear in output
      4. Assert exit code is 0
    Expected Result: All 6 previously-failing scratchpad tests pass
    Failure Indicators: Any "FAIL" in output
    Evidence: .sisyphus/evidence/task-8-scratchpad.txt
  ```

  **Commit**: YES (groups with Task 7 if test-only changes)
  - Message: `fix(tests): align scratchpad test assertions with corrected pathToFile resolution`
  - Files: `tests/test_scratchpad.lua`
  - Pre-commit: `make test-scratchpad`

- [ ] 9. Fix test_splits.lua window ordering failures (7 failures)

  **What to do**:
  - After Task 1 (state nil safety) and Task 3 (threshold fix) are complete, run `make test-splits` to see which tests now pass.
  - **Root cause**: Window ordering in `nvim_tabpage_list_wins()` differs from expected. Tests assert specific window ID positions (e.g., `{1002, 1001, 1003, 1000}`) but get different ordering (e.g., `{1002, 1001, 1000, 1003}`).
  - The window ordering from `nvim_tabpage_list_wins()` can vary based on window creation order and split direction. The tests should NOT depend on exact window ID ordering.
  - **Fix approach**: 
    1. First, determine if the test helper functions use exact ordering or set comparison. Check `tests/helpers.lua` for assertion patterns.
    2. If tests use exact ordering, update assertions to use set comparison or sort before comparing.
    3. If the issue is that side buffers appear in unexpected positions, check if `ui.move_sides()` is correctly moving them.
  - Check if the window count is correct even if order differs — tests might just need to assert on count + membership rather than exact order.

  **Must NOT do**:
  - Do not change window creation order in ui.lua
  - Do not modify `nvim_tabpage_list_wins` behavior
  - Do not add sorting to the plugin source code (only to test assertions if needed)

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: Requires understanding window creation semantics and test assertion patterns
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Tasks 7, 8)
  - **Blocks**: Task 13
  - **Blocked By**: Tasks 1, 3

  **References**:

  **Test References**:
  - `tests/test_splits.lua` — 7 failing tests with window ordering mismatches
  - `tests/helpers.lua` — Test utility functions including any window assertion helpers

  **Pattern References**:
  - `lua/no-neck-pain/ui.lua:32-63` — `ui.move_sides()`: moves side buffers to correct positions
  - `lua/no-neck-pain/state.lua:346-353` — `get_unregistered_wins()`: filters wins from tabpage list

  **WHY Each Reference Matters**:
  - `move_sides()` is what positions side buffers — if it's not working, window order will be wrong
  - Test helpers show how window assertions are structured — whether they use exact order or membership

  **Acceptance Criteria**:

  - [ ] `make test-splits` passes with 0 failures (all 7 fixed)
  - [ ] Fix is in test assertions (not source) if window ordering is non-deterministic

  **QA Scenarios**:

  ```
  Scenario: All split tests pass
    Tool: Bash
    Preconditions: Tasks 1 and 3 completed, window ordering assertions fixed
    Steps:
      1. Run `make test-splits`
      2. Capture full stdout
      3. Assert "FAIL" does not appear in output
      4. Assert exit code is 0
    Expected Result: All 7 previously-failing split tests pass
    Failure Indicators: Any "FAIL" in output
    Evidence: .sisyphus/evidence/task-9-splits.txt
  ```

  **Commit**: YES (groups with Task 7)
  - Message: `fix(tests): fix window ordering assertions in split tests`
  - Files: `tests/test_splits.lua`, optionally `tests/helpers.lua`
  - Pre-commit: `make test-splits`

- [ ] 10. Fix test_autocmds.lua (3 failures) + test_colors.lua (1 failure)

  **What to do**:
  - After Tasks 1, 2, and 6 are complete, run `make test-autocmds` and `make test-colors` to see which tests now pass thanks to upstream fixes.
  - **Root causes (autocmds)**:
    1. VimEnter autocmd test: State is nil when `enableOnVimEnter` fires because `init()` tries to access state before it's fully initialized. Task 1's nil safety guards should fix this. If not, ensure `init()` checks `S.enabled` before accessing tab state.
    2. Autocmd not deleted on disable: When the plugin is disabled, the `skipEnteringNoNeckPainBuffer` autocmd should be cleaned up. Check `main.lua` `disable()` at lines 442-523 — verify autocmd deletion is present.
    3. ScratchPad skip logic: `skipEnteringNoNeckPainBuffer` should NOT skip when scratchPad is enabled. Check `util/event.lua:skip_entering()` logic — it should return early (don't skip) if `scratchpad_enabled` is true for the current tab.
  - **Root cause (colors)**: State nil access when checking window validity for color application. Task 1's nil guards should fix this. Verify color application in `colors.lua` uses safe state access.
  - Fix any remaining assertion mismatches after upstream tasks have been applied.

  **Must NOT do**:
  - Do not change autocmd event registration logic beyond fixing cleanup
  - Do not alter color calculation algorithms

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: Requires running tests, tracing event flow through multiple modules, fixing subtle state timing issues
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 3 (with Tasks 11, 12)
  - **Blocks**: Task 13
  - **Blocked By**: Tasks 1, 2, 6

  **References**:

  **Test References**:
  - `tests/test_autocmds.lua` — 3 failing tests: VimEnter enable, autocmd cleanup on disable, scratchPad skip
  - `tests/test_colors.lua` — 1 failing test: color application with nil state

  **Pattern References**:
  - `lua/no-neck-pain/main.lua:442-523` — `disable()` function, where autocmd cleanup should happen
  - `lua/no-neck-pain/util/event.lua:1-112` — Event skip logic including `skip_entering()` 
  - `lua/no-neck-pain/colors.lua` — Color application functions that may access state unsafely
  - `lua/no-neck-pain/main.lua:97-140` — `init()` function where VimEnter triggers

  **WHY Each Reference Matters**:
  - `disable()` must clean up autocmds — missing deletion causes test to find stale autocmd
  - `event.lua` has the scratchPad skip exemption logic — if it's not checking `scratchpad_enabled`, the skip will incorrectly fire
  - `colors.lua` may call state methods without nil guards — Task 1 fixes state, but color code may also need guarding
  - `init()` is the VimEnter entry point — understanding its flow reveals where nil state causes the crash

  **Acceptance Criteria**:

  - [ ] `make test-autocmds` passes with 0 failures (all 3 fixed)
  - [ ] `make test-colors` passes with 0 failures (1 fixed)

  **QA Scenarios**:

  ```
  Scenario: All autocmd tests pass
    Tool: Bash
    Preconditions: Tasks 1, 2, 6 completed
    Steps:
      1. Run `make test-autocmds`
      2. Capture full stdout
      3. Assert "FAIL" does not appear in output
      4. Assert exit code is 0
    Expected Result: All 3 previously-failing autocmd tests pass
    Failure Indicators: Any "FAIL" in output, non-zero exit code
    Evidence: .sisyphus/evidence/task-10-autocmds.txt

  Scenario: All color tests pass
    Tool: Bash
    Preconditions: Tasks 1, 6 completed
    Steps:
      1. Run `make test-colors`
      2. Capture full stdout
      3. Assert "FAIL" does not appear in output
      4. Assert exit code is 0
    Expected Result: 1 previously-failing color test passes
    Failure Indicators: Any "FAIL" in output
    Evidence: .sisyphus/evidence/task-10-colors.txt
  ```

  **Commit**: YES (groups with Task 11)
  - Message: `fix(tests): fix autocmd and color test failures with state safety and event logic`
  - Files: `tests/test_autocmds.lua`, `tests/test_colors.lua`, optionally `lua/no-neck-pain/util/event.lua`, `lua/no-neck-pain/colors.lua`
  - Pre-commit: `make test-autocmds && make test-colors`

- [ ] 11. Fix test_buffers.lua (2 failures) + test_integrations.lua (3 failures) + test_state_edge_cases.lua (3 failures)

  **What to do**:
  - After Tasks 1 and 6 are complete, run the three test suites to see which tests now pass.
  - **Root causes (buffers)**: "Invalid channel" errors when closing side buffers. This happens when `nvim_win_close()` is called on a window whose associated channel/buffer has already been invalidated. Task 6 adds window validity checks to `main.lua` which should prevent this. If tests still fail:
    1. Check if `vim.api.nvim_win_is_valid(win)` is called before `nvim_win_close(win)` in all close paths
    2. Check if buffer is still valid with `vim.api.nvim_buf_is_valid(buf)` before operations
  - **Root causes (integrations)**: 
    1. Neo-tree window ordering: `scan_layout()` may return windows in unexpected order when neo-tree is present. Check `state.lua:462-500` `scan_layout()` — it walks `nvim_tabpage_list_wins()` and categorizes by filetype. Neo-tree windows at position "left" should be detected and their width subtracted from left side padding.
    2. `checkhealth` nil state: Integration health check accesses state that may be nil before plugin is enabled. Add nil guard.
    3. Layout scanning returns 3 columns instead of 1: When integrations are present, column count includes integration windows. Task 1 fixes `get_columns()` nil guard but the column counting logic itself in `set_layout_windows()` (state.lua:402-418) may need to exclude integration windows from column count.
  - **Root causes (state edge cases)**:
    1. Layout returns 3 columns vs expected 1: Same root cause as integrations — column counting includes NNP side buffers. After Task 1 fixes, verify column count reflects only user-created splits.
    2. State recovery returns `false` vs expected `true`: After disable+re-enable cycle, state may not properly reinitialize. Check `init()` flow after `disable()`.
    3. State nil access on rapid toggle: Fast enable/disable/enable may hit uninitialized state. Task 1's nil guards + Task 2's debouncer fix should resolve.

  **Must NOT do**:
  - Do not change integration detection logic (filetype matching)
  - Do not alter the integration config structure
  - Do not change neo-tree or NvimTree specific handling beyond fixing window ordering

  **Recommended Agent Profile**:
  - **Category**: `deep`
    - Reason: Requires understanding complex state interactions across multiple modules, integration window handling, and state recovery edge cases
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 3 (with Tasks 10, 12)
  - **Blocks**: Task 13
  - **Blocked By**: Tasks 1, 6

  **References**:

  **Test References**:
  - `tests/test_buffers.lua` — 2 failing tests: "Invalid channel" on buffer close
  - `tests/test_integrations.lua` — 3 failing tests: neo-tree ordering, checkhealth nil, column count
  - `tests/test_state_edge_cases.lua` — 3 failing tests: columns mismatch, state recovery, rapid toggle

  **Pattern References**:
  - `lua/no-neck-pain/state.lua:402-418` — `set_layout_windows()`: counts columns, may over-count with integrations
  - `lua/no-neck-pain/state.lua:462-500` — `scan_layout()`: walks windows, categorizes by filetype
  - `lua/no-neck-pain/state.lua:219-221` — `get_integrations()`: no nil guard
  - `lua/no-neck-pain/main.lua:275` — unsafe split path without win validation
  - `lua/no-neck-pain/main.lua:442-523` — `disable()`: state cleanup order matters for re-enable

  **API/Type References**:
  - `lua/no-neck-pain/state.lua:170-182` — Tab state structure (as fixed by Task 1)

  **WHY Each Reference Matters**:
  - `set_layout_windows()` column counting logic is the root of "3 columns vs 1" failures
  - `scan_layout()` categorization determines if integration windows are correctly identified and excluded from column count
  - `get_integrations()` nil guard prevents crash in checkhealth path
  - `disable()` cleanup order affects whether re-enable can properly reinitialize state

  **Acceptance Criteria**:

  - [ ] `make test-buffers` passes with 0 failures (all 2 fixed)
  - [ ] `make test-integrations` passes with 0 failures (all 3 fixed)
  - [ ] `make test-state_edge_cases` passes with 0 failures (all 3 fixed)

  **QA Scenarios**:

  ```
  Scenario: All buffer tests pass
    Tool: Bash
    Preconditions: Tasks 1, 6 completed
    Steps:
      1. Run `make test-buffers`
      2. Capture full stdout
      3. Assert "FAIL" does not appear in output
      4. Assert exit code is 0
    Expected Result: All 2 previously-failing buffer tests pass
    Failure Indicators: Any "FAIL" in output
    Evidence: .sisyphus/evidence/task-11-buffers.txt

  Scenario: All integration tests pass
    Tool: Bash
    Preconditions: Tasks 1, 6 completed, column counting fixed
    Steps:
      1. Run `make test-integrations`
      2. Capture full stdout
      3. Assert "FAIL" does not appear in output
      4. Assert exit code is 0
    Expected Result: All 3 previously-failing integration tests pass
    Failure Indicators: Any "FAIL" in output
    Evidence: .sisyphus/evidence/task-11-integrations.txt

  Scenario: All state edge case tests pass
    Tool: Bash
    Preconditions: Tasks 1, 2, 6 completed
    Steps:
      1. Run `make test-state_edge_cases`
      2. Capture full stdout
      3. Assert "FAIL" does not appear in output
      4. Assert exit code is 0
    Expected Result: All 3 previously-failing state edge case tests pass
    Failure Indicators: Any "FAIL" in output
    Evidence: .sisyphus/evidence/task-11-state-edge-cases.txt
  ```

  **Commit**: YES (groups with Task 10)
  - Message: `fix(tests): fix buffer, integration, and state edge case test failures`
  - Files: `tests/test_buffers.lua`, `tests/test_integrations.lua`, `tests/test_state_edge_cases.lua`, optionally `lua/no-neck-pain/state.lua`
  - Pre-commit: `make test-buffers && make test-integrations && make test-state_edge_cases`

- [ ] 12. Fix test_width_calculations.lua (1 failure)

  **What to do**:
  - After Tasks 1 and 3 (threshold fix) are complete, run `make test-width_calculations` to verify the fix.
  - **Root cause**: The `minSideBufferWidth` threshold comparison uses `<` (strict less-than) in one place and `<=` (less-than-or-equal) in another. Task 3 normalizes these to use consistent operators. The test asserts that when side buffer width equals exactly `minSideBufferWidth`, the side buffers ARE created (boundary value is valid).
  - If the test still fails after Task 3:
    1. Check `ui.lua:139` — creation threshold should use `>=` to include the boundary value
    2. Check `ui.lua:260` — return-zero threshold should use `<` to not zero out at the boundary
    3. Verify the test asserts the correct behavior per README: "Represents the lowest width value a side buffer should be" — meaning the value itself is the minimum acceptable, not one-below-minimum.
  - Fix any remaining assertion mismatches.

  **Must NOT do**:
  - Do not change `minSideBufferWidth` config default value
  - Do not alter width calculation algorithm beyond threshold operator fix

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Single test file, single root cause (threshold operator), likely already fixed by Task 3
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 3 (with Tasks 10, 11)
  - **Blocks**: Task 13
  - **Blocked By**: Tasks 1, 3

  **References**:

  **Test References**:
  - `tests/test_width_calculations.lua` — 1 failing test: boundary value for `minSideBufferWidth`

  **Pattern References**:
  - `lua/no-neck-pain/ui.lua:139` — Creation threshold (as fixed by Task 3, `>` → `>=`)
  - `lua/no-neck-pain/ui.lua:180` — Closure threshold (`<`, correct)
  - `lua/no-neck-pain/ui.lua:260` — Return-zero threshold (as fixed by Task 3, `<=` → `<`)

  **WHY Each Reference Matters**:
  - All three threshold lines in ui.lua determine side buffer creation/destruction at boundary values
  - The test specifically targets the exact boundary value — must be consistent across all three checks

  **Acceptance Criteria**:

  - [ ] `make test-width_calculations` passes with 0 failures (1 fixed)

  **QA Scenarios**:

  ```
  Scenario: Width calculation boundary test passes
    Tool: Bash
    Preconditions: Tasks 1, 3 completed (threshold operators normalized)
    Steps:
      1. Run `make test-width_calculations`
      2. Capture full stdout
      3. Assert "FAIL" does not appear in output
      4. Assert exit code is 0
    Expected Result: The boundary value test for minSideBufferWidth passes
    Failure Indicators: Any "FAIL" in output
    Evidence: .sisyphus/evidence/task-12-width.txt
  ```

  **Commit**: YES (groups with Task 3 if source-only, or with Task 10-11 if test-only)
  - Message: `fix(tests): verify width threshold boundary test passes`
  - Files: `tests/test_width_calculations.lua` (if assertion fix needed)
  - Pre-commit: `make test-width_calculations`

- [ ] 13. Full verification — run complete test suite and documentation

  **What to do**:
  - This is the final verification task after ALL implementation and test fix tasks (1-12) are complete.
  - Run the following commands in sequence and verify all pass:
    1. `stylua --check . -g '*.lua' -g '!deps/' -g '!nightly/'` — Lint check
    2. `make test` — Full test suite (all 373 cases across all test files)
    3. `make documentation` — Documentation generation
  - If ANY failures occur:
    1. Identify which specific test(s) fail
    2. Trace back to the responsible task (1-12)
    3. Document the failure in evidence file
    4. Fix the issue (minimal change only)
    5. Re-run the full suite to confirm no regressions
  - Run `make test` a second time after any fixes to confirm stability (no flaky tests).

  **Must NOT do**:
  - Do not skip any of the three verification commands
  - Do not mark as complete if ANY command fails
  - Do not add new features or refactoring during verification

  **Recommended Agent Profile**:
  - **Category**: `deep`
    - Reason: Must run full test suite, analyze any failures, trace root causes, and fix with minimal changes
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Wave 4 (sequential, alone)
  - **Blocks**: Final Verification Wave (F1-F4)
  - **Blocked By**: Tasks 1-12 (ALL must be complete)

  **References**:

  **Pattern References**:
  - `Makefile:1-57` — All test targets, lint, documentation commands
  - All `tests/test_*.lua` files — Full test inventory
  - All `lua/no-neck-pain/*.lua` files — All source files that may have been modified in Tasks 1-6

  **WHY Each Reference Matters**:
  - Makefile defines exact commands — must use these, not custom invocations
  - Test files are the comprehensive verification — all 373 cases must pass
  - Source files must be checked for unintended changes from earlier tasks

  **Acceptance Criteria**:

  - [ ] `stylua --check . -g '*.lua' -g '!deps/' -g '!nightly/'` exits 0
  - [ ] `make test` exits 0 with 0 failures across all 373 test cases
  - [ ] `make documentation` exits 0 with no errors
  - [ ] Second `make test` run also exits 0 (confirms no flaky tests)

  **QA Scenarios**:

  ```
  Scenario: Full lint check passes
    Tool: Bash
    Preconditions: All tasks 1-12 completed
    Steps:
      1. Run `stylua --check . -g '*.lua' -g '!deps/' -g '!nightly/'`
      2. Assert exit code is 0
    Expected Result: All Lua files pass style check
    Failure Indicators: Non-zero exit code, style diff output
    Evidence: .sisyphus/evidence/task-13-lint.txt

  Scenario: Full test suite passes
    Tool: Bash
    Preconditions: Lint passes
    Steps:
      1. Run `make test`
      2. Capture full stdout
      3. Assert "FAIL" does not appear in output
      4. Assert exit code is 0
      5. Count total tests — should be 373 or more
    Expected Result: 373/373 tests pass, 0 failures
    Failure Indicators: Any "FAIL" in output, non-zero exit code, fewer than 373 tests
    Evidence: .sisyphus/evidence/task-13-test-suite.txt

  Scenario: Documentation generation succeeds
    Tool: Bash
    Preconditions: Tests pass
    Steps:
      1. Run `make documentation`
      2. Assert exit code is 0
    Expected Result: Documentation generated without errors
    Failure Indicators: Non-zero exit code, error output
    Evidence: .sisyphus/evidence/task-13-documentation.txt

  Scenario: Test suite stability (second run)
    Tool: Bash
    Preconditions: First test run passed
    Steps:
      1. Run `make test` again
      2. Assert "FAIL" does not appear in output
      3. Assert exit code is 0
    Expected Result: 373/373 tests pass on second run (no flaky tests)
    Failure Indicators: Any test that passed first time but fails second time
    Evidence: .sisyphus/evidence/task-13-stability.txt
  ```

  **Commit**: YES
  - Message: `chore: verify all tests, lint, and documentation pass`
  - Files: (any remaining fixes from verification)
  - Pre-commit: `make test && make documentation`

---

## Final Verification Wave

> 4 review agents run in PARALLEL. ALL must APPROVE. Rejection → fix → re-run.

- [ ] F1. **Plan Compliance Audit** — `oracle`
  Read the plan end-to-end. For each "Must Have": verify implementation exists (read file, run command). For each "Must NOT Have": search codebase for forbidden patterns — reject with file:line if found. Check evidence files exist in `.sisyphus/evidence/`. Compare deliverables against plan.
  Output: `Must Have [N/N] | Must NOT Have [N/N] | Tasks [N/N] | VERDICT: APPROVE/REJECT`

- [ ] F2. **Code Quality Review** — `unspecified-high`
  Run `make test` + `stylua --check . -g '*.lua' -g '!deps/' -g '!nightly/'`. Review all changed files for: `as any`/`@ts-ignore` equivalents, empty catches, debug prints in prod, commented-out code, unused requires. Check AI slop: excessive comments, over-abstraction, generic names.
  Output: `Test [PASS/FAIL] | Lint [PASS/FAIL] | Files [N clean/N issues] | VERDICT`

- [ ] F3. **Real Manual QA — full make test-race** — `unspecified-high`
  Run `make test-race` (10 iterations of full test suite). Capture output for each iteration. If any iteration fails, report which test and which iteration.
  Output: `Iterations [N/10 pass] | Flaky tests [list] | VERDICT`

- [ ] F4. **Scope Fidelity Check** — `deep`
  For each task: read "What to do", read actual diff (`git diff`). Verify 1:1 — everything in spec was built (no missing), nothing beyond spec was built (no creep). Check "Must NOT do" compliance. Flag unaccounted changes.
  Output: `Tasks [N/N compliant] | Unaccounted [CLEAN/N files] | VERDICT`

---

## Commit Strategy

| Commit | Scope | Message | Files | Pre-commit |
|--------|-------|---------|-------|------------|
| 1 | Wave 1 | `fix(state): add nil safety guards and initialize redraw field` | state.lua | `make test-state_edge_cases` |
| 2 | Wave 1 | `fix(api): resolve debouncer race condition with timer cleanup` | api.lua | `make test-autocmds` |
| 3 | Wave 1 | `fix(ui): use consistent threshold operator for minSideBufferWidth` | ui.lua | `make test-width_calculations` |
| 4 | Wave 1 | `fix(ui): handle empty scratchpad pathToFile gracefully` | ui.lua | `make test-scratchpad` |
| 5 | Wave 2 | `fix(main): add window validity checks and fix state cleanup order` | main.lua | `make test-tabs` |
| 6 | Wave 2-3 | `fix(tests): update assertions to match corrected behavior` | tests/*.lua | `make test` |
| 7 | Wave 4 | `chore: verify all tests pass` | — | `make test && make documentation` |

---

## Success Criteria

### Verification Commands
```bash
make test           # Expected: 373/373 tests pass, 0 failures
make documentation  # Expected: exit 0, no errors
stylua --check . -g '*.lua' -g '!deps/' -g '!nightly/'  # Expected: exit 0
```

### Final Checklist
- [ ] All 39 previously-failing tests now pass
- [ ] All 334 previously-passing tests still pass (no regressions)
- [ ] `make test` exits with 0 failures
- [ ] `make documentation` succeeds
- [ ] `stylua` formatting check passes
- [ ] No new global mutable state introduced
- [ ] Public API unchanged (all commands work identically)
- [ ] All changes are minimal and scoped to identified bugs
