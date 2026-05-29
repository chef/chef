#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SUBSYSTEM_DIR="$ROOT_DIR/chef-config"
DIAGRAM_FILE="$ROOT_DIR/ai-track-docs/chef-config-architecture.mmd"
SUMMARY_FILE="$ROOT_DIR/ai-track-docs/chef-config-architecture-change-summary.md"
MAX_LIB_FILES=18

if [[ ! -d "$SUBSYSTEM_DIR" ]]; then
  echo "Missing subsystem directory: $SUBSYSTEM_DIR" >&2
  exit 1
fi

tmp_before="$(mktemp)"
tmp_after="$(mktemp)"
tmp_diff="$(mktemp)"

cleanup() {
  rm -f "$tmp_before" "$tmp_after" "$tmp_diff"
}
trap cleanup EXIT

if [[ -f "$DIAGRAM_FILE" ]]; then
  cp "$DIAGRAM_FILE" "$tmp_before"
  before_state="existing"
else
  : > "$tmp_before"
  before_state="missing"
fi

{
  echo "flowchart TD"
  echo "    S[\"chef-config subsystem\"]"
  echo "    L[\"chef-config/lib\"]"
  echo "    SP[\"chef-config/spec\"]"
  echo "    GS[\"chef-config/chef-config.gemspec\"]"
  echo "    G[\"chef-config/Gemfile\"]"
  echo ""
  echo "    S --> L"
  echo "    S --> SP"
  echo "    S --> GS"
  echo "    S --> G"

  lib_files=()
  if [[ -d "$SUBSYSTEM_DIR/lib" ]]; then
    while IFS= read -r rel_path; do
      [[ -z "$rel_path" ]] && continue
      lib_files+=("$rel_path")
    done < <(find "$SUBSYSTEM_DIR/lib" -type f -name "*.rb" | sed "s|$ROOT_DIR/||" | LC_ALL=C sort)
  fi

  displayed_count=0
  total_count=${#lib_files[@]}

  for rel_path in "${lib_files[@]}"; do
    displayed_count=$((displayed_count + 1))
    if (( displayed_count > MAX_LIB_FILES )); then
      break
    fi

    node_id="L${displayed_count}"
    echo "    ${node_id}[\"${rel_path}\"]"
    echo "    L --> ${node_id}"
  done

  if (( total_count > MAX_LIB_FILES )); then
    omitted_count=$((total_count - MAX_LIB_FILES))
    echo "    LMORE[\"... ${omitted_count} more Ruby files under chef-config/lib\"]"
    echo "    L --> LMORE"
  fi
} > "$tmp_after"

install -m 0644 "$tmp_after" "$DIAGRAM_FILE"

before_hash="missing"
if [[ "$before_state" == "existing" ]]; then
  before_hash="$(shasum -a 256 "$tmp_before" | awk '{print $1}')"
fi
after_hash="$(shasum -a 256 "$DIAGRAM_FILE" | awk '{print $1}')"

if diff -u "$tmp_before" "$DIAGRAM_FILE" > "$tmp_diff"; then
  diagram_changed="no"
else
  diagram_changed="yes"
fi

before_node_count="0"
if [[ "$before_state" == "existing" ]]; then
  before_node_count="$(grep -Ec '^    [A-Z0-9]+\["' "$tmp_before" || true)"
fi
after_node_count="$(grep -Ec '^    [A-Z0-9]+\["' "$DIAGRAM_FILE" || true)"

{
  echo "# chef-config Architecture Change Summary"
  echo ""
  echo "## Scope"
  echo "- Subsystem: chef-config"
  echo "- Source scanned: chef-config/lib/**/*.rb"
  echo "- Excluded: vendor/, pkg/, submodules"
  echo ""
  echo "## Before/After Evidence"
  echo "- Diagram before: ${before_state}"
  echo "- Diagram changed: ${diagram_changed}"
  echo "- Before SHA-256: ${before_hash}"
  echo "- After SHA-256: ${after_hash}"
  echo "- Node count before: ${before_node_count}"
  echo "- Node count after: ${after_node_count}"
  echo ""
  echo "## What Shifted"
  if [[ "$diagram_changed" == "yes" ]]; then
    echo "- Updated the generated chef-config architecture flowchart from current filesystem state."
    echo "- Added/removed nodes and edges based on detected Ruby files under chef-config/lib."
    echo ""
    echo "### Diff Excerpt"
    echo '```diff'
    head -n 120 "$tmp_diff"
    echo '```'
  else
    echo "- No topology changes were detected in the scoped subsystem."
  fi
  echo ""
  echo "## Rollback Guidance"
  echo "- Revert only generated artifacts if needed:"
  echo "  - git checkout -- ai-track-docs/chef-config-architecture.mmd ai-track-docs/chef-config-architecture-change-summary.md"
  echo "- Keep scripts/update_chef_config_architecture.sh to preserve the repeatable refresh process."
} > "$SUMMARY_FILE"

echo "Updated: $DIAGRAM_FILE"
echo "Updated: $SUMMARY_FILE"
