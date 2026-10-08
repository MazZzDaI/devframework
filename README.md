# Devframework
![Version](https://img.shields.io/badge/version-2026.10.08.1-blue)
Local scaffold for orchestrating parallel tasks with git worktrees.

## Что это такое и для чего

### Проблема

Когда вы работаете с Cursor Agent (модель Grok) над разработкой проекта, возникают сложности:

1. **Одна задача за раз** — AI может работать только над одной задачей, пока вы ждёте. Если нужно сделать дизайн БД, бизнес-логику, UI и review — это займёт 8+ часов последовательной работы.

2. **Конфликты в Git** — если запустить несколько AI одновременно в одной ветке, они будут конфликтовать друг с другом, перезаписывая файлы.

3. **Нужен надзор** — AI постоянно задают вопросы ("какую библиотеку использовать?", "как назвать функцию?"), требуя вашего участия каждые 5-10 минут.

4. **Теряется контекст** — когда вы переключаетесь между задачами, AI теряет контекст предыдущей работы.

### Решение

**Devframework** — это система оркестрации, которая позволяет:

✅ **Запускать несколько AI параллельно** — 4 задачи одновременно вместо последовательно (2.5 часа вместо 8)

✅ **Изолировать работу через Git worktrees** — каждый AI работает в своём изолированном пространстве без конфликтов

✅ **Работать автономно** — AI не задают вопросы, а принимают решения по заданным правилам

✅ **Автоматически делать review** — отдельный AI проверяет результаты других

✅ **Сохранять контекст** — вся работа логируется, документируется, передаётся между агентами

### Как это работает (простыми словами)

Представьте **строительную бригаду**:

1. **Прораб (Orchestrator)** — читает план работ и распределяет задачи по бригадам
2. **Бригады (AI Workers)** — каждая работает на своём участке (worktree), не мешая другим
3. **Мастер-приёмщик (Review Agent)** — проверяет качество работы после завершения
4. **Журнал работ (Logs)** — всё фиксируется: кто, что, когда сделал

**В коде это выглядит так:**

```
Ваш проект (main)
  ├─ worktree-1: AI #1 делает дизайн БД
  ├─ worktree-2: AI #2 пишет бизнес-логику
  ├─ worktree-3: AI #3 делает UI компоненты
  └─ worktree-4: AI #4 проверяет код (review)

После завершения:
  → Все изменения мержатся в main
  → Review результаты записываются в framework/review/
  → Логи сохраняются в framework/logs/
```

### Ключевые концепты

| Термин | Объяснение для новичков |
|--------|-------------------------|
| **Orchestrator** | "Диспетчер" — Python-скрипт, который читает конфиг с задачами и запускает AI-агентов параллельно |
| **Git Worktree** | "Изолированная копия" — отдельная рабочая директория с той же историей Git, позволяет работать в разных ветках одновременно |
| **Task** | "Задача" — .md файл с описанием того, что должен сделать AI (например, "Спроектировать схему БД") |
| **Runner** | "Исполнитель" — Cursor Agent на модели Grok (`cursor` для задач, `cursor-interactive` для интервью) |
| **Phase** | "Этап" — main (разработка), review (проверка), post (улучшение фреймворка), legacy (миграция старого проекта) |
| **Handoff** | "Передача контекста" — документ, в котором AI описывает что сделал и почему, для следующего AI |

### Кому это нужно

✅ **Разработчикам**, использующим AI-ассистентов и желающим ускорить разработку в 3-4 раза

✅ **Tech Lead'ам**, управляющим несколькими AI-агентами как командой

✅ **Командам**, мигрирующим legacy-проекты с помощью AI (безопасно, с анализом рисков)

✅ **DevOps/Platform Engineers**, автоматизирующим процессы разработки

### Что внутри репозитория

```
devframework/
├── framework/                    # Основной фреймворк
│   ├── orchestrator/             # Оркестратор (запускатор задач)
│   │   ├── orchestrator.py       # Главный скрипт
│   │   └── orchestrator.json     # Конфиг: какие задачи, какие AI
│   ├── tasks/                    # Шаблоны задач для AI
│   │   ├── db-schema.md          # "Спроектируй БД"
│   │   ├── business-logic.md     # "Реализуй логику"
│   │   └── ui.md                 # "Сделай UI"
│   ├── docs/                     # Выходные документы (handoff, спеки)
│   ├── review/                   # Результаты code review
│   ├── migration/                # Анализ и миграция legacy-кода
│   └── logs/                     # Логи выполнения
├── .cursor/rules/                # Правило Cursor: следовать AGENTS.md, оставаться на Grok
├── AGENTS.md                     # Протокол, который Cursor читает сам
├── install-fr.sh               # Установщик для новых проектов
└── README.md                     # Этот файл
```

Папка `claude-code/` — архив заметок upstream-версии (Codex / Claude Code). Рабочий агент этого форка — Cursor + Grok.

### Cursor + Grok

DevFramework запускает [Cursor Agent CLI](https://cursor.com/docs/cli/using) (`agent`) с моделью **Grok 4.7**.

- Интерактивное интервью: `./cursor`, затем «start».
- Параллельные задачи: `agent -p --force --trust --model grok-4.7` через `framework/tools/cursor-runner.sh`.
- Контекст проекта: `AGENTS.md` и `.cursor/rules/devframework.mdc` (Cursor подхватывает оба).
- Другая модель Grok: `FRAMEWORK_CURSOR_MODEL=grok-4.5` (или `grok-4.6`).

Установка CLI и вход:

```bash
curl https://cursor.com/install -fsS | bash
agent login
```

Для оркестратора без TTY достаточно `CURSOR_API_KEY`.

### Быстрый старт за 3 шага

**1. Клонируйте репозиторий:**
```bash
git clone https://github.com/MazZzDaI/devframework.git
cd devframework
```

**2. Инициализируйте проект:**
```bash
git init
git add .
git commit -m "init"
```

**3. Запустите установщик:**
```bash
./install-fr.sh
```

Orchestrator автоматически:
- Создаст worktrees для параллельных задач
- Запустит AI-агентов по заданиям из `framework/tasks/`
- Соберёт результаты и создаст review
 - После миграции (legacy) автоматически перейдёт к интервью (discovery)

### Агент

Поддерживаемый исполнитель — **Cursor Agent на Grok**. Оркестратор поднимает его в изолированных Git worktrees. Модель по умолчанию — `grok-4.7`; переопределение — `FRAMEWORK_CURSOR_MODEL`.

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
3) Discovery interview → ТЗ/план/тест‑план.
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
   - Затем discovery интервью в Cursor Agent (Grok).
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
