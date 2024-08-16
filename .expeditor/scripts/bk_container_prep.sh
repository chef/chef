# This script gets a container ready to run our various tests in BuildKite

# source /etc/os-release
# echo $PRETTY_NAME

# Install Chef Foundation
echo "--- Installing Chef Foundation"
curl -fsSL https://omnitruck.chef.io/chef/install.sh | bash -s -- -c "current" -P "chef-foundation" -v "$CHEF_FOUNDATION_VERSION"
export PATH="/opt/chef/bin:${PATH}"

echo "--- Container Config..."
echo "ruby version:"
ruby -v
echo "bundler version:"
bundle -v

echo "--- Preparing Container..."

export FORCE_FFI_YAJL="ext"
export CHEF_LICENSE="accept-no-persist"
export CHEF_LICENSE_SERVER="http://hosted-license-service-lb-8000-606952349.us-west-2.elb.amazonaws.com:8000"

export BUNDLE_GEMFILE="/workdir/Gemfile"

# make sure we have the network tools in place for various network specs
if [ -f /etc/debian_version ]; then
  touch /etc/network/interfaces
fi

# remove default bundler config if there is one
rm -f .bundle/config

echo "+++ Run tests"
