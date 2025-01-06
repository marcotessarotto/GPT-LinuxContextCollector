#!/usr/bin/env bash

# gather_linux_context.sh
# A modular script to gather detailed system information from a Linux OS instance.
# Designed for use with ChatGPT to provide context for troubleshooting or analysis.

# Function to show help message
show_help() {
  echo "Usage: $0 [options]"
  echo ""
  echo "Options:"
  echo "  -u  Collect current user information"
  echo "  -c  Collect full absolute paths of selected commands/tools"
  echo "  -s  Collect basic system information"
  echo "  -H  Collect hardware information"
  echo "  -t  Collect storage information"
  echo "  -n  Collect network configuration"
  echo "  -f  Collect NFS configuration"
  echo "  -b  Collect BusyBox information"
  echo "  -p  Collect installed packages"
  echo "  -r  Collect running processes"
  echo "  -v  Collect systemd services status"
  echo "  -e  Collect environment variables"
  echo "  -l  Collect recent system logs"
  echo "  -A  Collect all information"
  echo "  -h  Show this help message"
}

# Check if the script is run as sudo or prompt the user
check_sudo() {
  if [ "$EUID" -ne 0 ]; then
    echo "This script should ideally be run as root to collect all possible information."
    read -p "Do you want to elevate privileges and re-run the script? (y/n): " answer
    if [ "$answer" = "y" ]; then
      echo "Re-running script with sudo..."
      exec sudo bash "$0" "$@"
    else
      echo "Proceeding without elevated privileges. Some information may be unavailable."
    fi
  fi
}

# Function to run commands with optional sudo
run_command_as_su() {
  local cmd="$1"
  echo "---- Running: $cmd ----"
  if [ "$EUID" -ne 0 ]; then
    if command -v sudo >/dev/null 2>&1; then
      sudo bash -c "$cmd"
    else
      echo "sudo not available, skipping: $cmd"
    fi
  else
    bash -c "$cmd"
  fi
}

# Collect current user information
collect_user_info() {
  echo "============================================================"
  echo "                  CURRENT USER INFORMATION"
  echo "============================================================"
  echo "User (whoami): $(whoami)"
  echo "Numeric UID: $(id -u)"
  echo "Numeric GID: $(id -g)"
  echo "Groups (current user): $(id -Gn)"
  echo "Home directory: $HOME"
  echo "Current shell: $SHELL"

}

# Collect absolute paths of commands/tools
collect_command_paths() {
  echo "============================================================"
  echo "      FULL ABSOLUTE PATHS OF SELECTED COMMANDS/TOOLS"
  echo "============================================================"

  local commands_to_check=(
    apt
    bash
    busybox
    dmesg
    dpkg
    dpkg-query
    exportfs
    free
    gzip
    hostnamectl
    ip
    lsblk
    lsb_release
    lspci
    lsusb
    mount
    ps
    rpm
    service
    su
    sudo
    systemctl
    tar
    uname
    xz
  )

  for cmd in "${commands_to_check[@]}"; do
    if command -v "$cmd" >/dev/null 2>&1; then
      echo "$cmd -> $(command -v "$cmd")"
    else
      echo "$cmd -> not found"
    fi
  done
}

# Collect basic system information
collect_system_info() {
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

  # check if kernel headers are installed
  if [ -d /usr/src/linux-headers-$(uname -r) ]; then
    echo "Kernel headers are installed. Path: /usr/src/linux-headers-$(uname -r)"
  else
    echo "Kernel headers are not installed."
  fi

  # output contents of /etc/shells, if the file exists
  if [ -f /etc/shells ]; then
    echo "---- /etc/shells ----"
    cat /etc/shells
  fi
}

# Collect hardware information
collect_hardware_info() {
  echo "============================================================"
  echo "                 HARDWARE INFORMATION"
  echo "============================================================"
  echo "---- CPU Info ----"
  if command -v lscpu >/dev/null 2>&1; then
    lscpu | grep -E 'Model name|CPU\(s\)|MHz'
  else
    grep -E 'model name|cpu cores|cpu MHz' /proc/cpuinfo | uniq
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
}

# Collect storage information
collect_storage_info() {
  echo "============================================================"
  echo "                 STORAGE INFORMATION"
  echo "============================================================"
  echo "---- Disk Usage (df -h) ----"
  df -h
}

