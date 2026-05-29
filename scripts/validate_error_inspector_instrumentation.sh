#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"

inspector_files=(
  "lib/chef/formatters/error_inspectors/compile_error_inspector.rb"
  "lib/chef/formatters/error_inspectors/cookbook_resolve_error_inspector.rb"
  "lib/chef/formatters/error_inspectors/cookbook_sync_error_inspector.rb"
  "lib/chef/formatters/error_inspectors/node_load_error_inspector.rb"
  "lib/chef/formatters/error_inspectors/registration_error_inspector.rb"
  "lib/chef/formatters/error_inspectors/resource_failure_inspector.rb"
  "lib/chef/formatters/error_inspectors/run_list_expansion_error_inspector.rb"
)

for file in "${inspector_files[@]}"; do
  if ! grep -q "log_inspector_invocation" "$file"; then
    echo "FAIL: missing log_inspector_invocation in $file"
    exit 1
  fi
done

if ! grep -q 'event: "error_inspector.add_explanation"' lib/chef/formatters/error_inspectors/instrumentation.rb; then
  echo "FAIL: shared instrumentation event not found"
  exit 1
fi

echo "PASS: error inspector instrumentation is present across all inspector entry points"
