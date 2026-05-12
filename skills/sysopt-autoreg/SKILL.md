---
name: sysopt-autoreg
description: >
  Auto-register common system log channels (syslog, kern.log, auth.log, journal
  errors, proc entries, command outputs, etc.). Use when the user says
  "/sysopt-autoreg" or wants to quickly set up system monitoring.
---

# /sysopt-autoreg — Auto-Register Common Channels

**Purpose**: Scan the system and auto-register useful data channels.

## Project Root

`/home/cooper/Code/system-optimizer/`

## Flow

### Step 1: Check prerequisites

```bash
test -d .sysopt || echo "Run /sysopt-init first"
```

### Step 2: Scan system for available sources

```bash
bash scripts/scan-channels.sh --json
```

This probes the system and returns channel-ready JSON for ~30+ sources.

### Step 3: Filter already-registered channels

```bash
EXISTING=$(jq -r '.channels[].name' .sysopt/channels.json)
# Filter scan results to exclude existing
```

### Step 4: Present to user

```
Found 33 available channels. 28 are new (5 already registered).
Register all 28? (or pick specific ones)
```

### Step 5: Register approved channels

For each:
```bash
echo '<channel-json>' | bash scripts/add-channel.sh --stdin
```

### Step 6: Summary

```
Registered 28 new channels:
  Logs: syslog, kern-log, auth-log, dpkg-log, ...
  Journal: journal-errors, journal-warnings, cron-log, ...
  Proc: proc-meminfo, proc-cpuinfo, ...
  Command: cmd-df, cmd-free, cmd-uptime, ...

Run /sysopt-update to collect data.
```

## Available Templates

See `references/channel-templates.md` for the full list of 30+ pre-defined channels
covering logs, journal queries, proc/sysfs entries, and command outputs.
