# Backlog (self-host devframework)

Based on `docs/tech-spec-generated.md`, `docs/plan-generated.md`, and the interview.

## P0 / MVP (required for the first stable cycle)
1) BKL-001 — Separate summaries by phase (main/post/legacy) — DONE
   - Goal: do not overwrite `orchestrator-run-summary.md`.
   - Criteria: the summary is saved to `framework/docs/orchestrator-run-summary-<phase>-<run_id>.md`
     and a link to the latest run is written to `orchestrator-run-summary.md`.
2) BKL-002 — Auto-generation of artifacts from the interview — DONE
   - Artifacts: `tech-spec-generated.md`, `plan-generated.md`,
     `data-inputs-generated.md`, `review/test-plan.md`.
   - Criteria: a single task run generates the full set with no manual editing;
     UNKNOWN/TODO items are recorded explicitly.
3) BKL-003 — "Enough questions" criterion in discovery — DONE
   - Criteria: a fixed list of required sections plus a completeness threshold; once
     reached, a final confirmation and a move to generation.
4) BKL-004 — Standardized collection of bug reports from host projects — DONE
   - Criteria: a single issue/PR template plus automatic publishing through `publish-report.py`
     with `host_id`, `run_id`, the phase, and the list of artifacts.
5) BKL-005 — Stronger secret redaction in logs and reports — DONE
   - Criteria: `export-report.py` removes or masks keys and tokens from env and logs,
     and the report contains no plaintext secrets when tested with fixtures.

## P1 / Next iteration
6) BKL-006 — Orchestrator configuration validation — DONE
   - Criteria: clear errors for a worktree conflict, empty fields, and a missing prompt.
7) BKL-007 — Updated `.env` template and `inputs-required.md` — DONE
   - Criteria: a list of secrets for Supabase/Stripe/SES/Vercel|Netlify,
     and clear steps for requesting credentials.
8) BKL-008 — Orchestrator tests (unit/integration) — DONE
   - Criteria: at least 5 unit tests for config/lock/redact plus 1 integration no-op.
9) BKL-011 — Exclude internal folders from the legacy audit
   - Criteria: `framework/`, `framework.backup.*`, `_worktrees/`, and `.git` are not read during the legacy audit.

## P2 / Optional
10) BKL-009 — Better artifact UX (master doc + table of contents + links) — DONE
    - Criteria: a single overview document with a table of contents and links to the details.
11) BKL-010 — Analytics and observability integrations (optional)
    - Criteria: optional modules that do not block the MVP.
