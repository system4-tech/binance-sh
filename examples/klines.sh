#!/usr/bin/env bash

set -eu

SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"

. "$SCRIPT_DIR/../lib/binance.sh"

main() {
  local symbols start_time
  local klines open high low close
  local -a kline

  symbols=$(symbols spot)
  start_time=$(today)

  for symbol in $symbols; do
    klines=$(klines spot $symbol 1d $start_time | jq -c .[])

    for kline in $klines; do
      readarray -t kline < <(jq -r .[] <<< $kline)

      open_time=${kline[0]}
      open=${kline[1]}
      high=${kline[2]}
      low=${kline[3]}
      close=${kline[4]}
      close_time=${kline[6]}

      if is_set $open; then
        echo "Symbol: $symbol, Open: $open, High: $high"
      fi

    done

  done
}

main
