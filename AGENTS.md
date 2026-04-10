# AGENTS.md

Repository: https://github.com/shortcuts/no-neck-pain.nvim
Language: Lua
Target runtime: Neovim ≥ 0.10

`no-neck-pain.nvim` centers the active buffer by creating left and right padding windows.
These side windows maintain a consistent reading width without modifying the main editing workflow.

## Source of Truth

Use `@README.md` as the authoritative reference for:

* plugin behavior
* commands
* configuration
* integrations
* expected UX

Do not implement behavior that contradicts the README.

## Required Validation

Before assuming any change is valid, always run:

```
make lint
make test
make documentation
```

All three must pass.

## Core Responsibilities

The plugin must:

* Toggle a centered editing layout
* Create and manage left/right padding windows
* Maintain correct centered width
* React to window and editor resize events
* Work across tabs and window splits
* Preserve layout stability during buffer switches
* Support optional scratchpad buffers

## Architectural Principles

### Non-intrusive

The plugin must never alter unrelated windows or workflows.

### Layout determinism

The centered buffer must always remain the active editing window.

Side windows exist strictly for padding or scratchpads.

### Window isolation

Side buffers must not interfere with:

* buffer navigation
* split logic
* tab behavior
* external UI plugins

### Minimal state

Avoid global mutable state unless necessary for layout tracking.

## Window Model

Typical layout:

```
[left padding] [main buffer] [right padding]
```

## Commands

The following commands must remain stable:

* `:NoNeckPain` — toggle centered layout
* `:NoNeckPainResize <width>` — set main width
* `:NoNeckPainWidthUp`
* `:NoNeckPainWidthDown`
* `:NoNeckPainToggleLeftSide`
* `:NoNeckPainToggleRightSide`
* `:NoNeckPainScratchPad`

Changes affecting layout must preserve command semantics.

## Compatibility

The plugin must remain compatible with common UI plugins, including:

* file tree plugins
* dashboard plugins
* outline / symbol panels
* sidebars created by other plugins

Side windows must not conflict with these layouts. See @tests/test_integrations.lua

## Testing Expectations

Tests must cover logic related to:

* layout creation
* layout destruction
* resizing
* split handling
* tab handling
* toggle idempotency

Prefer deterministic scenarios simulating:

* window resize
* new splits
* buffer switches
* repeated toggling

If modifying layout logic, update or add tests.

## Documentation

Any behavioral change requires updating:

* `README.md`
* generated documentation (`make documentation`)

Documentation must reflect actual runtime behavior.

## Change Policy

Agents must:

* keep changes minimal and scoped
* avoid unnecessary refactors
* preserve public API stability
* maintain layout determinism
* update tests when behavior changes
* update documentation when behavior changes

