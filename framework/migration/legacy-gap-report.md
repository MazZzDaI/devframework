# Legacy Gap Report

## What is missing relative to the framework
- There is no product code, data, or fixtures, so the db-schema, business-logic, and UI tasks are not grounded in facts.
- The declared CSVs are not attached (`plans_2026.csv`, `zip_rating_map_2026.csv`, `fpl_2026.csv`, `slcsp_2026.csv`), nor are the extra specs (`docs/tech-spec.md`, `tech-addendum-1.md`, `data-templates.md`, `inputs-required.md`).
- There is no environment check: runner CLI, PyYAML, git worktree access, write permissions. The orchestrator does not validate and then fails or hangs.
- There are no automated tests or CI, no lint/format, and no health checks for logs or reports.
- Secret redaction is partial: nonstandard tokens can end up in logs or the bundle.

## Process quality
- DoD: not recorded; there are no readiness criteria for artifacts or a release.
- Review: templates exist (`framework/review/*`), but there are no real reviews or results.
- Tests: no automated tests and no pipeline; the test plan was never filled in.
- Observability: only the orchestrator's file logs; no metrics, alerts, or retention.

## Migration risks
- Running on machines without a runner CLI or write permission will crash the pipeline.
- Secrets can leak when reports are published (redaction does not cover every pattern).
- Worktree and branch collisions on repeat runs if nothing is cleaned up.
- Nondeterministic results because tests and source data are missing.
