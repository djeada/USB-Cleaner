#!/usr/bin/env bash
#
# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║                        USB-CLEANER PRO v2.0                               ║
# ║          Advanced USB Drive Sanitization & Management Tool                ║
# ╚═══════════════════════════════════════════════════════════════════════════╝
#
# Copyright (c) 2024 - A comprehensive USB drive management solution
# Features: Secure wiping, Drive health monitoring, Modern TUI, Advanced logging
#

# ═══════════════════════════════════════════════════════════════════════════════
# Version and Configuration
# ═══════════════════════════════════════════════════════════════════════════════
VERSION="2.0.0"
SCRIPT_NAME="USB-Cleaner Pro"

# Only check sudo when running directly (not when being sourced for testing)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]] && [[ $EUID -ne 0 ]]; then
    exec sudo "$0" "$@"
fi

# ═══════════════════════════════════════════════════════════════════════════════
# Default Configuration
# ═══════════════════════════════════════════════════════════════════════════════
LOGFILE="${LOGFILE:-/var/log/cleaner.log}"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/usb-cleaner"
CONFIG_FILE="$CONFIG_DIR/config"
BACKUP_DIR="${BACKUP_DIR:-$HOME/usb-backups}"
usb_drives=()
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Global settings with defaults
DRY_RUN="${DRY_RUN:-false}"
VERBOSE="${VERBOSE:-false}"
QUIET="${QUIET:-false}"
FORCE="${FORCE:-false}"
PARALLEL="${PARALLEL:-false}"
LOG_FORMAT="${LOG_FORMAT:-text}"
COLOR_OUTPUT="${COLOR_OUTPUT:-true}"
VERIFY_WIPE="${VERIFY_WIPE:-true}"
NOTIFICATION="${NOTIFICATION:-false}"

# ═══════════════════════════════════════════════════════════════════════════════
# Color Definitions (ANSI escape codes)
# ═══════════════════════════════════════════════════════════════════════════════
if [[ "$COLOR_OUTPUT" == "true" ]] && [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    MAGENTA='\033[0;35m'
    CYAN='\033[0;36m'
    WHITE='\033[1;37m'
    GRAY='\033[0;90m'
    BOLD='\033[1m'
    DIM='\033[2m'
    UNDERLINE='\033[4m'
    BLINK='\033[5m'
    REVERSE='\033[7m'
    RESET='\033[0m'
    # Background colors
    BG_RED='\033[41m'
    BG_GREEN='\033[42m'
    BG_YELLOW='\033[43m'
    BG_BLUE='\033[44m'
else
    RED='' GREEN='' YELLOW='' BLUE='' MAGENTA='' CYAN='' WHITE='' GRAY=''
    BOLD='' DIM='' UNDERLINE='' BLINK='' REVERSE='' RESET=''
    BG_RED='' BG_GREEN='' BG_YELLOW='' BG_BLUE=''
fi

# ═══════════════════════════════════════════════════════════════════════════════
# ASCII Art Banner
# ═══════════════════════════════════════════════════════════════════════════════
show_banner() {
    echo -e "${CYAN}"
    cat << 'EOF'
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
EOF
    echo -e "${RESET}"
    echo -e "${BOLD}${WHITE}                     Version $VERSION - Professional Edition${RESET}"
    echo -e "${GRAY}         ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo
}

# ═══════════════════════════════════════════════════════════════════════════════
# Logging Functions
# ═══════════════════════════════════════════════════════════════════════════════
log() {
    local timestamp=$(date +'%Y-%m-%d %H:%M:%S')
    local message="$1"
    local level="${2:-INFO}"
    
    # Console output (respecting quiet mode)
    if [[ "$QUIET" != "true" ]]; then
        case "$level" in
            ERROR)   echo -e "${RED}[✗] $message${RESET}" ;;
            WARNING) echo -e "${YELLOW}[⚠] $message${RESET}" ;;
            SUCCESS) echo -e "${GREEN}[✓] $message${RESET}" ;;
            DEBUG)   [[ "$VERBOSE" == "true" ]] && echo -e "${GRAY}[◈] $message${RESET}" ;;
            *)       echo -e "${WHITE}[•] $message${RESET}" ;;
        esac
    fi
    
    # File logging
    if [[ "$LOG_FORMAT" == "json" ]]; then
        echo "{\"timestamp\":\"$timestamp\",\"level\":\"$level\",\"message\":\"$message\"}" >> "$LOGFILE"
    else
        echo "$timestamp - $message" | tee -a "$LOGFILE" > /dev/null
    fi
}

log_debug() { log "$1" "DEBUG"; }
log_error() { log "$1" "ERROR"; }
log_warning() { log "$1" "WARNING"; }
log_success() { log "$1" "SUCCESS"; }

# ═══════════════════════════════════════════════════════════════════════════════
# Progress Bar and Visual Feedback
# ═══════════════════════════════════════════════════════════════════════════════
show_progress() {
    local current="$1"
    local total="$2"
    local label="${3:-Progress}"
    local width=50
    local percent=$((current * 100 / total))
    local filled=$((width * current / total))
    local empty=$((width - filled))
    
    # Create progress bar
    local bar=""
    for ((i=0; i<filled; i++)); do bar+="█"; done
    for ((i=0; i<empty; i++)); do bar+="░"; done
    
    # Calculate ETA
    local elapsed=$SECONDS
    local rate=$((current / (elapsed + 1)))
    local remaining=$(( (total - current) / (rate + 1) ))
    local eta_min=$((remaining / 60))
    local eta_sec=$((remaining % 60))
    
    printf "\r${CYAN}${label}${RESET} [${GREEN}%s${RESET}] ${BOLD}%3d%%${RESET} ETA: %02d:%02d " "$bar" "$percent" "$eta_min" "$eta_sec"
}

