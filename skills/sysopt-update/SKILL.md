---
name: sysopt-update
description: >
  Collect data from all registered sysopt channels into a timestamped snapshot,
  then analyze for system issues. Use when the user says "/sysopt-update" or
  wants to refresh system diagnostics data.
---

# /sysopt-update — Collect Data and Analyze

**Purpose**: Collect data from all registered channels, generate a snapshot, and analyze.

## Project Root

`/home/cooper/Code/system-optimizer/`

## Flow

### Step 1: Check prerequisites

```bash
# Ensure initialized
test -d .sysopt || echo "Run /sysopt-init first"

# Ensure channels exist
jq '.channels | length' .sysopt/channels.json
```

If no channels, suggest `/sysopt-autoreg`.

### Step 2: Run collection

```bash
bash scripts/collect-all.sh
```

This creates `.sysopt/data/<timestamp>/` with:
- `_metadata.json` — Snapshot summary
- `<channel>.txt` — Raw data per channel
- `<channel>.meta.json` — Collection metadata per channel

### Step 3: Present collection summary

Read `_metadata.json` and show:
- Snapshot ID, duration
- Channels succeeded vs failed
- Any errors

### Step 4: Analyze collected data

Ask user: "Would you like me to analyze this data?"

If yes:
1. Read `references/analysis-guide.md` for analysis patterns
2. Read `_metadata.json` for context
3. Read each channel's `.txt` and `.meta.json`
4. Cross-reference channels for correlated issues
5. Present structured health report:

```
## System Health Report — <timestamp>

### Summary
<one-line assessment>

### Findings
#### Critical
- ...
#### Warnings
- ...
#### Informational
- ...

### Recommendations
1. <actionable recommendation with command>
2. ...

### Data Sources Used
- <channel>: <what it contributed>
```

### Step 5: Save report (optional)

Write to `.sysopt/reports/<timestamp>.md`
