import importlib.util
import tempfile
import unittest
from pathlib import Path


def load_module(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


ROOT = Path(__file__).resolve().parents[2]
ORCH_PATH = ROOT / "framework" / "orchestrator" / "orchestrator.py"
orchestrator = load_module("orchestrator", ORCH_PATH)


class OrchestratorTests(unittest.TestCase):
    def test_normalize_tasks_missing_fields(self):
        with self.assertRaises(RuntimeError):
            orchestrator.normalize_tasks([{"name": "t1", "prompt": "x"}])
        with self.assertRaises(RuntimeError):
            orchestrator.normalize_tasks([{"name": "t1", "worktree": "x"}])

    def test_select_tasks_respects_manual(self):
        tasks = [
            {"name": "t1", "worktree": "w1", "prompt": "p1"},
            {"name": "t2", "worktree": "w2", "prompt": "p2", "manual": True},
        ]
        normalized, _ = orchestrator.normalize_tasks(tasks)
        selected = orchestrator.select_tasks(normalized, "main", include_manual=False)
        self.assertEqual([t["name"] for t in selected], ["t1"])
        selected_all = orchestrator.select_tasks(normalized, "main", include_manual=True)
        self.assertEqual([t["name"] for t in selected_all], ["t1", "t2"])

    def test_preflight_detects_collisions_and_prompt_dir(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            project_root = Path(tmpdir)
            logs_dir = project_root / "logs"
            prompt_dir = project_root / "prompts"
            prompt_dir.mkdir(parents=True, exist_ok=True)
            prompt_file = prompt_dir / "p.md"
            prompt_file.write_text("ok", encoding="utf-8")
            log_dir = project_root / "logdir"
            log_dir.mkdir(parents=True, exist_ok=True)

            runners = {"codex": {"command": "python3 -c \"print('ok')\""}}
            tasks = [
                {
                    "name": "a",
                    "worktree": "wt/shared",
                    "prompt": str(prompt_file),
                    "runner": "codex",
                    "branch": "task/shared",
                    "log": "logs/shared.log",
                },
                {
                    "name": "b",
                    "worktree": "wt/shared",
                    "prompt": str(prompt_dir),
                    "runner": "codex",
                    "branch": "task/shared",
                    "log": "logs/shared.log",
                },
                {
                    "name": "c",
                    "worktree": "wt/unique",
                    "prompt": str(prompt_file),
                    "runner": "codex",
                    "branch": "task/unique",
                    "log": str(log_dir),
                },
            ]
            normalized, _ = orchestrator.normalize_tasks(tasks)
            with self.assertRaises(RuntimeError) as ctx:
                orchestrator.preflight(project_root, logs_dir, runners, normalized, "main")
            msg = str(ctx.exception)
            self.assertIn("Worktree path collision", msg)
            self.assertIn("Branch collision", msg)
            self.assertIn("Prompt path is a directory", msg)
            self.assertIn("Log path collision", msg)
            self.assertIn("Log path is a directory", msg)

    def test_inject_cursor_model_pins_grok(self):
        command = orchestrator.inject_cursor_model("agent")
        self.assertEqual(command, f"agent --model {orchestrator.DEFAULT_CURSOR_MODEL}")
        custom = orchestrator.inject_cursor_model("agent --model grok-4.5")
        self.assertEqual(custom, "agent --model grok-4.5")
        wrapped = orchestrator.inject_cursor_model(
            'bash framework/tools/cursor-runner.sh "/tmp/task.md"'
        )
        self.assertIn("cursor-runner.sh", wrapped)
        self.assertNotIn("--model", wrapped)

    def test_command_uses_cursor(self):
        self.assertTrue(orchestrator.command_uses_cursor("agent --model grok-4.7"))
        self.assertTrue(
            orchestrator.command_uses_cursor(
                'bash framework/tools/cursor-runner.sh "/tmp/p.md"'
            )
        )
        self.assertFalse(orchestrator.command_uses_cursor("python3 -c \"print('ok')\""))


if __name__ == "__main__":
    unittest.main()
