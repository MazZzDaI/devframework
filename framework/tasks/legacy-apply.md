# Task: Legacy Migration Apply (manual)

## Goal
Apply the changes on the migration branch after approval.

## Inputs
- `framework/migration/approval.md`
- `framework/migration/legacy-migration-plan.md`

## Outputs
- Changes on the `legacy-migration` branch
- An updated migration plan with status

## Rules
- Start only after approval.
- Work only on the migration branch (`legacy-migration-<run_id>`).
- Do not change main directly.

## Done When
- The changes are on the branch and have been tested.
