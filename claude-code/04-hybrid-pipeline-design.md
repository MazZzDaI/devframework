# Hybrid Pipeline: Claude Code + Codex

> **NOTE**: The configuration examples and file paths in this document are illustrative. Real paths may differ depending on your project structure. See `framework/tasks/` for the current task definitions.

## Philosophical basis

**Key insight**: Claude Code and Codex are not competitors. They are **complementary tools**.

Instead of choosing "either-or", you can use "both" inside one workflow.

## Strengths of each agent

### Claude Code
✅ **Deep analysis** — understands the project architecture
✅ **Follows patterns** — imitates the code style
✅ **Safety** — conservative, does not rush
✅ **Planning** — strong in the design phase
✅ **Code review** — a critical eye on quality

❌ **Slow** — likes to clarify and double-check
❌ **Gets stuck** — stops when something is ambiguous
❌ **Not autonomous** — tends to ask questions

### Codex (OpenAI)
✅ **Fast** — pushes a task through to the end
✅ **Autonomous** — hours of work without questions
✅ **Parallelism** — can do 10 tasks at once
✅ **Pragmatic** — does not fuss over "perfect" code

❌ **Less architecturally precise** — may miss existing patterns
❌ **Pragmatic to a fault** — the code works, but it is not elegant
❌ **May skip details** — in the rush for speed

## The hybrid pipeline idea

**Use each agent for what it is good at:**

```
Phase 1: Architecture & Planning
  → Claude Code (Interactive)
  → Detailed architectural plan
  → Every decision documented

Phase 2: Implementation
  → Codex (Autonomous)
  → Implementation from the plan
  → Fast, with no questions

Phase 3: Review & Polish
  → Claude Code (Interactive)
  → Quality check
  → Match the project style
```

## Pipeline design

### Option 1: Sequential

```
┌─────────────────────┐
│  1. PLAN PHASE      │
│  Agent: Claude Code │
│  Mode: Interactive  │
│                     │
│  Output:            │
│  - architecture.md  │
│  - decisions.md     │
│  - task-spec.md     │
└──────────┬──────────┘
           │
           ↓
┌─────────────────────┐
│  2. BUILD PHASE     │
│  Agent: Codex       │
│  Mode: Autonomous   │
│                     │
│  Input:             │
│  - task-spec.md     │
│                     │
│  Output:            │
│  - Implementation   │
└──────────┬──────────┘
           │
           ↓
┌─────────────────────┐
│  3. REVIEW PHASE    │
│  Agent: Claude Code │
│  Mode: Interactive  │
│                     │
│  Output:            │
│  - code-review.md   │
│  - improvements.md  │
└─────────────────────┘
```

#### Orchestrator config

```json
{
  "workflows": {
    "feature-development": {
      "phases": [
        {
          "name": "plan",
          "agent": "claude-code",
          "mode": "interactive",
          "tasks": [
            {
              "id": "architecture-design",
              "file": "framework/tasks/db-schema.md",
              "outputs": [
                "framework/docs/architecture.md",
                "framework/docs/decisions.md"
              ]
            }
          ]
        },
        {
          "name": "build",
          "agent": "codex",
          "mode": "autonomous",
          "depends_on": ["plan"],
          "tasks": [
            {
              "id": "implement-feature",
              "file": "framework/tasks/business-logic.md",
              "inputs": [
                "framework/docs/architecture.md"
              ],
              "time_budget": 120
            }
          ]
        },
        {
          "name": "review",
          "agent": "claude-code",
          "mode": "interactive",
          "depends_on": ["build"],
          "tasks": [
            {
              "id": "code-review",
              "file": "framework/tasks/review.md",
              "inputs": [
                "git diff main...feature-branch"
              ]
            }
          ]
        }
      ]
    }
  }
}
```

#### Advantages of Sequential

✅ Clear separation of responsibility
✅ Each agent does what it does best
✅ Easy to debug (each phase is isolated)
✅ You can skip phases (for example, skip review for simple tasks)

#### Drawbacks of Sequential

❌ Slower (sequential execution)
❌ No feedback between phases (Codex cannot ask Claude)
❌ Rigid structure (hard to adapt on the fly)

---

### Option 2: Fallback (escalation when stuck)

```
┌─────────────────────┐
│  Start: Claude Code │
│  Mode: Autonomous   │
│  (with protocol)    │
└──────────┬──────────┘
           │
           ↓
      [Watchdog]
           │
      ┌────┴────┐
      │ Progress? │
      └────┬────┘
           │
     ┌─────┴─────┐
     │           │
    Yes         No (5+ min stuck)
     │           │
     ↓           ↓
  Continue   ┌──────────────┐
              │  Escalate to │
              │     Codex    │
              └──────┬───────┘
                     │
                     ↓
              ┌──────────────┐
              │ Codex takes   │
              │ over and      │
              │ completes     │
              └──────────────┘
```

