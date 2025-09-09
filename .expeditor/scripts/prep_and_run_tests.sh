#!/usr/bin/env bash

set -euo pipefail

if [ -z "$1" ]
  then
    echo "No TestType supplied"
fi

TestType=$1

if [ "$TestType" == "Unit" ]
then
    mkdir spec/data/nodes && touch spec/data/nodes/test.rb && touch spec/data/nodes/default.rb && touch spec/data/nodes/test.example.com.rb
fi

echo "--- Update PATH and activate ruby and bundle"
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"

ruby -v
bundle -v

###
### The followiong block is intended to troubleshoot why git pull is failing on Debian 9 when using a cheffish git dependency and a SHA reference.
### The working theory is that an older version of git is not handling the git+https URL with a SHA properly.
###

# Function to detect OS and version
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    elif type lsb_release >/dev/null 2>&1; then
        OS=$(lsb_release -si)
        VER=$(lsb_release -sr)
    elif [ -f /etc/lsb-release ]; then
        . /etc/lsb-release
        OS=$DISTRIB_ID
        VER=$DISTRIB_RELEASE
    elif [ -f /etc/debian_version ]; then
        OS=Debian
        VER=$(cat /etc/debian_version)
    else
        OS=$(uname -s)
        VER=$(uname -r)
    fi
}

# Check if running on Debian 9
is_debian_9() {
    detect_os
    if [[ "$OS" =~ "Debian" ]] && [[ "$VER" =~ ^9\. ]]; then
        return 0  # true
    else
        return 1  # false
    fi
}

echo "=== OS Detection ==="
detect_os
echo "Detected OS: $OS"
echo "Detected Version: $VER"

# Only run git update on Debian 9
if is_debian_9; then
    echo "=== Running on Debian 9 - Proceeding with Git update ==="

    echo "=== Checking Git Version ==="
    echo "Current Git version:"
    git --version

    # Get the current git version number
    CURRENT_VERSION=$(git --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    echo "Detected version: $CURRENT_VERSION"

    # Define minimum required version (GitHub requires 2.18+ for best compatibility)
    MIN_VERSION="2.18.0"

    # Function to compare versions
    version_compare() {
        echo "$1 $2" | awk '{
            split($1, a, ".");
            split($2, b, ".");
            for (i = 1; i <= 3; i++) {
                if (a[i] < b[i]) {
                    print "older";
                    exit;
                } else if (a[i] > b[i]) {
                    print "newer";
                    exit;
                }
            }
            print "equal";
        }'
    }

    COMPARISON=$(version_compare "$CURRENT_VERSION" "$MIN_VERSION")

    if [ "$COMPARISON" = "older" ]; then
        echo "Git version $CURRENT_VERSION is older than recommended $MIN_VERSION"
        echo "Updating Git..."

        # Update package lists
        apt-get update

        # For Debian 9, we might need to use backports or compile from source
        # First try the standard repository
        echo "Attempting to install newer git from standard repository..."
        apt-get install -y git

        # Check if update was successful
        NEW_VERSION=$(git --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        NEW_COMPARISON=$(version_compare "$NEW_VERSION" "$MIN_VERSION")

        if [ "$NEW_COMPARISON" = "older" ]; then
            echo "Standard repository didn't provide newer version. Trying backports..."

            # Add stretch-backports for newer git
            echo "deb http://deb.debian.org/debian stretch-backports main" >> /etc/apt/sources.list
            apt-get update

            # Install git from backports
            apt-get install -y -t stretch-backports git

            # Final version check
            FINAL_VERSION=$(git --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
            echo "Final Git version after update: $FINAL_VERSION"
        else
            echo "Git successfully updated to version: $NEW_VERSION"
        fi

    else
        echo "Git version $CURRENT_VERSION is sufficient (>= $MIN_VERSION)"
    fi

    echo "=== Final Git Version ==="
    git --version

    # Also check git's SSL/TLS configuration
    echo "=== Git SSL Configuration ==="
    echo "Git SSL verify setting: $(git config --global --get http.sslverify || echo 'not set')"
    echo "Git SSL version: $(git config --global --get http.sslversion || echo 'not set')"

    # Optionally configure git for better GitHub compatibility
    echo "=== Configuring Git for GitHub compatibility ==="
    git config --global http.postBuffer 524288000
    git config --global http.maxRequestBuffer 100M
    git config --global core.compression 0

    echo "=== Git Update Complete ==="

else
    echo "=== Not running on Debian 9 - Skipping Git update ==="
    echo "Current system: $OS $VER"
    echo "Git update script only runs on Debian 9"

    # Still show current git version for reference
    echo "Current Git version on this system:"
    git --version 2>/dev/null || echo "Git not installed or not in PATH"
fi

###
###
###
### End git update block

echo "--- Running Chef bundle install"
bundle install --jobs=3 --retry=3

case $TestType in

    Unit)
        RakeTest=("spec:unit" "component_specs")
        ;;

    Integration)
        RakeTest=("spec:integration")
        ;;

    Functional)
        RakeTest=("spec:functional")
        ;;

    *)
        echo -e "\nTestType $TestType not valid\n" >&2
        exit 1
        ;;
esac

for test in "${RakeTest[@]}"
do
    echo "--- Chef $test run"
    bundle exec rake "$test"
done
