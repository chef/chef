#!/usr/bin/env bash

set -euo pipefail

export HAB_LICENSE="accept"
export HAB_NONINTERACTIVE="true"

HAB_VERSION="${HAB_VERSION:-2.0.504}"
hab_target="$1"

# print error message followed by usage and exit
error () {
  local message="$1"

  echo -e "\nERROR: ${message}\n" >&2

  exit 1
}

[[ -n "$hab_target" ]] || error 'no hab target provided'

install_habitat() {
  echo "--- :habicat: Installing Habitat $HAB_VERSION"
  curl https://raw.githubusercontent.com/habitat-sh/habitat/main/components/hab/install.sh | bash -s -- -t "$hab_target" -v "$HAB_VERSION"
  hab license accept
}

# Returns 0 if $1 >= $2 (minimum version met), 1 if $1 < $2
version_at_least() {
  [ "$(printf '%s\n' "$1" "$2" | sort -V | head -n 1)" = "$2" ]
}

if command -v hab &>/dev/null; then
  current_version=$(hab --version 2>/dev/null | awk '{print $2}' | cut -d'/' -f1 || true)
  if version_at_least "$current_version" "$HAB_VERSION"; then
    echo "--- :habicat: :thumbsup: Habitat $current_version is installed (>= $HAB_VERSION)"
  else
    echo "--- :habicat: Habitat $current_version detected (below minimum $HAB_VERSION). Installing..."
    install_habitat
  fi
else
  install_habitat
fi
