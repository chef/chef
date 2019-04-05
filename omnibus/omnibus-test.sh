#!/bin/bash
set -ueo pipefail

channel="${CHANNEL:-unstable}"
product="${PRODUCT:-chef}"
version="${VERSION:-latest}"

echo "--- Installing $channel $product $version"
package_file="$(install-omnibus-product -c "$channel" -P "$product" -v "$version" | tail -n 1)"

echo "--- Verifying omnibus package is signed"
check-omnibus-package-signed "$package_file"

echo "--- Testing $channel $product $version"

export INSTALL_DIR=/opt/chef
export PATH="/opt/chef/bin:$PATH"

echo "Verifying ownership of package files"

NONROOT_FILES="$(find "$INSTALL_DIR" ! -uid 0 -print)"
if [[ "$NONROOT_FILES" == "" ]]; then
  echo "Packages files are owned by root.  Continuing verification."
else
  echo "Exiting with an error because the following files are not owned by root:"
  echo "$NONROOT_FILES"
  exit 1
fi

echo "Running verification for $product"

sh ci/verify-chef.sh
