#!/bin/bash
set -euo pipefail

RUBY_VERSION="3.4.2"
RUBY_TARBALL="ruby-${RUBY_VERSION}.tar.bz2"
RUBY_BASE_URL="https://cache.ruby-lang.org/pub/ruby/3.4"
INSTALL_DIR="/tmp/ruby-${RUBY_VERSION}"

echo "👉 Installing Ruby ${RUBY_VERSION} into ${INSTALL_DIR}..."

# Download and extract
mkdir -p "${INSTALL_DIR}"
curl -sSL "${RUBY_BASE_URL}/${RUBY_TARBALL}" | tar -xj -C /tmp

# Build Ruby (Amazon Linux 2 needs dev tools)
cd "/tmp/ruby-${RUBY_VERSION}"
./configure --prefix="${INSTALL_DIR}"
make -j"$(nproc)"
make install

echo "Ruby installed at ${INSTALL_DIR}/bin/ruby"
