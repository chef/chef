#!/bin/sh

set -evx

# Our tests hammer YUM pretty hard and the EL6 testers get corrupted
# after some period of time. Rebuilding the RPM database clears
# up the underlying corruption. We'll do this each test run just to
# be safe.
if [ -f /etc/redhat-release ]; then
  major_version=`sed 's/^.\+ release \([0-9]\+\).*/\1/' /etc/redhat-release`
  if [ "$major_version" -lt "7" ]; then
    sudo rm -rf /var/lib/rpm/__db*
    sudo db_verify /var/lib/rpm/Packages
    sudo rpm --rebuilddb
    sudo yum clean all
  fi
fi

# Set up a custom tmpdir, and clean it up before and after the tests
TMPDIR="${TMPDIR:-/tmp}/cheftest"
export TMPDIR
sudo rm -rf $TMPDIR
mkdir -p $TMPDIR

# Verify that we kill any orphaned test processes. Kill any orphaned rspec processes.
ps ax | egrep 'rspec' | grep -v grep | awk '{ print $1 }' | xargs sudo kill -s KILL || true

# $PROJECT_NAME is set by Jenkins, this allows us to use the same script to verify
# Chef and Angry Chef
PATH=/opt/$PROJECT_NAME/bin:$PATH
export PATH

BIN_DIR=/opt/$PROJECT_NAME/bin
export BIN_DIR

# We don't want to add the embedded bin dir to the main PATH as this
# could mask issues in our binstub shebangs.
EMBEDDED_BIN_DIR=/opt/$PROJECT_NAME/embedded/bin
export EMBEDDED_BIN_DIR

# If we are on Mac our symlinks are located under /usr/local/bin
# otherwise they are under /usr/bin
if [ -f /usr/bin/sw_vers ]; then
  USR_BIN_DIR="/usr/local/bin"
else
  USR_BIN_DIR="/usr/bin"
fi
export USR_BIN_DIR

# sanity check that we're getting the correct symlinks from the pre-install script
# solaris doesn't have readlink or test -e. ls -n is different on BSD. proceed with caution.
if [ ! -L $USR_BIN_DIR/chef-client ] || [ `ls -l $USR_BIN_DIR/chef-client | awk '{print$NF}'` != "$BIN_DIR/chef-client" ]; then
  echo "$USR_BIN_DIR/chef-client symlink to $BIN_DIR/chef-client was not correctly created by the pre-install script!"
  exit 1
fi

if [ ! -L $USR_BIN_DIR/knife ] || [ `ls -l $USR_BIN_DIR/knife | awk '{print$NF}'` != "$BIN_DIR/knife" ]; then
  echo "$USR_BIN_DIR/knife symlink to $BIN_DIR/knife was not correctly created by the pre-install script!"
  exit 1
fi

if [ ! -L $USR_BIN_DIR/chef-solo ] || [ `ls -l $USR_BIN_DIR/chef-solo | awk '{print$NF}'` != "$BIN_DIR/chef-solo" ]; then
  echo "$USR_BIN_DIR/chef-solo symlink to $BIN_DIR/chef-solo was not correctly created by the pre-install script!"
  exit 1
fi

if [ ! -L $USR_BIN_DIR/ohai ] || [ `ls -l $USR_BIN_DIR/ohai | awk '{print$NF}'` != "$BIN_DIR/ohai" ]; then
  echo "$USR_BIN_DIR/ohai symlink to $BIN_DIR/ohai was not correctly created by the pre-install script!"
  exit 1
fi

# Ensure the calling environment (disapproval look Bundler) does not
# infect our Ruby environment created by the `chef-client` cli.
for ruby_env_var in _ORIGINAL_GEM_PATH \
                    BUNDLE_BIN_PATH \
                    BUNDLE_GEMFILE \
                    GEM_HOME \
                    GEM_PATH \
                    GEM_ROOT \
                    RUBYLIB \
                    RUBYOPT \
                    RUBY_ENGINE \
                    RUBY_ROOT \
                    RUBY_VERSION \
                    BUNDLER_VERSION

do
  unset $ruby_env_var
done

chef-client --version

# Exercise various packaged tools to validate binstub shebangs
$EMBEDDED_BIN_DIR/ruby --version
$EMBEDDED_BIN_DIR/gem --version
$EMBEDDED_BIN_DIR/bundle --version
$EMBEDDED_BIN_DIR/rspec --version

# ffi-yajl must run in c-extension mode or we take perf hits, so we force it
# before running rspec so that we don't wind up testing the ffi mode
FORCE_FFI_YAJL=ext
export FORCE_FFI_YAJL

OLD_PATH=$PATH
PATH=/opt/$PROJECT_NAME/bin:/opt/$PROJECT_NAME/embedded/bin:$PATH

gem_list=`gem which chef`
lib_dir=`dirname $gem_list`
CHEF_GEM=`dirname $lib_dir`


cd $CHEF_GEM
sudo bundle install
sudo bundle exec rspec -r rspec_junit_formatter -f RspecJunitFormatter -o $WORKSPACE/test.xml -f documentation spec/functional
