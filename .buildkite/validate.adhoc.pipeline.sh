#!/bin/bash

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

echo "--- Generating pipeline configuration.."
/tmp/ruby-3.4.2-install/bin/ruby .buildkite/validate-adhoc.rb > pipeline-config.yaml

buildkite-agent pipeline upload pipeline-config.yaml
