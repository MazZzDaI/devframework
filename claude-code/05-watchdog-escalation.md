# Watchdog and Escalation of Stuck Tasks

## Problem

Claude Code in autonomous mode can **get stuck without anyone noticing**:

- Loops on architecture analysis (reads the same code over and over)
- Waits for a response from an API that does not exist
- Tries to solve an unsolvable problem
- Falls into an infinite loop of reasoning

**Without monitoring**, a task can "hang" for hours, consuming resources.

## Watchdog concept

A **watchdog** is a background process that monitors task progress and detects when it is stuck.

### How it works

```
Task Start
    ↓
Watchdog: [Monitor every 30 sec]
    ↓
Check Progress Indicators:
  - Files changed?
  - Commits made?
  - Log growing?
  - CPU/Memory usage?
    ↓
  ┌─── Yes → Continue monitoring
  │
  └─── No (5 min) → ESCALATE
         ↓
    [Kill task]
         ↓
    [Notify / Retry / Switch agent]
```

## Progress Indicators

### 1. File System Activity

**Metric**: Timestamp of the latest file modification in the worktree

```python
def check_file_activity(worktree_path, threshold=300):
    """Check if any files modified in last 5 minutes"""
    recent_files = []

    for root, dirs, files in os.walk(worktree_path):
        # Skip .git directory
        dirs[:] = [d for d in dirs if d != '.git']

        for file in files:
            filepath = os.path.join(root, file)
            mtime = os.path.getmtime(filepath)

            if time.time() - mtime < threshold:
                recent_files.append({
                    "path": filepath,
                    "modified": datetime.fromtimestamp(mtime),
                    "age_seconds": time.time() - mtime
                })

    return len(recent_files) > 0, recent_files
```

**Pros**: A direct indicator of work (the code is changing)
**Cons**: The agent may be reading without writing (false positive)

---

### 2. Git Commits

**Metric**: Number of new commits in the worktree

```python
def check_git_activity(worktree_path, since_minutes=5):
    """Check if new commits made recently"""
    result = subprocess.run(
        ["git", "log", f"--since={since_minutes} minutes ago", "--oneline"],
        cwd=worktree_path,
        capture_output=True,
        text=True
    )

    commits = result.stdout.strip().split('\n') if result.stdout else []
    return len(commits) > 0, commits
```

**Pros**: Shows meaningful progress (finished changes)
**Cons**: The agent may work for a long time before the first commit

---

### 3. Log Growth

**Metric**: The task log file is growing

```python
class LogGrowthMonitor:
    def __init__(self, log_path):
        self.log_path = log_path
        self.last_size = 0
        self.last_check = time.time()

    def check_growth(self, min_growth_bytes=100):
        """Check if log file growing"""
        if not os.path.exists(self.log_path):
            return False, "Log file not found"

        current_size = os.path.getsize(self.log_path)
        growth = current_size - self.last_size

        # Update state
        self.last_size = current_size
        elapsed = time.time() - self.last_check
        self.last_check = time.time()

        if growth >= min_growth_bytes:
            return True, f"Log grew by {growth} bytes in {elapsed:.1f}s"
        else:
            return False, f"Log stagnant (only {growth} bytes in {elapsed:.1f}s)"
```

**Pros**: Shows that the agent is "thinking" (writing to the log)
**Cons**: The agent may spam the same thing (infinite loop)

---

### 4. Process Resource Usage

**Metric**: CPU and memory usage of the agent process

```python
import psutil

class ProcessMonitor:
    def __init__(self, pid):
        self.process = psutil.Process(pid)
        self.cpu_samples = []
        self.memory_samples = []

    def check_activity(self):
        """Check if process is actively working"""
        cpu_percent = self.process.cpu_percent(interval=1.0)
        memory_mb = self.process.memory_info().rss / 1024 / 1024

        self.cpu_samples.append(cpu_percent)
        self.memory_samples.append(memory_mb)

        # Keep last 10 samples
        self.cpu_samples = self.cpu_samples[-10:]
        self.memory_samples = self.memory_samples[-10:]

        # Check patterns
        avg_cpu = sum(self.cpu_samples) / len(self.cpu_samples)

        if avg_cpu < 5:
            return False, "CPU usage very low (idle or waiting)"
        elif avg_cpu > 90:
            return None, "CPU usage very high (possible infinite loop)"
        else:
            return True, f"CPU usage normal ({avg_cpu:.1f}%)"
```

