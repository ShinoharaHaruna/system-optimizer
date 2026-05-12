#!/usr/bin/env bash
# sysinfo.sh — Gather basic system information
# Usage: sysinfo.sh [--json]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/json-utils.sh"

OUTPUT_JSON=false
if [[ "${1:-}" == "--json" ]]; then
  OUTPUT_JSON=true
fi

# Gather system info
HOSTNAME=$(hostname)
OS_NAME=$(cat /etc/os-release 2>/dev/null | grep ^PRETTY_NAME | cut -d= -f2 | tr -d '"' || echo "Unknown")
KERNEL=$(uname -r)
UPTIME_SEC=$(awk '{print int($1)}' /proc/uptime)
UPTIME_DAYS=$((UPTIME_SEC / 86400))
UPTIME_HOURS=$(( (UPTIME_SEC % 86400) / 3600 ))
UPTIME_MINS=$(( (UPTIME_SEC % 3600) / 60 ))

# CPU
CPU_MODEL=$(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)
CPU_CORES=$(nproc)

# Memory
MEM_TOTAL_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
MEM_AVAIL_KB=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
MEM_TOTAL_GB=$(awk "BEGIN {printf \"%.1f\", $MEM_TOTAL_KB/1048576}")
MEM_AVAIL_GB=$(awk "BEGIN {printf \"%.1f\", $MEM_AVAIL_KB/1048576}")
MEM_USED_GB=$(awk "BEGIN {printf \"%.1f\", ($MEM_TOTAL_KB - $MEM_AVAIL_KB)/1048576}")

# Swap
SWAP_TOTAL_KB=$(grep SwapTotal /proc/meminfo | awk '{print $2}')
SWAP_FREE_KB=$(grep SwapFree /proc/meminfo | awk '{print $2}')
SWAP_TOTAL_GB=$(awk "BEGIN {printf \"%.1f\", $SWAP_TOTAL_KB/1048576}")
SWAP_USED_GB=$(awk "BEGIN {printf \"%.1f\", ($SWAP_TOTAL_KB - $SWAP_FREE_KB)/1048576}")

# Load average
LOAD_AVG=$(cat /proc/loadavg | awk '{print $1, $2, $3}')

# Disk usage (all mounts)
DISK_USAGE=$(df -h --output=source,size,used,avail,pcent,target -x tmpfs -x devtmpfs -x squashfs 2>/dev/null | tail -n +2)

# Network interfaces (up)
NET_IFACES=$(ip -brief addr show up 2>/dev/null | grep -v "^lo" || echo "none")

# Top 5 processes by CPU
TOP_CPU=$(ps aux --sort=-%cpu | head -6 | tail -5)

# Top 5 processes by memory
TOP_MEM=$(ps aux --sort=-%mem | head -6 | tail -5)

if $OUTPUT_JSON; then
  # Build JSON output
  DISK_JSON=$(echo "$DISK_USAGE" | jq -R -s '
    split("\n") | map(select(length > 0)) | map(
      split(" +"; "") | {
        device: .[0],
        size: .[1],
        used: .[2],
        avail: .[3],
        use_percent: .[4],
        mount: .[5]
      }
    )
  ')

  NET_JSON=$(echo "$NET_IFACES" | jq -R -s '
    split("\n") | map(select(length > 0)) | map(
      split(" +"; "") | {
        interface: .[0],
        state: .[1],
        addresses: (.[2:] | join(" "))
      }
    )
  ')

  cat <<EOF
{
  "hostname": "$HOSTNAME",
  "os": "$OS_NAME",
  "kernel": "$KERNEL",
  "uptime": {
    "seconds": $UPTIME_SEC,
    "human": "${UPTIME_DAYS}d ${UPTIME_HOURS}h ${UPTIME_MINS}m"
  },
  "cpu": {
    "model": "$CPU_MODEL",
    "cores": $CPU_CORES
  },
  "memory": {
    "total_gb": $MEM_TOTAL_GB,
    "used_gb": $MEM_USED_GB,
    "available_gb": $MEM_AVAIL_GB
  },
  "swap": {
    "total_gb": $SWAP_TOTAL_GB,
    "used_gb": $SWAP_USED_GB
  },
  "load_average": "$LOAD_AVG",
  "disk": $DISK_JSON,
  "network": $NET_JSON,
  "collected_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF

  # Also save to sysinfo/latest.json
  mkdir -p "$SYSOPT_HOME/sysinfo"
  cat <<EOF > "$SYSOPT_HOME/sysinfo/latest.json"
{
  "hostname": "$HOSTNAME",
  "os": "$OS_NAME",
  "kernel": "$KERNEL",
  "uptime": {
    "seconds": $UPTIME_SEC,
    "human": "${UPTIME_DAYS}d ${UPTIME_HOURS}h ${UPTIME_MINS}m"
  },
  "cpu": {
    "model": "$CPU_MODEL",
    "cores": $CPU_CORES
  },
  "memory": {
    "total_gb": $MEM_TOTAL_GB,
    "used_gb": $MEM_USED_GB,
    "available_gb": $MEM_AVAIL_GB
  },
  "swap": {
    "total_gb": $SWAP_TOTAL_GB,
    "used_gb": $SWAP_USED_GB
  },
  "load_average": "$LOAD_AVG",
  "disk": $DISK_JSON,
  "network": $NET_JSON,
  "collected_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
else
  # Human-readable output
  echo "=== System Information ==="
  echo "Hostname:    $HOSTNAME"
  echo "OS:          $OS_NAME"
  echo "Kernel:      $KERNEL"
  echo "Uptime:      ${UPTIME_DAYS}d ${UPTIME_HOURS}h ${UPTIME_MINS}m"
  echo ""
  echo "=== CPU ==="
  echo "Model:       $CPU_MODEL"
  echo "Cores:       $CPU_CORES"
  echo "Load Avg:    $LOAD_AVG"
  echo ""
  echo "=== Memory ==="
  echo "Total:       ${MEM_TOTAL_GB} GB"
  echo "Used:        ${MEM_USED_GB} GB"
  echo "Available:   ${MEM_AVAIL_GB} GB"
  echo "Swap Total:  ${SWAP_TOTAL_GB} GB"
  echo "Swap Used:   ${SWAP_USED_GB} GB"
  echo ""
  echo "=== Disk ==="
  echo "$DISK_USAGE"
  echo ""
  echo "=== Network ==="
  echo "$NET_IFACES"
  echo ""
  echo "=== Top 5 by CPU ==="
  echo "$TOP_CPU"
  echo ""
  echo "=== Top 5 by Memory ==="
  echo "$TOP_MEM"
fi
