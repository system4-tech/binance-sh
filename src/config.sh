#!/usr/bin/env bash

# shellcheck disable=SC2034
declare -Ag API_URLS

API_URLS=(
  [spot]=https://api.binance.com/api/v3
  [cm]=https://dapi.binance.com/dapi/v1  # COIN-M Futures
  [um]=https://fapi.binance.com/fapi/v1  # USD-M Futures
)
