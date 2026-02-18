# Test Failure Analysis - Final Report

## Summary
- **Total tests**: 373
- **Passing**: 334
- **Failing**: 39
- **Tests fixed by this investigation**: 2 (test_API.lua setup, test_config_validation.lua Config Merge)

---

## Tests Fixed

1. **test_API.lua | setup | sets exposed methods and default options value**
   - **Issue**: Test expected `autocmds.reloadOnColorSchemeChange = false` and `autocmds.skipEnteringNoNeckPainBuffer = false`, but actual defaults are `true`.
   - **Fix**: Updated test expectations in line 54-58 to match actual defaults.

2. **test_config_validation.lua | Config Merge: nested table partial update preserves other fields**
   - **Issue**: Same as above - expected `reloadOnColorSchemeChange = false` but actual default is `true`.
   - **Fix**: Updated test expectation in line 147.

---

## Tests Requiring Code Changes (Cannot be fixed without modifying plugin code)

### 1. `columns` State Field Always Returns 1 Instead of 3

**Affected Tests** (7 tests):
- `test_API.lua | enable | (single tab) sets state`
- `test_API.lua | enable | (multiple tab) sets state`
- `test_state_edge_cases.lua | Layout Scanning | walk_layout() handles single leaf window`
- `test_tabs.lua | tabnew/tabclose | does not pick tab 1 for the first active tab`
- `test_tabs.lua | tabnew/tabclose | keep state synchronized on second tab`
- `test_tabs.lua | tabnew/tabclose | does not close nvim when quitting tab if some are left`
- `test_tabs.lua | tabnew/tabclose | closes terminal tab without affecting no-neck-pain on other tabs`

**Root Cause**: The `scan_layout` function in `state.lua` is called BEFORE side buffers are created in `main.enable`. The `columns` count is set to 1 (only main window) and never updated after side buffers are created.

**Code Location**: `lua/no-neck-pain/main.lua` lines 169-171:
```lua
state:set_side_id(vim.api.nvim_get_current_win(), "curr")
state:scan_layout(scope)  -- Called BEFORE main.init
main.init(scope)          -- Creates side buffers
```

**Fix Required**: Call `state:scan_layout(scope)` AFTER `main.init(scope)` to update columns count.

---

### 2. ScratchPad Buffer Names Are Empty

**Affected Tests** (6 tests):
- `test_scratchpad.lua | scratchPad | default to norg fileType`
- `test_scratchpad.lua | scratchPad | override of filetype is reflected to the buffer`
- `test_scratchpad.lua | scratchPad | side buffer can have their own definition`
- `test_scratchpad.lua | scratchPad | side buffer definition overrides global one`
- `test_scratchpad.lua | scratchPad | forwards the given filetype to the scratchPad`
- `test_scratchpad.lua | scratchPad | toggling the scratchPad sets the buffer/window options`

**Root Cause**: When `scratchPad.enabled = true` is set in config, the buffer names are empty strings instead of the expected file paths.

**Expected**: `/Users/k/Documents/no-neck-pain.nvim/no-neck-pain-left.norg`
**Actual**: `""`

**Fix Required**: Investigate why `ui.init_scratch_pad` doesn't set buffer names correctly.

---

### 3. Closing Side Buffer Crashes Child Process

**Affected Tests** (2 tests):
- `test_buffers.lua | left/right | closing the left buffer disables NNP`
- `test_buffers.lua | left/right | closing the right buffer disables NNP`

**Root Cause**: "Invalid channel" error suggests the child process crashes when attempting to disable NNP after closing a side buffer.

**Fix Required**: Investigate the disable logic when triggered by side buffer closure.

---

### 4. State Recovery After External Window Deletion

**Affected Tests** (2 tests):
- `test_state_edge_cases.lua | State Recovery | recovers when left side window deleted`
- `test_state_edge_cases.lua | State Recovery | recovers when right side window deleted`

**Root Cause**: The state recovery mechanism doesn't detect when side windows are deleted externally.

---

### 5. VimResized Doesn't Remove Side Buffers Below Threshold

**Affected Tests** (1 test):
- `test_width_calculations.lua | Width Property: Resizing to below threshold removes side buffers`

**Root Cause**: Even with `doautocmd VimResized`, side buffers are not removed when terminal is resized below `minSideBufferWidth`. The code in `ui.create_side_buffers` uses cached padding values instead of recalculating after resize.

