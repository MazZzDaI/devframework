#!/usr/bin/env python3
import argparse
import re
from pathlib import Path


def parse_interview(path: Path) -> dict:
    answers = {}
    current_q = None
    current_a = []
    in_answer = False
    q_re = re.compile(r"^-\s*Q(\d+):")
    a_re = re.compile(r"^\s*-\s*A(\d+):")

    for raw in path.read_text(encoding="utf-8", errors="ignore").splitlines():
        line = raw.rstrip()
        if not line:
            if in_answer and current_q:
                current_a.append("")
            continue
        q_match = q_re.match(line)
        if q_match:
            if current_q and current_a:
                answers[current_q] = " ".join([s.strip() for s in current_a if s is not None]).strip()
            current_q = q_match.group(1)
            current_a = []
            in_answer = False
            continue
        a_match = a_re.match(line)
        if a_match:
            current_q = a_match.group(1)
            answer = line.split(":", 1)[1].strip() if ":" in line else ""
            current_a = [answer]
            in_answer = True
            continue
        if in_answer and current_q:
            current_a.append(line.strip())

    if current_q and current_a:
        answers[current_q] = " ".join([s.strip() for s in current_a if s is not None]).strip()
    return answers


def get_answer(answers: dict, qnum: str, fallback: str) -> str:
    return answers.get(qnum, fallback)


def missing_questions(answers: dict, required: list) -> list:
    return [q for q in required if q not in answers or not answers[q].strip()]


def write_file(path: Path, content: str, overwrite: bool) -> None:
    if path.exists() and not overwrite:
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content.strip() + "\n", encoding="utf-8")


def build_tech_spec(answers: dict) -> str:
    missing = missing_questions(
        answers,
        ["1", "2", "3", "5", "6", "8", "10", "12", "13", "14", "15", "16", "17", "19", "21"],
    )
    return f"""
# Generated Specification (self-host devframework)

## 1. Goal and success criteria
- {get_answer(answers, "1", "UNKNOWN: product goal")}
- {get_answer(answers, "8", "UNKNOWN: success criteria")}

## 2. User and experience
- Roles: {get_answer(answers, "2", "UNKNOWN: roles and personas")}
- Minimum contact after the interview: {get_answer(answers, "4", "UNKNOWN")}
- Key scenario: {get_answer(answers, "5", "UNKNOWN")}
- Final notification: {get_answer(answers, "6", "UNKNOWN")}

## 3. Scope
- Included: discovery, then specification, then plan, then orchestrator, then review and post-run.
- Host project types: {get_answer(answers, "9", "UNKNOWN")}
- Excluded: performance optimization on the MVP (see SLOs).

## 4. Architecture and process
- Orchestrator, one worktree per task, and phases main, post, and legacy.
- Parallel task map: `docs/orchestrator-plan.md`.
- Self-review and bug reports: {get_answer(answers, "21", "UNKNOWN")}
- Stop points: {get_answer(answers, "10", "UNKNOWN")}

## 5. Default stack
- {get_answer(answers, "14", "UNKNOWN: stack")}

## 6. Deploy and environments
- {get_answer(answers, "16", "UNKNOWN: deploy")}

## 7. Integrations
- {get_answer(answers, "17", "UNKNOWN: integrations")}

## 8. Secrets and access
- {get_answer(answers, "12", "UNKNOWN: secrets and credentials")}

## 9. Logging and reporting
- {get_answer(answers, "13", "UNKNOWN: logging")}

## 10. Non-functional requirements (MVP)
- {get_answer(answers, "15", "UNKNOWN: SLO and performance")}

## 11. Artifact format
- {get_answer(answers, "19", "UNKNOWN: artifact format")}

## 12. TODO / UNKNOWN
{"- Missing required answers: " + ", ".join([f"Q{q}" for q in missing]) if missing else "- None"}
""".strip()


def build_plan() -> str:
    return """
# Work Plan (self-host devframework)

## Stages
1) Finish discovery and produce the artifacts.
2) Run the orchestrator main phase (no-op or real).
3) Run the post-run framework review.
4) Fix issues from bug reports and run again.

## Parallelism
- Use the task map in `docs/orchestrator-plan.md`.
- UI comes after component choices. Real calculations come after the data is available.

## Risks
- Missing data or credentials becomes a stop point that asks for them.
- Worktree collisions are caught by preflight validation.

## Definition of Done
- The main-to-post run finishes without errors.
- Artifacts are generated and linked.
""".strip()


