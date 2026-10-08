# Orchestrator: shared contracts + parallel task map + mini-specs

A document for launching parallel subtasks with different agents.

---

## 1) Shared contracts (the same for every task)

### 1.1 Global rules
- Do not overwrite anything: versions only (`version`, `is_current`).
- Store `project_id` everywhere (multi-tenant Supabase).
- Medical and legal advice is forbidden.
- Anonymize data before it reaches an LLM.
- Store data collected before authorization as anonymous sessions.

### 1.2 Data schemas (input files)
See **`docs/data-templates.md`**:
- `plans_2026.csv`
- `zip_rating_map_2026.csv`
- `fpl_2026.csv`
- `slcsp_2026.csv`

### 1.3 Database contracts (minimum set)
- `plans`
- `rating_area_map`
- `questionnaires` (versioned)
- `reports` (versioned)
- `chat_sessions`, `chat_messages` (versioned)
- `users` (link to Supabase auth)
- `subscriptions`, `token_balance`
- All tables contain `project_id`.

### 1.4 API / behavior (minimum)
- Wizard → questionnaire data → calculation → results.
- Results → Report → PDF.
- What-If → real-time calculation.

### 1.5 Logging
- Store LLM and prompt logs (anonymized).
- Store dialogue sessions in full.

---

## 2) Task map and parallelism

### Can be done in parallel (no mutual blocking)
1) **Data Research** (tables A–D per the template)
2) **DB schema + migrations + RLS**
3) **Business Logic** (APTC, scenarios, scoring)
4) **UI/UX** (select Tailwind UI components + mockups)
5) **PDF generation** (on synthetic data)
6) **LLM prompts/policies**
7) **Unit + E2E tests (mock data)**
8) **DevOps (Vercel env, deploy pipelines)**
9) **Test Plan (independent)** (based on the spec and DoD)
10) **Review Handoff Prep** (package for independent review)
11) **Framework Review (post-run)** (analysis of how the framework ran)
12) **Legacy Migration (read-only)** (audit, reverse-spec, gap, plan)

### Dependencies
- UI depends on the choice of Tailwind UI components (per the protocol).
- Real subsidy calculations are more accurate after the real tables (A–D).
- Integrations (Supabase/Auth, Stripe/PayPal, SES) come after the basic skeleton.
- Independent Review runs after the key dev tasks + Test Plan.
- Framework Review runs only between runs (post-run).

---

## 3) Mini-specs and prompts by task

### 3.1 Data Research (A–D)
**Goal:** collect the official tables for 2026.
- Use `docs/deep-research-prompt.md`.
- Output: 4 CSVs + `sources.md` + `issues.md` + `summary.md`.

### 3.2 DB Schema + RLS
**Goal:** Supabase migrations for every entity, plus RLS.
- Account for `project_id`.
- Apply AES-256 encryption in the application before writing.

### 3.3 Business Logic
**Goal:** implement subsidy and scenario calculations.
- APTC formulas (FPL 2026, expected contribution up to 8.5%).
- 4 scenarios + cap `(premium*12 + MOOP)`.
- Return-subsidy scenarios (+50/100/200/300/500%).

### 3.4 UI/UX (Tailwind UI)
**Goal:** pick components from the screen list.
- Use `docs/screens-list.md`.
- First choose templates in `Claude-Cowork/TAILWIND_UI_CATALOG.md`.

### 3.5 PDF generation
**Goal:** a PDF report on the paid plan.
- Include every section (tables, scenarios, sources, disclaimers).

### 3.6 LLM Prompts/Policies
**Goal:** prompts for the chat and the final analysis.
- Follow the restrictions (no medical/legal advice).
- Store reasoning and the explanation separately.

### 3.7 Tests
**Goal:** automation (unit + Playwright).
- Unit: APTC, scenarios, scoring.
- E2E: Anonymous → Wizard → Payment (mock) → PDF.

### 3.8 DevOps
**Goal:** a deploy pipeline on Vercel.
- main → prod, develop → staging, feature → preview.
- ENV per environment.

### 3.9 Test Plan (Independent)
**Goal:** write an independent test plan.
- Basis: the spec + DoD.
- Output: `framework/review/test-plan.md`.
- No code changes.

### 3.10 Review Handoff Prep
**Goal:** prepare the package for independent review.
- Input: commit/branch, test results (if any).
- Output: `framework/review/handoff.md`, `framework/review/bundle.md`, `framework/review/test-results.md` (optional).
- No code changes.

### 3.11 Independent Review
**Goal:** independent code review and QA.
- Input: `framework/review/test-plan.md`, `framework/review/review-brief.md`.
- Output: `framework/review/code-review-report.md`, `framework/review/bug-report.md`, `framework/review/qa-coverage.md`.
- No code changes.

### 3.12 Framework Review (post-run)
**Goal:** analyze how the orchestrator ran and the framework's errors.
- Input: `framework/logs/framework-run.jsonl`, `framework/docs/orchestrator-run-summary.md`.
- Output: `framework/framework-review/framework-log-analysis.md`, `framework/framework-review/framework-bug-report.md`.
- Run only between runs (no `framework/logs/framework-run.lock`).
- Launch: `python3 framework/orchestrator/orchestrator.py --phase post`.

### 3.13 Framework Fix (post-run, manual)
**Goal:** fix framework errors based on the Framework Review.
- Input: `framework/framework-review/framework-bug-report.md`, `framework/framework-review/framework-fix-plan.md`.
- Output: fixes in the framework code.
- Run only between runs.

### 3.14 Legacy Migration (read-only)
**Goal:** analyze the legacy project and prepare a safe migration plan.
- Input: the repository (read-only), `framework/docs/orchestrator-plan.md`.
- Output: `framework/migration/legacy-snapshot.md`, `framework/migration/legacy-tech-spec.md`,
  `framework/migration/legacy-gap-report.md`, `framework/migration/legacy-risk-assessment.md`,
  `framework/migration/legacy-migration-plan.md`, `framework/migration/legacy-migration-proposal.md`,
  `framework/migration/rollback-plan.md`.
- Launch: `python3 framework/orchestrator/orchestrator.py --phase legacy`.
- Next (a required user-flow step): an interactive discovery interview (supports `/pause` to pause and resume later).
- Changes are applied only after approval, and on a separate branch.

### 3.15 Legacy Apply (manual)
**Goal:** apply the changes on a separate branch after approval.
- Input: `framework/migration/approval.md`, `framework/migration/legacy-migration-plan.md`.
- Output: changes on the `legacy-migration` branch.
- Launch: `python3 framework/orchestrator/orchestrator.py --phase legacy --include-manual`.

---

## 4) Shared inputs (credentials / data)
See `docs/inputs-required.md`.

---

## 5) References
- `docs/tech-spec.md`
- `docs/tech-addendum-1.md`
- `docs/qa.md`
