#!/bin/sh

# Set up a custom tmpdir, and clean it up before and after the tests
TMPDIR="${TMPDIR:-/tmp}/cheftest"
export TMPDIR
rm -rf $TMPDIR
mkdir -p $TMPDIR

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

# ACCEPTANCE environment variable will be set on acceptance testers.
# If is it set; we run the acceptance tests, otherwise run rspec tests.
if [ "x$ACCEPTANCE" != "x" ]; then
  # On acceptance testers we have Chef DK. We will use its Ruby environment
  # to cut down the gem installation time.
  PATH=/opt/chefdk/bin:/opt/chefdk/embedded/bin:$PATH
  export PATH

  # Test against the vendored Chef gem
  cd /opt/$PROJECT_NAME/embedded/lib/ruby/gems/*/gems/chef-[0-9]*/acceptance
  sudo env PATH=$PATH AWS_SSH_KEY_ID=$AWS_SSH_KEY_ID ARTIFACTORY_USERNAME=$ARTIFACTORY_USERNAME ARTIFACTORY_PASSWORD=$ARTIFACTORY_PASSWORD bundle install
  sudo env PATH=$PATH AWS_SSH_KEY_ID=$AWS_SSH_KEY_ID ARTIFACTORY_USERNAME=$ARTIFACTORY_USERNAME ARTIFACTORY_PASSWORD=$ARTIFACTORY_PASSWORD KITCHEN_DRIVER=ec2 bundle exec chef-acceptance test top-cookbooks --force-destroy
else
  PATH=/opt/$PROJECT_NAME/bin:/opt/$PROJECT_NAME/embedded/bin:$PATH
  export PATH

  # Test against the vendored Chef gem
  cd /opt/$PROJECT_NAME/embedded/lib/ruby/gems/*/gems/chef-[0-9]*

  if [ ! -f "Gemfile.lock" ]; then
    echo "Chef gem does not contain a Gemfile.lock! This is needed to run any tests."
    exit 1
  fi

  unset CHEF_FIPS
  if [ "$PIPELINE_NAME" = "chef-fips" ]; then
      echo "Setting fips mode"
      CHEF_FIPS=1
      export CHEF_FIPS
  fi
  sudo env PATH=$PATH TERM=xterm CHEF_FIPS=$CHEF_FIPS bundle exec rspec -r rspec_junit_formatter -f RspecJunitFormatter -o $WORKSPACE/test.xml -f documentation spec/functional
fi
