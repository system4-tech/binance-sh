#!/usr/bin/env bats

setup() {
  bats_load_library bats-support
  bats_load_library bats-assert
  load "../lib/utils.sh"
  load "../src/config.sh"
  load "../src/klines.sh"

  # Mock http.get to return the output of the example command
  http_get_mock() {
    local url=$1
    case "$url" in
      *startTime=1609459200000*)
        echo '[[1609459200000,"28923.63000000","29600.00000000","28624.57000000","29331.69000000","54182.92501100",1609545599999,"1582526989.16187265",1314910,"27455.80172500","802247744.54510409","0"],[1609545600000,"29331.70000000","33300.00000000","28946.53000000","32178.33000000","129993.87336200",1609631999999,"4073842163.67154117",2245922,"67446.30524600","2110334723.88714587","0"]]'
        ;;
      *startTime=1609459200000\&endTime=1609459200000*)
        echo '[]'
        ;;
      *startTime=1609631999999*)
        echo '[]'
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

# Test: klines should return kline data for valid inputs
@test "klines returns kline data for valid inputs" {
  run klines spot BTCUSDT 1d 2021-01-01 2021-01-02
  assert_success
  assert_output --partial '"28923.63000000"'
  assert_output --partial '"29331.69000000"'
}

# Test: klines should fail if product argument is missing
@test "klines fails when product argument is missing" {
  run klines
  assert_failure
  assert_output --partial "missing required <product> argument"
}

# Test: klines should fail if symbol argument is missing
@test "klines fails when symbol argument is missing" {
  run klines spot
  assert_failure
  assert_output --partial "missing required <symbol> argument"
}

# Test: klines should fail if interval argument is missing
@test "klines fails when interval argument is missing" {
  run klines spot BTCUSDT
  assert_failure
  assert_output --partial "missing required <interval> argument"
}

# Test: klines should fail if start_time is invalid
@test "klines fails when start_time is invalid" {
  run klines spot BTCUSDT 1d "invalid-date" "2021-01-02"
  assert_failure
  assert_output --partial "must be valid date"
}

# Test: klines should fail if end_time is invalid
@test "klines fails when end_time is invalid" {
  run klines spot BTCUSDT 1d "2021-01-01" "invalid-date"
  assert_failure
  assert_output --partial "must be valid date"
}

# Test: klines handles API response with no data gracefully
@test "klines handles empty API response gracefully" {
  run klines spot BTCUSDT 1d 2021-01-01 2021-01-01
  assert_success
  assert_output "[]"
}

# Test: klines fails for invalid API response
@test "klines fails when API response is not valid" {
  run klines spot BTCUSDT 1d 2021-01-02 2021-01-03
  assert_failure
  assert_output --partial "Failed to get valid data from API"
}
