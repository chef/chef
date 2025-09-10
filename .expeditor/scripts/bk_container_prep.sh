# This script gets a container ready to run our various tests in BuildKite

. /etc/os-release

echo "--- Installing packages"
# Set package manager based on os type
PACKAGE_MANAGER=""
PACKAGES=""

# for debian 9, we need to update the source list.
if [ "$ID" = "debian" ] && [ "$VERSION_ID" = "9" ]; then
  echo "sources.list before:"
  sudo cat /etc/apt/sources.list

  echo "updating sources.list:"
  sudo tee /etc/apt/sources.list <<EOF
deb http://cdn-aws.deb.debian.org/debian-archive/debian stretch main
deb http://archive.debian.org/debian-security stretch/updates main
deb http://cdn-aws.deb.debian.org/debian-archive/debian-security stretch/updates main
deb http://archive.debian.org/debian stretch-backports main
EOF

  echo "sources.list after:"
  sudo cat /etc/apt/sources.list
fi

echo "updating git on debian 9"
sudo apt-get update -y
sudo apt-get install -y -t stretch-backports git

case "$ID" in
  ubuntu|debian)
    PACKAGE_MANAGER="apt-get"
    PACKAGES="$PACKAGES libssl-dev libreadline-dev zlib1g-dev autoconf bison build-essential libyaml-dev libncurses5-dev libffi-dev libgdbm-dev libarchive-dev"

    echo "using $PACKAGE_MANAGER to install packages: $PACKAGES"
    sudo $PACKAGE_MANAGER update -y
    sudo $PACKAGE_MANAGER install $PACKAGES -y
    ;;
  rhel|rocky)
    PACKAGE_MANAGER="dnf"
    if [ "$ID" = "rocky" ]; then
      PACKAGE_MANAGER+=" --enablerepo=devel"
    fi
    PACKAGES="$PACKAGES openssl-devel libarchive-devel libffi-devel libyaml-devel"
    echo "using $PACKAGE_MANAGER to install packages: $PACKAGES"
    sudo $PACKAGE_MANAGER install $PACKAGES -y
    ;;
esac

if [ "$PACKAGE_MANAGER" = "" ]; then
  echo "Invalid OS type: $ID"
  exit 1
fi

# Install Ruby to get the bundler gem.
echo "--- Configuring Ruby..."

RUBY_VERSION=$(cat .buildkite-platform.json | awk -F'"' '/"ruby_version"/ {print $4}')
export RUBY_VERSION

curl -fsSL https://github.com/rbenv/rbenv-installer/raw/HEAD/bin/rbenv-installer | bash
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"

rbenv install ${RUBY_VERSION}
rbenv global ${RUBY_VERSION}

gem install bundler -v $(cat .buildkite-platform.json | awk -F'"' '/"bundle_version"/ {print $4}')

echo "Checking Ruby and Bundle version..."
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
  touch /etc/network/interfaces
fi

# remove default bundler config if there is one
rm -f .bundle/config

echo "+++ Run tests"
