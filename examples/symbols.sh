#!/usr/bin/env bash

set -eu

SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"

. "$SCRIPT_DIR/../lib/binance.sh"

main() {
  local product

  for product in "${API_URLS[@]}"; do
    symbols "$product"
  done
}

main
