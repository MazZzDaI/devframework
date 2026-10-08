# Concept for orchestrating parallel tasks (local)

Goal: **fully automate** launching parallel tasks, with no human involvement after the design stage.

---

## 1) Overall idea
The orchestrator is a local utility that:
1) reads the task list and its parameters (from YAML),
2) creates a separate git worktree and branch for each task,
3) launches an agent in each worktree,
4) monitors execution (by process status),
5) collects the results and saves them to a report.

---

## 2) Why Python (not bash)
Python is a better fit for:
- managing dependencies between tasks,
- logging to files,
- monitoring statuses,
- more complex logic (retry, timeouts).

---

## 3) What the process looks like
1) Prepare **mini-tasks** in `framework/tasks/*.md`.
2) Configure the task list in `framework/orchestrator/orchestrator.json`.
3) Run:
   ```bash
   python3 framework/orchestrator/orchestrator.py --config framework/orchestrator/orchestrator.json
   ```
4) The orchestrator:
   - creates a worktree for each task (by default `_worktrees/{phase}/{task}`),
   - runs the commands,
   - writes a log to `framework/logs/*.log`,
   - creates the report `framework/docs/orchestrator-run-summary.md`,
   - periodically prints `[RUNNING] ...` as a sign of life (the interval is set by `FRAMEWORK_PROGRESS_INTERVAL`).

**Key user flow:**
- Empty project → start the interview (phase `discovery`) → generate the spec → confirm the start of development → phase `main`.
- Legacy project → analysis (phase `legacy`) → interview (phase `discovery`) → confirm the start of development → phase `main`.

**Monitoring and resilience:**
- The protocol is started through `framework/tools/run-protocol.py`.
- A watcher (`framework/tools/protocol-watch.py`) tracks progress, writes alerts, and stops the protocol after a long idle period.
- A `[STATUS]` status line is printed every 10 seconds (setting: `FRAMEWORK_STATUS_INTERVAL`).
- The discovery interview is interactive; use the `/pause` command to pause.

---

## 4) Parallelism and dependencies
- Each task can have `depends_on`.
- The orchestrator starts a task only after its dependencies complete successfully.

---

## 5) How an agent is launched
The YAML config has a `command` for each task, for example:
```
command: "bash framework/tools/cursor-runner.sh framework/tasks/db-schema.md"
```
The command can be anything; what matters is that it exits with code 0 on success.

---

## 6) Output artifacts
- `framework/logs/<task>.log` — log for each task
- `framework/docs/orchestrator-run-summary.md` — final status

---

## 7) Limitations
- The orchestrator is local, with no server-side automation.
- Full autonomy depends on correct mini-prompts.

---

## 8) Independent review (two sessions)
The idea: the dev agent finishes its work and prepares a handoff, and a second agent in another worktree
runs the review and tests without that context.

**Artifacts:**
- `framework/review/handoff.md` — context and launch commands from the dev agent.
- `framework/review/test-plan.md` — independent test plan.
- `framework/review/code-review-report.md`, `framework/review/bug-report.md`, `framework/review/qa-coverage.md`.

---

## 9) Framework Review (third stream, post-run)
The idea: a separate agent analyzes the framework's own errors between runs.

**Rule:** the third stream starts only after the main run finishes.

**Mechanics:**
- During the main run, `framework/logs/framework-run.lock` is created.
- After completion the lock is removed and post-run tasks can be started.
- Logs are stored in `framework/logs/framework-run.jsonl`.

**Artifacts:**
- `framework/framework-review/framework-log-analysis.md`
- `framework/framework-review/framework-bug-report.md`
- `framework/framework-review/framework-fix-plan.md`

---

## 10) Legacy Migration (read-only track)
Legacy migration runs on a separate track and does not change code until approval.

**Artifacts:**
- `framework/migration/legacy-snapshot.md`
- `framework/migration/legacy-tech-spec.md`
- `framework/migration/legacy-gap-report.md`
- `framework/migration/legacy-risk-assessment.md`
- `framework/migration/legacy-migration-plan.md`
- `framework/migration/legacy-migration-proposal.md`
- `framework/migration/approval.md`
- `framework/migration/rollback-plan.md`
