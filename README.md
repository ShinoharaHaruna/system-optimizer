# sysopt — System Optimizer

A Claude Code skill suite for Linux system optimization through structured data collection and LLM analysis.

## Philosophy

Shell scripts collect deterministic data. Claude Code analyzes it.

## Commands

| Command | Description |
|---------|-------------|
| `/sysopt` | General optimization — collect data and analyze |
| `/sysopt-init` | Gather system info, create `.sysopt/` structure |
| `/sysopt-reg` | Register a custom data channel |
| `/sysopt-autoreg` | Auto-register common system log channels |
| `/sysopt-update` | Collect data from all channels, generate snapshot |
| `/sysopt-list` | List all registered channels |

## Quick Start

```bash
# Clone
git clone https://github.com/ShinoharaHaruna/system-optimizer.git
cd system-optimizer

# Install as Claude Code skill (project-local)
ln -s ../../skills/sysopt .claude/skills/sysopt
ln -s ../../skills/sysopt-init .claude/skills/sysopt-init
ln -s ../../skills/sysopt-update .claude/skills/sysopt-update
ln -s ../../skills/sysopt-reg .claude/skills/sysopt-reg
ln -s ../../skills/sysopt-autoreg .claude/skills/sysopt-autoreg
ln -s ../../skills/sysopt-list .claude/skills/sysopt-list

# In Claude Code:
/sysopt-init       # Initialize
/sysopt-autoreg    # Register common channels
/sysopt-update     # Collect and analyze
```

## Prerequisites

- Linux (bash, coreutils)
- [jq](https://stedolan.github.io/jq/) — `sudo apt install jq`
- [Claude Code](https://claude.ai/code)

## Project Structure

```
├── SKILL.md                  # Main skill entry point
├── skills/                   # Skill definitions (one per command)
│   ├── sysopt/SKILL.md
│   ├── sysopt-init/SKILL.md
│   ├── sysopt-update/SKILL.md
│   ├── sysopt-reg/SKILL.md
│   ├── sysopt-autoreg/SKILL.md
│   └── sysopt-list/SKILL.md
├── scripts/                  # Data collection shell scripts
│   ├── sysinfo.sh            # System info gathering
│   ├── collect.sh            # Single channel collection
│   ├── collect-all.sh        # Full snapshot collection
│   ├── add-channel.sh        # Channel registration
│   ├── scan-channels.sh      # System source scanner
│   └── ...
├── references/               # Analysis guides and docs
│   ├── analysis-guide.md     # How to interpret collected data
│   ├── channel-schema.md     # Channel JSON schema
│   ├── channel-templates.md  # Pre-defined channel templates
│   └── cmd-*.md              # Per-command flow docs
└── .sysopt/                  # Runtime state (gitignored)
    ├── channels.json         # Registered channels
    ├── data/<timestamp>/     # Snapshots
    └── reports/              # Analysis reports
```

## Channel Types

| Type | Source | Use Case |
|------|--------|----------|
| `log` | File path | Tail log files (syslog, kern.log, etc.) |
| `command` | Shell command | Capture command output (df, free, etc.) |
| `journal` | journalctl filter | Query systemd journal |
| `proc` | /proc path | Read proc filesystem entries |
| `sysfs` | /sys path | Read sysfs entries (thermal, etc.) |

## License

MIT
