#!/usr/bin/env bash

get_usb_drive() {
	sudo blkid
	
	echo -e "\nFind your usb drive."
	echo "If the following appears in the output /dev/sdb1, then your usb drive is /dev/sdb."
	echo "Providing an empty string will take you back to the main menu."	

	read drive
	
	if [[ -z "$drive" ]] ; then
		return
	else
		echo "You have provided the following drive: $drive"
		echo "Enter yes if you are absolutely sure that you want to continue this operation."
		
		read choice

		if [[ $choice == "yes" ]] ; then
			eval "$1=$drive $2=$choice"
		fi
	fi
}

wipe_disk() {

	drive=""
	choice=""
	get_usb_drive drive choice

	if [[ $choice == "yes" ]] ; then 
		sudo dd if=/dev/zero of=$drive bs=1k count=2048 
		echo "Eject and reinstall the disc. Then choose option 2."
	fi
	
	main
}

create_partition() {

	drive=""
	choice=""
	get_usb_drive drive choice

	if [[ $choice == "yes" ]] ; then 
		partition="${drive}1"

		sudo parted $drive mklabel msdos
		sudo parted -a none $drive mkpart  primary fat32 0 2048
		sudo mkfs.vfat -n "Disk" $partition

		echo "Congratulations you have wiped your disk clean and created a new partition on the disk."

	fi
}

main() {
	echo "What would you like to do?"
	echo "1. Wipe the disk clean."
	echo "2. Create a partition on the disk."

	read choice

	if [[ $choice -eq 1 ]] ; then
		wipe_disk
	elif [[ $choice -eq 2 ]] ; then
		create_partition
	else
		echo "Not a valid option."
	fi
}

main "$@"
