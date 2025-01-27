#!/bin/bash

set -euo pipefail

validate_env_vars() {
    if [ -z "${CHEF_INFRA_MIGRATE_TAR:-}" ] || [ -z "${CHEF_INFRA_HAB_TAR:-}" ]; then
        echo "Environment variables CHEF_INFRA_MIGRATE_TAR and CHEF_INFRA_HAB_TAR must be set to the URLs of the respective tarball files."
        echo "Usage: Set the following environment variables before running the script:"
        echo "  export CHEF_INFRA_MIGRATE_TAR=<url_to_chef-migrate-tarball>"
        echo "  export CHEF_INFRA_HAB_TAR=<url_to_chef-infra-client-tarball>"
        echo "Example:"
        echo   export CHEF_INFRA_MIGRATE_TAR=\"https://example.com/migration-tools_Linux_x86_64.tar.gz\"
        echo   export CHEF_INFRA_HAB_TAR=\"https://example.com/chef-chef-infra-client-19.0.54-20241121145703.tar.gz\"
        exit 1
    fi
    echo "Environment variables validated successfully."
}

initialize_vars() {
    TAR_NAME=$(basename "$CHEF_INFRA_HAB_TAR")
    VERSION=$(echo "$TAR_NAME" | cut -d '-' -f 5 )
    RELEASE="1"
    ARCH=$(dpkg --print-architecture)
    DEB_NAME="chef-infra-client-${VERSION}-${RELEASE}_${ARCH}.deb"

    if [[ -z "$VERSION" ]]; then
        echo "Error: Failed to extract version from tarball name: $TAR_NAME"
        exit 1
    fi
    TEMP_DIR="$HOME/temp_chef-infra-client_${VERSION}-${RELEASE}_${ARCH}"
    CHEF_BIN_DIR="/hab/migration/bin"
    CHEF_BUNDLE_DIR="/hab/migration/bundle"
    DEB_PKG_NAME=chef-infra-client

    echo "Variables initialized successfully."
}

create_temp_dir() {
    mkdir -p "$TEMP_DIR" || { echo "Error: Failed to create temporary directory"; exit 1; }
    echo "Temporary directory created at $TEMP_DIR."
}

download_files() {
    echo "Downloading migration tool..."
    aws s3 cp "$CHEF_INFRA_MIGRATE_TAR" "$TEMP_DIR/migration-tools.tar.gz" || { echo "Error: Failed to download migration tool from $CHEF_INFRA_MIGRATE_TAR"; exit 1; }

    echo "Downloading Chef Infra tarball..."
    aws s3 cp "$CHEF_INFRA_HAB_TAR" "$TEMP_DIR/$TAR_NAME" || { echo "Error: Failed to download Chef Infra tarball from $CHEF_INFRA_HAB_TAR"; exit 1; }

    echo "Files downloaded successfully."
}

prepare_package() {
    PACKAGE_DIR="$TEMP_DIR/infra-client-package"
    mkdir -p "$PACKAGE_DIR/DEBIAN" || { echo "Error: Failed to create DEBIAN directory"; exit 1; }
    mkdir -p "$PACKAGE_DIR$CHEF_BIN_DIR" || { echo "Error: Failed to create Chef bin directory"; exit 1; }
    mkdir -p "$PACKAGE_DIR$CHEF_BUNDLE_DIR" || { echo "Error: Failed to create Chef bundle directory"; exit 1; }

    echo "Unpacking migration tool..."
    tar -xf "$TEMP_DIR/migration-tools.tar.gz" -C "$PACKAGE_DIR$CHEF_BIN_DIR/" || { echo "Error: Failed to unpack migration tool"; exit 1; }

    echo "Copying Chef Infra tarball..."
    cp "$TEMP_DIR/$TAR_NAME" "$PACKAGE_DIR$CHEF_BUNDLE_DIR/" || { echo "Error: Failed to copy Chef Infra tarball"; exit 1; }

    prepare_control_file
    prepare_preinstall_script
    prepare_postinstall_script
    echo "Package structure prepared successfully."
}

prepare_control_file() {
    cat <<EOL > "$PACKAGE_DIR/DEBIAN/control"
Package: $DEB_PKG_NAME
Version: $VERSION
Architecture: $ARCH
Maintainer: The Chef Maintainers <maintainers@chef.io>
Description: Chef Infra Client
 Chef Infra Client is an agent for configuration management.
Conflicts: chef-workstation
URL: 		    https://www.chef.io
Packager: 	    Chef Software, Inc. <maintainers@chef.io>
Group: 		    default
License:        Chef EULA

EOL
    if [ $? -ne 0 ]; then
        echo "Error: Failed to create control file"; exit 1
    fi
    echo "Control file prepared successfully."
}

