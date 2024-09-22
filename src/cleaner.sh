#!/usr/bin/env bash

LOGFILE="/var/log/cleaner.log"
DRY_RUN=false
usb_drives=()
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOGFILE"
}

dry_run_check() {
    if $DRY_RUN; then
        log "[Dry Run] $1"
    else
        log "Executing: $1"
        eval "$1"
    fi
}

check_dependencies() {
    deps=(whiptail lsblk parted mkfs.vfat mkfs.ext4 mkfs.ntfs dd pv)
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            log "Dependency $dep not found. Installing..."
            dry_run_check "sudo apt-get install -y $dep"
        fi
    done
}

get_usb_drives() {
    usb_list=($(lsblk -dplno NAME,TRAN | grep ' usb$' | awk '{print $1}'))
    if [ ${#usb_list[@]} -eq 0 ]; then
        log "No USB drives found."
        exit 1
    fi

    options=()
    for drive in "${usb_list[@]}"; do
        size=$(lsblk -dno SIZE "$drive")
        model=$(udevadm info --query=property --name="$drive" | grep 'ID_MODEL=' | cut -d'=' -f2)
        options+=("$drive" "$model ($size)")
    done

    selected_drives=$(whiptail --title "Select USB Drives" --checklist "Choose drives to clean:" 20 78 10 "${options[@]}" 3>&1 1>&2 2>&3)
    if [ $? -ne 0 ]; then
        log "Operation cancelled by user."
        exit 1
    fi

    IFS=" " read -r -a usb_drives <<< "$selected_drives"
    for usb_drive in "${usb_drives[@]}"; do
        confirm=$(whiptail --title "Confirm Drive" --yesno "You have chosen $usb_drive. Proceed?" 8 60 3>&1 1>&2 2>&3)
        if [ $? -ne 0 ]; then
            log "Operation cancelled by user."
            get_usb_drives
            return
        fi
    done
}

check_mounted() {
    mount_points=$(lsblk -no MOUNTPOINT "$usb_drive" | grep -v '^$')
    if [ -n "$mount_points" ]; then
        unmount=$(whiptail --title "Unmount Partitions" --yesno "Partitions on $usb_drive are mounted:\n$mount_points\nUnmount automatically?" 12 60 3>&1 1>&2 2>&3)
        if [ $? -eq 0 ]; then
            dry_run_check "sudo umount ${usb_drive}*"
        else
            log "Please unmount partitions manually and retry."
            exit 1
        fi
    fi
}

wipe_disk() {
    for usb_drive in "${usb_drives[@]}"; do
        check_mounted
        backup_usb_drive

        wipe_method=$(whiptail --title "Select Wipe Method" --menu "Choose a wipe method for $usb_drive:" 15 60 4 \
            "1" "Single Pass (Zero Fill)" \
            "2" "Triple Pass (DoD 5220.22-M)" \
            "3" "Seven Pass (Guttman)" 3>&1 1>&2 2>&3)

        if [ $? -ne 0 ]; then
            log "Operation cancelled by user."
            exit 1
        fi

        case $wipe_method in
            1)
                log "Starting single pass wipe on $usb_drive"
                dry_run_check "sudo dd if=/dev/zero | pv --rate --eta | sudo dd of=\"$usb_drive\" bs=4M status=none"
                ;;
            2)
                log "Starting triple pass wipe on $usb_drive"
                for pass in {1..3}; do
                    log "Pass $pass of 3"
                    if [ $pass -eq 2 ]; then
                        dry_run_check "sudo dd if=/dev/urandom | pv --rate --eta | sudo dd of=\"$usb_drive\" bs=4M status=none"
                    else
                        dry_run_check "sudo dd if=/dev/zero | pv --rate --eta | sudo dd of=\"$usb_drive\" bs=4M status=none"
                    fi
                done
                ;;
            3)
                log "Starting seven pass wipe on $usb_drive"
                for pass in {1..7}; do
                    log "Pass $pass of 7"
                    if [ $((pass % 2)) -eq 0 ]; then
                        dry_run_check "sudo dd if=/dev/urandom | pv --rate --eta | sudo dd of=\"$usb_drive\" bs=4M status=none"
                    else
                        dry_run_check "sudo dd if=/dev/zero | pv --rate --eta | sudo dd of=\"$usb_drive\" bs=4M status=none"
                    fi
                done
                ;;
        esac
        log "Wipe completed for $usb_drive"
        create_partition_prompt
    done
}

choose_filesystem() {
    fs_choice=$(whiptail --title "Select Filesystem" --menu "Choose a filesystem for the new partition:" 15 60 4 \
        "1" "FAT32" \
        "2" "ext4" \
        "3" "NTFS" 3>&1 1>&2 2>&3)

    case $fs_choice in
        1) fs_type="vfat"; fs_label="FAT32" ;;
        2) fs_type="ext4"; fs_label="EXT4" ;;
        3) fs_type="ntfs"; fs_label="NTFS" ;;
        *) fs_type="vfat"; fs_label="FAT32" ;;
    esac
}

create_partition() {
    for usb_drive in "${usb_drives[@]}"; do
        choose_filesystem
        partition="${usb_drive}1"
        dry_run_check "sudo parted \"$usb_drive\" --script mklabel msdos mkpart primary \"$fs_type\" 0% 100%"

        case $fs_type in
            vfat) dry_run_check "sudo mkfs.vfat -n \"$fs_label\" \"$partition\"" ;;
            ext4) dry_run_check "sudo mkfs.ext4 -L \"$fs_label\" \"$partition\"" ;;
            ntfs) dry_run_check "sudo mkfs.ntfs -f -L \"$fs_label\" \"$partition\"" ;;
        esac

        log "Partition created on $usb_drive with $fs_label filesystem"
    done
}

create_partition_prompt() {
    create_part=$(whiptail --title "Create Partition" --yesno "Do you want to create a new partition on the wiped drive(s)?" 8 60 3>&1 1>&2 2>&3)
    if [ $? -eq 0 ]; then
        create_partition
    fi
}

backup_usb_drive() {
    backup=$(whiptail --title "Backup Drive" --yesno "Do you want to backup $usb_drive before wiping?" 8 60 3>&1 1>&2 2>&3)
    if [ $? -eq 0 ]; then
        backup_file="$TEMP_DIR/backup_$(basename $usb_drive)_$(date +'%Y%m%d%H%M%S').img"
        dry_run_check "sudo dd if=\"$usb_drive\" | pv --rate --eta | sudo dd of=\"$backup_file\" bs=4M status=none"
        log "Backup saved to $backup_file"
    fi
}

main_menu() {
    while true; do
        choice=$(whiptail --title "USB Cleaner" --menu "Choose an option:" 15 60 4 \
            "1" "Wipe USB drive(s)" \
            "2" "Create partition on USB drive(s)" \
            "3" "Exit" 3>&1 1>&2 2>&3)

        case $choice in
            1)
                get_usb_drives
                wipe_disk
                ;;
            2)
                get_usb_drives
                create_partition
                ;;
            3)
                exit 0
                ;;
            *)
                log "Invalid choice."
                ;;
        esac
    done
}

check_dependencies

if [ "$1" == "--dry-run" ]; then
    DRY_RUN=true
    log "Dry run mode activated."
fi

sudo -v
if [[ $? -ne 0 ]]; then
    log "You need sudo privileges to run this script."
    exit 1
fi

main_menu
