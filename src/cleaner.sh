#!/usr/bin/env bash

# Script Name: cleaner.sh
# Description: A professional script to securely wipe USB drives, optionally create new partitions,
#              and provide enhanced safety, logging, and user experience. Caution: The user must have sudo privileges.
# Usage: ./cleaner.sh

LOGFILE="/var/log/cleaner.log"
DRY_RUN=false
usb_drives=()

# Function to log messages
log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOGFILE"
}

# Function to execute a command or simulate it in dry-run mode
dry_run_check() {
    if $DRY_RUN; then
        log "[Dry Run] $1"
    else
        log "Executing: $1"
        eval "$1"
    fi
}

# Function to install whiptail if not present
install_whiptail() {
    sudo apt-get install -y whiptail
}

# Function to check for mounted partitions and unmount if required
check_mounted() {
    mounted=$(lsblk -no MOUNTPOINT "$usb_drive" | grep -v '^$')
    if [ -n "$mounted" ]; then
        log "Warning: The following partitions on $usb_drive are mounted:"
        log "$mounted"
        echo "You must unmount them before proceeding. Unmount automatically? (y/n)"
        read -r unmount
        if [ "$unmount" == "y" ]; then
            dry_run_check "sudo umount ${usb_drive}*"
        else
            log "Operation cancelled. Please unmount the partitions manually and try again."
            exit 1
        fi
    fi
}

# Function to display all USB drives and let the user choose one or more
get_usb_drives() {
    echo "The following USB drives were found:"
    usb_list=( $(lsblk -o NAME,TRAN | grep 'usb' | awk '{print $1}') )
    if [ ${#usb_list[@]} -eq 0 ]; then
        log "No USB drives found."
        exit 1
    fi

    for i in "${!usb_list[@]}"; do
        device="/dev/${usb_list[$i]}"
        space_info=$(df -h | grep "$device" | awk '{print $3 " used / " $4 " available"}')
        if [ -z "$space_info" ]; then
            space_info="No mounted filesystem"
        fi
        echo "$((i+1)). $device ($space_info)"
    done

    echo "Select one or more USB drives to clean (comma-separated for multiple selections):"
    read -r usb_numbers
    IFS=',' read -r -a selected_drives <<< "$usb_numbers"

    for num in "${selected_drives[@]}"; do
        if [[ ! "$num" =~ ^[0-9]+$ ]] || (( num < 1 || num > ${#usb_list[@]} )); then
            log "Invalid selection: $num"
            get_usb_drives
            return 1
        fi
        usb_drives+=("/dev/${usb_list[$((num-1))]}")
    done

    for usb_drive in "${usb_drives[@]}"; do
        echo "You have chosen $usb_drive. Type 'y' to confirm, or 'n' to cancel."
        read -r confirm
        if [ "$confirm" != 'y' ]; then
            log "Operation cancelled."
            get_usb_drives
        fi
    done
}

# Function to securely wipe the selected USB drive(s)
wipe_disk() {
    for usb_drive in "${usb_drives[@]}"; do
        check_mounted

        log "Cleaning $usb_drive"
        dry_run_check "sudo dd if=/dev/zero of=\"$usb_drive\" bs=1k count=2048 status=progress"
        log "Wipe completed for $usb_drive!"

        echo "Do you want to create a new partition on $usb_drive? Type 'y' to confirm, or 'n' to skip."
        read -r confirm

        if [ "$confirm" == 'y' ]; then
            create_partition
        fi
    done
}

# Function to choose the filesystem for the new partition
choose_filesystem() {
    echo "Select a filesystem for the new partition:"
    echo "1. FAT32"
    echo "2. ext4"
    echo "3. NTFS"
    read -r fs_choice

    case $fs_choice in
        1) fs_type="vfat"; fs_label="FAT32" ;;
        2) fs_type="ext4"; fs_label="EXT4" ;;
        3) fs_type="ntfs"; fs_label="NTFS" ;;
        *) 
            log "Invalid choice. Defaulting to FAT32."
            fs_type="vfat"; fs_label="FAT32" ;;
    esac
}

# Function to create a new partition on the wiped USB drive(s)
create_partition() {
    for usb_drive in "${usb_drives[@]}"; do
        choose_filesystem

        local partition="${usb_drive}1"
        dry_run_check "sudo parted \"$usb_drive\" mklabel msdos"
        dry_run_check "sudo parted -a none \"$usb_drive\" mkpart primary \"$fs_type\" 0% 100%"
        dry_run_check "sudo mkfs.\"$fs_type\" -n \"$fs_label\" \"$partition\""
        log "Partition creation completed on $usb_drive with $fs_label filesystem!"
    done
}

# Function to offer a backup option before wiping
backup_usb_drive() {
    for usb_drive in "${usb_drives[@]}"; do
        echo "Do you want to backup the USB drive before wiping? (y/n)"
        read -r backup
        if [ "$backup" == "y" ]; then
            backup_file="backup_$(basename $usb_drive)_$(date +'%Y%m%d%H%M%S').img"
            dry_run_check "sudo dd if=\"$usb_drive\" of=\"$backup_file\" bs=4M status=progress"
            log "Backup saved to $backup_file"
        fi
    done
}

# Main function to drive the script.
main() {
    # Check if the user has sudo privileges.
    sudo -v
    if [[ $? -ne 0 ]]; then
        log "You need to have sudo privileges to run this script."
        exit 1
    fi

    # Check for dry-run mode
    if [ "$1" == "--dry-run" ]; then
        DRY_RUN=true
        log "Dry run mode activated."
    fi

    # Display menu options and get user input.
    echo "Select an option:"
    echo "1. Wipe your USB drive clean."
    echo "2. Create a new partition on your USB drive."
    echo "3. Exit."

    read -r choice

    case $choice in
        1)
            get_usb_drives
            backup_usb_drive
            wipe_disk
            ;;
        2)
            get_usb_drives
            create_partition
            ;;
        3) exit 0 ;;
        *) 
            log "Invalid choice. Please try again."
            main ;;
    esac
}

# Execute the main function with all script arguments.
main "$@"
