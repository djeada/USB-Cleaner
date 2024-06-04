# USB-Cleaner

A little bash script for wiping your USB devices clean from the terminal. The user must be a sudoer in order to run the script.

## Requirements

For this script to work, you need to have bash installed on your system. If you don't have bash and you are on a Debian-based system, you can install it with the following command:

```bash
apt install bash
```

You can switch to bash by typing the following command:

```bash
chsh -s /bin/bash
```

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

## Contributing

This is an open-source project, so feel free to contribute! To get started, fork the repository, make your changes, and submit a pull request.

## License

This project is licensed under the <a href="https://github.com/djeada/USB-Cleaner/blob/main/LICENSE">MIT license</a>.
