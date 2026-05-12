---
name: sysopt-reg
description: >
  Register a new sysopt data channel (log file, command output, journal query,
  proc/sysfs entry). Use when the user says "/sysopt-reg" or wants to add a
  new system data source to monitor.
---

# /sysopt-reg — Register a Channel

**Purpose**: Register a new information channel for data collection.

## Project Root

`/home/cooper/Code/system-optimizer/`

## Flow

### Step 1: Check prerequisites

```bash
test -d .sysopt || echo "Run /sysopt-init first"
```

### Step 2: Parse user input

Three forms:

**Full form**: `/sysopt-reg syslog log /var/log/syslog`
→ name=syslog, type=log, source=/var/log/syslog

**Partial form**: `/sysopt-reg syslog`
→ Ask user for type and source

**JSON form**: User provides full JSON:
```json
{"name":"my-log","type":"log","source":"/var/log/my-app.log","description":"My app log","tags":["app"]}
```

### Step 3: Validate

- **Name**: lowercase alphanumeric with hyphens, unique
- **Type**: one of `log`, `command`, `journal`, `proc`, `sysfs`
- **Source**: appropriate for type (file exists for log, command exists for command, etc.)

### Step 4: Register

```bash
bash scripts/add-channel.sh '<json-object>'
```

### Step 5: Confirm

```
Channel 'syslog' registered.
  Type: log
  Source: /var/log/syslog

Run /sysopt-update to collect data.
```

## Channel Types

| Type | Source | Options |
|------|--------|---------|
| `log` | File path | `lines` (500), `grep` (optional filter) |
| `command` | Shell command | `timeout` (30s) |
| `journal` | journalctl filters | `since`, `priority`, `lines` |
| `proc` | /proc path | none |
| `sysfs` | /sys path | none |
