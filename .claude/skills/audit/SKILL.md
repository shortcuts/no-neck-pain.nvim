---
name: audit
description: Audit current branch changes against main. Checks for regressions, lint compliance, unit tests, CI status, and reviews code for bugs and improvements.
disable-model-invocation: false
allowed-tools: Bash(git *), Bash(make lint), Bash(make test), Bash(gh pr checks *), Bash(gh pr view *), Bash(gh run view *), Bash(gh pr comment *), Bash(gh api *), Grep, Read, Glob, Write
---

You are auditing the current branch to verify code quality before review. Report only concrete, evidence-backed findings.

## 1. Identify changed files

Run `git fetch origin` to ensure we have the latest main branch.

Run `git diff --name-only origin/main...HEAD` to list all changed files.

Categorize into: source code, tests, other.

If no changes, stop and report "No changes to audit."

Note which packages are affected.

## 2. Analyze the diff

Run `git diff origin/main...HEAD --stat` for an overview.

Run `git diff origin/main...HEAD` for the full diff.

For each changed source file, note:
- New exported functions/methods
- Changed signatures
- Deleted functions
- New imports

Keep analysis factual — list what changed, not what should change.

## 3. Check CI status

Check if the branch has a PR with CI checks.

Run `gh pr view --json number,url 2>/dev/null`.

If no PR exists (command fails): record CI Status as SKIPPED (no PR found). Skip to step 8.

If a PR exists:
    - run `gh pr checks`.

Classify each check:
- **pass**: check succeeded
- **fail**: check failed
- **pending/in_progress**: check still running

If ALL checks passed: record PASS.

If any checks are still running: record IN PROGRESS. List which checks are pending and which have completed. Do NOT wait or poll — report current state and move on.

If any checks failed:
1. Record FAIL with the list of failed check names.
2. For each failed check, attempt to get failure details:
   Run `gh run view <run-id> --log-failed 2>/dev/null` (extract run ID from the check URL).
   If log output exceeds 100 lines, summarize the key failure messages per job.
3. Record a brief failure summary for each failed check (1-3 lines each).

If `gh` commands fail due to authentication: record SKIPPED (gh auth unavailable).

## 4. Run lint with auto-fix

Skip this step unless:
- there are local changes
- the local branch differs from the remote branch
- the PR checks have failed

Run `make lint`.

Check `git diff --name-only` for changes produced by lint.

If lint modified files: create a commit for it `git add && git commit -m "chore: commit lint fix"`

If no changes: record PASS.

If terraform-related lint fails due to missing init, note as SKIPPED not FAIL.

## 5. Run unit tests

Skip this step unless:
- there are local changes
- the local branch differs from the remote branch
- the PR checks have failed

Run `make test`.

If tests pass: record PASS.

If tests fail: record each failing test with package path and failure message.

## 7. Check test coverage of changed code

For each new/modified source file (skip test files, mocks, generated code):

1. Check if a corresponding test exists.
2. Check if test file was also modified/created in this branch.
3. For new exported functions, check if any test references them.

Classify:
- **Covered**: test exists AND updated.
- **Partially covered**: test exists, NOT updated.
- **Not covered**: no test file.

## 8. Review changes for bugs and improvements

Review the diff obtained in step 2 for issues. This is a deep analytical review — use reasoning, but ground every finding in specific code from the diff.

**Scope**: Only review files changed in this branch. Skip:
- `mocks/`, `*_mock.go`, `*_generated.go` (generated code)
- `go.sum`, `go.mod` (dependency management)
- Files that were only deleted

**What to look for**:
- 🔴 **Bug**: Logic errors, nil pointer risks, race conditions, incorrect error handling, security issues
- 🟡 **Warning**: Missing error handling, missing tests for new exported functions/methods, unvalidated inputs, potential panics
- 🟢 **Suggestion**: Meaningful improvements to correctness or robustness (NOT style, NOT refactoring, NOT architecture)

