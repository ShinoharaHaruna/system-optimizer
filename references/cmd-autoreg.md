# /sysopt-autoreg — Auto-Register Common Channels

**Purpose**: Auto-register common, useful channels for a typical Linux system.

## Flow

### Step 1: Check prerequisites

```bash
if [[ ! -d ".sysopt" ]]; then
  echo "Run /sysopt-init first."
  exit 1
fi
```

### Step 2: Scan system for available sources

```bash
bash scripts/scan-channels.sh --json
```

This probes the system and returns channel-ready JSON objects for all available sources.

### Step 3: Cross-reference with existing channels

```bash
# Get names of already-registered channels
EXISTING=$(jq -r '.channels[].name' .sysopt/channels.json)

# Filter out already-registered channels
echo "$SCAN_RESULT" | jq --argjson existing "$EXISTING" '
  map(select(.name as $n | $existing | index($n) | not))
'
```

### Step 4: Present to user

```
I found 33 available channels. 28 are new (5 already registered).

Register all 28 new channels? (or pick specific ones)
```

If user wants to pick, show the list and let them select.

### Step 5: Register approved channels

For each approved channel:
```bash
echo '<channel-json>' | bash scripts/add-channel.sh --stdin
```

### Step 6: Summary

```
Registered 28 new channels:
  Logs:     syslog, kern-log, auth-log, dpkg-log, apt-history, ...
  Journal:  journal-errors, journal-warnings, cron-log, docker-logs, ...
  Proc:     proc-meminfo, proc-cpuinfo, proc-loadavg, ...
  Command:  cmd-df, cmd-free, cmd-uptime, ...

Skipped (already registered): syslog, cmd-df, ...

Run /sysopt-update to collect data from all channels.
```
