#!/usr/bin/env bash
# json-utils.sh — Shared JSON manipulation helpers for sysopt scripts
# Source this file: source "$(dirname "$0")/json-utils.sh"

set -euo pipefail

# Default sysopt home directory
SYSOPT_HOME="${SYSOPT_HOME:-$(cd "$(dirname "$0")/.." && pwd)/.sysopt}"

require_jq() {
  if ! command -v jq &>/dev/null; then
    echo "Error: jq is required but not installed. Install with: sudo apt install jq" >&2
    exit 1
  fi
}

require_sysopt_home() {
  if [[ ! -d "$SYSOPT_HOME" ]]; then
    echo "Error: sysopt not initialized. Run /sysopt-init first." >&2
    exit 1
  fi
}

require_channels() {
  local channels_file="$SYSOPT_HOME/channels.json"
  if [[ ! -f "$channels_file" ]]; then
    echo "Error: channels.json not found. Run /sysopt-init first." >&2
    exit 1
  fi
}

# Read a value from a JSON file
# Usage: json_get <file> <jq-expression>
json_get() {
  local file="$1"
  local expr="$2"
  jq -r "$expr" "$file"
}

# Write a value to a JSON file (atomic write via temp file)
# Usage: json_set <file> <jq-expression> <value>
json_set() {
  local file="$1"
  local expr="$2"
  local value="$3"
  local tmp="${file}.tmp.$$"
  jq "$expr = $value" "$file" > "$tmp" && mv "$tmp" "$file"
}

# Append an object to a JSON array
# Usage: json_append <file> <array-path> <json-object>
json_append() {
  local file="$1"
  local array_path="$2"
  local obj="$3"
  local tmp="${file}.tmp.$$"
  jq "$array_path += [$obj]" "$file" > "$tmp" && mv "$tmp" "$file"
}

# Remove an object from a JSON array by field value
# Usage: json_remove <file> <array-path> <field> <value>
json_remove() {
  local file="$1"
  local array_path="$2"
  local field="$3"
  local value="$4"
  local tmp="${file}.tmp.$$"
  jq "$array_path |= map(select(.$field != \"$value\"))" "$file" > "$tmp" && mv "$tmp" "$file"
}

# Check if a value exists in a JSON array
# Usage: json_exists <file> <array-path> <field> <value>
# Returns: 0 if exists, 1 if not
json_exists() {
  local file="$1"
  local array_path="$2"
  local field="$3"
  local value="$4"
  local count
  count=$(jq "$array_path | map(select(.$field == \"$value\")) | length" "$file")
  [[ "$count" -gt 0 ]]
}