# Collect network configuration
collect_network_info() {
  echo "============================================================"
  echo "               NETWORK CONFIGURATION"
  echo "============================================================"
  echo "---- IP Addresses (ip addr) ----"
  ip addr show

  echo "---- Routing Table (ip route) ----"
  ip route show

  echo "---- DNS Configuration (/etc/resolv.conf) ----"
  [ -f /etc/resolv.conf ] && cat /etc/resolv.conf || echo "/etc/resolv.conf not found."
}

# Collect NFS configuration
collect_nfs_info() {
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

  echo "---- Active NFS mounts ----"
  mount | grep nfs || echo "No active NFS mounts found."
}

# Collect BusyBox information
collect_busybox_info() {
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
}

# Collect installed packages
collect_installed_packages() {
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
}

# Collect running processes
collect_processes() {
  echo "============================================================"
  echo "                 RUNNING PROCESSES"
  echo "============================================================"
  ps aux --sort=-%mem
}

# Collect systemd services status
collect_services_status() {
  echo "============================================================"
  echo "               SYSTEMD SERVICES STATUS"
  echo "============================================================"
  if command -v systemctl >/dev/null 2>&1; then
    systemctl --no-pager list-units --type=service --all
  else
    echo "systemctl not available. Checking SysV services (service --status-all):"
    service --status-all 2>/dev/null || echo "No SysV init or systemd found."
  fi
}

# Collect environment variables
collect_environment_variables() {
  echo "============================================================"
  echo "                ENVIRONMENT VARIABLES"
  echo "============================================================"
  printenv
}

# Collect recent system logs
collect_system_logs() {
  echo "============================================================"
  echo "                RECENT SYSTEM LOGS"
  echo "============================================================"
  if [ -d /var/log ]; then
    echo "---- dmesg (kernel ring buffer) ----"
    run_command_as_su "dmesg | tail -n 50"

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
}

# Main function to orchestrate all tasks
main() {

  # Initialize flags
  local collect_all=false
  local collect_user=false
  local collect_command_paths=false
  local collect_system=false
  local collect_hardware=false
  local collect_storage=false
  local collect_network=false
  local collect_nfs=false
  local collect_busybox=false
  local collect_packages=false
  local collect_processes=false
  local collect_services=false
  local collect_env=false
  local collect_logs=false

  local check_sudo_opt=false

  # Parse command line options
  while getopts "ucsHtnfbprvelAh" opt; do
    case $opt in
      u) collect_user=true ;;
      c) collect_command_paths=true ;;
      s) collect_system=true ;;
      H) collect_hardware=true ;;
      t) collect_storage=true ;;
      n) collect_network=true ;;
      f) collect_nfs=true ;;
      b) collect_busybox=true ;;
      p) collect_packages=true ;;
      r) collect_processes=true ;;
      v) collect_services=true ;;
      e) collect_env=true ;;
      l) collect_logs=true ;;
      A) collect_all=true ;;
      h) show_help; exit 0 ;;
      *) show_help; exit 1 ;;
    esac
  done

  if [ "$check_sudo_opt" = true ]; then
    check_sudo
  fi

  # output a header which includes the date and time
  echo "============================================================"
  echo "              SYSTEM INFORMATION - $(date)"
  echo "============================================================"

  # If no options were provided, set collect_all to true
  if [ $OPTIND -eq 1 ]; then
    #collect_all=true
    collect_user=true
    collect_system=true
  fi

  # If collect_all flag is set, run all functions
  if [ "$collect_all" = true ]; then
    collect_user=true
    collect_command_paths=true
    collect_system=true
    collect_hardware=true
    collect_storage=true
    collect_network=true
    collect_nfs=true
    collect_busybox=true
    collect_packages=true
    collect_processes=true
    collect_services=true
    collect_env=true
    collect_logs=true
  fi

  # Run functions based on flags
  [ "$collect_user" = true ] && collect_user_info
  [ "$collect_command_paths" = true ] && collect_command_paths
  [ "$collect_system" = true ] && collect_system_info
  [ "$collect_hardware" = true ] && collect_hardware_info
  [ "$collect_storage" = true ] && collect_storage_info
  [ "$collect_network" = true ] && collect_network_info
  [ "$collect_nfs" = true ] && collect_nfs_info
  [ "$collect_busybox" = true ] && collect_busybox_info
  [ "$collect_packages" = true ] && collect_installed_packages
  [ "$collect_processes" = true ] && collect_processes
  [ "$collect_services" = true ] && collect_services_status
  [ "$collect_env" = true ] && collect_environment_variables
  [ "$collect_logs" = true ] && collect_system_logs

  echo ""
  echo "============================================================"
  echo "              END OF SYSTEM INFORMATION"
  echo "============================================================"
}

# Run the main function
main "$@"
