#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_PATHS=("lib/chef/target_io" "spec/unit/target_io")

cd "$ROOT_DIR"

bundle exec cookstyle --enable-pending-cops -A "${TARGET_PATHS[@]}"
