#!/usr/bin/env bash
set -euo pipefail

REPO="${FRAMEWORK_REPO:-MazZzDaI/devframework}"
REF="${FRAMEWORK_REF:-main}"
DEST_DIR="${FRAMEWORK_DEST:-.}"
PHASE="${FRAMEWORK_PHASE:-}"
TOKEN="${FRAMEWORK_TOKEN:-${GITHUB_TOKEN:-}}"
PYTHON_BIN="${FRAMEWORK_PYTHON:-python3}"

ZIP_PATH=""
ZIP_EXPLICIT=0
REF_EXPLICIT=0
UPDATE_FLAG=0
RUN_FLAG=0
SKIP_INSTALL=0
TMP_ZIP=""

if [[ -n "${FRAMEWORK_REF:-}" ]]; then
  REF_EXPLICIT=1
fi

usage() {
  cat <<'EOF'
Usage: ./install-fr.sh [options]

Options:
  --repo <owner/name>    GitHub repo (default: MazZzDaI/devframework)
  --ref <ref>            Branch or tag (default: main)
  --zip <path>           Use local framework.zip instead of downloading
  --dest <dir>           Install destination (default: .)
  --token <token>        GitHub token for private repos (or env FRAMEWORK_TOKEN/GITHUB_TOKEN)
  --update               Replace existing framework (backup is created)
  --run                  Run protocol after install (default: off)
  --no-run               Skip running orchestrator (default)
  --phase <discovery|main|legacy|post>  Force phase when running
  --legacy               Shortcut for --phase legacy
  --main                 Shortcut for --phase main
  --discovery            Shortcut for --phase discovery
  -h, --help             Show help

Env overrides:
  FRAMEWORK_REPO, FRAMEWORK_REF, FRAMEWORK_DEST, FRAMEWORK_PHASE
  FRAMEWORK_TOKEN (or GITHUB_TOKEN)
  FRAMEWORK_PYTHON (default: python3)
  FRAMEWORK_UPDATE=1, FRAMEWORK_RUN=1 (set to 1 to run protocol)
  FRAMEWORK_SKIP_DISCOVERY=1 (skip auto-discovery after legacy)
  FRAMEWORK_RESUME=1 (skip completed phases when re-running)
  FRAMEWORK_PROGRESS_INTERVAL=10 (seconds between [RUNNING] lines)
  FRAMEWORK_STATUS_INTERVAL=10 (seconds between [STATUS] lines)
  FRAMEWORK_WATCH_POLL=2 (watcher poll interval)
  FRAMEWORK_STALL_TIMEOUT=900 (seconds without log updates before alert)
  FRAMEWORK_STALL_KILL=1 (terminate orchestrator on stall)
  FRAMEWORK_OFFLINE=1 (skip GitHub download; use local/embedded zip)
  FRAMEWORK_CURSOR_MODEL (default: grok-4.7)
  CURSOR_API_KEY (headless Cursor auth; or run 'agent login')
EOF
}

truthy() {
  case "${1:-}" in
    1|true|yes|on) return 0 ;;
    *) return 1 ;;
  esac
}

fetch_url() {
  local url="$1"
  local accept_raw="${2:-}"
  if command -v curl >/dev/null 2>&1; then
    if [[ -n "$TOKEN" ]]; then
      if [[ -n "$accept_raw" ]]; then
        curl -fsSL -H "Authorization: token $TOKEN" -H "Accept: application/vnd.github.raw" "$url"
      else
        curl -fsSL -H "Authorization: token $TOKEN" "$url"
      fi
    else
      curl -fsSL "$url"
    fi
    return $?
  fi
  "$PYTHON_BIN" - <<'PY' "$url" "$TOKEN" "$accept_raw"
import sys
import urllib.request
url = sys.argv[1]
token = sys.argv[2] if len(sys.argv) > 2 else ""
accept_raw = sys.argv[3] if len(sys.argv) > 3 else ""
headers = {}
if token:
    headers["Authorization"] = f"token {token}"
if accept_raw:
    headers["Accept"] = "application/vnd.github.raw"
try:
    req = urllib.request.Request(url, headers=headers)
    with urllib.request.urlopen(req) as resp:
        sys.stdout.buffer.write(resp.read())
except Exception as exc:
    sys.stderr.write(str(exc))
    sys.exit(1)
PY
}

parse_release_info() {
  "$PYTHON_BIN" - <<'PY'
import json
import sys

try:
    data = json.load(sys.stdin)
except Exception:
    print()
    print()
    raise SystemExit(0)
tag = data.get("tag_name", "") or ""
zip_url = ""
for asset in data.get("assets") or []:
    if asset.get("name") == "framework.zip":
        zip_url = asset.get("browser_download_url", "") or ""
        break
print(tag)
print(zip_url)
PY
}

script_dir() {
  cd "$(dirname "${BASH_SOURCE[0]}")" && pwd
}

zip_version() {
  local zip_path="$1"
  "$PYTHON_BIN" - <<'PY' "$zip_path"
import sys
import zipfile
from pathlib import Path

zip_path = Path(sys.argv[1])
if not zip_path.exists():
    sys.exit(0)
try:
    with zipfile.ZipFile(zip_path, "r") as zf:
        with zf.open("framework/VERSION") as f:
            value = f.read().decode("utf-8", errors="ignore").strip()
            if value:
                print(value)
except Exception:
    pass
PY
}

has_embedded_zip() {
  grep -q "^__FRAMEWORK_ZIP_PAYLOAD_BEGIN__$" "$1"
}

extract_embedded_zip() {
  local script_path="$1"
  local out_path="$2"
  "$PYTHON_BIN" - <<'PY' "$script_path" "$out_path"
import base64
import sys
from pathlib import Path

script_path = Path(sys.argv[1])
out_path = Path(sys.argv[2])
begin = "__FRAMEWORK_ZIP_PAYLOAD_BEGIN__"
end = "__FRAMEWORK_ZIP_PAYLOAD_END__"
data_lines = []
found = False
for line in script_path.read_text(encoding="utf-8", errors="ignore").splitlines():
    if line == begin:
        found = True
        continue
    if line == end:
        break
    if found:
        data_lines.append(line.strip())
if not data_lines:
    sys.exit(1)
payload = "".join(data_lines).encode("utf-8")
out_path.parent.mkdir(parents=True, exist_ok=True)
out_path.write_bytes(base64.b64decode(payload))
PY
}

CLEANUP_FILES=()
cleanup_add() {
  CLEANUP_FILES+=("$1")
}
cleanup_run() {
  local files=("${CLEANUP_FILES[@]-}")
  for f in "${files[@]}"; do
    rm -f "$f"
  done
}
trap cleanup_run EXIT

output_stub() {
  local path="$1"
  local title="$2"
  local note="$3"
  mkdir -p "$(dirname "$path")"
  {
    echo "# $title"
    echo
    echo "$note"
  } > "$path"
}