**Pros**: Detects idle (waiting for a response) and infinite loops (CPU spike)
**Cons**: Does not show whether the work is meaningful (can burn CPU for nothing)

---

### 5. Tool Usage Patterns

**Metric**: Which tools the agent calls

```python
class ToolUsageMonitor:
    def __init__(self, log_path):
        self.log_path = log_path
        self.tool_history = []

    def parse_recent_tools(self, last_n_lines=50):
        """Parse recent tool calls from log"""
        with open(self.log_path) as f:
            lines = f.readlines()[-last_n_lines:]

        tools = []
        for line in lines:
            if "tool:" in line.lower():
                # Extract tool name (format: "Using tool: Read")
                match = re.search(r'tool:\s*(\w+)', line, re.IGNORECASE)
                if match:
                    tools.append(match.group(1))

        self.tool_history.extend(tools)
        return tools

    def detect_patterns(self):
        """Detect problematic tool usage patterns"""
        recent = self.tool_history[-20:]  # Last 20 tool calls

        # Pattern 1: Repetitive reads of same file
        if recent.count("Read") > 10:
            files = self._extract_read_targets(recent)
            if len(set(files)) == 1:
                return "stuck_reading", f"Reading same file repeatedly: {files[0]}"

        # Pattern 2: Many Grep calls without progress
        if recent.count("Grep") > 8:
            return "stuck_searching", "Too many search operations without action"

        # Pattern 3: Excessive Bash calls
        if recent.count("Bash") > 15:
            return "stuck_executing", "Too many command executions"

        # Pattern 4: Only Task calls (spawning subagents)
        if all(t == "Task" for t in recent[-5:]):
            return "stuck_delegating", "Only spawning subagents, no direct work"

        return "healthy", "Tool usage looks normal"
```

**Pros**: Shows **qualitative** progress (not just activity)
**Cons**: Harder to implement (log parsing, pattern matching)

---

## Composite Progress Indicator

A combined metric from several indicators:

```python
class ProgressWatchdog:
    def __init__(self, task):
        self.task = task
        self.indicators = {
            "files": FileActivityIndicator(task["worktree_path"]),
            "commits": GitCommitIndicator(task["worktree_path"]),
            "log": LogGrowthMonitor(task["log_path"]),
            "process": ProcessMonitor(task["pid"]),
            "tools": ToolUsageMonitor(task["log_path"])
        }
        self.last_progress_time = time.time()

    def check_progress(self):
        """Check if task is making progress (composite)"""
        results = {}

        for name, indicator in self.indicators.items():
            has_progress, details = indicator.check()
            results[name] = {
                "progress": has_progress,
                "details": details
            }

        # Decision logic: ANY indicator shows progress → not stuck
        any_progress = any(r["progress"] for r in results.values())

        if any_progress:
            self.last_progress_time = time.time()
            return True, results

        # No progress detected
        stuck_duration = time.time() - self.last_progress_time

        if stuck_duration > 300:  # 5 minutes
            return False, {
                "stuck_duration": stuck_duration,
                "indicators": results
            }

        return None, results  # Uncertain (too early to tell)
```

---

## Escalation Strategies

When a stall is detected, what should you do?

### Strategy 1: Notify

The softest option — just log it and keep waiting.

```python
def escalate_notify(task, stuck_info):
    """Log warning and continue monitoring"""
    logger.warning(
        f"Task {task['id']} appears stuck for {stuck_info['stuck_duration']:.0f}s"
    )
    logger.debug(f"Progress indicators: {stuck_info['indicators']}")

    # Could send notification (email, Slack, etc.)
    # send_notification(...)
```

