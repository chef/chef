# This script gets a container ready to run our various tests in BuildKite

# source /etc/os-release
# echo $PRETTY_NAME

# # Install Chef Foundation
# echo "--- Installing Chef Foundation"
# curl -fsSL https://omnitruck.chef.io/chef/install.sh | bash -s -- -c "current" -P "chef-foundation" -v "$CHEF_FOUNDATION_VERSION"
# export PATH="/opt/chef/bin:${PATH}"

# Install Ruby to get the bundler gem.
echo "--- Ruby Config..."
sudo apt-get install jq -y
RUBY_VERSION=$(cat .buildkite-platform.json | jq -r '.ruby_version')
export RUBY_VERSION
echo "Proposed Ruby Version is: $RUBY_VERSION"
rbenv install ${RUBY_VERSION}
rbenv global ${RUBY_VERSION}
gem install bundler -v ${BUNDLER_VERSION}


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
