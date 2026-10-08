# Legacy Migration Plan

## Strategy
- Self-dogfood: bring the framework itself up to the framework's requirements, changing the API as little as possible; add predictability (preflight), testability, and data/spec artifacts.

## Stages
1) Stabilize: clean up and normalize worktree paths, add environment preflight checks (python, git, runner CLI, write access to `framework/logs`, free worktrees/branches), and expand secret redaction in export-report.
2) Complete the facts: fill in `legacy-tech-spec`, `legacy-gap-report`, `legacy-migration-plan`, and `approval`; attach the missing docs and data templates (empty or sample CSVs) and describe the contract; document DoD/Review/Tests/Observability in the README.
3) Validate and ship: add a basic CI (lint plus smoke `python -m py_compile` / `python -m compileall` plus an orchestrator dry-run), build a new `framework.zip`, run the `legacy` and `post` phases, and optionally publish the report.

## Minimal changes (safe path)
- Do not change the orchestrator's external CLI API; add only preflight and broader secret redaction.
- Drop in sample CSV and doc stubs instead of real data.
- Enable a runner fallback (when the CLI is missing, start with `FRAMEWORK_RUNNER_NOOP=1`) through an environment variable, without hard-patching the orchestrator.

## Validation
- `python3 framework/orchestrator/orchestrator.py --config framework/orchestrator/orchestrator.json --phase legacy --dry-run` (checks dependencies and preflight).
- `python3 -m compileall framework` and `python3 scripts/package-framework.py` with no errors.
- Run `--phase main` and `--phase post` on a clean host; artifacts land in `framework/docs/orchestrator-run-summary.md` and `framework/framework-review/*` with no FAIL.
