#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INPUT_FILE="$ROOT_DIR/ai-track-docs/architecture.mmd"
OUTPUT_FILE="$ROOT_DIR/ai-track-docs/architecture.svg"

if [[ ! -f "$INPUT_FILE" ]]; then
  echo "Diagram source not found: $INPUT_FILE" >&2
  exit 1
fi

if command -v docker >/dev/null 2>&1; then
  if docker run --rm \
      -u "$(id -u):$(id -g)" \
      -v "$ROOT_DIR":/data \
      minlag/mermaid-cli:11.12.0 \
      -i /data/ai-track-docs/architecture.mmd \
      -o /data/ai-track-docs/architecture.svg; then
    echo "Rendered diagram to $OUTPUT_FILE"
    exit 0
  fi
  echo "Docker render failed; trying npx fallback..." >&2
fi

if command -v npx >/dev/null 2>&1; then
  npx -y @mermaid-js/mermaid-cli@11.12.0 \
    -i "$INPUT_FILE" \
    -o "$OUTPUT_FILE"
  echo "Rendered diagram to $OUTPUT_FILE"
  exit 0
fi

echo "Neither docker nor npx is available; cannot validate Mermaid rendering." >&2
exit 1
