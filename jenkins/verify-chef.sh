#!/usr/bin/env bash

# $PROJECT_NAME is set by Jenkins, this allows us to use the same script to verify
# Chef and Angry Chef
PATH=/opt/$PROJECT_NAME/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export PATH

# We don't want to add the embedded bin dir to the main PATH as this
# could mask issues in our binstub shebangs.
EMBEDDED_BIN_DIR=/opt/$PROJECT_NAME/embedded/bin
export PATH

# sanity check that we're getting symlinks from the pre-install script
if [ ! -L "/usr/bin/chef-client" ]; then
  echo "/usr/bin/chef-client symlink was not installed by pre-install script!"
  exit 1
fi

if [ ! -L "/usr/bin/knife" ]; then
  echo "/usr/bin/knife symlink was not installed by pre-install script!"
  exit 1
fi

if [ ! -L "/usr/bin/chef-solo" ]; then
  echo "/usr/bin/chef-solo symlink was not installed by pre-install script!"
  exit 1
fi

if [ ! -L "/usr/bin/ohai" ]; then
  echo "/usr/bin/ohai symlink was not installed by pre-install script!"
  exit 1
fi

# Ensure the calling environment (disapproval look Bundler) does not
# infect our Ruby environment created by the `chef-client` cli.
for ruby_env_var in RUBYOPT \
                    BUNDLE_BIN_PATH \
                    BUNDLE_GEMFILE \
                    GEM_PATH \
                    GEM_HOME
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

PATH=/opt/$PROJECT_NAME/bin:/opt/$PROJECT_NAME/embedded/bin:$PATH
export PATH

# Test against the appbundle'd Chef
cd /opt/$PROJECT_NAME/embedded/apps/chef
sudo env PATH=$PATH TERM=xterm bundle exec rspec -r rspec_junit_formatter -f RspecJunitFormatter -o $WORKSPACE/test.xml -f documentation spec/functional spec/unit
