# Modifications to orchestrator.py for Autonomous Mode

## Current architecture

Looking at `framework/orchestrator/orchestrator.py` (~540 lines), I see:

```python
class Orchestrator:
    def __init__(self, config_path):
        self.config = load_config(config_path)
        self.tasks = self.config["tasks"]
        self.runners = self.config["runners"]

    def run_task(self, task):
        runner = self.get_runner(task["runner"])
        cmd = self.build_command(runner, task)
        process = subprocess.Popen(cmd, ...)
        # Monitor and log
```

**What works well**:
- ✅ Support for multiple runners (codex, claude-code, aider)
- ✅ Task dependencies
- ✅ JSONL event logging
- ✅ Worktree isolation

**What needs to be added for autonomy**:
- ❌ No `execution_mode` parameter in the task definition
- ❌ No metaprompt injection into the launch command
- ❌ No progress monitoring (watchdog)
- ❌ No automatic escalation when a task hangs
- ❌ No validation of autonomous mode compliance

## Levels of change

### Level 0: No orchestrator changes (task definitions only)

**Approach**: Add the metaprompt directly in `framework/tasks/*.md`

**Pros**:
- Zero code changes
- Works right now
- Backward compatible

**Cons**:
- The metaprompt is duplicated in every task
- You cannot switch the mode dynamically
- No compliance validation

**Recommendation**: Start at this level for a quick prototype

---

### Level 1: Minimal changes (execution_mode in the config)

#### Changes to orchestrator.json

```json
{
  "runners": {
    "claude-code": {
      "type": "claude-code",
      "command": "claude-code",
      "autonomous_mode": {
        "enabled": true,
        "prepend_protocol": true,
        "protocol_file": "claude-code/01-autonomous-mode-protocol.md"
      }
    },
    "codex": {
      "type": "codex",
      "command": "codex --mode agent"
    }
  },
  "tasks": [
    {
      "id": "db-schema",
      "file": "framework/tasks/db-schema.md",
      "runner": "claude-code",
      "execution_mode": "autonomous",
      "time_budget": 45,
      "depends_on": []
    }
  ]
}
```

#### Changes to orchestrator.py

```python
class Orchestrator:
    def build_command(self, task, runner):
        """Build command with optional autonomous mode injection"""
        base_cmd = runner["command"]
        task_file = task["file"]

        # Check if autonomous mode enabled
        if task.get("execution_mode") == "autonomous":
            autonomous_config = runner.get("autonomous_mode", {})

            if autonomous_config.get("enabled") and autonomous_config.get("prepend_protocol"):
                # Create temporary task file with protocol prepended
                protocol_file = autonomous_config["protocol_file"]
                temp_task_file = self._inject_autonomous_protocol(
                    protocol_file,
                    task_file,
                    task.get("time_budget", 60)
                )
                task_file = temp_task_file

        return f"{base_cmd} --task {task_file}"

    def _inject_autonomous_protocol(self, protocol_path, task_path, time_budget):
        """Prepend autonomous mode protocol to task definition"""
        protocol = Path(protocol_path).read_text()
        task_content = Path(task_path).read_text()

        # Replace placeholders
        protocol = protocol.replace("{TIME_BUDGET}", str(time_budget))

        # Create temp file
        temp_path = Path(f"/tmp/autonomous_task_{uuid.uuid4().hex}.md")
        temp_path.write_text(f"{protocol}\n\n{task_content}")

        return str(temp_path)
```

**Pros**:
- Centralized protocol (one place to edit)
- Easy to turn on or off per task
- Dynamic substitution of parameters (time_budget)

**Cons**:
- orchestrator.py has to be modified
- Temporary files (but that is not critical)

---

### Level 2: Full support (+ watchdog + validation)

#### Additional fields in the config

```json
{
  "tasks": [
    {
      "id": "db-schema",
      "execution_mode": "autonomous",
      "time_budget": 45,
      "watchdog": {
        "enabled": true,
        "check_interval": 300,
        "progress_indicators": ["files_changed", "commits", "log_activity"],
        "escalation_strategy": "notify"
      },
      "validation": {
        "check_autonomous_compliance": true,
        "fail_on_ask_user": true
      }
    }
  ]
}
```

#### Watchdog for progress monitoring

