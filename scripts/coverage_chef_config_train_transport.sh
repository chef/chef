#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHEF_CONFIG_DIR="$ROOT_DIR/chef-config"
TARGET_FILE="$CHEF_CONFIG_DIR/lib/chef-config/mixin/train_transport.rb"
COVERAGE_DIR="$CHEF_CONFIG_DIR/coverage-train-transport"
EXCLUDE_SPEC="${EXCLUDE_TRAIN_TRANSPORT_SPEC:-0}"

if [[ ! -f "$TARGET_FILE" ]]; then
  echo "Missing target file: $TARGET_FILE" >&2
  exit 1
fi

rm -rf "$COVERAGE_DIR"

cd "$CHEF_CONFIG_DIR"

TARGET_FILE="$TARGET_FILE" COVERAGE_DIR="$COVERAGE_DIR" EXCLUDE_SPEC="$EXCLUDE_SPEC" bundle exec ruby <<'RUBY'
require "simplecov"
require "rspec/core"

target_file = ENV.fetch("TARGET_FILE")
coverage_dir = ENV.fetch("COVERAGE_DIR")
exclude_spec = ENV.fetch("EXCLUDE_SPEC", "0") == "1"
spec_files = Dir["spec/unit/*_spec.rb"].sort
spec_files.reject! { |f| File.basename(f) == "train_transport_spec.rb" } if exclude_spec

SimpleCov.coverage_dir(coverage_dir)
SimpleCov.start do
  track_files target_file
  add_filter "/spec/"
end

exit_code = RSpec::Core::Runner.run(spec_files)
result = SimpleCov.result
file_result = result.files.find { |f| f.filename == target_file }

if file_result
  puts format("MODULE_COVERAGE=%.2f", file_result.covered_percent)
  puts "MODULE_COVERED_LINES=#{file_result.covered_lines.count}"
  puts "MODULE_MISSED_LINES=#{file_result.missed_lines.count}"
else
  puts "MODULE_COVERAGE=0.00"
  puts "MODULE_COVERED_LINES=0"
  puts "MODULE_MISSED_LINES=0"
end

result.format!
exit(exit_code)
RUBY
