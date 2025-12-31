#!/usr/bin/env bats

# Test suite for USB Cleaner script
# Uses BATS (Bash Automated Testing System)

# Timestamp regex pattern for log format validation
TIMESTAMP_PATTERN="[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}"

setup() {
    # Create a temporary directory for test logs
    TEST_TEMP_DIR=$(mktemp -d)
    export LOGFILE="$TEST_TEMP_DIR/test_cleaner.log"
    
    # Set script path for tests that need to run in subshell
    SCRIPT_PATH="$BATS_TEST_DIRNAME/../src/cleaner.sh"
    
    # Source the cleaner script to get access to functions
    source "$SCRIPT_PATH"
}

teardown() {
    # Clean up temporary files
    if [[ -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}

# Helper function to test choose_filesystem with given input
# Usage: run_choose_filesystem "1"
run_choose_filesystem() {
    local input="$1"
    run bash -c 'source "'"$SCRIPT_PATH"'"; choose_filesystem <<<"'"$input"'"; echo "fs_type=$fs_type fs_mk=$fs_mk fs_label=$fs_label"'
}

# Test: log function writes to log file
@test "log function writes message to log file" {
    log "Test message"
    
    # Check that log file exists
    [[ -f "$LOGFILE" ]]
    
    # Check that log file contains the message
    grep -q "Test message" "$LOGFILE"
}

# Test: log function includes timestamp
@test "log function includes timestamp in output" {
    log "Timestamp test"
    
    # Check for timestamp format using pattern variable
    grep -qE "^${TIMESTAMP_PATTERN} - Timestamp test$" "$LOGFILE"
}

# Test: log function handles empty messages
@test "log function handles empty message" {
    log ""
    
    # Check that log file exists (still logs even with empty message)
    [[ -f "$LOGFILE" ]]
}

# Test: log function handles special characters
@test "log function handles special characters" {
    log "Test with special chars: !@#$%^&*()"
    
    # Check that log file contains the message with special chars
    grep -q "special chars" "$LOGFILE"
}

# Test: LOGFILE can be overridden via environment variable
@test "LOGFILE can be overridden via environment variable" {
    custom_log="$TEST_TEMP_DIR/custom.log"
    LOGFILE="$custom_log" log "Custom log test"
    
    # Check that custom log file exists
    [[ -f "$custom_log" ]]
    
    # Check that message was written to custom log
    grep -q "Custom log test" "$custom_log"
}

# Test: usb_drives array is initialized as empty
@test "usb_drives array is initialized" {
    [[ "${#usb_drives[@]}" -ge 0 ]]
}

# Test: TEMP_DIR is created
@test "TEMP_DIR is created" {
    [[ -d "$TEMP_DIR" ]]
}

# Test: choose_filesystem sets fs_type for FAT32
@test "choose_filesystem sets fs_type for FAT32 (choice 1)" {
    run_choose_filesystem "1"
    [[ "$output" == *"fs_type=fat32"* ]]
    [[ "$output" == *"fs_mk=mkfs.vfat"* ]]
    [[ "$output" == *"fs_label=FAT32"* ]]
}

# Test: choose_filesystem sets fs_type for ext4
@test "choose_filesystem sets fs_type for ext4 (choice 2)" {
    run_choose_filesystem "2"
    [[ "$output" == *"fs_type=ext4"* ]]
    [[ "$output" == *"fs_mk=mkfs.ext4"* ]]
    [[ "$output" == *"fs_label=EXT4"* ]]
}

# Test: choose_filesystem sets fs_type for NTFS
@test "choose_filesystem sets fs_type for NTFS (choice 3)" {
    run_choose_filesystem "3"
    [[ "$output" == *"fs_type=ntfs"* ]]
    [[ "$output" == *"fs_mk=mkfs.ntfs"* ]]
    [[ "$output" == *"fs_label=NTFS"* ]]
}

# Test: choose_filesystem defaults to FAT32 for invalid input
@test "choose_filesystem defaults to FAT32 for invalid input" {
    run_choose_filesystem "invalid"
    [[ "$output" == *"fs_type=fat32"* ]]
    [[ "$output" == *"fs_mk=mkfs.vfat"* ]]
    [[ "$output" == *"fs_label=FAT32"* ]]
}

# Test: choose_filesystem defaults to FAT32 for out of range input
@test "choose_filesystem defaults to FAT32 for out of range input" {
    run_choose_filesystem "99"
    [[ "$output" == *"fs_type=fat32"* ]]
    [[ "$output" == *"fs_mk=mkfs.vfat"* ]]
    [[ "$output" == *"fs_label=FAT32"* ]]
}

# Test: multiple log calls append to file
@test "multiple log calls append to file" {
    log "First message"
    log "Second message"
    log "Third message"
    
    # Count lines containing log messages
    count=$(grep -c "message" "$LOGFILE")
    [[ "$count" -eq 3 ]]
}
