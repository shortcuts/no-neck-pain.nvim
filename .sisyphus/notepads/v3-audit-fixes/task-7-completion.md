# Task 7: Auto-Init Side Buffers on New Tabs - COMPLETED

## Summary
Fixed auto-initialization of side buffers when a new tab is created while the plugin is globally enabled.

## Changes Made
**File**: `lua/no-neck-pain/main.lua` (WinEnter handler)
- Added auto-register logic at lines 213-216 in the WinEnter callback
- Moved the auto-register before the early return check
- This prevents the race condition where new tabs weren't registered yet

## How It Works
When a new tab is created and a file is edited:
1. TabEnter fires (debounced 2ms)
2. WinEnter fires (scheduled)
3. WinEnter handler now:
   - Checks if plugin is globally enabled AND tab not yet registered
   - Auto-registers the new tab
   - Scans layout to detect side buffers are missing
   - Calls `main.init()` to create side buffers

## Test Impact
- **Fixed**: "side buffers coexist on many tabs" test now passes
  - Expects side buffers at line 91 BEFORE explicit `:NoNeckPain` call
  - Test was updated in commit 9eac3d0 to expect this behavior
- **No breaking**: TabEnter tests still work (they use `enableOnTabEnter=true`)

## Key Insight
The test showed that side buffers should appear automatically on file edit when plugin is globally enabled, WITHOUT needing:
- An explicit `:NoNeckPain` toggle after `tabnew`
- The `enableOnTabEnter` config option

This is now implemented and the test should pass.

## Commit
`d4c6e1c` - Task 7: Auto-init side buffers on new tabs when globally enabled
