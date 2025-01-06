#!/usr/bin/env bash

# gather_linux_context.sh
# A modular script to gather detailed system information from a Linux OS instance.
# Designed for use with ChatGPT to provide context for troubleshooting or analysis.

global version="1.0.0"
global verbose_output=false

# Function to show help message
show_help() {
  echo "Usage: $0 [options]"
  echo ""
  echo "Options:"
  echo "  -u  Collect current user information"
  echo "  -c  Collect full absolute paths of selected commands/tools"
  echo "  -s  Collect basic system information"
  echo "  -H  Collect hardware information"
  echo "  -M  Collect kernel modules and drivers information"
  echo "  -V  Detect virtualization"
  echo "  -B  Collect system boot and shutdown history"
  echo "  -t  Collect storage information"
  echo "  -n  Collect network configuration"
  echo "  -f  Collect NFS configuration"
  echo "  -b  Collect BusyBox information"
  echo "  -p  Collect installed packages"
  echo "  -r  Collect running processes"
  echo "  -v  Collect systemd services status"
  echo "  -e  Collect environment variables"
  echo "  -l  Collect recent system logs"
  echo "  -D  Collect Docker information"
  echo "  -P  Collect Python information"
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

# Collect system boot and shutdown history
collect_boot_shutdown_history() {
  echo "============================================================"
  echo "              SYSTEM BOOT & SHUTDOWN HISTORY"
  echo "============================================================"

  echo "---- Recent Reboots ----"
  last reboot

  if command -v systemd-analyze >/dev/null 2>&1; then
    echo ""
    echo "---- Boot Performance Details ----"
    systemd-analyze --no-stream blame
  else
    echo "systemd-analyze not available."
  fi

  echo
  echo "============================================================"
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

  echo
  echo "============================================================"
}

collect_docker_info() {
  echo "============================================================"
  echo "                      DOCKER INFORMATION"
  echo "============================================================"

  # Check if Docker is installed
  if ! command -v docker >/dev/null 2>&1; then
    echo "Docker is not installed or not in the system's PATH."
    echo "============================================================"
    return
  fi

  echo
  echo "---- Docker Version ----"
  echo
  docker --version

  echo
  echo "---- Docker Info ----"
  echo
  docker info || echo "Failed to retrieve Docker information."

  echo
  echo "---- Docker Images ----"
  echo
  docker images || echo "Failed to list Docker images."

  echo
  echo "---- Docker Containers (Running) ----"
  echo
  docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Status}}" || echo "Failed to list running containers."

  echo
  echo "---- Docker Containers (All) ----"
  echo
  docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Status}}" || echo "Failed to list all containers."

  echo
  echo "---- Docker Networks ----"
  echo
  docker network ls || echo "Failed to list Docker networks."

  echo
  echo "---- Docker Volumes ----"
  echo
  docker volume ls || echo "Failed to list Docker volumes."

  echo
  echo "============================================================"
}

