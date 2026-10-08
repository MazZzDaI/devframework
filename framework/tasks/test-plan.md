# Task: Test Plan (independent)

## Goal
Write an independent test plan from the spec and the definition of done.

## Inputs
- `framework/docs/definition-of-done.md`
- `framework/docs/orchestrator-plan.md`
- `docs/tech-spec.md` (if present)
- `framework/review/review-brief.md`
- `framework/review/handoff.md` (if present)

## Outputs
- `framework/review/test-plan.md` (using the template in `framework/review/`)

## Rules
- Do not change code.
- State the test types (unit/integration/e2e/manual).
- Explicitly record gaps when data or a spec is missing.

## Done When
- The test plan covers the critical flows and risks.
- The plan is readable and can be executed independently.
