#!/usr/bin/env bats

setup() {
  bats_load_library bats-support
  bats_load_library bats-assert
  load "../lib/utils.sh"
  load "../src/config.sh"
  load "../src/klines.sh"
}

# Test: klines should return kline data for valid inputs
@test "klines returns kline data for valid inputs" {
  run klines spot BTCUSDT 1d 2021-01-01 2021-01-02
  assert_success
  assert_output --partial "28923.63"
  assert_output --partial "29331.69"
}

# Test: klines should fail if product argument is missing
@test "klines fails when product argument is missing" {
  run klines
  assert_failure
}

# Test: klines should fail if symbol argument is missing
@test "klines fails when symbol argument is missing" {
  run klines spot
  assert_failure
}

# Test: klines should fail if interval argument is missing
@test "klines fails when interval argument is missing" {
  run klines spot BTCUSDT
  assert_failure
}

# Test: klines should return klines with default dates if start_time and end_time are omitted
@test "klines returns klines if start_time and end_time are omitted" {
  run klines spot BTCUSDT 1d
  assert_success
}

# Test: klines should fail if start_time is invalid
@test "klines fails when start_time is invalid" {
  run klines spot BTCUSDT 1d "invalid-date" "2021-01-02"
  assert_failure
}

# Test: klines should fail if end_time is invalid
@test "klines fails when end_time is invalid" {
  run klines spot BTCUSDT 1d "2021-01-01" "invalid-date"
  assert_failure
}
