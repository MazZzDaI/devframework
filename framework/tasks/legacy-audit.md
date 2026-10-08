# Task: Legacy Audit (read-only)

## Goal
Capture an objective picture of the legacy project without changing code.

## Inputs
- The repository (read-only)
- `framework/docs/definition-of-done.md`

## Outputs
- `framework/migration/legacy-snapshot.md`

## Rules
- No code edits.
- Analysis and recorded facts only.
- Ignore service directories: `framework/`, `framework.backup.*`, `_worktrees/`, `.git`.

## Done When
- The snapshot is filled in.
