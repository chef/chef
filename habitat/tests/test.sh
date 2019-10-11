#!/bin/sh
#/ Usage: test.sh <pkg_ident>
#/
#/ Example: test.sh chef/scaffolding-chef-infra/1.2.0/20181108151533
#/
set -euo pipefail

if [[ -z "${1:-}" ]]; then
  grep '^#/' < "${0}" | cut -c4-
  exit 1
fi

TEST_PKG_IDENT="${1}"

( cd $(dirname $(hab pkg exec ${TEST_PKG_IDENT} gem which chef))/..
  hab pkg exec ${TEST_PKG_IDENT} rspec spec/functional
)
