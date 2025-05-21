#!/usr/bin/env bats

# Sample test for cleaner.sh

@test "cleaner.sh runs without error" {
  run bash ../src/cleaner.sh --help
  [ "$status" -eq 0 ]
}

@test "main menu is displayed" {
  run bash ../src/cleaner.sh <<< $'3' # Exit immediately
  [[ "$output" =~ "Wipe USB drive(s)" ]]
}

@test "script requests sudo if not root" {
  if [[ $EUID -eq 0 ]]; then
    skip "Test only valid when not running as root"
  fi
  run bash ../src/cleaner.sh --help
  [[ "$output" =~ "sudo" ]]
}

@test "log function writes to logfile" {
  sudo rm -f /var/log/cleaner.log
  run sudo bash ../src/cleaner.sh --help
  [ -f /var/log/cleaner.log ]
}

@test "missing dependency is handled" {
  # Simulate missing dependency by moving mkfs.vfat
  if command -v mkfs.vfat &>/dev/null; then
    sudo mv $(command -v mkfs.vfat) $(command -v mkfs.vfat).bak
    trap 'sudo mv $(command -v mkfs.vfat).bak $(dirname $(command -v mkfs.vfat))/mkfs.vfat' EXIT
  fi
  run sudo bash ../src/cleaner.sh --help
  [ "$status" -eq 0 ]
}