```python
class TaskWatchdog:
    """Monitor task progress and detect stuck tasks"""

    def __init__(self, task, config):
        self.task = task
        self.config = config
        self.last_activity = time.time()
        self.activity_indicators = {
            "files_changed": self._check_files_changed,
            "commits": self._check_git_commits,
            "log_activity": self._check_log_growth
        }

    def check_progress(self):
        """Check if task is making progress"""
        watchdog_config = self.task.get("watchdog", {})
        if not watchdog_config.get("enabled"):
            return True

        check_interval = watchdog_config.get("check_interval", 300)

        # Check if any activity indicator shows progress
        has_progress = any(
            indicator_fn()
            for indicator_name, indicator_fn in self.activity_indicators.items()
            if indicator_name in watchdog_config.get("progress_indicators", [])
        )

        if has_progress:
            self.last_activity = time.time()
            return True

        # No progress detected
        elapsed = time.time() - self.last_activity
        if elapsed > check_interval:
            self._handle_stuck_task()
            return False

        return True

    def _check_files_changed(self):
        """Check if files in worktree changed recently"""
        worktree_path = self.task["worktree_path"]
        cutoff_time = time.time() - 60  # Last 60 seconds

        for root, dirs, files in os.walk(worktree_path):
            for file in files:
                file_path = os.path.join(root, file)
                if os.path.getmtime(file_path) > cutoff_time:
                    return True
        return False

    def _check_git_commits(self):
        """Check if new commits made in worktree"""
        worktree_path = self.task["worktree_path"]
        result = subprocess.run(
            ["git", "log", "--since=5 minutes ago", "--oneline"],
            cwd=worktree_path,
            capture_output=True,
            text=True
        )
        return len(result.stdout.strip()) > 0

    def _check_log_growth(self):
        """Check if task log is growing"""
        log_path = self.task.get("log_path")
        if not log_path or not os.path.exists(log_path):
            return False

        current_size = os.path.getsize(log_path)
        last_size = getattr(self, "_last_log_size", 0)
        self._last_log_size = current_size

        return current_size > last_size

    def _handle_stuck_task(self):
        """Handle task that appears stuck"""
        strategy = self.task.get("watchdog", {}).get("escalation_strategy", "notify")

        if strategy == "notify":
            logger.warning(f"Task {self.task['id']} appears stuck (no progress for 5+ min)")

        elif strategy == "kill_and_retry":
            logger.warning(f"Killing stuck task {self.task['id']} and retrying")
            self._kill_task()
            self._retry_task()

        elif strategy == "escalate_to_codex":
            logger.warning(f"Escalating stuck task {self.task['id']} to Codex")
            self._kill_task()
            self._restart_with_different_runner("codex")


class Orchestrator:
    def monitor_tasks(self):
        """Main monitoring loop with watchdog"""
        watchdogs = {
            task_id: TaskWatchdog(task, self.config)
            for task_id, task in self.running_tasks.items()
            if task.get("watchdog", {}).get("enabled")
        }

        while self.running_tasks:
            for task_id, watchdog in watchdogs.items():
                if not watchdog.check_progress():
                    # Task stuck, watchdog handled it
                    pass

            time.sleep(30)  # Check every 30 seconds
```

#### Validation of autonomous mode compliance

```python
class AutonomousValidator:
    """Validate that task followed autonomous mode protocol"""

    def validate(self, task):
        """Check if task violated autonomous mode rules"""
        if task.get("execution_mode") != "autonomous":
            return {"compliant": True, "violations": []}

        violations = []

        # Check for AskUserQuestion usage
        if self._used_ask_user_tool(task):
            violations.append({
                "rule": "NO_QUESTIONS_TO_USER",
                "severity": "critical",
                "details": "Used AskUserQuestion tool in autonomous mode"
            })

        # Check for handoff documentation
        if not self._has_handoff_docs(task):
            violations.append({
                "rule": "DOCUMENT_DECISIONS",
                "severity": "warning",
                "details": "Missing handoff documentation"
            })

        # Check time budget compliance
        if self._exceeded_time_budget(task):
            violations.append({
                "rule": "TIME_BUDGET",
                "severity": "warning",
                "details": f"Exceeded budget by {self._time_overrun(task)} minutes"
            })

        return {
            "compliant": len([v for v in violations if v["severity"] == "critical"]) == 0,
            "violations": violations
        }

    def _used_ask_user_tool(self, task):
        """Parse task log for AskUserQuestion tool usage"""
        log_path = task.get("log_path")
        if not log_path:
            return False

        with open(log_path) as f:
            log_content = f.read()
            return "AskUserQuestion" in log_content

    def _has_handoff_docs(self, task):
        """Check if handoff.md exists and has content"""
        handoff_path = Path("framework/docs/handoff.md")
        if not handoff_path.exists():
            return False

        # Check if task_id mentioned in handoff
        content = handoff_path.read_text()
        return task["id"] in content


class Orchestrator:
    def finalize_task(self, task):
        """Validate and finalize completed task"""
        validator = AutonomousValidator()
        validation_result = validator.validate(task)

        if not validation_result["compliant"]:
            logger.error(f"Task {task['id']} violated autonomous mode protocol:")
            for violation in validation_result["violations"]:
                logger.error(f"  - {violation['rule']}: {violation['details']}")

            if task.get("validation", {}).get("fail_on_violation"):
                raise AutonomousProtocolViolation(task["id"], validation_result)

        # Log validation result
        self._log_event({
            "type": "task_validation",
            "task_id": task["id"],
            "compliant": validation_result["compliant"],
            "violations": validation_result["violations"]
        })
```

