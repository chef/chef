#!/usr/bin/env bash

export PATH=/opt/chefdk/bin:$PATH

# Ensure the calling environment (disapproval look Bundler) does not
# infect our Ruby environment created by the `chef` cli.
for ruby_env_var in RUBYOPT \
                    BUNDLE_BIN_PATH \
                    BUNDLE_GEMFILE \
                    GEM_PATH \
                    GEM_HOME
do
  unset $ruby_env_var
done

sudo chef verify --unit
