# Task: Framework Fix (post-run, manual)

## Goal
Apply fixes to the framework based on the framework review.

## Inputs
- `framework/framework-review/framework-bug-report.md`
- `framework/framework-review/framework-fix-plan.md`

## Outputs
- Changes in the framework code
- An updated `framework/framework-review/framework-fix-plan.md`

## Rules
- Run only between runs.
- Do not start if `framework/logs/framework-run.lock` is active.

## Done When
- The fixes are in and described.
- The fix plan is updated with a completed status.
