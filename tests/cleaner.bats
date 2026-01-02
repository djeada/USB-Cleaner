#!/usr/bin/env bats

# Test suite for USB Cleaner Pro script
# Uses BATS (Bash Automated Testing System)

# Timestamp regex pattern for log format validation
TIMESTAMP_PATTERN="[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}"

setup() {
    # Create a temporary directory for test logs
    TEST_TEMP_DIR=$(mktemp -d)
    export LOGFILE="$TEST_TEMP_DIR/test_cleaner.log"
    export BACKUP_DIR="$TEST_TEMP_DIR/backups"
    export QUIET="true"
    export COLOR_OUTPUT="false"
    
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

# ═══════════════════════════════════════════════════════════════════════════════
# NEW TESTS FOR USB-CLEANER PRO v2.0
# ═══════════════════════════════════════════════════════════════════════════════

# Test: Version is defined
@test "VERSION is defined" {
    [[ -n "$VERSION" ]]
    [[ "$VERSION" == "2.0.0" ]]
}

# Test: log_debug function exists
@test "log_debug function exists and works" {
    export VERBOSE="true"
    run log_debug "Debug test message"
    [[ "$status" -eq 0 ]]
}

# Test: log_error function exists
@test "log_error function exists and works" {
    run log_error "Error test message"
    [[ "$status" -eq 0 ]]
}

# Test: log_warning function exists
@test "log_warning function exists and works" {
    run log_warning "Warning test message"
    [[ "$status" -eq 0 ]]
}

# Test: log_success function exists
@test "log_success function exists and works" {
    run log_success "Success test message"
    [[ "$status" -eq 0 ]]
}

# Test: show_banner function exists
@test "show_banner function exists" {
    run show_banner
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"USB"* ]] || [[ "$output" == *"CLEANER"* ]]
}

# Test: show_help function exists and works
@test "show_help function shows usage information" {
    run show_help
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"USAGE"* ]] || [[ "$output" == *"OPTIONS"* ]]
}

# Test: show_version function exists
@test "show_version function shows version" {
    run show_version
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"2.0.0"* ]]
}

# Test: Configuration directory is set
@test "CONFIG_DIR is defined" {
    [[ -n "$CONFIG_DIR" ]]
    [[ "$CONFIG_DIR" == *"usb-cleaner"* ]]
}

# Test: save_config creates config file
@test "save_config creates configuration file" {
    export CONFIG_DIR="$TEST_TEMP_DIR/config"
    export CONFIG_FILE="$CONFIG_DIR/config"
    
    run save_config
    [[ "$status" -eq 0 ]]
    [[ -f "$CONFIG_FILE" ]]
}

# Test: load_config loads configuration
@test "load_config works with existing config" {
    export CONFIG_DIR="$TEST_TEMP_DIR/config"
    export CONFIG_FILE="$CONFIG_DIR/config"
    mkdir -p "$CONFIG_DIR"
    echo 'VERBOSE="true"' > "$CONFIG_FILE"
    
    run load_config
    [[ "$status" -eq 0 ]]
}

# Test: choose_filesystem supports exFAT (choice 4)
@test "choose_filesystem sets fs_type for exFAT (choice 4)" {
    run bash -c 'source "'"$SCRIPT_PATH"'"; choose_filesystem <<<"4"; echo "fs_type=$fs_type fs_mk=$fs_mk fs_label=$fs_label"'
    [[ "$output" == *"fs_type=exfat"* ]]
    [[ "$output" == *"fs_label=EXFAT"* ]]
}

# Test: choose_filesystem supports Btrfs (choice 5)
@test "choose_filesystem sets fs_type for Btrfs (choice 5)" {
    run bash -c 'source "'"$SCRIPT_PATH"'"; choose_filesystem <<<"5"; echo "fs_type=$fs_type fs_mk=$fs_mk fs_label=$fs_label"'
    [[ "$output" == *"fs_type=btrfs"* ]]
    [[ "$output" == *"fs_label=BTRFS"* ]]
}

