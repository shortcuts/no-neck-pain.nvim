# Task 2: Debouncer Race Condition Fix - Completion Summary

## Problem
The recursive `api.debounce()` call on line 115 caused a race condition:
- Recursive call created a fresh debouncer entry at lines 95-96
- This lost the `executing` state on the original debouncer object
- New timer could be created while old `executing` flag was still true
- Result: timers could leak and state could get corrupted

## Solution Implemented
Replaced recursion with a `debouncer.reschedule` flag-based approach:

1. **Line 105-106**: Added `debouncer.reschedule = false` to initialize the flag
2. **Line 116-120**: When callback is executing and new trigger arrives, set `debouncer.reschedule = true` instead of recursing
3. **Line 128-131**: After callback completes, check reschedule flag:
   - If true: call `api.debounce()` to create new timer (proper reschedule)
   - If false: cleanup debouncer if no new timer waiting

## Key Properties Preserved
- ✅ Timer cleanup: Uses existing `timer_stop_close()` pattern (lines 73-80)
- ✅ Closure semantics: Still properly captures `debouncer` and `timer` variables
- ✅ State isolation: `debouncer.executing` and `debouncer.reschedule` stay on same object
- ✅ No timer leaks: Old timer properly stopped before new one created
- ✅ API unchanged: `api.debounce(context, callback, timeout)` signature unchanged

## Verification
- RaceConditions test group: **16/16 PASS** (all green 'o's)
- Pre-existing failures in other test groups (not related to this fix)
- No remaining recursive calls in debounce function
- Reschedule call on line 131 is now properly placed AFTER callback execution

## Changes Made
File: `lua/no-neck-pain/util/api.lua` (lines 91-138)
- Replaced recursive call with flag-based reschedule logic
- Moved rescheduling logic to within vim.schedule block
- Ensures state transitions happen safely on same debouncer object
