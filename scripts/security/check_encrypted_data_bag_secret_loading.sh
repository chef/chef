#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$repo_root"

target_file="lib/chef/encrypted_data_bag_item.rb"

echo "Checking encrypted data bag secret loading hardening in ${target_file}"

if grep -q "Kernel.open(path)" "$target_file"; then
  echo "FAIL: Kernel.open(path) is still present"
  exit 1
fi

if ! grep -q "URI.open(uri, open_timeout: 5, read_timeout: 5)" "$target_file"; then
  echo "FAIL: URI.open with explicit timeout options is missing"
  exit 1
fi

if ! grep -q "must use http or https" "$target_file"; then
  echo "FAIL: URL scheme validation guard is missing"
  exit 1
fi

if ! grep -q "must not include user credentials" "$target_file"; then
  echo "FAIL: URL userinfo validation guard is missing"
  exit 1
fi

echo "PASS: encrypted data bag secret loading security checks passed"