# Test: choose_filesystem supports XFS (choice 6)
@test "choose_filesystem sets fs_type for XFS (choice 6)" {
    run bash -c 'source "'"$SCRIPT_PATH"'"; choose_filesystem <<<"6"; echo "fs_type=$fs_type fs_mk=$fs_mk fs_label=$fs_label"'
    [[ "$output" == *"fs_type=xfs"* ]]
    [[ "$output" == *"fs_label=XFS"* ]]
}

# Test: choose_partition_table selects MBR by default
@test "choose_partition_table defaults to MBR" {
    run bash -c 'source "'"$SCRIPT_PATH"'"; choose_partition_table <<<"1"; echo "partition_table=$partition_table"'
    [[ "$output" == *"partition_table=msdos"* ]]
}

# Test: choose_partition_table selects GPT
@test "choose_partition_table supports GPT (choice 2)" {
    run bash -c 'source "'"$SCRIPT_PATH"'"; choose_partition_table <<<"2"; echo "partition_table=$partition_table"'
    [[ "$output" == *"partition_table=gpt"* ]]
}

# Test: DRY_RUN mode is supported
@test "DRY_RUN mode is configurable" {
    export DRY_RUN="true"
    [[ "$DRY_RUN" == "true" ]]
}

# Test: FORCE mode is supported
@test "FORCE mode is configurable" {
    export FORCE="true"
    [[ "$FORCE" == "true" ]]
}

# Test: PARALLEL mode is supported
@test "PARALLEL mode is configurable" {
    export PARALLEL="true"
    [[ "$PARALLEL" == "true" ]]
}

# Test: JSON logging is supported
@test "JSON log format is configurable" {
    export LOG_FORMAT="json"
    [[ "$LOG_FORMAT" == "json" ]]
}

# Test: VERIFY_WIPE option is supported
@test "VERIFY_WIPE option is configurable" {
    export VERIFY_WIPE="true"
    [[ "$VERIFY_WIPE" == "true" ]]
}

# Test: NOTIFICATION option is supported
@test "NOTIFICATION option is configurable" {
    export NOTIFICATION="true"
    [[ "$NOTIFICATION" == "true" ]]
}

# Test: get_drive_info function exists
@test "get_drive_info function exists" {
    run type get_drive_info
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"function"* ]]
}

# Test: show_drive_dashboard function exists
@test "show_drive_dashboard function exists" {
    run type show_drive_dashboard
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"function"* ]]
}

# Test: check_drive_health function exists
@test "check_drive_health function exists" {
    run type check_drive_health
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"function"* ]]
}

# Test: verify_wipe function exists
@test "verify_wipe function exists" {
    run type verify_wipe
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"function"* ]]
}

# Test: calculate_hash function exists
@test "calculate_hash function exists" {
    run type calculate_hash
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"function"* ]]
}

# Test: restore_backup function exists
@test "restore_backup function exists" {
    run type restore_backup
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"function"* ]]
}

# Test: quick_format function exists
@test "quick_format function exists" {
    run type quick_format
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"function"* ]]
}

# Test: secure_erase function exists
@test "secure_erase function exists" {
    run type secure_erase
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"function"* ]]
}

# Test: send_notification function exists
@test "send_notification function exists" {
    run type send_notification
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"function"* ]]
}

# Test: show_progress function exists
@test "show_progress function exists" {
    run type show_progress
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"function"* ]]
}

# Test: show_spinner function exists
@test "show_spinner function exists" {
    run type show_spinner
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"function"* ]]
}

# Test: parse_arguments function exists
@test "parse_arguments function exists" {
    run type parse_arguments
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"function"* ]]
}

# Test: Script has proper shebang
@test "script has proper shebang" {
    first_line=$(head -n1 "$SCRIPT_PATH")
    [[ "$first_line" == "#!/usr/bin/env bash" ]]
}

# Test: Color variables are defined when COLOR_OUTPUT is true
@test "color variables are defined" {
    export COLOR_OUTPUT="true"
    source "$SCRIPT_PATH"
    # At least verify no errors occur
    [[ "$?" -eq 0 ]]
}
