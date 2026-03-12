# Task 1: State Nil Safety + Redraw Field Initialization

## Changes Made

### 1. Added `redraw = false` to `set_tab()` initialization (line 173)
- This field is required for `consume_redraw()` to function properly
- It tracks whether layout redrawing is needed when integrations change
- Initialized as `false` to prevent spurious redraws on tab registration

### 2. Added nil guards to 7 state accessor methods:
All follow the same pattern: `if not (self:has_tabs() and self.tabs[self.active_tab] ~= nil) then return <safe_default> end`

#### Getters with safe defaults:
- `get_integrations()` → returns `{}` (empty table)
- `get_side_id(side)` → returns `nil` 
- `get_columns()` → returns `0` (numeric default)
- `consume_redraw()` → returns `false` (boolean default)
- `get_scratch_pad()` → returns `false` (boolean default)

#### Setters become no-ops:
- `set_side_id(id, side)` → early return if tab not registered
- `set_scratch_pad(bool)` → early return if tab not registered

## Root Cause Understanding

The state module accesses `self.tabs[self.active_tab]` without validation in multiple places. This is unsafe because:
- `self.active_tab` can be stale (pointing to a closed tab)
- `self.tabs` can be empty during initialization or after cleanup
- The exact pattern to check: `self:has_tabs() and self.tabs[self.active_tab] ~= nil`

## Pattern Replicated From

Used the nil-check pattern from `is_active_tab_registered()` (lines 101-105):
```lua
function state:is_active_tab_registered()
    return self:has_tabs()
        and self.tabs[self.active_tab] ~= nil
        and vim.api.nvim_tabpage_is_valid(self.active_tab)
end
```

## Test Results

- **Before changes**: 28 pass, 3 failures (Layout Scanning, State Recovery x2)
- **After changes**: 28 pass, 3 failures (identical pre-existing failures)
- **Conclusion**: Changes did NOT introduce new failures, only added safety

## Style Compliance

- Stylua linter: PASSED
- Code follows existing patterns in the codebase
- All 8 edits maintain consistency with nil-guard pattern

## Impact

This task blocks 6 subsequent tasks (Tasks 6-12) that depend on safe state access.
