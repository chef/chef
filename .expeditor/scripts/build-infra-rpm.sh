#!/usr/bin/env bash

set -euo pipefail

arch=$(uname -m)
if [ "$arch" != "x86_64" ]; then
  echo "Architecture '$arch' is not supported. Only x86_64 is supported."
  exit 1
fi

TEMP_DIR=$(mktemp -d)
TARS_DIR="$TEMP_DIR/tars"
mkdir -p "$TARS_DIR"
trap 'rm -rf "$TEMP_DIR"' EXIT

CHEF_INFRA_MIGRATE_TAR="${CHEF_INFRA_MIGRATE_TAR:-}"
CHEF_INFRA_HAB_TAR="${CHEF_INFRA_HAB_TAR:-}"

# Check if required environment variables pointing to tarball URLs are set
if [ -z "$CHEF_INFRA_MIGRATE_TAR" ] || [ -z "$CHEF_INFRA_HAB_TAR" ]; then
  echo "Environment variables CHEF_INFRA_MIGRATE_TAR and CHEF_INFRA_HAB_TAR must be set to the URLs of the respective tarball files."
  echo "Usage: Set the following environment variables before running the script:"
  echo "  export CHEF_INFRA_MIGRATE_TAR=<url_to_chef-migrate-tarball>"
  echo "  export CHEF_INFRA_HAB_TAR=<url_to_chef-infra-client-tarball>"
  echo "Example:"
  echo "  export CHEF_INFRA_MIGRATE_TAR=https://example.com/migration-tools_Linux_x86_64.tar.gz"
  echo "  export CHEF_INFRA_HAB_TAR=https://example.com/chef-chef-infra-client-19.0.54.tar.gz"
  exit 1
fi

# Function to download a file
download_file() {
  local url="$1"
  local output_path="$2"

  echo "Downloading $url to $output_path..."
  if ! curl -fsSL "$url" -o "$output_path"; then
    echo "Error: Failed to download $url"
    exit 1
  fi
}

migrate_filename=$(basename "${CHEF_INFRA_MIGRATE_TAR%%\?*}")
hab_filename=$(basename "${CHEF_INFRA_HAB_TAR%%\?*}")

download_file "$CHEF_INFRA_MIGRATE_TAR" "$TARS_DIR/$migrate_filename"
download_file "$CHEF_INFRA_HAB_TAR" "$TARS_DIR/$hab_filename"

# Set final paths to the downloaded files
CHEF_MIGRATE_TAR="$TARS_DIR/$migrate_filename"
CHEF_INFRA_TAR="$TARS_DIR/$hab_filename"

echo "Tarballs downloaded and variables set:"
echo "  CHEF_INFRA_TAR=$CHEF_INFRA_TAR"
echo "  CHEF_MIGRATE_TAR=$CHEF_MIGRATE_TAR"

SPEC_NAME="chef-infra-client.spec"
SPEC_FILE=".expeditor/scripts/$SPEC_NAME"

CHEF_INFRA_TAR_NAME=$(basename "$CHEF_INFRA_TAR")
CHEF_MIGRATE_TAR_NAME=$(basename "$CHEF_MIGRATE_TAR")
VERSION=$(echo "$CHEF_INFRA_TAR_NAME" | grep -oP '(?<=chef-chef-infra-client-)[0-9]+\.[0-9]+\.[0-9]+')
#VERSION=$(echo "$CHEF_INFRA_TAR_NAME" | grep -oP '(?<=chef-chef-infra-client-)[0-9]+\.[0-9]+\.[0-9]+-[0-9]+')

# Create the directory structure
RPMBUILD_ROOT=$TEMP_DIR/rpmbuild
mkdir -p "$RPMBUILD_ROOT"/{BUILD,RPMS/x86_64,SOURCES,SPECS,SRPMS}

echo "RPM build directory structure created under $RPMBUILD_ROOT"

cp "$CHEF_INFRA_TAR" "$RPMBUILD_ROOT/SOURCES/"
cp "$CHEF_MIGRATE_TAR" "$RPMBUILD_ROOT/SOURCES/"
cp "$SPEC_FILE" "$RPMBUILD_ROOT/SPECS/"

# Replace the VERSION and file name place holders
sed -i "s/%{VERSION}/$VERSION/" "$RPMBUILD_ROOT/SPECS/$SPEC_NAME"
sed -i "s/%{CHEF_INFRA_TAR}/$CHEF_INFRA_TAR_NAME/" "$RPMBUILD_ROOT/SPECS/$SPEC_NAME"
sed -i "s/%{CHEF_MIGRATE_TAR}/$CHEF_MIGRATE_TAR_NAME/" "$RPMBUILD_ROOT/SPECS/$SPEC_NAME"

# Run the rpmbuild command
rpmbuild -bb --target $arch --buildroot "$RPMBUILD_ROOT/BUILD" --define "_topdir $RPMBUILD_ROOT" "$RPMBUILD_ROOT/SPECS/$SPEC_NAME"

# RPM_PATH=$(find "$RPMBUILD_ROOT/RPMS/$arch" -type f -name "chef-infra-client-${version}~${release}-*.${arch}.rpm" | head -n 1)
find "$RPMBUILD_ROOT/RPMS/$arch" -type f
RPM_PATH=$(find "$RPMBUILD_ROOT/RPMS/$arch" -type f -name "chef-infra-client-${VERSION}-*.${arch}.rpm" | head -n 1)

# Check if the RPM was created
if [ -f "$RPM_PATH" ]; then
  echo "RPM created successfully: $RPM_PATH"
  cp "$RPM_PATH" .  # Copy the RPM to the current directory
  echo "RPM copied to current directory."
else
  echo "RPM creation failed or the RPM is not located in the expected directory."
  exit 1
fi
