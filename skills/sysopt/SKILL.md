---
name: sysopt
description: >
  System optimization through structured data collection and LLM analysis.
  Use when the user asks to optimize their system, diagnose system issues,
  check system health, analyze logs for problems, collect system diagnostics,
  or says "check my system", "what's wrong with my machine", "system health check".
  For specific commands, use /sysopt-init, /sysopt-update, /sysopt-reg, /sysopt-autoreg.
---

# sysopt — System Optimizer

sysopt collects structured data from your Linux system and analyzes it for issues.

## Available Commands

| Command | What it does |
|---------|-------------|
| `/sysopt-init` | Gather basic system info, create `.sysopt/` structure |
| `/sysopt-reg` | Register a data channel |
| `/sysopt-autoreg` | Auto-register common system log channels |
| `/sysopt-update` | Collect data from all enabled channels into a snapshot |

## General Optimization Flow

When the user asks for system optimization without a specific command:

1. Check if `.sysopt/` exists in the project root. If not, suggest `/sysopt-init`.
2. Check if channels are registered. If not, suggest `/sysopt-autoreg`.
3. Run `/sysopt-update` to collect fresh data.
4. Read the analysis guide at `references/analysis-guide.md` for how to interpret data.
5. Read the snapshot data and present a structured health report.

## Project Root

All scripts and references are at the project root: `/home/cooper/Code/system-optimizer/`

- `scripts/` — Shell scripts for data collection
- `references/` — Analysis guides and command flow docs
- `.sysopt/` — Runtime state (channels, snapshots, reports)

## Safety

- Scripts only READ system state; never modify it
- Channel registration is metadata only (`.sysopt/channels.json`)
- All recommendations are advisory; no auto-remediation
