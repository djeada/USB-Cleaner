#!/usr/bin/env bash

# Script Name: cleaner.sh
# Description: A professional script to securely wipe USB drives and optionally create new partitions. 
#              Caution: The user must have sudo privileges.
# Usage: ./cleaner.sh

# Function to display all USB drives found on the system and let the user choose one.
get_usb_drive() {
    local message="$1"

    echo "The following USB drives were found:"
    usb_list=( $(lsblk -o NAME,TRAN | grep 'usb' | awk '{print $1}') )
    if [ ${#usb_list[@]} -eq 0 ]; then
        echo "No USB drives found."
        exit 1
    fi

    for i in "${!usb_list[@]}"; do
        echo "$((i+1)). /dev/${usb_list[$i]}"
    done

    echo "$message Please provide the number of the USB drive:"
    read -r usb_number

    if [[ ! "$usb_number" =~ ^[0-9]+$ ]] || (( usb_number < 1 || usb_number > ${#usb_list[@]} )); then
        echo "Invalid selection. Please try again."
        get_usb_drive "$message"
    else
        usb_drive="/dev/${usb_list[$((usb_number-1))]}"
        echo "You have chosen $usb_drive. Type 'y' to confirm, or 'n' to cancel."
        read -r confirm
        if [ "$confirm" != 'y' ]; then
            echo "Operation cancelled."
            get_usb_drive "$message"
        fi
    fi
}

# Function to securely wipe the selected USB drive.
wipe_disk() {
    if [ "$confirm" == 'y' ]; then
        echo "Cleaning $usb_drive"
        sudo dd if=/dev/zero of="$usb_drive" bs=1k count=2048 status=progress
        echo "Wipe completed!"

        echo "Do you want to create a new partition on $usb_drive? Type 'y' to confirm, or 'n' to cancel."
        read -r confirm

        if [ "$confirm" == 'y' ]; then
            create_partition
        fi
    else
        echo "Operation cancelled."
        return 1
    fi

    return 0
}

# Function to create a new partition on the wiped USB drive.
create_partition() {
    if [ "$confirm" == 'y' ]; then
        local partition="${usb_drive}1"
        sudo parted "$usb_drive" mklabel msdos
        sudo parted -a none "$usb_drive" mkpart primary fat32 0% 100%
        sudo mkfs.vfat -n "Disk" "$partition"
        echo "Partition creation completed!"
    else
        echo "Operation cancelled."
        return 1
    fi

    return 0
}

# Main function to drive the script.
main() {
    # Check if the user has sudo privileges.
    sudo -v
    if [[ $? -ne 0 ]]; then
        echo "You need to have sudo privileges to run this script."
        exit 1
    fi

    # If a USB drive is provided as an argument, use it.
    if [ $# -eq 1 ]; then
        usb_drive=$1
        wipe_disk
        return
    elif [ $# -gt 1 ]; then
        echo "Too many arguments provided."
        exit 1
    fi

    # Display menu options and get user input.
    echo "Select an option:"
    echo "1. Wipe your USB drive clean."
    echo "2. Create a new partition on your USB drive."
    echo "3. Exit."

    read -r choice

    case $choice in
        1) get_usb_drive "Choose the drive to clean:" && wipe_disk ;;
        2) get_usb_drive "Choose the drive to create a partition on:" && create_partition ;;
        3) exit 0 ;;
        *) 
            echo "Invalid choice. Please try again."
            main ;;
    esac
}

# Execute the main function with all script arguments.
main "$@"
