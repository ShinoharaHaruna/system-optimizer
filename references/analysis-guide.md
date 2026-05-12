# Analysis Guide

How to interpret collected system data and generate health reports.

## General Principles

1. **Start with context**: Read `_metadata.json` first to understand what was collected, how long it took, and what failed.
2. **Check collection health**: Read `.meta.json` files — truncated output or permission errors affect analysis quality.
3. **Cross-reference**: The most valuable insights come from correlating multiple channels.
4. **Separate severity**: Distinguish critical (act now), warning (investigate soon), and informational findings.
5. **Be specific**: Recommendations should include exact commands the user can run.
6. **No auto-remediation**: All recommendations are advisory. Never run fix commands automatically.

## Per-Channel-Type Analysis

### Log Files

**Patterns to scan for:**
- `ERROR`, `FATAL`, `CRITICAL`, `WARN` — severity indicators
- Repeated identical messages — potential loops or persistent issues
- Timestamp gaps — service crashes/restarts
- `OOM`, `Out of memory`, `killed process` — OOM killer events
- `I/O error`, `filesystem`, `corruption` — disk/filesystem issues
- `segfault`, `coredump` — application crashes

**Key questions:**
- Are errors increasing over time or steady?
- Are there patterns in when errors occur?
- Do errors correlate with service restarts?

### Command Outputs

**`df -h` (disk usage):**
- Flag partitions with >80% usage
- Flag partitions with >90% usage as critical
- Check if any partition is 100% (will cause immediate failures)

**`free -h` (memory):**
- Swap usage >50% indicates memory pressure
- Available memory <10% of total is concerning
- High swap + low available = OOM risk

**`systemctl --failed`:**
- Any failed service is actionable
- Check if the service is expected to be running

**`ps aux` (processes):**
- Single process >80% CPU = CPU hog
- Single process >50% memory = memory leak candidate
- Many zombie processes = parent process issues

**`uptime` / `loadavg`:**
- 1-min load > CPU core count = system saturated
- Load consistently increasing = growing problem

### Journal Queries

**Priority 3 (errors):**
- Always worth investigating
- Look for service restart patterns (start/stop sequences)
- Check for coredumps

**Priority 4 (warnings):**
- Precursors to errors
- Deprecation warnings may indicate future breakage

### Proc Filesystem

**`/proc/meminfo`:**
- `MemAvailable / MemTotal` < 10% = memory pressure
- High `SwapUsed` with low `MemAvailable` = OOM risk
- `Dirty` memory pages > 1GB = write-heavy workload

**`/proc/loadavg`:**
- First number (1-min) > CPU cores = saturated
- Compare 1-min vs 5-min vs 15-min for trend

**`/proc/diskstats`:**
- High `io_await` (>100ms) = disk bottleneck
- Increasing error counts = hardware issue

**`/proc/vmstat`:**
- High `pswpin`/`pswpout` (swap in/out) = memory pressure
- High `pgfault` = memory contention

### Sysfs

**Thermal zones:**
- Temperature >80°C = concerning (may throttle)
- Temperature >90°C = critical (thermal shutdown risk)

## Cross-Channel Correlation

These patterns emerge from combining multiple channels:

| Pattern | Channels | Diagnosis |
|---------|----------|-----------|
| High memory + OOM messages | proc-meminfo + kern-log | OOM crisis — find the memory hog |
| High disk + I/O errors | cmd-df + kern-log | Disk failure risk — backup immediately |
| Failed services + error logs | cmd-systemctl-failed + journal-errors | Service crash debugging |
| High CPU + top processes | proc-loadavg + cmd-top-procs | CPU hog identification |
| Auth failures + SSH connections | auth-log + sshd-log | Brute force attack |
| High load + low CPU usage | proc-loadavg + proc-cpustat | I/O wait, not CPU |
| Docker issues + container logs | docker-logs + cmd-docker-ps | Container debugging |

## Report Format

```markdown
## System Health Report — <timestamp>

### Summary
<one-line overall assessment>

### Findings

#### Critical (immediate action needed)
- [Finding 1]: [Description] (Source: [channel])
- ...

#### Warnings (should investigate soon)
- [Finding 1]: [Description] (Source: [channel])
- ...

#### Informational (FYI)
- [Finding 1]: [Description] (Source: [channel])
- ...

### Recommendations
1. [Actionable recommendation with specific command]
   ```bash
   # The actual command to run
   ```
2. ...

### Data Sources Used
- [channel-name]: [what it contributed]
- ...
```

## Thresholds Reference

| Metric | Warning | Critical |
|--------|---------|----------|
| Disk usage | >80% | >95% |
| Memory available | <20% total | <10% total |
| Swap usage | >50% | >80% |
| Load average (1-min) | >CPU cores | >2x CPU cores |
| Temperature | >80°C | >90°C |
| Auth failures/hour | >10 | >100 |
| Failed services | >0 | >3 |