def build_data_inputs(answers: dict) -> str:
    return f"""
# Required Data and Secrets (self-host devframework)

## Data and templates
- Discovery answers: `docs/discovery/interview.md`.
- Data templates (when domain tables are needed): `docs/data-templates.md`.
- Additional: {get_answer(answers, "18", "UNKNOWN")}

## Secrets and access
- Policy: {get_answer(answers, "12", "UNKNOWN")}
- Integrations: {get_answer(answers, "17", "UNKNOWN")}

## Default secret list
- Supabase: `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_KEY`.
- Stripe: `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET` (if webhooks are used).
- SES (optional): `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION`, `SES_SENDER`.
- Vercel or Netlify: an access token and a project id.
""".strip()


def build_test_plan() -> str:
    return """
# Test Plan (self-host devframework)

## 1) Goals
- Check that DevFramework can run the interview, generate artifacts, and complete a main-to-post run without errors.
- Confirm that secrets do not leak into logs or reports.
- Check readiness for typical host repositories (empty and legacy).

## 2) Scope
- Orchestrator CLI and config (`orchestrator.py`, `orchestrator.json`).
- Discovery flow and generated files (`docs/discovery/interview.md` and the generated docs).
- Report export and publish tools (`tools/export-report.py`, `tools/publish-report.py`).
- Framework-review flow (post phase).

## 3) Test types
- Unit: config parsing, worktree path validation, lock handling, redaction, and YAML/JSON I/O.
- Integration: no-op main run, export-report on synthetic logs, and publish-report dry-run.
- End to end: install with `install-fr.sh` into an empty repo, run main-to-post in no-op mode, and run legacy analysis read-only.
- Manual and UX: generated artifacts are understandable to a non-technical user.

## 4) Critical scenarios
1) Install into an empty repo, then a main no-op run. Artifacts are generated and there are no errors.
2) Run the legacy phase in a repo with arbitrary files. Migration artifacts are created and product code does not change.
3) Export plus redaction. The report has no secrets and still includes the key logs.
4) Framework post-run review. `framework-review/*` is generated without crashes.

## 5) Negative cases
- Missing or occupied worktree paths produce a clear error and do not corrupt the repo.
- Missing git produces a clear message and a graceful exit.
- Missing PyYAML or other dependencies produces a message with instructions.
- An empty or corrupt orchestrator config produces a validation error.
- Missing credentials during a real deploy become a stop point, with no secret leakage.

## 6) Acceptance criteria
- Every critical scenario passes. There are no P0 or P1 issues.
- Logs contain no secrets. Export and publish do not reveal tokens.
- The main-to-post no-op run succeeds and is repeatable.

## 7) Data and fixtures
- Synthetic logs and run JSONL for export and redaction.
- An empty git repo for install, and a repo with extra files for the legacy check.
- Data template stubs (`plans_2026.csv` and the rest) when needed.
""".strip()


def build_overview(answers: dict) -> str:
    return f"""
# Overview (self-host devframework)

## Idea in one paragraph
{get_answer(answers, "1", "UNKNOWN: product goal")}

## Success criteria
{get_answer(answers, "8", "UNKNOWN: success criteria")}

## User role
{get_answer(answers, "2", "UNKNOWN: roles and personas")}

## Stack and deploy
- Stack: {get_answer(answers, "14", "UNKNOWN")}
- Deploy: {get_answer(answers, "16", "UNKNOWN")}

## Contents (key artifacts)
1) Specification: `docs/tech-spec-generated.md`
2) Work plan: `docs/plan-generated.md`
3) Inputs and secrets: `docs/data-inputs-generated.md`
4) Test plan: `review/test-plan.md`
5) Improvement backlog: `docs/backlog.md`
6) Bug report template: `docs/reporting/bug-report-template.md`
7) Orchestration map: `docs/orchestrator-plan.md`
8) Required inputs: `docs/inputs-required.md`
""".strip()


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate framework artifacts from discovery interview.")
    parser.add_argument("--interview", default="framework/docs/discovery/interview.md")
    parser.add_argument("--docs-dir", default="framework/docs")
    parser.add_argument("--review-dir", default="framework/review")
    parser.add_argument("--overwrite", action="store_true")
    args = parser.parse_args()

    interview_path = Path(args.interview)
    docs_dir = Path(args.docs_dir)
    review_dir = Path(args.review_dir)

    answers = parse_interview(interview_path)

    write_file(docs_dir / "tech-spec-generated.md", build_tech_spec(answers), overwrite=args.overwrite)
    write_file(docs_dir / "plan-generated.md", build_plan(), overwrite=args.overwrite)
    write_file(docs_dir / "data-inputs-generated.md", build_data_inputs(answers), overwrite=args.overwrite)
    write_file(docs_dir / "overview.md", build_overview(answers), overwrite=args.overwrite)
    write_file(review_dir / "test-plan.md", build_test_plan(), overwrite=args.overwrite)


if __name__ == "__main__":
    main()
