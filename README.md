# USB-Cleaner Pro v2.0

<div align="center">

```
╔═══════════════════════════════════════════════════════════════════════════╗
║                                                                           ║
║     ██╗   ██╗███████╗██████╗        ██████╗██╗     ███████╗ █████╗ ███╗   ║
║     ██║   ██║██╔════╝██╔══██╗      ██╔════╝██║     ██╔════╝██╔══██╗████╗  ║
║     ██║   ██║███████╗██████╔╝█████╗██║     ██║     █████╗  ███████║██╔██╗ ║
║     ██║   ██║╚════██║██╔══██╗╚════╝██║     ██║     ██╔══╝  ██╔══██║██║╚██╗║
║     ╚██████╔╝███████║██████╔╝      ╚██████╗███████╗███████╗██║  ██║██║ ╚██║
║      ╚═════╝ ╚══════╝╚═════╝        ╚═════╝╚══════╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═║
║                                                                           ║
║                    ████████████████████████████████                       ║
║                    █ SECURE USB DRIVE SANITIZER █                         ║
║                    ████████████████████████████████                       ║
║                                                                           ║
╚═══════════════════════════════════════════════════════════════════════════╝
```

**A professional-grade USB drive sanitization and management tool**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/version-2.0.0-blue.svg)](https://github.com/djeada/USB-Cleaner)
[![Bash](https://img.shields.io/badge/bash-5.0%2B-green.svg)](https://www.gnu.org/software/bash/)

</div>

---

## ✨ Features

### 🔒 Security Features
- **Multiple Wipe Methods**: Single-pass zero, Triple-pass DoD 5220.22-M, Seven-pass Gutmann, Random, and Custom patterns
- **Wipe Verification**: Automatic verification with sampling at multiple points on the drive
- **Pre-wipe Hashing**: Cryptographic hash calculation before and after wipe operations
- **Secure Random Sources**: Support for both `/dev/urandom` and `/dev/zero` data sources

### 💾 Filesystem Support
- **FAT32**: Universal compatibility (4GB file limit)
- **ext4**: Linux native with journaling
- **NTFS**: Windows compatible, large file support
- **exFAT**: Cross-platform, no file size limits
- **Btrfs**: Modern Linux with snapshots and checksums
- **XFS**: High-performance Linux filesystem

### 📊 Drive Management
- **Drive Health Monitoring**: SMART data analysis (requires `smartctl`)
- **Detailed Drive Information**: Model, vendor, serial number, capacity display
- **Partition Layout Viewer**: Visual representation of current partitions
- **GPT & MBR Support**: Both modern and legacy partition table types

### 💾 Backup & Restore
- **Compressed Backups**: gzip and xz compression options
- **Checksum Verification**: SHA256 integrity validation
- **Easy Restore**: Simple backup restoration with compression auto-detection

### 🎨 User Experience
- **Modern TUI**: Colorful terminal interface with ASCII art branding
- **Progress Indicators**: Real-time progress bars with ETA
- **Command Line Interface**: Full CLI support with options and commands
- **Configuration System**: Persistent settings saved to `~/.config/usb-cleaner/`
- **Dry Run Mode**: Preview operations without making changes
- **Desktop Notifications**: Optional notification support

### 📝 Logging
- **Structured Logging**: Text or JSON format
- **Verbose Mode**: Detailed debug output
- **Operation Timestamps**: Complete audit trail

---

## 📋 Requirements

### Operating System
- Linux-based OS (Ubuntu, Debian, CentOS, Fedora, Arch, etc.)
- Tested on Ubuntu 20.04 LTS and later

### Privileges
- Root/sudo access required for disk operations

### Dependencies
The script will automatically install missing dependencies:
- `lsblk` - Block device information
- `parted` - Partition manipulation
- `dd` - Low-level data copying
- `wipefs` - Filesystem signature removal
- `pv` - Progress viewing (optional)
- `smartctl` - SMART health monitoring (optional)
- Filesystem tools: `mkfs.vfat`, `mkfs.ext4`, `mkfs.ntfs`, `mkfs.exfat`, `mkfs.btrfs`, `mkfs.xfs`

---

## 🚀 Installation

```bash
# Clone the repository
git clone https://github.com/djeada/USB-Cleaner.git

# Navigate to the directory
cd USB-Cleaner/src

# Make executable (if needed)
chmod +x cleaner.sh

# Run the script
./cleaner.sh
```

---

## 📖 Usage

### Interactive Mode

```bash
./cleaner.sh
```

This launches the interactive menu with all options:

```
╔════════════════════════════════════════════════════════════════════╗
║                      MAIN MENU                                      ║
╠════════════════════════════════════════════════════════════════════╣
║  1) Wipe USB Drive(s)        - Secure data destruction             ║
║  2) Create Partition         - Format with new filesystem          ║
║  3) Quick Format             - Fast format (no wipe)               ║
║  4) Secure Erase             - 7-pass maximum security             ║
║  5) Drive Information        - View drive details & health         ║
║  6) Backup Drive             - Create drive image backup           ║
║  7) Restore Backup           - Restore from backup image           ║
║  8) Configuration            - Save/load settings                  ║
║  9) Help                     - Show detailed help                  ║
║  0) Exit                     - Quit program                        ║
╚════════════════════════════════════════════════════════════════════╝
```

### Command Line Interface

```bash
# Show help
./cleaner.sh --help

# Show version
./cleaner.sh --version

# Wipe with dry-run (preview only)
./cleaner.sh --dry-run wipe

# Force wipe without prompts
./cleaner.sh --force wipe

# Create partition with verbose output
./cleaner.sh --verbose partition

# View drive information
./cleaner.sh info

# Check drive health
./cleaner.sh health

# Quick format
./cleaner.sh quick-format

# Maximum security wipe
./cleaner.sh secure-erase
```

### Available Commands

| Command | Description |
|---------|-------------|
| `wipe` | Securely wipe USB drive(s) |
| `partition` | Create partition on USB drive(s) |
| `info` | Display detailed drive information |
| `health` | Check drive health (SMART data) |
| `backup` | Create backup image of USB drive |
| `restore` | Restore backup image to USB drive |
| `verify` | Verify wipe operation |
| `quick-format` | Fast format without secure wipe |
| `secure-erase` | 7-pass maximum security wipe |
| `config` | Manage configuration |

### Available Options

| Option | Description |
|--------|-------------|
| `-h, --help` | Show help message |
| `-v, --version` | Display version |
| `-d, --dry-run` | Simulate operations |
| `-f, --force` | Skip confirmations |
| `-q, --quiet` | Suppress output |
| `--verbose` | Enable debug output |
| `--parallel` | Process drives in parallel |
| `--no-color` | Disable colored output |
| `--json` | JSON format for logs |
| `--notify` | Enable desktop notifications |
| `--no-verify` | Skip wipe verification |

---

## 🔐 Wipe Methods

### 1. Single Pass (Zero)
- **Speed**: Fastest
- **Security**: Basic
- **Method**: Overwrites with zeros
- **Use Case**: Quick data removal

### 2. Triple Pass (DoD 5220.22-M)
- **Speed**: Moderate
- **Security**: High
- **Method**: Zero → Random → Zero
- **Use Case**: Government/enterprise standards

### 3. Seven Pass (Gutmann-lite)
- **Speed**: Slow
- **Security**: Maximum
- **Method**: Alternating zero and random passes
- **Use Case**: Highest security requirements

### 4. Random Only
- **Speed**: Moderate
- **Security**: Good
- **Method**: Single pass with random data
- **Use Case**: Randomized destruction

### 5. Custom Pattern
- **Speed**: Variable
- **Security**: User-defined
- **Method**: User-specified hex pattern
- **Use Case**: Special requirements

---

## ⚙️ Configuration

Settings are stored in `~/.config/usb-cleaner/config`:

```bash
# USB-Cleaner Pro Configuration

# Logging
LOG_FORMAT="text"      # text or json
VERBOSE="false"        # Enable debug output

# Behavior
DRY_RUN="false"        # Simulate operations
FORCE="false"          # Skip confirmations
PARALLEL="false"       # Process drives in parallel
VERIFY_WIPE="true"     # Verify after wipe

# Notifications
NOTIFICATION="false"   # Desktop notifications

# Paths
BACKUP_DIR="$HOME/usb-backups"
```

---

## 📊 Example Session

```bash
$ sudo ./cleaner.sh

╔═══════════════════════════════════════════════════════════════════════════╗
║                    USB-CLEANER PRO v2.0                                   ║
╚═══════════════════════════════════════════════════════════════════════════╝

Select option: 1

╔════════════════════════════════════════════════════════════════════╗
║                    AVAILABLE USB DRIVES                            ║
╠════════════════════════════════════════════════════════════════════╣
║  1. /dev/sdb    - SanDisk_Ultra            (16G)                   ║
║  2. /dev/sdc    - Kingston_DataTraveler    (32G)                   ║
╚════════════════════════════════════════════════════════════════════╝

Select drives by space-separated numbers: 1

╔════════════════════════════════════════════════════════════════════╗
║               DRIVE INFORMATION                                    ║
╠════════════════════════════════════════════════════════════════════╣
║ Device:         /dev/sdb                                           ║
║ Model:          SanDisk_Ultra                                      ║
║ Vendor:         SanDisk                                            ║
║ Size:           16G                                                ║
║ Serial:         ABC123456789                                       ║
╚════════════════════════════════════════════════════════════════════╝

⚠ You have chosen /dev/sdb. Proceed? [y/n]: y

╭──────────────────────────────────────────────────────────╮
│              SELECT WIPE METHOD                          │
├──────────────────────────────────────────────────────────┤
│  1) Single Pass (Zero)     - Fast, basic security       │
│  2) Triple Pass (DoD)      - US DoD 5220.22-M standard  │
│  3) Seven Pass (Gutmann)   - Maximum security           │
│  4) Random Only            - /dev/urandom single pass   │
│  5) Custom Pattern         - User-defined pattern       │
╰──────────────────────────────────────────────────────────╯

Choice: 1

▶ Pass 1/1: Zero fill...
16106127360 bytes (16 GB) copied, 45.123 s, 357 MB/s

╔════════════════════════════════════════════════════════════════════╗
║  ✓ WIPE COMPLETED                                                  ║
║    Drive: /dev/sdb                                                 ║
║    Duration: 0m 45s                                                ║
╚════════════════════════════════════════════════════════════════════╝

Create a new partition? [y/n]: y

╭──────────────────────────────────────────────────────────╮
│              SELECT FILESYSTEM                           │
├──────────────────────────────────────────────────────────┤
│  1) FAT32    - Universal compatibility (4GB limit)      │
│  2) ext4     - Linux native, journaling                 │
│  3) NTFS     - Windows compatible, large files          │
│  4) exFAT    - Cross-platform, no file size limit       │
│  5) Btrfs    - Modern Linux, snapshots, checksums       │
│  6) XFS      - High-performance Linux filesystem        │
╰──────────────────────────────────────────────────────────╯

Choice: 1

╔════════════════════════════════════════════════════════════════════╗
║  ✓ PARTITION CREATED                                               ║
║    Device: /dev/sdb1                                               ║
║    Filesystem: fat32 | Label: FAT32                                ║
║    Table: msdos                                                    ║
╚════════════════════════════════════════════════════════════════════╝
```

---

## 🧪 Testing

```bash
# Run all tests
bats tests/cleaner.bats

# Run specific test
bats tests/cleaner.bats --filter "log function"
```

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📜 License

This project is licensed under the [MIT License](https://github.com/djeada/USB-Cleaner/blob/main/LICENSE).

---

## ⚠️ Disclaimer

**USE AT YOUR OWN RISK.** This tool performs irreversible operations on storage devices. Always:

- Double-check the selected drive before confirming operations
- Create backups of important data before wiping
- Verify you're wiping the correct device
- Test with `--dry-run` first if unsure

The authors are not responsible for any data loss resulting from the use of this software.

---

<div align="center">

**Made with ❤️ for secure data destruction**

*Stay secure! 🔒*

</div>
