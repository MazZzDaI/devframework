# Devframework
![Version](https://img.shields.io/badge/version-2026.10.08.2-blue)
Local scaffold for orchestrating parallel tasks with git worktrees.

## What this is and what it is for

### The problem

When you work with Cursor Agent (the Grok model) on a project, several difficulties come up:

1. **One task at a time** — the AI can work on only one task while you wait. If you need a database design, business logic, a UI, and a review, that is 8+ hours of sequential work.

2. **Git conflicts** — if several AIs run at once on the same branch, they conflict with each other and overwrite files.

3. **Constant supervision** — the AIs keep asking questions ("which library should I use?", "what should this function be called?"), which pulls you in every 5–10 minutes.

4. **Lost context** — when you switch between tasks, the AI loses the context of the previous work.

### The solution

**Devframework** is an orchestration system that lets you:

✅ **Run several AIs in parallel** — 4 tasks at once instead of one after another (2.5 hours instead of 8)

✅ **Isolate work with Git worktrees** — each AI works in its own isolated space, without conflicts

✅ **Work autonomously** — the AIs do not ask questions; they decide according to the given rules

✅ **Review automatically** — a separate AI checks the results of the others

✅ **Keep the context** — all work is logged, documented, and passed between agents

### How it works (in plain language)

Picture a **construction crew**:

1. **Foreman (Orchestrator)** — reads the work plan and assigns tasks to the crews
2. **Crews (AI Workers)** — each works on its own site (worktree) without getting in the way of the others
3. **Acceptance lead (Review Agent)** — checks the quality of the work after it is finished
4. **Work log (Logs)** — everything is recorded: who did what, and when

**In code it looks like this:**

```
Your project (main)
  ├─ worktree-1: AI #1 designs the database
  ├─ worktree-2: AI #2 writes the business logic
  ├─ worktree-3: AI #3 builds the UI components
  └─ worktree-4: AI #4 reviews the code

After completion:
  → All changes are merged into main
  → Review results are written to framework/review/
  → Logs are saved in framework/logs/
```

### Key concepts

| Term | Explanation for newcomers |
|--------|-------------------------|
| **Orchestrator** | "Dispatcher" — a Python script that reads the task config and starts AI agents in parallel |
| **Git Worktree** | "Isolated copy" — a separate working directory with the same Git history, so you can work on different branches at the same time |
| **Task** | "Assignment" — a .md file that describes what the AI should do (for example, "Design the database schema") |
| **Runner** | "Executor" — Cursor Agent on the Grok model (`cursor` for tasks, `cursor-interactive` for interviews) |
| **Phase** | "Stage" — main (development), review (checking), post (framework improvement), legacy (migrating an old project) |
| **Handoff** | "Context handoff" — a document in which the AI describes what it did and why, for the next AI |

### Who it is for

✅ **Developers** who use AI assistants and want to speed development up by 3–4 times

✅ **Tech leads** who manage several AI agents as a team

✅ **Teams** migrating legacy projects with AI (safely, with a risk analysis)

✅ **DevOps/Platform Engineers** who automate development processes

### What is inside the repository

```
devframework/
├── framework/                    # Core framework
│   ├── orchestrator/             # Orchestrator (task launcher)
│   │   ├── orchestrator.py       # Main script
│   │   └── orchestrator.json     # Config: which tasks, which AIs
│   ├── tasks/                    # Task templates for the AI
│   │   ├── db-schema.md          # "Design the database"
│   │   ├── business-logic.md     # "Implement the logic"
│   │   └── ui.md                 # "Build the UI"
│   ├── docs/                     # Output documents (handoffs, specs)
│   ├── review/                   # Code review results
│   ├── migration/                # Legacy-code analysis and migration
│   └── logs/                     # Execution logs
├── .cursor/rules/                # Cursor rule: follow AGENTS.md and stay on Grok
├── AGENTS.md                     # Protocol that Cursor reads on its own
├── install-fr.sh               # Installer for new projects
└── README.md                     # This file
```

The `claude-code/` folder is an archive of notes from the upstream version (Codex / Claude Code). The working agent of this fork is Cursor + Grok.

### Cursor + Grok

DevFramework runs the [Cursor Agent CLI](https://cursor.com/docs/cli/using) (`agent`) with the **Grok 4.7** model.

- Interactive interview: `./cursor`, then "start".
- Parallel tasks: `agent -p --force --trust --model grok-4.7` through `framework/tools/cursor-runner.sh`.
- Project context: `AGENTS.md` and `.cursor/rules/devframework.mdc` (Cursor picks up both).
- Another Grok model: `FRAMEWORK_CURSOR_MODEL=grok-4.5` (or `grok-4.6`).

Install the CLI and sign in:

```bash
curl https://cursor.com/install -fsS | bash
agent login
```

For an orchestrator without a TTY, `CURSOR_API_KEY` is enough.

### Quick start in 3 steps

**1. Clone the repository:**
```bash
git clone https://github.com/MazZzDaI/devframework.git
cd devframework
```

**2. Initialize the project:**
```bash
git init
git add .
git commit -m "init"
```

**3. Run the installer:**
```bash
./install-fr.sh
```

The orchestrator automatically:
- Creates worktrees for the parallel tasks
- Starts AI agents from the assignments in `framework/tasks/`
- Collects the results and creates a review
 - After a migration (legacy), moves on to the interview (discovery) automatically

### Agent

The supported executor is **Cursor Agent on Grok**. The orchestrator starts it in isolated Git worktrees. The default model is `grok-4.7`; override it with `FRAMEWORK_CURSOR_MODEL`.

---

## Structure
- framework/orchestrator/ - script and YAML config
- framework/docs/ - process docs, checklists, orchestration plan
- framework/tasks/ - task mini-spec templates
- framework/review/ - independent review artifacts and runbook
- framework/framework-review/ - framework QA artifacts (third flow)
- framework/migration/ - legacy migration analysis and safety artifacts
- framework/VERSION - framework release identifier
- framework.zip - portable bundle for host projects
- install-fr.sh - installer for framework.zip
- scripts/package-framework.py - build helper for framework.zip

## Quick start
1) Fill in the task files in `framework/tasks/*.md`.
2) Review `framework/orchestrator/orchestrator.json`.
3) Run:
   `python3 framework/orchestrator/orchestrator.py --config framework/orchestrator/orchestrator.json`