collect_modules_drivers_info() {
  echo "============================================================"
  echo "              KERNEL MODULES AND DRIVERS INFORMATION"
  echo "============================================================"

  # 1. Collect loaded modules with lsmod (if available)
  echo "----- Kernel Modules (lsmod) -----"
  if command -v lsmod &>/dev/null; then
    echo "Collecting loaded modules via lsmod..."
    lsmod
  else
    echo "lsmod not found. Cannot list currently loaded modules."
    echo "Warning: lsmod is not installed or not in PATH."
  fi

  # 2. If modinfo is available, probe some critical modules
  echo -e "\n----- Critical Modules Info (modinfo) -----"
  if command -v modinfo &>/dev/null; then
    # Define a list of critical modules (modify as needed)
    local critical_modules=("ext4" "e1000e" "iwlwifi" "nvidia" "amdgpu" "xfs" "zfs" "btrfs" "nouveau")
    local critical_modules=("acpi_cpufreq" "af_packet" "ahci" "alx" "amdgpu" "asus_laptop" "ath" "ath9k" "ath9k_common" "ath9k_hw" "bnep" "bluetooth" "btrfs" "ccm" "cdrom" "cfg80211" "cifs" "cp210x" "crc16" "crc32c_intel" "cryptd" "crypto_user" "dm_crypt" "dm_mirror" "dm_mod" "dm_region_hash" "drm" "drm_kms_helper" "e1000e" "ext4" "fuse" "gf128mul" "ghash_clmulni_intel" "hid" "hid_generic" "hid_logitech" "i2c_piix4" "i915" "input_leds" "intel_cstate" "intel_powerclamp" "intel_rapl_msr" "ip_tables" "ipt_MASQUERADE" "iwldvm" "iwlwifi" "joydev" "jbd2" "kvm" "kvm_intel" "ledtrig_audio" "libata" "lp" "lpc_ich" "mac80211" "md4" "md_mod" "mei" "mei_hdcp" "mei_me" "msr" "mousedev" "mxm_wmi" "nouveau" "nvidia" "parport" "parport_pc" "pcbc" "psmouse" "rfcomm" "rtsx_pci" "rtsx_pci_sdmmc" "scsi_mod" "sd_mod" "serio_raw" "sha256_generic" "snd" "snd_hda_codec" "snd_hda_codec_hdmi" "snd_hda_codec_realtek" "snd_hda_core" "snd_hda_intel" "snd_hwdep" "snd_intel_dspcfg" "snd_pcm" "snd_seq" "snd_seq_device" "snd_timer" "soundcore" "sr_mod" "uas" "usbhid" "usb_storage" "uvcvideo" "video" "wacom" "wl" "x86_pkg_temp_thermal" "xfs" "zfs")

    echo "Probing critical modules with modinfo..."
    for module in "${critical_modules[@]}"; do
#      echo "Module: $module"
      # Execute modinfo; if the module isn't found, it will display an error
      # if verbose_output is enabled, run this command:
      if [ "$verbose_output" = true ]; then
        modinfo "$module" 2>&1 || echo "Module $module not found."
      else
        if modinfo "$module" >/dev/null 2>&1; then
          module_status="Module $module exists."
          if lsmod | grep -q "^$module"; then
            module_status="$module_status Loaded."
          else
            module_status="$module_status Not loaded."
          fi
          module_path=$(modinfo -n "$module")
          echo "$module_status Path: $module_path"
        else
          echo "Module $module not found."
        fi
      fi

#      echo
    done
  else
    echo "modinfo not found. Skipping probing of critical modules."
    echo "Warning: modinfo is not installed or not in PATH."
  fi

  echo
  echo "============================================================"
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

  echo
  echo "============================================================"
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

  echo
  echo "============================================================"
}

# Collect storage information
collect_storage_info() {
  echo "============================================================"
  echo "                 STORAGE INFORMATION"
  echo "============================================================"
  echo "---- Disk Usage (df -h) ----"
  df -h



  echo
  echo "============================================================"
}

collect_network_info() {
  echo "============================================================"
  echo "                     NETWORK CONFIGURATION"
  echo "============================================================"

  echo
  echo "---- IP Addresses (ip addr) ----"
  echo
  ip addr show

  echo
  echo "---- Routing Table (ip route) ----"
  echo
  ip route show

  echo
  echo "---- DNS Configuration (/etc/resolv.conf) ----"
  echo
  if [ -f /etc/resolv.conf ]; then
    cat /etc/resolv.conf
  else
    echo "/etc/resolv.conf not found."
  fi

  echo
  echo "---- Firewall Status ----"
  echo
  if command -v firewall-cmd >/dev/null 2>&1; then
    echo "FirewallD Status:"
    firewall-cmd --state 2>/dev/null || echo "FirewallD is not running."
  elif command -v ufw >/dev/null 2>&1; then
    echo "UFW Status (Uncomplicated Firewall):"
    ufw status 2>/dev/null || echo "UFW is not running."
  elif command -v iptables >/dev/null 2>&1; then
    echo "iptables Status:"
    iptables -L -n -v 2>/dev/null || echo "iptables is not running or no rules are configured or run script as root."
  else
    echo "No recognized firewall management tool found (e.g., FirewallD, UFW, iptables)."
  fi

  echo
  echo "============================================================"
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

  echo
  echo "============================================================"
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

  echo
  echo "============================================================"
}


