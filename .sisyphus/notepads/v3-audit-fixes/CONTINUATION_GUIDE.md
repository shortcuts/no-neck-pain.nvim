# Session 2 Continuation Guide - no-neck-pain.nvim v3 Audit

**Last Updated**: 2026-03-13 (Session 2)
**Status**: 27 test failures remaining (down from 39)
**Tokens Used**: ~97k / 200k

---

## What We Accomplished This Session

### Task 9: Window Ordering Investigation (ATTEMPTED - BLOCKED)
- **Issue**: test_splits.lua expects exact window ID order, but gets different order
- **Root Cause**: When splits exist before NNP enables, `nvim_open_win()` with `split="left"|"right"` places windows relative to CURRENT window, not at extremes
- **Attempted Fix**: Adding `ui.move_sides()` call after `create_side_buffers()` in main.lua
- **Result**: Fix worked for window ordering but BROKE 12 other tests (27→38 failures)
- **Conclusion**: `move_sides()` approach causes unintended side effects - needs different solution
- **Alternative Approaches Not Yet Tried**:
  1. Change window creation method (use different API flags)
  2. Only call `move_sides()` conditionally (check window order first)
  3. Update test assertions to accept any window order (risky - might hide bugs)

### What Worked (Tasks 1-8)
1. ✅ State nil safety + redraw field initialization
2. ✅ Debouncer race condition fix
3. ✅ UI threshold operator consistency (line 139, 260)
4. ✅ Scratchpad pathToFile resolution + window switching
5. ✅ Lint compliance (stylua)
6. ✅ Main.lua window validity checks (before set_current_win)
7. ✅ Walk_layout fix (preserve leaf items in column count)
8. ✅ Scratchpad test fixes

---

## Current Test Failure Breakdown

### Category 1: Window Ordering (8 failures in test_splits.lua)
Tests expect: `{ 1002, 1001, 1000, 1003 }` (left, split, main, right)
Tests get: `{ 1002, 1001, 1003, 1000 }` (left, split, right, main)

**Root Cause**: Window list ordering from `nvim_tabpage_list_wins()` - right side buffer appears in wrong position
**Status**: NEEDS FIX - move_sides() approach doesn't work

```lua
-- Examples of failing tests:
- test_splits.lua:113  - correctly starts nnp with previously opened splits
- test_splits.lua:177  - correctly position side buffers when there's enough space
- test_splits.lua:265  - hides side buffers
- test_splits.lua:290  - many vsplit leave side buffers open
- test_splits.lua:339  - state is correctly sync'd even after many changes
- test_splits.lua:370  - closing side buffers because of splits restores focus
```

### Category 2: Width Calculations (3 failures in test_splits.lua)
**Issue**: Buffer width calculations don't match expected ranges

```lua
- test_splits.lua:190  - preserve vsplit width: got 36, expected 26
- test_splits.lua:419  - splits and vsplits keeps a correct size: got 18, expected 19
```

**Root Cause**: Likely related to how side buffer widths are calculated when splits exist. Might be fixed by resolving window ordering first.

### Category 3: Nil State Access (5+ failures in test_tabs.lua)
**Error**: `attempt to index field 'state' (a nil value)`
**Location**: helpers.lua line 65 (state access in test setup)

```lua
- test_tabs.lua:173  - TabEnter: starts the plugin on new tab
- test_tabs.lua:195  - TabEnter: does not re-enable if the user disables it
- test_tabs.lua:233  - TabEnter: allows re-enabling a tab manually disabled
- test_tabs.lua:280  - tabnew/tabclose: opening and closing tabs
- test_tabs.lua:314  - tabnew/tabclose: doesn't keep closed tabs in state
- test_tabs.lua:393  - tabnew/tabclose: keeps state synchronized between tabs
```

**Likely Cause**: Test setup issue or state not being initialized properly in multi-tab scenarios

### Category 4: State Recovery (2 failures in test_state_edge_cases.lua)
**Error**: Expected true, got false - state recovery failed

```lua
- test_state_edge_cases.lua:455  - recovers when left side window deleted
- test_state_edge_cases.lua:478  - recovers when right side window deleted
```

