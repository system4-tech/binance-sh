#!/usr/bin/env bash

. ../lib/utils.sh # run `make deps` first

. api_urls.sh
. klines.sh
. ./symbols.sh # fix: find out why awk won't interpret 'symbols.sh'
