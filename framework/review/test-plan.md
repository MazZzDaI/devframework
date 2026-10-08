# Test plan (self-hosted devframework)

## 1) Goals
- Verify that devframework can run an interview, generate artifacts, and complete a main-to-post run without errors.
- Confirm that secrets do not leak into logs or reports.
- Check readiness for typical host repos (empty, legacy).

## 2) Scope
- Orchestrator CLI and config (`orchestrator.py`, `orchestrator.json`).
- Discovery flow and file generation (`docs/discovery/interview.md`, generated docs).
- Report export/publish tools (`tools/export-report.py`, `tools/publish-report.py`).
- Framework-review flow (post phase).

## 3) Test types
- Unit: config parsing, worktree path validation, lock handling, redact functions, YAML/JSON I/O.
- Integration: no-op main run; export-report on synthetic logs; publish-report dry-run.
- E2E: install via `install-fr.sh` into an empty repo; main-to-post no-op run; legacy analysis run (read-only).
- Manual/UX: check that generated artifacts are understandable to a non-technical user.

## 4) Critical scenarios
1) Install into an empty repo, then a main no-op run: artifacts are generated and there are no errors.
2) Run the legacy phase in a repo with arbitrary files: migration artifacts are created and the code is not changed.
3) Export plus redact: the report contains no secrets and does include the key logs.
4) Framework post-run review: `framework-review/*` files are generated without crashes.

## 5) Negative cases
- Missing worktree paths / paths already in use: a clear error, and the repo is not corrupted.
- Git is missing: a clear message and a graceful exit.
- PyYAML or other dependencies are missing: a message that includes instructions.
- Empty or corrupted orchestrator config: a validation error.
- Credentials are missing when a real deploy is attempted: stop at the checkpoint, with no secret leaks.

## 6) Acceptance criteria
- All critical scenarios pass; there are no P0/P1 issues.
- Logs contain no secrets; export and publish do not reveal tokens.
- The main-to-post no-op run finishes successfully and is repeatable.

## 7) Data and fixtures
- Synthetic logs and run jsonl for export/redact.
- An empty git repo for installation; a repo with junk files for the legacy check.
- Stub data templates (`plans_2026.csv` etc.) when needed.
