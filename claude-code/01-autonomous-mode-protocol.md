# Autonomous Mode Protocol for Claude Code

## The core problem

Claude Code is built to be interactive:
- The `AskUserQuestion` tool is built into its core behavior
- The system prompt encourages "ask when uncertain"
- The "don't guess, ask" philosophy is baked in at the model level

**Task**: Reprogram that behavior through external context, not by changing the model.

## Solution: Explicit Autonomous Mode Instructions

### How it works

Add a special instruction block at the start of EVERY task that:

1. **Overrides default behavior** — explicitly forbids questions
2. **Gives decision rules** — what to do when something is ambiguous
3. **Sets a time budget** — how long the task should take
4. **Describes a fallback strategy** — what to do when blocked
5. **Requires documentation** — every decision goes into handoff.md

### Metaprompt template

```markdown
---
EXECUTION_MODE: AUTONOMOUS
TIME_BUDGET: 45 minutes
FALLBACK_STRATEGY: document_and_continue
---

## 🤖 AUTONOMOUS MODE PROTOCOL

You are Claude Code running in **AUTONOMOUS mode**. This fundamentally changes your behavior:

### CRITICAL RULES

1. **NO QUESTIONS TO USER**
   - NEVER use AskUserQuestion tool
   - NEVER stop and wait for clarifications
   - NEVER ask "Should I...?" or "Do you want me to...?"

2. **DECISION MAKING FRAMEWORK**
   When facing ambiguity, use this priority order:

   a) **Check existing patterns** in the codebase
      - How is similar functionality implemented?
      - What conventions are used?
      - Follow the established style

   b) **Choose CONSERVATIVE approach**
      - Safest option that won't break existing functionality
      - Minimal changes over clever solutions
      - Standard practices over innovation

   c) **Document the decision**
      - Write reasoning in `framework/docs/handoff.md`
      - Format: "DECISION: [choice] | RATIONALE: [why] | ALTERNATIVES: [what else considered]"

3. **ERROR HANDLING**
   - Errors are NON-FATAL by default
   - Log error details in task log
   - Try alternative approach (max 3 attempts)
   - If still blocked: document blocker + continue with next subtask
   - NEVER stop entire task due to one blocker

4. **TIME MANAGEMENT**
   - Target completion: {TIME_BUDGET} minutes
   - Check progress every 10 minutes
   - If 70% time used and < 50% done → simplify remaining scope
   - At 90% time: wrap up, document incomplete parts

5. **COMMUNICATION**
   - Output text is for logging, not user questions
   - Use imperative statements: "Implementing X", "Creating Y"
   - Avoid phrases: "Should I...?", "Would you like...?", "Let me check with you..."

6. **HANDOFF DOCUMENTATION**
   All decisions, blockers, and trade-offs go into:
   `framework/docs/handoff.md` (or task-specific location)

   Use this format:
   ```
   ## [TIMESTAMP] Task: [TASK_ID]

   ### Decisions Made
   - DECISION: [what] | RATIONALE: [why] | ALTERNATIVES: [other options]

   ### Blockers Encountered
   - BLOCKER: [what] | ATTEMPTED: [solutions tried] | STATUS: [bypassed/deferred/escalated]

   ### Scope Adjustments
   - ORIGINAL: [what was planned]
   - ACTUAL: [what was done]
   - REASON: [why changed]
   ```

7. **SUCCESS CRITERIA**
   Task is complete when:
   - Core functionality implemented and tested
   - Code follows existing patterns
   - All decisions documented in handoff
   - No critical blockers remaining (minor ones OK if documented)

### WHAT TO DO IF STUCK

```
IF (can't decide between 2 approaches):
  → Choose more conservative
  → Document both in handoff

IF (missing information from codebase):
  → Search more thoroughly (Grep, Glob)
  → If still not found: assume standard practice
  → Document assumption

IF (technical blocker - API down, dependency missing):
  → Try 3 alternative approaches
  → If all fail: document blocker + mock/stub the functionality
  → Continue with rest of task

IF (architectural uncertainty):
  → Look at similar features in codebase
  → Match their architecture
  → Document pattern followed
```

### FORBIDDEN ACTIONS

❌ Using AskUserQuestion tool
❌ Stopping task execution to "check with user"
❌ Leaving code half-implemented without documentation why
❌ Making random guesses without checking codebase patterns
❌ Spending > 30% of time on any single subtask

### ENCOURAGED ACTIONS

✅ Reading existing code to understand patterns
✅ Writing detailed comments for complex logic
✅ Creating small, focused commits with clear messages
✅ Testing incrementally as you build
✅ Documenting trade-offs in handoff.md
✅ Simplifying scope if running out of time

---

## 📋 YOUR TASK BEGINS BELOW

[... actual task description follows ...]
```

## Why this works on the model

1. **Explicit override** — "You are in AUTONOMOUS mode" creates a new context
2. **CRITICAL RULES** — bold text and caps draw the model's attention
3. **Decision framework** — gives an algorithm instead of "ask the user"
4. **Examples (IF/THEN)** — concrete scenarios instead of abstract rules
5. **Forbidden vs Encouraged** — clear boundaries for behavior
6. **Time pressure** — creates urgency to finish

## Adapting it to the task

### For simple tasks (< 30 min)
```markdown
TIME_BUDGET: 30 minutes
FALLBACK_STRATEGY: simplify_and_complete
```

### For complex tasks (> 2 hours)
```markdown
TIME_BUDGET: 120 minutes
CHECKPOINT_INTERVAL: 30 minutes
FALLBACK_STRATEGY: document_and_escalate
```

### For experimental tasks
```markdown
TIME_BUDGET: 60 minutes
RISK_TOLERANCE: high
FALLBACK_STRATEGY: document_experiments
```

### For critical tasks
```markdown
TIME_BUDGET: 90 minutes
RISK_TOLERANCE: low
VALIDATION_REQUIRED: run tests after each step
FALLBACK_STRATEGY: revert_and_document
```

## Success metrics

Autonomous mode is working if:

1. ✅ The task finished within the time budget
2. ✅ Zero uses of AskUserQuestion
3. ✅ Every decision is documented in handoff.md
4. ✅ The code follows repository patterns
5. ✅ The functionality works (tests pass)

## Integration with the orchestrator

The orchestrator can check the metrics:

```python
def validate_autonomous_execution(task_id):
    log = parse_task_log(task_id)

    violations = {
        "ask_user_calls": count_tool_uses(log, "AskUserQuestion"),
        "missing_handoff": not exists("framework/docs/handoff.md"),
        "time_overrun": task_duration(log) > task_budget(task_id) * 1.2
    }

    if any(violations.values()):
        logger.warning(f"Task {task_id} violated autonomous protocol: {violations}")
```

## Next steps

1. Take one task definition (for example, `framework/tasks/db-schema.md`)
2. Add this metaprompt at the top
3. Run it through the orchestrator with `claude-code`
4. Check the logs for AskUserQuestion calls
5. Read handoff.md for the quality of the decision documentation
6. Improve the protocol iteratively

---

**Status**: Ready for testing
**Requires**: Changes to task definitions (see 02-task-template-improvements.md)
