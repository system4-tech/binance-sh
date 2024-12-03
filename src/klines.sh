#!/usr/bin/env bash

#######################################
# Retrieves kline (candlestick) data for a specific symbol and interval.
# Globals:
#   API_URLS (associative array of API URLs per product)
# Arguments:
#   product (string): Product key used to select base URL.
#   symbol (string): Trading symbol (e.g., BTCUSDT).
#   interval (string): Kline interval (e.g., 1m, 1h, 1d).
#   start_time (string, optional): Start date in format 'YYYY-MM-DD'.
#   end_time (string, optional): End date in format 'YYYY-MM-DD'.
# Outputs:
#   JSON array of kline data.
# Returns:
#   0 on success, non-zero on error.
#######################################
klines() {
  local product=${1:?missing required <product> argument}
  local symbol=${2:?missing required <symbol> argument}
  local interval=${3:?missing required <interval> argument}
  local start_time=${4:?missing required <start_time> argument}
  local end_time=${5:?missing required <end_time> argument}
  local base_url=${API_URLS[$product]:?API URL is not set}
  local query="symbol=${symbol}&interval=${interval}&limit=1000"
  local start_time_ms end_time_ms url response klines="[]"

  if ! is_date "$start_time" || ! is_date "$end_time"; then
    fail "<start_time> and <end_time> must be valid date"
  fi

  start_time_ms=$(date_to_ms "$start_time")
  end_time_ms=$(date_to_ms "$end_time")

  query+="&startTime=${start_time_ms}&endTime=${end_time_ms}"
  url="${base_url}/klines?${query}"

  while ((start_time_ms < end_time_ms)); do
    if ! response=$(http.get "$url") || ! is_array "$response"; then
      fail "Failed to get valid data from API: $response"
    fi

    length=$(json_length "$response")
    if (( length == 0 )); then
      break
    fi

    klines=$(echo "$klines" "$response" | jq -s 'add')
    # todo: add max_iterations and check start_time to avoid infinite loop
    start_time_ms=$(echo "$response" | jq -r '.[-1][6]') # get last close time
    url=$(urlparam "$url" startTime "$start_time_ms")
  done

  echo "$klines" | jq -rc .
}
