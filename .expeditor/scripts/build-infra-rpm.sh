#!/usr/bin/env bash

set -euo pipefail

# Check if required environment variables pointing to tarball paths are set
if [ -z "$CHEF_INFRA_MIGRATE_TAR" ] || [ -z "$CHEF_INFRA_HAB_TAR" ]; then
  echo "Environment variables CHEF_INFRA_MIGRATE_TAR and CHEF_INFRA_HAB_TAR must be set to the paths of the respective tarball files."
  echo "Usage: Set the following environment variables before running the script:"
  echo "  export CHEF_INFRA_MIGRATE_TAR=<path_to_chef-migrate-tarball>"
  echo "  export CHEF_INFRA_HAB_TAR=<path_to_chef-infra-client-tarball>"
  echo "Example:"
  echo "  export CHEF_INFRA_MIGRATE_TAR=/path/to/migration-tools_Linux_x86_64.tar.gz"
  echo "  export CHEF_INFRA_HAB_TAR=/path/to/chef-chef-infra-client-19.0.54-20241121145703.tar.gz"
  exit 1
fi

# Ensure the provided files exist
if [ ! -f "$CHEF_INFRA_MIGRATE_TAR" ]; then
  echo "Error: The file specified in CHEF_INFRA_MIGRATE_TAR does not exist: $CHEF_INFRA_MIGRATE_TAR"
  exit 1
fi

if [ ! -f "$CHEF_INFRA_HAB_TAR" ]; then
  echo "Error: The file specified in CHEF_INFRA_HAB_TAR does not exist: $CHEF_INFRA_HAB_TAR"
  exit 1
fi

arch=$(uname -m)
if [ "$arch" != "x86_64" ]; then
  echo "Architecture '$arch' is not supported. Only x86_64 is supported."
  exit 1
fi

CHEF_INFRA_TAR="$CHEF_INFRA_HAB_TAR"
CHEF_MIGRATE_TAR="$CHEF_INFRA_MIGRATE_TAR"
SPEC_FILE="chef-infra-client.spec"

CHEF_INFRA_TAR_NAME=$(basename "$CHEF_INFRA_TAR")
CHEF_MIGRATE_TAR_NAME=$(basename "$CHEF_MIGRATE_TAR")
VERSION=$(echo "$CHEF_INFRA_TAR_NAME" | grep -oP '(?<=chef-chef-infra-client-)[0-9]+\.[0-9]+\.[0-9]+')
#VERSION=$(echo "$CHEF_INFRA_TAR_NAME" | grep -oP '(?<=chef-chef-infra-client-)[0-9]+\.[0-9]+\.[0-9]+-[0-9]+')

# Define the base directory for the RPM build environment
TEMP_DIR=$(mktemp -d)

# Create the directory structure
RPMBUILD_ROOT=$TEMP_DIR/rpmbuild
mkdir -p "$RPMBUILD_ROOT"/{BUILD,RPMS/x86_64,SOURCES,SPECS,SRPMS}

echo "RPM build directory structure created under $RPMBUILD_ROOT"

cp "$CHEF_INFRA_TAR" "$RPMBUILD_ROOT/SOURCES/"
cp "$CHEF_MIGRATE_TAR" "$RPMBUILD_ROOT/SOURCES/"
cp "$SPEC_FILE" "$RPMBUILD_ROOT/SPECS/"

# Replace the VERSION and file name place holders
sed -i "s/%{VERSION}/$VERSION/" "$RPMBUILD_ROOT/SPECS/$SPEC_FILE"
sed -i "s/%{CHEF_INFRA_TAR}/$CHEF_INFRA_TAR_NAME/" "$RPMBUILD_ROOT/SPECS/$SPEC_FILE"
sed -i "s/%{CHEF_MIGRATE_TAR}/$CHEF_MIGRATE_TAR_NAME/" "$RPMBUILD_ROOT/SPECS/$SPEC_FILE"

# Run the rpmbuild command
rpmbuild -bb --target $arch --buildroot "$RPMBUILD_ROOT/BUILD" --define "_topdir $RPMBUILD_ROOT" "$RPMBUILD_ROOT/SPECS/$SPEC_FILE"

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
fi

# Delete the temporary directory after build
rm -rf "$TEMP_DIR"
