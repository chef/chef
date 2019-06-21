#!/bin/bash
set -ueo pipefail

channel="${CHANNEL:-unstable}"
product="${PRODUCT:-chef}"
version="${VERSION:-latest}"

export INSTALL_DIR="/opt/$product"

echo "--- Installing $channel $product $version"
package_file="$("/opt/$TOOLCHAIN/bin/install-omnibus-product" -c "$channel" -P "$product" -v "$version" | tail -1)"

echo "--- Verifying omnibus package is signed"
"/opt/$TOOLCHAIN/bin/check-omnibus-package-signed" "$package_file"

sudo rm -f "$package_file"

echo "--- Verifying ownership of package files"

NONROOT_FILES="$(find "$INSTALL_DIR" ! -user 0 -print)"
if [[ "$NONROOT_FILES" == "" ]]; then
  echo "Packages files are owned by root.  Continuing verification."
else
  echo "Exiting with an error because the following files are not owned by root:"
  echo "$NONROOT_FILES"
  exit 1
fi

echo "--- Running verification for $channel $product $version"

# Our tests hammer YUM pretty hard and the EL6 testers get corrupted
# after some period of time. Rebuilding the RPM database clears
# up the underlying corruption. We'll do this each test run just to
# be safe.
if [[ -f /etc/redhat-release ]]; then
  major_version="$(sed 's/^.\+ release \([0-9]\+\).*/\1/' /etc/redhat-release)"
  if [[ "$major_version" -lt "7" ]]; then
    sudo rm -rf /var/lib/rpm/__db*
    sudo db_verify /var/lib/rpm/Packages
    sudo rpm --rebuilddb
    sudo yum clean all
  fi
fi

# Set up a custom tmpdir, and clean it up before and after the tests
TMPDIR="${TMPDIR:-/tmp}/cheftest"
export TMPDIR
sudo rm -rf "$TMPDIR"
mkdir -p "$TMPDIR"

# Verify that we kill any orphaned test processes. Kill any orphaned rspec processes.
ps ax | grep -E 'rspec' | grep -v grep | awk '{ print $1 }' | xargs sudo kill -s KILL || true

PATH="/opt/$product/bin:$PATH"
export PATH

BIN_DIR="/opt/$product/bin"
export BIN_DIR

# We don't want to add the embedded bin dir to the main PATH as this
# could mask issues in our binstub shebangs.
EMBEDDED_BIN_DIR="/opt/$product/embedded/bin"
export EMBEDDED_BIN_DIR

# If we are on Mac our symlinks are located under /usr/local/bin
# otherwise they are under /usr/bin
if [[ -f /usr/bin/sw_vers ]]; then
  USR_BIN_DIR="/usr/local/bin"
else
  USR_BIN_DIR="/usr/bin"
fi
export USR_BIN_DIR

# sanity check that we're getting the correct symlinks from the pre-install script
# solaris doesn't have readlink or test -e. ls -n is different on BSD. proceed with caution.
if [[ ! -L $USR_BIN_DIR/chef-client ]] || [[ $(ls -l $USR_BIN_DIR/chef-client | awk '{print$NF}') != "$BIN_DIR/chef-client" ]]; then
  echo "$USR_BIN_DIR/chef-client symlink to $BIN_DIR/chef-client was not correctly created by the pre-install script!"
  exit 1
fi

if [[ ! -L $USR_BIN_DIR/knife ]] || [[ $(ls -l $USR_BIN_DIR/knife | awk '{print$NF}') != "$BIN_DIR/knife" ]]; then
  echo "$USR_BIN_DIR/knife symlink to $BIN_DIR/knife was not correctly created by the pre-install script!"
  exit 1
fi

if [[ ! -L $USR_BIN_DIR/chef-solo ]] || [[ $(ls -l $USR_BIN_DIR/chef-solo | awk '{print$NF}') != "$BIN_DIR/chef-solo" ]]; then
  echo "$USR_BIN_DIR/chef-solo symlink to $BIN_DIR/chef-solo was not correctly created by the pre-install script!"
  exit 1
fi

if [[ ! -L $USR_BIN_DIR/ohai ]] || [[ $(ls -l $USR_BIN_DIR/ohai | awk '{print$NF}') != "$BIN_DIR/ohai" ]]; then
  echo "$USR_BIN_DIR/ohai symlink to $BIN_DIR/ohai was not correctly created by the pre-install script!"
  exit 1
fi

chef-client --version

# Exercise various packaged tools to validate binstub shebangs
"$EMBEDDED_BIN_DIR/ruby" --version
"$EMBEDDED_BIN_DIR/gem" --version
"$EMBEDDED_BIN_DIR/bundle" --version
"$EMBEDDED_BIN_DIR/rspec" --version

# ffi-yajl must run in c-extension mode or we take perf hits, so we force it
# before running rspec so that we don't wind up testing the ffi mode
FORCE_FFI_YAJL=ext
export FORCE_FFI_YAJL

# chef-shell smoke tests require "rb-readline" which requires "infocmp"
# most platforms provide "infocmp" by default via an "ncurses" package but SLES 11 and 12 provide it via "ncurses-devel" which
# isn't typically installed. omnibus-toolchain has "infocmp" built-in so we add omnibus-toolchain to the PATH to ensure
# tests will function properly.
PATH="/opt/$TOOLCHAIN/bin:/usr/local/bin:/opt/$TOOLCHAIN/embedded/bin:$PATH"

# add chef's bin paths to PATH to ensure tests function properly
PATH="/opt/$product/bin:/opt/$product/embedded/bin:$PATH"

gem_list="$(gem which chef)"
lib_dir="$(dirname "$gem_list")"
chef_gem="$(dirname "$lib_dir")"

# ensure that PATH doesn't get reset by sudoers
if [[ -d /etc/sudoers.d ]]; then
  echo "Defaults:$(id -un) !secure_path, exempt_group += $(id -gn)" | sudo tee "/etc/sudoers.d/$(id -un)-preserve_path"
  sudo chmod 440 "/etc/sudoers.d/$(id -un)-preserve_path"
elif [[ -d /usr/local/etc/sudoers.d ]]; then
  echo "Defaults:$(id -un) !secure_path, exempt_group += $(id -gn)" | sudo tee "/usr/local/etc/sudoers.d/$(id -un)-preserve_path"
  sudo chmod 440 "/usr/local/etc/sudoers.d/$(id -un)-preserve_path"
fi

cd "$chef_gem"
sudo -E bundle install
sudo -E bundle exec rspec -r rspec_junit_formatter -f RspecJunitFormatter -o test.xml -f documentation spec/functional
