# Task: Framework Review (post-run)

## Goal
Analyze how the framework ran and produce a bug report from the logs.

## Inputs
- `framework/logs/framework-run.jsonl`
- `framework/docs/orchestrator-run-summary.md`
- `framework/logs/*.log`
- `framework/orchestrator/orchestrator.py`
- `framework/orchestrator/orchestrator.json`

## Outputs
- `framework/framework-review/bundle.md`
- `framework/framework-review/framework-log-analysis.md`
- `framework/framework-review/framework-bug-report.md`
- `framework/framework-review/framework-fix-plan.md`

## Rules
- Run only between runs (no `framework/logs/framework-run.lock`).
- Do not change code, only reports.

## Done When
- The analysis and bug report are filled in.
- There is a fix plan.
