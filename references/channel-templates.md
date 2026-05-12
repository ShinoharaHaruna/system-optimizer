# Channel Templates

Pre-defined channel definitions for auto-registration. Used by `/sysopt-autoreg`.

## Log Files

| Name | Type | Source | Description | Tags |
|------|------|--------|-------------|------|
| `syslog` | log | `/var/log/syslog` | System log — kernel, services, applications | core, system |
| `kern-log` | log | `/var/log/kern.log` | Kernel messages | core, kernel |
| `auth-log` | log | `/var/log/auth.log` | Authentication events | security |
| `dpkg-log` | log | `/var/log/dpkg.log` | Package install/remove history | packages |
| `apt-history` | log | `/var/log/apt/history.log` | APT operations | packages |
| `apt-term` | log | `/var/log/apt/term.log` | APT terminal output | packages |
| `boot-log` | log | `/var/log/boot.log` | Boot messages | boot |
| `ufw-log` | log | `/var/log/ufw.log` | Firewall events | security |
| `nginx-error` | log | `/var/log/nginx/error.log` | Nginx errors | web |
| `mysql-error` | log | `/var/log/mysql/error.log` | MySQL errors | database |

## Journal Queries

| Name | Type | Source | Description | Tags |
|------|------|--------|-------------|------|
| `cron-log` | journal | `unit=cron` | Cron job execution | cron |
| `journal-errors` | journal | `priority=3` | Systemd error-level messages | core, errors |
| `journal-warnings` | journal | `priority=4` | Systemd warning-level messages | core, warnings |
| `docker-logs` | journal | `unit=docker` | Docker daemon logs | containers |
| `sshd-log` | journal | `unit=sshd` | SSH daemon logs | security |
| `nginx-journal` | journal | `unit=nginx` | Nginx via journal | web |
| `mysql-journal` | journal | `unit=mysql` | MySQL via journal | database |

## Proc Filesystem

| Name | Type | Source | Description | Tags |
|------|------|--------|-------------|------|
| `proc-meminfo` | proc | `meminfo` | Memory information | core, memory |
| `proc-cpuinfo` | proc | `cpuinfo` | CPU information | core, cpu |
| `proc-loadavg` | proc | `loadavg` | Load average | core, cpu |
| `proc-diskstats` | proc | `diskstats` | Disk I/O statistics | core, disk |
| `proc-net-dev` | proc | `net/dev` | Network interface statistics | core, network |
| `proc-vmstat` | proc | `vmstat` | Virtual memory statistics | core, memory |
| `proc-stat` | proc | `stat` | CPU and system statistics | core, cpu |

## Sysfs

| Name | Type | Source | Description | Tags |
|------|------|--------|-------------|------|
| `sys-thermal-zone0` | sysfs | `class/thermal/thermal_zone0/temp` | CPU temperature | thermal |

Additional thermal zones are auto-detected at scan time.

## Command Outputs

| Name | Type | Source | Description | Tags |
|------|------|--------|-------------|------|
| `cmd-df` | command | `df -h` | Disk space usage | core, disk |
| `cmd-free` | command | `free -h` | Memory usage summary | core, memory |
| `cmd-uptime` | command | `uptime` | Uptime and load | core |
| `cmd-ip-addr` | command | `ip -brief addr` | Network interfaces | core, network |
| `cmd-systemctl-failed` | command | `systemctl --failed` | Failed systemd services | core, errors |
| `cmd-top-procs` | command | `ps aux --sort=-%cpu \| head -20` | Top processes by CPU | core, cpu |
| `cmd-dmesg-tail` | command | `dmesg --time-format=iso \| tail -100` | Recent kernel messages | core, kernel |
| `cmd-ss` | command | `ss -tuln` | Listening ports | network |
| `cmd-docker-ps` | command | `docker ps -a` | Docker containers | containers |
| `cmd-iostat` | command | `iostat -x 1 1` | Disk I/O stats | disk |
