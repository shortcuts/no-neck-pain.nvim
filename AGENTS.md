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


<!-- code-review-graph MCP tools -->
## MCP Tools: code-review-graph

**IMPORTANT: This project has a knowledge graph. ALWAYS use the
code-review-graph MCP tools BEFORE using Grep/Glob/Read to explore
the codebase.** The graph is faster, cheaper (fewer tokens), and gives
you structural context (callers, dependents, test coverage) that file
scanning cannot.

### When to use graph tools FIRST

- **Exploring code**: `semantic_search_nodes` or `query_graph` instead of Grep
- **Understanding impact**: `get_impact_radius` instead of manually tracing imports
- **Code review**: `detect_changes` + `get_review_context` instead of reading entire files
- **Finding relationships**: `query_graph` with callers_of/callees_of/imports_of/tests_for
- **Architecture questions**: `get_architecture_overview` + `list_communities`

Fall back to Grep/Glob/Read **only** when the graph doesn't cover what you need.

### Key Tools

| Tool | Use when |
|------|----------|
| `detect_changes` | Reviewing code changes — gives risk-scored analysis |
| `get_review_context` | Need source snippets for review — token-efficient |
| `get_impact_radius` | Understanding blast radius of a change |
| `get_affected_flows` | Finding which execution paths are impacted |
| `query_graph` | Tracing callers, callees, imports, tests, dependencies |
| `semantic_search_nodes` | Finding functions/classes by name or keyword |
| `get_architecture_overview` | Understanding high-level codebase structure |
| `refactor_tool` | Planning renames, finding dead code |

### Workflow

1. The graph auto-updates on file changes (via hooks).
2. Use `detect_changes` for code review.
3. Use `get_affected_flows` to understand impact.
4. Use `query_graph` pattern="tests_for" to check coverage.
