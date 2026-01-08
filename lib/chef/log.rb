#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: AJ Christensen (<@aj@opscode.com>)
# Author:: Christopher Brown (<cb@chef.io>)
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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

require "logger"
require_relative "monologger"
require_relative "exceptions"
require "mixlib/log"
require_relative "log/syslog" unless RUBY_PLATFORM.match?(/mswin|mingw|windows/)
require_relative "log/winevt"

class Chef
  class Log
    extend Mixlib::Log

    def self.setup!
      init(MonoLogger.new(STDOUT))
      nil
    end

    # Force initialization of the primary log device (@logger)
    setup!

    class Formatter
      def self.show_time=(*args)
        Mixlib::Log::Formatter.show_time = *args
      end
    end

    #
    # Get the location of the caller (from the recipe). Grabs the first caller
    # that is *not* in the chef gem proper (allowing us to weed out internal
    # calls and give the user a more useful perspective).
    #
    # @return [String] The location of the caller (file:line#) from caller(0..20), or nil if no non-chef caller is found.
    #
    def self.caller_location
      # Pick the first caller that is *not* part of the Chef gem, that's the
      # thing the user wrote. Or failing that, the most recent caller.
      chef_gem_path = File.expand_path("..", __dir__)
      caller(0..20).find { |c| !c.start_with?(chef_gem_path) } || caller(0..1)[0]
    end

    # Log a deprecation warning.
    #
    # If the treat_deprecation_warnings_as_errors config option is set, this
    # will raise an exception instead.
    #
    # @param msg [String] Deprecation message to display.
    def self.deprecation(msg, &block)
      if Chef::Config[:treat_deprecation_warnings_as_errors]
        error(msg, &block)
        raise Chef::Exceptions::DeprecatedFeatureError.new(msg)
      else
        warn(msg, &block)
      end
    end

  end
end
