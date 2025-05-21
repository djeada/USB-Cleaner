# USB-Cleaner

A simple and efficient bash script designed to securely wipe USB devices directly from the terminal. This script ensures complete data erasure, making your USB devices clean and safe for reuse or disposal. 

![usb_cleaner](https://github.com/user-attachments/assets/022549ba-1703-4681-935b-776f78d862ba)

## Features

- The script uses low-level data writing methods to securely wipe the contents of your USB drive, making it difficult for any data recovery tools to retrieve the erased data.
- After wiping a USB drive, the script offers the option to create a new partition, allowing you to format the drive with your preferred filesystem, such as FAT32, ext4, or NTFS.
- Before any operation is performed, the script ensures that the user confirms the action. It also checks if the drive is mounted, preventing accidental data loss by unmounting partitions if necessary.
- The script can create a backup image of the USB drive before wiping it, ensuring that your data is safely stored if needed.
- For users who want to see what actions will be performed without making any actual changes, a dry run mode is available.

## Requirements

To run the `cleaner.sh` script, ensure your system meets the following requirements:

### 1. **Operating System**
   - Linux-based operating system (Ubuntu, Debian, CentOS, etc.)
   - The script has been tested on Ubuntu 20.04 LTS and later.

### 2. **Sudo Privileges**
   - The user running the script must have `sudo` privileges. The script requires elevated permissions to perform disk operations, such as wiping and partitioning USB drives.

### 3. **Dependencies**
   - The following utilities must be installed on your system:
     - `lsblk`: To list information about block devices.
     - `df`: To display disk space usage.
     - `parted`: For partition manipulation.
     - `mkfs`: To create file systems (supports FAT32, ext4, NTFS, etc.).
     - `dd`: For low-level copying of data.
     - `grep`, `awk`, `sed`: For text processing within the script.

### 4. **Disk Space**
   - Sufficient disk space on the system to handle backups if the backup option is used.

### 5. **USB Drives**
   - The script is designed to work with USB drives. Ensure that the USB drive(s) you intend to wipe or partition are connected to the system.

### 6. **Logging Directory**
   - The script writes logs to `/var/log/cleaner.log`. Ensure that this directory is writable by the user running the script. If the directory does not exist, it should be created with appropriate permissions.

### 7. **Internet Access (Optional)**
   - For installing missing dependencies via a package manager (e.g., `apt-get` for Ubuntu/Debian).

### 8. **Backup Space**
   - If the backup option is enabled, ensure that there is enough space available on your system to store the backup image files, which can be as large as the USB drive's total capacity.

## Usage

1. Clone the repository:

    ```bash
    git clone https://github.com/djeada/USB-Cleaner.git
    ```

2. Navigate to the source directory:

    ```bash
    cd USB-Cleaner/src
    ```

3. Run the script:

    ```bash
    ./cleaner.sh
    ```

The script will prompt you to select the USB device you want to wipe. If you don't have a USB device connected, you can type `exit` to exit the script.

## Usage Scenario Overview
This scenario simulates a user interacting with a `cleaner.sh` script designed to manage USB drives. The script provides options to wipe a USB drive clean and create a new partition, with a focus on ensuring the user is fully informed and consents to potentially destructive actions.

### **Initial Script Execution:**

```bash
$ sudo ./cleaner.sh
```

The script is executed with `sudo` because managing disk partitions and wiping drives requires elevated privileges. Without `sudo`, the script wouldn't have the necessary permissions to perform these operations.

### **Script Output:**

```
Select an option:
1. Wipe your USB drive clean.
2. Create a new partition on your USB drive.
3. Exit.
```

The script presents a simple menu with three options. This approach makes it clear to the user what actions they can take. The first option allows the user to wipe a USB drive, the second to create a new partition, and the third to exit the script without making changes.

### **User Action: Selecting Option 1 (Wipe USB Drive):**

```bash
1
```

The user chooses to wipe a USB drive. This is a potentially destructive action, so the script will proceed with caution, ensuring that the user is fully aware of the implications.

### **Script Displays Available USB Drives:**

```
The following USB drives were found:
1. /dev/sdb (7.4G used / 8.0G available)
2. /dev/sdc (No mounted filesystem)

Select one or more USB drives to clean (comma-separated for multiple selections):
```

The script lists all detected USB drives, displaying relevant information such as the used and available space. This information helps the user identify the correct drive to wipe. The script also allows multiple drives to be selected at once, which is useful for batch operations.

### **User Action: Selecting `/dev/sdc` (Drive 2):**

```bash
2
```

The user selects `/dev/sdc`, the second USB drive, for wiping. The script will now focus on this drive for the subsequent operations.

### **Script Requests Confirmation:**

```
You have chosen /dev/sdc. Type 'y' to confirm, or 'n' to cancel.
```

To prevent accidental data loss, the script asks for confirmation. This step is crucial, as wiping a drive is irreversible. The script ensures that the user is deliberately choosing to proceed.

### **User Action: Confirming the Choice:**

```bash
y
```

The user confirms their choice by typing `y`. The script can now proceed with the wipe process, but it will first check for any mounted partitions and offer a backup option.

### **Script Checks for Mounted Partitions and Offers Backup:**

```
No mounted partitions found on /dev/sdc.

Do you want to backup the USB drive before wiping? (y/n)
```

The script detects that there are no mounted partitions on `/dev/sdc`, which simplifies the process. However, it still offers the user the option to back up the drive. This is a safety feature to prevent unintended data loss.

### **User Action: Choosing Not to Back Up:**

```bash
n
```

The user opts not to back up the drive. This decision implies that the user is either sure that the data is not needed or that they have already backed it up elsewhere.

### **Script Wipes the Selected USB Drive:**

```
Cleaning /dev/sdc
2048+0 records in
2048+0 records out
2097152 bytes (2.1 MB, 2.0 MiB) copied, 0.0104543 s, 201 MB/s
Wipe completed for /dev/sdc!
```

The script begins wiping the drive, typically by writing zeros or random data to overwrite the existing data. The output shows the progress of the wipe, including the amount of data processed and the speed. This transparency helps the user understand what is happening in real-time.

### **Script Offers to Create a New Partition:**

```
Do you want to create a new partition on /dev/sdc? Type 'y' to confirm, or 'n' to skip.
```

After wiping the drive, the script offers to create a new partition. This is a common next step after wiping a drive, as the drive needs a new partition to be usable. The script once again asks for confirmation to ensure the user wants to proceed.

### **User Action: Choosing to Create a New Partition:**

```bash
y
```

The user confirms that they want to create a new partition. This action will reinitialize the drive with a new filesystem, making it ready for use again.

### **Script Prompts for Filesystem Selection:**

```
Select a filesystem for the new partition:
1. FAT32
2. ext4
3. NTFS
```

The script provides a choice of filesystems. Each filesystem has its own use cases:
  - **FAT32** is widely compatible across different operating systems but has limitations like a 4GB file size limit.
  - **ext4** is commonly used in Linux environments and supports larger files and better performance.
  - **NTFS** is often used in Windows environments and supports advanced features like encryption.

### **User Action: Selecting ext4 (Option 2):**

```bash
2
```

The user chooses `ext4`, likely because they plan to use the USB drive with a Linux system. The script will now create the partition with this filesystem.

### **Script Creates the Partition:**

```
Creating a new partition on /dev/sdc with ext4 filesystem...
Partition creation completed on /dev/sdc with EXT4 filesystem!
```

The script creates the new partition using the selected filesystem. It confirms the completion of this task, so the user knows the drive is ready to use.

### **Script Returns to Main Menu or Exits Based on User Input:**

```
Select an option:
1. Wipe your USB drive clean.
2. Create a new partition on your USB drive.
3. Exit.
```

The script returns to the main menu, allowing the user to perform additional operations or exit. This loop structure is user-friendly, providing flexibility for further actions without needing to restart the script.

### **User Action: Exiting the Script (Option 3):**

```bash
3
```

Exiting script. Thank you for using cleaner.sh!

## Contributing

This is an open-source project, so feel free to contribute! To get started, fork the repository, make your changes, and submit a pull request.

## License

This project is licensed under the <a href="https://github.com/djeada/USB-Cleaner/blob/main/LICENSE">MIT license</a>.
