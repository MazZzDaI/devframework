# Legacy Migration Runbook

## 0) Preconditions
- The main branch is stable.
- There is a restore point (commit hash).
- The main agents are not running.

## 1) Read-only analysis (legacy phase)
- Run analysis and document generation only.
- Do not change code.
```
python3 framework/orchestrator/orchestrator.py --phase legacy
```

## 2) Produce the artifacts
- `framework/migration/legacy-snapshot.md`
- `framework/migration/legacy-tech-spec.md`
- `framework/migration/legacy-gap-report.md`
- `framework/migration/legacy-risk-assessment.md`
- `framework/migration/legacy-migration-plan.md`
- `framework/migration/legacy-migration-proposal.md`

## 3) Approval gate
- A person fills in `framework/migration/approval.md`.
- Changes are forbidden without approval.

## 4) Create the migration branch (isolated)
The orchestrator creates the branch automatically when `legacy-apply` starts, and the name includes `run_id`:
`legacy-migration-<run_id>`.

## 5) Apply changes only on the migration branch
- All edits stay on the `legacy-migration` branch.
- After the changes, run tests and review.
```
python3 framework/orchestrator/orchestrator.py --phase legacy --include-manual
```

## 6) Merge into main (manual)
- Only after tests and review.
- If something goes wrong, roll back with reset/rollback on main.

## 7) Post-merge check
- Update statuses in `framework/migration/legacy-migration-plan.md`.
- Record the outcome in `framework/migration/legacy-migration-proposal.md`.