## Install in a host project (launcher)
1) Copy `install-fr.sh` (or `install-fr-<version>.sh`) into the host project root.
2) Run (self-contained installer; installs into `./framework` and writes `AGENTS.md`):
   `./install-fr.sh`
3) Start Cursor Agent in the project root and say **"start"** to begin the protocol:
   `./cursor`

Tip: release assets include both:
- `install-fr.sh` (latest)
- `install-fr-<version>.sh` (pinned version)

### Host prerequisites (before running the launcher)
- Git repo initialized in the host project (remote is optional):
  ```
  git init
  git add .
  git commit -m "init"
  ```
- `python3` available on PATH:
  ```
  python3 --version
  ```
- Network access to GitHub to check and download the latest release.
- (Optional) `curl` installed; if missing, Python will download the zip instead.
- Cursor CLI `agent` on `PATH`, signed in with `agent login` or `CURSOR_API_KEY`.
- Default model is Grok 4.7 (`FRAMEWORK_CURSOR_MODEL` overrides it). Headless tasks also pass `--force --trust`.
- If `./framework` already exists, the launcher auto-updates when the latest release differs.
  Use `--update` to force a refresh or when using a local zip.

Options:
- Use a local zip: `./install-fr.sh --zip ./framework.zip`
- Force update (creates a backup first): `./install-fr.sh --update`
- Run orchestrator immediately (legacy/main/post): `./install-fr.sh --run --phase legacy|main|post`
- Override repo/ref:
  `FRAMEWORK_REPO=MazZzDaI/devframework FRAMEWORK_REF=main ./install-fr.sh`
  (REF can be a tag, e.g. `v2026.01.24`)

Auto-detection (when running the orchestrator manually):
- If the host root contains only `.git`, `framework/`, `framework.zip`, `install-fr.sh`, or `install-fr-<version>.sh`,
  `run-protocol.py` chooses discovery.
- Otherwise it assumes legacy.
- To skip auto-discovery after legacy: `FRAMEWORK_SKIP_DISCOVERY=1`.
- To resume from last completed phase: `FRAMEWORK_RESUME=1`.
- Status line: `FRAMEWORK_STATUS_INTERVAL=10` (seconds between `[STATUS]` lines).
- Watcher poll: `FRAMEWORK_WATCH_POLL=2`.
- Stall detection: `FRAMEWORK_STALL_TIMEOUT=900` and `FRAMEWORK_STALL_KILL=1`.
- Offline fallback (skip GitHub download): `FRAMEWORK_OFFLINE=1`.

## End-to-end flows (memory cheatsheet)

### A) New project (clean host)
1) `./install-fr.sh`
2) Run `./cursor` and say **"start"** to begin discovery.
3) Discovery interview → tech spec / plan / test plan.
   - Pause command: type `/pause` to stop and resume later.
4) User reviews outputs and confirms start of development.
5) Start development:
   `python3 framework/orchestrator/orchestrator.py --phase main`
6) Dev flow completes → parallel review flow uses `framework/review/`.
7) Optional post-run framework QA:
   `python3 framework/orchestrator/orchestrator.py --phase post`
