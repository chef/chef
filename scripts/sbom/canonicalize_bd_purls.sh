#!/usr/bin/env bash
# Replace each component's purl in a CycloneDX JSON file with the canonical
# PURL stored in the BlackDuck KB, so BD maps components to existing KB entries
# instead of creating unmatched or duplicate entries.
#
# Components not found in the BD KB are logged and kept with their original purl.
#
# Usage:
#   export BD_URL=https://your-instance.blackducksoftware.com
#   export BD_TOKEN=<api-token>
#   bash scripts/sbom/canonicalize_bd_purls.sh <sbom.json>          # in-place update
#   bash scripts/sbom/canonicalize_bd_purls.sh --dry-run <sbom.json> # print, no write
#
# Requires: curl, jq

set -euo pipefail

DRY_RUN=false
SBOM_FILE=""
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    *) SBOM_FILE="$arg" ;;
  esac
done

if [ -z "$SBOM_FILE" ]; then
  echo "Usage: $0 [--dry-run] <sbom.json>" >&2
  exit 1
fi
if [ ! -f "$SBOM_FILE" ]; then
  echo "ERROR: File not found: $SBOM_FILE" >&2
  exit 1
fi

BD_URL="${BD_URL:?Set BD_URL to your BlackDuck instance URL (no trailing slash)}"
BD_TOKEN="${BD_TOKEN:?Set BD_TOKEN to your BlackDuck API token}"

# ── Authenticate ─────────────────────────────────────────────────────────────
echo "Authenticating with BlackDuck..." >&2
BEARER=$(curl -sSf -X POST "${BD_URL}/api/tokens/authenticate" \
  -H "Authorization: token ${BD_TOKEN}" \
  -H "Accept: application/vnd.blackducksoftware.user-4+json" \
  | jq -r '.bearerToken')
if [ -z "$BEARER" ] || [ "$BEARER" = "null" ]; then
  echo "ERROR: Authentication failed." >&2; exit 1
fi
echo "Authenticated." >&2

# ── Look up the BD canonical PURL for a single component ─────────────────────
# Strips the "Habitat core_" prefix before querying BD — BD KB uses the raw
# package name (e.g. "glibc"), not the display name.
# Returns one of:
#   <purl>              — found in BD KB
#   NOT_FOUND_COMPONENT — component not in BD KB at all
#   NOT_FOUND_VERSION   — component found, but this version is absent
#   CURL_ERROR          — network/auth failure; caller exits
lookup_purl() {
  local display_name="$1" version="$2"
  # Strip display-name prefix to get the raw package name for BD search
  local name="${display_name#Habitat core_}"

  local bd_name_encoded bd_version_encoded
  bd_name_encoded=$(printf '%s' "$name" | jq -sRr @uri)
  bd_version_encoded=$(printf '%s' "$version" | jq -sRr @uri)

  local search
  if ! search=$(curl -sSf \
    "${BD_URL}/api/components?q=name:${bd_name_encoded}&limit=20" \
    -H "Authorization: Bearer ${BEARER}" \
    -H "Accept: application/vnd.blackducksoftware.internal-1+json"); then
    echo "CURL_ERROR"; return
  fi

  local comp_href
  comp_href=$(printf '%s' "$search" | jq -r \
    --arg n "$name" \
    '.items // [] | .[] | select(.name == $n) | ._meta.href' | head -1)
  if [ -z "$comp_href" ] || [ "$comp_href" = "null" ]; then
    echo "NOT_FOUND_COMPONENT"; return
  fi

  local ver_result
  if ! ver_result=$(curl -sSf \
    "${comp_href}/versions?q=versionName:${bd_version_encoded}&limit=10" \
    -H "Authorization: Bearer ${BEARER}" \
    -H "Accept: application/vnd.blackducksoftware.component-detail-5+json"); then
    echo "CURL_ERROR"; return
  fi

  local purl
  purl=$(printf '%s' "$ver_result" | jq -r \
    --arg v "$version" \
    '.items // [] | .[] | select(.versionName == $v) | .packageUrl // .externalId // ""' \
    | head -1)

  # Fall back to component-level packageUrl if version-level is empty
  if [ -z "$purl" ] || [ "$purl" = "null" ]; then
    purl=$(printf '%s' "$search" | jq -r \
      --arg n "$name" \
      '.items // [] | .[] | select(.name == $n) | .packageUrl // ""' | head -1)
  fi

  if [ -z "$purl" ] || [ "$purl" = "null" ]; then
    echo "NOT_FOUND_VERSION"; return
  fi

  echo "$purl"
}

# ── Process each component ────────────────────────────────────────────────────
TOTAL=$(jq '.components | length' "$SBOM_FILE")
echo "" >&2
echo "Canonicalizing PURLs for ${TOTAL} components in ${SBOM_FILE}..." >&2
echo "" >&2

UPDATED_COMPONENTS=$(jq -c '.components[]' "$SBOM_FILE" | while IFS= read -r component; do
  name=$(echo    "$component" | jq -r '.name')
  version=$(echo "$component" | jq -r '.version')
  orig_purl=$(echo "$component" | jq -r '.purl // ""')

  result=$(lookup_purl "$name" "$version")

  case "$result" in
    CURL_ERROR)
      printf "  %-40s %-15s  ✗  BD API error (aborting)\n" "$name" "$version" >&2
      exit 1
      ;;
    NOT_FOUND_COMPONENT)
      printf "  %-40s %-15s  ⚠  not in BD KB — keeping original purl\n" "$name" "$version" >&2
      echo "$component"
      ;;
    NOT_FOUND_VERSION)
      printf "  %-40s %-15s  ⚠  version absent in BD KB — keeping original purl\n" "$name" "$version" >&2
      echo "$component"
      ;;
    *)
      if [ "$result" = "$orig_purl" ]; then
        printf "  %-40s %-15s  ✓  unchanged\n" "$name" "$version" >&2
      else
        printf "  %-40s %-15s  ✓  %s\n" "$name" "$version" "$result" >&2
      fi
      echo "$component" | jq --arg purl "$result" '.purl = $purl'
      ;;
  esac

  sleep 0.2  # avoid hammering the BD API
done | jq -s '.')

UPDATED_DOC=$(jq --argjson components "$UPDATED_COMPONENTS" \
  '.components = $components' "$SBOM_FILE")

echo "" >&2
if $DRY_RUN; then
  echo "Dry run — not writing file." >&2
  echo "$UPDATED_DOC"
else
  echo "$UPDATED_DOC" > "$SBOM_FILE"
  echo "Written to $SBOM_FILE" >&2
fi
