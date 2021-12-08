# USB-Cleaner
A little bash script for wiping your USB devices clean from the terminal. The user must be a sudoer in order to run the script.

<h1>Requirements</h1>
For this script to work, you need to have bash installed on your system. If you don't have bash and you are on Debian based system, you can install it with the following command:

    apt install bash

You can switch to bash by typing the following command:

    chsh -s /bin/bash

<h1>Usage</h1>

1. Clone the repository:

    git clone https://github.com/djeada/USB-Cleaner.git

2. Run the script:

    cd src
    ./cleaner.sh

The script will ask you for the USB device you want to wipe. If you don't have a USB device connected, you can type "exit" to exit the script. 

<h1>Contributing</h1>
It is an open source project, so feel free to contribute!

<h1>License</h1>
This project is licensed under the MIT license.