reset_output_file() {
  local root="$1"
  local rel="$2"
  local now="$3"
  local path="$root/$rel"
  case "$rel" in
    docs/discovery/interview.md)
      output_stub "$path" "Discovery Interview Log" "Generated by DevFramework. Empty on install (${now})."
      ;;
    docs/tech-spec-generated.md)
      output_stub "$path" "Tech Spec (Generated)" "Generated by DevFramework. Empty on install (${now})."
      ;;
    docs/overview.md)
      output_stub "$path" "Overview (Generated)" "Generated by DevFramework. Empty on install (${now})."
      ;;
    docs/plan-generated.md)
      output_stub "$path" "Plan (Generated)" "Generated by DevFramework. Empty on install (${now})."
      ;;
    docs/data-inputs-generated.md)
      output_stub "$path" "Data Inputs (Generated)" "Generated by DevFramework. Empty on install (${now})."
      ;;
    docs/orchestrator-run-summary.md)
      output_stub "$path" "Orchestrator Run Summary" "Generated by DevFramework. Empty on install (${now})."
      ;;
    review/test-plan.md)
      output_stub "$path" "Test Plan (Generated)" "Generated by DevFramework. Empty on install (${now})."
      ;;
    migration/legacy-snapshot.md)
      output_stub "$path" "Legacy Snapshot" "Generated by DevFramework. Empty on install (${now})."
      ;;
    migration/legacy-tech-spec.md)
      output_stub "$path" "Legacy Tech Spec" "Generated by DevFramework. Empty on install (${now})."
      ;;
    migration/legacy-gap-report.md)
      output_stub "$path" "Legacy Gap Report" "Generated by DevFramework. Empty on install (${now})."
      ;;
    migration/legacy-migration-plan.md)
      output_stub "$path" "Legacy Migration Plan" "Generated by DevFramework. Empty on install (${now})."
      ;;
    migration/legacy-risk-assessment.md)
      output_stub "$path" "Legacy Risk Assessment" "Generated by DevFramework. Empty on install (${now})."
      ;;
    *)
      mkdir -p "$(dirname "$path")"
      : > "$path"
      ;;
  esac
}

reset_outputs() {
  local root="$1"
  local now
  now="$(date -u '+%Y-%m-%d %H:%M:%S UTC')"
  local rel
  for rel in "${OUTPUT_FILES[@]}"; do
    reset_output_file "$root" "$rel" "$now"
  done
  mkdir -p "$root/logs"
  : > "$root/logs/discovery.transcript.log"
  rm -f "$root/logs/discovery.pause"
}

restore_or_reset_outputs() {
  local root="$1"
  local backup="$2"
  local rel
  local now
  now="$(date -u '+%Y-%m-%d %H:%M:%S UTC')"
  for rel in "${OUTPUT_FILES[@]}"; do
    local new_path="$root/$rel"
    local old_path="$backup/$rel"
    if [[ -f "$old_path" ]]; then
      if [[ -f "$new_path" ]] && cmp -s "$old_path" "$new_path"; then
        reset_output_file "$root" "$rel" "$now"
      else
        mkdir -p "$(dirname "$new_path")"
        cp -a "$old_path" "$new_path"
      fi
    else
      reset_output_file "$root" "$rel" "$now"
    fi
  done
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      REPO="$2"
      shift 2
      ;;
    --ref)
      REF="$2"
      REF_EXPLICIT=1
      shift 2
      ;;
    --token)
      TOKEN="$2"
      shift 2
      ;;
    --zip)
      ZIP_PATH="$2"
      ZIP_EXPLICIT=1
      shift 2
      ;;
    --dest)
      DEST_DIR="$2"
      shift 2
      ;;
    --update)
      UPDATE_FLAG=1
      shift
      ;;
    --run)
      RUN_FLAG=1
      shift
      ;;
    --no-run)
      RUN_FLAG=0
      shift
      ;;
    --phase)
      PHASE="$2"
      shift 2
      ;;
    --legacy)
      PHASE="legacy"
      shift
      ;;
    --main)
      PHASE="main"
      shift
      ;;
    --discovery)
      PHASE="discovery"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      if [[ -z "$ZIP_PATH" && -f "$1" ]]; then
        ZIP_PATH="$1"
        ZIP_EXPLICIT=1
        shift
      else
        echo "Unknown argument: $1" >&2
        usage
        exit 1
      fi
      ;;
  esac
done

if truthy "${FRAMEWORK_UPDATE:-}"; then
  UPDATE_FLAG=1
fi
if [[ -n "${FRAMEWORK_RUN:-}" ]]; then
  if truthy "${FRAMEWORK_RUN}"; then
    RUN_FLAG=1
  else
    RUN_FLAG=0
  fi
fi

OFFLINE=0
if truthy "${FRAMEWORK_OFFLINE:-}"; then
  OFFLINE=1
fi

RELEASE_TAG=""
RELEASE_ZIP_URL=""
RELEASE_VERSION=""
if [[ "$OFFLINE" -eq 0 ]]; then
  RELEASE_JSON="$(fetch_url "https://api.github.com/repos/${REPO}/releases/latest" 2>/dev/null || true)"
  if [[ -n "$RELEASE_JSON" ]]; then
    read -r RELEASE_TAG RELEASE_ZIP_URL < <(parse_release_info <<<"$RELEASE_JSON")
    if [[ -n "$RELEASE_TAG" ]]; then
      RELEASE_VERSION="${RELEASE_TAG#v}"
      if [[ "$REF_EXPLICIT" -ne 1 ]]; then
        REF="$RELEASE_TAG"
      fi
    fi
  fi
fi

ZIP_URL="${FRAMEWORK_ZIP_URL:-}"
VERSION_URL="${FRAMEWORK_VERSION_URL:-}"
ZIP_ACCEPT=""
VERSION_ACCEPT=""

if [[ -z "$ZIP_URL" && -n "$RELEASE_ZIP_URL" ]]; then
  ZIP_URL="$RELEASE_ZIP_URL"
fi

if [[ -z "$ZIP_URL" ]]; then
  if [[ -n "$TOKEN" ]]; then
    ZIP_URL="https://api.github.com/repos/${REPO}/contents/framework.zip?ref=${REF}"
    ZIP_ACCEPT="raw"
  else
    ZIP_URL="https://github.com/${REPO}/raw/${REF}/framework.zip"
  fi
fi

if [[ -z "$VERSION_URL" ]]; then
  if [[ -n "$TOKEN" ]]; then
    VERSION_URL="https://api.github.com/repos/${REPO}/contents/framework/VERSION?ref=${REF}"
    VERSION_ACCEPT="raw"
  else
    VERSION_URL="https://raw.githubusercontent.com/${REPO}/${REF}/framework/VERSION"
  fi
fi

FRAMEWORK_DIR="${DEST_DIR%/}/framework"
LOCAL_VERSION=""
REMOTE_VERSION="$RELEASE_VERSION"
ZIP_VERSION=""

if ! command -v "$PYTHON_BIN" >/dev/null 2>&1; then
  echo "Python not found: $PYTHON_BIN" >&2
  exit 1
fi

