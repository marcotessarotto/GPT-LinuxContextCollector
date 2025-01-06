# GPT-LinuxContextCollector

A Bash script designed to gather detailed system information from a Linux OS instance. The collected data can be used to create a comprehensive context for reasoning and troubleshooting with ChatGPT or other AI tools.

## Features

- Collects **basic system information** (OS, kernel, hostname).
- Gathers **hardware details** (CPU, memory, block devices, PCI, and USB devices).
- Extracts **network configuration** (IP addresses, routing table, DNS settings).
- Retrieves **NFS exports, imports, and active mounts**.
- Lists **BusyBox-supported commands** and their version (if installed).
- Collects **absolute paths** of key system commands.
- Provides **current user information**, including groups, UID, and GID.
- Captures **installed packages and versions** (supports both `dpkg` and `rpm`).
- Displays **running processes** and **system logs** for troubleshooting.
- Outputs all information in a structured, human-readable format.

## Use Case

The script is designed to streamline the process of providing relevant system context for:
- Debugging and troubleshooting.
- Generating queries for AI tools like ChatGPT.
- System audits or diagnostics.

## Usage

### Prerequisites

- A Linux-based OS (Debian/Ubuntu, RedHat/CentOS, or similar).
- Bash shell.

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/marcotessarotto/GPT-LinuxContextCollector
   cd GPT-LinuxContextCollector

2. Make the script executable:
   ```bash
    chmod +x gather_linux_context.sh
3. Running the script:
   ```bash
   Execute the script to collect system information and save it to a file:

   ./gather_linux_context.sh > system_info.txt

4. Reviewing the Output

   Inspect the output of the script thoroughly to ensure completeness and accuracy. While the script does not collect user credentials, tokens, or SSH user or host keys, it is still important to review the output carefully. Redact or remove any sensitive data that might inadvertently appear before sharing the file with ChatGPT or any external party.

   **Note:** Sharing detailed information with ChatGPT may be necessary for it to address your question effectively. However, you should exercise caution and carefully evaluate what to include. Striking the right balance between providing enough context and protecting sensitive information is essential for both resolving your issue and maintaining privacy.

5. Example Output

Below is a snippet of what the output might look like:

    ============================================================
                      CURRENT USER INFORMATION
    ============================================================
    User (whoami): ubuntu
    Numeric UID: 1000
    Numeric GID: 1000
    Groups (current user): ubuntu sudo
    
    ============================================================
          FULL ABSOLUTE PATHS OF SELECTED COMMANDS/TOOLS
    ============================================================
    lsblk -> /bin/lsblk
    lspci -> /usr/bin/lspci
    busybox -> /bin/busybox
    ...
    
    ============================================================
                    BASIC SYSTEM INFORMATION
    ============================================================
    ---- OS Release ----
    NAME="Ubuntu"
    VERSION="22.04.3 LTS (Jammy Jellyfish)"
    ...
    
    ============================================================
                       BUSYBOX VERSION & COMMANDS
    ============================================================
    BusyBox absolute path: /bin/busybox
    BusyBox version:
    BusyBox v1.35.0 (Ubuntu 1:1.35.0-2ubuntu1) multi-call binary
    
    BusyBox supported commands (busybox --list):
    [ [ [[ addgroup adduser ash base64 basename ...
