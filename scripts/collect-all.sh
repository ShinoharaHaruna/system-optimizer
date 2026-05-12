#!/usr/bin/env bash
# collect-all.sh — Collect data from all enabled channels into a snapshot
# Usage: collect-all.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/json-utils.sh"

require_jq
require_sysopt_home
require_channels

CHANNELS_FILE="$SYSOPT_HOME/channels.json"

# Check for enabled channels
ENABLED_COUNT=$(jq '[.channels[] | select(.enabled == true)] | length' "$CHANNELS_FILE")
if [[ "$ENABLED_COUNT" -eq 0 ]]; then
  echo "No enabled channels. Run /sysopt-autoreg to register common channels." >&2
  exit 2
fi

# Create snapshot directory
SNAPSHOT_ID=$(date +%Y-%m-%dT%H-%M-%S)
SNAPSHOT_DIR="$SYSOPT_HOME/data/$SNAPSHOT_ID"
mkdir -p "$SNAPSHOT_DIR"

echo "Starting snapshot: $SNAPSHOT_ID"
echo "Channels to collect: $ENABLED_COUNT"
echo ""

START_TIME=$(date +%s%N)
SUCCESS_COUNT=0
FAIL_COUNT=0
FAILED_CHANNELS="[]"

# Collect each enabled channel
while IFS= read -r name; do
  echo -n "  Collecting '$name'... "
  if bash "$SCRIPT_DIR/collect.sh" "$name" "$SNAPSHOT_DIR" 2>/tmp/sysopt-err.$$; then
    echo "OK"
    SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
  else
    EXIT_CODE=$?
    ERROR_MSG=$(cat /tmp/sysopt-err.$$ 2>/dev/null || echo "Unknown error")
    echo "FAILED ($ERROR_MSG)"
    FAIL_COUNT=$((FAIL_COUNT + 1))
    FAILED_CHANNELS=$(echo "$FAILED_CHANNELS" | jq --arg n "$name" --arg e "$ERROR_MSG" \
      '. + [{"name": $n, "error": $e}]')
  fi
done < <(jq -r '.channels[] | select(.enabled == true) | .name' "$CHANNELS_FILE")

END_TIME=$(date +%s%N)
DURATION_MS=$(( (END_TIME - START_TIME) / 1000000 ))
DURATION_SEC=$(awk "BEGIN {printf \"%.1f\", $DURATION_MS/1000}")

# Write snapshot metadata
NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)
HOSTNAME=$(hostname)
OS_NAME=$(cat /etc/os-release 2>/dev/null | grep ^PRETTY_NAME | cut -d= -f2 | tr -d '"' || echo "Unknown")
KERNEL=$(uname -r)

cat > "$SNAPSHOT_DIR/_metadata.json" <<EOF
{
  "snapshot_id": "$SNAPSHOT_ID",
  "collected_at": "$NOW",
  "duration_seconds": $DURATION_SEC,
  "channels_attempted": $ENABLED_COUNT,
  "channels_succeeded": $SUCCESS_COUNT,
  "channels_failed": $FAIL_COUNT,
  "failed_channels": $FAILED_CHANNELS,
  "system_info": {
    "hostname": "$HOSTNAME",
    "os": "$OS_NAME",
    "kernel": "$KERNEL"
  }
}
EOF

# Prune old snapshots
MAX_SNAPSHOTS=$(jq -r '.defaults.max_snapshots // 20' "$SYSOPT_HOME/config.json" 2>/dev/null || echo 20)
SNAPSHOT_DIRS=($(ls -dt "$SYSOPT_HOME/data"/*/ 2>/dev/null))
if [[ ${#SNAPSHOT_DIRS[@]} -gt $MAX_SNAPSHOTS ]]; then
  echo ""
  echo "Pruning old snapshots (keeping $MAX_SNAPSHOTS)..."
  for dir in "${SNAPSHOT_DIRS[@]:$MAX_SNAPSHOTS}"; do
    rm -rf "$dir"
    echo "  Removed: $(basename "$dir")"
  done
fi

echo ""
echo "=== Snapshot Complete ==="
echo "ID:        $SNAPSHOT_ID"
echo "Duration:  ${DURATION_SEC}s"
echo "Success:   $SUCCESS_COUNT"
echo "Failed:    $FAIL_COUNT"
echo "Location:  $SNAPSHOT_DIR"

if [[ $FAIL_COUNT -gt 0 ]]; then
  echo ""
  echo "Failed channels:"
  echo "$FAILED_CHANNELS" | jq -r '.[] | "  - \(.name): \(.error)"'
fi

exit $(( FAIL_COUNT > 0 ? 1 : 0 ))
