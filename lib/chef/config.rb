#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Christopher Brown (<cb@chef.io>)
# Author:: AJ Christensen (<aj@chef.io>)
# Author:: Mark Mzyk (<mmzyk@chef.io>)
# Author:: Kyle Goodwin (<kgoodwin@primerevenue.com>)
# Copyright:: Copyright 2008-2016, Chef Software Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "chef/log"
require "chef-config/logger"

# DI our logger into ChefConfig before we load the config. Some defaults are
# auto-detected, and this emits log messages on some systems, all of which will
# occur at require-time. So we need to set the logger first.
ChefConfig.logger = Chef::Log

require "chef-config/config"
require "chef/platform/query_helpers"

# Ohai::Config defines its own log_level and log_location. When loaded, it will
# override the default ChefConfig::Config values. We save them here before
# loading ohai/config so that we can override them again inside Chef::Config.
#
# REMOVEME once these configurables are removed from the top level of Ohai.
LOG_LEVEL = ChefConfig::Config[:log_level] unless defined? LOG_LEVEL
LOG_LOCATION = ChefConfig::Config[:log_location] unless defined? LOG_LOCATION

# Load the ohai config into the chef config. We can't have an empty ohai
# configuration context because `ohai.plugins_path << some_path` won't work,
# and providing default ohai config values here isn't DRY.
require "ohai/config"

class Chef
  Config = ChefConfig::Config

  # We re-open ChefConfig::Config to add additional settings. Generally,
  # everything should go in chef-config so it's shared with whoever uses that.
  # We make execeptions to that rule when:
  # * The functionality isn't likely to be useful outside of Chef
  # * The functionality makes use of a dependency we don't want to add to chef-config
  class Config

    default :event_loggers do
      evt_loggers = []
      if ChefConfig.windows? && !(Chef::Platform.windows_server_2003? ||
          Chef::Platform.windows_nano_server?)
        evt_loggers << :win_evt
      end
      evt_loggers
    end

    # Override the default values that were set by Ohai.
    #
    # REMOVEME once these configurables are removed from the top level of Ohai.
    default :log_level, LOG_LEVEL
    default :log_location, LOG_LOCATION

    # Ohai::Config[:log_level] is deprecated and warns when set. Unfortunately,
    # there is no way to distinguish between setting log_level and setting
    # Ohai::Config[:log_level]. Since log_level and log_location are used by
    # chef-client and other tools (e.g., knife), we will mute the warnings here
    # by redefining the config_attr_writer to not warn for these options.
    #
    # REMOVEME once the warnings for these configurables are removed from Ohai.
    [ :log_level, :log_location ].each do |option|
      config_attr_writer option do |value|
        value
      end
    end

  end
end
