#!/usr/bin/env bash
# DEVFRAMEWORK:MANAGED
# Project launcher for Cursor Agent on Grok.
set -euo pipefail

MODEL="${FRAMEWORK_CURSOR_MODEL:-${CURSOR_MODEL:-grok-4.7}}"

AGENT_BIN=""
if command -v agent >/dev/null 2>&1; then
  AGENT_BIN="$(command -v agent)"
elif command -v cursor-agent >/dev/null 2>&1; then
  AGENT_BIN="$(command -v cursor-agent)"
else
  echo "Cursor CLI 'agent' is not installed." >&2
  echo "Install: curl https://cursor.com/install -fsS | bash" >&2
  echo "Then sign in: agent login   (or set CURSOR_API_KEY)" >&2
  exit 127
fi

if [[ $# -eq 0 ]]; then
  exec "$AGENT_BIN" --model "$MODEL"
fi

# Honor an explicit --model from the caller; otherwise pin Grok.
for arg in "$@"; do
  if [[ "$arg" == "--model" || "$arg" == --model=* ]]; then
    exec "$AGENT_BIN" "$@"
  fi
done

exec "$AGENT_BIN" --model "$MODEL" "$@"
