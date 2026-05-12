---
name: sysopt-list
description: >
  List all registered sysopt data channels with their name, type, source,
  and description. Use when the user says "/sysopt-list" or wants to see
  what system data sources are being monitored.
---

# /sysopt-list — List Registered Channels

**Purpose**: Show all registered channels in a readable format.

## Project Root

`/home/cooper/Code/system-optimizer/`

## Flow

### Step 1: Check prerequisites

```bash
test -d .sysopt || echo "Run /sysopt-init first"
```

### Step 2: List channels

Use a human-readable table by default:

```bash
jq -r '.channels[] | "\(.name)\t\(.type)\t\(.enabled)\t\(.description)\t\(.source)"' \
  .sysopt/channels.json | column -t -s $'\t'
```

Format: NAME | TYPE | ENABLED | DESCRIPTION | SOURCE

If user asks for JSON, use:
```bash
jq '.channels' .sysopt/channels.json
```

### Step 3: Present results

Show the table with a summary:
```
Total: N channels (M enabled, K disabled)
```

If no channels are registered, suggest `/sysopt-autoreg`.
