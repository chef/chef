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
    TAR_NAME_NO_QUERY=$(echo "$TAR_NAME" | cut -d '?' -f 1)
    VERSION=$(echo "$TAR_NAME" | cut -d '-' -f 5 )
    TIMESTAMP=$(echo "$TAR_NAME" | cut -d '-' -f 6 | cut -d '.' -f 1)
    DEB_NAME=$(echo "$TAR_NAME_NO_QUERY" | awk -F'.tar.gz' '{print $1}').deb

    if [[ -z "$VERSION" || -z "$TIMESTAMP" ]]; then
        echo "Error: Failed to extract version or timestamp from tarball name: $TAR_NAME"
        exit 1
    fi
    TEMP_DIR="$HOME/temp_chef_chef_infra_client_${VERSION}_${TIMESTAMP}"
    CHEF_BIN_DIR="/opt/chef/bin"
    CHEF_BUNDLE_DIR="/opt/chef/bundle"
    DEB_PKG_NAME=chef
    ARCH=$(dpkg --print-architecture)

    echo "Variables initialized successfully."
}

create_temp_dir() {
    mkdir -p "$TEMP_DIR" || { echo "Error: Failed to create temporary directory"; exit 1; }
    echo "Temporary directory created at $TEMP_DIR."
}

download_files() {
    echo "Downloading migration tool..."
    curl -L -o "$TEMP_DIR/migration-tools.tar.gz" "$CHEF_INFRA_MIGRATE_TAR" || { echo "Error: Failed to download migration tool from $CHEF_INFRA_MIGRATE_TAR"; exit 1; }

    echo "Downloading Chef Infra tarball..."
    curl -L -o "$TEMP_DIR/$TAR_NAME_NO_QUERY" "$CHEF_INFRA_HAB_TAR" || { echo "Error: Failed to download Chef Infra tarball from $CHEF_INFRA_HAB_TAR"; exit 1; }

    echo "Files downloaded successfully."
}

prepare_package() {
    PACKAGE_DIR="$TEMP_DIR/infra-client_package"
    mkdir -p "$PACKAGE_DIR/DEBIAN" || { echo "Error: Failed to create DEBIAN directory"; exit 1; }
    mkdir -p "$PACKAGE_DIR$CHEF_BIN_DIR" || { echo "Error: Failed to create Chef bin directory"; exit 1; }
    mkdir -p "$PACKAGE_DIR$CHEF_BUNDLE_DIR" || { echo "Error: Failed to create Chef bundle directory"; exit 1; }

    echo "Unpacking migration tool..."
    tar -xf "$TEMP_DIR/migration-tools.tar.gz" -C "$PACKAGE_DIR$CHEF_BIN_DIR/" || { echo "Error: Failed to unpack migration tool"; exit 1; }

    echo "Copying Chef Infra tarball..."
    cp "$TEMP_DIR/$TAR_NAME_NO_QUERY" "$PACKAGE_DIR$CHEF_BUNDLE_DIR/" || { echo "Error: Failed to copy Chef Infra tarball"; exit 1; }

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
EOL
    if [ $? -ne 0 ]; then
        echo "Error: Failed to create control file"; exit 1
    fi
    echo "Control file prepared successfully."
}

prepare_preinstall_script() {
    cat <<EOL > "$PACKAGE_DIR/DEBIAN/preinst"
#!/bin/bash

FRESH_INSTALL_FLAG_FILE="/tmp/chef_fresh_install"

if [ -d "/opt/chef" ]; then
    rm -f "\$FRESH_INSTALL_FLAG_FILE"
else
    echo "fresh_install" > "\$FRESH_INSTALL_FLAG_FILE"
fi

if [[ "\$1" == "--help" ]]; then
    echo -e "\nChef Infra Client Installation Help"
    echo "Usage: sudo LICENSE_KEY=\"<license-key>\" dpkg -i <deb-file>"
    echo "Example:"
    echo "  sudo LICENSE_KEY=\"your-license-key\" dpkg -i chef-chef-infra-client-<version>-<timestamp>.deb"
    echo "Environment Variables:"
    echo "  LICENSE_KEY: The license key required for the Chef Infra Client installation."
    exit 0
fi

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
CHEF_BIN_DIR="/opt/chef/bin"
CHEF_BUNDLE_DIR="/opt/chef/bundle"
FRESH_INSTALL_FLAG_FILE="/tmp/chef_fresh_install"

FRESH_INSTALL_FLAG=""
LICENSE_SERVER=\${CHEF_INFRA_LICENSE_SERVER:-}
LICENSE_KEY=\${CHEF_INFRA_LICENSE_KEY:-}

if [ -f "\$FRESH_INSTALL_FLAG_FILE" ]; then
    FRESH_INSTALL_FLAG="--fresh_install"
    echo "Postinstall: Detected fresh installation."
    rm -f "\$FRESH_INSTALL_FLAG_FILE"
else
    echo "Postinstall: Detected upgrade installation."
fi

if [ -f "\$CHEF_BIN_DIR/chef-migrate" ]; then
    echo "Running post-install tasks..."
    MIGRATE_CMD="\$CHEF_BIN_DIR/chef-migrate apply airgap \$FRESH_INSTALL_FLAG \$CHEF_BUNDLE_DIR/$TAR_NAME_NO_QUERY"

    if [ -n "\$LICENSE_KEY" ]; then
        MIGRATE_CMD="\$MIGRATE_CMD --license.key \$LICENSE_KEY"
    fi

    if [ -n "\$LICENSE_SERVER" ]; then
        MIGRATE_CMD="\$MIGRATE_CMD --license.server \$LICENSE_SERVER"
    fi

    echo "Executing: \$MIGRATE_CMD"
    eval \$MIGRATE_CMD || { echo "Error: Post-installation failed."; exit 1; }
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

    if [ ! -f "$DEB_NAME" ]; then
        echo "Error: Package creation failed. $DEB_NAME not found."
        exit 1
    fi

    echo "Package built successfully: $DEB_NAME."
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