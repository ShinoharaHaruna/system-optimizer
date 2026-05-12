---
name: sysopt
description: >
  System optimization through structured data collection and LLM analysis.
  Use when the user says "sysopt", "/sysopt-init", "/sysopt-update",
  "/sysopt-reg", "/sysopt-autoreg", or asks to optimize their system,
  diagnose system issues, check system health, analyze logs for problems,
  or collect system diagnostics. Also trigger on phrases like "check my
  system", "what's wrong with my machine", "system health check",
  "collect system info", "register a log source", "monitor my system".
  Works on Linux systems with bash, jq, and standard coreutils.
---

# sysopt — System Optimizer

sysopt collects structured data from your Linux system (logs, commands, proc/sysfs)
and uses Claude Code's analysis capabilities to identify issues and suggest optimizations.

**Philosophy**: Shell scripts collect deterministic data. Claude Code analyzes it.

## Quick Reference

| Command | What it does |
|---------|-------------|
| `/sysopt-init` | Gather basic system info, create `.sysopt/` structure |
| `/sysopt-reg <name> <type> <source>` | Register a data channel |
| `/sysopt-autoreg` | Auto-register common system log channels |
| `/sysopt-update` | Collect data from all enabled channels into a snapshot |

## Prerequisites

- Linux with bash, jq, coreutils
- jq must be installed (check with `which jq`; install with `sudo apt install jq`)
- Some channels require read access to log files (may need sudo)

## Project Layout

All scripts and state are local to this project:

```
./scripts/          — Shell scripts for data collection
./references/       — Detailed command flows and analysis guides
./.sysopt/          — Runtime state (gitignored): channels, snapshots, reports
```

## Command Routing

When the user invokes a `/sysopt-*` command:

1. Check prerequisites: `which jq` must succeed
2. Route to the appropriate reference file:
   - `/sysopt-init` → read [references/cmd-init.md](references/cmd-init.md)
   - `/sysopt-update` → read [references/cmd-update.md](references/cmd-update.md)
   - `/sysopt-reg` → read [references/cmd-reg.md](references/cmd-reg.md)
   - `/sysopt-autoreg` → read [references/cmd-autoreg.md](references/cmd-autoreg.md)
3. Execute the flow described in the reference

For general system optimization requests (not a specific command):
1. Run `/sysopt-init` if `.sysopt/` doesn't exist
2. Run `/sysopt-update` to collect fresh data
3. Read the snapshot data and analyze (see [references/analysis-guide.md](references/analysis-guide.md))

## Channel Types

Brief description of each type (details in [references/channel-schema.md](references/channel-schema.md)):

- **log**: Tail a log file (last N lines, optional grep filter)
- **command**: Run a shell command and capture stdout
- **journal**: Query systemd journal with filters
- **proc**: Read a /proc filesystem entry
- **sysfs**: Read a /sys filesystem entry

## Working with Collected Data

After `/sysopt-update` completes, Claude Code should:
1. Read `_metadata.json` to understand the snapshot
2. Read each channel's `.txt` file for raw data
3. Read each channel's `.meta.json` for collection context
4. Apply analysis patterns to identify issues
5. Present a structured report to the user

For detailed analysis guidance, read [references/analysis-guide.md](references/analysis-guide.md).

## Safety Notes

- Scripts never modify system state; they only READ
- Channel registration is purely metadata (writes to `.sysopt/channels.json`)
- Data collection is non-destructive (copies/tails log data)
- No automatic remediation; all recommendations are advisory