collect_system_update_status() {
  echo "=== Checking System Update Status ==="

  # Detect which package manager is available
  if command -v apt-get &>/dev/null; then
    # Debian/Ubuntu-based systems
    echo "Detected apt-get (Debian/Ubuntu-based)."
    echo "Refreshing package index..."
    sudo apt-get update -qq

    # Check for upgradable packages (simulate upgrade, count lines).
    local updates
    updates=$(apt-get --just-print upgrade 2>/dev/null | grep -c '^Inst ')
    if [ "$updates" -gt 0 ]; then
      echo "There are $updates packages that can be upgraded."
      echo "System is behind in terms of updates."
    else
      echo "System appears up to date."
    fi

  elif command -v dnf &>/dev/null; then
    # Fedora or newer RHEL/CentOS (dnf-based)
    echo "Detected dnf (Fedora/RHEL/CentOS)."
    echo "Refreshing package index..."
    sudo dnf check-update -q &>/dev/null
    local return_code=$?

    # dnf check-update exits with:
    # 100 if there are packages to update
    # 0 if there are no packages to update
    if [ "$return_code" -eq 100 ]; then
      echo "System is behind in terms of updates (dnf check-update found packages)."
    else
      echo "System appears up to date."
    fi

  elif command -v yum &>/dev/null; then
    # Older RHEL/CentOS (yum-based)
    echo "Detected yum (RHEL/CentOS)."
    echo "Refreshing package index..."
    sudo yum check-update -q &>/dev/null
    local return_code=$?

    # yum check-update returns:
    # 100 if there are updates
    # 0 if none are available
    if [ "$return_code" -eq 100 ]; then
      echo "System is behind in terms of updates (yum check-update found packages)."
    else
      echo "System appears up to date."
    fi

  elif command -v pacman &>/dev/null; then
    # Arch Linux and derivatives
    echo "Detected pacman (Arch Linux)."
    echo "Refreshing package index..."
    sudo pacman -Sy --noconfirm &>/dev/null

    # List of outdated packages
    local outdated
    outdated=$(pacman -Qu 2>/dev/null)
    if [ -n "$outdated" ]; then
      echo "Outdated packages detected:"
      echo "$outdated"
      echo "System is behind in terms of updates."
    else
      echo "System appears up to date."
    fi

  elif command -v zypper &>/dev/null; then
    # openSUSE / SUSE Linux Enterprise
    echo "Detected zypper (openSUSE/SLE)."
    echo "Refreshing package index..."
    sudo zypper refresh -q &>/dev/null

    # Check for available updates
    local updates
    updates=$(zypper list-updates 2>/dev/null | grep -v 'Loading repository data...' | grep -vcE 'Repository|Name|No updates found')
    if [ "$updates" -gt 0 ]; then
      echo "There are $updates packages that can be upgraded."
      echo "System is behind in terms of updates."
    else
      echo "System appears up to date."
    fi

  else
    # If we reach here, we didn't detect a known package manager
    echo "No recognized package manager found (apt, dnf, yum, pacman, zypper)."
    echo "Cannot determine update status."
  fi

  echo "=== Update Status Check Complete ==="
}


collect_installed_packages() {
  echo "============================================================"
  echo "               INSTALLED PACKAGES / VERSIONS"
  echo "============================================================"

  if command -v apt &>/dev/null; then
    # Debian/Ubuntu (APT)
    echo "---- Debian/Ubuntu (APT) ----"
    # apt list --installed can be noisy, so you may want to filter or adjust formatting
    apt list --installed 2>/dev/null

  elif command -v dpkg-query &>/dev/null; then
    # Fallback for Debian/Ubuntu-based systems without 'apt'
    echo "---- Debian/Ubuntu (dpkg-query) ----"
    dpkg-query -W -f='${Package} ${Version}\n'

  elif command -v dnf &>/dev/null; then
    # Fedora / newer RHEL/CentOS (DNF)
    echo "---- Fedora/RHEL/CentOS (DNF) ----"
    dnf list installed 2>/dev/null

  elif command -v yum &>/dev/null; then
    # Older RHEL/CentOS (YUM)
    echo "---- RHEL/CentOS (YUM) ----"
    yum list installed 2>/dev/null

  elif command -v pacman &>/dev/null; then
    # Arch Linux / derivatives (Pacman)
    echo "---- Arch/Manjaro (Pacman) ----"
    pacman -Q

  elif command -v zypper &>/dev/null; then
    # openSUSE / SLE (Zypper)
    echo "---- openSUSE/SLE (Zypper) ----"
    zypper search --installed-only

  elif command -v rpm &>/dev/null; then
    # Generic RPM-based fallback
    echo "---- RPM-based system (rpm -qa) ----"
    rpm -qa --qf '%{NAME} %{VERSION}-%{RELEASE}\n'

  else
    echo "No known package manager detected or installed."
  fi

  echo
  echo "============================================================"
}


# Collect running processes
collect_processes() {
  echo "============================================================"
  echo "                 RUNNING PROCESSES"
  echo "============================================================"
  ps aux --sort=-%mem

  echo
  echo "============================================================"
}