8) Auto-publish (optional): set `FRAMEWORK_REPORTING_*` env vars before step 1.

### B) Legacy project (migration + safety)
1) `./install-fr.sh`
2) Run `./cursor` and say **"start"**:
   - Legacy analysis runs first (read-only).
   - Then a discovery interview in Cursor Agent (Grok).
   - Pause command: type `/pause` to stop and resume later.
3) Review migration artifacts:
   - `framework/migration/legacy-snapshot.md`
   - `framework/migration/legacy-tech-spec.md`
   - `framework/migration/legacy-gap-report.md`
   - `framework/migration/legacy-risk-assessment.md`
   - `framework/migration/legacy-migration-plan.md`
   - `framework/migration/legacy-migration-proposal.md`
4) Human approval gate:
   - Fill `framework/migration/approval.md`
5) Apply changes in isolated branch:
   `python3 framework/orchestrator/orchestrator.py --phase legacy --include-manual`
   (branch name includes `legacy-migration-<run_id>`)
6) Start development (after interview + approval):
   `python3 framework/orchestrator/orchestrator.py --phase main`
7) Run review/tests, then merge manually if safe.
8) Optional framework QA (post-run) and auto-publish.

### C) Framework improvement loop (3rd agent)
1) Main or legacy run finishes.
2) Framework QA (post phase):
   `python3 framework/orchestrator/orchestrator.py --phase post`
3) Output:
   - `framework/framework-review/framework-log-analysis.md`
   - `framework/framework-review/framework-bug-report.md`
   - `framework/framework-review/framework-fix-plan.md`
4) Apply fixes between runs:
   `python3 framework/orchestrator/orchestrator.py --phase post --include-manual`
5) Rebuild release zip if framework changed:
   `python3 scripts/package-framework.py --version <new_version>`

### D) Auto‑report publishing (no manual steps)
1) Set env before running the launcher:
   - `FRAMEWORK_REPORTING_ENABLED=1`
   - `FRAMEWORK_REPORTING_REPO=MazZzDaI/devframework`
   - `FRAMEWORK_REPORTING_MODE=pr|issue|both`
   - `FRAMEWORK_REPORTING_HOST_ID=<host>`
   - `FRAMEWORK_REPORTING_PHASES=legacy,main,post`
   - (optional) `FRAMEWORK_REPORTING_INCLUDE_MIGRATION=1`
   - (optional) `FRAMEWORK_REPORTING_INCLUDE_REVIEW=1`
   - (optional) `FRAMEWORK_REPORTING_INCLUDE_TASK_LOGS=1`
   - `GITHUB_TOKEN=...`
2) `./install-fr.sh`
3) PR/issue will be created automatically in `devframework`.

## Minimal quick start (one‑liners)
New project:
```
FRAMEWORK_REPORTING_ENABLED=1 FRAMEWORK_REPORTING_REPO=MazZzDaI/devframework FRAMEWORK_REPORTING_MODE=pr FRAMEWORK_REPORTING_HOST_ID=$(basename "$PWD") GITHUB_TOKEN=... ./install-fr.sh
```
Legacy project:
```
FRAMEWORK_REPORTING_ENABLED=1 FRAMEWORK_REPORTING_REPO=MazZzDaI/devframework FRAMEWORK_REPORTING_MODE=pr FRAMEWORK_REPORTING_HOST_ID=$(basename "$PWD") GITHUB_TOKEN=... ./install-fr.sh --phase legacy
```

## Build release zip (maintainers)
```
python3 scripts/package-framework.py
```
Produces `framework.zip` and keeps `framework/VERSION` as the version string.
Use `--version <value>` to update `framework/VERSION`.

## Report bundle + auto publish (host project)
1) Export report bundle (redacts logs by default):
   `python3 framework/tools/export-report.py --include-migration`
2) Publish to central repo (creates PR by default):
   `export GITHUB_TOKEN=...`
   `python3 framework/tools/publish-report.py --repo MazZzDaI/devframework --run-id <RUN_ID> --host-id <HOST_ID>`

Auto-publish from orchestrator (no manual command):
- Set `reporting` in `framework/orchestrator/orchestrator.json` or via env vars:
  - `FRAMEWORK_REPORTING_ENABLED=1`
  - `FRAMEWORK_REPORTING_REPO=MazZzDaI/devframework`
  - `FRAMEWORK_REPORTING_MODE=pr|issue|both`
  - `FRAMEWORK_REPORTING_HOST_ID=<host>`
  - `FRAMEWORK_REPORTING_PHASES=legacy,main,post`
  - `FRAMEWORK_REPORTING_INCLUDE_MIGRATION=1` (optional)
  - `FRAMEWORK_REPORTING_INCLUDE_REVIEW=1` (optional)
  - `FRAMEWORK_REPORTING_INCLUDE_TASK_LOGS=1` (optional, redacted)
  - `FRAMEWORK_REPORTING_DRY_RUN=1` (optional; skips network, prints planned publish)
