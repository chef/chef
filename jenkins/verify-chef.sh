#!/usr/bin/env bash

# $PROJECT_NAME is set by Jenkins, this allows us to use the same script to verify
# Chef and Angry Chef
PATH=/opt/$PROJECT_NAME/bin:$PATH
export PATH

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
linked_binaries=( "chef-client" "knife" "chef-solo" "ohai" )

for i in "${linked_binaries[@]}"
do
  LINK_TARGET=`readlink $USR_BIN_DIR/$i`
  if [ "$LINK_TARGET" != "$EMBEDDED_BIN_DIR/$i" ]; then
    echo "$USR_BIN_DIR/$i symlink to $EMBEDDED_BIN_DIR/$i was not correctly created by the pre-install script!"
    exit 1
  fi
done

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
                    RUBY_VERSION

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

# Test against the vendored Chef gem
cd /opt/$PROJECT_NAME/embedded/lib/ruby/gems/*/gems/chef-[0-9]*

if [ ! -f "Gemfile.lock" ]; then
  echo "Chef gem does not contain a Gemfile.lock! This is needed to run any tests."
  exit 1
fi

sudo env PATH=$PATH TERM=xterm bundle exec rspec -r rspec_junit_formatter -f RspecJunitFormatter -o $WORKSPACE/test.xml -f documentation spec/functional spec/unit
