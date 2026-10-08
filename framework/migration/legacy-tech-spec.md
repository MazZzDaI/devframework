# Legacy Tech Spec (Reverse)

## Purpose
- A local Devframework skeleton (v2026.01.24.2) for orchestrating parallel development tasks through git worktrees, automating agent launches, logging, and producing report artifacts and bundles for reporting.

## Functional requirements (from the code)
- Reads the config `framework/orchestrator/orchestrator.json|yaml`, normalizes tasks, phases (`main`, `legacy`, `post`), and dependencies.
- For each task, creates a branch and a git worktree at the given path, runs the runner's external command (by default `bash framework/tools/cursor-runner.sh "{prompt}"`, Cursor Agent on Grok), and writes stdout/stderr to a per-task log.
- Records events in `framework/logs/framework-run.jsonl`, takes a lock for the main phase, and writes a summary to `framework/docs/orchestrator-run-summary.md`.
- Supports `--include-manual` (includes tasks with `manual: true`) and dry-run.
- The installer `install-fr.sh` delivers or updates `framework/` from a local `framework.zip` or from GitHub, takes a backup on `--update`, and auto-detects the phase (legacy if the repo root contains files that are not part of the framework).
- The tools `framework/tools/export-report.py` and `publish-report.py` collect artifacts and logs into a zip and can open a GitHub PR or Issue when `GITHUB_TOKEN` is set.

## Non-functional requirements
- Requires `python3`, `git`, the Cursor CLI `agent` (Grok model), and PyYAML when the config is YAML.
- Runs locally, with no network calls in the orchestrator (except publish-report, which pushes to GitHub).
- File-based logging, no rotation; writes are expected under `framework/logs` with write permission.
- No built-in tests; reliability depends on a correct environment and working runners.

## Integrations
- Git (worktrees, branches, status).
- External agent CLI: Cursor `agent` with the Grok model (the command is set in `runners`).
- GitHub API via `publish-report.py` (curl/subprocess).
- Optionally `curl` for downloading the zip in the installer.

## Data / contracts
- Task configuration: name/branch/worktree/prompt/runner/depends_on/log/phase/manual.
- Artifacts: task logs (`framework/logs/*.log`), events (`framework-run.jsonl`), the summary (`docs/orchestrator-run-summary.md`), migration documents (`framework/migration/*.md`), report bundles (`reports/<host>/<run_id>.zip` when publishing).
- No product code, SQL, CSV templates, or fixtures are included; the declared files `plans_2026.csv`, `zip_rating_map_2026.csv`, `fpl_2026.csv`, and `slcsp_2026.csv` are missing.

## Constraints / assumptions
- The host must be a git repository; worktree paths must be free.
- External runners are assumed to exist; without them, tasks fail or hang.
- Secrets in logs are only partly redacted (regex in export-report), so nonstandard tokens can leak.
- There is no built-in check that data or a spec is present; the orchestrator will run even with empty inputs.
