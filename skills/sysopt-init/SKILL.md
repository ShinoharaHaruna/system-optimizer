---
name: sysopt-init
description: >
  Initialize sysopt system optimizer. Gather basic system info (OS, CPU, memory,
  disk, network) and create the .sysopt/ directory structure. Use when the user
  says "/sysopt-init" or wants to initialize system monitoring.
---

# /sysopt-init — Initialize System Optimizer

**Purpose**: One-time setup. Gather system info, create `.sysopt/` directory structure.

## Project Root

`/home/cooper/Code/system-optimizer/`

## Flow

### Step 1: Check prerequisites

```bash
which jq
```

If jq is not installed: `sudo apt install jq`

### Step 2: Check if already initialized

```bash
ls .sysopt/ 2>/dev/null
```

If exists, show existing info and ask user if they want to re-initialize.

### Step 3: Create directory structure

```bash
mkdir -p .sysopt/{sysinfo,data,reports}
```

### Step 4: Gather system info

```bash
bash scripts/sysinfo.sh --json
```

This writes to `.sysopt/sysinfo/latest.json` and outputs JSON to stdout.

### Step 5: Create config.json

```bash
cat > .sysopt/config.json << 'EOF'
{
  "version": 1,
  "created_at": "<current-ISO-timestamp>",
  "defaults": {
    "log_lines": 500,
    "command_timeout": 30,
    "journal_since": "1 hour ago",
    "max_snapshots": 20
  }
}
EOF
```

### Step 6: Create empty channels.json

```bash
cat > .sysopt/channels.json << 'EOF'
{"version": 1, "channels": []}
EOF
```

### Step 7: Present system summary

Display from `sysinfo/latest.json`:
- Hostname, OS, Kernel, Uptime
- CPU model and cores
- Memory total/used/available
- Disk usage
- Network interfaces

### Step 8: Suggest next steps

```
Ready to collect system data.

Next steps:
- /sysopt-autoreg  — Register common log channels
- /sysopt-reg      — Register custom channels
- /sysopt-update   — Collect data and analyze
```
