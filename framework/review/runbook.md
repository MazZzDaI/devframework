# Runbook: independent review via worktree

## 1) Create a worktree
```bash
git worktree add ../project-review <COMMIT_HASH>
```

## 2) Read the bundle/brief/handoff
- `framework/review/bundle.md`
- `framework/review/review-brief.md`
- `framework/review/handoff.md`

## 3) Start the agent
```bash
cd ../project-review
# start your AI agent with the prompt from framework/review/review-brief.md
```

## 4) Run tests (if any)
- Use the commands from `framework/review/handoff.md` or `framework/review/review-brief.md`
- Save results/logs in `framework/review/test-results.md`

## 5) Wrap up
- Fill in:
  - `framework/review/test-plan.md`
  - `framework/review/test-results.md`
  - `framework/review/code-review-report.md`
  - `framework/review/bug-report.md`
  - `framework/review/qa-coverage.md`
- Hand the results back to the main branch
