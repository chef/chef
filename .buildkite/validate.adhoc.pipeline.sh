#!/bin/bash

# Install Ruby to get the bundler gem.
# echo "--- Installing dev tools.."
# yum groupinstall "Development Tools" -y
# yum install -y git curl gcc openssl-devel libyaml-devel libffi-devel readline-devel zlib-devel gdbm-devel ncurses-devel

# echo "--- Installing Ruby..."
# RUBY_VERSION=$(cat .buildkite-platform.json | awk -F'"' '/"ruby_version"/ {print $4}')
# export RUBY_VERSION

# curl -fsSL https://github.com/rbenv/rbenv-installer/raw/HEAD/bin/rbenv-installer | bash
# export PATH="$HOME/.rbenv/bin:$PATH"
# eval "$(rbenv init -)"

# rbenv install ${RUBY_VERSION}
# rbenv global ${RUBY_VERSION}

# echo "Successfully installed ruby"
# ruby -v

workdir=$(pwd)

echo "--- Installing Ruby.."
curl -sSL https://cache.ruby-lang.org/pub/ruby/3.4/ruby-3.4.2.tar.xz | tar -xJ -C /tmp

cd /tmp/ruby-3.4.2
./configure --prefix=/tmp/ruby-3.4.2-install
make -j"$(nproc)"
make install

echo "Installed Ruby version"
/tmp/ruby-3.4.2-install/bin/ruby -v

cd $workdir
echo "where am i?"
ls -la

echo "--- Generating pipeline configuration.."
/tmp/ruby-3.4.2-install/bin/ruby .buildkite/validate-adhoc.rb > pipeline-config.yaml
cat pipeline-config.yaml

buildkite-agent pipeline upload pipeline-config.yaml
