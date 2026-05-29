#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_PATHS=("lib/chef/target_io" "spec/unit/target_io")
OUT_FILE="${1:-/tmp/target_io_cookstyle_strict.json}"

cd "$ROOT_DIR"

set +e
bundle exec cookstyle --enable-pending-cops "${TARGET_PATHS[@]}" --format json --out "$OUT_FILE"
status=$?
set -e

ruby -rjson -e 'j=JSON.parse(File.read(ARGV[0])); puts "offense_count=#{j.dig("summary","offense_count")}"; puts "target_file_count=#{j.dig("summary","target_file_count")}"; puts "inspected_file_count=#{j.dig("summary","inspected_file_count")}"' "$OUT_FILE"

exit "$status"
