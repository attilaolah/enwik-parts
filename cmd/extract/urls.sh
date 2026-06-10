#!/usr/bin/env bash

# Extract bracketed URLs from the input dataset.
# Usage: ./expected.sh [dataset_path]

dataset_path="${1:-$DATASET}"

# shellcheck disable=SC2016 # $1 is a capture group
rg_cmd=(rg -oPU '\[((?:https?|ftp):[^\]\s]*)(?:[ \t\r\n][^\]]*)?\]' -r '$1')

"${rg_cmd[@]}" "$dataset_path"
