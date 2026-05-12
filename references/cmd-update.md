# /sysopt-update — Collect Data and Analyze

**Purpose**: Collect data from all registered channels into a timestamped snapshot.

## Flow

### Step 1: Check prerequisites

```bash
# Ensure sysopt is initialized
if [[ ! -d ".sysopt" ]]; then
  echo "Run /sysopt-init first."
  exit 1
fi

# Ensure channels exist
CHANNEL_COUNT=$(jq '.channels | length' .sysopt/channels.json)
if [[ "$CHANNEL_COUNT" -eq 0 ]]; then
  echo "No channels registered. Run /sysopt-autoreg first."
  exit 1
fi
```

### Step 2: Run collection

```bash
bash scripts/collect-all.sh
```

This will:
- Create a new snapshot directory under `.sysopt/data/<timestamp>/`
- Collect data from all enabled channels
- Write `_metadata.json` with summary
- Prune old snapshots if count exceeds `max_snapshots`

### Step 3: Present collection summary

Read `_metadata.json` and display:
- Snapshot ID (timestamp)
- Duration
- Channels succeeded vs failed
- Any errors

### Step 4: Analyze collected data

Ask user: "Would you like me to analyze this data?"

If yes:

1. Read `_metadata.json` to understand the snapshot context
2. For each successful channel:
   - Read `<channel>.txt` for raw data
   - Read `<channel>.meta.json` for collection context
3. Read [analysis-guide.md](analysis-guide.md) for analysis patterns
4. Apply analysis:
   - Scan for errors, warnings, anomalies
   - Cross-reference between channels
   - Check thresholds (disk >80%, memory pressure, load > cores, etc.)
5. Present findings as structured report:

```
## System Health Report — <timestamp>

### Summary
<one-line assessment: healthy / needs attention / critical issues>

### Findings

#### Critical (immediate action needed)
- ...

#### Warnings (should investigate soon)
- ...

#### Informational (FYI)
- ...

### Recommendations
1. <actionable recommendation with specific commands>
2. ...

### Data Sources Used
- <list of channels that contributed>
```

### Step 5: Save report (optional)

```bash
REPORT_FILE=".sysopt/reports/<timestamp>.md"
# Write the analysis report to file
```
