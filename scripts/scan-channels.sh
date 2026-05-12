#!/usr/bin/env bash
# scan-channels.sh — Scan system for available data sources
# Usage: scan-channels.sh [--json]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/json-utils.sh"

require_jq

OUTPUT_JSON=false
if [[ "${1:-}" == "--json" ]]; then
  OUTPUT_JSON=true
fi

CHANNELS="[]"

# Helper to add a channel to the list
add_channel() {
  local name="$1" type="$2" source="$3" desc="$4" tags="$5"
  CHANNELS=$(echo "$CHANNELS" | jq \
    --arg n "$name" --arg t "$type" --arg s "$source" \
    --arg d "$desc" --arg tg "$tags" \
    '. + [{
      "name": $n,
      "type": $t,
      "source": $s,
      "description": $d,
      "tags": ($tg | split(",")),
      "enabled": true,
      "options": {}
    }]')
}

# === Log files ===
scan_log() {
  local path="$1" name="$2" desc="$3" tags="$4"
  if [[ -r "$path" ]]; then
    add_channel "$name" "log" "$path" "$desc" "$tags"
  fi
}

scan_log "/var/log/syslog"       "syslog"      "System log — kernel, services, applications" "core,system"
scan_log "/var/log/kern.log"     "kern-log"    "Kernel messages" "core,kernel"
scan_log "/var/log/auth.log"     "auth-log"    "Authentication events" "security"
scan_log "/var/log/dpkg.log"     "dpkg-log"    "Package install/remove history" "packages"
scan_log "/var/log/apt/history.log" "apt-history" "APT operations" "packages"
scan_log "/var/log/apt/term.log" "apt-term"    "APT terminal output" "packages"
scan_log "/var/log/boot.log"     "boot-log"    "Boot messages" "boot"
scan_log "/var/log/ufw.log"      "ufw-log"     "Firewall events" "security"
scan_log "/var/log/nginx/error.log" "nginx-error" "Nginx errors" "web"
scan_log "/var/log/mysql/error.log" "mysql-error" "MySQL errors" "database"
scan_log "/var/log/postgresql/postgresql-*-main.log" "pg-log" "PostgreSQL logs" "database"

# === Journal queries ===
scan_journal() {
  local unit="$1" name="$2" desc="$3" tags="$4" source="$5"
  if command -v journalctl &>/dev/null; then
    # Check if the unit exists in journal
    if journalctl -u "$unit" -n 1 --no-pager &>/dev/null 2>&1; then
      add_channel "$name" "journal" "$source" "$desc" "$tags"
    fi
  fi
}

scan_journal_any() {
  local name="$1" desc="$2" tags="$3" source="$4"
  if command -v journalctl &>/dev/null; then
    add_channel "$name" "journal" "$source" "$desc" "$tags"
  fi
}

scan_journal "cron"    "cron-log"    "Cron job execution" "cron" "unit=cron"
scan_journal "docker"  "docker-logs" "Docker daemon logs" "containers" "unit=docker"
scan_journal "sshd"    "sshd-log"    "SSH daemon logs" "security" "unit=sshd"
scan_journal "nginx"   "nginx-journal" "Nginx via journal" "web" "unit=nginx"
scan_journal "mysql"   "mysql-journal" "MySQL via journal" "database" "unit=mysql"

scan_journal_any "journal-errors"   "Systemd error-level messages" "core,errors" "priority=3"
scan_journal_any "journal-warnings" "Systemd warning-level messages" "core,warnings" "priority=4"

# === Proc filesystem ===
scan_proc() {
  local path="$1" name="$2" desc="$3" tags="$4"
  if [[ -r "/proc/$path" ]]; then
    add_channel "$name" "proc" "$path" "$desc" "$tags"
  fi
}

scan_proc "meminfo"     "proc-meminfo"     "Memory information" "core,memory"
scan_proc "cpuinfo"     "proc-cpuinfo"     "CPU information" "core,cpu"
scan_proc "loadavg"     "proc-loadavg"     "Load average" "core,cpu"
scan_proc "diskstats"   "proc-diskstats"   "Disk I/O statistics" "core,disk"
scan_proc "net/dev"     "proc-net-dev"     "Network interface statistics" "core,network"
scan_proc "vmstat"      "proc-vmstat"      "Virtual memory statistics" "core,memory"
scan_proc "stat"        "proc-stat"        "CPU and system statistics" "core,cpu"

# === Sysfs ===
scan_sysfs() {
  local path="$1" name="$2" desc="$3" tags="$4"
  if [[ -r "/sys/$path" ]]; then
    add_channel "$name" "sysfs" "$path" "$desc" "$tags"
  fi
}

# Scan thermal zones
for zone in /sys/class/thermal/thermal_zone*/temp; do
  if [[ -r "$zone" ]]; then
    zone_name=$(basename "$(dirname "$zone")")
    scan_sysfs "class/thermal/$zone_name/temp" "sys-$zone_name" "Temperature sensor: $zone_name" "thermal"
  fi
done

# === Command outputs ===
scan_command() {
  local cmd="$1" name="$2" desc="$3" tags="$4"
  # Check if the command exists
  local base_cmd=$(echo "$cmd" | awk '{print $1}')
  if command -v "$base_cmd" &>/dev/null; then
    add_channel "$name" "command" "$cmd" "$desc" "$tags"
  fi
}

scan_command "df -h"                        "cmd-df"                "Disk space usage" "core,disk"
scan_command "free -h"                      "cmd-free"              "Memory usage summary" "core,memory"
scan_command "uptime"                       "cmd-uptime"            "Uptime and load" "core"
scan_command "ip -brief addr"              "cmd-ip-addr"           "Network interfaces" "core,network"
scan_command "systemctl --failed"           "cmd-systemctl-failed"  "Failed systemd services" "core,errors"
scan_command "ps aux --sort=-%cpu | head -20" "cmd-top-procs"      "Top processes by CPU" "core,cpu"
scan_command "dmesg --time-format=iso | tail -100" "cmd-dmesg-tail" "Recent kernel messages" "core,kernel"
scan_command "ss -tuln"                     "cmd-ss"                "Listening ports" "network"
scan_command "docker ps -a"                 "cmd-docker-ps"         "Docker containers" "containers"
scan_command "iostat -x 1 1"               "cmd-iostat"            "Disk I/O stats" "disk"

# Output results
TOTAL=$(echo "$CHANNELS" | jq 'length')

if $OUTPUT_JSON; then
  echo "$CHANNELS" | jq '.'
else
  echo "Scanned system for available data sources."
  echo ""
  echo "Found $TOTAL available channels:"
  echo "────────────────────────────────────────────────────────────────"
  printf "%-20s %-10s %-40s\n" "NAME" "TYPE" "DESCRIPTION"
  echo "────────────────────────────────────────────────────────────────"

  echo "$CHANNELS" | jq -r '.[] | [.name, .type, .description] | @tsv' | \
    while IFS=$'\t' read -r name type desc; do
      printf "%-20s %-10s %-40s\n" "$name" "$type" "$desc"
    done

  echo "────────────────────────────────────────────────────────────────"
  echo "Run /sysopt-autoreg to register these channels."
fi
