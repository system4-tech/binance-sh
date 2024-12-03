#!/usr/bin/env bash



# Color constants
readonly COLOR_WHITE=37
readonly COLOR_BLUE=34
readonly COLOR_YELLOW=33
readonly COLOR_RED=31
readonly COLOR_GREEN=32

#######################################
# Logs a message with a specified color and level.
# Globals:
#   LOG_<LEVEL>_DISABLED
# Arguments:
#   color
#   message
# Outputs:
#   YYYY-MM-DD hh:mm:ss.SSS  <LEVEL> --- <message>
#######################################
_log() {
  local color instant level

  color=${1:?missing required <color> argument}
  shift

  # Determine log level from caller's function name
  level=${FUNCNAME[1]}
  level=${level#log.} # remove "log." prefix
  level=${level^^}    # convert to uppercase 

  # Check if logging for this level is disabled
  if [[ ! -v "LOG_${level}_DISABLED" ]]; then
    # Get timestamp with millisecond precision, fallback to basic if %-3N is unsupported
    instant=$(date '+%F %T.%-3N' 2>/dev/null || date '+%F %T' || :)

    # https://no-color.org/
    if [[ -v NO_COLOR ]]; then
      printf -- '%s  %s --- %s\n' "$instant" "$level" "$*" 1>&2 || :
    else
      printf -- '\033[0;%dm%s  %s --- %s\033[0m\n' "$color" "$instant" "$level" "$*" 1>&2 || :
    fi
  fi
}

log.debug() {
  _log "$COLOR_WHITE" "$@"
}

log.notice() {
  _log "$COLOR_BLUE" "$@"
}

log.warning() {
  _log "$COLOR_YELLOW" "$@" 
}

log.error() {
  _log "$COLOR_RED" "$@"
}

log.success() {
  _log "$COLOR_GREEN" "$@"
}

#######################################
# Makes HTTP request using curl.
# Arguments:
#   url - The URL for the request
#   method - HTTP method (GET, POST, etc.)
#   additional args - Additional arguments for curl
# Outputs:
#   Response from the server
#######################################
_http() {
  local url method

  url=${1:?missing required <url> argument}
  shift

  # Extract method from the calling function name (http.get -> GET)
  method=${FUNCNAME[1]}
  method=${method#http.} # remove "http." prefix
  method=${method^^}     # convert to uppercase 

  curl "$url" "$@" \
    --request "$method" \
    --fail-with-body \
    --silent \
    --location \
    --retry-connrefused \
    --max-time "${HTTP_MAX_TIME:-180}" \
    --retry "${HTTP_RETRY_NUM:-20}" \
    --retry-max-time "${HTTP_RETRY_MAX_TIME:-600}"
}

http.get() {
  _http "$@"
}

http.post() {
  local url data
  
  url=${1:?missing required <url> argument}
  data=${2:?missing required <data> argument}
  shift 2

  _http "$url" "$@" --data "$data" 
}

http.put() {
  local url data
  
  url=${1:?missing required <url> argument}
  data=${2:?missing required <data> argument}
  shift 2

  _http "$url" "$@" --data "$data" 
}

#######################################
# Downloads files request using curl.
# Arguments:
#   url - The URL for the request
#   additional args - Additional arguments for curl
# Outputs:
#   filename
#######################################
download() {
  local url path

  url=${1:?missing required <url> argument}
  path=${2:?missing required <path> argument}
  shift 2

  curl "$url" "$@" \
    --output "$path" \
    --fail \
    --silent \
    --show-error \
    --location \
    --retry "${HTTP_RETRY_NUM:-20}" \
    --retry-connrefused \
    --compressed \
    --parallel \
    --parallel-max "${HTTP_PARALLEL_MAX:-10}" \
    --write-out "%{filename_effective}\n"
}

#######################################
# Decodes a URL-encoded string.
# Globals:
#   None
# Arguments:
#   url (string): URL-encoded string to decode
# Outputs:
#   Writes the decoded string to stdout
# Returns:
#   0 on success
#######################################
urldecode() {
  local url=${1:-}
  local decoded="${url//+/ }"  # Replace + with a space
  printf '%b' "${decoded//%/\\x}"  # Decode percent-encoded characters
}

#######################################
# Encodes a string to be used in a URL.
# Globals:
#   None
# Arguments:
#   url (string): String to encode
# Outputs:
#   Writes the URL-encoded string to stdout
# Returns:
#   0 on success
#######################################
urlencode() {
  local url=${1:-}
  local encoded=""
  local char 
  
  for ((i = 0; i < ${#url}; i++)); do
    char="${url:i:1}"
    # Alphanumeric and some special characters don't need encoding
    if [[ "$char" =~ [A-Za-z0-9._~-] ]]; then
      encoded+="$char"
    else
      # Percent-encode any other character
      printf -v encoded '%s%%%02X' "$encoded" "'$char"
    fi
  done
  echo "$encoded"
}

#######################################
# Adds or updates a query parameter in a URL.
# If the key already exists, it updates the value, otherwise it adds the parameter.
# Globals:
#   None
# Arguments:
#   url (string): Base URL to modify
#   key (string): The query parameter key to add/update
#   value (string): The value to associate with the query parameter key
# Outputs:
#   Writes the modified URL with the added/updated query parameter to stdout
# Returns:
#   0 on success
#######################################
urlparam() {
  local url=${1:?missing required <url> argument}
  local key=${2:?missing required <key> argument}
  local value=${3:-}

  # URL encode the key and value
  key=$(urlencode "$key")
  value=$(urlencode "$value")

  if [[ "$url" =~ ([?&])$key= ]]; then
    url=$(echo "$url" | sed -E "s/([?&]$key=)[^&]*/\1$value/")
  elif [[ "$url" == *"?"* ]]; then
    url="$url&$key=$value"
  else
    url="$url?$key=$value"
  fi

  echo "$url"
}

#######################################
# Checks if the provided argument is a regular file.
# Globals:
#   None
# Arguments:
#   file (string): Path to the file
# Outputs:
#   Writes nothing to stdout
# Returns:
#   0 (true) if the file exists and is a regular file, 1 (false) otherwise.
#######################################
file_exists() {
  local file=${1:?missing required <file> argument}
  
  if [[ -f "$file" ]]; then
    return 0
  else
    return 1
  fi
}

#######################################
# Checks if the provided argument is a directory.
# Globals:
#   None
# Arguments:
#   dir (string): Path to the directory
# Outputs:
#   Writes nothing to stdout
# Returns:
#   0 (true) if the directory exists, 1 (false) otherwise.
#######################################
dir_exists() {
  local dir=${1:?missing required <dir> argument}
  
  if [[ -d "$dir" ]]; then
    return 0
  else
    return 1
  fi
}

#######################################
# Checks if the provided argument is a valid date.
# Globals:
#   None
# Arguments:
#   date (string): Date string
# Outputs:
#   Writes nothing to stdout
# Returns:
#   0 (true) if the date is valid, 1 (false) otherwise.
#######################################
is_date() {
  local date=${1:?missing required <date> argument}
  
  if date -d "$date" &>/dev/null; then
    return 0
  else
    return 1
  fi
}

#######################################
# Converts a date string to milliseconds since the Unix epoch.
# Assumes the provided date is valid; use is_date() to verify.
# Globals:
#   None
# Arguments:
#   date (string): Date string
# Outputs:
#   Writes milliseconds since Unix epoch to stdout
# Returns:
#   0 on success
#######################################
date_to_ms() {
  local date=${1:?missing required <date> argument}

  date -d "$date" +%s%3N
}

#######################################
# Gets today's date in YYYY-MM-DD format.
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   Writes today's date to stdout
# Returns:
#   0 on success
#######################################
today() {
  date +%F
}

#######################################
# Gets yesterday's date in YYYY-MM-DD format.
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   Writes yesterday's date to stdout
# Returns:
#   0 on success
#######################################
yesterday() {
  date -d "yesterday" +%F
}

#######################################
# Gets tomorrow's date in YYYY-MM-DD format.
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   Writes tomorrow's date to stdout
# Returns:
#   0 on success
#######################################
tomorrow() {
  date -d "tomorrow" +%F
}

#######################################
# Gets the current date and time in YYYY-MM-DD HH:MM:SS.sss format.
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   Writes the current date and time to stdout, including milliseconds if supported.
# Returns:
#   0 on success
#######################################
now() {
  date '+%Y-%m-%d %H:%M:%S.%3N'
}

#######################################
# Converts a JSON array into newline-delimited JSON (NDJSON).
# Globals:
#   None
# Arguments:
#   json (string): JSON array as a string
# Outputs:
#   Writes each item in the JSON array to stdout, one per line
# Returns:
#   0 on success
#######################################
json_to_ndjson() {
  local json=${1:-}

  if [ -z "$json" ] && [ -p /dev/stdin ]; then
    json=$(< /dev/stdin)    
  fi

  if [ -z "$json" ]; then
    echo "Error: Empty JSON string"
    return 1
  fi

  echo "$json" | jq -rc '.[]'
}

#######################################
# Converts a JSON array into TSV format with only values.
# Supports arrays, array of arrays, and array of objects.
# Globals:
#   None
# Arguments:
#   json (string): JSON array as a string
# Outputs:
#   Writes TSV-formatted values to stdout
# Returns:
#   0 on success, 1 on error
#######################################
json_to_tsv() {
  local json=${1:-}

  if [ -z "$json" ] && [ -p /dev/stdin ]; then
    json=$(< /dev/stdin)
  fi

  if [ -z "$json" ]; then
    echo "Error: Empty JSON string" >&2
    return 1
  fi

  # todo: support streaming
  echo "$json" | jq -r '
    .[] |
    if type == "array" then
      .
    elif type == "object" then
      [.[]]
    else
      [.] # Wrap single values into an array
    end | @tsv
  '
}

#######################################
# Checks if a string is valid JSON.
# Globals:
#   None
# Arguments:
#   json (string): Input string to validate
# Outputs:
#   None
# Returns:
#   0 if the input is valid JSON, 1 otherwise
#######################################
is_json() {
  local json="${1:-}"

  if echo "${json}" | jq -e . >/dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}

#######################################
# Checks if a string is a valid JSON array.
# Globals:
#   None
# Arguments:
#   json (string): Input string to validate as a JSON array
# Outputs:
#   None
# Returns:
#   0 if the input is a valid JSON array, 1 otherwise
#######################################
is_array() {
  local json="${1:-}"

  if echo "${json}" | jq -e 'if type == "array" then true else false end' >/dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}

#######################################
# Converts a JSON array into CSV format with only values.
# Supports arrays, array of arrays, and array of objects.
# Globals:
#   None
# Arguments:
#   json (string): JSON array as a string
# Outputs:
#   Writes CSV-formatted values to stdout
# Returns:
#   0 on success, 1 on error
#######################################
json_to_csv() {
  local json=${1:-}

  if [ -z "$json" ] && [ -p /dev/stdin ]; then
    json=$(< /dev/stdin)
  fi

  if [ -z "$json" ]; then
    echo "Error: Empty JSON string" >&2
    return 1
  fi

  # todo: support streaming
  echo "$json" | jq -r '
    .[] |
    if type == "array" then
      .
    elif type == "object" then
      [.[]]
    else
      [.] # Wrap single values into an array
    end | @csv
  '
}

#######################################
# Counts the length of a JSON array.
# Globals:
#   None
# Arguments:
#   json (string): JSON array as a string
#   path (string): Optional. JSON path to the array (default: ".")
# Outputs:
#   Writes the length of the JSON array to stdout
# Returns:
#   0 on success, 1 on error
#######################################
json_length() {
  local json=${1:-}
  local path=${2:-.}

  if [ -z "$json" ] && [ -p /dev/stdin ]; then
    json=$(< /dev/stdin)
  fi

  if [ -z "$json" ]; then
    echo "Error: Empty JSON string" >&2
    return 1
  fi

  echo "${json}" | jq -r "${path} | length" 
}

#######################################
# Checks if the provided argument is set (non-empty).
# Globals:
#   None
# Arguments:
#   string (string): The string to check.
# Outputs:
#   Writes nothing to stdout.
# Returns:
#   0 (true) if the string is set (non-empty), 1 (false) otherwise.
#######################################
is_set() {
  local str="${1:-}"

  if [[ -n "$str" ]]; then
    return 0
  else
    return 1
  fi
}

#######################################
# Checks if the provided argument is empty.
# Globals:
#   None
# Arguments:
#   string (string): The string to check.
# Outputs:
#   Writes nothing to stdout.
# Returns:
#   0 (true) if the string is empty, 1 (false) otherwise.
#######################################
is_empty() {
  local str="${1:-}"

  if [[ -z "$str" ]]; then
    return 0
  else
    return 1
  fi
}

#######################################
# Prints an error message to stderr and exits the script.
# Globals:
#   None
# Arguments:
#   message (string): The error message to display.
# Outputs:
#   Writes the error message to stderr.
# Returns:
#   Exits the script with a status code of 1.
#######################################
fail() {
  local message="$*"
  echo "$message" >&2
  exit 1
}


# shellcheck disable=SC2034
declare -Ag API_URLS

API_URLS=(
  [spot]=https://api.binance.com/api/v3
  [cm]=https://dapi.binance.com/dapi/v1  # COIN-M Futures
  [um]=https://fapi.binance.com/fapi/v1  # USD-M Futures
)

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
  local product base_url response
  
  product=${1:?missing required <product> argument}
  
  base_url=${API_URLS[$product]:?API URL is not set}

  response=$(http.get "${base_url}/exchangeInfo") || {
    fail "Error: $response"?
  }

  echo "$response" | jq -r '.symbols[].symbol'
}

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
