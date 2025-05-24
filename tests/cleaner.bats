#!/usr/bin/env bats

# Sample test for cleaner.sh

setup() {
  TEST_DIR=$(mktemp -d)
  CLEANER_SRC="/workspaces/USB-Cleaner/src/cleaner.sh"
  cp "$CLEANER_SRC" "$TEST_DIR/cleaner.sh"
  cd "$TEST_DIR"
}

teardown() {
  rm -rf "$TEST_DIR"
}

@test "cleaner.sh runs and shows help with -h" {
  run bash cleaner.sh -h
  [ "$status" -eq 0 ]
  [[ "$output" == *"usage"* || "$output" == *"Usage"* ]]
}
