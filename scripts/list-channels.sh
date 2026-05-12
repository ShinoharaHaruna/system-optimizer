#!/usr/bin/env bash
# list-channels.sh — List registered channels
# Usage: list-channels.sh [--json] [--type <type>] [--tag <tag>] [--enabled]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/json-utils.sh"

require_jq
require_sysopt_home
require_channels

CHANNELS_FILE="$SYSOPT_HOME/channels.json"

# Parse arguments
OUTPUT_JSON=false
FILTER_TYPE=""
FILTER_TAG=""
FILTER_ENABLED=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) OUTPUT_JSON=true; shift ;;
    --type) FILTER_TYPE="$2"; shift 2 ;;
    --tag) FILTER_TAG="$2"; shift 2 ;;
    --enabled) FILTER_ENABLED=true; shift ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

# Build jq filter
JQ_FILTER=".channels"
if [[ -n "$FILTER_TYPE" ]]; then
  JQ_FILTER="$JQ_FILTER | map(select(.type == \"$FILTER_TYPE\"))"
fi
if [[ -n "$FILTER_TAG" ]]; then
  JQ_FILTER="$JQ_FILTER | map(select(.tags | index(\"$FILTER_TAG\")))"
fi
if $FILTER_ENABLED; then
  JQ_FILTER="$JQ_FILTER | map(select(.enabled == true))"
fi

if $OUTPUT_JSON; then
  jq "$JQ_FILTER" "$CHANNELS_FILE"
else
  # Human-readable table
  COUNT=$(jq "$JQ_FILTER | length" "$CHANNELS_FILE")
  if [[ "$COUNT" -eq 0 ]]; then
    echo "No channels registered. Run /sysopt-autoreg to register common channels."
    exit 0
  fi

  echo "Registered Channels ($COUNT):"
  echo "────────────────────────────────────────────────────────────────"
  printf "%-20s %-10s %-8s %-40s\n" "NAME" "TYPE" "ENABLED" "SOURCE"
  echo "────────────────────────────────────────────────────────────────"

  jq -r "$JQ_FILTER | .[] | [.name, .type, (if .enabled then \"yes\" else \"no\" end), .source] | @tsv" "$CHANNELS_FILE" | \
    while IFS=$'\t' read -r name type enabled source; do
      printf "%-20s %-10s %-8s %-40s\n" "$name" "$type" "$enabled" "$source"
    done

  echo "────────────────────────────────────────────────────────────────"
fi
