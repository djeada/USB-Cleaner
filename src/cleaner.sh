#!/usr/bin/env bash

if [[ $EUID -ne 0 ]]; then
    exec sudo "$0" "$@"
fi

LOGFILE="/var/log/cleaner.log"
usb_drives=()
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOGFILE"
}

check_dependencies() {
    deps=(lsblk parted mkfs.vfat mkfs.ext4 mkfs.ntfs dd pv wipefs)
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            apt-get install -y $dep
        fi
    done
}

get_usb_drives() {
    usb_list=($(lsblk -dplno NAME,TRAN | grep ' usb$' | awk '{print $1}'))
    if [ ${#usb_list[@]} -eq 0 ]; then
        log "No USB drives found."
        return 1
    fi
    echo "Available USB Drives:"
    for i in "${!usb_list[@]}"; do
        drive="${usb_list[$i]}"
        size=$(lsblk -dno SIZE "$drive")
        model=$(udevadm info --query=property --name="$drive" | grep 'ID_MODEL=' | cut -d'=' -f2)
        echo "$((i+1)). $drive - $model ($size)"
    done
    echo -n "Select drives by space-separated numbers: "
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
        echo -n "You have chosen $usb_drive. Proceed? [y/n]: "
        read -r confirm
        if [ "$confirm" != "y" ]; then
            log "Operation cancelled by user."
            return 1
        fi
    done
}

check_mounted() {
    parts=$(lsblk -lno NAME "$usb_drive" | tail -n +2)
    for p in $parts; do
        mp=$(lsblk -no MOUNTPOINT "/dev/$p")
        if [ -n "$mp" ]; then
            log "Found mounted partition /dev/$p at $mp"
            echo -n "Unmount automatically? [y/n]: "
            read -r unmount
            if [ "$unmount" = "y" ]; then
                log "Unmounting /dev/$p"
                umount -f "/dev/$p" || true
            else
                log "Please unmount partitions manually."
                return 1
            fi
        fi
    done
}

backup_usb_drive() {
    echo -n "Backup $usb_drive before wiping? [y/n]: "
    read -r backup
    if [ "$backup" = "y" ]; then
        backup_file="$TEMP_DIR/backup_$(basename "$usb_drive")_$(date +'%Y%m%d%H%M%S').img"
        log "Backing up $usb_drive to $backup_file"
        dd if="$usb_drive" of="$backup_file" bs=4M status=progress conv=fsync
        sync
        log "Backup completed: $backup_file"
    fi
}

wipe_disk() {
    for usb_drive in "${usb_drives[@]}"; do
        check_mounted || return 1
        backup_usb_drive
        echo "Wipe method:"
        echo "1) Single Pass (Zero)"
        echo "2) Triple Pass (DoD)"
        echo "3) Seven Pass (Guttman)"
        echo -n "Choice: "
        read -r wipe_method
        if ! [[ $wipe_method =~ ^[1-3]$ ]]; then
            log "Invalid choice."
            return 1
        fi
        wipefs -a "$usb_drive"
        sync
        case $wipe_method in
            1)
                log "Wiping $usb_drive single pass zero"
                dd if=/dev/zero of="$usb_drive" bs=4M status=progress conv=fsync
                sync
                ;;
            2)
                log "Wiping $usb_drive triple pass"
                for pass in {1..3}; do
                    log "Pass $pass of 3"
                    if [ $pass -eq 2 ]; then
                        dd if=/dev/urandom of="$usb_drive" bs=4M status=progress conv=fsync
                    else
                        dd if=/dev/zero of="$usb_drive" bs=4M status=progress conv=fsync
                    fi
                    sync
                done
                ;;
            3)
                log "Wiping $usb_drive seven pass"
                for pass in {1..7}; do
                    log "Pass $pass of 7"
                    if [ $((pass % 2)) -eq 0 ]; then
                        dd if=/dev/urandom of="$usb_drive" bs=4M status=progress conv=fsync
                    else
                        dd if=/dev/zero of="$usb_drive" bs=4M status=progress conv=fsync
                    fi
                    sync
                done
                ;;
        esac
        sync
        log "Wipe completed for $usb_drive"
        create_partition_prompt
    done
}

choose_filesystem() {
    echo "Filesystem:"
    echo "1) FAT32"
    echo "2) ext4"
    echo "3) NTFS"
    echo -n "Choice: "
    read -r fs_choice
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
        log "Creating partition on $usb_drive"
        wipefs -a "$usb_drive"
        sync
        parted "$usb_drive" --script mklabel msdos || return 1
        parted "$usb_drive" --script mkpart primary "$fs_type" 0% 100% || return 1
        sync
        partition="${usb_drive}1"
        if [ "$fs_type" = "vfat" ]; then
            mkfs.vfat -n "$fs_label" "$partition"
        elif [ "$fs_type" = "ext4" ]; then
            mkfs.ext4 -L "$fs_label" "$partition"
        elif [ "$fs_type" = "ntfs" ]; then
            mkfs.ntfs -f -L "$fs_label" "$partition"
        fi
        sync
        log "Partition created: $partition with $fs_label"
    done
}

create_partition_prompt() {
    echo -n "Create partition? [y/n]: "
    read -r create_part
    if [ "$create_part" = "y" ]; then
        create_partition
    fi
}

main_menu() {
    while true; do
        echo "1) Wipe USB drive(s)"
        echo "2) Create partition on USB drive(s)"
        echo "3) Exit"
        echo -n "Choice: "
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
                exit 0
                ;;
            *)
                log "Invalid choice."
                ;;
        esac
    done
}

check_dependencies
main_menu
