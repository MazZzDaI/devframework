# Claude Code: Autonomous Mode for devframework

> Archive of the upstream version. This fork runs **Cursor Agent on Grok**, not Claude Code and not Codex. The working protocol is `AGENTS.md`, the rule is `.cursor/rules/devframework.mdc`, and the runner is `framework/tools/cursor-runner.sh`. The text below is kept as historical notes.

## Problem

**Claude Code** was built as an "Interaction First" tool — a partner in the flow (Pair Programming). Its philosophy is to keep clarifying, asking, and stopping when in doubt.

**Devframework** requires a "Delegation First" approach — autonomous task execution for hours without interruptions.

**Conflict**: When launched through orchestrator.py, Claude Code still behaves interactively:
- Asks questions through AskUserQuestion
- Stops on ambiguity
- Waits for confirmations
- Cannot work autonomously for hours

## Claude Code's Strengths

Do not lose these when moving to autonomy:

✅ **Deep understanding of context** — reads the architecture of the whole repository
✅ **Imitates code style** — writes in the style of the existing project
✅ **Architectural precision** — does not invent hacks or reinvent the wheel
✅ **Creative approach** — proposes elegant solutions
✅ **Safety** — does not rush; checks before acting

## Goal of the Improvements

**Turn Claude Code into a hybrid tool:**

1. **Autonomous Mode** — when the spec is detailed and clear
2. **Interactive Mode** — when collaborative design is needed
3. **Smooth switching** between modes

## Proposed Solutions (5 levels)

### Level 1: Metaprompts in task definitions
Modify existing framework/tasks/*.md without changing orchestrator code.

### Level 2: Extending orchestrator.py + improved templates
Add an `execution_mode` parameter to the task configuration.

### Level 3: Hybrid pipeline (Claude + Codex)
Combination of Claude Code (planning) + Codex (implementation) + Claude Code (review).

### Level 4: GPT-5.2 Pro Formal Spec (architect + executor)
GPT-5.2 Pro creates a detailed specification → Claude Code implements it autonomously.

### Level 5: AI Team Architecture 🚀 (revolutionary approach)
GPT-5.2 Pro (Team Lead) + Multiple Claude (Developers) with real-time communication through a Bridge.
**3-4× speedup through parallelism!**

## Documentation Structure

```
claude-code/                                   280KB total
├── README.md                                  # This file — overview
├── COMPARISON.md                              # ⭐ START HERE — comparison of Levels 1-5
├── QUICK-START.md                             # Quick start (3 complexity levels)
├── SUMMARY.md                                 # Detailed contents of all documents
│
├── 01-autonomous-mode-protocol.md             # Level 1 — Autonomous mode protocol
├── 02-task-template-improvements.md           # Level 2 — Task template improvements
├── 03-orchestrator-modifications.md           # Changes to orchestrator.py
├── 04-hybrid-pipeline-design.md               # Level 3 — Hybrid pipeline (Claude+Codex)
├── 05-watchdog-escalation.md                  # Monitoring and escalation
├── 06-gpt52-pro-claude-pipeline.md            # Level 4 — GPT-5.2 as architect
├── 07-ai-team-architecture.md                 # Level 5 — AI Team 🚀 (revolution!)
│
└── examples/                                  # Usage examples
    ├── task-autonomous-example.md             # Complete task example
    ├── orchestrator-config-example.json       # Configuration example
    └── hybrid-workflow-example.md             # Real workflow scenario
```

## Principles

1. **Backward compatibility** — all changes are optional; old configs still work
2. **Minimal invasiveness** — do not break existing code
3. **Gradual adoption** — can be applied in parts
4. **Documenting decisions** — autonomous mode logs every choice
5. **Fallback strategy** — if you get stuck, there is a plan B

## Next Steps

**Quick start (5 minutes):**
1. Open **`COMPARISON.md`** ⭐ — visually compare all 5 levels
2. Choose your level (1-5) based on budget and requirements
3. Go to the matching document

**Full understanding (2-3 hours):**
1. Read `COMPARISON.md` — understand the difference between levels
2. Read `SUMMARY.md` — a detailed overview of every document
3. Study the chosen level in detail (01-07)
4. Study `examples/` for a practical understanding

**For adoption:**
1. Level 1-2: Simply add metaprompts to tasks (1 hour)
2. Level 3: Set up a hybrid workflow (1 day)
3. Level 4: Get ChatGPT Pro and set up the GPT-5.2 pipeline (3-5 days)
4. Level 5: Build an AI Team with a Bridge (1-2 weeks, but 3× ROI!)

## Philosophy

> Claude Code can work autonomously if you give it **detailed context** and **explicit decision rules**. We are not changing its nature — we are giving it a framework for confidence.

---

**Status**: Proposals, not implemented in the main project
**Author**: Claude Sonnet 4.5
**Date**: 2026-01-26
