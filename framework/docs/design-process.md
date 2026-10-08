# Design instructions (Process)

This document describes the sequence of product design stages and of preparation for implementation by autonomous agents.

---

## Stage 0. Goals and success metrics
**Goal:** define what counts as MVP success.
- Product goals (user value).
- Metrics (conversion, time-to-report, retention, CAC).

**Output:**
- Success criteria recorded in `docs/tech-spec.md`.

---

## Stage 1. Initial idea description (Free-form Brief)
**Goal:** collect a general description of the product in free form.
- The user describes the idea in their own words.
- The agent does not clarify details; it only records the intent.

**Output:**
- Saved to `docs/qa.md` (as part of the log).

---

## Stage 2. Clarifying questions (Deep Discovery)
**Goal:** ask 100–200 clarifying questions (one at a time) in order to close every gap.
- The questions cover: business logic, UX, data, integrations, compliance, tests.
- Answers are recorded without interpretation.

**Output:**
- Q/A log in `docs/qa.md`.

---

## Stage 3. Forming the spec and specifications
**Goal:** convert the answers into a structured spec.
- These are created: `docs/tech-spec.md`, `docs/tech-addendum-1.md`.
- A list of input data and credentials is produced (`docs/inputs-required.md`).

**Output:**
- A complete set of specs and requirements.

**Checkpoint:**
- Ask the user the main question: **"Can we start development?"**
- If the answer is "yes", start the development phase.

---

## Stage 4. Risk / Feasibility Review
**Goal:** assess the risks and whether the data and dependencies are available.
- Data availability (FPL/SLCSP/ZIP).
- Compliance risks, LLM cost, legal risks.
- Plan B (synthetic data, stubs).

**Output:**
- A short list of risks and workaround plans.

---

## Stage 5. Architecture decisions (ADR)
**Goal:** record the key architecture decisions.
- Stack, storage, multi-tenant, encryption model.

**Output:**
- A list of ADRs, or a section in `docs/tech-spec.md`.

---

## Stage 6. Contracts and reference data
**Goal:** stabilize the formats and the verification sets.
- Data and API contracts.
- Golden datasets for tests.

**Output:**
- `docs/data-templates.md` + fixtures.

---

## Stage 7. Identifying tasks that can proceed without credentials
**Goal:** identify the tasks that can be implemented on stubs.
- UI/UX, business logic, PDF, tests, mock data, migrations.

**Output:**
- A list of tasks that start without external keys.

---

## Stage 8. Parallelism analysis
**Goal:** split the tasks into independent streams.
- Identify the dependencies and what can be launched in parallel.

**Output:**
- A map of parallel tasks and dependencies.

---

## Stage 9. Orchestration and agents
**Goal:** prepare the documentation for agents working in parallel.
- Create the **orchestrator**: `framework/docs/orchestrator-plan.md`.
- Create separate task files for each agent (mini-spec + data + prompt).

**Output:**
- A set of files for autonomous agent work.

---

## Stage 10. Test and acceptance plan
**Goal:** formalize the readiness criteria.
- Definition of Done for features and the release.
- Test plan (unit/integration/e2e).
- The test plan can be prepared in parallel with development.
 - After development, a handoff is prepared for independent review.

**Output:**
- An acceptance checklist.

---

## Stage 11. Security/Privacy Review
**Goal:** check security and privacy.
- Retention, export/deletion, encryption, disclaimers.

**Output:**
- Updates to the spec and policies.

---

## Stage 12. Observability & Telemetry
**Goal:** monitor quality and errors.
- Logs, metrics, alerts.

**Output:**
- A monitoring plan.

---

## Stage 13. Release & Rollback
**Goal:** a safe release.
- The release and rollback process.

**Output:**
- Release instructions.

---

## Stage 14. Post-Launch cycle
**Goal:** improvements after launch.
- Collecting feedback, A/B tests, improvements.

**Output:**
- An iteration plan.

---

## Logging
- Every stage is recorded in `docs/qa.md`.
- Sessions are logged in `docs/chat-log.md` plus a short summary in `docs/chat-summary.md`.

---

## Framework Review (post-run)
After the main run finishes, the framework's work is analyzed
from the logs and a bug report is produced. Fixes are applied only between runs.

---

## Legacy Migration (read-only)
A legacy project uses a separate safe track:
audit → reverse spec → gap/risk → migration plan → approval → apply on a separate branch.
