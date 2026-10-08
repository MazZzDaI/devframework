# Legacy Risk Assessment

## Risks
- A missing runner CLI, PyYAML, or write permission breaks the pipeline (tasks hang or fail).
- Secrets leak into logs or bundles because redaction is incomplete.
- Branch and worktree collisions on repeat runs and on auto-generated `task/*` names.
- Artifacts are unreliable because real data, code, and tests are missing.

## Areas that need extra care
- Runs on machines without git, or in a directory that is not a git repo.
- Publishing reports to private repos without checking that secrets were redacted.
- An automatic `--update` by the installer while `framework/` has custom edits.

## Stop factors
- The host has no `git init`, or there is no write access to `framework/logs`.
- Existing worktrees or branches named `task/*` and `legacy-migration-*` conflict.
- The runner CLI is missing and the config has no no-op fallback.
