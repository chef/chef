#!/bin/bash

# Install Ruby to get the bundler gem.
echo "--- Installing dev tools.."
yum groupinstall "Development Tools" -y
yum install -y git curl gcc openssl-devel libyaml-devel libffi-devel readline-devel zlib-devel gdbm-devel ncurses-devel

echo "--- Installing Ruby..."
RUBY_VERSION=$(cat .buildkite-platform.json | awk -F'"' '/"ruby_version"/ {print $4}')
export RUBY_VERSION

curl -fsSL https://github.com/rbenv/rbenv-installer/raw/HEAD/bin/rbenv-installer | bash
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"

rbenv install ${RUBY_VERSION}
rbenv global ${RUBY_VERSION}

echo "Successfully installed ruby"
ruby -v

echo "--- Generating pipeline configuration.."
ruby .buildkite/validate-adhoc.rb | buildkite-agent pipeline upload
