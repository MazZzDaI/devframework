# Legacy Snapshot

## Project summary
- Devframework v2026.01.24.2: a local skeleton for orchestrating parallel tasks through git worktrees, generating logs and reports, and publishing bundles. This worktree has no product application code (only the framework itself).
- Target domain from the documentation: subsidy and plan calculation (FPL/SLCSP/ZIP 2026), wizard questionnaire to calculation to results to PDF, multi-tenant Supabase with encryption before write.

## Architecture / modules
- The orchestrator (`framework/orchestrator/orchestrator.py`) reads the config (`orchestrator.json|yaml`), creates a worktree and branch per task, logs events to `framework/logs/framework-run.jsonl`, takes a lock for the main phase, writes `docs/orchestrator-run-summary.md`, and optionally publishes a report through `tools/publish-report.py`.
- Tasks are described in `framework/tasks/*.md`, with phases main/post/legacy. The runner calls the Cursor CLI `agent` on the Grok model. Worktree paths are set in the config ahead of time.
- Folders: `framework/migration` (templates for snapshot/tech-spec/gap/risk/plan/approval/rollback plus the runbook), `framework/review` (independent review and test plan), `framework/framework-review` (post-run QA of the framework itself), `framework/tools` (export and publish reports), `install-fr.sh` (install/update and auto-start the orchestrator).

## Data / database
- The documentation requires the templates `plans_2026.csv`, `zip_rating_map_2026.csv`, `fpl_2026.csv`, and `slcsp_2026.csv` (see orchestrator-plan), but the files are not present.
- A minimal table contract is described: `plans`, `rating_area_map`, `questionnaires`, `reports`, `chat_sessions`/`chat_messages`, `users`, `subscriptions`, `token_balance`, with `project_id` everywhere and versioning (`version`, `is_current`). There are no ready migrations or RLS policies.
- The repository has no real data, fixtures, or SQL schemas.

## Critical flows
- User flow: Wizard to questionnaire to subsidy calculation to Results to Report to PDF; What-If recalculations; session and LLM logging.
- Release check: Wizard to Results to Report to PDF, auth plus subscriptions, email and web-push notifications, database migrations and RLS.
- Legacy contour: read-only audit, then reverse tech spec, then gap plus risk, then migration plan, then human approval, then apply only on the `legacy-migration-<run_id>` branch, then review and tests.

## Tests / CI
- There are no automated tests or CI configs (.github/ and equivalents are absent); only templates exist (`framework/review/test-plan.md`, tasks that mention unit/E2E).
- There are no test logs or reports; the orchestrator does not invoke test runners.

## Known issues
- This worktree has no product source, migrations, or data, so an audit of the actual logic and schemas is impossible.
- Referenced artifacts from the documentation are missing (`docs/tech-spec.md`, `docs/tech-addendum-1.md`, `docs/data-templates.md`, `docs/inputs-required.md`), so the db-schema, business-logic, and UI tasks have no source context.
- The orchestrator depends on external CLI runners and PyYAML; without them, tasks do not start, and there is no validation.
- `export-report.py` redacts only simple tokens and keys (a few regexes); other secrets can remain in the logs.
- `install-fr.sh` and the orchestrator require git and free worktree paths. Running outside git, or when conflicting paths already exist, produces an error and does not resolve collisions automatically.