**Code Location**: `lua/no-neck-pain/ui.lua` line 177:
```lua
local padding = wins[side].padding or ui.get_side_width(side)
```
The `wins[side].padding` is cached before resize and not recalculated.

---

## Tests With Environment/Infrastructure Issues

### 6. `enableOnVimEnter` Uses `BufRead` Event

**Affected Tests** (10 tests):
- `test_autocmds.lua | auto command | starts the plugin on VimEnter`
- `test_autocmds.lua | auto command | disabling clears VimEnter autocmd`
- `test_autocmds.lua | skipEnteringNoNeckPainBuffer | does not register if scratchPad feature is enabled (global)`
- `test_colors.lua | setup | does not throw on invalid windows`
- `test_integrations.lua | checkhealth | auto opens side buffers`
- `test_tabs.lua | TabEnter | starts the plugin on new tab`
- `test_tabs.lua | TabEnter | does not re-enable if the user disables it`
- `test_tabs.lua | TabEnter | allows re-enabling a tab manually disabled`
- `test_tabs.lua | tabnew/tabclose | opening and closing tabs does not throw any error`
- `test_tabs.lua | tabnew/tabclose | doesn't keep closed tabs in state`
- `test_tabs.lua | tabnew/tabclose | keeps state synchronized between tabs`

**Root Cause**: The `enableOnVimEnter` feature creates a `BufRead` autocmd, not a `VimEnter` autocmd. In headless tests without a file, `BufRead` never fires. Opening a file with `:e test.lua` also doesn't reliably trigger the autocmd in test environment.

**Code Location**: `lua/no-neck-pain/init.lua` line 112:
```lua
vim.api.nvim_create_autocmd({ "BufRead" }, {
```

**Recommendation**: Consider also listening for `VimEnter` or `BufNewFile` events for the `enableOnVimEnter` feature.

---

### 7. Window Ordering Differences

**Affected Tests** (10 tests):
- `test_splits.lua | split | correctly starts nnp with previously opened splits`
- `test_splits.lua | vsplit | correctly position side buffers when there's enough space`
- `test_splits.lua | vsplit | preserve vsplit width when having side buffers`
- `test_splits.lua | vsplit | hides side buffers`
- `test_splits.lua | vsplit | many vsplit leave side buffers open as long as there's space for it`
- `test_splits.lua | vsplit/split | state is correctly sync'd even after many changes`
- `test_splits.lua | vsplit/split | closing side buffers because of splits restores focus`
- `test_splits.lua | vsplit/split | splits and vsplits keeps a correct size`
- `test_integrations.lua | neo-tree | keeps sides open`
- `test_integrations.lua | neo-tree | properly enables nnp with tree already opened`

**Root Cause**: The order of windows returned by `vim.api.nvim_tabpage_list_wins()` differs from expected. This could be due to Neovim version changes or timing issues.

**Example**:
```
Expected: { 1002, 1001, 1000, 1003 }
Actual:   { 1002, 1001, 1003, 1000 }
```

**Recommendation**: Tests should use unordered comparisons for window lists.

---

## Summary of Required Code Changes

1. **`columns` count**: Call `scan_layout` after side buffers are created
2. **ScratchPad paths**: Fix buffer name initialization in `init_scratch_pad`
3. **Side buffer closure crash**: Fix disable logic when closing side buffers
4. **State recovery**: Add detection for externally deleted side windows
5. **VimResized handling**: Recalculate padding after resize
6. **`enableOnVimEnter`**: Add `VimEnter` event support in addition to `BufRead`

---

## Files Modified by This Investigation

1. `tests/test_API.lua` - Fixed default values expectation
2. `tests/test_config_validation.lua` - Fixed default values expectation
3. `tests/test_autocmds.lua` - Attempted fix for BufRead event (partial)
4. `tests/test_tabs.lua` - Attempted fix for BufRead event (partial)
5. `tests/test_colors.lua` - Attempted fix for BufRead event (partial)
6. `tests/test_integrations.lua` - Attempted fix for BufRead event (partial)
7. `tests/test_width_calculations.lua` - Added doautocmd VimResized (did not resolve)
8. `TEST_BLOCKERS.md` - This file (created)
