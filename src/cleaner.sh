#!/usr/bin/env bash

# Script Name: cleaner.sh
# Description: A simple script to wipe USB drives. Caution: The user must have sudo privileges.
# Usage: ./cleaner.sh

get_usb_drive() {
    # Display all USB drives found on the system and let the user choose one.
    local message="$1"

    echo "The following USB drives were found:"
    
    ls -l /dev/disk/by-id/usb*

    echo "$message You have to use the full path:"
    usb_drive=""
    read usb_drive

    echo "You have chosen $usb_drive. Type 'y' to confirm, or 'n' to cancel."
    confirm=""
    read confirm

}

wipe_disk() {
    # Wipe a disk.

    if [ $confirm == 'y' ]; then
        echo "Cleaning $usb_drive"
        sudo dd if=/dev/zero of=$usb_drive bs=1k count=2048
        echo "Done!"
        echo "Do you want to create a new partition on $usb_drive? Type 'y' to confirm, or 'n' to cancel."
        read confirm
        if [ $confirm == 'y' ]; then
            create_partition
        fi
    else
        echo "Cancelled."
        return 1
    fi

    return 0
}

create_partition() {
    # Create a partition on a disk.

      if [ $confirm == 'y' ]; then
        local partition="${usb_drive}1"
        sudo parted $usb_drive mklabel msdos
        sudo parted -a none $usb_drive mkpart  primary fat32 0 2048
        sudo mkfs.vfat -n "Disk" $partition
        echo "Done!"
    else
        echo "Cancelled."
        return 1
    fi

    return 0
}

main() {

    # check if sudo rights are available
    sudo -v
    if [[ $? -ne 0 ]] ; then
        echo "You need to be in the sudoers group to run this script."
        exit 1
    fi

    # if the user provided a USB drive, use it.
    if [ $# -eq 1 ]; then
        usb_drive=$1
        wipe_disk
        return
    elif [ $# -gt 1 ]; then
        echo "Too many arguments."
        exit 1
    fi

    # display menu and get user input
    echo "1. Wipe your disk clean."
    echo "2. Create a new partition on your disk."
    echo "3. Exit."

    read choice

    case $choice in
        1) get_usb_drive "Choose the drive to clean." && wipe_disk ;;
        2) get_usb_drive "Choose the drive to create a partition on." && create_partition ;;
        3) exit ;;
        *) echo "Invalid choice. Please try again."
            main ;;
    esac
}

main "$@"
