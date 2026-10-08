# Legacy Migration (safe-mode)

Goal: put a legacy project back on the framework rails without risking the existing code.
The whole migration is isolated and stays read-only until a person explicitly approves it.

## Safety principles
- Analysis is read-only (no code edits).
- All changes happen on a separate branch and worktree.
- An approval gate is required.
- Rollback is possible: main is left untouched until an explicit merge.
 - The migration branch is created automatically as `legacy-migration-<run_id>`.

## Output artifacts
- `framework/migration/legacy-snapshot.md` — an objective picture of the project
- `framework/migration/legacy-tech-spec.md` — a reverse spec derived from the code
- `framework/migration/legacy-gap-report.md` — what is missing relative to the framework
- `framework/migration/legacy-risk-assessment.md` — risks and critical areas
- `framework/migration/legacy-migration-plan.md` — a staged migration plan
- `framework/migration/legacy-migration-proposal.md` — a proposal for approval
- `framework/migration/approval.md` — the human decision
- `framework/migration/rollback-plan.md` — the rollback plan

## Stages
1) **Legacy Audit (read-only)**
2) **Reverse Spec (read-only)**
3) **Gap + Risk (read-only)**
4) **Migration Plan (read-only)**
5) **Approval Gate (human)**
6) **Apply in branch**
7) **Review + Tests**
8) **Merge (manual)**

Detailed steps: `framework/migration/runbook.md`.
