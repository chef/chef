#!/usr/bin/env bash

# $PROJECT_NAME is set by Jenkins, this allows us to use the same script to verify
# Chef and Angry Chef
export PATH=/opt/$PROJECT_NAME/bin:$PATH

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
for ruby_env_var in RUBYOPT \\
                    BUNDLE_BIN_PATH \\
                    BUNDLE_GEMFILE \\
                    GEM_PATH \\
                    GEM_HOME
do
  unset $ruby_env_var
done

chef-client --version
