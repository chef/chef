#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-quick}"

if [[ "$MODE" != "quick" && "$MODE" != "full" ]]; then
  echo "Usage: bash scripts/run_local_ci_tests.sh [quick|full]"
  exit 2
fi

# Run from repository root to keep paths and bundle context stable.
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

export CHEF_LICENSE="accept-no-persist"
export FORCE_FFI_YAJL="ext"

echo "[local-ci] mode=$MODE"
echo "[local-ci] repo=$REPO_ROOT"

# Mirror CI fixture setup expected by unit specs.
mkdir -p spec/data/nodes
touch spec/data/nodes/test.rb spec/data/nodes/default.rb spec/data/nodes/test.example.com.rb

echo "[local-ci] bundle install"
bundle install --jobs=3 --retry=3

echo "[local-ci] spellcheck module tests"
bundle exec rspec spec/unit/tasks/spellcheck_task_spec.rb

if [[ "$MODE" == "full" ]]; then
  echo "[local-ci] full unit suite"
  bundle exec rake spec:unit

  echo "[local-ci] component specs"
  bundle exec rake component_specs
fi

echo "[local-ci] success"