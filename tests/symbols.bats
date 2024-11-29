#!/usr/bin/env bats

setup() {
  bats_load_library bats-support
  bats_load_library bats-assert
  load "../lib/utils.sh"
  load "../src/config.sh"
  load "../src/symbols.sh"

  # Mock http.get to return the output of the example command
  http_get_mock() {
    local url=$1
    case "$url" in
      *//api*)
        echo '{"symbols":[{"symbol":"BTCUSDT"},{"symbol":"ETHUSDT"}]}'
        ;;
      *)
        echo '{"error":"unexpected"}'
        return 1
        ;;
    esac
  }

  # Override http.get function
  http.get() {
    http_get_mock "$@"
  }
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

# Test: symbols should fail for an invalid response
@test "symbols fails for an invalid response" {
  run symbols um
  assert_failure
  assert_line --partial "Error:"
}
