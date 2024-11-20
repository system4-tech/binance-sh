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
  local product symbol interval start_time end_time
  local base_url query_string
  local start_time_ms end_time_ms

  product=${1:?missing required <product> argument}
  symbol=${2:?missing required <symbol> argument}
  interval=${3:?missing required <interval> argument}
  start_time=${4:-}
  end_time=${5:-}

  base_url=${API_URLS[$product]:?API URL is not set}
  query_string="symbol=${symbol}&interval=${interval}&limit=1000"

  if is_set "$start_time"; then
    if ! is_date "$start_time"; then
      fail "<start_time> must be valid date"
    fi

    start_time_ms=$(date_to_ms "$start_time")
    query_string+="&startTime=${start_time_ms}"
  fi

  if is_set "$end_time"; then
    if ! is_date "$end_time"; then
      fail "<end_time> must be valid date"
    fi
    
    end_time_ms=$(date_to_ms "$end_time")
    query_string+="&endTime=${end_time_ms}"
  fi

  # todo: check response before passing to jq
  http.get "${base_url}/klines?${query_string}" | jq -r .
}
