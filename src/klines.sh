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

  query+="&endTime=${end_time_ms}"

  while ((start_time_ms < end_time_ms)); do
    url="${base_url}/klines?${query}&startTime=${start_time_ms}"

    response=$(http.get "$url")
    
    if ! is_array "$response"; then
      fail "Error: $response"
    fi

    length=$(json_length "$response")
    if (( length == 0 )); then
      break
    fi

    klines=$(jq -s 'add' <<< "$klines $response")

    # get last close time
    if ! start_time_ms=$(jq -r '.[-1][6]' <<< "$response"); then
      break
    fi
  done

  jq -rc . <<< "$klines"
}