collect_python_info() {
  echo "============================================================"
  echo "                 PYTHON INFO COLLECTION"
  echo "============================================================"

  # List of potential Python interpreters to check
  local python_interpreters=(
    python
    python2
    python3
    python3.6
    python3.7
    python3.8
    python3.9
    python3.10
    python3.11
    python3.12
    python3.13
  )

  # Check each interpreter
  for interpreter in "${python_interpreters[@]}"; do
    if command -v "$interpreter" &>/dev/null; then
      echo "Found interpreter: $interpreter"

      # Get Python version
      local version
      version=$("$interpreter" --version 2>&1)
      echo "  Version: $version"

      # Check pip availability for this interpreter
      if "$interpreter" -m pip --version &>/dev/null; then
        local pip_cmd="$interpreter -m pip"
        echo "  pip version: $($pip_cmd --version 2>&1)"

#        echo "  Main installed packages (first 10 lines of pip list):"
#        # Show the first 10 lines of pip list
#        $pip_cmd list --disable-pip-version-check 2>&1 | head -n 11
      else
        echo "  pip is not available for $interpreter"
      fi

      # Check if venv module is available in Python
      if "$interpreter" -m venv -h &>/dev/null; then
        echo "  venv module is available in Python."
      else
        echo "  venv module is not available in Python."
      fi

      echo
    fi
  done

#  # Check if virtualenv is installed
#  echo "Checking virtualenv..."
#  if command -v virtualenv &>/dev/null; then
#    echo "  virtualenv is installed: $(virtualenv --version)"
#  else
#    echo "  virtualenv is not installed."
#  fi

  echo
  echo "============================================================"
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
  echo
  echo "============================================================"
}

detect_virtualization_status() {
  echo "============================================================"
  echo "               VIRTUALIZATION DETECTION"
  echo "============================================================"

  # 1. Attempt to detect using systemd-detect-virt
  if command -v systemd-detect-virt &>/dev/null; then
    echo "-> systemd-detect-virt:"
    systemd-detect-virt
  else
    echo "systemd-detect-virt is not installed or not in PATH."
  fi

  echo

  # 2. Attempt to detect using virt-what
  if command -v virt-what &>/dev/null; then
    echo "-> virt-what:"
    virt-what
  else
    echo "virt-what is not installed or not in PATH."
  fi

  echo

  # 3. Check /proc/cpuinfo for hypervisor or virtualization flags
  echo "-> Checking /proc/cpuinfo for hypervisor or virtualization flags..."
  if grep -Eqi '^flags\s*:.*(vmx|svm)' /proc/cpuinfo; then
    echo "CPU virtualization support (vmx/svm) detected."
  else
    echo "No CPU virtualization flags (vmx or svm) found in /proc/cpuinfo."
  fi

  if grep -Eiq 'hypervisor' /proc/cpuinfo; then
    echo "Hypervisor flags found in /proc/cpuinfo."
  else
    echo "No hypervisor flags found in /proc/cpuinfo."
  fi

  echo
  echo "============================================================"
}


#!/usr/bin/env bash

