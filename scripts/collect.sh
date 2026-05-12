#!/usr/bin/env bash
# collect.sh — Collect data from a single channel
# Usage: collect.sh <channel-name> <output-dir>

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/json-utils.sh"

require_jq
require_sysopt_home
require_channels

if [[ -z "${1:-}" || -z "${2:-}" ]]; then
  echo "Usage: collect.sh <channel-name> <output-dir>" >&2
  exit 1
fi

NAME="$1"
OUTPUT_DIR="$2"
CHANNELS_FILE="$SYSOPT_HOME/channels.json"

# Get channel definition
CHANNEL=$(jq -r --arg name "$NAME" '.channels[] | select(.name == $name)' "$CHANNELS_FILE")
if [[ -z "$CHANNEL" ]]; then
  echo "Error: Channel '$NAME' not found" >&2
  exit 1
fi

# Parse channel fields
TYPE=$(echo "$CHANNEL" | jq -r '.type')
SOURCE=$(echo "$CHANNEL" | jq -r '.source')
ENABLED=$(echo "$CHANNEL" | jq -r '.enabled')

if [[ "$ENABLED" != "true" ]]; then
  echo "Skipping disabled channel: $NAME"
  exit 0
fi

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

OUT_FILE="$OUTPUT_DIR/${NAME}.txt"
META_FILE="$OUTPUT_DIR/${NAME}.meta.json"
START_TIME=$(date +%s%N)

collect_log() {
  local lines=$(echo "$CHANNEL" | jq -r '.options.lines // 500')
  local grep_pattern=$(echo "$CHANNEL" | jq -r '.options.grep // empty')

  if [[ ! -f "$SOURCE" ]]; then
    echo "Error: Log file not found: $SOURCE" >&2
    return 1
  fi

  if [[ ! -r "$SOURCE" ]]; then
    echo "Error: Permission denied: $SOURCE" >&2
    return 1
  fi

  if [[ -n "$grep_pattern" ]]; then
    tail -n "$lines" "$SOURCE" | grep -E "$grep_pattern" > "$OUT_FILE" 2>/dev/null || true
  else
    tail -n "$lines" "$SOURCE" > "$OUT_FILE" 2>/dev/null || true
  fi
}

collect_command() {
  local timeout=$(echo "$CHANNEL" | jq -r '.options.timeout // 30')
  timeout "$timeout" bash -c "$SOURCE" > "$OUT_FILE" 2>&1 || {
    local exit_code=$?
    if [[ $exit_code -eq 124 ]]; then
      echo "Error: Command timed out after ${timeout}s: $SOURCE" >&2
    fi
    return $exit_code
  }
}

collect_journal() {
  local since=$(echo "$CHANNEL" | jq -r '.options.since // "1 hour ago"')
  local priority=$(echo "$CHANNEL" | jq -r '.options.priority // empty')
  local lines=$(echo "$CHANNEL" | jq -r '.options.lines // 500')

  local args=("--since=$since" "-n" "$lines" "--no-pager")
  if [[ -n "$priority" ]]; then
    args+=("-p" "$priority")
  fi

  # Parse source as journalctl filters (e.g., "unit=cron" or "priority=3")
  IFS=' ' read -ra filters <<< "$SOURCE"
  for filter in "${filters[@]}"; do
    if [[ "$filter" == unit=* ]]; then
      args+=("-u" "${filter#unit=}")
    elif [[ "$filter" == priority=* ]]; then
      # Already handled above, skip duplicate
      :
    fi
  done

  journalctl "${args[@]}" > "$OUT_FILE" 2>&1 || true
}

collect_proc() {
  local proc_path="/proc/$SOURCE"
  if [[ ! -f "$proc_path" ]]; then
    echo "Error: /proc entry not found: $proc_path" >&2
    return 1
  fi
  cat "$proc_path" > "$OUT_FILE" 2>/dev/null || {
    echo "Error: Permission denied: $proc_path" >&2
    return 1
  }
}

collect_sysfs() {
  local sysfs_path="/sys/$SOURCE"
  if [[ ! -e "$sysfs_path" ]]; then
    echo "Error: /sys entry not found: $sysfs_path" >&2
    return 1
  fi
  cat "$sysfs_path" > "$OUT_FILE" 2>/dev/null || {
    echo "Error: Permission denied: $sysfs_path" >&2
    return 1
  }
}

# Execute collection based on type
COLLECTION_ERROR=""
EXIT_CODE=0

case "$TYPE" in
  log)     collect_log || EXIT_CODE=$? ;;
  command) collect_command || EXIT_CODE=$? ;;
  journal) collect_journal || EXIT_CODE=$? ;;
  proc)    collect_proc || EXIT_CODE=$? ;;
  sysfs)   collect_sysfs || EXIT_CODE=$? ;;
  *)
    echo "Error: Unknown channel type: $TYPE" >&2
    EXIT_CODE=1
    ;;
esac

if [[ $EXIT_CODE -ne 0 ]]; then
  COLLECTION_ERROR="Collection failed with exit code $EXIT_CODE"
fi

END_TIME=$(date +%s%N)
DURATION_MS=$(( (END_TIME - START_TIME) / 1000000 ))
DURATION_SEC=$(awk "BEGIN {printf \"%.2f\", $DURATION_MS/1000}")

# Calculate output stats
OUTPUT_BYTES=0
OUTPUT_LINES=0
if [[ -f "$OUT_FILE" ]]; then
  OUTPUT_BYTES=$(stat -c%s "$OUT_FILE" 2>/dev/null || echo 0)
  OUTPUT_LINES=$(wc -l < "$OUT_FILE" 2>/dev/null || echo 0)
fi

# Write metadata
NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)
cat > "$META_FILE" <<EOF
{
  "channel_name": "$NAME",
  "type": "$TYPE",
  "source": "$SOURCE",
  "collected_at": "$NOW",
  "duration_seconds": $DURATION_SEC,
  "output_bytes": $OUTPUT_BYTES,
  "output_lines": $OUTPUT_LINES,
  "exit_code": $EXIT_CODE,
  "error": $(if [[ -n "$COLLECTION_ERROR" ]]; then echo "\"$COLLECTION_ERROR\""; else echo "null"; fi)
}
EOF

# Update last_collected_at in channels.json
TMP="${CHANNELS_FILE}.tmp.$$"
jq --arg name "$NAME" --arg now "$NOW" '
  .channels |= map(if .name == $name then .last_collected_at = $now else . end)
' "$CHANNELS_FILE" > "$TMP" && mv "$TMP" "$CHANNELS_FILE"

if [[ $EXIT_CODE -ne 0 ]]; then
  echo "Collection failed for '$NAME': $COLLECTION_ERROR" >&2
  exit 2
fi

echo "Collected '$NAME': ${OUTPUT_LINES} lines, ${OUTPUT_BYTES} bytes in ${DURATION_SEC}s"