prepare_preinstall_script() {
    cat <<EOL > "$PACKAGE_DIR/DEBIAN/preinst"
#!/bin/bash

BACKUP_DIR="/opt/chef_backup"
echo "LICENSE_KEY=\$LICENSE_KEY" > /tmp/chef_env
echo "LICENSE_SERVER=\$LICENSE_SERVER" >> /tmp/chef_env
chmod 600 /tmp/chef_env

if [ -z "\${LICENSE_KEY:-}" ]; then
    LICENSE_KEY=$(env | grep -m 1 '^LICENSE_KEY=' | cut -d '=' -f 2 | xargs)
    
    if [ -z "\$LICENSE_KEY" ]; then
        echo -e "\nError: LICENSE_KEY environment variable is required."
        echo "Usage: sudo LICENSE_KEY=\"<license-key>\" dpkg -i <deb-file>"
        exit 1
    fi
fi

EOL
    chmod +x "$PACKAGE_DIR/DEBIAN/preinst" || { echo "Error: Failed to make preinst script executable"; exit 1; }
    echo "Pre-install script prepared successfully."
}

prepare_postinstall_script() {
    cat <<EOL > "$PACKAGE_DIR/DEBIAN/postinst"
#!/bin/bash

CHEF_BIN_DIR="/hab/migration/bin"
CHEF_BUNDLE_DIR="/hab/migration/bundle"
BACKUP_DIR="/opt/chef_backup"
FRESH_INSTALL_FLAG=""
LICENSE_KEY_FLAG=""
LICENSE_SERVER_FLAG=""

LICENSE_SERVER=\${CHEF_INFRA_LICENSE_SERVER:-}
LICENSE_KEY=\${CHEF_INFRA_LICENSE_KEY:-}

if [ -f /tmp/chef_env ]; then
    source /tmp/chef_env
    rm -f /tmp/chef_env
fi

if [ ! -d "/opt/chef/" ]; then
    FRESH_INSTALL_FLAG="--fresh_install"
    echo "Postinstall: Detected fresh installation."
else
    echo "Postinstall: Detected upgrade installation."
fi

if [ -f "\$CHEF_BIN_DIR/chef-migrate" ]; then
    echo "Running post-install tasks..."

     if [ -n "\$LICENSE_KEY" ]; then
        LICENSE_KEY_FLAG="--license.key \$LICENSE_KEY"
    fi

    if [ -n "\$LICENSE_SERVER" ]; then
        LICENSE_SERVER_FLAG="--license.server \$LICENSE_SERVER"
    fi

    MIGRATE_CMD="\$CHEF_BIN_DIR/chef-migrate apply airgap \$FRESH_INSTALL_FLAG \$CHEF_BUNDLE_DIR/$TAR_NAME \$LICENSE_KEY_FLAG \$LICENSE_SERVER_FLAG"

    echo "Executing: \$MIGRATE_CMD"
    eval \$MIGRATE_CMD || { echo "Error: Post-installation failed."; exit 1; }

    cp /hab/chef/bin/* \$CHEF_BIN_DIR || { echo "Error: Failed to copy binaries to \$CHEF_BIN_DIR"; exit 1; }
else
    echo "Error: chef-migrate tool not found in \$CHEF_BIN_DIR"
    exit 1
fi
EOL
    chmod +x "$PACKAGE_DIR/DEBIAN/postinst" || { echo "Error: Failed to make postinst script executable"; exit 1; }
    echo "Post-install script prepared successfully."
}

build_package() {
    dpkg-deb --build "$PACKAGE_DIR" "$DEB_NAME" || { echo "Error: Failed to build .deb package"; exit 1; }

    echo "Package built successfully: $DEB_NAME."
    echo "$DEB_NAME" > "DEB_PKG_NAME"
}

cleanup() {
    rm -rf "$TEMP_DIR" || { echo "Error: Failed to clean up temporary directory"; exit 1; }
    echo "Temporary directory cleaned up."
}

trap cleanup EXIT

validate_env_vars
initialize_vars
create_temp_dir
download_files
prepare_package
build_package