**When to use**: For long tasks (> 2 hours), where 5 minutes of idle time is normal.

---

### Strategy 2: Interrupt

Try to "wake" the agent through a signal or an API.

```python
def escalate_interrupt(task, stuck_info):
    """Send interrupt signal to agent process"""
    logger.warning(f"Interrupting stuck task {task['id']}")

    # Send SIGUSR1 (custom signal agents can handle)
    os.kill(task["pid"], signal.SIGUSR1)

    # Or if agent has HTTP API:
    # requests.post(f"http://localhost:{task['port']}/interrupt")
```

**When to use**: If the agent supports graceful interrupts.

---

### Strategy 3: Kill and Retry

Hard-kill the process and start the task again.

```python
def escalate_kill_retry(task, stuck_info):
    """Kill stuck task and retry from beginning"""
    logger.warning(f"Killing and retrying task {task['id']}")

    # Kill process
    os.kill(task["pid"], signal.SIGKILL)

    # Clean up worktree
    subprocess.run(["git", "worktree", "remove", "--force", task["worktree_path"]])

    # Retry task (increment attempt counter)
    task["attempt"] = task.get("attempt", 0) + 1

    if task["attempt"] <= 3:
        logger.info(f"Retrying task {task['id']} (attempt {task['attempt']})")
        orchestrator.run_task(task)
    else:
        logger.error(f"Task {task['id']} failed after 3 attempts")
        mark_task_failed(task)
```

**When to use**: For short tasks (< 1 hour), when a restart is cheaper than waiting.

---

### Strategy 4: Escalate to Different Agent

The most interesting strategy — hand the task to another agent.

```python
def escalate_switch_agent(task, stuck_info):
    """Switch to different agent (e.g., Claude → Codex)"""
    current_agent = task["runner"]
    logger.warning(f"Task {task['id']} stuck with {current_agent}, escalating to Codex")

    # Kill current process
    os.kill(task["pid"], signal.SIGKILL)

    # Prepare handoff context
    handoff = ContextHandoff()
    context_file = handoff.prepare(
        from_agent=current_agent,
        to_agent="codex",
        task=task,
        reason=f"Stuck for {stuck_info['stuck_duration']:.0f}s"
    )

    # Update task to use Codex
    task["runner"] = "codex"
    task["context_file"] = context_file
    task["escalated_from"] = current_agent

    # Restart with Codex
    logger.info(f"Restarting task {task['id']} with Codex")
    orchestrator.run_task(task)
```

**When to use**: Ideal for autonomous mode — Claude got stuck, Codex will push it through.

---

### Strategy 5: Simplify Scope

If the task is too hard, simplify it.

```python
def escalate_simplify(task, stuck_info):
    """Reduce task scope and retry"""
    logger.warning(f"Task {task['id']} stuck, simplifying scope")

    # Parse task definition
    task_md = Path(task["file"]).read_text()

    # Generate simplified version with LLM
    simplified = simplify_task_with_llm(task_md, reason=stuck_info)

    # Write simplified task
    simplified_path = task["file"].replace(".md", "_simplified.md")
    Path(simplified_path).write_text(simplified)

    # Kill and restart with simplified task
    os.kill(task["pid"], signal.SIGKILL)
    task["file"] = simplified_path
    task["simplified"] = True
    orchestrator.run_task(task)
```

**When to use**: When the task is too ambitious for autonomous mode.

---

## Integration into the Orchestrator

### Configuration

```json
{
  "tasks": [
    {
      "id": "complex-feature",
      "watchdog": {
        "enabled": true,
        "check_interval_seconds": 30,
        "stuck_threshold_seconds": 300,
        "indicators": [
          "files",
          "commits",
          "log",
          "tools"
        ],
        "escalation": {
          "strategy": "escalate_to_codex",
          "max_retries": 2,
          "fallback_strategy": "notify"
        }
      }
    }
  ]
}
```

### Implementation

