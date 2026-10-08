# Rollback Plan

## Rollback conditions
- The pipeline fails because a runner or write permission is missing, or because worktrees conflict.
- After a `framework/` update, install or startup breaks on hosts.
- Publishing a report revealed secrets that were not redacted.

## Rollback steps
1) Return to the backup `framework.backup.<ts>` (created by the installer on `--update`): `rm -rf framework && mv framework.backup.<ts> framework`.
2) Remove the created worktrees and branches: `rm -rf _worktrees && git worktree prune && git branch -D task/* legacy-migration-* || true`.

## Restoring state
- Rebuild a known-good `framework.zip` from a stable version (`scripts/package-framework.py`), then rerun `./install-fr.sh --zip ./framework.zip --update --phase legacy --dry-run` to validate.