**Constraints**:
- Each finding MUST reference a specific file and line range from the diff
- Do NOT flag issues in unchanged code (code that was not part of this branch's diff)
- Do NOT suggest style changes, variable renaming, or code reorganization
- Do NOT suggest refactoring or architectural improvements
- Focus on: "Would this code work correctly in production?"

If no issues found: record PASS with "No issues found."

## 9. Produce the audit report

**Conciseness rule**: Only include sections that have actionable results. Omit any section whose status is PASS, SKIPPED, or IN PROGRESS — unless it failed or has findings worth reporting. The goal is a scannable report: the reader should see only what needs attention and a quick confirmation of what passed.

Use this format, **including only the sections that apply**:

```
## Branch Audit Report

**Branch**: <branch name> | **Commits**: <count> ahead of origin/main | **Files changed**: <count>

### Changes
<concise bullet points describing the changes>

### Checks

<for everything in the "Details" column: only list up to 5 entries. If there's more than 5, also add a mention of the total number of entries.>
| Check | Status | Details |
|-------|--------|---------|
| Lint | ✅ PASS / ❌ FAIL | <if FAIL: list files> |
| Unit Tests | ✅ PASS / ❌ FAIL | <if FAIL: list failing tests> |
| Mocks | ✅ PASS / ❌ FAIL | <if FAIL: list stale mocks> |
| CI | ✅ PASS / ❌ FAIL | <if FAIL: list failed checks> |

Omit rows where the status is SKIPPED or IN PROGRESS. If ALL checks passed, collapse to a single line: `All checks passed ✅`

### Test Coverage (only if gaps exist)
| File | Status | Notes |
|------|--------|-------|
| path/to/file.go | Partially covered / Not covered | <details> |

Only list files that are **partially covered** or **not covered**. If all changed files have full coverage, omit this section entirely.

### CI Failures (only if CI failed)
For each failed check, include a 1-3 line failure summary.

### Code Review
| # | Severity | File | Line(s) | Finding |
|---|----------|------|---------|---------|
| 1 | 🔴 Bug / 🟡 Warning / 🟢 Suggestion | path/to/file.go | 42-45 | Description |

If no issues found, replace the table with: `No issues found ✅`
```

### Save the report to file

After producing the report above, also save it to a file:

1. Get the branch name: `git branch --show-current`
2. Sanitize it for use as a filename: replace any character that is not a letter, digit, or hyphen with `-`, then collapse consecutive hyphens into one.
3. Get today's date in `YYYY-MM-DD` format.
4. Save the full report (the markdown block above) to `/tmp/audit-report-{sanitized-branch}-{commit-sha}.md` using the Write tool.
5. Print: `📄 Report saved to /tmp/audit-report-{sanitized-branch}-{commit-sha}.md`

### Publish the report as a PR comment

If a pull request exists for this branch (determined in step 7) and the CI checks are succesful:

1. Ask the user: "A pull request is open for this branch. Would you like me to publish the audit report as a comment on the PR?"
2. If the user agrees:
   a. Check if a previous audit report comment already exists on the PR:
      - Run `gh api repos/{owner}/{repo}/issues/{pr-number}/comments --jq '.[] | select(.body | startswith("## Branch Audit Report")) | .id'`
   b. If an existing comment is found (non-empty output):
      - Update the existing comment: `gh api repos/{owner}/{repo}/issues/comments/{comment-id} -X PATCH -F body=@/tmp/audit-report-{sanitized-branch}-{commit-sha}.md`
      - Print: `📝 Updated existing audit report comment on PR #{pr-number}`
   c. If no existing comment is found:
      - Create a new comment: `gh pr comment {pr-number} --body-file /tmp/audit-report-{sanitized-branch}-{commit-sha}.md`
      - Print: `💬 Published audit report as a comment on PR #{pr-number}`

## 10. Offer next steps

If ALL checks passed with full coverage and no findings: "All checks passed. Branch is ready for review. ✅"

If ANY findings exist, list only the items that need attention (skip anything that passed):

Ask: "Would you like me to create a plan to address the findings? The plan will be scoped strictly to the issues found — no other changes."