#### Orchestrator config

```json
{
  "tasks": [
    {
      "id": "complex-feature",
      "execution_mode": "autonomous",
      "runner_strategy": "fallback",
      "runners": [
        {
          "type": "claude-code",
          "priority": 1,
          "timeout": 45,
          "autonomous_protocol": true,
          "fallback_triggers": [
            "no_progress_5min",
            "ask_user_question_detected"
          ]
        },
        {
          "type": "codex",
          "priority": 2,
          "context_handoff": {
            "include": [
              "framework/docs/handoff.md",
              "git log --oneline -10",
              "git diff"
            ]
          }
        }
      ]
    }
  ]
}
```

#### Context handoff on escalation

```python
class ContextHandoff:
    """Prepare context when escalating from Claude to Codex"""

    def prepare(self, from_agent, to_agent, task):
        """Build context package for new agent"""
        context = {
            "task_id": task["id"],
            "original_agent": from_agent,
            "reason_for_handoff": self._get_handoff_reason(task),
            "work_completed": self._get_completed_work(task),
            "current_blocker": self._get_blocker(task),
            "decisions_made": self._parse_handoff_docs(task),
            "code_changes": self._get_git_diff(task),
            "remaining_work": self._estimate_remaining(task)
        }

        # Write context to file for new agent
        context_file = f"/tmp/handoff_{task['id']}.md"
        self._write_handoff_markdown(context_file, context)

        return context_file

    def _get_handoff_reason(self, task):
        """Determine why handoff happened"""
        log = parse_task_log(task)

        if "AskUserQuestion" in log:
            return "Claude asked questions in autonomous mode"
        elif no_progress_detected(task):
            return "No progress for 5+ minutes"
        elif task_timeout(task):
            return "Task exceeded time budget"
        else:
            return "Unknown"

    def _write_handoff_markdown(self, path, context):
        """Format context as markdown for Codex"""
        content = f"""
# Task Handoff: {context['task_id']}

## Context
This task was started by {context['original_agent']} but is being handed off to you.

**Reason for handoff**: {context['reason_for_handoff']}

## Work Completed So Far
{context['work_completed']}

## Current Blocker
{context['current_blocker']}

## Decisions Already Made
{context['decisions_made']}

## Code Changes Made
```diff
{context['code_changes']}
```

## What Remains To Be Done
{context['remaining_work']}

## Instructions
- Continue from where {context['original_agent']} left off
- Respect decisions already documented
- Don't redo completed work
- Focus on unblocking and completing
"""
        Path(path).write_text(content)
```

#### Advantages of Fallback

✅ Best of both worlds — try with Claude, finish with Codex
✅ Automatic unblocking of stuck tasks
✅ Time optimization (do not wait until Claude asks)
✅ Context is preserved (Codex sees what Claude did)

#### Drawbacks of Fallback

❌ Harder to debug (switching between agents)
❌ Risk of losing context during the handoff
❌ Extra overhead for monitoring

---

### Option 3: Parallel (parallel work with consensus)

```
                 ┌──────────────┐
                 │  Task Split  │
                 └──────┬───────┘
                        │
          ┌─────────────┴─────────────┐
          │                           │
          ↓                           ↓
   ┌──────────────┐          ┌──────────────┐
   │ Claude Code  │          │    Codex     │
   │ Subtask A    │          │  Subtask B   │
   └──────┬───────┘          └──────┬───────┘
          │                           │
          └─────────────┬─────────────┘
                        ↓
                 ┌──────────────┐
                 │   Merge &    │
                 │   Review     │
                 └──────────────┘
```

**Concept**: Split the task into parallel subtasks and give Claude and Codex different parts.

#### Split example

**Task**: "Implement user authentication"

**Subtasks**:
- **A (Claude Code)**: Database schema + RLS policies (needs architectural precision)
- **B (Codex)**: API endpoints implementation (more mechanical work)
- **C (Claude Code)**: Frontend integration + UX (needs an understanding of patterns)

#### Orchestrator config

```json
{
  "tasks": [
    {
      "id": "user-authentication",
      "execution_mode": "parallel",
      "merge_strategy": "manual_review",
      "subtasks": [
        {
          "id": "auth-db-schema",
          "runner": "claude-code",
          "mode": "autonomous",
          "branch": "auth-db",
          "depends_on": []
        },
        {
          "id": "auth-api",
          "runner": "codex",
          "mode": "autonomous",
          "branch": "auth-api",
          "depends_on": ["auth-db-schema"]
        },
        {
          "id": "auth-frontend",
          "runner": "claude-code",
          "mode": "autonomous",
          "branch": "auth-frontend",
          "depends_on": ["auth-api"]
        }
      ],
      "merge": {
        "strategy": "review_then_merge",
        "reviewer": "claude-code",
        "conflict_resolution": "manual"
      }
    }
  ]
}
```

