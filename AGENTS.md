# AGENTS.md — DevFramework (Cursor + Grok)
<!-- DEVFRAMEWORK:MANAGED -->

Cursor reads this file automatically in the editor and in the `agent` CLI.
The working agent is Cursor Agent. The default model is Grok `grok-4.7`.
Choose another Grok model with `FRAMEWORK_CURSOR_MODEL` (or `CURSOR_MODEL`).

## Launch
Start the agent with the project launcher. It selects Grok for you:

```
./cursor
```

Before the first run, install the CLI and sign in:

```
curl https://cursor.com/install -fsS | bash
agent login
```

Non-interactive orchestrator tasks can use `CURSOR_API_KEY` instead.

## Triggers
- "start" or "begin" — run the start protocol.

## Start protocol
1) If `framework/logs/discovery.pause` exists, resume the interview:
   - read `framework/docs/discovery/interview.md`,
   - close only the unanswered questions,
   - delete the pause marker after resuming.
2) Decide whether the project root contains legacy code:
   - treat the tree as legacy when it has files or folders other than: `framework/`, `framework.zip`,
     `install-fr.sh`, `install-fr-<version>.sh`, `.git/`, `.gitignore`, `AGENTS.md`,
     `AGENTS.override.md`, `.cursor/`, `cursor`, `.DS_Store`.
   - if legacy code is present, run analysis:
     `FRAMEWORK_AGENT_FLOW=1 FRAMEWORK_SKIP_DISCOVERY=1 python3 framework/tools/run-protocol.py`
3) Run the discovery interview:
   - read `framework/tasks/discovery.md` and follow it;
   - ask exactly one question at a time (no lists or batches of questions);
   - keep the log in `framework/docs/discovery/interview.md`;
   - append the transcript to `framework/logs/discovery.transcript.log` with timestamps.
4) After the interview, generate artifacts:
   - `python3 framework/tools/generate-artifacts.py --overwrite`
5) At the end, ask: **"May I start development?"**
   - if yes: `python3 framework/orchestrator/orchestrator.py --phase main`.

## Pause
If the user types `/pause`:
- save progress in `framework/docs/discovery/interview.md`,
- write `framework/logs/discovery.pause` (time and reason),
- end the session cleanly.

## Limits
- During discovery, do not change product source code. Write only under `framework/docs`, `framework/logs`, `framework/migration`, and `framework/review`.
- Do not switch models. The orchestrator and `./cursor` already pass `--model`.
- Use English for every user-facing document, question, and reply.
