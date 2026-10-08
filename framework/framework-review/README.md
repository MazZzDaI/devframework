# Framework Review

This flow analyzes errors and the quality of the framework itself (the orchestrator).
It runs only between active sessions (after the main run finishes).

## Contents
- `bundle.md` — single entry point for the post-run review
- `runbook.md` — how to run the analysis
- `framework-log-analysis.md` — analysis of the run logs
- `framework-bug-report.md` — bug report for the framework
- `framework-fix-plan.md` — fix plan

## When to run
- Only after the main run has finished.
- Make sure `framework/logs/framework-run.lock` is absent.