```python
class Orchestrator:
    def run_task(self, task):
        """Run task with optional watchdog monitoring"""
        # Start task process
        process = self._start_task_process(task)
        task["pid"] = process.pid

        # Start watchdog if enabled
        if task.get("watchdog", {}).get("enabled"):
            watchdog = ProgressWatchdog(task)
            watchdog_thread = threading.Thread(
                target=self._monitor_with_watchdog,
                args=(task, watchdog),
                daemon=True
            )
            watchdog_thread.start()

        # Wait for completion or escalation
        while process.poll() is None:
            time.sleep(1)

        return self._finalize_task(task)

    def _monitor_with_watchdog(self, task, watchdog):
        """Background thread monitoring task progress"""
        config = task["watchdog"]
        check_interval = config["check_interval_seconds"]

        while True:
            time.sleep(check_interval)

            # Check if task still running
            if not psutil.pid_exists(task["pid"]):
                logger.debug(f"Task {task['id']} completed, stopping watchdog")
                break

            # Check progress
            has_progress, info = watchdog.check_progress()

            if has_progress is False:  # Stuck detected
                logger.warning(f"Watchdog detected stuck task {task['id']}")
                self._handle_escalation(task, info)
                break

    def _handle_escalation(self, task, stuck_info):
        """Handle stuck task according to escalation strategy"""
        strategy_name = task["watchdog"]["escalation"]["strategy"]
        strategies = {
            "notify": escalate_notify,
            "interrupt": escalate_interrupt,
            "kill_retry": escalate_kill_retry,
            "escalate_to_codex": escalate_switch_agent,
            "simplify": escalate_simplify
        }

        strategy_fn = strategies.get(strategy_name, escalate_notify)
        strategy_fn(task, stuck_info)
```

---

## Metrics for tuning

After the watchdog is in place, collect statistics:

```jsonl
{"task_id": "db-schema", "stuck": false, "duration": 42, "indicators": {"files": true, "commits": true}}
{"task_id": "ui-complex", "stuck": true, "duration": 312, "stuck_at": 305, "escalation": "codex", "after_escalation_duration": 95}
{"task_id": "api-impl", "stuck": false, "duration": 67, "indicators": {"log": true, "tools": true}}
```

Analyze:
- **False positive rate** — how many tasks were wrongly marked as stuck
- **Detection latency** — how quickly a stall is detected
- **Escalation effectiveness** — whether escalation helps finish the task

Tune:
- `stuck_threshold_seconds` — when to treat a task as stuck
- `check_interval_seconds` — how often to check
- The set of indicators — which combinations work better

---

## Progress visualization

Optional: a real-time dashboard for monitoring:

```
┌─────────────────────────────────────────────────────┐
│ Task: db-schema                       [⚠ Watching]  │
├─────────────────────────────────────────────────────┤
│ Runner: claude-code     Mode: autonomous            │
│ Duration: 8m 42s / 45m budget                       │
│                                                     │
│ Progress Indicators:                                │
│   Files changed:  ✓ (2m ago)    [=============>   ] │
│   Git commits:    ✓ (5m ago)    [========>        ] │
│   Log growth:     ✓ (12s ago)   [===============> ] │
│   CPU usage:      ✓ (42% avg)   [===========>     ] │
│   Tool patterns:  ✓ (healthy)   [===============>] │
│                                                     │
│ Recent Activity:                                    │
│   08:42 → Read: framework/tasks/db-schema.md        │
│   08:43 → Grep: "CREATE TABLE" in db/               │
│   08:44 → Write: db/migrations/001_initial.sql      │
│   08:45 → Bash: psql -f db/migrations/001_initial...│
│                                                     │
│ Status: 🟢 Making progress                          │
└─────────────────────────────────────────────────────┘
```

Implemented with curses, blessed, or rich (Python libraries for a TUI).

---

**Status**: Ready to implement
**Priority**: High (critical for autonomous mode)
**Dependencies**: Requires changes to orchestrator.py
**Next step**: Start with a simple LogGrowthMonitor, then add indicators gradually
