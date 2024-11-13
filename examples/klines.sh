#!/usr/bin/env bash

set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

. "$SCRIPT_DIR/../lib/binance.sh"

main() {
  local symbols

  symbols=$(symbols spot)

  for symbol in $symbols; do
    klines spot $symbol 1d 2021-01-01 2021-01-02
  done
}

main
