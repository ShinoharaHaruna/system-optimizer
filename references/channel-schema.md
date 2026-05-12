# Channel Schema

JSON schema for channel definitions used by sysopt.

## Channel Object

```json
{
  "name": "string (required, unique)",
  "type": "string (required)",
  "source": "string (required)",
  "description": "string (optional)",
  "tags": ["string"],
  "enabled": true,
  "options": {},
  "registered_at": "ISO-8601 timestamp",
  "last_collected_at": "ISO-8601 timestamp | null"
}
```

## Fields

### `name` (required)
- Unique identifier for the channel
- Must be lowercase alphanumeric with hyphens
- Examples: `syslog`, `kern-log`, `cmd-df`, `proc-meminfo`

### `type` (required)
One of:
- `log` — Tail a log file
- `command` — Run a shell command
- `journal` — Query systemd journal
- `proc` — Read /proc filesystem entry
- `sysfs` — Read /sys filesystem entry

### `source` (required)
Meaning depends on type:

| Type | Source value | Example |
|------|-------------|---------|
| `log` | File path | `/var/log/syslog` |
| `command` | Shell command | `df -h` |
| `journal` | Journalctl filters | `unit=cron` or `priority=3` |
| `proc` | Path under /proc | `meminfo` |
| `sysfs` | Path under /sys | `class/thermal/thermal_zone0/temp` |

### `description` (optional)
Human-readable description. Auto-generated from source if not provided.

### `tags` (optional)
Array of strings for categorization. Common tags:
- `core` — Essential system monitoring
- `system` — System-level logs
- `kernel` — Kernel-related
- `security` — Authentication, firewall
- `packages` — Package management
- `boot` — Boot process
- `network` — Network interfaces, connections
- `memory` — Memory usage
- `cpu` — CPU usage, load
- `disk` — Disk usage, I/O
- `containers` — Docker, containers
- `web` — Web servers (nginx, apache)
- `database` — Database servers
- `thermal` — Temperature sensors

### `enabled` (optional, default: true)
Whether this channel is included in data collection.

### `options` (optional)
Type-specific options:

#### Log options
```json
{
  "lines": 500,        // Number of lines to tail (default: 500)
  "grep": null          // Optional grep pattern filter
}
```

#### Command options
```json
{
  "timeout": 30         // Timeout in seconds (default: 30)
}
```

#### Journal options
```json
{
  "since": "1 hour ago", // Time window (default: "1 hour ago")
  "priority": null,       // Syslog priority 0-7 (null = all)
  "lines": 500            // Max lines (default: 500)
}
```

#### Proc/Sysfs options
No options (empty object).

### `registered_at`
ISO-8601 timestamp of when the channel was registered.

### `last_collected_at`
ISO-8601 timestamp of last data collection, or null if never collected.

## channels.json File Format

```json
{
  "version": 1,
  "channels": [
    { /* channel object */ },
    { /* channel object */ }
  ]
}
```
