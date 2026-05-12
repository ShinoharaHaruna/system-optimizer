# /sysopt-init — Initialize System Optimizer

**Purpose**: One-time setup. Gather system info, create `.sysopt/` directory structure.

## Flow

### Step 1: Check if already initialized

```bash
if [[ -d ".sysopt" ]]; then
  # Show existing system info
  cat .sysopt/sysinfo/latest.json | jq '{hostname, os, kernel, uptime, cpu, memory}'
  echo "sysopt already initialized. Re-run to refresh system info."
  # Offer to re-init (data/ is preserved)
fi
```

If the user confirms re-init, proceed. Otherwise stop.

### Step 2: Create directory structure

```bash
mkdir -p .sysopt/{sysinfo,data,reports}
```

### Step 3: Gather system info

```bash
bash scripts/sysinfo.sh --json
```

This writes to `.sysopt/sysinfo/latest.json` and outputs JSON.

### Step 4: Create config.json

```bash
cat > .sysopt/config.json << 'EOF'
{
  "version": 1,
  "created_at": "<current-timestamp>",
  "defaults": {
    "log_lines": 500,
    "command_timeout": 30,
    "journal_since": "1 hour ago",
    "max_snapshots": 20
  }
}
EOF
```

### Step 5: Create empty channels.json

```bash
cat > .sysopt/channels.json << 'EOF'
{"version": 1, "channels": []}
EOF
```

### Step 6: Present system summary

Read `.sysopt/sysinfo/latest.json` and display:
- Hostname, OS, Kernel
- CPU model and cores
- Memory total/used/available
- Disk usage (all mounts)
- Network interfaces

### Step 7: Suggest next steps

```
Ready to collect system data.

Next steps:
- Run /sysopt-autoreg to register common log channels
- Run /sysopt-reg to register custom channels
- Run /sysopt-update to collect data and analyze
```
