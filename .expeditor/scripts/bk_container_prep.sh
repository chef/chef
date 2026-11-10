#!/usr/bin/env bash

set -euo pipefail

# This script gets a container ready to run our various tests in BuildKite

if [ "${CHEF_USE_SYSTEM_RUBY:-false}" = "true" ]; then
  . /etc/os-release
  case "$ID:$VERSION_ID" in
    debian:12)
      export DEBIAN_FRONTEND=noninteractive
      apt-get update -y
      apt-get install -y --no-install-recommends libarchive13 cron locales sudo
      ;;
    *) echo "Unsupported system Ruby image: $ID $VERSION_ID" >&2; exit 1 ;;
  esac
else
  echo "--- Installing Chef Foundation"
  curl -fsSL https://omnitruck.chef.io/install.sh | bash -s -- -c "stable" -P "chef-foundation" -v "$CHEF_FOUNDATION_VERSION"
  export PATH="/opt/chef/bin:${PATH}"
fi

echo "--- Container Config..."
echo "ruby version:"
ruby -v
echo "bundler version:"
bundle -v

echo "--- Preparing Container..."

export FORCE_FFI_YAJL="ext"
export CHEF_LICENSE="accept-no-persist"
export BUNDLE_GEMFILE="/workdir/Gemfile"

# make sure we have the network tools in place for various network specs
if [ -f /etc/debian_version ]; then
  mkdir -p /etc/network
  touch /etc/network/interfaces
fi

# remove default bundler config if there is one
rm -f .bundle/config

echo "+++ Run tests"