**Pros**:
- Full control over execution
- Automatic problem detection
- Quality metrics for autonomous mode
- Ability to escalate

**Cons**:
- More code to maintain
- More complex configuration

---

### Level 3: Hybrid pipeline (Claude + Codex)

#### Concept

```
Task Definition
     ↓
[Check execution_mode]
     ↓
IF autonomous:
  → Try Claude Code first (with protocol)
  → Watchdog monitors
  → IF stuck > 5 min:
      → Auto-escalate to Codex
      → Codex continues from where Claude stopped
     ↓
IF interactive:
  → Use standard Claude Code
  → Allow AskUserQuestion
```

#### Configuration

```json
{
  "tasks": [
    {
      "id": "db-schema",
      "execution_mode": "autonomous",
      "runner_strategy": "fallback",
      "runners": [
        {
          "type": "claude-code",
          "priority": 1,
          "timeout": 45
        },
        {
          "type": "codex",
          "priority": 2,
          "trigger": "on_timeout"
        }
      ]
    }
  ]
}
```

#### Implementation

```python
class Orchestrator:
    def run_task_with_fallback(self, task):
        """Run task with fallback runner strategy"""
        runners = task.get("runners", [])
        runners.sort(key=lambda r: r["priority"])

        for runner in runners:
            logger.info(f"Attempting task {task['id']} with {runner['type']}")

            try:
                result = self.run_task(task, runner)

                # Check if completed successfully
                if result["status"] == "success":
                    return result

                # Check if should try next runner
                if runner.get("trigger") == "on_failure":
                    logger.warning(f"{runner['type']} failed, trying next runner")
                    continue

            except TaskTimeout:
                if runner.get("trigger") == "on_timeout":
                    logger.warning(f"{runner['type']} timed out, trying next runner")
                    continue
                raise

        # All runners exhausted
        raise TaskFailed(task["id"], "All runners failed")
```

---

## Recommended rollout plan

### Phase 1: Prototype (Level 0)
- Add the metaprompt to 1-2 task definitions
- Run it manually and check the behavior
- Collect metrics (AskUserQuestion usage, completion time)

### Phase 2: Basic integration (Level 1)
- Add `execution_mode` and `time_budget` to orchestrator.json
- Implement `_inject_autonomous_protocol()` in orchestrator.py
- Test it on 5-10 tasks

### Phase 3: Production (Level 2)
- Add a watchdog for monitoring
- Add compliance validation
- Collect metrics for optimization

### Phase 4: Optimization (Level 3)
- Hybrid strategies (Claude + Codex)
- Machine learning to pick a runner by task type
- Automatic optimization of time budgets

---

## Backward compatibility

All changes are optional:

```json
// Old config (still works)
{
  "tasks": [
    {
      "id": "db-schema",
      "file": "framework/tasks/db-schema.md",
      "runner": "claude-code"
    }
  ]
}

// New config (opt-in)
{
  "tasks": [
    {
      "id": "db-schema",
      "file": "framework/tasks/db-schema.md",
      "runner": "claude-code",
      "execution_mode": "autonomous",  // New field
      "time_budget": 45                 // New field
    }
  ]
}
```

---

## Metrics to track

After rollout, collect:

1. **Autonomous compliance rate** — % of tasks with no AskUserQuestion
2. **Time budget accuracy** — actual vs planned time
3. **Watchdog triggers** — how often tasks get stuck
4. **Runner effectiveness** — Claude vs Codex success rate
5. **Task retry rate** — how many tasks have to be redone

Store them in `framework/logs/metrics.jsonl`:

```jsonl
{"task_id": "db-schema", "runner": "claude-code", "mode": "autonomous", "asked_questions": 0, "time_actual": 42, "time_budget": 45, "compliant": true}
{"task_id": "ui-component", "runner": "claude-code", "mode": "autonomous", "asked_questions": 2, "time_actual": 67, "time_budget": 60, "compliant": false}
```

---

**Status**: Ready to implement
**Recommendation**: Start at Level 1 and add features gradually
**Files to change**:
- `framework/orchestrator/orchestrator.py`
- `framework/orchestrator/orchestrator.json`
