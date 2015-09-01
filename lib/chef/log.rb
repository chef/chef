#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: AJ Christensen (<@aj@opscode.com>)
# Author:: Christopher Brown (<cb@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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

require 'logger'
require 'chef/monologger'
require 'chef/exceptions'
require 'mixlib/log'
require 'chef/log/syslog' unless (RUBY_PLATFORM =~ /mswin|mingw|windows/)
require 'chef/log/winevt'

class Chef
  class Log
    extend Mixlib::Log

    # Force initialization of the primary log device (@logger)
    init(MonoLogger.new(STDOUT))

    class Formatter
      def self.show_time=(*args)
        Mixlib::Log::Formatter.show_time = *args
      end
    end

    def self.deprecation(msg=nil, location=caller(2..2)[0], &block)
      if msg
        msg << " at #{Array(location).join("\n")}"
        msg = msg.join("") if msg.respond_to?(:join)
      end
      if Chef::Config[:treat_deprecation_warnings_as_errors]
        error(msg, &block)
        raise Chef::Exceptions::DeprecatedFeatureError.new(msg)
      else
        warn(msg, &block)
      end
    end

  end
end
