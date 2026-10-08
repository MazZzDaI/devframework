#!/usr/bin/env bash
# Headless Cursor Agent runner for DevFramework tasks.
# Usage: cursor-runner.sh /absolute/path/to/prompt.md
set -euo pipefail

PROMPT_FILE="${1:-}"
MODEL="${FRAMEWORK_CURSOR_MODEL:-${CURSOR_MODEL:-grok-4.7}}"
SANDBOX="${FRAMEWORK_CURSOR_SANDBOX:-disabled}"

if [[ -z "$PROMPT_FILE" || ! -f "$PROMPT_FILE" ]]; then
  echo "cursor-runner: prompt file not found: ${PROMPT_FILE:-<missing>}" >&2
  exit 2
fi

AGENT_BIN=""
if command -v agent >/dev/null 2>&1; then
  AGENT_BIN="$(command -v agent)"
elif command -v cursor-agent >/dev/null 2>&1; then
  AGENT_BIN="$(command -v cursor-agent)"
else
  echo "cursor-runner: Cursor CLI 'agent' is not on PATH." >&2
  echo "Install: curl https://cursor.com/install -fsS | bash" >&2
  echo "Then sign in: agent login   (or set CURSOR_API_KEY)" >&2
  exit 127
fi

PROMPT="$(cat "$PROMPT_FILE")"
echo "[cursor] model=${MODEL} sandbox=${SANDBOX} prompt=${PROMPT_FILE}"
exec "$AGENT_BIN" -p --force --trust --sandbox "$SANDBOX" \
  --model "$MODEL" --output-format text "$PROMPT"
