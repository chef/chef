#! /bin/bash
set -eu -o pipefail

if [[ "${BUILDKITE_LABEL:-}" =~ "el-.*-x86_64" || \
      "${BUILDKITE_LABEL:-}" =~ "el-.*-ppc64" || \
      "${BUILDKITE_LABEL:-}" =~ "el-.*aarch" || \
      "${BUILDKITE_LABEL:-}" =~ "ubuntu-" || \
      "${BUILDKITE_LABEL:-}" =~ "amazon-2023" ]]
then
  echo "%% Installing with OPENSSL_FIPS=1 %%"
  export OPENSSL_FIPS=1
fi

echo "--- Installing package from BuildKite"

if [[ $OSTYPE == "msys" ]]; then
  buildkite-agent artifact download "pkg\*.msi" . --step "$OMNIBUS_BUILDER_KEY"
  package_file=$(find pkg/*)
else
  extensions=( deb rpm amd64.sh )
  for ext in "${extensions[@]}"
  do
    buildkite-agent artifact download "pkg/*.${ext}" . --step "$OMNIBUS_BUILDER_KEY" || true
  done
  package_file=$(find pkg/*)
fi

if [[ -z $package_file ]]; then
  buildkite-agent annotate "Failed to download packages from the $OMNIBUS_BUILDER_KEY builder." --style "warning" --context "ctx-warn" || true
  exit 1
fi

# if [[ -v $OMNIBUS_RPM_SIGNING_PASSPHRASE ]]; then
#   case "$package_file" in
#     *.rpm)
#       echo "--- Checking that $package_file has been signed."
#       if [[ $(rpm -qpi "$package_file" 2>&1 | grep -c "Signature.*Key ID") -eq 1 ]]; then
#         echo "Verified $package_file has been signed."
#       else
#         echo "Exiting with an error because $package_file has not been signed. Check your omnibus project config."
#         exit 1
#       fi
#       ;;
#   esac
# fi

echo "--- Setting CHEF_LICENSE_SERVER environment variable"
# Get the directory of the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Use SCRIPT_DIR to refer to files relative to the script’s location
export CHEF_LICENSE_SERVER=$(cat "$SCRIPT_DIR/chef_license_server_url.txt")
echo "--- Script dir is $SCRIPT_DIR"
echo "--- License serverl url is $CHEF_LICENSE_SERVER"

echo "--- Installing ${package_file}"
FILE_TYPE="${package_file##*.}"
case "$FILE_TYPE" in
  "rpm")
    if [[ "${IGNORE_INSTALL_DEPENDENCIES:-false}" == true ]]; then
      IGNORE_DEPENDS_OPTION="--nodeps"
    fi
    sudo rpm -Uvh ${IGNORE_DEPENDS_OPTION:-} --oldpackage --replacepkgs "$package_file"
    ;;
  "deb")
    if [[ "${IGNORE_INSTALL_DEPENDENCIES:-false}" == true ]]; then
      IGNORE_DEPENDS_OPTION="--force-depends"
    fi
    sudo dpkg ${IGNORE_DEPENDS_OPTION:-} -i "$package_file"
    ;;
  "sh" )
    sudo sh "$package_file"
    ;;
  *)
    echo "Unknown filetype: $FILE_TYPE"
    exit 1
    ;;
esac