#### Advantages of Parallel

✅ Maximum speed (parallel work)
✅ Optimal use of each agent's strengths
✅ Scalability (you can add more agents)

#### Drawbacks of Parallel

❌ Coordination complexity (dependencies between subtasks)
❌ Risk of conflicts on merge
❌ Requires a smart split into independent parts

---

### Option 4: Collaborative (working together)

```
┌─────────────────────────────────────┐
│         Main Task Loop              │
│                                     │
│  ┌──────────┐      ┌──────────┐   │
│  │  Claude  │ ←───→ │  Codex   │   │
│  │   Code   │      │          │   │
│  └──────────┘      └──────────┘   │
│       ↓                  ↓          │
│  [Makes plan]      [Implements]    │
│       ↓                  ↓          │
│  [Reviews code]    [Fixes issues]  │
│       ↓                  ↓          │
│  [Approves] ────────────→ [Done]   │
└─────────────────────────────────────┘
```

**Concept**: The agents work together, like a team. Claude plans and reviews, Codex implements.

#### Workflow

1. **Claude** creates a detailed plan
2. **Codex** implements from the plan
3. **Claude** reviews and finds problems
4. **Codex** fixes them
5. **Claude** approves → Done

#### Orchestrator config

```json
{
  "tasks": [
    {
      "id": "complex-feature",
      "execution_mode": "collaborative",
      "workflow": {
        "steps": [
          {
            "name": "plan",
            "agent": "claude-code",
            "action": "create_plan",
            "output": "framework/docs/plan.md"
          },
          {
            "name": "implement",
            "agent": "codex",
            "action": "implement",
            "input": "framework/docs/plan.md",
            "max_iterations": 3
          },
          {
            "name": "review",
            "agent": "claude-code",
            "action": "code_review",
            "output": "framework/review/issues.md"
          },
          {
            "name": "fix",
            "agent": "codex",
            "action": "fix_issues",
            "input": "framework/review/issues.md",
            "condition": "if issues.md not empty"
          },
          {
            "name": "approve",
            "agent": "claude-code",
            "action": "final_approval"
          }
        ],
        "max_cycles": 3
      }
    }
  ]
}
```

#### Advantages of Collaborative

✅ Quality + speed (each does its own part)
✅ Iterative improvement (review-fix cycle)
✅ Natural split of roles (architect vs executor)

#### Drawbacks of Collaborative

❌ Complex orchestration (many steps)
❌ Slower than simple sequential (several iterations)
❌ Requires good integration between agents

---

## Recommendations for choosing an option

### Sequential — when:
- The task has clear phases (design → build → review)
- Execution time is not critical
- Process traceability matters

### Fallback — when:
- You want to try Claude, but you need a guarantee of completion
- The task may be ambiguous
- Autonomy matters

### Parallel — when:
- The task splits easily into independent subtasks
- Time is critical (you need maximum speed)
- You have a clear idea of what to give to whom

### Collaborative — when:
- A complex task with high quality requirements
- You are willing to spend more time for a better result
- The agents are well integrated

---

## Implementation in devframework

### Minimal option (quick start)

Add a new `workflow_type` field to `orchestrator.json`:

```json
{
  "tasks": [
    {
      "id": "feature-x",
      "workflow_type": "sequential",
      "phases": ["plan", "build", "review"]
    }
  ],
  "workflows": {
    "sequential": {
      "plan": {"agent": "claude-code", "mode": "interactive"},
      "build": {"agent": "codex", "mode": "autonomous"},
      "review": {"agent": "claude-code", "mode": "interactive"}
    }
  }
}
```

### Full version (production)

Create `framework/orchestrator/workflows.py`:

```python
class WorkflowEngine:
    def __init__(self, orchestrator):
        self.orchestrator = orchestrator
        self.workflows = {
            "sequential": SequentialWorkflow,
            "fallback": FallbackWorkflow,
            "parallel": ParallelWorkflow,
            "collaborative": CollaborativeWorkflow
        }

    def execute(self, task):
        workflow_type = task.get("workflow_type", "sequential")
        workflow_class = self.workflows[workflow_type]
        workflow = workflow_class(self.orchestrator, task)
        return workflow.run()
```

---

## Effectiveness metrics for the hybrid approach

Compare against a baseline (Claude only or Codex only):

| Metric | Claude only | Codex only | Hybrid Sequential | Hybrid Fallback |
|--------|-------------|------------|-------------------|-----------------|
| Execution time | 100% | 50% | 75% | 60% |
| Code quality | 95% | 75% | 90% | 85% |
| Autonomy | 40% | 95% | 70% | 90% |
| Following patterns | 95% | 70% | 90% | 80% |

*(hypothetical values for illustration)*

---

**Status**: Conceptual design, ready to prototype
**Next step**: Pick one option for an MVP
**Recommendation**: Start with Sequential (simplest) or Fallback (more useful)
