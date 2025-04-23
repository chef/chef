# This script gets a container ready to run our various tests in BuildKite

. /etc/os-release
echo $NAME
echo $ID

echo "--- Installing packages"
# Set package manager based on os type
PACKAGE_MANAGER=""
PACKAGES=""
case "$ID" in
  ubuntu|debian)
    PACKAGE_MANAGER="apt-get"
    PACKAGES="$PACKAGES libssl-dev libreadline-dev zlib1g-dev autoconf bison build-essential libyaml-dev libreadline-dev libncurses5-dev libffi-dev libgdbm-dev"

    echo "using $PACKAGE_MANAGER to install packages: $PACKAGES"
    sudo $PACKAGE_MANAGER update
    sudo $PACKAGE_MANAGER install $PACKAGES -y
    ;;
  rhel|rocky)
    PACKAGE_MANAGER="yum"
    # PACKAGES="$PACKAGES "
    ;;
esac

if [[ "$PACKAGE_MANAGER" == "" ]]; then
  echo "Invalid OS type: $ID"
  exit 1
fi

# Install Ruby to get the bundler gem.
echo "--- Ruby Config..."

RUBY_VERSION=$(cat .buildkite-platform.json | awk -F'"' '/"ruby_version"/ {print $4}')
export RUBY_VERSION

curl -fsSL https://github.com/rbenv/rbenv-installer/raw/HEAD/bin/rbenv-installer | bash
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
. ~/.bashrc

rbenv install ${RUBY_VERSION}
rbenv global ${RUBY_VERSION}

gem install bundler -v $(cat .buildkite-platform.json | awk -F'"' '/"bundle_version"/ {print $4}')
export PATH="/root/.rbenv/shims:$PATH"

echo "--- Container Config..."
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
