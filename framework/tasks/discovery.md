# Task: Discovery and Full Spec Synthesis

## Goal
Run one deep interview (100+ questions) in plain language for a **non-technical domain expert**, then generate a full specification, work plan, and test plan with no further clarification.

## Inputs
- The user's answers during the interview (collected in this session).
- Any files or links the user provides.
- Persona description: see `framework/docs/user-persona.md`.

## Outputs
- framework/docs/discovery/interview.md — question and answer log.
- framework/logs/discovery.transcript.log — full raw dialogue transcript (as shown in the terminal).
- framework/docs/tech-spec-generated.md — structured specification.
- framework/docs/overview.md — overview with a table of contents and links.
- framework/docs/plan-generated.md — task and iteration plan with dependencies.
- framework/docs/data-inputs-generated.md — required data, templates, and fixtures.
- framework/review/test-plan.md — completed test plan (unit, end-to-end, acceptance, performance, security).
- (legacy mode) update framework/migration/legacy-snapshot.md and legacy-tech-spec.md with facts from the interview.

## Approach
0) This is interactive. Talk to the user directly in the terminal.
   - Ask exactly **one** question at a time. Do not send a list of questions.
     If a topic needs follow-ups, ask them one by one and wait for each answer.
   - If the user types `/pause`, immediately:
     1) save the current progress in `framework/docs/discovery/interview.md`,
     2) confirm the pause in one short line,
     3) end the session (do not ask anything else).
   - Keep a raw transcript: append every turn (question and answer) to
     `framework/logs/discovery.transcript.log` with timestamps.
   - If `framework/docs/discovery/interview.md` already exists, resume where it stopped:
     do not repeat answered questions; close only the open sections.
1) Use everyday language. Do not say git, CI, branch, runner, or env. Restate the answer ("Did I understand correctly that ...?") and show progress by section.
2) Close topics in this order: goals and roles, user flows, domain rules, data and schemas, integrations, security and compliance, performance and SLOs, deploy and operations, observability, migration and disaster recovery, tests and quality, constraints and risks.
3) Keep the back-and-forth short. If a fact is missing, propose an option and mark it TODO or ASSUMPTION.
4) After the interview, generate every output file yourself. The test plan must include positive, negative, end-to-end, smoke, security, performance, and regression cases.
   - Command: `python3 framework/tools/generate-artifacts.py --overwrite`
5) Keep the results compact and free of jargon. Mark gaps as UNKNOWN or ASSUMPTION.
6) Finish by asking: **"May I start development?"**
   - If yes, say the next step is `python3 framework/orchestrator/orchestrator.py --phase main`.
   - If no, record the reasons and the missing data in `framework/docs/discovery/interview.md`.

## Done When
- Every output file exists and is filled in.
- Remaining questions are listed under TODO/UNKNOWN in each document.

## Minimum bar for "enough questions"
- Product goal (Q1), roles (Q2), expected outcome (Q3), key scenario (Q5).
- Final notification format (Q6) and success criteria (Q8).
- Stop-point rules (Q10) and secret handling (Q12).
- Logging and reporting (Q13) and the default stack (Q14).
- Deploy (Q16) and integrations (Q17).
- Artifact format (Q19) and self-review / bug reports (Q21).
If an item was not answered, mark it UNKNOWN and propose an assumption.

## Rules
- Do not change product source code. Write only under docs, review, and migration.
- If the runner or environment is unavailable, describe the steps and record UNKNOWN instead of inventing results.
- Ask questions and write every artifact in English.