- Requires `GITHUB_TOKEN`.

Notes:
- The publish script pushes a report zip into `reports/<host>/<run_id>.zip` and opens a PR/Issue.
- Redaction replaces obvious secrets in logs; turn off with `--no-redact` during export if needed.

## Outputs
- `framework/logs/*.log`
- `framework/logs/framework-run.jsonl`
- `framework/logs/protocol-alerts.log`
- `framework/logs/protocol-status.log`
- `framework/logs/discovery.transcript.log`
- `framework/logs/discovery.pause` (if interview paused)
- `framework/docs/orchestrator-run-summary.md`
- `framework/review/*.md`
- `framework/framework-review/*.md`
- `framework/migration/*.md`

## Notes
- Relative paths in YAML are resolved from the config file; task paths are resolved from `project_root`.
- The repo must be a git repository (for `git worktree`).
- `framework/logs/framework-run.lock` exists only during an active main run; post-run tasks require it to be absent.
- Default task worktrees are created under `_worktrees/{phase}/{task}` unless overridden in config.
- If a worktree path already exists, the orchestrator verifies it belongs to the same git repo and aborts otherwise.
- Progress heartbeat: `FRAMEWORK_PROGRESS_INTERVAL=10` prints `[RUNNING] ...` status; set `0` to disable.
- Protocol watcher status: `FRAMEWORK_STATUS_INTERVAL=10` prints `[STATUS] ...`; set `0` to disable.

## Parallel review flow (two-agent)
1) Dev agent completes tasks and prepares `framework/review/handoff.md` (and test results if any).
2) In parallel, a second agent uses `framework/review/runbook.md` and `framework/review/review-brief.md` to run review/testing.
3) Review outputs go to `framework/review/` and are fed back to the dev agent.

## Framework QA flow (third agent, post-run)
1) Main run finishes and `framework/logs/framework-run.lock` is removed.
2) Run post phase:
   `python3 framework/orchestrator/orchestrator.py --phase post`
3) Framework review outputs are written to `framework/framework-review/`.
4) If fixes are needed, run:
   `python3 framework/orchestrator/orchestrator.py --phase post --include-manual`
5) Use `framework/framework-review/bundle.md` as the single entry point for the third agent.

## Legacy migration flow (read-only + approval gate)
1) Run legacy analysis phase:
   `python3 framework/orchestrator/orchestrator.py --phase legacy`
2) Review artifacts in `framework/migration/`.
3) Human approval in `framework/migration/approval.md`.
4) Apply changes in isolated branch (manual):
   `python3 framework/orchestrator/orchestrator.py --phase legacy --include-manual`
   (branch name: `legacy-migration-<run_id>`)

## AGENTS.md and Cursor rules

Cursor Agent (editor and CLI) loads project instructions at session start:

- `AGENTS.md` at the repo root
- `CLAUDE.md` if present (not used by this fork)
- `.cursor/rules/*.mdc`

The installer writes a managed `AGENTS.md` from `framework/AGENTS.template.md` and copies `framework/cursor/rules/devframework.mdc` to `.cursor/rules/`. Files marked `DEVFRAMEWORK:MANAGED` are refreshed on the next install. A hand-edited file without that marker is left alone.

`AGENTS.md` holds the start protocol: legacy detection, one-question discovery, artifact generation, and the gate before `--phase main`. Keep it short. Task details stay in `framework/tasks/` and `framework/docs/`.

Say **start** in `./cursor` to run that protocol. There is no separate init command: a new `agent` session picks up the files automatically.

## Model

| Surface | How Grok is selected |
|---|---|
| `./cursor` | `agent --model "$FRAMEWORK_CURSOR_MODEL"` (default `grok-4.7`) |
| Headless tasks | `framework/tools/cursor-runner.sh` passes the same model with `-p --force --trust` |
| Interactive discovery | orchestrator attaches `agent --model …` and, on resume, `agent --continue` |

Override the model for a run:

```bash
FRAMEWORK_CURSOR_MODEL=grok-4.5 ./cursor
```

`grok-4.6` and `grok-4.5` are the other Grok models in the Cursor catalog. Check the account list with `agent models`.

Headless sandbox defaults to `disabled` so agents can write the worktree. Set `FRAMEWORK_CURSOR_SANDBOX=enabled` to turn it back on.

## Rules

`.cursor/rules/devframework.mdc` is `alwaysApply: true`. It tells Grok to follow `AGENTS.md`, ask one discovery question at a time, and stay on the selected Grok model.

Cursor skills (`.cursor/skills` or user skills) are separate from this protocol. The rule does not replace them; it only pins the DevFramework start behavior.