SCRIPT_DIR="$(script_dir)"
LOCAL_ZIP_PATH=""
EMBEDDED_AVAILABLE=0
SCRIPT_PATH="$SCRIPT_DIR/$(basename "${BASH_SOURCE[0]}")"
if [[ -f "$SCRIPT_DIR/framework.zip" ]]; then
  LOCAL_ZIP_PATH="$SCRIPT_DIR/framework.zip"
fi
if has_embedded_zip "$SCRIPT_PATH"; then
  EMBEDDED_AVAILABLE=1
fi

if [[ "$OFFLINE" -eq 1 && -z "$ZIP_PATH" ]]; then
  if [[ -n "$LOCAL_ZIP_PATH" ]]; then
    ZIP_PATH="$LOCAL_ZIP_PATH"
  elif [[ "$EMBEDDED_AVAILABLE" -eq 1 ]]; then
    TMP_ZIP="$(mktemp -t devframework.XXXXXX.zip)"
    cleanup_add "$TMP_ZIP"
    if extract_embedded_zip "$SCRIPT_PATH" "$TMP_ZIP"; then
      ZIP_PATH="$TMP_ZIP"
    fi
  fi
fi

if [[ -f "$FRAMEWORK_DIR/VERSION" ]]; then
  LOCAL_VERSION="$(head -n1 "$FRAMEWORK_DIR/VERSION" | tr -d '\r')"
fi

if [[ -n "$ZIP_PATH" ]]; then
  ZIP_VERSION="$(zip_version "$ZIP_PATH")"
fi

if [[ -z "$REMOTE_VERSION" && "$OFFLINE" -eq 0 ]]; then
  if REMOTE_VERSION="$(fetch_url "$VERSION_URL" "$VERSION_ACCEPT" 2>/dev/null)"; then
    REMOTE_VERSION="$(printf '%s' "$REMOTE_VERSION" | tr -d '\r' | head -n1)"
  else
    REMOTE_VERSION=""
  fi
fi

if [[ -n "$REMOTE_VERSION" && -n "$ZIP_PATH" && -n "$ZIP_VERSION" && "$ZIP_VERSION" != "$REMOTE_VERSION" && "$OFFLINE" -eq 0 ]]; then
  echo "Local zip version ($ZIP_VERSION) differs from latest ($REMOTE_VERSION). Downloading latest release."
  ZIP_PATH=""
  ZIP_VERSION=""
fi

if [[ -d "$FRAMEWORK_DIR" && "$UPDATE_FLAG" -ne 1 ]]; then
  if [[ -n "$ZIP_PATH" ]]; then
    if [[ -n "$LOCAL_VERSION" && -n "$ZIP_VERSION" && "$LOCAL_VERSION" == "$ZIP_VERSION" ]]; then
      echo "Framework is already up to date ($LOCAL_VERSION)."
      SKIP_INSTALL=1
    else
      UPDATE_FLAG=1
    fi
  fi

  if [[ -z "$ZIP_PATH" && -n "$REMOTE_VERSION" ]]; then
    if [[ -n "$LOCAL_VERSION" && "$LOCAL_VERSION" == "$REMOTE_VERSION" ]]; then
      echo "Framework is already up to date ($LOCAL_VERSION)."
      SKIP_INSTALL=1
    else
      echo "Updating framework from $LOCAL_VERSION to $REMOTE_VERSION"
      UPDATE_FLAG=1
    fi
  elif [[ -z "$ZIP_PATH" ]]; then
    echo "Framework already installed at $FRAMEWORK_DIR" >&2
    if [[ "$OFFLINE" -eq 1 ]]; then
      echo "Offline mode: skipping remote update check." >&2
    else
      echo "Remote version unknown. Re-run with --update or --zip to replace." >&2
    fi
    SKIP_INSTALL=1
  fi
fi

if [[ -d "$FRAMEWORK_DIR" && "$UPDATE_FLAG" -eq 1 ]]; then
  if [[ -n "$LOCAL_VERSION" && -n "$ZIP_VERSION" && "$LOCAL_VERSION" == "$ZIP_VERSION" ]]; then
    echo "Framework is already up to date ($LOCAL_VERSION)."
    SKIP_INSTALL=1
  elif [[ -n "$LOCAL_VERSION" && -n "$REMOTE_VERSION" && "$LOCAL_VERSION" == "$REMOTE_VERSION" ]]; then
    echo "Framework is already up to date ($LOCAL_VERSION)."
    SKIP_INSTALL=1
  fi
fi

if [[ "$SKIP_INSTALL" -ne 1 ]]; then
  DOWNLOAD_ZIP=""
  if [[ -z "$ZIP_PATH" ]]; then
    DOWNLOAD_ZIP="$(mktemp -t devframework.XXXXXX.zip)"
    cleanup_add "$DOWNLOAD_ZIP"
    if ! fetch_url "$ZIP_URL" "$ZIP_ACCEPT" > "$DOWNLOAD_ZIP"; then
      echo "Failed to download framework zip from $ZIP_URL" >&2
      if [[ -z "$TOKEN" ]]; then
        echo "If the repo is private, set FRAMEWORK_TOKEN or GITHUB_TOKEN." >&2
      fi
      if [[ -n "$LOCAL_ZIP_PATH" ]]; then
        echo "Falling back to local framework.zip ($LOCAL_ZIP_PATH)."
        ZIP_PATH="$LOCAL_ZIP_PATH"
      elif [[ "$EMBEDDED_AVAILABLE" -eq 1 ]]; then
        echo "Falling back to embedded framework.zip."
        if extract_embedded_zip "$SCRIPT_PATH" "$DOWNLOAD_ZIP"; then
          ZIP_PATH="$DOWNLOAD_ZIP"
        else
          exit 1
        fi
      else
        exit 1
      fi
    else
      ZIP_PATH="$DOWNLOAD_ZIP"
    fi
  fi

  if [[ ! -f "$ZIP_PATH" ]]; then
    echo "Missing zip: $ZIP_PATH" >&2
    exit 1
  fi

  BACKUP_DIR=""
  if [[ -d "$FRAMEWORK_DIR" && "$UPDATE_FLAG" -eq 1 ]]; then
    TS="$(date +%Y%m%d%H%M%S)"
    BACKUP_DIR="${FRAMEWORK_DIR}.backup.${TS}"
    mv "$FRAMEWORK_DIR" "$BACKUP_DIR"
  fi

  "$PYTHON_BIN" - <<'PY' "$ZIP_PATH" "$DEST_DIR"
import sys
import zipfile
from pathlib import Path

zip_path = Path(sys.argv[1]).resolve()
dest_dir = Path(sys.argv[2]).resolve()

with zipfile.ZipFile(zip_path, "r") as zf:
    zf.extractall(dest_dir)