show_spinner() {
    local pid=$1
    local message="${2:-Processing}"
    local spinners=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
    local i=0
    
    while kill -0 "$pid" 2>/dev/null; do
        printf "\r${CYAN}${spinners[i]} ${message}...${RESET}"
        i=$(( (i + 1) % ${#spinners[@]} ))
        sleep 0.1
    done
    printf "\r"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Configuration Management
# ═══════════════════════════════════════════════════════════════════════════════
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        log_debug "Loading configuration from $CONFIG_FILE"
        source "$CONFIG_FILE"
    fi
}

save_config() {
    mkdir -p "$CONFIG_DIR"
    cat > "$CONFIG_FILE" << EOF
# USB-Cleaner Pro Configuration
# Generated on $(date)

# Logging
LOG_FORMAT="$LOG_FORMAT"
VERBOSE="$VERBOSE"

# Behavior
DRY_RUN="$DRY_RUN"
FORCE="$FORCE"
PARALLEL="$PARALLEL"
VERIFY_WIPE="$VERIFY_WIPE"

# Notifications
NOTIFICATION="$NOTIFICATION"

# Paths
BACKUP_DIR="$BACKUP_DIR"
EOF
    log_success "Configuration saved to $CONFIG_FILE"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Help and Usage Information
# ═══════════════════════════════════════════════════════════════════════════════
show_help() {
    echo -e "${BOLD}${CYAN}USB-Cleaner Pro v$VERSION${RESET}"
    echo -e "${GRAY}Advanced USB Drive Sanitization & Management Tool${RESET}\n"
    
    echo -e "${BOLD}USAGE:${RESET}"
    echo -e "  ${GREEN}./cleaner.sh${RESET} [OPTIONS] [COMMAND]\n"
    
    echo -e "${BOLD}COMMANDS:${RESET}"
    echo -e "  ${CYAN}wipe${RESET}         Securely wipe USB drive(s)"
    echo -e "  ${CYAN}partition${RESET}    Create partition on USB drive(s)"
    echo -e "  ${CYAN}info${RESET}         Display detailed drive information"
    echo -e "  ${CYAN}health${RESET}       Check drive health (SMART data)"
    echo -e "  ${CYAN}backup${RESET}       Create backup image of USB drive"
    echo -e "  ${CYAN}restore${RESET}      Restore backup image to USB drive"
    echo -e "  ${CYAN}verify${RESET}       Verify wipe operation\n"
    
    echo -e "${BOLD}OPTIONS:${RESET}"
    echo -e "  ${YELLOW}-h, --help${RESET}        Show this help message"
    echo -e "  ${YELLOW}-v, --version${RESET}     Display version information"
    echo -e "  ${YELLOW}-d, --dry-run${RESET}     Simulate operations without changes"
    echo -e "  ${YELLOW}-f, --force${RESET}       Skip confirmation prompts"
    echo -e "  ${YELLOW}-q, --quiet${RESET}       Suppress console output"
    echo -e "  ${YELLOW}--verbose${RESET}         Enable verbose debug output"
    echo -e "  ${YELLOW}--parallel${RESET}        Process multiple drives in parallel"
    echo -e "  ${YELLOW}--no-color${RESET}        Disable colored output"
    echo -e "  ${YELLOW}--json${RESET}            Use JSON format for logs"
    echo -e "  ${YELLOW}--notify${RESET}          Enable desktop notifications\n"
    
    echo -e "${BOLD}WIPE METHODS:${RESET}"
    echo -e "  ${MAGENTA}1${RESET}  Single Pass (Zero)    - Fast, basic security"
    echo -e "  ${MAGENTA}2${RESET}  Triple Pass (DoD)     - U.S. DoD 5220.22-M standard"
    echo -e "  ${MAGENTA}3${RESET}  Seven Pass (Gutmann)  - Maximum security"
    echo -e "  ${MAGENTA}4${RESET}  Random Only           - /dev/urandom single pass"
    echo -e "  ${MAGENTA}5${RESET}  Custom Pattern        - User-defined pattern\n"
    
    echo -e "${BOLD}FILESYSTEMS:${RESET}"
    echo -e "  FAT32, ext4, NTFS, exFAT, Btrfs, XFS\n"
    
    echo -e "${BOLD}EXAMPLES:${RESET}"
    echo -e "  ${DIM}# Interactive mode${RESET}"
    echo -e "  ${GREEN}./cleaner.sh${RESET}\n"
    echo -e "  ${DIM}# Wipe drive with dry-run${RESET}"
    echo -e "  ${GREEN}./cleaner.sh --dry-run wipe${RESET}\n"
    echo -e "  ${DIM}# Force wipe without prompts${RESET}"
    echo -e "  ${GREEN}./cleaner.sh --force wipe${RESET}\n"
    
    echo -e "${BOLD}CONFIGURATION:${RESET}"
    echo -e "  Config file: ${CYAN}~/.config/usb-cleaner/config${RESET}"
    echo -e "  Log file:    ${CYAN}/var/log/cleaner.log${RESET}\n"
}

show_version() {
    echo -e "${BOLD}USB-Cleaner Pro${RESET} version ${CYAN}$VERSION${RESET}"
    echo -e "Copyright (c) 2024 - Professional USB Drive Management"
    echo -e "License: MIT"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Dependency Management
# ═══════════════════════════════════════════════════════════════════════════════
check_dependencies() {
    local deps=(lsblk parted mkfs.vfat mkfs.ext4 mkfs.ntfs dd pv wipefs smartctl)
    local missing=()
    
    log_debug "Checking dependencies..."
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log_warning "Missing dependencies: ${missing[*]}"
        echo -e "${YELLOW}Installing missing dependencies...${RESET}"
        apt-get update -qq
        for dep in "${missing[@]}"; do
            case "$dep" in
                smartctl) apt-get install -y -qq smartmontools ;;
                mkfs.ntfs) apt-get install -y -qq ntfs-3g ;;
                mkfs.exfat) apt-get install -y -qq exfat-utils ;;
                mkfs.btrfs) apt-get install -y -qq btrfs-progs ;;
                *) apt-get install -y -qq "$dep" ;;
            esac
        done
        log_success "Dependencies installed successfully"
    else
        log_debug "All dependencies satisfied"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# Drive Information and Detection
# ═══════════════════════════════════════════════════════════════════════════════
get_drive_info() {
    local drive="$1"
    local size=$(lsblk -dno SIZE "$drive" 2>/dev/null)
    local model=$(udevadm info --query=property --name="$drive" 2>/dev/null | grep 'ID_MODEL=' | cut -d'=' -f2)
    local serial=$(udevadm info --query=property --name="$drive" 2>/dev/null | grep 'ID_SERIAL_SHORT=' | cut -d'=' -f2)
    local vendor=$(udevadm info --query=property --name="$drive" 2>/dev/null | grep 'ID_VENDOR=' | cut -d'=' -f2)
    
    echo "model:$model|size:$size|serial:$serial|vendor:$vendor"
}

show_drive_dashboard() {
    local drive="$1"
    local info=$(get_drive_info "$drive")
    local model=$(echo "$info" | cut -d'|' -f1 | cut -d':' -f2)
    local size=$(echo "$info" | cut -d'|' -f2 | cut -d':' -f2)
    local serial=$(echo "$info" | cut -d'|' -f3 | cut -d':' -f2)
    local vendor=$(echo "$info" | cut -d'|' -f4 | cut -d':' -f2)
    
    echo -e "\n${BOLD}${CYAN}╔════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${CYAN}║${RESET}               ${BOLD}DRIVE INFORMATION${RESET}                       ${BOLD}${CYAN}║${RESET}"
    echo -e "${BOLD}${CYAN}╠════════════════════════════════════════════════════════╣${RESET}"
    printf "${BOLD}${CYAN}║${RESET} %-15s ${WHITE}%-40s${RESET}${BOLD}${CYAN}║${RESET}\n" "Device:" "$drive"
    printf "${BOLD}${CYAN}║${RESET} %-15s ${WHITE}%-40s${RESET}${BOLD}${CYAN}║${RESET}\n" "Model:" "${model:-Unknown}"
    printf "${BOLD}${CYAN}║${RESET} %-15s ${WHITE}%-40s${RESET}${BOLD}${CYAN}║${RESET}\n" "Vendor:" "${vendor:-Unknown}"
    printf "${BOLD}${CYAN}║${RESET} %-15s ${WHITE}%-40s${RESET}${BOLD}${CYAN}║${RESET}\n" "Size:" "${size:-Unknown}"
    printf "${BOLD}${CYAN}║${RESET} %-15s ${WHITE}%-40s${RESET}${BOLD}${CYAN}║${RESET}\n" "Serial:" "${serial:-Unknown}"
    echo -e "${BOLD}${CYAN}╚════════════════════════════════════════════════════════╝${RESET}"
}

check_drive_health() {
    local drive="$1"
    
    echo -e "\n${BOLD}${MAGENTA}╔════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${MAGENTA}║${RESET}              ${BOLD}DRIVE HEALTH CHECK${RESET}                       ${BOLD}${MAGENTA}║${RESET}"
    echo -e "${BOLD}${MAGENTA}╠════════════════════════════════════════════════════════╣${RESET}"
    
    if command -v smartctl &>/dev/null; then
        local health=$(smartctl -H "$drive" 2>/dev/null | grep -i "result" | awk '{print $NF}')
        local temp=$(smartctl -A "$drive" 2>/dev/null | grep -i "temperature" | head -1 | awk '{print $10}')
        local power_on=$(smartctl -A "$drive" 2>/dev/null | grep -i "power_on" | awk '{print $10}')
        
        if [[ -n "$health" ]]; then
            if [[ "$health" == "PASSED" ]]; then
                printf "${BOLD}${MAGENTA}║${RESET} %-15s ${GREEN}%-40s${RESET}${BOLD}${MAGENTA}║${RESET}\n" "Health:" "✓ PASSED"
            else
                printf "${BOLD}${MAGENTA}║${RESET} %-15s ${RED}%-40s${RESET}${BOLD}${MAGENTA}║${RESET}\n" "Health:" "✗ $health"
            fi
            [[ -n "$temp" ]] && printf "${BOLD}${MAGENTA}║${RESET} %-15s ${WHITE}%-40s${RESET}${BOLD}${MAGENTA}║${RESET}\n" "Temperature:" "${temp}°C"
            [[ -n "$power_on" ]] && printf "${BOLD}${MAGENTA}║${RESET} %-15s ${WHITE}%-40s${RESET}${BOLD}${MAGENTA}║${RESET}\n" "Power-On:" "${power_on} hours"
        else
            printf "${BOLD}${MAGENTA}║${RESET} ${YELLOW}%-54s${RESET}${BOLD}${MAGENTA}║${RESET}\n" "SMART data not available for this drive"
        fi
    else
        printf "${BOLD}${MAGENTA}║${RESET} ${YELLOW}%-54s${RESET}${BOLD}${MAGENTA}║${RESET}\n" "smartctl not installed - health check unavailable"
    fi
    
    echo -e "${BOLD}${MAGENTA}╚════════════════════════════════════════════════════════╝${RESET}"
}

get_usb_drives() {
    usb_list=($(lsblk -dplno NAME,TRAN | grep ' usb$' | awk '{print $1}'))
    if [ ${#usb_list[@]} -eq 0 ]; then
        log "No USB drives found."
        return 1
    fi
    
    echo -e "\n${BOLD}${CYAN}╔════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${CYAN}║${RESET}                    ${BOLD}AVAILABLE USB DRIVES${RESET}                          ${BOLD}${CYAN}║${RESET}"
    echo -e "${BOLD}${CYAN}╠════════════════════════════════════════════════════════════════════╣${RESET}"
    
    for i in "${!usb_list[@]}"; do
        drive="${usb_list[$i]}"
        info=$(get_drive_info "$drive")
        model=$(echo "$info" | cut -d'|' -f1 | cut -d':' -f2)
        size=$(echo "$info" | cut -d'|' -f2 | cut -d':' -f2)
        
        printf "${BOLD}${CYAN}║${RESET}  ${GREEN}%d${RESET}. ${WHITE}%-10s${RESET} - ${YELLOW}%-25s${RESET} (${MAGENTA}%s${RESET})      ${BOLD}${CYAN}║${RESET}\n" "$((i+1))" "$drive" "${model:-Unknown Device}" "${size:-?}"
    done
    
    echo -e "${BOLD}${CYAN}╚════════════════════════════════════════════════════════════════════╝${RESET}"
    
    echo -ne "\n${BOLD}Select drives by space-separated numbers: ${RESET}"
    read -r selection
    if [ -z "$selection" ]; then
        log "No selection made."
        return 1
    fi
    usb_drives=()
    for sel in $selection; do
        if ! [[ $sel =~ ^[0-9]+$ ]]; then
            log "Invalid selection."
            return 1
        fi
        if [ $sel -le 0 ] || [ $sel -gt ${#usb_list[@]} ]; then
            log "Invalid selection."
            return 1
        fi
        usb_drives+=("${usb_list[$((sel-1))]}")
    done
    
    for usb_drive in "${usb_drives[@]}"; do
        show_drive_dashboard "$usb_drive"
        
        if [[ "$FORCE" != "true" ]]; then
            echo -ne "\n${YELLOW}⚠ You have chosen ${WHITE}$usb_drive${YELLOW}. Proceed? [y/n]: ${RESET}"
            read -r confirm
            if [ "$confirm" != "y" ]; then
                log "Operation cancelled by user."
                return 1
            fi
        fi
    done
}

# ═══════════════════════════════════════════════════════════════════════════════
# Mount and Partition Management
# ═══════════════════════════════════════════════════════════════════════════════
check_mounted() {
    local drive="${1:-$usb_drive}"
    local parts=$(lsblk -lno NAME "$drive" 2>/dev/null | tail -n +2)
    
    for p in $parts; do
        local mp=$(lsblk -no MOUNTPOINT "/dev/$p" 2>/dev/null)
        if [ -n "$mp" ]; then
            log_warning "Found mounted partition /dev/$p at $mp"
            
            if [[ "$FORCE" == "true" ]]; then
                log "Auto-unmounting /dev/$p (force mode)"
                umount -f "/dev/$p" 2>/dev/null || true
            else
                echo -ne "${YELLOW}⚠ Unmount /dev/$p automatically? [y/n]: ${RESET}"
                read -r unmount
                if [ "$unmount" = "y" ]; then
                    log "Unmounting /dev/$p"
                    umount -f "/dev/$p" 2>/dev/null || true
                else
                    log_error "Please unmount partitions manually."
                    return 1
                fi
            fi
        fi
    done
}

# ═══════════════════════════════════════════════════════════════════════════════
# Backup and Restore Functions
# ═══════════════════════════════════════════════════════════════════════════════
backup_usb_drive() {
    local drive="${1:-$usb_drive}"
    
    if [[ "$FORCE" == "true" ]]; then
        return 0
    fi
    
    echo -ne "${CYAN}💾 Backup ${WHITE}$drive${CYAN} before wiping? [y/n]: ${RESET}"
    read -r backup
    if [ "$backup" = "y" ]; then
        mkdir -p "$BACKUP_DIR"
        local backup_file="$BACKUP_DIR/backup_$(basename "$drive")_$(date +'%Y%m%d%H%M%S').img"
        local compress_choice
        
        echo -e "${CYAN}Compression options:${RESET}"
        echo -e "  ${GREEN}1${RESET}) No compression (fastest, largest file)"
        echo -e "  ${GREEN}2${RESET}) gzip compression (balanced)"
        echo -e "  ${GREEN}3${RESET}) xz compression (slowest, smallest file)"
        echo -ne "${BOLD}Choice: ${RESET}"
        read -r compress_choice
        
        log "Backing up $drive..."
        
        local drive_size=$(lsblk -dno SIZE -b "$drive" 2>/dev/null)
        
        if [[ "$DRY_RUN" == "true" ]]; then
            log "[DRY RUN] Would backup $drive to $backup_file"
            return 0
        fi
        
        case "$compress_choice" in
            2)
                backup_file="${backup_file}.gz"
                dd if="$drive" bs=4M status=progress 2>/dev/null | gzip -c > "$backup_file"
                ;;
            3)
                backup_file="${backup_file}.xz"
                dd if="$drive" bs=4M status=progress 2>/dev/null | xz -c > "$backup_file"
                ;;
            *)
                dd if="$drive" of="$backup_file" bs=4M status=progress conv=fsync 2>/dev/null
                ;;
        esac
        
        sync
        
        # Calculate and store checksum
        local checksum=$(sha256sum "$backup_file" | cut -d' ' -f1)
        echo "$checksum  $(basename "$backup_file")" > "${backup_file}.sha256"
        
        local backup_size=$(du -h "$backup_file" | cut -f1)
        log_success "Backup completed: $backup_file ($backup_size)"
        log_debug "SHA256: $checksum"
    fi
}

restore_backup() {
    echo -e "\n${BOLD}${CYAN}╔════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${CYAN}║${RESET}               ${BOLD}RESTORE BACKUP${RESET}                           ${BOLD}${CYAN}║${RESET}"
    echo -e "${BOLD}${CYAN}╚════════════════════════════════════════════════════════╝${RESET}"
    
    # List available backups
    if [[ ! -d "$BACKUP_DIR" ]] || [[ -z "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]]; then
        log_error "No backups found in $BACKUP_DIR"
        return 1
    fi
    
    echo -e "\n${BOLD}Available backups:${RESET}"
    local backups=($(ls -1 "$BACKUP_DIR"/*.img* 2>/dev/null | grep -v ".sha256$"))
    
    for i in "${!backups[@]}"; do
        local backup="${backups[$i]}"
        local size=$(du -h "$backup" | cut -f1)
        local date=$(stat -c "%y" "$backup" | cut -d'.' -f1)
        printf "  ${GREEN}%d${RESET}) %s (${MAGENTA}%s${RESET}) - ${GRAY}%s${RESET}\n" "$((i+1))" "$(basename "$backup")" "$size" "$date"
    done
    
    echo -ne "\n${BOLD}Select backup to restore: ${RESET}"
    read -r backup_sel
    
    if ! [[ $backup_sel =~ ^[0-9]+$ ]] || [[ $backup_sel -le 0 ]] || [[ $backup_sel -gt ${#backups[@]} ]]; then
        log_error "Invalid selection"
        return 1
    fi
    
    local selected_backup="${backups[$((backup_sel-1))]}"
    
    # Verify checksum if available
    if [[ -f "${selected_backup}.sha256" ]]; then
        echo -e "${CYAN}Verifying backup integrity...${RESET}"
        if sha256sum -c "${selected_backup}.sha256" --quiet 2>/dev/null; then
            log_success "Backup integrity verified"
        else
            log_error "Backup integrity check failed!"
            return 1
        fi
    fi
    
    # Select target drive
    get_usb_drives || return 1
    
    for drive in "${usb_drives[@]}"; do
        check_mounted "$drive" || return 1
        
        log "Restoring $selected_backup to $drive..."
        
        if [[ "$DRY_RUN" == "true" ]]; then
            log "[DRY RUN] Would restore to $drive"
            continue
        fi
        
        if [[ "$selected_backup" == *.gz ]]; then
            gunzip -c "$selected_backup" | dd of="$drive" bs=4M status=progress conv=fsync
        elif [[ "$selected_backup" == *.xz ]]; then
            xz -dc "$selected_backup" | dd of="$drive" bs=4M status=progress conv=fsync
        else
            dd if="$selected_backup" of="$drive" bs=4M status=progress conv=fsync
        fi
        
        sync
        log_success "Restore completed for $drive"
    done
}

# ═══════════════════════════════════════════════════════════════════════════════
# Secure Wipe Operations
# ═══════════════════════════════════════════════════════════════════════════════
calculate_hash() {
    local drive="$1"
    local sample_size="${2:-1M}"
    
    # Sample hash from start, middle, and end of drive
    local drive_size=$(lsblk -dno SIZE -b "$drive" 2>/dev/null)
    local mid_offset=$((drive_size / 2))
    local end_offset=$((drive_size - 1048576))
    
    local hash_start=$(dd if="$drive" bs=1M count=1 2>/dev/null | sha256sum | cut -d' ' -f1)
    local hash_mid=$(dd if="$drive" bs=1M count=1 skip=$((mid_offset / 1048576)) 2>/dev/null | sha256sum | cut -d' ' -f1)
    local hash_end=$(dd if="$drive" bs=1M count=1 skip=$((end_offset / 1048576)) 2>/dev/null | sha256sum | cut -d' ' -f1)
    
    echo "${hash_start}:${hash_mid}:${hash_end}"
}

verify_wipe() {
    local drive="$1"
    local expected_pattern="${2:-zero}"
    
    log "Verifying wipe for $drive..."
    
    echo -e "\n${CYAN}╭──────────────────────────────────────────────────────────╮${RESET}"
    echo -e "${CYAN}│${RESET}              ${BOLD}WIPE VERIFICATION${RESET}                          ${CYAN}│${RESET}"
    echo -e "${CYAN}╰──────────────────────────────────────────────────────────╯${RESET}"
    
    # Sample verification at multiple points
    local samples=5
    local drive_size=$(lsblk -dno SIZE -b "$drive" 2>/dev/null)
    local passed=0
    local failed=0
    
    for i in $(seq 1 $samples); do
        local offset=$(( (drive_size / samples) * (i - 1) ))
        local sample=$(dd if="$drive" bs=1024 count=1 skip=$((offset / 1024)) 2>/dev/null | xxd -p | head -c 64)
        
        if [[ "$expected_pattern" == "zero" ]]; then
            if [[ "$sample" =~ ^0+$ ]]; then
                echo -e "  ${GREEN}✓${RESET} Sample $i at offset $offset: Verified zero"
                ((passed++))
            else
                echo -e "  ${RED}✗${RESET} Sample $i at offset $offset: Non-zero data found"
                ((failed++))
            fi
        else
            echo -e "  ${CYAN}◈${RESET} Sample $i at offset $offset: $sample..."
            ((passed++))
        fi
    done
    
    echo -e "\n${BOLD}Verification Results:${RESET} ${GREEN}$passed passed${RESET}, ${RED}$failed failed${RESET}"
    
    if [[ $failed -eq 0 ]]; then
        log_success "Wipe verification passed for $drive"
        return 0
    else
        log_warning "Wipe verification had issues - please review"
        return 1
    fi
}

wipe_disk() {
    echo -e "\n${BOLD}${RED}╔════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${RED}║${RESET}                    ${BOLD}⚠  SECURE WIPE OPERATION  ⚠${RESET}                     ${BOLD}${RED}║${RESET}"
    echo -e "${BOLD}${RED}╚════════════════════════════════════════════════════════════════════╝${RESET}"
    
    for usb_drive in "${usb_drives[@]}"; do
        # Show drive info before wipe
        show_drive_dashboard "$usb_drive"
        
        # Pre-wipe hash for verification
        local pre_wipe_hash=""
        if [[ "$VERIFY_WIPE" == "true" ]]; then
            echo -e "${CYAN}Calculating pre-wipe hash...${RESET}"
            pre_wipe_hash=$(calculate_hash "$usb_drive")
            log_debug "Pre-wipe hash: $pre_wipe_hash"
        fi
        
        check_mounted "$usb_drive" || return 1
        backup_usb_drive "$usb_drive"
        
        echo -e "\n${BOLD}${CYAN}╭──────────────────────────────────────────────────────────╮${RESET}"
        echo -e "${BOLD}${CYAN}│${RESET}              ${BOLD}SELECT WIPE METHOD${RESET}                         ${BOLD}${CYAN}│${RESET}"
        echo -e "${BOLD}${CYAN}├──────────────────────────────────────────────────────────┤${RESET}"
        echo -e "${BOLD}${CYAN}│${RESET}  ${GREEN}1${RESET}) ${WHITE}Single Pass (Zero)${RESET}     - Fast, basic security       ${BOLD}${CYAN}│${RESET}"
        echo -e "${BOLD}${CYAN}│${RESET}  ${GREEN}2${RESET}) ${WHITE}Triple Pass (DoD)${RESET}      - US DoD 5220.22-M standard  ${BOLD}${CYAN}│${RESET}"
        echo -e "${BOLD}${CYAN}│${RESET}  ${GREEN}3${RESET}) ${WHITE}Seven Pass (Gutmann)${RESET}   - Maximum security           ${BOLD}${CYAN}│${RESET}"
        echo -e "${BOLD}${CYAN}│${RESET}  ${GREEN}4${RESET}) ${WHITE}Random Only${RESET}            - /dev/urandom single pass   ${BOLD}${CYAN}│${RESET}"
        echo -e "${BOLD}${CYAN}│${RESET}  ${GREEN}5${RESET}) ${WHITE}Custom Pattern${RESET}         - User-defined pattern       ${BOLD}${CYAN}│${RESET}"
        echo -e "${BOLD}${CYAN}╰──────────────────────────────────────────────────────────╯${RESET}"
        
        echo -ne "\n${BOLD}Choice: ${RESET}"
        read -r wipe_method
        if ! [[ $wipe_method =~ ^[1-5]$ ]]; then
            log_error "Invalid choice."
            return 1
        fi
        
        # Get drive size for progress calculation
        local drive_size=$(lsblk -dno SIZE "$usb_drive")
        local drive_bytes=$(lsblk -dno SIZE -b "$usb_drive")
        
        log "Starting secure wipe of $usb_drive ($drive_size)"
        
        if [[ "$DRY_RUN" == "true" ]]; then
            log "[DRY RUN] Would wipe $usb_drive with method $wipe_method"
            continue
        fi
        
        # Clear existing signatures
        wipefs -a "$usb_drive" 2>/dev/null
        sync
        
        local start_time=$SECONDS
        
        case $wipe_method in
            1)
                log "Wiping $usb_drive - Single Pass (Zero Fill)"
                echo -e "\n${YELLOW}▶ Pass 1/1: Zero fill...${RESET}"
                dd if=/dev/zero of="$usb_drive" bs=4M status=progress conv=fsync 2>&1
                sync
                ;;
            2)
                log "Wiping $usb_drive - Triple Pass (DoD 5220.22-M)"
                for pass in {1..3}; do
                    echo -e "\n${YELLOW}▶ Pass $pass/3: $([ $pass -eq 2 ] && echo "Random" || echo "Zero") fill...${RESET}"
                    log "Pass $pass of 3"
                    if [ $pass -eq 2 ]; then
                        dd if=/dev/urandom of="$usb_drive" bs=4M status=progress conv=fsync 2>&1
                    else
                        dd if=/dev/zero of="$usb_drive" bs=4M status=progress conv=fsync 2>&1
                    fi
                    sync
                done
                ;;
            3)
                log "Wiping $usb_drive - Seven Pass (Gutmann-lite)"
                for pass in {1..7}; do
                    echo -e "\n${YELLOW}▶ Pass $pass/7: $([ $((pass % 2)) -eq 0 ] && echo "Random" || echo "Zero") fill...${RESET}"
                    log "Pass $pass of 7"
                    if [ $((pass % 2)) -eq 0 ]; then
                        dd if=/dev/urandom of="$usb_drive" bs=4M status=progress conv=fsync 2>&1
                    else
                        dd if=/dev/zero of="$usb_drive" bs=4M status=progress conv=fsync 2>&1
                    fi
                    sync
                done
                ;;
            4)
                log "Wiping $usb_drive - Random Data Fill"
                echo -e "\n${YELLOW}▶ Pass 1/1: Random fill (/dev/urandom)...${RESET}"
                dd if=/dev/urandom of="$usb_drive" bs=4M status=progress conv=fsync 2>&1
                sync
                ;;
            5)
                echo -ne "${CYAN}Enter custom pattern (hex, e.g., 'DEADBEEF'): ${RESET}"
                read -r custom_pattern
                
                # Create pattern file
                local pattern_file="$TEMP_DIR/pattern.bin"
                echo -n "$custom_pattern" | xxd -r -p > "$pattern_file"
                
                log "Wiping $usb_drive - Custom Pattern ($custom_pattern)"
                echo -e "\n${YELLOW}▶ Pass 1/1: Custom pattern fill...${RESET}"
                
                # Create a larger pattern file for efficiency
                local large_pattern="$TEMP_DIR/large_pattern.bin"
                for i in {1..1024}; do cat "$pattern_file"; done > "$large_pattern"
                
                # Write pattern repeatedly
                local blocks=$((drive_bytes / 4194304))
                for ((b=0; b<blocks; b++)); do
                    dd if="$large_pattern" of="$usb_drive" bs=4M seek=$b count=1 conv=notrunc 2>/dev/null
                    printf "\r${CYAN}Progress: %d/%d blocks${RESET}" "$((b+1))" "$blocks"
                done
                echo
                sync
                ;;
        esac
        
        local elapsed=$((SECONDS - start_time))
        local elapsed_min=$((elapsed / 60))
        local elapsed_sec=$((elapsed % 60))
        
        sync
        
        # Post-wipe verification
        if [[ "$VERIFY_WIPE" == "true" ]]; then
            verify_wipe "$usb_drive" "zero"
        fi
        
        echo -e "\n${GREEN}╔════════════════════════════════════════════════════════════════════╗${RESET}"
        echo -e "${GREEN}║${RESET}  ${BOLD}✓ WIPE COMPLETED${RESET}                                                ${GREEN}║${RESET}"
        echo -e "${GREEN}║${RESET}    Drive: ${CYAN}$usb_drive${RESET}                                             ${GREEN}║${RESET}"
        echo -e "${GREEN}║${RESET}    Duration: ${CYAN}${elapsed_min}m ${elapsed_sec}s${RESET}                                         ${GREEN}║${RESET}"
        echo -e "${GREEN}╚════════════════════════════════════════════════════════════════════╝${RESET}"
        
        log_success "Wipe completed for $usb_drive in ${elapsed_min}m ${elapsed_sec}s"
        
        # Send notification if enabled
        if [[ "$NOTIFICATION" == "true" ]]; then
            send_notification "USB Wipe Complete" "Successfully wiped $usb_drive"
        fi
        
        create_partition_prompt
    done
}

# ═══════════════════════════════════════════════════════════════════════════════
# Filesystem and Partition Functions
# ═══════════════════════════════════════════════════════════════════════════════
choose_filesystem() {
    echo -e "\n${BOLD}${CYAN}╭──────────────────────────────────────────────────────────╮${RESET}"
    echo -e "${BOLD}${CYAN}│${RESET}              ${BOLD}SELECT FILESYSTEM${RESET}                          ${BOLD}${CYAN}│${RESET}"
    echo -e "${BOLD}${CYAN}├──────────────────────────────────────────────────────────┤${RESET}"
    echo -e "${BOLD}${CYAN}│${RESET}  ${GREEN}1${RESET}) ${WHITE}FAT32${RESET}    - Universal compatibility (4GB limit)     ${BOLD}${CYAN}│${RESET}"
    echo -e "${BOLD}${CYAN}│${RESET}  ${GREEN}2${RESET}) ${WHITE}ext4${RESET}     - Linux native, journaling               ${BOLD}${CYAN}│${RESET}"
    echo -e "${BOLD}${CYAN}│${RESET}  ${GREEN}3${RESET}) ${WHITE}NTFS${RESET}     - Windows compatible, large files         ${BOLD}${CYAN}│${RESET}"
    echo -e "${BOLD}${CYAN}│${RESET}  ${GREEN}4${RESET}) ${WHITE}exFAT${RESET}    - Cross-platform, no file size limit      ${BOLD}${CYAN}│${RESET}"
    echo -e "${BOLD}${CYAN}│${RESET}  ${GREEN}5${RESET}) ${WHITE}Btrfs${RESET}    - Modern Linux, snapshots, checksums      ${BOLD}${CYAN}│${RESET}"
    echo -e "${BOLD}${CYAN}│${RESET}  ${GREEN}6${RESET}) ${WHITE}XFS${RESET}      - High-performance Linux filesystem       ${BOLD}${CYAN}│${RESET}"
    echo -e "${BOLD}${CYAN}╰──────────────────────────────────────────────────────────╯${RESET}"
    
    echo -ne "\n${BOLD}Choice: ${RESET}"
    read -r fs_choice
    case $fs_choice in
        1) fs_type="fat32"; fs_mk="mkfs.vfat" ; fs_label="FAT32" ;;
        2) fs_type="ext4"; fs_mk="mkfs.ext4" ; fs_label="EXT4" ;;
        3) fs_type="ntfs"; fs_mk="mkfs.ntfs" ; fs_label="NTFS" ;;
        4) fs_type="exfat"; fs_mk="mkfs.exfat" ; fs_label="EXFAT" ;;
        5) fs_type="btrfs"; fs_mk="mkfs.btrfs" ; fs_label="BTRFS" ;;
        6) fs_type="xfs"; fs_mk="mkfs.xfs" ; fs_label="XFS" ;;
        *) fs_type="fat32"; fs_mk="mkfs.vfat"; fs_label="FAT32" ;;
    esac
}

choose_partition_table() {
    echo -e "\n${BOLD}${CYAN}╭──────────────────────────────────────────────────────────╮${RESET}"
    echo -e "${BOLD}${CYAN}│${RESET}           ${BOLD}SELECT PARTITION TABLE TYPE${RESET}                    ${BOLD}${CYAN}│${RESET}"
    echo -e "${BOLD}${CYAN}├──────────────────────────────────────────────────────────┤${RESET}"
    echo -e "${BOLD}${CYAN}│${RESET}  ${GREEN}1${RESET}) ${WHITE}MBR (msdos)${RESET} - Legacy, up to 2TB, max 4 primary    ${BOLD}${CYAN}│${RESET}"
    echo -e "${BOLD}${CYAN}│${RESET}  ${GREEN}2${RESET}) ${WHITE}GPT${RESET}         - Modern, large disks, 128 partitions ${BOLD}${CYAN}│${RESET}"
    echo -e "${BOLD}${CYAN}╰──────────────────────────────────────────────────────────╯${RESET}"
    
    echo -ne "\n${BOLD}Choice: ${RESET}"
    read -r table_choice
    case $table_choice in
        2) partition_table="gpt" ;;
        *) partition_table="msdos" ;;
    esac
}

create_partition() {
    echo -e "\n${BOLD}${BLUE}╔════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${BLUE}║${RESET}                 ${BOLD}PARTITION CREATION${RESET}                                ${BOLD}${BLUE}║${RESET}"
    echo -e "${BOLD}${BLUE}╚════════════════════════════════════════════════════════════════════╝${RESET}"
    
    for usb_drive in "${usb_drives[@]}"; do
        show_drive_dashboard "$usb_drive"
        
        choose_partition_table
        choose_filesystem
        
        # Ask for custom label
        echo -ne "\n${CYAN}Enter volume label (press Enter for '${fs_label}'): ${RESET}"
        read -r custom_label
        [[ -n "$custom_label" ]] && fs_label="$custom_label"
        
        log "Creating partition on $usb_drive (Table: $partition_table, FS: $fs_type)"
        
        if [[ "$DRY_RUN" == "true" ]]; then
            log "[DRY RUN] Would create $fs_type partition on $usb_drive"
            continue
        fi
        
        # Clear existing signatures
        wipefs -a "$usb_drive" 2>/dev/null
        sync
        
        # Create partition table
        parted "$usb_drive" --script mklabel "$partition_table" || {
            log_error "Failed to create partition table"
            return 1
        }
        
        # Create partition based on filesystem type
        case "$fs_type" in
            fat32)
                parted "$usb_drive" --script mkpart primary fat32 0% 100%
                ;;
            ext4)
                parted "$usb_drive" --script mkpart primary ext4 0% 100%
                ;;
            ntfs)
                parted "$usb_drive" --script mkpart primary ntfs 0% 100%
                ;;
            exfat)
                parted "$usb_drive" --script mkpart primary fat32 0% 100%  # parted doesn't support exfat type
                ;;
            btrfs|xfs)
                parted "$usb_drive" --script mkpart primary 0% 100%
                ;;
        esac
        
        sync
        sleep 1  # Allow kernel to recognize the new partition
        
        # Determine partition name
        local partition=""
        if [[ "$usb_drive" =~ nvme|loop ]]; then
            partition="${usb_drive}p1"
        else
            partition="${usb_drive}1"
        fi
        
        # Wait for partition to be ready
        for i in {1..10}; do
            [[ -b "$partition" ]] && break
            sleep 0.5
        done
        
        # Format the partition
        echo -e "\n${CYAN}Formatting ${partition} as ${fs_type}...${RESET}"
        
        case "$fs_type" in
            fat32)
                $fs_mk -n "$fs_label" "$partition" 2>/dev/null
                ;;
            ext4)
                $fs_mk -L "$fs_label" "$partition" 2>/dev/null
                ;;
            ntfs)
                $fs_mk -f -L "$fs_label" "$partition" 2>/dev/null
                ;;
            exfat)
                mkfs.exfat -n "$fs_label" "$partition" 2>/dev/null
                ;;
            btrfs)
                mkfs.btrfs -f -L "$fs_label" "$partition" 2>/dev/null
                ;;
            xfs)
                mkfs.xfs -f -L "$fs_label" "$partition" 2>/dev/null
                ;;
        esac
        
        sync
        
        echo -e "\n${GREEN}╔════════════════════════════════════════════════════════════════════╗${RESET}"
        echo -e "${GREEN}║${RESET}  ${BOLD}✓ PARTITION CREATED${RESET}                                            ${GREEN}║${RESET}"
        echo -e "${GREEN}║${RESET}    Device: ${CYAN}$partition${RESET}                                           ${GREEN}║${RESET}"
        echo -e "${GREEN}║${RESET}    Filesystem: ${CYAN}$fs_type${RESET} | Label: ${CYAN}$fs_label${RESET}                          ${GREEN}║${RESET}"
        echo -e "${GREEN}║${RESET}    Table: ${CYAN}$partition_table${RESET}                                              ${GREEN}║${RESET}"
        echo -e "${GREEN}╚════════════════════════════════════════════════════════════════════╝${RESET}"
        
        log_success "Partition created: $partition with $fs_label ($fs_type, $partition_table)"
        
        if [[ "$NOTIFICATION" == "true" ]]; then
            send_notification "Partition Created" "Successfully formatted $partition as $fs_type"
        fi
    done
}

# ═══════════════════════════════════════════════════════════════════════════════
# Notification System
# ═══════════════════════════════════════════════════════════════════════════════
send_notification() {
    local title="$1"
    local message="$2"
    
    # Try desktop notification first
    if command -v notify-send &>/dev/null; then
        notify-send -u normal -i drive-removable-media "$title" "$message"
    fi
    
    # Log the notification
    log_debug "Notification: $title - $message"
}

# ═══════════════════════════════════════════════════════════════════════════════
# Interactive Prompts
# ═══════════════════════════════════════════════════════════════════════════════
create_partition_prompt() {
    echo -ne "\n${CYAN}Create a new partition? [y/n]: ${RESET}"
    read -r create_part
    if [ "$create_part" = "y" ]; then
        create_partition
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# Quick Actions
# ═══════════════════════════════════════════════════════════════════════════════
quick_format() {
    echo -e "\n${BOLD}${MAGENTA}╔════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${MAGENTA}║${RESET}                   ${BOLD}QUICK FORMAT${RESET}                                   ${BOLD}${MAGENTA}║${RESET}"
    echo -e "${BOLD}${MAGENTA}╚════════════════════════════════════════════════════════════════════╝${RESET}"
    echo -e "${GRAY}Quick format creates a new partition table and filesystem${RESET}"
    echo -e "${GRAY}without secure wiping. Data may be recoverable.${RESET}\n"
    
    get_usb_drives || return 1
    create_partition
}

secure_erase() {
    echo -e "\n${BOLD}${RED}╔════════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${RED}║${RESET}                ${BOLD}SECURE ERASE (Maximum Security)${RESET}                   ${BOLD}${RED}║${RESET}"
    echo -e "${BOLD}${RED}╚════════════════════════════════════════════════════════════════════╝${RESET}"
    echo -e "${GRAY}Performs 7-pass wipe followed by partition creation${RESET}\n"
    
    get_usb_drives || return 1
    
    for usb_drive in "${usb_drives[@]}"; do
        usb_drives=("$usb_drive")  # Process one at a time for safety
        
        # Force 7-pass wipe
        check_mounted "$usb_drive" || continue
        backup_usb_drive "$usb_drive"
        
        log "Performing secure erase on $usb_drive"
        wipefs -a "$usb_drive" 2>/dev/null
        sync
        
        for pass in {1..7}; do
            echo -e "\n${YELLOW}▶ Pass $pass/7: $([ $((pass % 2)) -eq 0 ] && echo "Random" || echo "Zero") fill...${RESET}"
            if [ $((pass % 2)) -eq 0 ]; then
                dd if=/dev/urandom of="$usb_drive" bs=4M status=progress conv=fsync 2>&1
            else
                dd if=/dev/zero of="$usb_drive" bs=4M status=progress conv=fsync 2>&1
            fi
            sync
        done
        
        verify_wipe "$usb_drive" "zero"
        log_success "Secure erase completed for $usb_drive"
        
        echo -ne "\n${CYAN}Create partition after secure erase? [y/n]: ${RESET}"
        read -r create_part
        if [ "$create_part" = "y" ]; then
            create_partition
        fi
    done
}

# ═══════════════════════════════════════════════════════════════════════════════
# Drive Information Display
# ═══════════════════════════════════════════════════════════════════════════════
show_all_drive_info() {
    get_usb_drives || return 1
    
    for usb_drive in "${usb_drives[@]}"; do
        show_drive_dashboard "$usb_drive"
        check_drive_health "$usb_drive"
        
        # Show partition information
        echo -e "\n${BOLD}${CYAN}╭──────────────────────────────────────────────────────────╮${RESET}"
        echo -e "${BOLD}${CYAN}│${RESET}              ${BOLD}PARTITION LAYOUT${RESET}                           ${BOLD}${CYAN}│${RESET}"
        echo -e "${BOLD}${CYAN}╰──────────────────────────────────────────────────────────╯${RESET}"
        lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT,LABEL "$usb_drive" 2>/dev/null
    done
}

# ═══════════════════════════════════════════════════════════════════════════════
# Command Line Argument Parsing
# ═══════════════════════════════════════════════════════════════════════════════
parse_arguments() {
    COMMAND=""
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--version)
                show_version
                exit 0
                ;;
            -d|--dry-run)
                DRY_RUN="true"
                log_warning "Dry run mode enabled - no changes will be made"
                shift
                ;;
            -f|--force)
                FORCE="true"
                shift
                ;;
            -q|--quiet)
                QUIET="true"
                shift
                ;;
            --verbose)
                VERBOSE="true"
                shift
                ;;
            --parallel)
                PARALLEL="true"
                shift
                ;;
            --no-color)
                COLOR_OUTPUT="false"
                RED='' GREEN='' YELLOW='' BLUE='' MAGENTA='' CYAN='' WHITE='' GRAY=''
                BOLD='' DIM='' UNDERLINE='' BLINK='' REVERSE='' RESET=''
                shift
                ;;
            --json)
                LOG_FORMAT="json"
                shift
                ;;
            --notify)
                NOTIFICATION="true"
                shift
                ;;
            --no-verify)
                VERIFY_WIPE="false"
                shift
                ;;
            wipe|partition|info|health|backup|restore|verify|quick-format|secure-erase|config)
                COMMAND="$1"
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
}

# ═══════════════════════════════════════════════════════════════════════════════
# Main Menu (Interactive Mode)
# ═══════════════════════════════════════════════════════════════════════════════
main_menu() {
    while true; do
        echo -e "\n${BOLD}${CYAN}╔════════════════════════════════════════════════════════════════════╗${RESET}"
        echo -e "${BOLD}${CYAN}║${RESET}                      ${BOLD}MAIN MENU${RESET}                                   ${BOLD}${CYAN}║${RESET}"
        echo -e "${BOLD}${CYAN}╠════════════════════════════════════════════════════════════════════╣${RESET}"
        echo -e "${BOLD}${CYAN}║${RESET}                                                                    ${BOLD}${CYAN}║${RESET}"
        echo -e "${BOLD}${CYAN}║${RESET}  ${GREEN}1${RESET}) ${WHITE}Wipe USB Drive(s)${RESET}        - Secure data destruction         ${BOLD}${CYAN}║${RESET}"
        echo -e "${BOLD}${CYAN}║${RESET}  ${GREEN}2${RESET}) ${WHITE}Create Partition${RESET}         - Format with new filesystem      ${BOLD}${CYAN}║${RESET}"
        echo -e "${BOLD}${CYAN}║${RESET}  ${GREEN}3${RESET}) ${WHITE}Quick Format${RESET}             - Fast format (no wipe)           ${BOLD}${CYAN}║${RESET}"
        echo -e "${BOLD}${CYAN}║${RESET}  ${GREEN}4${RESET}) ${WHITE}Secure Erase${RESET}             - 7-pass maximum security         ${BOLD}${CYAN}║${RESET}"
        echo -e "${BOLD}${CYAN}║${RESET}  ${GREEN}5${RESET}) ${WHITE}Drive Information${RESET}        - View drive details & health     ${BOLD}${CYAN}║${RESET}"
        echo -e "${BOLD}${CYAN}║${RESET}  ${GREEN}6${RESET}) ${WHITE}Backup Drive${RESET}             - Create drive image backup       ${BOLD}${CYAN}║${RESET}"
        echo -e "${BOLD}${CYAN}║${RESET}  ${GREEN}7${RESET}) ${WHITE}Restore Backup${RESET}           - Restore from backup image       ${BOLD}${CYAN}║${RESET}"
        echo -e "${BOLD}${CYAN}║${RESET}  ${GREEN}8${RESET}) ${WHITE}Configuration${RESET}            - Save/load settings              ${BOLD}${CYAN}║${RESET}"
        echo -e "${BOLD}${CYAN}║${RESET}  ${GREEN}9${RESET}) ${WHITE}Help${RESET}                     - Show detailed help              ${BOLD}${CYAN}║${RESET}"
        echo -e "${BOLD}${CYAN}║${RESET}  ${RED}0${RESET}) ${WHITE}Exit${RESET}                     - Quit program                    ${BOLD}${CYAN}║${RESET}"
        echo -e "${BOLD}${CYAN}║${RESET}                                                                    ${BOLD}${CYAN}║${RESET}"
        echo -e "${BOLD}${CYAN}╚════════════════════════════════════════════════════════════════════╝${RESET}"
        
        echo -ne "\n${BOLD}Select option: ${RESET}"
        read -r choice
        
        case $choice in
            1)
                get_usb_drives || continue
                wipe_disk
                ;;
            2)
                get_usb_drives || continue
                create_partition
                ;;
            3)
                quick_format
                ;;
            4)
                secure_erase
                ;;
            5)
                show_all_drive_info
                ;;
            6)
                get_usb_drives || continue
                for usb_drive in "${usb_drives[@]}"; do
                    backup_usb_drive "$usb_drive"
                done
                ;;
            7)
                restore_backup
                ;;
            8)
                echo -e "\n${CYAN}1) Save current settings${RESET}"
                echo -e "${CYAN}2) Load settings from file${RESET}"
                echo -ne "\n${BOLD}Choice: ${RESET}"
                read -r config_choice
                case "$config_choice" in
                    1) save_config ;;
                    2) load_config && log_success "Configuration loaded" ;;
                esac
                ;;
            9)
                show_help
                ;;
            0)
                echo -e "\n${GREEN}Thank you for using ${BOLD}USB-Cleaner Pro${RESET}${GREEN}!${RESET}"
                echo -e "${GRAY}Stay secure! 🔒${RESET}\n"
                exit 0
                ;;
            *)
                log_error "Invalid choice. Please select 0-9."
                ;;
        esac
    done
}

# ═══════════════════════════════════════════════════════════════════════════════
# Main Entry Point
# ═══════════════════════════════════════════════════════════════════════════════

# Only run main if script is executed directly, not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Parse command line arguments
    parse_arguments "$@"
    
    # Load configuration
    load_config
    
    # Check dependencies
    check_dependencies
    
    # Show banner unless quiet mode
    [[ "$QUIET" != "true" ]] && show_banner
    
    # Execute command or show menu
    case "$COMMAND" in
        wipe)
            get_usb_drives && wipe_disk
            ;;
        partition)
            get_usb_drives && create_partition
            ;;
        info)
            show_all_drive_info
            ;;
        health)
            get_usb_drives || exit 1
            for drive in "${usb_drives[@]}"; do
                check_drive_health "$drive"
            done
            ;;
        backup)
            get_usb_drives || exit 1
            for usb_drive in "${usb_drives[@]}"; do
                backup_usb_drive "$usb_drive"
            done
            ;;
        restore)
            restore_backup
            ;;
        verify)
            get_usb_drives || exit 1
            for drive in "${usb_drives[@]}"; do
                verify_wipe "$drive"
            done
            ;;
        quick-format)
            quick_format
            ;;
        secure-erase)
            secure_erase
            ;;
        config)
            echo "1) Save settings"
            echo "2) Load settings"
            read -r cfg_choice
            [[ "$cfg_choice" == "1" ]] && save_config
            [[ "$cfg_choice" == "2" ]] && load_config
            ;;
        *)
            main_menu
            ;;
    esac
fi
