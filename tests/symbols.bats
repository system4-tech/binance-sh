#!/usr/bin/env bats

setup() {
  bats_load_library bats-support
  bats_load_library bats-assert
  load "../lib/utils.sh"
  load "../src/main.sh"
}

# Test: symbols should return a list of symbols for a valid product
@test "symbols returns list of symbols for a valid product" {
  run symbols spot
  assert_success
  assert_line "BTCUSDT"
  assert_line "ETHUSDT"
}

# Test: symbols should fail if product argument is missing
@test "symbols fails when product argument is missing" {
  run symbols
  assert_failure
}

# Test: symbols should fail for an invalid product
@test "symbols fails for an invalid product" {
  run symbols invalid_product
  assert_failure
}