print(f"Installed framework to {dest_dir / 'framework'}")
PY

  if [[ -n "$BACKUP_DIR" ]]; then
    for d in logs outbox review framework-review migration tasks; do
      if [[ -d "$BACKUP_DIR/$d" ]]; then
        rm -rf "$FRAMEWORK_DIR/$d"
        cp -a "$BACKUP_DIR/$d" "$FRAMEWORK_DIR/$d"
      fi
    done
    if [[ -f "$BACKUP_DIR/docs/orchestrator-run-summary.md" ]]; then
      mkdir -p "$FRAMEWORK_DIR/docs"
      cp -a "$BACKUP_DIR/docs/orchestrator-run-summary.md" "$FRAMEWORK_DIR/docs/"
    fi
    echo "Backup saved to $BACKUP_DIR"
  fi

  OUTPUT_FILES=(
    "docs/discovery/interview.md"
    "docs/tech-spec-generated.md"
    "docs/overview.md"
    "docs/plan-generated.md"
    "docs/data-inputs-generated.md"
    "docs/orchestrator-run-summary.md"
    "review/test-plan.md"
    "migration/legacy-snapshot.md"
    "migration/legacy-tech-spec.md"
    "migration/legacy-gap-report.md"
    "migration/legacy-migration-plan.md"
    "migration/legacy-risk-assessment.md"
  )

  if [[ -n "$BACKUP_DIR" ]]; then
    restore_or_reset_outputs "$FRAMEWORK_DIR" "$BACKUP_DIR"
  else
    reset_outputs "$FRAMEWORK_DIR"
  fi
fi

AGENTS_TEMPLATE="$FRAMEWORK_DIR/AGENTS.template.md"
AGENTS_FILE="$DEST_DIR/AGENTS.md"
if [[ -f "$AGENTS_TEMPLATE" ]]; then
  if [[ ! -f "$AGENTS_FILE" ]]; then
    cp -a "$AGENTS_TEMPLATE" "$AGENTS_FILE"
    echo "AGENTS.md installed to $AGENTS_FILE"
  elif grep -q "DEVFRAMEWORK:MANAGED" "$AGENTS_FILE" 2>/dev/null; then
    cp -a "$AGENTS_TEMPLATE" "$AGENTS_FILE"
    echo "AGENTS.md updated in $AGENTS_FILE"
  else
    echo "AGENTS.md already exists; leaving as-is."
  fi
fi

CURSOR_TEMPLATE="$FRAMEWORK_DIR/cursor-launcher.template.sh"
CURSOR_LAUNCHER="$DEST_DIR/cursor"
if [[ -f "$CURSOR_TEMPLATE" ]]; then
  if [[ ! -f "$CURSOR_LAUNCHER" ]]; then
    cp -a "$CURSOR_TEMPLATE" "$CURSOR_LAUNCHER"
    chmod +x "$CURSOR_LAUNCHER"
    echo "Cursor launcher installed to $CURSOR_LAUNCHER"
  elif grep -q "DEVFRAMEWORK:MANAGED" "$CURSOR_LAUNCHER" 2>/dev/null; then
    cp -a "$CURSOR_TEMPLATE" "$CURSOR_LAUNCHER"
    chmod +x "$CURSOR_LAUNCHER"
    echo "Cursor launcher updated in $CURSOR_LAUNCHER"
  else
    echo "Cursor launcher already exists; leaving as-is."
  fi
fi

