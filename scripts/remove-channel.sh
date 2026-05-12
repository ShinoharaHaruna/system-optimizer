#!/usr/bin/env bash
# remove-channel.sh — Remove a channel by name
# Usage: remove-channel.sh <channel-name>

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/json-utils.sh"

require_jq
require_sysopt_home
require_channels

if [[ -z "${1:-}" ]]; then
  echo "Usage: remove-channel.sh <channel-name>" >&2
  exit 1
fi

NAME="$1"
CHANNELS_FILE="$SYSOPT_HOME/channels.json"

if ! json_exists "$CHANNELS_FILE" ".channels" "name" "$NAME"; then
  echo "Error: Channel '$NAME' not found" >&2
  exit 1
fi

json_remove "$CHANNELS_FILE" ".channels" "name" "$NAME"
echo "Channel '$NAME' removed."
