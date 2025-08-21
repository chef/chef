#!/bin/bash
set -e

RUBY_VERSION="3.4.2"

echo "Installing dependencies..."
sudo yum groupinstall -y "Development Tools"
sudo yum install -y openssl-devel readline-devel zlib-devel libffi-devel gdbm-devel \
    libyaml-devel ncurses-devel wget tar xz xz-devel

echo "Downloading Ruby $RUBY_VERSION..."
cd /tmp
wget https://cache.ruby-lang.org/pub/ruby/3.4/ruby-${RUBY_VERSION}.tar.xz
tar -xf ruby-${RUBY_VERSION}.tar.xz

echo "Building Ruby $RUBY_VERSION..."
cd ruby-${RUBY_VERSION}
./configure --prefix=/usr/local
make -j"$(nproc)"
sudo make install

echo "Ruby $RUBY_VERSION installed!"
ruby --version