collect_environment_variables() {
  echo "============================================================"
  echo "             FILTERED ENVIRONMENT VARIABLES"
  echo "============================================================"

  # A curated list of common environment variables which typically do not
  # contain sensitive information. Remove or add variables as needed.
  # (Listed ~ 100, but adjust to your preference).
  local safe_vars=(
    # Shell & user-related
    "USER"
    "HOME"
    "SHELL"
    "TERM"
    "HOSTNAME"
    "LOGNAME"
    "LANG"
    "LANGUAGE"
    "LC_ALL"
    "PWD"
    "OLDPWD"

    # Paths & directories
    "PATH"
    "MANPATH"
    "LD_LIBRARY_PATH"
    "LD_PRELOAD"
    "PWD"
    "TMPDIR"

    # Editors & tools
    "EDITOR"
    "VISUAL"
    "BROWSER"
    "PAGER"
    "COLORTERM"

    # Session & desktop environment
    "DISPLAY"
    "DESKTOP_SESSION"
    "XDG_SESSION_TYPE"
    "XDG_SESSION_DESKTOP"
    "XDG_SESSION_CLASS"
    "XDG_CURRENT_DESKTOP"
    "XDG_RUNTIME_DIR"
    "XDG_CONFIG_DIRS"
    "XDG_DATA_DIRS"
    "GNOME_DESKTOP_SESSION_ID"
    "GNOME_SHELL_SESSION_MODE"
    "GDMSESSION"

    # Misc common variables
    "HISTCONTROL"
    "HISTFILE"
    "HISTSIZE"
    "HISTFILESIZE"
    "PROMPT_COMMAND"
    "SHLVL"
    "TERM_PROGRAM"
    "TERM_PROGRAM_VERSION"
    "COLORS"
    "COLUMNS"
    "LINES"
    "PS1"
    "PS2"
    "PS4"
    "TZ"

    # Python/Java/Node, etc.
    "PYTHONPATH"
    "PYTHONDONTWRITEBYTECODE"
    "PYTHONUNBUFFERED"
    "JAVA_HOME"
    "JRE_HOME"
    "NODE_ENV"
    "NODE_PATH"

    # Network & proxy
    "HTTP_PROXY"
    "HTTPS_PROXY"
    "NO_PROXY"
    "FTP_PROXY"
    "RSYNC_PROXY"

    # Misc development / build
    "C_INCLUDE_PATH"
    "CPLUS_INCLUDE_PATH"
    "PKG_CONFIG_PATH"
    "GOPATH"
    "GOROOT"
    "RUSTUP_HOME"
    "CARGO_HOME"

    # AWS / Cloud config (keys/credentials excluded intentionally)
    "AWS_REGION"
    "AWS_DEFAULT_REGION"
    "GOOGLE_CLOUD_PROJECT"
    "AZURE_SUBSCRIPTION_ID"

    # Docker / Container
    "DOCKER_HOST"
    "DOCKER_CERT_PATH"
    "DOCKER_TLS_VERIFY"

    # Git
    "GIT_AUTHOR_NAME"
    "GIT_AUTHOR_EMAIL"
    "GIT_SSH_COMMAND"
    "GIT_EDITOR"

    # Misc version control or CI
    "CI"
    "CONTINUOUS_INTEGRATION"

    # Add more variables here as desired...
  )

  # Loop through the "safe" variables and print them if set
  for var in "${safe_vars[@]}"; do
    # Check if the variable is set
    if [ -n "${!var+x}" ]; then
      echo "$var=${!var}"
    fi
  done

  echo
  echo "============================================================"
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
    echo "---- Last 50 lines of syslog or messages (if available) ----"
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
  echo "---- Recent logs from journalctl ----"
  if command -v journalctl >/dev/null 2>&1; then
    journalctl -n 50 --no-pager
  else
    echo "journalctl not found on this system."
  fi

  echo
  echo "============================================================"
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
  local collect_docker=false
  local collect_boot_shutdown=false
  local collect_modules_drivers=false
  local detect_virtualization=false
  local collect_python=false
  local collect_system_update=false

  local check_sudo_opt=false

  # Parse command line options
  while getopts "ucsHtnfbprvelDAhBMVPU" opt; do
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
      D) collect_docker=true ;;
      A) collect_all=true ;;
      B) collect_boot_shutdown=true ;;
      M) collect_modules_drivers=true ;;
      V) detect_virtualization=true ;;
      P) collect_python=true ;;
      U) collect_system_update=true ;;
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
    collect_docker=true
    collect_boot_shutdown=true
    collect_modules_drivers=true
    detect_virtualization=true
    collect_python=true
    collect_system_update=true
  fi

  # Run functions based on flags
  [ "$collect_user" = true ] && collect_user_info
  [ "$collect_command_paths" = true ] && collect_command_paths
  [ "$collect_system" = true ] && collect_system_info
  [ "$collect_boot_shutdown" = true ] && collect_boot_shutdown_history
  [ "$collect_hardware" = true ] && collect_hardware_info
  [ "$collect_modules_drivers" = true ] && collect_modules_drivers_info
  [ "$detect_virtualization" = true ] && detect_virtualization_status
  [ "$collect_storage" = true ] && collect_storage_info
  [ "$collect_network" = true ] && collect_network_info
  [ "$collect_nfs" = true ] && collect_nfs_info
  [ "$collect_busybox" = true ] && collect_busybox_info
  [ "$collect_packages" = true ] && collect_installed_packages
  [ "$collect_processes" = true ] && collect_processes
  [ "$collect_services" = true ] && collect_services_status
  [ "$collect_env" = true ] && collect_environment_variables
  [ "$collect_logs" = true ] && collect_system_logs
  [ "$collect_docker" = true ] && collect_docker_info
  [ "$collect_python" = true ] && collect_python_info
  [ "$collect_system_update" = true ] && collect_system_update_status


  echo ""
  echo "============================================================"
  echo "              END OF SYSTEM INFORMATION"
  echo "============================================================"
}

# Run the main function
main "$@"
