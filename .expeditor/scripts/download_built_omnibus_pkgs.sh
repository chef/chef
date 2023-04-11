#! /bin/bash
set -eu -o pipefail

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
