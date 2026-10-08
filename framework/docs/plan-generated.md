# Work plan (self-host devframework)

## Stages
1) Finish discovery and produce the artifacts.
2) Start the orchestrator's main phase (no-op or real).
3) Run the post-run framework review.
4) Apply fixes from bug reports, then run again.

## Parallelization
- Use the task map from `docs/orchestrator-plan.md`.
- UI after component selection; real calculations after the data.

## Risks
- Missing data or credentials → a stop point that requests them.
- Worktree collisions → preflight validation.

## Definition of Done
- The main-to-post run finishes with no errors.
- Artifacts are generated and linked.
