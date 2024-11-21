#!/usr/bin/env bash

readonly VERSION="${1:-main}"
readonly LIB_DIR="/usr/local/share/system4"
readonly LIB_PATH="${LIB_DIR}/binance.sh"
readonly BIN_PATH="/usr/local/bin/binance.sh"

install_lib() {
  local temp_file
  temp_file=$(mktemp) || {
    echo "Error: Unable to create a temporary file" >&2
    return 1
  }

  if ! wget -q "https://raw.githubusercontent.com/system4-tech/binance-sh/refs/heads/${VERSION}/lib/binance.sh" -O "${temp_file}"; then
    echo "Error: Download failed for version '${VERSION}'" >&2
    rm -f "${temp_file}"
    return 1
  fi

  sudo mv "${temp_file}" "${LIB_PATH}" || {
    echo "Error: Failed to move to '${LIB_PATH}'" >&2
    rm -f "${temp_file}"
    return 1
  }

  sudo ln -sf "${LIB_PATH}" "${BIN_PATH}" || {
    echo "Error: Symlink creation failed for '${BIN_PATH}'" >&2
    return 1
  }
}

main() {
  [[ -d "${LIB_DIR}" ]] || sudo mkdir -p "${LIB_DIR}" || {
    echo "Error: Unable to create '${LIB_DIR}'" >&2
    exit 1
  }

  install_lib || exit 1
}

main "$@"
