# Runbook: Framework Review (post-run)

## 1) Confirm the main run has finished
- The file `framework/logs/framework-run.lock` must be absent.
- `framework/docs/orchestrator-run-summary.md` and `framework/logs/framework-run.jsonl` must exist.

## 2) Fill in the bundle and read the input artifacts
- Fill in `framework/framework-review/bundle.md` from the summary and logs
- `framework/framework-review/bundle.md`
- `framework/docs/orchestrator-run-summary.md`
- `framework/logs/framework-run.jsonl`
- `framework/logs/*.log`
- `framework/orchestrator/orchestrator.py`
- `framework/orchestrator/orchestrator.json`

## 3) Fill in the analysis
- `framework/framework-review/framework-log-analysis.md`

## 4) Write the bug report
- `framework/framework-review/framework-bug-report.md`

## 5) Prepare the fix plan
- `framework/framework-review/framework-fix-plan.md`

## Important
- Do not change code during analysis.
- Fixes are a separate task and happen only between runs.