RULES_SRC="$FRAMEWORK_DIR/cursor/rules"
RULES_DEST="$DEST_DIR/.cursor/rules"
if [[ -d "$RULES_SRC" ]]; then
  mkdir -p "$RULES_DEST"
  for rule in "$RULES_SRC"/*.mdc; do
    [[ -f "$rule" ]] || continue
    dest="$RULES_DEST/$(basename "$rule")"
    if [[ ! -f "$dest" ]] || grep -q "DEVFRAMEWORK:MANAGED" "$dest" 2>/dev/null; then
      cp -a "$rule" "$dest"
      echo "Cursor rule installed to $dest"
    else
      echo "Cursor rule $dest already exists; leaving as-is."
    fi
  done
fi

if [[ "$RUN_FLAG" -eq 1 ]]; then
  if ! git -C "$DEST_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Host project is not a git repo. Run 'git init' first." >&2
    exit 1
  fi

  echo "Running protocol"
  if [[ -n "$PHASE" ]]; then
    "$PYTHON_BIN" "$FRAMEWORK_DIR/tools/run-protocol.py" \
      --config "$FRAMEWORK_DIR/orchestrator/orchestrator.json" \
      --phase "$PHASE"
  else
    "$PYTHON_BIN" "$FRAMEWORK_DIR/tools/run-protocol.py" \
      --config "$FRAMEWORK_DIR/orchestrator/orchestrator.json"
  fi
  ORCH_EXIT=$?
  if [[ "$ORCH_EXIT" -ne 0 ]]; then
    exit "$ORCH_EXIT"
  fi
else
  echo "Next: install the Cursor CLI if needed (curl https://cursor.com/install -fsS | bash), run 'agent login', then run './cursor' in the project root and say \"start\"."
fi

if [[ -f "$FRAMEWORK_DIR/VERSION" ]]; then
  VERSION="$(head -n1 "$FRAMEWORK_DIR/VERSION" | tr -d '\r')"
  if [[ -n "$VERSION" ]]; then
    echo "Framework version: $VERSION"
  fi
fi

exit 0
__FRAMEWORK_ZIP_PAYLOAD_BEGIN__
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
S0/S83s6gW80oDrAlRkCJsMOrme3Yd41zckJvGrhRyDFTpv8FpsOfo4EExoHm4BOjWAixIQbS+v6
GChfIQSKieXg2bgEK8XTZBKMGMd2fR8GB3JJEiTUcYIwO2fcsC7lX7dwTag7dvYA6NAeomCvbG3Z
Cxi1giUd372i06BZzZPAgmDTMlbGyIW/cKmjRnQDgWItjfd93/hDGtmdwzbgRHsOuzMOapQhJJ/D
X4e1P0DXlfJQeykIueM3mTDWsyJIMiGGZLaoUiauv0Oebsk+q+lddOjjyGk96f4foYnU2EVP6hmx
A/oukOfwHOBg4q7DGCnGzN0zMo4XnbfoXpYQ2HNEW5IycectXHi5vUELAyYSpAvwFKJ83dZYG0G0
8ig2LmkZKn/wZfnZqqgth43RmhzsjXzvnOAYXaq+beEykJQrv3XEvNX2ykS28qrbJuv1vgZAlbxY
EpdwnBNPAqDQil73o5Ttl8mlrD302SkhxdMi0pzoZBwZTNlZC1Qv4v9tdP+x6R8Q9qm+fe5r4+8K
XVJFLdMWi0jnj82RubQWSExczHoMfFCmXzIyjxfbRKGELTVOszlBZk7VZYFuDO3/g3vkuHDQTehm
tEc7vW/hisKQOUpc98WqhmTffy9robb5oKsOvm4h8kRplH0CAwtJ+8BukDFY2Nig2hVV5E1F6Sxf
ljvhJheqPH8QP3NM3VS6kCHUTpB/eZ01I1SmWfzypDSf9Elu71r2aqgyEGHKfqQX4Nyzz7r5A1BL
AwQUAAAACADWhEhdHMwbJZkFAAB3CwAAJwAAAGZyYW1ld29yay9taWdyYXRpb24vbGVnYWN5LXRl
Y2gtc3BlYy5tZIVWW2/bNhR+7684aB/mDLbVZcMekqJA1tuCZW3WZAP2FNESbXGmSI0XJ+62/77v
HMqO3RXYS2JRFHnOdyOf0ZVeqWZLt7rp6GbQDU0+6o0OUZ88efLsGV3nMPion8zogqxvlKXXerMM
qtf3PqwprrXVyTuabE6fn34/f/7N/PS7+ekJLX0gH5pOxxRUMm5FgwrKWm2pxfrWD712iZKK60ip
Cz6vOlqZRLxsClrHKamcfF8+ViuebVV2vOQUpaxWGMcc19IQfJsbnhb04EMiFZJZqiZFeb3IrrU6
SkllAqbOpbu3WC8Z79BW0H9mEzRXFWmyDL5HWZoa3wKJGX3Uqo3jiFuaFdV7EKrHPn04epj/Eb37
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
lBmZGyXkVduSXmErnOWRUaiJzoEKE2qjxt3ocKIqk7lLenIx3voj6tfYedtbi9vgcB660eOiC+nE
0VzXFH91/gh7Z/vDP74BUEsDBBQAAAAIAPx8SF1Bo9rYKQAAACwAAAAdAAAAZnJhbWV3b3JrL2Rh
dGEvc2xjc3BfMjAyNi5jc3aryizQKc5JLi6ILyhKzc0szeWyNDEwNNMxNjXVMzEAc8yBHCM9QwMu
AFBLAwQUAAAACAD8fEhd0fVAOT4AAABAAAAAGwAAAGZyYW1ld29yay9kYXRhL2ZwbF8yMDI2LmNz
dsvILy1OzcjPSYkvzqxK1UkryInPzc8rycipBLMT8/JKE3O4DHUMjQxNdQxNTC1MuYx0DM1MjHUM
Lc2NDLgAUEsDBBQAAAAIAPx8SF0CxFjzKAAAADAAAAAmAAAAZnJhbWV3b3JrL2RhdGEvemlwX3Jh
dGluZ19tYXBfMjAyNi5jc3aryizQKUosycxLj08sSk3UKS5JLEnlsjQxMDTTCXI01HF2BHPMYRwA
UEsDBBQAAAAIAPx8SF2+iJ0eigAAAC0BAAAyAAAAZnJhbWV3b3JrL2ZyYW1ld29yay1yZXZpZXcv
ZnJhbWV3b3JrLWJ1Zy1yZXBvcnQubWTFjj0KwkAQRvucYmAbLUS0TKcQwU7UCyybMSxmnWV+YnJ7
k7XxBnaPx/vgc3Bin/BN/ISjdXDFTKxV5RycRQxhV23gHrXHeoYbDshRp4WbIbb4CgirnjrZiqXk
eVqXTDELKAFjZmotlHEzZgyK7cKHoOb70pp8NQRvUsILUyaZzSOO9c+V/b+vfABQSwMEFAAAAAgA
/HxIXSSCspySAAAA0QAAADQAAABmcmFtZXdvcmsvZnJhbWV3b3JrLXJldmlldy9mcmFtZXdvcmst
bG9nLWFuYWx5c2lzLm1kRY3NCsJADITvfYpAz+Ldm6KC4KFYXyBsYxv2J5JsFd/e3Yp6+zIzmWnh
qBjpKerhLCNsE4aXsTVN28JlThAp44AZm9VynvabQt2ERhX+zw9SY0lV7DNqpmHxObFNlWvfQVXU
YF1WJGJgshJZnF0Q52mAjOZ/4pUjp7HEO9KbaMTk6Ov1s93JlRVQkQwOZ/u0vQFQSwMEFAAAAAgA
/HxIXfi3YljrAAAA4gEAACQAAABmcmFtZXdvcmsvZnJhbWV3b3JrLXJldmlldy9idW5kbGUubWSN
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
IhSwOdF6ZnxNU5XS9fBUmdvW5HEMsjkyJuN1fnCMI50zDxubTdlYciEFCTn12fUz0WgPf4GL9OXV
HzmQm0FN8K3KRfH/D3659ybhsSYbb+sJFemZSo1SGgjugoM2LHAmDYxrup897Gqk5mCbIWU9WXU1
Q5OthtJr+CazneNtYainotkuA6WAq0ILDWOEXGXe+fDpiXsOZQDtB8uS8FYjgg9PSfH7BruUqjW4
ECNZbe1hEVCrV/bGACiCxitC2w1zcfQ1xWCCxO/mnJoplN83tnvU5Lr7AVBLAwQUAAAACAD3hEhd
4ZWQuAgBAAAYAgAAIAAAAGZyYW1ld29yay90YXNrcy9mcmFtZXdvcmstZml4Lm1knVFNa8MwDL3n
Vwh62WDJ7ruVlY6eBqWwa5VYaUwd2dhy0/37yenWlZ7GbuZJT+/DC9hhOr7AOuJIk49HWNszPASf
pI6Zn2BEzugeq2qxgDePrlqG4D6ht2dKIB5kIOiv5BYTGfB8B0c6WZqa+ciGQ5ZU1bC/zp+vr/qy
eQO0+aBg8FGa0ez/TFN/dXDIM6nIvmf51n0dkA9q3t677LwhnS8ZcjAoGuSfWtvsqChtM2sX2lZL
MhExaKOp0cHKA3uBJBgFbH+r4/wh3YplbpzvjnuwCbATe6JLjSvPBB8DsZ7blRjzh2CkkgvZgKHU
RduSaX43oNgsl34CTlYGQE0+BkcFUEuS1eMXUEsDBBQAAAAIAPeESF3G6fv14wAAAIwBAAAdAAAA
ZnJhbWV3b3JrL3Rhc2tzL2xlZ2FjeS1nYXAubWSNkEFrwzAMhe/5FYJcOoaT+64rlMFgUAa9VthK
7MWxjORQ+u8XJ1AYvewisHjve/Jr4Rt1eoNPGtHe4YQZXuEcdIKDEDrDKd5fmqZt4cQYm3eeMwpB
8QRxt2ThH7IFbqH4bT8IznRjmQCTgyGsY8Ss20tWsnYb7yPlpWhj4Pow9HMYBUvg1O9wU8h6o5ls
N7vrX61jqz2L9aRlNbGYHDFtuor/Wso/+OthRiizlOeAJ3E93qAqqc6UyiPqvESqQUeGxAWsxzQS
WHa0//TIieDiKa2aWnAtYqu4NjmEGMlBSF3zC1BLAwQUAAAACAD3hEhdw6RUHQkBAAChAQAAFQAA
AGZyYW1ld29yay90YXNrcy91aS5tZGWQQUvEMBCF7/0VA73ooduDnrzuoiyKCrroNSbTTWiSCZmU
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
ZVBLAQIUAxQAAAAIALiESF0gM3puegQAAEMJAAAcAAAAAAAAAAAAAACkgeUCAABmcmFtZXdvcmsv
QUdFTlRTLnRlbXBsYXRlLm1kUEsBAhQDFAAAAAgAS4ZIXctdylQPAAAADQAAABEAAAAAAAAAAAAA
AKSBmQcAAGZyYW1ld29yay9WRVJTSU9OUEsBAhQDFAAAAAgA/HxIXYlm3f54AgAAqAUAACEAAAAA
AAAAAAAAAKSB1wcAAGZyYW1ld29yay90ZXN0cy90ZXN0X3JlcG9ydGluZy5weVBLAQIUAxQAAAAI
ACR+SF3bUdOJtAQAAFkRAAAkAAAAAAAAAAAAAACkgY4KAABmcmFtZXdvcmsvdGVzdHMvdGVzdF9v
cmNoZXN0cmF0b3IucHlQSwECFAMUAAAACAD8fEhddpgbwNQBAABoBAAAJgAAAAAAAAAAAAAApIGE
DwAAZnJhbWV3b3JrL3Rlc3RzL3Rlc3RfcHVibGlzaF9yZXBvcnQucHlQSwECFAMUAAAACAD8fEhd
Z3sZ9lwEAACfEQAALQAAAAAAAAAAAAAApIGcEQAAZnJhbWV3b3JrL3Rlc3RzL3Rlc3RfZGlzY292
ZXJ5X2ludGVyYWN0aXZlLnB5UEsBAhQDFAAAAAgA/HxIXZwxyRkaAgAAGQUAAB4AAAAAAAAAAAAA
AKSBQxYAAGZyYW1ld29yay90ZXN0cy90ZXN0X3JlZGFjdC5weVBLAQIUAxQAAAAIAPx8SF18EkOY
wwIAAHEIAAAlAAAAAAAAAAAAAACkgZkYAABmcmFtZXdvcmsvdGVzdHMvdGVzdF9leHBvcnRfcmVw
b3J0LnB5UEsBAhQDFAAAAAgA1oRIXVHTKuFXAAAAbwAAADAAAAAAAAAAAAAAAKSBnxsAAGZyYW1l
d29yay9taWdyYXRpb24vbGVnYWN5LW1pZ3JhdGlvbi1wcm9wb3NhbC5tZFBLAQIUAxQAAAAIANaE
SF0FIY3utAEAABcDAAAkAAAAAAAAAAAAAACkgUQcAABmcmFtZXdvcmsvbWlncmF0aW9uL3JvbGxi
YWNrLXBsYW4ubWRQSwECFAMUAAAACADWhEhdJ/oggewBAABoAwAALQAAAAAAAAAAAAAApIE6HgAA
ZnJhbWV3b3JrL21pZ3JhdGlvbi9sZWdhY3ktcmlzay1hc3Nlc3NtZW50Lm1kUEsBAhQDFAAAAAgA
1oRIXcev43RjBgAAuw0AACYAAAAAAAAAAAAAAKSBcSAAAGZyYW1ld29yay9taWdyYXRpb24vbGVn
YWN5LXNuYXBzaG90Lm1kUEsBAhQDFAAAAAgA1oRIXVwy1mKHAgAAogUAAB0AAAAAAAAAAAAAAKSB
GCcAAGZyYW1ld29yay9taWdyYXRpb24vUkVBRE1FLm1kUEsBAhQDFAAAAAgA1oRIXRKI6dgFAwAA
qQUAACgAAAAAAAAAAAAAAKSB2ikAAGZyYW1ld29yay9taWdyYXRpb24vbGVnYWN5LWdhcC1yZXBv
cnQubWRQSwECFAMUAAAACADWhEhdLwlIKXkDAADSBgAALAAAAAAAAAAAAAAApIElLQAAZnJhbWV3
b3JrL21pZ3JhdGlvbi9sZWdhY3ktbWlncmF0aW9uLXBsYW4ubWRQSwECFAMUAAAACADWhEhd4APN
a0wAAABeAAAAHwAAAAAAAAAAAAAApIHoMAAAZnJhbWV3b3JrL21pZ3JhdGlvbi9hcHByb3ZhbC5t
ZFBLAQIUAxQAAAAIANaESF0Z9Sx5awIAAMUFAAAeAAAAAAAAAAAAAACkgXExAABmcmFtZXdvcmsv
bWlncmF0aW9uL3J1bmJvb2subWRQSwECFAMUAAAACADWhEhdHMwbJZkFAAB3CwAAJwAAAAAAAAAA
AAAApIEYNAAAZnJhbWV3b3JrL21pZ3JhdGlvbi9sZWdhY3ktdGVjaC1zcGVjLm1kUEsBAhQDFAAA
AAgAx4RIXceOkjNFAAAAVgAAAB8AAAAAAAAAAAAAAKSB9jkAAGZyYW1ld29yay9yZXZpZXcvcWEt
Y292ZXJhZ2UubWRQSwECFAMUAAAACAD8fEhd6VCdpL8AAACXAQAAGgAAAAAAAAAAAAAApIF4OgAA
ZnJhbWV3b3JrL3Jldmlldy9idW5kbGUubWRQSwECFAMUAAAACADHhEhdP7MzIswBAADuAwAAGgAA
AAAAAAAAAAAApIFvOwAAZnJhbWV3b3JrL3Jldmlldy9SRUFETUUubWRQSwECFAMUAAAACADHhEhd
vHVsXQoBAACMAQAAIAAAAAAAAAAAAAAApIFzPQAAZnJhbWV3b3JrL3Jldmlldy9yZXZpZXctYnJp
ZWYubWRQSwECFAMUAAAACADHhEhdvqOhkEQEAADWCAAAHQAAAAAAAAAAAAAApIG7PgAAZnJhbWV3
b3JrL3Jldmlldy90ZXN0LXBsYW4ubWRQSwECFAMUAAAACADHhEhdoJHKEJ4AAADkAAAAJgAAAAAA
AAAAAAAApIE6QwAAZnJhbWV3b3JrL3Jldmlldy9jb2RlLXJldmlldy1yZXBvcnQubWRQSwECFAMU
AAAACADHhEhdL2sHDHcAAACbAAAAIAAAAAAAAAAAAAAApIEcRAAAZnJhbWV3b3JrL3Jldmlldy90
ZXN0LXJlc3VsdHMubWRQSwECFAMUAAAACADHhEhdvNsGZ3MAAAD7AAAAHgAAAAAAAAAAAAAApIHR
RAAAZnJhbWV3b3JrL3Jldmlldy9idWctcmVwb3J0Lm1kUEsBAhQDFAAAAAgAx4RIXbswg8JgAQAA
RgMAABsAAAAAAAAAAAAAAKSBgEUAAGZyYW1ld29yay9yZXZpZXcvcnVuYm9vay5tZFBLAQIUAxQA
AAAIAMeESF1+9w+VDQEAALsBAAAbAAAAAAAAAAAAAACkgRlHAABmcmFtZXdvcmsvcmV2aWV3L2hh
bmRvZmYubWRQSwECFAMUAAAACAAWhUhdYj1cINMCAAATBQAAJwAAAAAAAAAAAAAApIFfSAAAZnJh
bWV3b3JrL2RvY3MvZGF0YS1pbnB1dHMtZ2VuZXJhdGVkLm1kUEsBAhQDFAAAAAgAHYZIXS4u1PeP
AQAAuQIAACMAAAAAAAAAAAAAAKSBd0sAAGZyYW1ld29yay9kb2NzL3JlbGVhc2UtY2hlY2tsaXN0
Lm1kUEsBAhQDFAAAAAgAFoVIXd83VEvBCQAA9hgAACMAAAAAAAAAAAAAAKSBR00AAGZyYW1ld29y
ay9kb2NzL29yY2hlc3RyYXRvci1wbGFuLm1kUEsBAhQDFAAAAAgAHYZIXeVdCC7XAAAAZAEAACAA
AAAAAAAAAAAAAKSBSVcAAGZyYW1ld29yay9kb2NzL2RhdGEtdGVtcGxhdGVzLm1kUEsBAhQDFAAA
AAgAwH1IXTihMHjXAAAAZgEAACoAAAAAAAAAAAAAAKSBXlgAAGZyYW1ld29yay9kb2NzL29yY2hl
c3RyYXRvci1ydW4tc3VtbWFyeS5tZFBLAQIUAxQAAAAIABaFSF3ZZflbZwcAAGkRAAAgAAAAAAAA
AAAAAACkgX1ZAABmcmFtZXdvcmsvZG9jcy9kZXNpZ24tcHJvY2Vzcy5tZFBLAQIUAxQAAAAIABaF
SF0HRmefzAgAABATAAAlAAAAAAAAAAAAAACkgSJhAABmcmFtZXdvcmsvZG9jcy90ZWNoLXNwZWMt
Z2VuZXJhdGVkLm1kUEsBAhQDFAAAAAgAFoVIXVDfCsPOBgAAvhAAACcAAAAAAAAAAAAAAKSBMWoA
AGZyYW1ld29yay9kb2NzL29yY2hlc3RyYXRpb24tY29uY2VwdC5tZFBLAQIUAxQAAAAIAB2GSF3P
Rhb99wIAAHAFAAAhAAAAAAAAAAAAAACkgURxAABmcmFtZXdvcmsvZG9jcy9pbnB1dHMtcmVxdWly
ZWQubWRQSwECFAMUAAAACAAWhUhdskJX9pMEAADSCQAAGQAAAAAAAAAAAAAApIF6dAAAZnJhbWV3
b3JrL2RvY3MvYmFja2xvZy5tZFBLAQIUAxQAAAAIAB2GSF1Gclg1RAIAANcDAAAeAAAAAAAAAAAA
AACkgUR5AABmcmFtZXdvcmsvZG9jcy91c2VyLXBlcnNvbmEubWRQSwECFAMUAAAACAAWhUhd2kbr
dwoEAADhBwAAGgAAAAAAAAAAAAAApIHEewAAZnJhbWV3b3JrL2RvY3Mvb3ZlcnZpZXcubWRQSwEC
FAMUAAAACAAWhUhd2DT8vYUBAABjAgAAIAAAAAAAAAAAAAAApIEGgAAAZnJhbWV3b3JrL2RvY3Mv
cGxhbi1nZW5lcmF0ZWQubWRQSwECFAMUAAAACAAdhkhdfpkbARwBAADEAQAAGwAAAAAAAAAAAAAA
pIHJgQAAZnJhbWV3b3JrL2RvY3MvdGVjaC1zcGVjLm1kUEsBAhQDFAAAAAgAHYZIXQNIgCzIAAAA
IAEAACEAAAAAAAAAAAAAAKSBHoMAAGZyYW1ld29yay9kb2NzL3RlY2gtYWRkZW5kdW0tMS5tZFBL
AQIUAxQAAAAIAB2GSF1ZzzVrjwEAAPwCAAAkAAAAAAAAAAAAAACkgSWEAABmcmFtZXdvcmsvZG9j
cy9kZWZpbml0aW9uLW9mLWRvbmUubWRQSwECFAMUAAAACAAdhkhdW6bGe8EAAAAdAQAAJAAAAAAA
AAAAAAAApIH2hQAAZnJhbWV3b3JrL2RvY3Mvb2JzZXJ2YWJpbGl0eS1wbGFuLm1kUEsBAhQDFAAA
AAgA/HxIXWlnF+l0AAAAiAAAAB0AAAAAAAAAAAAAAKSB+YYAAGZyYW1ld29yay9kYXRhL3BsYW5z
XzIwMjYuY3N2UEsBAhQDFAAAAAgA/HxIXUGj2tgpAAAALAAAAB0AAAAAAAAAAAAAAKSBqIcAAGZy
YW1ld29yay9kYXRhL3NsY3NwXzIwMjYuY3N2UEsBAhQDFAAAAAgA/HxIXdH1QDk+AAAAQAAAABsA
AAAAAAAAAAAAAKSBDIgAAGZyYW1ld29yay9kYXRhL2ZwbF8yMDI2LmNzdlBLAQIUAxQAAAAIAPx8
SF0CxFjzKAAAADAAAAAmAAAAAAAAAAAAAACkgYOIAABmcmFtZXdvcmsvZGF0YS96aXBfcmF0aW5n
X21hcF8yMDI2LmNzdlBLAQIUAxQAAAAIAPx8SF2+iJ0eigAAAC0BAAAyAAAAAAAAAAAAAACkge+I
AABmcmFtZXdvcmsvZnJhbWV3b3JrLXJldmlldy9mcmFtZXdvcmstYnVnLXJlcG9ydC5tZFBLAQIU
AxQAAAAIAPx8SF0kgrKckgAAANEAAAA0AAAAAAAAAAAAAACkgcmJAABmcmFtZXdvcmsvZnJhbWV3
b3JrLXJldmlldy9mcmFtZXdvcmstbG9nLWFuYWx5c2lzLm1kUEsBAhQDFAAAAAgA/HxIXfi3Yljr
AAAA4gEAACQAAAAAAAAAAAAAAKSBrYoAAGZyYW1ld29yay9mcmFtZXdvcmstcmV2aWV3L2J1bmRs
ZS5tZFBLAQIUAxQAAAAIAPeESF0C8UDYLwEAADUCAAAkAAAAAAAAAAAAAACkgdqLAABmcmFtZXdv
cmsvZnJhbWV3b3JrLXJldmlldy9SRUFETUUubWRQSwECFAMUAAAACAD8fEhdzjhxGV8AAABxAAAA
MAAAAAAAAAAAAAAApIFLjQAAZnJhbWV3b3JrL2ZyYW1ld29yay1yZXZpZXcvZnJhbWV3b3JrLWZp
eC1wbGFuLm1kUEsBAhQDFAAAAAgA94RIXU8RtSt5AQAAzAMAACUAAAAAAAAAAAAAAKSB+I0AAGZy
YW1ld29yay9mcmFtZXdvcmstcmV2aWV3L3J1bmJvb2subWRQSwECFAMUAAAACAAkfkhdWSRqT8oG
AADzEQAAHwAAAAAAAAAAAAAApIG0jwAAZnJhbWV3b3JrL3Rvb2xzL3J1bi1wcm90b2NvbC5weVBL
AQIUAxQAAAAIACR+SF2fHJSSJAIAAAkEAAAgAAAAAAAAAAAAAADtgbuWAABmcmFtZXdvcmsvdG9v
bHMvY3Vyc29yLXJ1bm5lci5zaFBLAQIUAxQAAAAIACR+SF3tTs/G/QAAAMsBAAAZAAAAAAAAAAAA
AACkgR2ZAABmcmFtZXdvcmsvdG9vbHMvUkVBRE1FLm1kUEsBAhQDFAAAAAgAK4ZIXQhsaQwLDQAA
HyUAACUAAAAAAAAAAAAAAKSBUZoAAGZyYW1ld29yay90b29scy9nZW5lcmF0ZS1hcnRpZmFjdHMu
cHlQSwECFAMUAAAACAD8fEhdoQHW7TcJAABnHQAAIAAAAAAAAAAAAAAA7YGfpwAAZnJhbWV3b3Jr
L3Rvb2xzL2V4cG9ydC1yZXBvcnQucHlQSwECFAMUAAAACAD8fEhdx4napSUHAABXFwAAIQAAAAAA
AAAAAAAA7YEUsQAAZnJhbWV3b3JrL3Rvb2xzL3B1Ymxpc2gtcmVwb3J0LnB5UEsBAhQDFAAAAAgA
/HxIXReyuCwiCAAAvB0AACEAAAAAAAAAAAAAAKSBeLgAAGZyYW1ld29yay90b29scy9wcm90b2Nv
bC13YXRjaC5weVBLAQIUAxQAAAAIACR+SF3qFJ/R6wcAAEIaAAAlAAAAAAAAAAAAAACkgdnAAABm
cmFtZXdvcmsvdG9vbHMvaW50ZXJhY3RpdmUtcnVubmVyLnB5UEsBAhQDFAAAAAgA94RIXaBc2gop
AQAA2gEAABwAAAAAAAAAAAAAAKSBB8kAAGZyYW1ld29yay90YXNrcy9kYi1zY2hlbWEubWRQSwEC
FAMUAAAACAD3hEhdW3QHlEABAABLAgAAHgAAAAAAAAAAAAAApIFqygAAZnJhbWV3b3JrL3Rhc2tz
L3Jldmlldy1wcmVwLm1kUEsBAhQDFAAAAAgA94RIXeGVkLgIAQAAGAIAACAAAAAAAAAAAAAAAKSB
5ssAAGZyYW1ld29yay90YXNrcy9mcmFtZXdvcmstZml4Lm1kUEsBAhQDFAAAAAgA94RIXcbp+/Xj
AAAAjAEAAB0AAAAAAAAAAAAAAKSBLM0AAGZyYW1ld29yay90YXNrcy9sZWdhY3ktZ2FwLm1kUEsB
AhQDFAAAAAgA94RIXcOkVB0JAQAAoQEAABUAAAAAAAAAAAAAAKSBSs4AAGZyYW1ld29yay90YXNr
cy91aS5tZFBLAQIUAxQAAAAIAPeESF0G6zmpFgEAAL8BAAAfAAAAAAAAAAAAAACkgYbPAABmcmFt
ZXdvcmsvdGFza3MvbGVnYWN5LWF1ZGl0Lm1kUEsBAhQDFAAAAAgA94RIXZ+EhKoCAQAA9wEAAB8A
AAAAAAAAAAAAAKSB2dAAAGZyYW1ld29yay90YXNrcy9sZWdhY3ktYXBwbHkubWRQSwECFAMUAAAA
CAD3hEhdnEXy42YBAADoAgAAGQAAAAAAAAAAAAAApIEY0gAAZnJhbWV3b3JrL3Rhc2tzL3Jldmll
dy5tZFBLAQIUAxQAAAAIAPeESF2lx9uu4wAAAN8BAAAoAAAAAAAAAAAAAACkgbXTAABmcmFtZXdv
cmsvdGFza3MvbGVnYWN5LW1pZ3JhdGlvbi1wbGFuLm1kUEsBAhQDFAAAAAgA94RIXQ5cmC5lAQAA
qQIAABwAAAAAAAAAAAAAAKSB3tQAAGZyYW1ld29yay90YXNrcy90ZXN0LXBsYW4ubWRQSwECFAMU
AAAACAD3hEhdAyy0vDYBAADhAgAAIwAAAAAAAAAAAAAApIF91gAAZnJhbWV3b3JrL3Rhc2tzL2Zy
YW1ld29yay1yZXZpZXcubWRQSwECFAMUAAAACAAdhkhdjLg8Tw4HAAARDwAAHAAAAAAAAAAAAAAA
pIH01wAAZnJhbWV3b3JrL3Rhc2tzL2Rpc2NvdmVyeS5tZFBLAQIUAxQAAAAIAPeESF1Z2VawFAEA
AL0BAAAhAAAAAAAAAAAAAACkgTzfAABmcmFtZXdvcmsvdGFza3MvYnVzaW5lc3MtbG9naWMubWRQ
SwECFAMUAAAACAD3hEhdWkd9f9AAAABMAQAAIwAAAAAAAAAAAAAApIGP4AAAZnJhbWV3b3JrL3Rh
c2tzL2xlZ2FjeS10ZWNoLXNwZWMubWRQSwECFAMUAAAACAAkfkhd6NOLoO4fAACRiwAAJgAAAAAA
AAAAAAAA7YGg4QAAZnJhbWV3b3JrL29yY2hlc3RyYXRvci9vcmNoZXN0cmF0b3IucHlQSwECFAMU
AAAACAAkfkhdPci4QuYCAAD3EgAAKAAAAAAAAAAAAAAApIHSAQEAZnJhbWV3b3JrL29yY2hlc3Ry
YXRvci9vcmNoZXN0cmF0b3IuanNvblBLAQIUAxQAAAAIAB2GSF0W4HqrogMAAD8QAAAoAAAAAAAA
AAAAAACkgf4EAQBmcmFtZXdvcmsvb3JjaGVzdHJhdG9yL29yY2hlc3RyYXRvci55YW1sUEsBAhQD
FAAAAAgAuIRIXX7mYtLoAQAAOwMAACcAAAAAAAAAAAAAAKSB5ggBAGZyYW1ld29yay9jdXJzb3Iv
cnVsZXMvZGV2ZnJhbWV3b3JrLm1kY1BLAQIUAxQAAAAIABaFSF0KyrTszQsAAJcbAAAlAAAAAAAA
AAAAAACkgRMLAQBmcmFtZXdvcmsvZG9jcy9kaXNjb3ZlcnkvaW50ZXJ2aWV3Lm1kUEsBAhQDFAAA
AAgAHYZIXbm2fLtqAQAAKwIAAC8AAAAAAAAAAAAAAKSBIxcBAGZyYW1ld29yay9kb2NzL3JlcG9y
dGluZy9idWctcmVwb3J0LXRlbXBsYXRlLm1kUEsFBgAAAABVAFUAhRoAANoYAQAAAA==
__FRAMEWORK_ZIP_PAYLOAD_END__