**Issue**: Plugin doesn't properly recover when side windows are deleted externally

### Category 5: Width Boundary Tests (3 failures in test_width_calculations.lua)
**Error**: Width values outside expected ranges

```lua
- test_width_calculations.lua:76   - At minSideBufferWidth threshold: got 11, expected 40
- test_width_calculations.lua:116  - Above minSideBufferWidth threshold: got 16, expected 43
- test_width_calculations.lua:138  - Very wide terminal: got 202, expected 166
```

**Issue**: Side buffer width calculation formula seems wrong

---

## Recommended Next Steps (Priority Order)

### HIGHEST PRIORITY: Fix Window Ordering (Task 9)
The window ordering issue is blocking other progress. Choose ONE approach:

**Approach A: Direct Fix (Recommended)**
- Don't use `move_sides()` after `create_side_buffers()`
- Instead, modify how `create_side_buffers()` creates windows
- Check if using different `nvim_open_win()` parameters can position windows correctly from the start
- Reference: `ui.lua` lines 168-176 (window creation)

**Approach B: Conditional Move**
- Only call `move_sides()` if windows are detected in wrong positions
- Add helper to check current window order: is left at `wins[1]`? is right at `wins[#wins]`?
- Only move if needed - less intrusive than unconditional move

**Approach C: Test-Only Fix (Last Resort)**
- Accept that window order is non-deterministic
- Update test assertions to check SET membership instead of order
- Add helper: `assert_windows_match_ids(actual_ids, expected_ids)` - unordered comparison

### SECOND PRIORITY: Nil State Access in test_tabs.lua
- These are likely test setup issues
- Check if test initialization properly creates state
- May need to add state initialization steps in test setup

### THIRD PRIORITY: State Recovery
- Implement recovery when side windows are deleted
- Add checks in `main.lua` to detect orphaned windows
- Clean up state when windows become invalid

### FOURTH PRIORITY: Width Calculations
- Investigate the width calculation formula in `ui.lua:get_side_width()`
- Likely needs adjustment to account for split windows
- These might auto-fix once window ordering is fixed

---

## Key Code Locations

### Window Creation & Movement
- `lua/no-neck-pain/ui.lua:145-214` - `create_side_buffers()` - creates left/right padding windows
- `lua/no-neck-pain/ui.lua:32-63` - `move_sides()` - moves side buffers using `<C-W>H` and `<C-W>L`
- `lua/no-neck-pain/ui.lua:225-295` - `get_side_width()` - calculates side buffer width

### State Management
- `lua/no-neck-pain/state.lua:328-338` - `get_side_id()` - retrieves side window IDs
- `lua/no-neck-pain/state.lua:416-434` - `set_layout_windows()` - records layout windows
- `lua/no-neck-pain/state.lua:446-471` - `walk_layout()` - traverses layout tree

### Main Plugin Flow
- `lua/no-neck-pain/main.lua:97-140` - `main.init()` - creates side buffers and positions them
- Line 110: `ui.move_sides()` called if consume_redraw() is true
- Line 113: `ui.create_side_buffers()` called
- **ISSUE**: No move after create for newly created buffers

### Test Utilities
- `tests/helpers.lua` - test setup and assertion helpers
- `tests/test_splits.lua` - window split/vsplit test suite

---

## Known Workarounds (if needed)

1. **If window ordering is truly non-deterministic**: Update tests to use set comparison instead of list equality
2. **If state recovery impossible**: Could disable the plugin when side windows are deleted externally
3. **If width calculation is complex**: Might need to revisit assumptions about how splits affect width

---

## Session Continuation Checklist

When continuing this work in the next session:

- [ ] Read this file first to understand context
- [ ] Check git log to see all prior commits
- [ ] Run `make test` to verify current failure count (should be 27)
- [ ] Pick ONE test failure category to fix
- [ ] Test incrementally - verify fix doesn't break other tests
- [ ] Commit atomic changes with clear messages
- [ ] Document findings in notepad for next session

---

## Token Budget Status

- **Used this session**: ~97k
- **Total available**: 200k
- **Remaining**: ~103k
- **Recommendation**: Next session can delegate 2-3 substantial tasks
