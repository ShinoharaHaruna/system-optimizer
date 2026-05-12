#!/usr/bin/env bash
# add-channel.sh — Register a new channel
# Usage: add-channel.sh '<json-string>'
#        echo '<json>' | add-channel.sh --stdin

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/json-utils.sh"

require_jq
require_sysopt_home
require_channels

CHANNELS_FILE="$SYSOPT_HOME/channels.json"

# Read channel JSON from argument or stdin
if [[ "${1:-}" == "--stdin" ]]; then
  CHANNEL_JSON=$(cat)
elif [[ -n "${1:-}" ]]; then
  CHANNEL_JSON="$1"
else
  echo "Usage: add-channel.sh '<json-string>'" >&2
  echo "       echo '<json>' | add-channel.sh --stdin" >&2
  exit 1
fi

# Validate JSON
if ! echo "$CHANNEL_JSON" | jq empty 2>/dev/null; then
  echo "Error: Invalid JSON" >&2
  exit 1
fi

# Validate required fields
for field in name type source; do
  val=$(echo "$CHANNEL_JSON" | jq -r ".$field // empty")
  if [[ -z "$val" ]]; then
    echo "Error: Missing required field: $field" >&2
    exit 1
  fi
done

# Validate channel name (lowercase, hyphens, no spaces)
NAME=$(echo "$CHANNEL_JSON" | jq -r '.name')
if [[ ! "$NAME" =~ ^[a-z0-9][a-z0-9-]*[a-z0-9]$|^[a-z0-9]$ ]]; then
  echo "Error: Channel name must be lowercase alphanumeric with hyphens (e.g., 'syslog', 'my-log')" >&2
  exit 1
fi

# Validate channel type
TYPE=$(echo "$CHANNEL_JSON" | jq -r '.type')
if [[ ! "$TYPE" =~ ^(log|command|journal|proc|sysfs)$ ]]; then
  echo "Error: Channel type must be one of: log, command, journal, proc, sysfs" >&2
  exit 1
fi

# Check for duplicate name
if json_exists "$CHANNELS_FILE" ".channels" "name" "$NAME"; then
  echo "Error: Channel '$NAME' already exists" >&2
  exit 2
fi

# Build the complete channel object with defaults
NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)
COMPLETE_JSON=$(echo "$CHANNEL_JSON" | jq --arg now "$NOW" '
  . + {
    enabled: (.enabled // true),
    tags: (.tags // []),
    description: (.description // ""),
    options: (.options // {}),
    registered_at: $now,
    last_collected_at: null
  }
')

# Set default options based on type
TYPE=$(echo "$COMPLETE_JSON" | jq -r '.type')
case "$TYPE" in
  log)
    COMPLETE_JSON=$(echo "$COMPLETE_JSON" | jq '
      .options.lines = (.options.lines // 500) |
      .options.grep = (.options.grep // null)
    ')
    ;;
  command)
    COMPLETE_JSON=$(echo "$COMPLETE_JSON" | jq '
      .options.timeout = (.options.timeout // 30)
    ')
    ;;
  journal)
    COMPLETE_JSON=$(echo "$COMPLETE_JSON" | jq '
      .options.since = (.options.since // "1 hour ago") |
      .options.priority = (.options.priority // null) |
      .options.lines = (.options.lines // 500)
    ')
    ;;
esac

# Append to channels.json
json_append "$CHANNELS_FILE" ".channels" "$COMPLETE_JSON"

echo "Channel '$NAME' registered successfully."
