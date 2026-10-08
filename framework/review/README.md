# Independent testing and code review (QA/Review)

This folder holds everything needed for an independent AI review and a test plan.

## Contents
- `review-brief.md` — short instructions for the reviewer
- `handoff.md` — handoff from the dev agent (context, commands, risks)
- `bundle.md` — single entry point for the review
- `test-plan.md` — test plan template
- `test-results.md` — test run results
- `code-review-report.md` — review report template
- `bug-report.md` — bug report template
- `qa-coverage.md` — what was actually tested and the coverage
- `runbook.md` — step-by-step review launch (worktree)

## Recommended process
1) The dev agent fills in `framework/review/handoff.md` (and `framework/review/test-results.md` if tests were run).
2) The independent agent reads `framework/review/review-brief.md` plus `framework/review/handoff.md`.
3) It writes `framework/review/test-plan.md`, runs the checks, and fills in the reports.
4) It returns the results to the main branch.
