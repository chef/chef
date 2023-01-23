#!/bin/bash

# exit immediately on failure, or if an undefined variable is used
set -eu

echo "---"
echo "steps:"
echo ""

# include build and test omnibus pipeline
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
source "$DIR/build-test-omnibus.sh"