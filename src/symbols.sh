#!/usr/bin/env bash

#######################################
# Retrieves available symbols for a given product.
# Globals:
#   API_URLS (associative array of API URLs per product)
# Arguments:
#   product (string): Product key used to select base URL.
# Outputs:
#   A list of symbols in plain text, one per line.
# Returns:
#   0 on success, non-zero on error.
#######################################
symbols() {
  local product base_url
  
  product=${1:?missing required <product> argument}
  
  base_url=${API_URLS[$product]:?API URL is not set}

  # todo: check response before passing to jq
  http.get "${base_url}/exchangeInfo" | jq -r '.symbols[].symbol'
}
