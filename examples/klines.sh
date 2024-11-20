#!/usr/bin/env bash

set -eu

SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"

. "$SCRIPT_DIR/../lib/binance.sh"

main() {
  local symbols start_time symbol

  symbols=$(symbols spot)
  start_time=$(today)

  for symbol in $symbols; do
    TZ=UTC klines spot "$symbol" 1d "$start_time"
  done
}

main
