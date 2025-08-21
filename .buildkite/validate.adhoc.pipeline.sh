#!/bin/bash
set -euo pipefail

workdir="$(pwd)"
echo "Initial workdir: $workdir"

echo "--- Installing Ruby.."
curl -sSL https://cache.ruby-lang.org/pub/ruby/3.4/ruby-3.4.2.tar.xz | tar -xJ -C /tmp

cd /tmp/ruby-3.4.2
./configure --prefix=/tmp/ruby-3.4.2-install
make -j"$(nproc)"
make install

echo "Installed Ruby version:"
/tmp/ruby-3.4.2-install/bin/ruby -v

cd "$workdir"
echo "Back to workdir: $(pwd)"
ls -la

if [[ ! -f "$workdir/.buildkite/validate-adhoc.rb" ]]; then
  echo "ERROR: .buildkite/validate-adhoc.rb not found in $workdir"
  exit 1
fi

echo "--- Generating pipeline configuration.."
/tmp/ruby-3.4.2-install/bin/ruby "$workdir/.buildkite/validate-adhoc.rb"
/tmp/ruby-3.4.2-install/bin/ruby "$workdir/.buildkite/validate-adhoc.rb" | buildkite-agent pipeline upload
