# /sysopt-reg — Register a Channel

**Purpose**: Register a new information channel for data collection.

## Flow

### Step 1: Check prerequisites

```bash
if [[ ! -d ".sysopt" ]]; then
  echo "Run /sysopt-init first."
  exit 1
fi
```

### Step 2: Parse user input

Three forms of input:

**Full form**: `/sysopt-reg syslog log /var/log/syslog`
- name=syslog, type=log, source=/var/log/syslog

**Partial form**: `/sysopt-reg syslog`
- Ask user for type and source interactively

**JSON form**: User provides full JSON object
```json
{
  "name": "my-log",
  "type": "log",
  "source": "/var/log/my-app.log",
  "description": "My application log",
  "tags": ["app"]
}
```

### Step 3: Validate channel definition

- **Name**: lowercase alphanumeric with hyphens, no spaces, unique
- **Type**: one of `log`, `command`, `journal`, `proc`, `sysfs`
- **Source**: appropriate for the type
  - `log`: file path exists and is readable
  - `command`: base command exists (check with `which`)
  - `journal`: valid journalctl expression
  - `proc`: path under /proc exists
  - `sysfs`: path under /sys exists
- **Description**: auto-generate from source path if not provided

### Step 4: Register the channel

```bash
bash scripts/add-channel.sh '<json-object>'
```

### Step 5: Confirm and suggest

```
Channel 'syslog' registered.
  Type: log
  Source: /var/log/syslog
  Description: System log — kernel, services, applications

Run /sysopt-update to collect data immediately.
```
