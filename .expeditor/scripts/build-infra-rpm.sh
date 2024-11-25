#!/bin/bash

if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Usage: $0 <version> <release>"
  exit 1
fi

arch=$(uname -m)
if [ "$arch" != "x86_64" ]; then
  echo "Architecture '$arch' is not supported. Only x86_64 is supported."
  exit 1
fi

# Read the version and release from the command-line arguments
VERSION="$1"
RELEASE="$2"

# Define the base directory for the RPM build environment
TEMP_DIR=$(mktemp -d)

export HAB_LICENSE="accept-no-persist"
sudo -E hab pkg export tar chef/chef-infra-client/$VERSION/$RELEASE


# Copy build source files to the BUILD directory or untar the tarball
TARBALL="chef-chef-infra-client-$VERSION-$RELEASE.tar.gz"

# Check if tarball exists
if [ ! -f "$TARBALL" ]; then
  echo "Tarball $TARBALL not found. Exiting."
  exit 1
fi


# Create the directory structure
BASE_DIR=$TEMP_DIR/rpmbuild
mkdir -p "$BASE_DIR"/{BUILD,RPMS/x86_64,SOURCES,SPECS,SRPMS}

echo "RPM build directory structure created under $BASE_DIR"

mkdir "$BASE_DIR/BUILD/hab"
mv $TARBALL "$BASE_DIR/BUILD/hab/"

.expeditor/scripts/hab-contents.sh "$BASE_DIR/BUILD/hab"

# Concatenate spec and contents into a single spec file
cat .expeditor/scripts/infra-hab.spec hab-contents.txt > "$BASE_DIR/SPECS/chef.spec"

# Replace all VERSION and RELEASE placeholders.
sed -i "s/%{VERSION}/$VERSION/ ; s/%{RELEASE}/$RELEASE/" "$BASE_DIR/SPECS/chef.spec"

# Run the rpmbuild command
rpmbuild -bb --target $arch --buildroot "$BASE_DIR/BUILD" --define "_topdir $BASE_DIR" "$BASE_DIR/SPECS/chef.spec"

RPM_PATH=$(find "$BASE_DIR/RPMS/$arch" -type f -name "chef-${VERSION}~${RELEASE}-*.${arch}.rpm" | head -n 1)

echo $RPM_PATH

# Check if the RPM was created
if [ -f "$RPM_PATH" ]; then
  echo "RPM created successfully: $RPM_PATH"
  cp "$RPM_PATH" .  # Copy the RPM to the current directory
  echo "RPM copied to current directory."
else
  echo "RPM creation failed or the RPM is not located in the expected directory."
fi

rm -rf "$TEMP_DIR"
