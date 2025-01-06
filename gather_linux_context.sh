#!/usr/bin/env bash

# gather_linux_context.sh
# A script to gather detailed system information from a Linux OS instance.
# Designed for use with ChatGPT to provide context for troubleshooting or analysis.

echo "============================================================"
echo "                  CURRENT USER INFORMATION"
echo "============================================================"
echo "User (whoami): $(whoami)"
echo "Numeric UID: $(id -u)"
echo "Numeric GID: $(id -g)"
echo "Groups (current user): $(id -Gn)"  # or simply `groups`

echo ""
echo "============================================================"
echo "      FULL ABSOLUTE PATHS OF SELECTED COMMANDS/TOOLS"
echo "============================================================"

commands_to_check=(
  lsb_release
  lsusb
  lsblk
  lspci
  exportfs
  busybox
  dpkg
  dpkg-query
  rpm
  systemctl
  ps
  service
  ip
  free
  dmesg
  mount
  uname
  hostnamectl
)

for cmd in "${commands_to_check[@]}"; do
    if command -v "$cmd" >/dev/null 2>&1; then
        echo "$cmd -> $(command -v "$cmd")"
    else
        echo "$cmd -> not found"
    fi
done

echo ""
echo "============================================================"
echo "                BASIC SYSTEM INFORMATION"
echo "============================================================"
echo "---- OS Release ----"
if command -v lsb_release >/dev/null 2>&1; then
    lsb_release -a 2>/dev/null
fi
[ -f /etc/os-release ] && cat /etc/os-release
[ -f /etc/issue ] && echo "Issue file:" && cat /etc/issue

echo "---- Hostname ----"
if command -v hostnamectl >/dev/null 2>&1; then
    hostnamectl 2>/dev/null
else
    echo "Hostname: $(hostname)"
fi

echo "---- Kernel Version ----"
uname -a

echo ""
echo "============================================================"
echo "                 HARDWARE INFORMATION"
echo "============================================================"
echo "---- CPU Info ----"
if command -v lscpu >/dev/null 2>&1; then
    lscpu
else
    cat /proc/cpuinfo
fi

echo "---- Memory Info ----"
free -h

echo "---- Block Devices ----"
lsblk

echo "---- PCI Devices ----"
if command -v lspci >/dev/null 2>&1; then
    lspci
else
    echo "lspci not available."
fi

echo "---- USB Devices ----"
if command -v lsusb >/dev/null 2>&1; then
    lsusb
else
    echo "lsusb not available."
fi

echo ""
echo "============================================================"
echo "                 STORAGE INFORMATION"
echo "============================================================"
echo "---- Disk Usage (df -h) ----"
df -h

echo ""
echo "============================================================"
echo "               NETWORK CONFIGURATION"
echo "============================================================"
echo "---- IP Addresses (ip addr) ----"
ip addr show

echo "---- Routing Table (ip route) ----"
ip route show

echo "---- DNS Configuration (/etc/resolv.conf) ----"
[ -f /etc/resolv.conf ] && cat /etc/resolv.conf || echo "/etc/resolv.conf not found."

echo ""
echo "============================================================"
echo "                 NFS CONFIGURATION"
echo "============================================================"
echo "---- /etc/exports contents (if any) ----"
if [ -f /etc/exports ]; then
    cat /etc/exports
else
    echo "/etc/exports not found."
fi

if command -v exportfs >/dev/null 2>&1; then
    echo "---- exportfs -v (NFS exports) ----"
    exportfs -v
else
    echo "exportfs not available."
fi

echo ""
echo "---- Active NFS mounts ----"
mount | grep nfs || echo "No active NFS mounts found."

echo ""
echo "============================================================"
echo "                   BUSYBOX VERSION & COMMANDS"
echo "============================================================"
if command -v busybox >/dev/null 2>&1; then
    echo "BusyBox absolute path: $(command -v busybox)"
    echo "BusyBox version:"
    busybox --version
    echo ""
    echo "BusyBox supported commands (busybox --list):"
    busybox --list
else
    echo "BusyBox not found."
fi

echo ""
echo "============================================================"
echo "               INSTALLED PACKAGES / VERSIONS"
echo "============================================================"
if command -v dpkg >/dev/null 2>&1; then
    echo "---- Debian/Ubuntu based (dpkg-query for versions) ----"
    dpkg-query -W -f='${Package} ${Version}\n'
elif command -v rpm >/dev/null 2>&1; then
    echo "---- RedHat/CentOS based (rpm -qa) ----"
    rpm -qa --qf '%{NAME} %{VERSION}-%{RELEASE}\n'
else
    echo "No known package manager detected or installed."
fi

echo ""
echo "============================================================"
echo "                 RUNNING PROCESSES"
echo "============================================================"
ps aux --sort=-%mem

echo ""
echo "============================================================"
echo "               SYSTEMD SERVICES STATUS"
echo "============================================================"
if command -v systemctl >/dev/null 2>&1; then
    systemctl list-units --type=service --all
else
    echo "systemctl not available. Checking SysV services (service --status-all):"
    service --status-all 2>/dev/null || echo "No SysV init or systemd found."
fi

echo ""
echo "============================================================"
echo "                ENVIRONMENT VARIABLES"
echo "============================================================"
printenv

echo ""
echo "============================================================"
echo "                RECENT SYSTEM LOGS"
echo "============================================================"
if [ -d /var/log ]; then
    echo "---- dmesg (kernel ring buffer) ----"
    dmesg | tail -n 50

    echo ""
    echo "---- Last 50 lines of syslog (if available) ----"
    if [ -f /var/log/syslog ]; then
        tail -n 50 /var/log/syslog
    elif [ -f /var/log/messages ]; then
        tail -n 50 /var/log/messages
    else
        echo "No syslog or messages file found."
    fi
else
    echo "/var/log not found."
fi

echo ""
echo "============================================================"
echo "              END OF SYSTEM INFORMATION"
echo "============================================================"
