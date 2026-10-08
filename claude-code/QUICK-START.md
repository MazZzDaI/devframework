# Quick Start: Autonomous Mode for Claude Code

## 3 ways to use it (from simple to advanced)

### 🟢 Level 1: Metaprompt in the task (5 minutes)

**What**: Add the autonomous protocol directly to the task definition

**How**:
1. Open any task, for example `framework/tasks/db-schema.md`
2. Add this at the top of the file:

```markdown
---
execution_mode: autonomous
time_budget: 45
---

## 🤖 AUTONOMOUS MODE PROTOCOL

[Copy the full protocol from 01-autonomous-mode-protocol.md]

---

[... the rest of the task content ...]
```

3. Run it through the orchestrator:
```bash
python framework/orchestrator/orchestrator.py --config framework/orchestrator/orchestrator.json
```

**Pros**: Works immediately, with no code changes
**Cons**: The protocol is duplicated in every task

---

### 🟡 Level 2: Configuration in orchestrator.json (30 minutes)

**What**: Add autonomous mode support to the orchestrator

**How**:

1. **Update `orchestrator.json`**:
```json
{
  "runners": {
    "claude-code": {
      "type": "claude-code",
      "command": "claude-code",
      "autonomous_mode": {
        "enabled": true,
        "protocol_file": "claude-code/01-autonomous-mode-protocol.md"
      }
    }
  },
  "tasks": [
    {
      "id": "db-schema",
      "file": "framework/tasks/db-schema.md",
      "runner": "claude-code",
      "execution_mode": "autonomous",
      "time_budget": 45
    }
  ]
}
```

2. **Modify `orchestrator.py`** (add about 30 lines of code):

```python
def build_command(self, task, runner):
    """Build command with optional autonomous mode injection"""
    base_cmd = runner["command"]
    task_file = task["file"]

    # Check if autonomous mode enabled
    if task.get("execution_mode") == "autonomous":
        autonomous_config = runner.get("autonomous_mode", {})

        if autonomous_config.get("enabled"):
            # Inject protocol
            protocol_file = autonomous_config["protocol_file"]
            temp_task_file = self._inject_protocol(
                protocol_file,
                task_file,
                task.get("time_budget", 60)
            )
            task_file = temp_task_file

    return f"{base_cmd} --task {task_file}"

def _inject_protocol(self, protocol_path, task_path, time_budget):
    """Prepend protocol to task"""
    protocol = Path(protocol_path).read_text()
    task_content = Path(task_path).read_text()

    # Replace placeholders
    protocol = protocol.replace("{TIME_BUDGET}", str(time_budget))

    # Create temp file
    temp_path = Path(f"/tmp/autonomous_task_{uuid.uuid4().hex}.md")
    temp_path.write_text(f"{protocol}\n\n{task_content}")

    return str(temp_path)
```

**Pros**: Centralized protocol, easy to update
**Cons**: Requires modifying orchestrator.py

---

### 🔴 Level 3: Full integration with a watchdog (2-3 hours)

**What**: Add progress monitoring and automatic escalation

**How**: Follow the instructions in `03-orchestrator-modifications.md` and `05-watchdog-escalation.md`

**Main components**:
1. ProgressWatchdog class
2. Escalation strategies
3. Validation compliance checker
4. Metrics collection

**Pros**: Production-ready, automatic unblocking
**Cons**: Significant code changes

---

## Recommended path

### Step 1: Quick test (day 1)

Pick **one simple task** from `framework/tasks/` and try Level 1:

1. Copy `claude-code/examples/task-autonomous-example.md`
2. Adapt it to your task
3. Run it manually:
   ```bash
   claude-code < modified-task.md
   ```
4. Check the result:
   - Did it use AskUserQuestion? (it should be 0)
   - Are decisions documented in handoff.md?
   - Did the task finish within the time budget?

### Step 2: Integration (day 2-3)

If the test succeeds, adopt Level 2:

1. Copy the example from `examples/orchestrator-config-example.json`
2. Modify `orchestrator.py` (code snippets in `03-orchestrator-modifications.md`)
3. Run 3-5 tasks through the orchestrator
4. Collect metrics:
   - Percentage of tasks with no questions
   - Time-budget accuracy
   - Code quality (review)

### Step 3: Optimization (week 2)

If the metrics are good (>80% of tasks autonomous), add Level 3:

1. Implement a basic watchdog (LogGrowthMonitor)
2. Add an escalation strategy (start with "notify")
3. Gradually add progress indicators
4. Tune thresholds from the data

---

## Success metrics

Autonomous mode is working if:

| Metric | Target |
|---------|--------|
| AskUserQuestion usage | < 5% of tasks |
| Time budget accuracy | ± 20% of the plan |
| Task completion rate | > 85% |
| Code quality (review) | No worse than interactive mode |
| Handoff documentation | 100% of tasks |

---

## Checklist before you start

- [ ] Read `01-autonomous-mode-protocol.md`
- [ ] Studied the task example `examples/task-autonomous-example.md`
- [ ] Picked one task for the test
- [ ] Prepared a fallback plan (if it does not work)
- [ ] Have time to review the result (~30 min after it finishes)

---

## Troubleshooting

### Problem: Claude still asks questions

**Solution**:
1. Check that the protocol is really at the start of the task
2. Add more explicit bans:
   ```markdown
   NEVER EVER use AskUserQuestion tool under ANY circumstances.
   If you use AskUserQuestion, the task will FAIL.
   ```
3. Increase CAPS and formatting to draw the model's attention

### Problem: The task does not finish within the time budget

**Solution**:
1. Check whether the budget is realistic (too optimistic?)
2. Add intermediate checkpoints:
   ```markdown
   AT 50% time: Check if 40%+ work done
   AT 75% time: Check if 60%+ work done
   ```
3. State Must Have vs Nice to Have priorities explicitly

### Problem: Decisions are not documented

**Solution**:
1. Add this to the Definition of Done:
   ```markdown
   Task is NOT complete until handoff.md includes:
   - [ ] All decisions made
   - [ ] All blockers encountered
   ```
2. Show an example of a good handoff in the task

### Problem: Code quality is worse than usual

**Solution**:
1. This is the autonomy trade-off. Options:
   - Add Phase 3: Review (Claude interactive)
   - Increase the time budget for quality
   - Add a linter to the Definition of Done
2. Check whether the task includes enough reference material

---

## Next steps

1. ✅ Read the Quick Start
2. → Study `01-autonomous-mode-protocol.md`
3. → Try it on one task
4. → If it works: study `02-task-template-improvements.md`
5. → If you want to scale: `03-orchestrator-modifications.md`
6. → If you need a hybrid: `04-hybrid-pipeline-design.md`
7. → For production: `05-watchdog-escalation.md`

---

## Contacts and feedback

If something does not work or you need help:
1. Check the existing examples in `examples/`
2. Reread the matching document (01-05)
3. Experiment with the wording in the protocol

**Remember**: Autonomous mode is not "set and forget". It is an iterative process of tuning for your project and tasks.

Good luck! 🚀
