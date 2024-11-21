#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"

. "$SCRIPT_DIR/../lib/binance.sh"

main() {
  local symbols start_time symbol

  symbols=$(symbols spot)
  start_time=$(today)

  for symbol in $symbols; do
    # shellcheck disable=SC2034,SC2119
    klines spot "$symbol" 1d "$start_time" | json_to_tsv | \
      while IFS=$'\t' read -r open_time open high low close volume close_time quote_asset_volume; do

        if is_set "$open"; then
          echo "Symbol: $symbol, Open: $open, High: $high, Low: $low, Close: $close, Volume: $quote_asset_volume"
        fi

      done
  done
}

main
