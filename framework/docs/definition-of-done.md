# Definition of Done (DoD)

## For a feature
- Logic and UI are implemented.
- Covered by unit tests when the logic is critical.
- An end-to-end scenario is updated or added when the change affects a flow.
- The console has no errors or warnings.
- Documentation is updated when requirements changed.

## For a release
- All end-to-end tests pass.
- All critical flows were checked manually.
- An independent review is done (report in `framework/review/`).
- The review handoff is prepared (`framework/review/handoff.md`).
- Framework review is done (see `framework/framework-review/`).
- For legacy projects: the migration went through approval and a separate branch.
- Database migrations are applied.
- A rollback plan is prepared.
- Release notes are updated.
